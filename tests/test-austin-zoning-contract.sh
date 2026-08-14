#!/usr/bin/env bash
set -euo pipefail

SKILL="skills/zoning-analysis-austin/SKILL.md"
README="skills/zoning-analysis-austin/README.md"
AGENT="agents/austin-zoning-expert.md"
SOURCES="skills/zoning-analysis-austin/references/data-sources.md"
CHECKLIST="skills/zoning-analysis-austin/references/regulatory-checklist.md"
GIS_GUIDE="skills/zoning-analysis-austin/references/gis-query-guide.md"
LOOKUP="skills/zoning-analysis-austin/scripts/austin_property_lookup.py"

for file in "$SKILL" "$README" "$AGENT" "$SOURCES" "$CHECKLIST" "$GIS_GUIDE" "$LOOKUP"; do
  [ -f "$file" ] || { echo "missing Austin zoning contract file: $file" >&2; exit 1; }
done

grep -q '^name: zoning-analysis-austin$' "$SKILL"
grep -q 'Zoning By Address dataset as a locator only' "$SKILL"
grep -q 'Never supply a numeric development control from model memory' "$SKILL"
grep -q 'full-purpose City of Austin jurisdiction, limited-purpose jurisdiction, ETJ' "$SKILL"
grep -q 'Missing values remain null or Not verified, never zero' "$CHECKLIST"
grep -q 'austin_property_lookup.py' "$SKILL"
grep -q 'parcel bounding envelope' "$GIS_GUIDE"
grep -q 'A conditional-overlay suffix is not a restriction list' "$AGENT"
grep -q 'architecture-studio:requires-disclaimer' "$SKILL"
grep -q '/as:zoning-analysis-austin' "$AGENT"
grep -q '/as:zoning-envelope' "$AGENT"

echo "Austin zoning contract: ok"
