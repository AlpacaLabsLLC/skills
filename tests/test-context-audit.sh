#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
first="$(mktemp)"
second="$(mktemp)"
trap 'rm -f "${first}" "${second}"' EXIT

"${repo_root}/scripts/audit-skill-context.sh" > "${first}"
LC_ALL=POSIX LANG=POSIX "${repo_root}/scripts/audit-skill-context.sh" > "${second}"
cmp "${first}" "${second}"

expected="$(( $(find "${repo_root}/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | wc -l | tr -d ' ') + 1 ))"
actual="$(wc -l < "${first}" | tr -d ' ')"
test "${actual}" = "${expected}"

head -1 "${first}" | grep -q $'^skill\tdescription_chars\tdescription_words\tdescription_lines\tdescription_est_tokens\tbody_chars\tbody_words\tbody_lines$'
grep -q '^occupancy-calculator[[:space:]]' "${first}"
awk -F '\t' 'NR > 1 { if ($2 < 1 || $5 < 1 || $6 < 1 || $8 < 1) exit 1 }' "${first}"

for skill in occupancy-calculator product-research resize-images; do
  source_chars="$(sed -n 's/^description: //p' "${repo_root}/skills/${skill}/SKILL.md" | awk '{ print length($0) }')"
  reported_chars="$(awk -F '\t' -v skill="${skill}" '$1 == skill { print $2 }' "${first}")"
  test "${source_chars}" = "${reported_chars}"
done

report="${repo_root}/docs/reports/v1-4-skill-context-optimization.md"
report_value() {
  awk -F '|' -v label="$1" '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    trim($2) == label { value=trim($4); gsub(/,/, "", value); print value; exit }
  ' "${report}"
}

audit_skills="$(awk -F '\t' 'NR > 1 { count++ } END { print count + 0 }' "${first}")"
audit_description_chars="$(awk -F '\t' 'NR > 1 { total += $2 } END { print total + 0 }' "${first}")"
audit_description_tokens="$(awk -F '\t' 'NR > 1 { total += $5 } END { print total + 0 }' "${first}")"
audit_body_chars="$(awk -F '\t' 'NR > 1 { total += $6 } END { print total + 0 }' "${first}")"

test "$(report_value 'Skills discovered')" = "${audit_skills}"
test "$(report_value 'Description characters')" = "${audit_description_chars}"
test "$(report_value 'Description estimated tokens')" = "${audit_description_tokens}"
test "$(report_value 'Skill-body characters')" = "${audit_body_chars}"

echo "context audit contract: ok"
