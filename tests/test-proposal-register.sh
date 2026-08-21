#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="$PWD/skills/proposal/scripts/proposal-workspace.sh"

root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
project="$root/2026-08-ACM-DESIGN-SERVICES"
mkdir -p "$project"
printf '# Project — Design Services\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 3 | setup | 2026-08-06 |\n| Project ID | 2026-08-ACM-DESIGN-SERVICES | setup | 2026-08-06 |\n| Project | Design Services | setup | 2026-08-06 |\n| Type | client | setup | 2026-08-06 |\n| Status | prospective | setup | 2026-08-06 |\n| Created | 2026-08-06 | setup | 2026-08-06 |\n| Client code | ACM | setup | 2026-08-06 |\n| Client | Acme Corp | setup | 2026-08-06 |\n' > "$project/PROJECT.md"

fail() { echo "FAIL: $*"; exit 1; }
expect_die() { if "$@" >/dev/null 2>&1; then fail "expected failure: $*"; fi; }

# Creation is project-local, collision-safe, and uses a user-confirmed revision.
bash "$SCRIPT" create "$project" "Acme Corp" "Design Services" "design-services" "2026-08-06" rev-01 >/dev/null
proposal="$project/proposals/2026-08-design-services-proposal-rev-01.md"
[ -f "$proposal" ] || fail "proposal file missing"
[ ! -e "$project/PROPOSALS.md" ] || fail "project-wide proposal register must not exist"
[ ! -e "$root/PROPOSALS.md" ] || fail "studio-wide proposal register must not exist"
grep -Fq '# Proposal — Design Services' "$proposal" || fail "title not rendered"
grep -Fq '| Project ID | 2026-08-ACM-DESIGN-SERVICES |' "$proposal" || fail "project identity missing"
grep -Fq '| Short title | design-services |' "$proposal" || fail "short title missing"
grep -Fq '| Revision | Rev. 01 |' "$proposal" || fail "revision missing"
grep -Fq '<!-- issued-terms:start -->' "$proposal" || fail "issued terms start marker missing"
grep -Fq '<!-- issued-terms:end -->' "$proposal" || fail "issued terms end marker missing"
grep -Fq '<!-- proposal-lifecycle:start -->' "$proposal" || fail "lifecycle start marker missing"

before=$(shasum "$proposal" | awk '{print $1}')
expect_die bash "$SCRIPT" create "$project" "Acme Corp" "Design Services" "design-services" "2026-08-06" rev-01
[ "$before" = "$(shasum "$proposal" | awk '{print $1}')" ] || fail "collision changed existing proposal"
expect_die bash "$SCRIPT" create "$project" "Acme Corp" "Bad" "Bad_Slug" "2026-08-06" rev-01
expect_die bash "$SCRIPT" create "$project" "Acme Corp" "Bad" "bad" "2026-13-06" rev-01
expect_die bash "$SCRIPT" create "$project" "Acme Corp" "Bad" "bad" "2026-08-06" r01
expect_die bash "$SCRIPT" create "$project" "Acme Corp" "Bad" "bad" "2026-08-06" 1

# Creation publishes only a fully rendered and validated temporary proposal.
# Render or validation failure leaves no canonical file or temporary artifact,
# and the same command can be retried safely.
for create_failure in create-render-failure create-invalid-temp; do
  case "$create_failure" in
    create-render-failure) retry_slug=render-retry; retry_title="Render Retry" ;;
    create-invalid-temp) retry_slug=validation-retry; retry_title="Validation Retry" ;;
  esac
  retry_target="$project/proposals/2026-08-$retry_slug-proposal-rev-01.md"
  expect_die env ARCH_PROPOSAL_FAIL_AT="$create_failure" bash "$SCRIPT" create "$project" "Acme Corp" "$retry_title" "$retry_slug" "2026-08-06" rev-01
  [ ! -e "$retry_target" ] && [ ! -L "$retry_target" ] || fail "$create_failure published a canonical proposal"
  [ -z "$(find "$project/proposals" -maxdepth 1 -name '.proposal-create.*' -print)" ] || fail "$create_failure left a temporary proposal"
  bash "$SCRIPT" create "$project" "Acme Corp" "$retry_title" "$retry_slug" "2026-08-06" rev-01 >/dev/null
  [ -f "$retry_target" ] || fail "$create_failure retry did not create the proposal"
done

# Lifecycle writes are confined to the Record section, including when protected
# issued terms happen to contain rows with reserved Record field names.
bash "$SCRIPT" create "$project" "Acme Corp" "Protected Fields" "protected-fields" "2026-08-06" rev-01 >/dev/null
protected="$project/proposals/2026-08-protected-fields-proposal-rev-01.md"
awk '
  /^<!-- issued-terms:end -->$/ && !added {
    print "| Status | issued-term status text |"
    print "| Issued terms SHA-256 | issued-term checksum text |"
    print "| Frozen on | issued-term date text |"
    added=1
  }
  { print }
' "$protected" > "$protected.with-fields"
mv "$protected.with-fields" "$protected"
protected_terms_before=$(sed -n '/^<!-- issued-terms:start -->$/,/^<!-- issued-terms:end -->$/p' "$protected")
bash "$SCRIPT" send "$protected" "2026-08-07" "Federico" "email" >/dev/null
[ "$protected_terms_before" = "$(sed -n '/^<!-- issued-terms:start -->$/,/^<!-- issued-terms:end -->$/p' "$protected")" ] || fail "lifecycle update changed issued terms"

# A generated lifecycle update is validated before replacement; failure leaves
# the canonical proposal byte-for-byte unchanged.
protected_before=$(shasum "$protected" | awk '{print $1}')
expect_die env ARCH_PROPOSAL_FAIL_AT=lifecycle-invalid-temp bash "$SCRIPT" set-status "$protected" accepted "2026-08-08" "Acme Corp" "signed PDF"
[ "$protected_before" = "$(shasum "$protected" | awk '{print $1}')" ] || fail "failed lifecycle validation changed canonical proposal"

# Sending freezes the issued terms but leaves lifecycle metadata editable.
bash "$SCRIPT" send "$proposal" "2026-08-07" "Federico" "email" >/dev/null
grep -Fq '| Status | sent |' "$proposal" || fail "sent status missing"
checksum=$(awk -F'|' '/^\| Issued terms SHA-256 / {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' "$proposal")
printf '%s\n' "$checksum" | grep -Eq '^[0-9a-f]{64}$' || fail "issued checksum missing"
grep -Fq '| sent | 2026-08-07 | Federico | email | — |' "$proposal" || fail "sent lifecycle event missing"
bash "$SCRIPT" verify "$project" >/dev/null

# Changes outside the protected block are allowed and do not alter the checksum.
printf '\nInternal follow-up note.\n' >> "$proposal"
bash "$SCRIPT" verify "$project" >/dev/null
[ "$checksum" = "$(awk -F'|' '/^\| Issued terms SHA-256 / {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' "$proposal")" ] || fail "lifecycle edit changed checksum"

# Changes inside the protected block are detected and never silently re-frozen.
cp "$proposal" "$root/proposal-before-tamper.md"
sed -i.bak 's/\[TO CONFIRM: exclusions\]/changed after issue/' "$proposal" && rm "$proposal.bak"
expect_die bash "$SCRIPT" verify "$project"
tampered=$(shasum "$proposal" | awk '{print $1}')
expect_die bash "$SCRIPT" send "$proposal" "2026-08-08" "Federico" "email"
[ "$tampered" = "$(shasum "$proposal" | awk '{print $1}')" ] || fail "failed re-send mutated tampered proposal"
mv "$root/proposal-before-tamper.md" "$proposal"

# Acceptance may freeze a draft directly: ordering is the user's responsibility.
bash "$SCRIPT" create "$project" "Acme Corp" "Additional Services" "additional-services" "2026-08-09" rev-01 >/dev/null
accepted="$project/proposals/2026-08-additional-services-proposal-rev-01.md"
bash "$SCRIPT" set-status "$accepted" accepted "2026-08-10" "Acme Corp" "signed PDF" >/dev/null
grep -Fq '| Status | accepted |' "$accepted" || fail "accepted status missing"
accepted_checksum=$(awk -F'|' '/^\| Issued terms SHA-256 / {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' "$accepted")
printf '%s\n' "$accepted_checksum" | grep -Eq '^[0-9a-f]{64}$' || fail "acceptance did not freeze terms"
grep -Fq '| accepted | 2026-08-10 | Acme Corp | signed PDF | — |' "$accepted" || fail "acceptance evidence missing"

# Lifecycle status is recorded without enforcing a business sequence.
bash "$SCRIPT" set-status "$accepted" declined "2026-08-11" "Acme Corp" "changed direction" >/dev/null
grep -Fq '| Status | declined |' "$accepted" || fail "user-directed status missing"
bash "$SCRIPT" set-status "$accepted" superseded "2026-08-12" "Federico" "replacement issued" "proposals/2026-08-design-services-proposal-rev-01.md" >/dev/null
grep -Fq '| superseded | 2026-08-12 | Federico | replacement issued | proposals/2026-08-design-services-proposal-rev-01.md |' "$accepted" || fail "related proposal missing"
expect_die bash "$SCRIPT" set-status "$accepted" paid "2026-08-12"

# Read-only commands discover local files; verification reports malformed records without repair.
list_output=$(bash "$SCRIPT" list "$project")
printf '%s\n' "$list_output" | grep -Fq $'proposals/2026-08-design-services-proposal-rev-01.md\tsent'
status_output=$(bash "$SCRIPT" status "$accepted")
printf '%s\n' "$status_output" | grep -Fq $'status\tsuperseded'
printf '%s\n' "$status_output" | grep -Fq $'revision\tRev. 01'
bash "$SCRIPT" verify "$project" >/dev/null
before=$(shasum "$accepted" | awk '{print $1}')
sed -i.bak '/<!-- issued-terms:end -->/d' "$accepted" && rm "$accepted.bak"
expect_die bash "$SCRIPT" verify "$project"
[ "$before" != "$(shasum "$accepted" | awk '{print $1}')" ] || fail "malformation setup failed"

# A same-path legacy migration that fails verification preserves its only source.
same_path="$project/proposals/2026-08-same-path-proposal-rev-01.md"
printf '# Legacy same-path proposal\n\nOnly source terms.\n\n<!-- issued-terms:end -->\n' > "$same_path"
cp "$same_path" "$root/same-path-before.md"
expect_die bash "$SCRIPT" migrate-legacy "$same_path" "$project" TS-0099 "Acme Corp" "Same Path" "2026-08-15" accepted same-path rev-01 --apply
[ -f "$same_path" ] || fail "failed same-path migration deleted its only source"
cmp -s "$same_path" "$root/same-path-before.md" || fail "failed same-path migration changed its only source"

# Legacy migration refuses a project whose owned proposals directory is a
# symlink, in both preview and apply modes.
symlink_project="$root/2026-08-ACM-SYMLINKED-PROPOSALS"
external_proposals="$root/external-proposals"
mkdir -p "$symlink_project" "$external_proposals"
sed 's/2026-08-ACM-DESIGN-SERVICES/2026-08-ACM-SYMLINKED-PROPOSALS/g; s/Design Services/Symlinked Proposals/g' "$project/PROJECT.md" > "$symlink_project/PROJECT.md"
ln -s "$external_proposals" "$symlink_project/proposals"
symlink_legacy="$external_proposals/TS-0100-linked.md"
printf '# Legacy linked proposal\n\nOnly source terms.\n' > "$symlink_legacy"
symlink_before=$(shasum "$symlink_legacy" | awk '{print $1}')
expect_die bash "$SCRIPT" migrate-legacy "$symlink_legacy" "$symlink_project" TS-0100 "Acme Corp" "Linked" "2026-08-15" draft linked rev-01
expect_die bash "$SCRIPT" migrate-legacy "$symlink_legacy" "$symlink_project" TS-0100 "Acme Corp" "Linked" "2026-08-15" draft linked rev-01 --apply
[ "$symlink_before" = "$(shasum "$symlink_legacy" | awk '{print $1}')" ] || fail "rejected symlink migration changed source"
[ ! -e "$external_proposals/2026-08-linked-proposal-rev-01.md" ] || fail "rejected symlink migration created target"

# A lifecycle date is recorded only when the migration caller provides a
# confirmed date explicitly.
dated_legacy="$project/proposals/TS-0101-dated.md"
printf '# Legacy dated proposal\n\nIssued terms.\n' > "$dated_legacy"
bash "$SCRIPT" migrate-legacy "$dated_legacy" "$project" TS-0101 "Acme Corp" "Dated" "2026-08-15" sent dated rev-01 --migration-date "2026-08-16" --apply >/dev/null
dated_migrated="$project/proposals/2026-08-dated-proposal-rev-01.md"
grep -Fq '| sent | 2026-08-16 | legacy migration | legacy number TS-0101 | — |' "$dated_migrated" || fail "explicit migration date was not retained"

echo "✓ project-local proposals use date/title/revision names and checksum-protected issued terms"
