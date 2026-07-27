#!/usr/bin/env bash
set -euo pipefail

# Every YAML description style a SKILL.md may legally use must be measured, not
# just the inline form the bundled skills happen to use today.
#
# Regression: a bare "description:" followed by indented continuation lines is a
# valid plain multi-line YAML scalar, but the audit matched only the ">" and "|"
# block indicators. The continuation lines fell through every rule, were
# dropped, and the skill was reported with a zero-character description. That is
# silent: nothing errors, the row is simply wrong, and any total built from it
# is wrong too.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
audit="${repo_root}/scripts/audit-skill-context.sh"

fixture="$(mktemp -d)"
output="$(mktemp)"
trap 'rm -rf "${fixture}" "${output}"' EXIT

# The audit derives a skill name by stripping everything up to "/skills/",
# so the fixture tree needs that component.
mkdir -p "${fixture}"/skills/{inline,folded,literal,plain,quoted}

# Each fixture carries the same 21-character description through a different
# YAML style, so one expected length covers all five.
cat > "${fixture}/skills/inline/SKILL.md" <<'EOF'
---
name: inline
description: Alpha bravo charlie
---

Body line.
EOF

cat > "${fixture}/skills/folded/SKILL.md" <<'EOF'
---
name: folded
description: >
  Alpha bravo
  charlie
---

Body line.
EOF

cat > "${fixture}/skills/literal/SKILL.md" <<'EOF'
---
name: literal
description: |-
  Alpha bravo charlie
---

Body line.
EOF

# The regression case: no block indicator at all.
cat > "${fixture}/skills/plain/SKILL.md" <<'EOF'
---
name: plain
description:
  Alpha bravo
  charlie
---

Body line.
EOF

cat > "${fixture}/skills/quoted/SKILL.md" <<'EOF'
---
name: quoted
description: "Alpha bravo charlie"
---

Body line.
EOF

"${audit}" "${fixture}/skills" > "${output}"

report_chars() {
  awk -F '\t' -v skill="$1" '$1 == skill { print $2 }' "${output}"
}

for style in inline folded literal plain quoted; do
  actual="$(report_chars "${style}")"
  if [ "${actual}" != "19" ]; then
    echo "description style '${style}' measured ${actual:-<missing>} chars; expected 19" >&2
    exit 1
  fi
done

# Every fixture must also report a non-empty body and a token estimate, so a
# zero never passes as a legitimate measurement.
awk -F '\t' 'NR > 1 { if ($2 < 1 || $5 < 1 || $6 < 1) exit 1 }' "${output}"

# The default invocation with no argument must still target this repository.
"${audit}" > "${output}"
grep -q '^occupancy-calculator[[:space:]]' "${output}"

echo "context audit description styles: ok"
