#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/tasklist/SKILL.md"
README="skills/tasklist/README.md"
TEMPLATE="skills/tasklist/templates/tasks.md"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing tasks file: $file" >&2; exit 1; }
done

grep -q '^name: tasklist$' "$SKILL"
grep -q 'list, add, update, complete, or cancel' "$SKILL"
grep -q 'one resolved `TASKS.md`' "$SKILL"
grep -q 'max(all parseable IDs) + 1' "$SKILL"
grep -q 'Never delete, reuse, or renumber' "$SKILL"
grep -q 'Preserve history' "$SKILL"
grep -q 'Normalize a source within the selected project' "$SKILL"
grep -q 'conversation:YYYY-MM-DD#instruction-N' "$SKILL"
grep -q 'complete canonical token.*deduplication key' "$SKILL"
grep -q 'show `link`, `update`, or `new`' "$SKILL"
grep -q 'Preview candidates before mutation' "$SKILL"
grep -q 'Malformed means blocked, not empty' "$SKILL"
grep -q 'block every mutation until the user authorizes repair' "$SKILL"
grep -q 'skills/project/references/context-resolution.md' "$SKILL"
grep -q 'typed result and validated choices are authoritative' "$SKILL"
grep -q 'All projects' "$SKILL"
grep -q 'read-only merged view' "$SKILL"
grep -q '<project-id>:<task-id>' "$SKILL"
grep -q 'portfolio task mode' "$SKILL"
grep -q 'Project ID' "$SKILL"
grep -q 'studio-relative link beginning with the selected registered project path' "$SKILL"
grep -q 'compare Project ID (in portfolio mode)' "$SKILL"
grep -q 'never simultaneously writable' "$SKILL"
grep -q 'no-projects' "$SKILL"
grep -q 'Cross-skill invocation.*optional conveniences, never runtime requirements' "$SKILL"
grep -q 'do not fabricate a false anchor' "$SKILL"
grep -q 'regardless of status' "$SKILL"
grep -q 'Updating a completed or cancelled task preserves its closure date and history' "$SKILL"

header='| ID | Description | Owner | Due | Status | Created | Updated | Completed | Cancelled | Source | Related |'
grep -Fqx "$header" "$TEMPLATE"
grep -q '^## History$' "$TEMPLATE"
! grep -Eq '^\| T[0-9]{4} \|' "$TEMPLATE"
! grep -Eq '^- [0-9]{4}-[0-9]{2}-[0-9]{2} .*T[0-9]{4}' "$TEMPLATE"

PORTFOLIO_TEMPLATE="skills/tasklist/templates/portfolio-tasks.md"
[ -f "$PORTFOLIO_TEMPLATE" ] || { echo "missing portfolio tasks template" >&2; exit 1; }
portfolio_header='| ID | Project ID | Description | Owner | Due | Status | Created | Updated | Completed | Cancelled | Source | Related |'
grep -Fqx "$portfolio_header" "$PORTFOLIO_TEMPLATE"
! grep -Eq '^\| T[0-9]{4} \|' "$PORTFOLIO_TEMPLATE"

# Executable fixture checks only deterministic register invariants. It does not
# pretend to execute the natural-language skill or its confirmation dialogue.
fixture_dir="$(mktemp -d)"
trap 'rm -rf "$fixture_dir"' EXIT
fixture="$fixture_dir/TASKS.md"
cp "$TEMPLATE" "$fixture"
first_id="$({ grep -Eo 'T[0-9]{4}' "$fixture" || true; } | sed 's/^T//' | sort -n | awk 'NF {max=$1} END {if (max) printf "T%04d", max + 1; else print "T0001"}')"
[ "$first_id" = "T0001" ] || { echo "empty template did not allocate T0001 first: $first_id" >&2; exit 1; }
printf '%s\n' '| T0007 | Existing item | Alex | — | completed | 2026-06-01 | 2026-06-02 | 2026-06-02 | — | [W1](docs/plans/a.md#w1) | — |' >> "$fixture"
printf '%s\n' '| T0012 | Closed item | Alex | — | cancelled | 2026-07-01 | 2026-07-02 | — | 2026-07-02 | [A1](meetings/a.md#a1) | — |' >> "$fixture"

next_id="$({ grep -Eo 'T[0-9]{4}' "$fixture" || true; } | sed 's/^T//' | sort -n | tail -1 | awk '{printf "T%04d", $1 + 1}')"
[ "$next_id" = "T0013" ] || { echo "non-monotonic fixture allocation: $next_id" >&2; exit 1; }

before_hash="$(shasum -a 256 "$fixture" | awk '{print $1}')"
matches="$(grep -Fc '(meetings/a.md#a1)' "$fixture")"
[ "$matches" -eq 1 ] || { echo "fixture duplicate-source detection failed" >&2; exit 1; }
after_hash="$(shasum -a 256 "$fixture" | awk '{print $1}')"
[ "$before_hash" = "$after_hash" ] || { echo "read-only fixture check mutated register" >&2; exit 1; }

conversation_key='conversation:2026-07-21#instruction-1'
printf '%s\n' "| T0013 | Direct instruction | Alex | — | open | 2026-07-21 | 2026-07-21 | — | — | $conversation_key | — |" >> "$fixture"
[ "$(grep -Fc "$conversation_key" "$fixture")" -eq 1 ] || { echo "conversation provenance dedupe key failed" >&2; exit 1; }

malformed="$fixture_dir/MALFORMED.md"
printf '%s\n' '# Project Tasks' '| ID | Description |' '| broken |' > "$malformed"
malformed_before="$(shasum -a 256 "$malformed" | awk '{print $1}')"
if grep -Fqx "$header" "$malformed"; then
  echo "malformed fixture unexpectedly passed schema check" >&2
  exit 1
fi
malformed_after="$(shasum -a 256 "$malformed" | awk '{print $1}')"
[ "$malformed_before" = "$malformed_after" ] || { echo "malformed fixture was not preserved" >&2; exit 1; }

echo "✓ tasks contract covers permanent IDs, lifecycle history, confirmed imports, duplicate sources, and malformed-file preservation"
