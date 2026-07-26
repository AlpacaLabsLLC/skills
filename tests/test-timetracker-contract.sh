#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/timetracker/SKILL.md"
README="skills/timetracker/README.md"
TEMPLATE="skills/timetracker/templates/timelog.md"

for file in "$SKILL" "$README" "$TEMPLATE"; do
  [ -f "$file" ] || { echo "missing timetracker file: $file" >&2; exit 1; }
done

grep -q '^name: timetracker$' "$SKILL"
grep -q 'Never infer hours, start/stop times, billing status, or completeness' "$SKILL"
grep -q 'Every duration comes from the user' "$SKILL"
grep -q 'Candidate rows always show a blank Hours field' "$SKILL"
grep -q 'Preview before mutation' "$SKILL"
grep -q 'Corrections are new rows that reference the original entry' "$SKILL"
grep -q 'highest parseable existing E-number plus one' "$SKILL"
grep -q 'outer search boundary, not the automatic winner' "$SKILL"
grep -q 'A nearer marker inside a monorepo takes precedence' "$SKILL"
grep -q 'Git is optional' "$SKILL"
for source in 'docs/plans/\*.md' 'decisions/\*.md' 'meetings/\*.md' 'site-reports/\*.md' 'TASKS.md'; do
  grep -q "$source" "$SKILL" || { echo "missing timetracker source: $source" >&2; exit 1; }
done
grep -q 'High confidence — explicit artifact date' "$SKILL"
grep -q 'Supporting evidence — git history' "$SKILL"
grep -q 'Low confidence — filesystem modification time' "$SKILL"
grep -q 'commit date never overrides a different explicit artifact event date' "$SKILL"
grep -q 'Group evidence into one candidate' "$SKILL"
grep -q 'Preserve all supporting source links' "$SKILL"
grep -q 'source already represented by an entry in `TIMELOG.md`' "$SKILL"
grep -q 'require an explicit new description and new duration' "$SKILL"
grep -q '| _(required)_ |' "$SKILL"
grep -q "Meeting duration.*must never prefill Hours" "$SKILL"
grep -q 'Reject blank, zero, negative, inferred, or merely suggested durations' "$SKILL"
grep -q 'If confirmation changes any field, render a new preview' "$SKILL"
grep -q 'Corrects E####' "$SKILL"
grep -q 'Do not calculate net billing or totals' "$SKILL"
grep -q 'structured questions, git, subagents, and other named tools are optional enhancements' "$SKILL"

grep -q '^| ID | Work date | Hours | Description | Sources | Correction |$' "$TEMPLATE"
! grep -Eq '^\| E[0-9]{4} \|' "$TEMPLATE"
grep -q 'does not establish duration, billing status, or completeness' "$TEMPLATE"

first_id="$({ grep -Eo 'E[0-9]{4}' "$TEMPLATE" || true; } | sed 's/^E//' | sort -n | awk 'NF {max=$1} END {if (max) printf "E%04d", max + 1; else print "E0001"}')"
[ "$first_id" = "E0001" ] || { echo "empty timelog template did not allocate E0001 first: $first_id" >&2; exit 1; }

grep -q 'Explicit dates inside artifacts take precedence' "$README"
grep -q 'Candidates always have a blank duration' "$README"
grep -q 'corrections receive a new ID and reference the original entry' "$README"

echo "✓ timetracker contract preserves evidence hierarchy, manual duration, and append-only history"
