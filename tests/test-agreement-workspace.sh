#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
PROPOSAL="$PWD/skills/proposal/scripts/proposal-register.sh"
AGREEMENT="$PWD/skills/agreement/scripts/agreement-workspace.sh"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
studio="$root/studio"
project="$studio/projects/alpha"
mkdir -p "$project"

fail() { echo "FAIL: $*"; exit 1; }
expect_die() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi }

bash "$PROPOSAL" init "$studio" "Test Studio" "TS" >/dev/null
bash "$PROPOSAL" create "$studio" "projects/alpha/proposals" "alpha" "Acme Corp" "Design Services" "design-services" "2026-08-06" >/dev/null
ACCEPTED_PATH="projects/alpha/proposals/TS-0001-design-services.md"

# promote refuses a non-accepted proposal
expect_die bash "$AGREEMENT" promote "$project" "$studio" TS-0001 "$ACCEPTED_PATH" "Alpha" "2026-08-06"
bash "$PROPOSAL" set-status "$studio" TS-0001 sent >/dev/null
expect_die bash "$AGREEMENT" promote "$project" "$studio" TS-0001 "$ACCEPTED_PATH" "Alpha" "2026-08-06"

# promote works once accepted
bash "$PROPOSAL" set-status "$studio" TS-0001 accepted >/dev/null
bash "$AGREEMENT" promote "$project" "$studio" TS-0001 "$ACCEPTED_PATH" "Alpha" "2026-08-06" >/dev/null
[ -f "$project/agreement/AGREEMENT.md" ] || fail "AGREEMENT.md missing"
[ -f "$project/agreement/TS-0001-design-services.md" ] || fail "accepted copy missing"
[ -d "$project/agreement/sow" ] || fail "sow dir missing"
grep -q '| Accepted proposal | TS-0001 |' "$project/agreement/AGREEMENT.md" || fail "identity row"

# double promotion refused; copied document never overwritten
expect_die bash "$AGREEMENT" promote "$project" "$studio" TS-0001 "$ACCEPTED_PATH" "Alpha" "2026-08-06"
before=$(cat "$project/agreement/TS-0001-design-services.md")
expect_die bash "$AGREEMENT" promote "$project" "$studio" TS-0001 "$ACCEPTED_PATH" "Alpha" "2026-08-07"
[ "$before" = "$(cat "$project/agreement/TS-0001-design-services.md")" ] || fail "accepted copy mutated"

# amendment requires the document to exist first, then appends atomically
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "Extra facade study" "2026-09-01"
printf '# SOW 2\n' > "$project/agreement/sow/sow-2.md"
bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "Extra facade study" "2026-09-01" >/dev/null
grep -q '| 1 | 2026-09-01 | \[sow-2.md\](sow/sow-2.md) | Extra facade study |' "$project/agreement/AGREEMENT.md" || fail "amendment row"
printf '# SOW 3\n' > "$project/agreement/sow/sow-3.md"
bash "$AGREEMENT" record-amendment "$project" "sow-3.md" "Interior package" "2026-10-01" >/dev/null
grep -q '| 2 | 2026-10-01 |' "$project/agreement/AGREEMENT.md" || fail "amendment numbering"

# path traversal refused
expect_die bash "$AGREEMENT" record-amendment "$project" "../evil.md" "x" "2026-10-02"

# verify passes clean, flags a missing amendment file, never repairs
bash "$AGREEMENT" verify "$project" >/dev/null
rm "$project/agreement/sow/sow-3.md"
if bash "$AGREEMENT" verify "$project" >/dev/null 2>&1; then fail "verify missed missing amendment"; fi
grep -q '| 2 | 2026-10-01 |' "$project/agreement/AGREEMENT.md" || fail "verify must not remove rows"

# malformed agreement blocks mutation
sed -i.bak 's/| Format version | 2 |/| Format version | 1 |/' "$project/agreement/AGREEMENT.md" && rm "$project/agreement/AGREEMENT.md.bak"
expect_die bash "$AGREEMENT" record-amendment "$project" "sow-2.md" "again" "2026-11-01"

echo "✓ agreement workspace promotes only accepted proposals, keeps documents append-only, and records amendments atomically"
