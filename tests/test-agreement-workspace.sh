#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
PROPOSAL="$PWD/skills/proposal/scripts/proposal-workspace.sh"
AGREEMENT="$PWD/skills/agreement/scripts/agreement-workspace.sh"
INVOICE="$PWD/skills/invoice/scripts/invoice-ledger.sh"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
project="$root/2026-08-ACM-DESIGN-SERVICES"
mkdir -p "$project"
printf '# Project — Design Services\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 3 | setup | 2026-08-06 |\n| Project ID | 2026-08-ACM-DESIGN-SERVICES | setup | 2026-08-06 |\n| Project | Design Services | setup | 2026-08-06 |\n| Type | client | setup | 2026-08-06 |\n| Status | prospective | setup | 2026-08-06 |\n| Created | 2026-08-06 | setup | 2026-08-06 |\n| Client code | ACM | setup | 2026-08-06 |\n| Client | Acme Corp | setup | 2026-08-06 |\n' > "$project/PROJECT.md"

fail() { echo "FAIL: $*"; exit 1; }
expect_die() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi; }

# Writers reject a symlinked project root even when its basename matches the Project ID.
symlink_id=2026-08-SYM-SYMLINK-ROOT
real_project="$root/real-projects/$symlink_id"
linked_project="$root/linked-projects/$symlink_id"
skills/project/scripts/project-workspace.sh init "$real_project" "Symlink Root" "$symlink_id" client active SYM "Symlink Client" >/dev/null
mkdir -p "$root/linked-projects"
ln -s "$real_project" "$linked_project"
expect_die bash "$AGREEMENT" init "$linked_project" "2026-08-06"
[ ! -e "$real_project/agreement" ] || fail "symlinked project root created agreement records in its target"

# Writers reject a symlinked agreement directory.
agreement_link_id=2026-08-LNK-AGREEMENT-DIRECTORY
agreement_link_project="$root/$agreement_link_id"
agreement_link_target="$root/external-agreement"
skills/project/scripts/project-workspace.sh init "$agreement_link_project" "Agreement Link" "$agreement_link_id" client active LNK "Link Client" >/dev/null
mkdir -p "$agreement_link_target"
ln -s "$agreement_link_target" "$agreement_link_project/agreement"
expect_die bash "$AGREEMENT" init "$agreement_link_project" "2026-08-06"
[ ! -e "$agreement_link_target/AGREEMENT.md" ] || fail "symlinked agreement directory received a record"

# Writers also reject a symlinked owned SOW directory.
sow_link_id=2026-08-SOW-SYMLINKED-SOW
sow_link_project="$root/$sow_link_id"
sow_link_target="$root/external-sow"
skills/project/scripts/project-workspace.sh init "$sow_link_project" "Symlinked SOW" "$sow_link_id" client active SOW "SOW Client" >/dev/null
mkdir -p "$sow_link_project/agreement" "$sow_link_target"
ln -s "$sow_link_target" "$sow_link_project/agreement/sow"
expect_die bash "$AGREEMENT" init "$sow_link_project" "2026-08-06"
[ ! -e "$sow_link_project/agreement/AGREEMENT.md" ] || fail "symlinked SOW directory allowed agreement initialization"

bash "$PROPOSAL" create "$project" "Acme Corp" "Design Services" "design-services" "2026-08-06" rev-01 >/dev/null
proposal="$project/proposals/2026-08-design-services-proposal-rev-01.md"
proposal_path="proposals/2026-08-design-services-proposal-rev-01.md"

# Promotion needs an accepted, checksum-protected source.
expect_die bash "$AGREEMENT" promote "$project" "$proposal_path" "2026-08-07"
bash "$PROPOSAL" send "$proposal" "2026-08-07" "Federico" "email" >/dev/null
checksum=$(awk -F'|' '/^\| Issued terms SHA-256 / {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' "$proposal")
expect_die bash "$AGREEMENT" promote "$project" "$proposal_path" "2026-08-07"
bash "$PROPOSAL" set-status "$proposal" accepted "2026-08-08" "Acme Corp" "signed PDF" >/dev/null
bash "$AGREEMENT" promote "$project" "$proposal_path" "2026-08-07" >/dev/null
[ -f "$project/agreement/AGREEMENT.md" ] || fail "AGREEMENT.md missing"
[ -d "$project/agreement/sow" ] || fail "sow dir missing"
[ ! -f "$project/agreement/2026-08-design-services-proposal-rev-01.md" ] || fail "proposal must be cited, not copied"
grep -Fq '| Source proposal | proposals/2026-08-design-services-proposal-rev-01.md |' "$project/agreement/AGREEMENT.md" || fail "source path missing"
grep -Fq "| Source proposal SHA-256 | $checksum |" "$project/agreement/AGREEMENT.md" || fail "source checksum missing"
grep -Fq '| Source proposal status | accepted |' "$project/agreement/AGREEMENT.md" || fail "accepted source status missing"
grep -Fq '| Status | prospective |' "$project/PROJECT.md" || fail "promotion changed project status"

# A second promotion is refused without touching either source or agreement.
agreement_before=$(shasum "$project/agreement/AGREEMENT.md" | awk '{print $1}')
proposal_before=$(shasum "$proposal" | awk '{print $1}')
expect_die bash "$AGREEMENT" promote "$project" "$proposal_path" "2026-08-08"
[ "$agreement_before" = "$(shasum "$project/agreement/AGREEMENT.md" | awk '{print $1}')" ] || fail "double promotion changed agreement"
[ "$proposal_before" = "$(shasum "$proposal" | awk '{print $1}')" ] || fail "promotion changed proposal"

# Lifecycle metadata remains outside the protected source and verification succeeds.
bash "$AGREEMENT" verify "$project" >/dev/null

# Tampering with cited issued terms is detected and never repaired.
cp "$proposal" "$root/proposal-backup.md"
sed -i.bak 's/\[TO CONFIRM: exclusions\]/changed after issue/' "$proposal" && rm "$proposal.bak"
tampered=$(shasum "$proposal" | awk '{print $1}')
expect_die bash "$AGREEMENT" verify "$project"
[ "$tampered" = "$(shasum "$proposal" | awk '{print $1}')" ] || fail "verify repaired the proposal"
mv "$root/proposal-backup.md" "$proposal"

# Amendment requires the document first, then appends atomically.
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "Extra facade study" "2026-09-01"
printf '# SOW 2\n' > "$project/agreement/sow/sow-2.md"
cp "$project/agreement/AGREEMENT.md" "$root/agreement-before-invalid-amendment-date.md"
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "Impossible effective date" "2026-02-30"
cmp -s "$project/agreement/AGREEMENT.md" "$root/agreement-before-invalid-amendment-date.md" || fail "invalid amendment date changed AGREEMENT.md bytes"
bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "Extra facade study" "2026-09-01" >/dev/null
grep -q '| 1 | 2026-09-01 | \[sow-2.md\](sow/sow-2.md) | Extra facade study |' "$project/agreement/AGREEMENT.md" || fail "amendment row"
printf '# SOW 3\n' > "$project/agreement/sow/sow-3.md"
bash "$AGREEMENT" record-amendment "$project" "sow-3.md" "Interior package" "2026-10-01" >/dev/null
grep -q '| 2 | 2026-10-01 |' "$project/agreement/AGREEMENT.md" || fail "amendment numbering"

expect_die bash "$AGREEMENT" record-amendment "$project" "../evil.md" "x" "2026-10-02"
bash "$AGREEMENT" verify "$project" >/dev/null
rm "$project/agreement/sow/sow-3.md"
expect_die bash "$AGREEMENT" verify "$project"
grep -q '| 2 | 2026-10-01 |' "$project/agreement/AGREEMENT.md" || fail "verify must not remove rows"

# A missing insertion marker blocks amendment recording and preserves the agreement byte-for-byte.
printf '# SOW 3 replacement\n' > "$project/agreement/sow/sow-3.md"
sed -i.bak '/<!-- amendments:end -->/d' "$project/agreement/AGREEMENT.md" && rm "$project/agreement/AGREEMENT.md.bak"
cp "$project/agreement/AGREEMENT.md" "$root/agreement-missing-marker-before.md"
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-3.md" "Marker failure" "2026-10-03"
cmp -s "$project/agreement/AGREEMENT.md" "$root/agreement-missing-marker-before.md" || fail "missing-marker amendment changed agreement bytes"

# Malformed agreement blocks mutation.
sed -i.bak 's/| Format version | 2 |/| Format version | 1 |/' "$project/agreement/AGREEMENT.md" && rm "$project/agreement/AGREEMENT.md.bak"
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "again" "2026-11-01"

# A direct engagement can initialize agreement context without a proposal.
direct_project="$root/2026-08-DIR-DIRECT-ENGAGEMENT"
skills/project/scripts/project-workspace.sh init "$direct_project" "Direct Engagement" 2026-08-DIR-DIRECT-ENGAGEMENT client active DIR "Direct Client" >/dev/null
bash "$AGREEMENT" init "$direct_project" "2026-08-09" >/dev/null
[ -f "$direct_project/agreement/AGREEMENT.md" ] || fail "direct AGREEMENT.md missing"
[ -d "$direct_project/agreement/sow" ] || fail "direct sow dir missing"
[ ! -d "$direct_project/proposals" ] || fail "direct initialization created proposals"
grep -Fq '| Source proposal | — |' "$direct_project/agreement/AGREEMENT.md" || fail "direct source path is not empty"
grep -Fq '| Source proposal SHA-256 | — |' "$direct_project/agreement/AGREEMENT.md" || fail "direct source checksum is not empty"
grep -Fq '| Source proposal status | — |' "$direct_project/agreement/AGREEMENT.md" || fail "direct source status is not empty"
bash "$AGREEMENT" verify "$direct_project" >/dev/null
expect_die bash "$AGREEMENT" init "$direct_project" "2026-08-10"

# Agreement status's documented invoice handoff is directly executable with the resolved root.
bash "$INVOICE" init "$direct_project" "Direct Engagement" USD monthly 1000.00 none "user input" 2026-08-09 >/dev/null
invoice_status=$(bash "$INVOICE" status "$direct_project")
printf '%s\n' "$invoice_status" | grep -Fq 'currency=USD' || fail "agreement invoice status handoff did not execute"
printf '%s\n' "$invoice_status" | grep -Fq 'total=0.00' || fail "agreement invoice status handoff did not return totals"

echo "✓ agreement requires accepted proposal promotion and supports direct initialization"
