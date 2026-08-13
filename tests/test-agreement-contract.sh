#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=skills/agreement/SKILL.md
README=skills/agreement/README.md
SCRIPT=skills/agreement/scripts/agreement-workspace.sh
TEMPLATE=skills/agreement/templates/AGREEMENT.md

for f in "$SKILL" "$README" "$SCRIPT" "$TEMPLATE" skills/agreement/templates/amendment.md; do
  [ -f "$f" ] || { echo "missing contract file: $f"; exit 1; }
done

grep -q '^name: agreement$' "$SKILL"

for command in promote check amend status verify; do
  grep -q "/as:agreement $command" "$SKILL" || { echo "missing command: $command"; exit 1; }
done

# Ownership and boundaries
grep -q 'only writer of `agreement/`' "$SKILL"
grep -q 'never writes `PROPOSALS.md`' "$SKILL"
grep -q 'Accepted documents are append-only' "$SKILL"
grep -q 'never inferred, never invented' "$SKILL"

# Advisory scope guard
grep -q 'Verdicts are advisory' "$SKILL"
grep -q 'in-scope' "$SKILL"
grep -q 'needs-SOW' "$SKILL"
grep -q 'out-of-scope' "$SKILL"
grep -q 'it never blocks, and the user always decides' "$SKILL"
grep -q 'silence in the contract is not permission' "$SKILL"

# Scope block contract in template and skill
for heading in '### In scope' '### Not in scope' '### Requires SOW'; do
  grep -q "^$heading\$" "$TEMPLATE" || { echo "missing template heading: $heading"; exit 1; }
done
grep -q '<!-- amendments:start -->' "$TEMPLATE"
grep -q '| Format version | 2 |' "$TEMPLATE"

# Promotion flow and handoffs
grep -q 'resolve-context.sh' "$SKILL"
grep -q 'refuses a second promotion' "$SKILL"
grep -q 'Read `agreement/AGREEMENT.md` before committing to new work; flag out-of-scope requests.' "$SKILL"
grep -q 'Run `/as:invoice init`' "$SKILL"
grep -q 'never recompute them' "$SKILL"

# No absolute home paths in the body
! grep -q '~/' "$SKILL"

echo "✓ /as:agreement promotes accepted proposals into sourced, append-only contract context with an advisory scope guard"
