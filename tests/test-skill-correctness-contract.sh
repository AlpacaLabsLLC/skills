#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"

if rg -n 'FLOAT' \
  "${repo_root}/skills/occupancy-calculator/SKILL.md" \
  "${repo_root}/skills/workplace-programmer/SKILL.md"; then
  echo "legacy FLOAT branding remains" >&2
  exit 1
fi

for skill in environmental-analysis spec-writer occupancy-calculator; do
  file="${repo_root}/skills/${skill}/SKILL.md"
  grep -q 'architecture-studio:requires-disclaimer' "${file}"
  grep -q 'Final Step: Disclaimer + Marker (required)' "${file}"
done

product="${repo_root}/skills/product-research/SKILL.md"
grep -q 'Never fill price, availability, lead time, dimensions, finishes, certifications, or other purchasing facts from model memory' "${product}"
grep -q 'Not verified' "${product}"

occupancy="${repo_root}/skills/occupancy-calculator/SKILL.md"
grep -q 'never assume an IBC default' "${occupancy}"
grep -q 'For sites outside the US, do not load or use it' "${occupancy}"
grep -A8 '^allowed-tools:' "${occupancy}" | grep -q 'WebSearch'
grep -A8 '^allowed-tools:' "${occupancy}" | grep -q 'WebFetch'
grep -q '^### Authoritative-source gate$' "${occupancy}"
grep -q 'authority having jurisdiction, its official code host, or the promulgating code body' "${occupancy}"
grep -q 'Minimum-exit thresholds, stair/door/other egress capacity factors' "${occupancy}"
grep -q 'Not provided — controlling provision not verified' "${occupancy}"
grep -q '"jurisdiction": "{verified jurisdiction and adopted code edition}"' "${occupancy}"
grep -q '"egress": null' "${occupancy}"
grep -q 'Never export CSV alone' "${occupancy}"
grep -q 'If the user declines the Markdown companion, do not write the CSV' "${occupancy}"
if rg -n '≤49|50-500|501-1000|1001\+|0\.2"/occupant|0\.15"/occupant' "${occupancy}"; then
  echo "occupancy skill contains uncited jurisdiction-sensitive egress constants" >&2
  exit 1
fi

resize="${repo_root}/skills/resize-images/SKILL.md"
grep -q 'scripts/resize_images.py' "${resize}"
if grep -q '^```python$' "${resize}"; then
  echo "resize-images still embeds Python" >&2
  exit 1
fi
grep -q 'Do not dump the layout/background table' "${repo_root}/skills/slide-deck-generator/SKILL.md"

echo "skill correctness contract: ok"
