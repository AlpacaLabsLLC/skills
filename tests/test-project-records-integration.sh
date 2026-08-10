#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

ROUTER="skills/studio/SKILL.md"
MENU="skills/tool-catalog/SKILL.md"
README="skills/README.md"
CI=".github/workflows/lint.yml"

for route in meeting-minutes site-visit-report tasklist timetracker; do
  grep -q "\`/as:$route\`" "$ROUTER" || { echo "missing router route: /as:$route" >&2; exit 1; }
  grep -q "^/as:$route " "$MENU" || { echo "missing menu entry: /as:$route" >&2; exit 1; }
  rows="$(grep -Ec "^\| \[\`/as:$route\`\]\(\./$route\) \|" "$README")"
  [ "$rows" -eq 1 ] || { echo "expected exactly one README catalog row for /$route, found $rows" >&2; exit 1; }
done

# Static routing assertions validate the written precedence contract and its
# examples. They do not claim to execute or prove model routing behavior.
grep -q '^## Task routing$' "$ROUTER"
grep -q 'explicit typed-record deliverable wins over a general plan' "$ROUTER"
grep -q 'explicit work-plan deliverable still routes to `/as:workplan`' "$ROUTER"
grep -q 'Meeting transcript or minutes.*`/as:meeting-minutes`' "$ROUTER"
grep -q 'Field notes or site-visit report.*`/as:site-visit-report`' "$ROUTER"
grep -q 'Tasks or action register.*`/as:tasklist`' "$ROUTER"
grep -q 'Daily/weekly time reconstruction.*`/as:timetracker`' "$ROUTER"
grep -q 'Explicit work plan.*`/as:workplan`' "$ROUTER"

grep -q '^### Project Records$' "$MENU"
grep -q '^### Project Records$' "$README"
grep -q 'linked graph' "$MENU"
grep -q 'linked graph' "$README"
! grep -q '^### Project Dossier$' "$MENU"
! grep -q '^### Project Dossier$' "$README"

for skill in project timetracker; do
  file="skills/$skill/SKILL.md"
  grep -q 'PROJECT.md' "$file" || { echo "$skill does not resolve project context" >&2; exit 1; }
  grep -qi 'project root\|project boundary' "$file" || { echo "$skill does not name its project boundary" >&2; exit 1; }
done

for skill in workplan meeting-minutes site-visit-report tasklist; do
  file="skills/$skill/SKILL.md"
  grep -q 'shared resolver' "$file" || { echo "$skill does not use the shared project resolver" >&2; exit 1; }
  grep -q 'context-resolution.md' "$file" || { echo "$skill does not load the shared resolver contract" >&2; exit 1; }
done

grep -q '`/as:project`' "$ROUTER"
grep -q '^/as:project ' "$MENU"
grep -q '^### Project Records$' "$README"
[ ! -d skills/project-dossier ]
[ ! -d skills/decision ]

plugin_version="$(python3 -c 'import json; print(json.load(open(".claude-plugin/plugin.json"))["version"])')"
market_version="$(python3 -c 'import json; print(json.load(open(".claude-plugin/marketplace.json"))["metadata"]["version"])')"
[ "$plugin_version" = "1.5.0" ]
[ "$market_version" = "$plugin_version" ]
grep -q '^## \[Unreleased\]$' CHANGELOG.md
grep -q '^## \[1.4.1\] - 2026-07-29$' CHANGELOG.md
grep -q '^## \[1.4.0\] - 2026-07-26$' CHANGELOG.md

grep -Fq 'for test_file in tests/test-*.sh' "$CI"
grep -Fq '"$test_file"' "$CI"

echo "✓ project-record routing, catalog, release, and CI contracts are integrated"
