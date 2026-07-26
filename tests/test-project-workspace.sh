#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="skills/project/scripts/project-workspace.sh"
[ -x "$SCRIPT" ] || { echo "missing executable project helper" >&2; exit 1; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

PROJECT="$ROOT/2401-museum-expansion"
"$SCRIPT" init "$PROJECT" "Museum Expansion" 2401

for file in PROJECT.md CLAUDE.md TASKS.md TIMELOG.md; do
  [ -f "$PROJECT/$file" ] || { echo "missing project file: $file" >&2; exit 1; }
done
for dir in decisions meetings site-reports docs/plans .claude/skills; do
  [ -d "$PROJECT/$dir" ] || { echo "missing project directory: $dir" >&2; exit 1; }
done
grep -q 'decisions/' "$PROJECT/PROJECT.md"
grep -Fq '| Format version | 2 |' "$PROJECT/PROJECT.md"
! grep -q '^## Decisions$' "$PROJECT/PROJECT.md"

SLUG_PROJECT="$ROOT/community-center"
"$SCRIPT" init "$SLUG_PROJECT" "Community Center" community-center
grep -q 'community-center' "$SLUG_PROJECT/PROJECT.md"

PORTFOLIO_PROJECT="$ROOT/2402-library"
"$SCRIPT" init "$PORTFOLIO_PROJECT" "Library" 2402 portfolio
[ ! -f "$PORTFOLIO_PROJECT/TASKS.md" ]
grep -q 'owning studio' "$PORTFOLIO_PROJECT/PROJECT.md"
grep -q 'owning studio' "$PROJECT/PROJECT.md"

if "$SCRIPT" init "$PROJECT" "Museum Expansion" 2401; then
  echo "project overwrite unexpectedly succeeded" >&2
  exit 1
fi

echo "✓ project helper creates numbered and locally identified bundles without overwriting"
