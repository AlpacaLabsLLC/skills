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
for command in init promote check amend status verify; do
  grep -q "/as:agreement $command" "$SKILL" || { echo "missing command: $command"; exit 1; }
done

# Ownership, direct engagements, and proposal-promotion boundaries.
grep -q 'only writer of `agreement/`' "$SKILL"
grep -q 'never writes.*proposals/' "$SKILL"
grep -q 'does not copy.*proposal\|proposal.*not copied' "$SKILL"
grep -q 'never inferred, never invented' "$SKILL"
grep -q 'Promotion requires.*accepted\|requires.*accepted proposal' "$SKILL"
grep -q 'Direct.*without a proposal\|without a proposal.*direct' "$SKILL"
grep -q 'never changes project status' "$SKILL"
! grep -q 'PROPOSALS.md\|proposal number\|<number>' "$SKILL"

# Advisory scope guard.
grep -q 'Verdicts are advisory' "$SKILL"
grep -q 'in-scope' "$SKILL"
grep -q 'needs-SOW' "$SKILL"
grep -q 'out-of-scope' "$SKILL"
grep -q 'it never blocks, and the user always decides' "$SKILL"

for heading in '### In scope' '### Not in scope' '### Requires SOW'; do
  grep -q "^$heading\$" "$TEMPLATE" || { echo "missing template heading: $heading"; exit 1; }
done
grep -q '<!-- amendments:start -->' "$TEMPLATE"
grep -q '| Format version | 2 |' "$TEMPLATE"
grep -q '| Source proposal | {{PROPOSAL_PATH}} |' "$TEMPLATE"
grep -q '| Source proposal SHA-256 | {{PROPOSAL_CHECKSUM}} |' "$TEMPLATE"
grep -q '| Source proposal status | {{PROPOSAL_STATUS}} |' "$TEMPLATE"
! grep -q 'ACCEPTED_FILE\|PROPOSAL_NUMBER' "$TEMPLATE"

grep -q 'resolve-context.sh' "$SKILL"
grep -q 'refuses a second promotion' "$SKILL"
grep -q 'Read `agreement/AGREEMENT.md` before committing to new work; flag out-of-scope requests.' "$SKILL"
grep -q 'never recompute them' "$SKILL"
grep -Fq '<plugin-root>/skills/invoice/scripts/invoice-ledger.sh status <project-root>' "$SKILL"
! grep -q '~[/]' "$SKILL"

echo "✓ /as:agreement cites protected proposal terms as optional context and keeps scope verdicts advisory"
