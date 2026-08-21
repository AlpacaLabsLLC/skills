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
grep -q 'YYYY-MM-CCC-PROJECT-NAME' "$SKILL"
grep -q 'immutable' "$SKILL"
grep -q 'Do not prefix the project display name or project-name slug with the client name' "$SKILL"
grep -q 'internal.*three-letter.*code\|three-letter.*code.*internal' "$SKILL"
grep -q 'internal.*client' "$SKILL"
grep -q 'status.*advisory\|advisory.*status' "$SKILL"
grep -q 'known structured references' "$SKILL"
grep -q 'restore.*backup\|backup.*restore' "$SKILL"

grep -q '\[decisions/\](decisions/)' "$TEMPLATE"
! grep -q '^## Decisions$' "$TEMPLATE"
grep -Fq '| Format version | 3 |' "$TEMPLATE"
grep -Fq '| Type | {{PROJECT_TYPE}} |' "$TEMPLATE"
grep -Fq '| Status | {{PROJECT_STATUS}} |' "$TEMPLATE"
grep -Fq '| Client code | {{CLIENT_CODE}} |' "$TEMPLATE"
! grep -Eq '^## (Site|Zoning|Program|Code)$' "$TEMPLATE"
grep -Fxq '@AGENTS.md' skills/project/templates/CLAUDE.md
! grep -Fq 'Read `PROJECT.md` before project work' skills/project/templates/CLAUDE.md
grep -Fq 'Before making scope commitments, read `agreement/AGREEMENT.md` when it exists.' skills/project/templates/AGENTS.md
grep -Fq 'For commercial work, discover the project-local `proposals/`, `agreement/`, and `INVOICES.md` records read-only before acting.' skills/project/templates/AGENTS.md

# Commercial records: status relays agreement term and cap read-only; ownership handoffs are named
grep -q 'agreement/AGREEMENT.md' skills/project/SKILL.md
grep -q 'never recompute its numbers' skills/project/SKILL.md
grep -q '`/as:proposal` owns project-local `proposals/`' skills/project/SKILL.md

grep -q 'type and status' skills/project/references/context-resolution.md
grep -q 'never block' skills/project/references/context-resolution.md
grep -q '`standards/` contains firm-wide standards and reusable templates' skills/project/references/context-resolution.md
grep -q '`references/` contains external source material such as code references' skills/project/references/context-resolution.md
grep -q 'Canonical singleton records use uppercase names' docs/workspace-model.md
grep -q 'Directories and individual repeatable records use lowercase kebab-case' docs/workspace-model.md
grep -q 'YYYY-MM-short-title-proposal-rev-NN.md' docs/workspace-model.md
grep -q 'do not enforce a proposal, agreement, invoice, or project-status sequence' docs/workspace-model.md

echo "✓ /project defines universal v3 identity, advisory context, and recoverable migration"
