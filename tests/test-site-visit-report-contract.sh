#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/site-visit-report/SKILL.md"
README="skills/site-visit-report/README.md"
TEMPLATE="skills/site-visit-report/templates/site-visit-report.md"
RULE="rules/professional-disclaimer.md"
LINT="scripts/lint.sh"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing site-visit-report file: $file" >&2; exit 1; }
done

grep -q '^name: site-visit-report$' "$SKILL"
grep -q 'site-reports/YYYY-MM-DD-<descriptive-slug>.md' "$SKILL"
grep -q 'skills/project/references/context-resolution.md' "$SKILL"
grep -q 'Stop on `invalid`, `no-projects`, or `no-context`' "$SKILL"
grep -q 'direct observations, participant-reported information, interpretation, issues, and proposed follow-ups separate' "$SKILL"
grep -q 'Reported; not independently verified' "$SKILL"
grep -q 'contractor statement that a wall is non-load-bearing remains participant-reported and unverified' "$SKILL"
grep -q 'An inaccessible or concealed area is `Not observed`, never “no issue observed.”' "$SKILL"
grep -q 'Do not claim concealed-condition certainty' "$SKILL"
grep -q 'Do not claim compliance' "$SKILL"
grep -q 'Saving must not create or modify `PROJECT.md`, `decisions/\*.md`, or `TASKS.md`' "$SKILL"
grep -q 'approval of the report as a whole is not promotion approval' "$SKILL"
grep -q 'Do not promote unselected siblings' "$SKILL"
grep -q 'next available suffix: `-02`, `-03`' "$SKILL"
grep -q 'search the owning record for the same project-relative report link and item label' "$SKILL"
grep -q 'offer link/update/new' "$SKILL"
grep -q 'purely internal administrative draft.*may omit it' "$SKILL"
grep -q 'client-facing, authority-facing, issued externally' "$SKILL"
grep -q '> \*\*Disclaimer:\*\* This is an AI-generated analysis for preliminary planning purposes' "$SKILL"
grep -q '<!-- architecture-studio:requires-disclaimer -->' "$SKILL"

for heading in Participants 'Visit Scope' 'Direct Observations' 'Participant-Reported Information' Interpretation 'Photographs and Files' 'Access and Visibility Limitations' 'Issues Requiring Review' 'Proposed Follow-Ups' Disclaimer; do
  grep -q "^## $heading$" "$TEMPLATE" || { echo "missing site report template heading: $heading" >&2; exit 1; }
done

for field in 'Visit date' Created Updated 'Project / location' 'Visit purpose' Conditions 'Prepared from' 'Revision note'; do
  grep -q "\*\*$field:\*\*" "$TEMPLATE" || { echo "missing site report template field: $field" >&2; exit 1; }
done

grep -q '^### O1 —' "$TEMPLATE"
grep -q '^### R1 —' "$TEMPLATE"
grep -q '^### I1 —' "$TEMPLATE"
grep -q '^### ISS1 —' "$TEMPLATE"
grep -q '^### F1 —' "$TEMPLATE"
grep -q 'not independently verified' "$TEMPLATE"
grep -q 'not yet recorded in `TASKS.md`' "$TEMPLATE"

# The repository lint validates that conditional-output skills carry the marker
# instruction. It does not force every internal report artifact to emit it.
grep -A20 '^REGULATORY_SKILLS=' "$LINT" | grep -q '^site-visit-report$'
grep -q 'Purely internal administrative site-visit drafts' "$RULE"
grep -q 'Omission never permits a site report to claim concealed-condition certainty' "$RULE"

echo "✓ site-visit-report contract preserves field evidence and conditional disclaimer policy"
