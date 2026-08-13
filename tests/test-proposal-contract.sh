#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL=skills/proposal/SKILL.md
README=skills/proposal/README.md
SCRIPT=skills/proposal/scripts/proposal-register.sh
TC=skills/proposal/references/tc-library.md

for f in "$SKILL" "$README" "$SCRIPT" "$TC" \
  skills/proposal/templates/PROPOSALS.md \
  skills/proposal/templates/proposal.md \
  skills/proposal/templates/proposal-letter.html; do
  [ -f "$f" ] || { echo "missing contract file: $f"; exit 1; }
done

grep -q '^name: proposal$' "$SKILL"

for command in create list status send accept decline supersede verify; do
  grep -q "/as:proposal $command" "$SKILL" || { echo "missing command: $command"; exit 1; }
done

# Ownership and boundaries
grep -q 'only writer of `PROPOSALS.md`' "$SKILL"
grep -q 'never writes `STUDIO.md`' "$SKILL"
grep -q 'Numbers are never reused or renumbered' "$SKILL"
grep -q 'superseded by {PREFIX}-{NNNN}' "$SKILL"
grep -q 'resolve-context.sh' "$SKILL"
grep -q 'Never reimplement resolution' "$SKILL"
grep -q 'Malformed means blocked, not empty' "$SKILL"

# Acceptance handoff
grep -q 'Run `/as:agreement promote <number>`' "$SKILL"

# Legal caution, verbatim in skill, library, and rendered template
CAUTION='These clauses are drafting guidance, not legal advice; have a licensed attorney review before signing.'
grep -qF "$CAUTION" "$SKILL"
grep -qF "$CAUTION" "$TC"
grep -q 'drafting guidance, not legal advice' skills/proposal/templates/proposal.md

# Register template contract
grep -q '<!-- proposals:start -->' skills/proposal/templates/PROPOSALS.md
grep -q '<!-- proposals:end -->' skills/proposal/templates/PROPOSALS.md
grep -q '| Format version | 2 |' skills/proposal/templates/PROPOSALS.md
grep -q '| Proposal prefix | {{PROPOSAL_PREFIX}} |' skills/proposal/templates/PROPOSALS.md

# The markdown record stays canonical; HTML is export only
grep -q 'the register always points at the `.md`' "$SKILL"

# No absolute home paths in the body
! grep -q '~/' "$SKILL"

echo "✓ /as:proposal owns a single register with permanent numbers, caution-carrying terms, and an agreement handoff"
