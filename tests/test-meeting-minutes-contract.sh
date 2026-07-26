#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/meeting-minutes/SKILL.md"
README="skills/meeting-minutes/README.md"
TEMPLATE="skills/meeting-minutes/templates/meeting-minutes.md"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing meeting-minutes file: $file" >&2; exit 1; }
done

grep -q '^name: meeting-minutes$' "$SKILL"
grep -q 'meetings/YYYY-MM-DD-slug.md' "$SKILL"
grep -q 'skills/project/references/context-resolution.md' "$SKILL"
grep -q 'Stop on `invalid`, `no-projects`, or `no-context`' "$SKILL"
grep -q 'Save before promotion' "$SKILL"
grep -q 'Saving must not create or modify `PROJECT.md`, `decisions/\*.md`, or `TASKS.md`' "$SKILL"
grep -q 'require the user to select each fact, decision, or task' "$SKILL"
grep -q 'approval of the minutes as a whole is not item-level selection' "$SKILL"
grep -q 'Do not promote unselected siblings' "$SKILL"
grep -q 'event date.*artifact creation date.*source/input reference' "$SKILL"
grep -q 'Never infer the event date from filesystem mtime' "$SKILL"
grep -q 'preserve the original event date, \*\*Created\*\* date, and sources' "$SKILL"
grep -q 'next available suffix: `-02`, `-03`' "$SKILL"
grep -q 'Never overwrite merely because the title and date match' "$SKILL"
grep -q 'search the owning record for the same project-relative meeting link and item label' "$SKILL"
grep -q 'offer link/update/new' "$SKILL"
grep -q 'When direct invocation is unavailable' "$SKILL"
grep -q '^/as:project remember selected stated information S2 from meetings/' "$SKILL"
grep -q '^/as:project record-decision selected item CD1 from meetings/' "$SKILL"
grep -q '^/as:tasklist import selected items T1, T3 from meetings/' "$SKILL"
grep -q 'might submit to a client or authority' "$SKILL"
grep -q '<!-- architecture-studio:requires-disclaimer -->' "$SKILL"

for heading in Attendees Agenda Discussion 'Stated Information' 'Confirmed Decisions' 'Proposed Decisions' 'Proposed Tasks' 'Open Questions' Limitations; do
  grep -q "^## $heading$" "$TEMPLATE" || { echo "missing meeting-minutes template heading: $heading" >&2; exit 1; }
done

for field in 'Event date' Created Updated 'Prepared from' 'Revision note'; do
  grep -q "\*\*$field:\*\*" "$TEMPLATE" || { echo "missing meeting-minutes template field: $field" >&2; exit 1; }
done

grep -q '^### S1 —' "$TEMPLATE"
grep -q '^### CD1 —' "$TEMPLATE"
grep -q '^### PD1 —' "$TEMPLATE"
grep -q '^### T1 —' "$TEMPLATE"
grep -q '^### Q1 —' "$TEMPLATE"
grep -q 'not independently verified' "$TEMPLATE"
grep -q 'not yet a durable `/as:project record-decision` record' "$TEMPLATE"
grep -q 'not yet recorded in `TASKS.md`' "$TEMPLATE"

# Static assertions deliberately validate the written contract only. They do not
# claim to execute or prove an LLM's promotion behavior.
echo "✓ meeting-minutes contract preserves typed records and selective promotion"
