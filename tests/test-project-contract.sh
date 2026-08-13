#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/project/SKILL.md"
README="skills/project/README.md"
TEMPLATE="skills/project/templates/PROJECT.md"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing project contract file: $file" >&2; exit 1; }
done

grep -q '^name: project$' "$SKILL"
for command in init status update remember decisions record-decision supersede migrate; do
  grep -q "/as:project $command" "$SKILL" || { echo "missing namespaced project command: $command" >&2; exit 1; }
done

grep -q 'only project-memory interface' "$SKILL"
grep -q 'Never write `STUDIO.md`' "$SKILL"
grep -q 'no Decisions table' "$SKILL"
grep -q 'Classify each item as fact-like, decision-like, or mixed' "$SKILL"
grep -q 'Preview grouped destinations' "$SKILL"
grep -q 'Discover `decisions/\*.md` independently' "$SKILL"
grep -q 'max parseable number + 1' "$SKILL"
grep -q 'create and verify the replacement first' "$SKILL"
grep -q 'Migration removes the legacy Decisions table only when it is lossless' "$SKILL"
grep -q 'PROJECT.md` is the only implicit project boundary' "$SKILL"
grep -q 'exact created path plus the `.agents/skills/`.*`.claude/skills/`' "$SKILL"

grep -q '\[decisions/\](decisions/)' "$TEMPLATE"
! grep -q '^## Decisions$' "$TEMPLATE"

# Commercial records: status relays agreement term and cap read-only; ownership handoffs are named
grep -q 'agreement/AGREEMENT.md' skills/project/SKILL.md
grep -q 'never recompute its numbers' skills/project/SKILL.md
grep -q '`/as:proposal` owns `PROPOSALS.md`' skills/project/SKILL.md

echo "✓ /project unifies setup, facts, decisions, and lossless migration"
