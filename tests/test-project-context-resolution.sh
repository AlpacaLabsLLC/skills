#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
RESOLVER=skills/project/scripts/resolve-context.sh
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

STUDIO="$ROOT/test-studio"
skills/studio/scripts/studio-workspace.sh init "$STUDIO" "Test Studio" metric US NY NYC >/dev/null

make_project() {
  project_id=$1
  project_name=$2
  project_type=$3
  project_status=$4
  client_code=$5
  client=$6
  project="$STUDIO/projects/$project_id"
  skills/project/scripts/project-workspace.sh init "$project" "$project_name" "$project_id" "$project_type" "$project_status" "$client_code" "$client" >/dev/null
  skills/studio/scripts/studio-workspace.sh register "$STUDIO" "$project_id" "$project_name" "projects/$project_id" >/dev/null
}

make_project 2026-08-INT-STUDIO-SYSTEMS "Studio Systems" internal active INT —
make_project 2026-08-ONE-PROSPECTIVE-ONE "Prospective One" client prospective ONE "Client One"
make_project 2026-08-TWO-ON-HOLD-TWO "On Hold Two" client on-hold TWO "Client Two"
make_project 2026-08-THR-LOST-THREE "Lost Three" client lost THR "Client Three"
make_project 2026-08-FOU-WITHDRAWN-FOUR "Withdrawn Four" client withdrawn FOU "Client Four"
make_project 2026-08-FIV-COMPLETED-FIVE "Completed Five" client completed FIV "Client Five"
make_project 2026-08-SIX-ARCHIVED-SIX "Archived Six" client archived SIX "Client Six"

P1="$STUDIO/projects/2026-08-INT-STUDIO-SYSTEMS"
P_ARCHIVED="$STUDIO/projects/2026-08-SIX-ARCHIVED-SIX"
mkdir -p "$P1/docs/plans" "$P_ARCHIVED/docs/plans"
P1_PHYSICAL=$(cd -P "$P1" && pwd)
P_ARCHIVED_PHYSICAL=$(cd -P "$P_ARCHIVED" && pwd)
STUDIO_PHYSICAL=$(cd -P "$STUDIO" && pwd)
"$RESOLVER" "$P1/docs/plans" | grep -Fq $'project\t'"$P1_PHYSICAL"$'\t2026-08-INT-STUDIO-SYSTEMS\t'"$STUDIO_PHYSICAL"$'\tproject\t'"$P1_PHYSICAL/TASKS.md"$'\tinternal\tactive'
"$RESOLVER" "$P_ARCHIVED/docs/plans" | grep -Fq $'project\t'"$P_ARCHIVED_PHYSICAL"$'\t2026-08-SIX-ARCHIVED-SIX\t'"$STUDIO_PHYSICAL"$'\tproject\t'"$P_ARCHIVED_PHYSICAL/TASKS.md"$'\tclient\tarchived'

RESULT=$("$RESOLVER" "$STUDIO")
printf '%s\n' "$RESULT" | grep -Fq $'studio-picker\t'"$STUDIO_PHYSICAL"
printf '%s\n' "$RESULT" | grep -Fq $'2026-08-ONE-PROSPECTIVE-ONE\tProspective One\tprojects/2026-08-ONE-PROSPECTIVE-ONE\tclient\tprospective'
printf '%s\n' "$RESULT" | grep -Fq $'2026-08-SIX-ARCHIVED-SIX\tArchived Six\tprojects/2026-08-SIX-ARCHIVED-SIX\tclient\tarchived'

skills/studio/scripts/studio-workspace.sh task-mode "$STUDIO" portfolio >/dev/null
"$RESOLVER" "$P_ARCHIVED/docs/plans" | grep -Fq $'project\t'"$P_ARCHIVED_PHYSICAL"$'\t2026-08-SIX-ARCHIVED-SIX\t'"$STUDIO_PHYSICAL"$'\tportfolio\t'"$STUDIO_PHYSICAL/TASKS.md"$'\tclient\tarchived'
skills/studio/scripts/studio-workspace.sh task-mode "$STUDIO" project >/dev/null

cp "$STUDIO/STUDIO.md" "$ROOT/studio-before-duplicate.md"
awk '/<!-- projects:end -->/ {print "| 2026-08-SIX-ARCHIVED-SIX | Duplicate | Client Six | SIX | client | archived | projects/2026-08-SIX-ARCHIVED-SIX | 2026-08-19 |"} {print}' "$ROOT/studio-before-duplicate.md" > "$STUDIO/STUDIO.md"
set +e
DUPLICATE_RESULT=$("$RESOLVER" "$P_ARCHIVED/docs/plans")
duplicate_status=$?
set -e
[ "$duplicate_status" -eq 2 ]
printf '%s\n' "$DUPLICATE_RESULT" | grep -Fq $'invalid\tproject is not uniquely registered in its owning studio'
cp "$ROOT/studio-before-duplicate.md" "$STUDIO/STUDIO.md"

EMPTY_STUDIO="$ROOT/empty-studio"
skills/studio/scripts/studio-workspace.sh init "$EMPTY_STUDIO" "Empty Studio" metric US NY NYC >/dev/null
EMPTY_STUDIO_PHYSICAL=$(cd -P "$EMPTY_STUDIO" && pwd)
[ "$("$RESOLVER" "$EMPTY_STUDIO")" = $'no-projects\t'"$EMPTY_STUDIO_PHYSICAL" ]

mkdir "$ROOT/unrelated"
[ "$("$RESOLVER" "$ROOT/unrelated")" = no-context ]

sed 's/| Format version | 3 |/| Format version | 99 |/' "$P1/PROJECT.md" > "$P1/PROJECT.tmp"
mv "$P1/PROJECT.tmp" "$P1/PROJECT.md"
RESULT=$("$RESOLVER" "$STUDIO")
! printf '%s\n' "$RESULT" | grep -Fq $'2026-08-INT-STUDIO-SYSTEMS\tStudio Systems'
printf '%s\n' "$RESULT" | grep -Fq $'2026-08-SIX-ARCHIVED-SIX\tArchived Six'
printf '%s\n' "$RESULT" | grep -Fq $'invalid-project\t2026-08-INT-STUDIO-SYSTEMS\tprojects/2026-08-INT-STUDIO-SYSTEMS\tPROJECT.md format version is 99; version 3 required'

# Studio-root selection validates every identity field, not only ID/type/status.
cp "$P_ARCHIVED/PROJECT.md" "$ROOT/archived-project-before-client-drift.md"
sed 's/| Client | Client Six |/| Client | Different Client |/' "$P_ARCHIVED/PROJECT.md" > "$P_ARCHIVED/PROJECT.tmp"
mv "$P_ARCHIVED/PROJECT.tmp" "$P_ARCHIVED/PROJECT.md"
RESULT=$("$RESOLVER" "$STUDIO")
! printf '%s\n' "$RESULT" | grep -Fq $'2026-08-SIX-ARCHIVED-SIX\tArchived Six\tprojects/2026-08-SIX-ARCHIVED-SIX\tclient\tarchived'
printf '%s\n' "$RESULT" | grep -Fq $'invalid-project\t2026-08-SIX-ARCHIVED-SIX\tprojects/2026-08-SIX-ARCHIVED-SIX\tPROJECT.md Client does not match its studio registration'
cp "$ROOT/archived-project-before-client-drift.md" "$P_ARCHIVED/PROJECT.md"

# Registered-but-invalid is not an empty studio and preserves a structured reason.
ALL_INVALID="$ROOT/all-invalid-studio"
skills/studio/scripts/studio-workspace.sh init "$ALL_INVALID" "All Invalid" metric US NY NYC >/dev/null
ALL_INVALID_ID=2026-08-BAD-BROKEN-PROJECT
skills/project/scripts/project-workspace.sh init "$ALL_INVALID/projects/$ALL_INVALID_ID" "Broken Project" "$ALL_INVALID_ID" client active BAD "Broken Client" >/dev/null
skills/studio/scripts/studio-workspace.sh register "$ALL_INVALID" "$ALL_INVALID_ID" "Broken Project" "projects/$ALL_INVALID_ID" >/dev/null
sed 's/| Client code | BAD |/| Client code | XYZ |/' "$ALL_INVALID/projects/$ALL_INVALID_ID/PROJECT.md" > "$ALL_INVALID/projects/$ALL_INVALID_ID/PROJECT.tmp"
mv "$ALL_INVALID/projects/$ALL_INVALID_ID/PROJECT.tmp" "$ALL_INVALID/projects/$ALL_INVALID_ID/PROJECT.md"
ALL_INVALID_RESULT=$("$RESOLVER" "$ALL_INVALID")
printf '%s\n' "$ALL_INVALID_RESULT" | grep -Fq $'studio-picker\t'
! printf '%s\n' "$ALL_INVALID_RESULT" | grep -Fq $'no-projects\t'
printf '%s\n' "$ALL_INVALID_RESULT" | grep -Fq $'invalid-project\t2026-08-BAD-BROKEN-PROJECT\tprojects/2026-08-BAD-BROKEN-PROJECT\tPROJECT.md Client code does not match its studio registration'

for skill in tasklist meeting-minutes site-visit-report workplan; do
  grep -Fq 'skills/project/references/context-resolution.md' "skills/$skill/SKILL.md"
done
echo "✓ shared resolver validates full project identity and distinguishes empty from invalid studios"
