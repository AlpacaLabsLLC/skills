#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
RESOLVER=skills/project/scripts/resolve-context.sh
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

STUDIO="$ROOT/test-studio"
skills/studio/scripts/studio-workspace.sh init "$STUDIO" "Test Studio" metric US NY NYC >/dev/null
P1="$STUDIO/projects/1001-one"
P2="$STUDIO/projects/1002-two"
skills/project/scripts/project-workspace.sh init "$P1" One 1001 >/dev/null
skills/project/scripts/project-workspace.sh init "$P2" Two 1002 >/dev/null
skills/studio/scripts/studio-workspace.sh register "$STUDIO" 1001 One projects/1001-one >/dev/null
skills/studio/scripts/studio-workspace.sh register "$STUDIO" 1002 Two projects/1002-two >/dev/null

mkdir -p "$P1/docs/plans"
P1_PHYSICAL=$(cd -P "$P1" && pwd)
STUDIO_PHYSICAL=$(cd -P "$STUDIO" && pwd)
"$RESOLVER" "$P1/docs/plans" | grep -Fq $'project\t'"$P1_PHYSICAL"$'\t1001\t'"$STUDIO_PHYSICAL"$'\tproject\t'"$P1_PHYSICAL/TASKS.md"
RESULT=$("$RESOLVER" "$STUDIO")
printf '%s\n' "$RESULT" | grep -Fq $'studio-picker\t'"$STUDIO_PHYSICAL"
printf '%s\n' "$RESULT" | grep -Fq $'1001\tOne\tprojects/1001-one'
printf '%s\n' "$RESULT" | grep -Fq $'1002\tTwo\tprojects/1002-two'

skills/studio/scripts/studio-workspace.sh task-mode "$STUDIO" portfolio >/dev/null
"$RESOLVER" "$P1/docs/plans" | grep -Fq $'project\t'"$P1_PHYSICAL"$'\t1001\t'"$STUDIO_PHYSICAL"$'\tportfolio\t'"$STUDIO_PHYSICAL/TASKS.md"
skills/studio/scripts/studio-workspace.sh task-mode "$STUDIO" project >/dev/null

cp "$STUDIO/STUDIO.md" "$ROOT/studio-before-duplicate.md"
awk '/<!-- projects:end -->/ {print "| duplicate | Duplicate | projects/1001-one | active | 2026-07-22 |"} {print}' "$ROOT/studio-before-duplicate.md" > "$STUDIO/STUDIO.md"
set +e
DUPLICATE_RESULT=$("$RESOLVER" "$P1/docs/plans")
duplicate_status=$?
set -e
[ "$duplicate_status" -eq 2 ]
printf '%s\n' "$DUPLICATE_RESULT" | grep -Fq $'invalid\tproject is not uniquely registered'
cp "$ROOT/studio-before-duplicate.md" "$STUDIO/STUDIO.md"

mkdir "$ROOT/unrelated"
[ "$("$RESOLVER" "$ROOT/unrelated")" = no-context ]

sed 's/| Format version | 2 |/| Format version | 99 |/' "$P1/PROJECT.md" > "$P1/PROJECT.tmp"
mv "$P1/PROJECT.tmp" "$P1/PROJECT.md"
RESULT=$("$RESOLVER" "$STUDIO")
! printf '%s\n' "$RESULT" | grep -Fq $'1001\tOne'
printf '%s\n' "$RESULT" | grep -Fq $'1002\tTwo'

for skill in tasklist meeting-minutes site-visit-report workplan; do
  grep -Fq 'skills/project/references/context-resolution.md' "skills/$skill/SKILL.md"
done
echo "✓ shared resolver returns typed, versioned, physically contained project context"
