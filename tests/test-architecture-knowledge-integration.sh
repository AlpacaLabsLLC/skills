#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

require() {
  local file="$1" pattern="$2"
  grep -Fq -- "$pattern" "$file" || {
    echo "missing contract text in $file: $pattern" >&2
    exit 1
  }
}

STUDIO=skills/studio/SKILL.md
WORKPLAN=skills/workplan/SKILL.md
AGREEMENT=skills/agreement/SKILL.md
SPEC=skills/spec-writer/SKILL.md
SPEC_README=skills/spec-writer/README.md
EPD=skills/epd-to-spec/SKILL.md
CSI=rules/csi-formatting.md
TERMS=rules/terminology.md

# Routing is based on the requested outcome, not a term's presence in a record.
require "$STUDIO" "Neutral professional-practice term, AIA document family, or document purpose"
require "$STUDIO" '$architecture-knowledge'
require "$STUDIO" "Actual signed project scope"
require "$STUDIO" '$agreement'
require "$STUDIO" "Actual work or submission plan"
require "$STUDIO" '$workplan'
require "$STUDIO" "Outline specification"
require "$STUDIO" '$spec-writer'
require "$STUDIO" "Regulatory conclusion"
require "$STUDIO" "Contract selection or clause question"
require "$STUDIO" "bounded refusal"

# Consultative corpus use must not take ownership away from record workflows.
for file in "$WORKPLAN" "$AGREEMENT" "$SPEC" "$EPD"; do
  require "$file" 'skills/architecture-knowledge/references/'
  require "$file" 'terminology context only'
  require "$file" 'not record authority, a mutation path, permission, or gate'
done
require "$AGREEMENT" "Actual signed project scope remains owned by this skill"

# CSI compatibility and SectionFormat organization deliberately have different bounds.
for file in "$SPEC" "$SPEC_README" "$CSI"; do
  require "$file" "limited MasterFormat 2020 compatibility baseline"
  require "$file" "project's licensed edition"
done
require "$SPEC" "CSI basis: limited MasterFormat 2020 compatibility baseline"
require "$CSI" "edition-neutral"
require "$CSI" "three-part organization"
! grep -Fq "MasterFormat 2018" "$CSI"

# Terminology is a style rule; factual orientation is linked to the corpus.
require "$TERMS" "style and first-use"
require "$TERMS" "../skills/architecture-knowledge/references/README.md"
require "$TERMS" "| Use this | Not this |"

echo "✓ architecture-knowledge integration boundaries hold"
