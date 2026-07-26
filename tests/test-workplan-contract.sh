#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/workplan/SKILL.md"
README="skills/workplan/README.md"
TEMPLATE="skills/workplan/templates/plan.md"
PROJECT="skills/project/SKILL.md"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing workplan file: $file" >&2; exit 1; }
done

grep -q '^name: workplan$' "$SKILL"
grep -q 'Do not use for floor plans, site plans, space planning' "$SKILL"
grep -q '\*\*The plan is the deliverable. Do not execute it.\*\*' "$SKILL"
grep -q 'Use available capabilities, never require them' "$SKILL"
grep -q 'AGENTS.md.*\.codex' "$SKILL"
grep -q 'meetings/.*site-reports/.*decisions/.*TASKS.md.*TIMELOG.md' "$SKILL"
grep -q 'skills/project/references/context-resolution.md' "$SKILL"
grep -q 'cannot become an implicit project root' "$SKILL"
grep -q 'Never overwrite a plan implicitly' "$SKILL"
grep -q '^## Step 4 — Resolve AEC dependencies$' "$SKILL"
grep -q '/as:zoning-analysis-nyc' "$SKILL"
grep -q '/as:workplace-programmer' "$SKILL"
grep -q '/as:occupancy-calculator' "$SKILL"
grep -q 'Do not invent the missing technical conclusion' "$SKILL"
grep -q 'required input, its expected output, and which work unit depends on it' "$SKILL"
grep -q '^## Step 7 — Validate$' "$SKILL"
grep -q '^## Step 8 — Hand off$' "$SKILL"
grep -q "Do not begin execution without the user's direction" "$SKILL"
grep -q 'Import selected work units or action items with `/as:tasklist`' "$SKILL"
grep -q 'optional and item-level' "$SKILL"
grep -q 'Never create or modify `TASKS.md` merely because a plan was saved or approved' "$SKILL"
grep -q '/as:tasklist import <project-relative-plan-path>#<W-ID>' "$SKILL"
grep -q '^## Professional boundary$' "$SKILL"
grep -q 'might submit to a client or authority does require it' "$SKILL"
grep -q '<!-- architecture-studio:requires-disclaimer -->' "$SKILL"
grep -q 'read `PROJECT.md` for established facts, then discover relevant `decisions/\*.md` directly' "$SKILL"
grep -q 'discover relevant `decisions/\*.md` directly' "$SKILL"
grep -q '`decided` is a current constraint' "$SKILL"
grep -q '`proposed` is an unresolved dependency' "$SKILL"
grep -q '`superseded by NNNN` is historical context only' "$SKILL"
grep -q 'Missing or unrecognized status is malformed' "$SKILL"
grep -q 'duplicate numbers, status disagreements' "$SKILL"
grep -qi 'do not interpret a parse failure as' "$SKILL"
grep -q 'State every path inspected and any path that could not be parsed' "$SKILL"
grep -q 'project-relative Markdown links plus a heading or stable item ID' "$SKILL"

for heading in Outcome 'Problem Frame' Scope 'Evidence Reviewed' Requirements 'Known Facts' Assumptions Decisions 'Work Units' 'Dependencies and Risks' 'Open Questions' 'Definition of Done'; do
  grep -q "^## $heading$" "$TEMPLATE" || { echo "missing template heading: $heading" >&2; exit 1; }
done

for field in Created Status 'Planning mode' Depth Produces 'Depends on' Covers 'Governed by' 'Work boundary' Verification; do
  grep -q "$field" "$TEMPLATE" || { echo "missing template field: $field" >&2; exit 1; }
done
grep -q '^### Included$' "$TEMPLATE"
grep -q '^### Excluded$' "$TEMPLATE"
grep -q '\*\*R1 —\*\*' "$TEMPLATE"
grep -q '\*\*A1 —\*\*' "$TEMPLATE"
grep -q '^### D1 —' "$TEMPLATE"
grep -q '^### W1 —' "$TEMPLATE"
grep -q '\*\*Source:\*\*' "$TEMPLATE"
grep -q '\*\*Sources:\*\*' "$TEMPLATE"

grep -q 'A nearer project inside a monorepo wins' "$PROJECT"
grep -q 'project-relative' "$PROJECT"
grep -qi 'malformed' "$PROJECT"
grep -q 'never reuse a number because another record is malformed' "$PROJECT"
grep -q 'A proposed source item remains proposed' "$PROJECT"
grep -q 'Preview the complete record' "$PROJECT"
grep -q 'create and verify the replacement first' "$PROJECT"
grep -q 'report the exact partial state' "$PROJECT"
grep -q 'require its exact project-relative path and stable item label' "$PROJECT"
grep -q 'preserve its epistemic status' "$PROJECT"
grep -q 'Preview grouped destinations' "$PROJECT"

grep -q '^## Cross-record project conventions$' PATTERNS.md
grep -q 'A parse failure means unknown, not absent and not approved' PATTERNS.md

grep -q '/as:workplan' README.md
grep -q '/as:workplan' skills/tool-catalog/SKILL.md
grep -q '/as:workplan' skills/studio/SKILL.md
grep -q '^## Task routing$' skills/studio/SKILL.md
grep -q 'Explicit work plan.*`/as:workplan`' skills/studio/SKILL.md

echo "✓ workplan contract preserves planning, AEC, portability, and handoff boundaries"
