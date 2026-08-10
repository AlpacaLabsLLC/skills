#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

skills=(
  product-research product-data-import product-data-cleanup product-enrich
  product-match product-pair product-image-processor product-spec-bulk-fetch
  product-spec-pdf-parser sif-to-csv csv-to-sif
)

owned=()
for skill in "${skills[@]}"; do
  owned+=("skills/$skill/SKILL.md")
  if [[ -f "skills/$skill/README.md" ]]; then
    owned+=("skills/$skill/README.md")
  fi
done
owned+=("agents/ffe-designer.md")

if rg -n -i 'mcp__google-sheets|google[[:space:]-]*sheet|spreadsheet|sheet id|sheet-conventions\.md|\.xlsx?\b|\.tsv\b|excel' "${owned[@]}"; then
  echo "FF&E surface still advertises Google Sheets or XLS/XLSX" >&2
  exit 1
fi

for skill in "${skills[@]}"; do
  file="skills/$skill/SKILL.md"
  rg -q 'product-library\.csv' "$file" || {
    echo "$file must name the canonical product-library.csv" >&2
    exit 1
  }
  rg -q 'csv-conventions\.md' "$file" || {
    echo "$file must reference schema/csv-conventions.md" >&2
    exit 1
  }
done

mutators=(
  product-research product-data-import product-data-cleanup product-enrich
  product-match product-pair product-spec-bulk-fetch product-spec-pdf-parser
  sif-to-csv
)
for skill in "${mutators[@]}"; do
  file="skills/$skill/SKILL.md"
  rg -q 'csv-library\.py' "$file" || {
    echo "$file must delegate persistent mutation to csv-library.py" >&2
    exit 1
  }
  rg -Fq '<plugin-root>/skills/master-schedule/scripts/csv-library.py' "$file" || {
    echo "$file must resolve the helper through the portable plugin root" >&2
    exit 1
  }
  rg -q -i 'preview' "$file" || {
    echo "$file must preview persistent changes" >&2
    exit 1
  }
  rg -q -i 'single.*gate' "$file" || {
    echo "$file must use the single confirmation gate" >&2
    exit 1
  }
done

if rg -n '(\.\./master-schedule/scripts/csv-library\.py|`skills/master-schedule/scripts/csv-library\.py|"skills/master-schedule/scripts/csv-library\.py)' "${owned[@]}"; then
  echo "FF&E surface contains an installed-plugin-unsafe helper path" >&2
  exit 1
fi

batch_appenders=(
  product-research product-data-import product-match product-pair
  product-spec-bulk-fetch product-spec-pdf-parser sif-to-csv
)
for skill in "${batch_appenders[@]}"; do
  file="skills/$skill/SKILL.md"
  rg -q -i 'one JSON array' "$file" || {
    echo "$file must serialize additions as one batch array" >&2
    exit 1
  }
  rg -q -i 'exactly once' "$file" || {
    echo "$file must invoke one approved batch mutation" >&2
    exit 1
  }
  rg -q -i 'never loop per row|never loop `update`' "$file" || {
    echo "$file must forbid per-row persistent mutation" >&2
    exit 1
  }
done

for skill in product-data-cleanup product-enrich; do
  file="skills/$skill/SKILL.md"
  rg -q -i 'complete proposed 33-column CSV' "$file" || {
    echo "$file must materialize one complete multi-row replacement" >&2
    exit 1
  }
  rg -q ' import product ' "$file" || {
    echo "$file must use one atomic import for multi-row replacement" >&2
    exit 1
  }
  rg -q -i 'exactly once' "$file" || {
    echo "$file must invoke the approved replacement once" >&2
    exit 1
  }
  rg -q -i 'never loop `update`' "$file" || {
    echo "$file must forbid update loops" >&2
    exit 1
  }
done

rg -q 'Image URL' skills/product-image-processor/SKILL.md
rg -q 'Product Name' skills/product-image-processor/SKILL.md
if rg -n -i 'column[[:space:]]+(AC|E)\b' skills/product-image-processor/SKILL.md; then
  echo "image processor must address CSV fields by name, not column letters" >&2
  exit 1
fi

rg -q -i 'SIF.*input|input.*SIF' skills/sif-to-csv/SKILL.md
rg -q -i 'SIF.*output|output.*SIF' skills/csv-to-sif/SKILL.md

echo "FF&E CSV contract tests passed"
