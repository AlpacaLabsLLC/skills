#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

HELPER="skills/master-schedule/scripts/csv-library.py"
[ -x "$HELPER" ] || { echo "missing executable CSV helper" >&2; exit 1; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
PROJECT="$ROOT/project"
mkdir -p "$PROJECT"
printf '# Project\n' > "$PROJECT/PROJECT.md"

(cd "$PROJECT" && "$OLDPWD/$HELPER" init product)
(cd "$PROJECT" && "$OLDPWD/$HELPER" init epd)

python3 - "$PROJECT" <<'PY'
import csv
import importlib.util
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
expected = {"product-library.csv": 33, "epd-library.csv": 42}
for name, count in expected.items():
    data = (root / name).read_bytes()
    assert not data.startswith(b"\xef\xbb\xbf"), name
    assert data.endswith(b"\r\n"), name
    assert b"\n" not in data.replace(b"\r\n", b""), name
    rows = list(csv.reader(data.decode("utf-8").splitlines()))
    assert len(rows) == 1, (name, rows)
    assert len(rows[0]) == count, (name, len(rows[0]))

repo = pathlib.Path.cwd()
spec = importlib.util.spec_from_file_location("csv_library", repo / "skills/master-schedule/scripts/csv-library.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
for schema, header in (("product-schema.md", module.PRODUCT_HEADER), ("epd-schema.md", module.EPD_HEADER)):
    text = (repo / "schema" / schema).read_text(encoding="utf-8")
    documented = re.search(r"```csv\n([^\n]+)\n```", text).group(1)
    assert next(csv.reader([documented])) == list(header), schema
PY

ROW_JSON="$ROOT/row.json"
python3 - "$ROW_JSON" <<'PY'
import json, pathlib, sys
row = {"Product Name": "Café chair, \"Arc\"\nlimited", "Link": "https://example.com/a,b"}
pathlib.Path(sys.argv[1]).write_text(json.dumps(row), encoding="utf-8")
PY
(cd "$PROJECT" && "$OLDPWD/$HELPER" append product --row-json "$ROW_JSON")
(cd "$PROJECT" && "$OLDPWD/$HELPER" validate product)

python3 - "$PROJECT/product-library.csv" <<'PY'
import csv, pathlib, sys
with pathlib.Path(sys.argv[1]).open("r", encoding="utf-8", newline="") as f:
    rows = list(csv.DictReader(f, strict=True))
assert rows[0]["Product Name"] == 'Café chair, "Arc"\nlimited'
assert rows[0]["Link"] == "https://example.com/a,b"
PY

BATCH_JSON="$ROOT/batch.json"
python3 - "$BATCH_JSON" <<'PY'
import json, pathlib, sys
rows = [
    {"Product Name": "Batch one", "SKU": "B-1"},
    {"Product Name": "Batch two", "SKU": "B-2"},
]
pathlib.Path(sys.argv[1]).write_text(json.dumps(rows), encoding="utf-8")
PY
(cd "$PROJECT" && "$OLDPWD/$HELPER" append product --row-json "$BATCH_JSON")
(cd "$PROJECT" && "$OLDPWD/$HELPER" status product) | grep -Fq 'valid: 3 data rows'

BATCH_BEFORE="$ROOT/batch-before"
cp "$PROJECT/product-library.csv" "$BATCH_BEFORE"
BAD_BATCH_JSON="$ROOT/bad-batch.json"
printf '[{"Product Name":"would append"},{"Unknown":"must fail"}]\n' > "$BAD_BATCH_JSON"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" append product --row-json "$BAD_BATCH_JSON"); then
  echo "batch append accepted an invalid row" >&2
  exit 1
fi
cmp "$BATCH_BEFORE" "$PROJECT/product-library.csv"
! find "$PROJECT" -maxdepth 1 -name '.csv-library-*' -print -quit | grep -q .

python3 - "$ROOT" <<'PY'
import importlib.util
import pathlib
import sys

repo = pathlib.Path.cwd()
spec = importlib.util.spec_from_file_location("csv_library", repo / "skills/master-schedule/scripts/csv-library.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
target = pathlib.Path(sys.argv[1]) / "appeared.csv"
target.write_bytes(b"concurrent creator\n")
before = target.read_bytes()
try:
    module.atomic_write(target, b"replacement\r\n", module.MISSING)
except module.LibraryError:
    pass
else:
    raise AssertionError("missing-target collision overwrote an appearing file")
assert target.read_bytes() == before
assert not list(target.parent.glob(".csv-library-*"))
PY

BEFORE="$ROOT/before"
cp "$PROJECT/product-library.csv" "$BEFORE"
printf 'wrong,header\r\nvalue,row\r\n' > "$PROJECT/product-library.csv"
MALFORMED="$ROOT/malformed"
cp "$PROJECT/product-library.csv" "$MALFORMED"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" append product --row-json "$ROW_JSON"); then
  echo "append accepted malformed input" >&2
  exit 1
fi
cmp "$MALFORMED" "$PROJECT/product-library.csv"
! find "$PROJECT" -maxdepth 1 -name '.csv-library-*' -print -quit | grep -q .

cp "$BATCH_BEFORE" "$PROJECT/product-library.csv"
UPDATE_JSON="$ROOT/update.json"
printf '{"Status":"specified","Notes":"updated"}\n' > "$UPDATE_JSON"
(cd "$PROJECT" && "$OLDPWD/$HELPER" update product --match-column 'Product Name' --match-value $'Café chair, "Arc"\nlimited' --row-json "$UPDATE_JSON")
(cd "$PROJECT" && "$OLDPWD/$HELPER" validate product)

VALID_IMPORT="$ROOT/valid-import.csv"
cp "$PROJECT/epd-library.csv" "$VALID_IMPORT"
rm "$PROJECT/epd-library.csv"
(cd "$PROJECT" && "$OLDPWD/$HELPER" import epd --source "$VALID_IMPORT")

REPLACEMENT="$ROOT/replacement.csv"
python3 - "$PROJECT/product-library.csv" "$REPLACEMENT" <<'PY'
import csv, pathlib, sys
with pathlib.Path(sys.argv[1]).open("r", encoding="utf-8", newline="") as f:
    header = next(csv.reader(f, strict=True))
row = [""] * len(header)
row[header.index("Product Name")] = "Reviewed replacement"
row[header.index("SKU")] = "R-1"
with pathlib.Path(sys.argv[2]).open("w", encoding="utf-8", newline="") as f:
    csv.writer(f, lineterminator="\r\n").writerows([header, row])
PY
(cd "$PROJECT" && "$OLDPWD/$HELPER" import product --source "$REPLACEMENT" --replace-existing)
(cd "$PROJECT" && "$OLDPWD/$HELPER" status product) | grep -Fq 'valid: 1 data rows'
grep -Fq 'Reviewed replacement' "$PROJECT/product-library.csv"

REPLACE_BEFORE="$ROOT/replace-before"
cp "$PROJECT/product-library.csv" "$REPLACE_BEFORE"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" import product --source "$REPLACEMENT"); then
  echo "ordinary import overwrote a populated target" >&2
  exit 1
fi
cmp "$REPLACE_BEFORE" "$PROJECT/product-library.csv"

INVALID_REPLACEMENT="$ROOT/invalid-replacement.csv"
printf 'not,the,right,header\r\n' > "$INVALID_REPLACEMENT"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" import product --source "$INVALID_REPLACEMENT" --replace-existing); then
  echo "replace accepted an invalid candidate" >&2
  exit 1
fi
cmp "$REPLACE_BEFORE" "$PROJECT/product-library.csv"

MALFORMED_CURRENT="$ROOT/malformed-current.csv"
printf 'malformed,current\r\n' > "$MALFORMED_CURRENT"
cp "$MALFORMED_CURRENT" "$PROJECT/product-library.csv"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" import product --source "$REPLACEMENT" --replace-existing); then
  echo "replace accepted a malformed current target" >&2
  exit 1
fi
cmp "$MALFORMED_CURRENT" "$PROJECT/product-library.csv"
cp "$REPLACE_BEFORE" "$PROJECT/product-library.csv"

python3 - "$ROOT" <<'PY'
import importlib.util
import pathlib
import sys

repo = pathlib.Path.cwd()
spec = importlib.util.spec_from_file_location("csv_library", repo / "skills/master-schedule/scripts/csv-library.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
target = pathlib.Path(sys.argv[1]) / "changed-existing.csv"
expected = b"validated version\r\n"
appeared = b"concurrent change\r\n"
target.write_bytes(appeared)
try:
    module.atomic_write(target, b"replacement\r\n", expected)
except module.LibraryError:
    pass
else:
    raise AssertionError("guarded replacement overwrote a changed target")
assert target.read_bytes() == appeared
assert not list(target.parent.glob(".csv-library-*"))
PY

BAD="$ROOT/bad.csv"
printf 'Category,Brand\r\nChair,Test\r\n' > "$BAD"
LEGACY="$PROJECT/master-schedule.json"
printf '{"master_sheet_id":"keep-me"}\n' > "$LEGACY"
LEGACY_BEFORE="$ROOT/legacy-before"
cp "$LEGACY" "$LEGACY_BEFORE"
TARGET_BEFORE="$ROOT/target-before"
cp "$PROJECT/product-library.csv" "$TARGET_BEFORE"
if (cd "$PROJECT" && "$OLDPWD/$HELPER" import product --source "$BAD"); then
  echo "import accepted invalid schema" >&2
  exit 1
fi
cmp "$TARGET_BEFORE" "$PROJECT/product-library.csv"
cmp "$LEGACY_BEFORE" "$LEGACY"

for variant in bom duplicate reordered extra; do
  fixture="$ROOT/$variant.csv"
  python3 - "$variant" "$fixture" "$BEFORE" <<'PY'
import csv, pathlib, sys
variant, destination, source = sys.argv[1:]
data = pathlib.Path(source).read_bytes()
if variant == "bom":
    data = b"\xef\xbb\xbf" + data
else:
    with pathlib.Path(source).open("r", encoding="utf-8", newline="") as f:
        rows = list(csv.reader(f, strict=True))
    if variant == "duplicate": rows[0][1] = rows[0][0]
    if variant == "reordered": rows[0][0], rows[0][1] = rows[0][1], rows[0][0]
    if variant == "extra":
        rows[0].append("Extra")
        for row in rows[1:]: row.append("")
    with pathlib.Path(destination).open("w", encoding="utf-8", newline="") as f:
        csv.writer(f, lineterminator="\r\n").writerows(rows)
    raise SystemExit
pathlib.Path(destination).write_bytes(data)
PY
  cp "$fixture" "$PROJECT/product-library.csv"
  fixture_before="$ROOT/$variant-before"
  cp "$fixture" "$fixture_before"
  if (cd "$PROJECT" && "$OLDPWD/$HELPER" validate product); then
    echo "validation accepted $variant header" >&2
    exit 1
  fi
  cmp "$fixture_before" "$PROJECT/product-library.csv"
done

echo "✓ CSV helper enforces exact schemas, RFC 4180 round trips, and atomic preservation"
