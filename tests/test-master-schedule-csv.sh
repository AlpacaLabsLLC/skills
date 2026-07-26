#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HELPER="skills/master-schedule/scripts/csv-library.py"
SKILL="skills/master-schedule/SKILL.md"
README="skills/master-schedule/README.md"

grep -Fq 'product-library.csv' "$SKILL"
grep -Fq 'PROJECT.md' "$SKILL"
grep -Fq 'user-exported CSV' "$SKILL"
grep -Fq 'product-library.csv' "$README"
! grep -Eqi 'mcp__google-sheets|docs\.google\.com|spreadsheet ID|template sheet' "$SKILL" "$README"

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
PROJECT="$ROOT/2401-test"
mkdir -p "$PROJECT/nested/work"
printf '# Project\n' > "$PROJECT/PROJECT.md"

(cd "$PROJECT/nested/work" && "$OLDPWD/$HELPER" init product)
[ -f "$PROJECT/product-library.csv" ]
[ ! -f "$PROJECT/nested/work/product-library.csv" ]
(cd "$PROJECT/nested/work" && "$OLDPWD/$HELPER" status product) | grep -Fq 'valid: 0 data rows'

printf '{"master_sheet_id":"legacy"}\n' > "$PROJECT/master-schedule.json"
LEGACY="$ROOT/legacy"
cp "$PROJECT/master-schedule.json" "$LEGACY"
(cd "$PROJECT/nested/work" && "$OLDPWD/$HELPER" status product) | grep -Fq 'legacy configuration preserved'
cmp "$LEGACY" "$PROJECT/master-schedule.json"

printf 'bad,header\r\n' > "$PROJECT/product-library.csv"
BAD="$ROOT/bad"
cp "$PROJECT/product-library.csv" "$BAD"
if (cd "$PROJECT/nested/work" && "$OLDPWD/$HELPER" status product); then
  echo "status accepted invalid library" >&2
  exit 1
fi
cmp "$BAD" "$PROJECT/product-library.csv"
cmp "$LEGACY" "$PROJECT/master-schedule.json"

echo "✓ /master-schedule resolves PROJECT.md, stays local, and preserves legacy evidence"
