#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

FILES=(
  skills/epd-research/SKILL.md skills/epd-research/README.md
  skills/epd-parser/SKILL.md skills/epd-parser/README.md
  skills/epd-compare/SKILL.md skills/epd-compare/README.md
  skills/epd-to-spec/SKILL.md skills/epd-to-spec/README.md
)

if rg -n -i 'mcp__google-sheets|google sheets?|spreadsheet (id|url)|sheet (id|url|rows?)|row references?|cell ranges?|\.xlsx?\b' "${FILES[@]}"; then
  echo "EPD surfaces still advertise spreadsheet connectivity or XLS/XLSX" >&2
  exit 1
fi

for skill in epd-research epd-parser epd-compare epd-to-spec; do
  file="skills/$skill/SKILL.md"
  rg -q 'schema/epd-schema\.md' "$file" || {
    echo "$file does not reference the canonical EPD schema" >&2
    exit 1
  }
done

for skill in epd-research epd-parser epd-compare epd-to-spec; do
  file="skills/$skill/SKILL.md"
  rg -q 'python3 "\$\{CLAUDE_PLUGIN_ROOT\}/skills/master-schedule/scripts/csv-library\.py"' "$file" || {
    echo "$file does not use the plugin-root helper invocation" >&2
    exit 1
  }
done

for skill in epd-research epd-parser; do
  file="skills/$skill/SKILL.md"
  rg -q 'one JSON array' "$file" || { echo "$file lacks batch JSON guidance" >&2; exit 1; }
  rg -q 'append epd --row-json <batch.json>` exactly once' "$file" || {
    echo "$file lacks single-append guidance" >&2
    exit 1
  }
  if rg -n -i 'for each record|per-row append' "$file"; then
    echo "$file advertises per-record persistence" >&2
    exit 1
  fi
done

for skill in epd-compare epd-to-spec; do
  file="skills/$skill/SKILL.md"
  rg -q 'Validation is read-only' "$file" || { echo "$file lacks read-only guidance" >&2; exit 1; }
done

python3 - <<'PY'
import csv
import importlib.util
import pathlib
import re

root = pathlib.Path.cwd()
helper_path = root / "skills/master-schedule/scripts/csv-library.py"
spec = importlib.util.spec_from_file_location("csv_library", helper_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

schema = (root / "schema/epd-schema.md").read_text(encoding="utf-8")
documented = re.search(r"```csv\n([^\n]+)\n```", schema)
assert documented, "canonical EPD header missing"
assert next(csv.reader([documented.group(1)])) == list(module.EPD_HEADER)
assert len(module.EPD_HEADER) == 42
assert len(module.PRODUCT_HEADER) == 33
assert module.EPD_HEADER != module.PRODUCT_HEADER

for path in [
    root / "skills/epd-research/SKILL.md",
    root / "skills/epd-parser/SKILL.md",
    root / "skills/epd-compare/SKILL.md",
    root / "skills/epd-to-spec/SKILL.md",
]:
    text = path.read_text(encoding="utf-8")
    assert "EPD Link,Manufacturer,Product Name" not in text, f"duplicated header in {path}"
    for line in text.splitlines():
        if "skills/master-schedule/scripts/csv-library.py" in line:
            assert 'python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py"' in line, (
                f"cwd/repository-relative helper invocation in {path}: {line}"
            )
PY

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
PROJECT="$ROOT/project"
mkdir -p "$PROJECT"
printf '# Project\n' > "$PROJECT/PROJECT.md"
export CLAUDE_PLUGIN_ROOT="$PWD"

(cd "$PROJECT" && python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" init epd >/dev/null)
EPD_BEFORE="$ROOT/epd-before"
cp "$PROJECT/epd-library.csv" "$EPD_BEFORE"

printf 'Category,Brand\r\nChair,Test\r\n' > "$ROOT/product-shaped.csv"
if (cd "$PROJECT" && python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" import epd --source "$ROOT/product-shaped.csv" >/dev/null 2>&1); then
  echo "EPD persistence accepted an FF&E-shaped CSV" >&2
  exit 1
fi
cmp "$EPD_BEFORE" "$PROJECT/epd-library.csv"

printf 'wrong,header\r\nvalue,row\r\n' > "$PROJECT/epd-library.csv"
MALFORMED_BEFORE="$ROOT/malformed-before"
cp "$PROJECT/epd-library.csv" "$MALFORMED_BEFORE"
printf '{"Product Name":"Test EPD"}\n' > "$ROOT/row.json"
if (cd "$PROJECT" && python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" append epd --row-json "$ROOT/row.json" >/dev/null 2>&1); then
  echo "EPD append accepted a malformed library" >&2
  exit 1
fi
cmp "$MALFORMED_BEFORE" "$PROJECT/epd-library.csv"

cp "$EPD_BEFORE" "$PROJECT/epd-library.csv"
cat > "$ROOT/batch.json" <<'JSON'
[
  {"Product Name":"EPD One","Manufacturer":"Maker A","Source":"epd-parser"},
  {"Product Name":"EPD Two","Manufacturer":"Maker B","Source":"epd-parser"}
]
JSON
(cd "$PROJECT" && python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" append epd --row-json "$ROOT/batch.json" >/dev/null)
python3 - "$PROJECT/epd-library.csv" <<'PY'
import csv, pathlib, sys
with pathlib.Path(sys.argv[1]).open("r", encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, strict=True))
assert [row["Product Name"] for row in rows] == ["EPD One", "EPD Two"]
PY

echo "✓ EPD workflows use the canonical CSV contract and reject FF&E/malformed persistence"
