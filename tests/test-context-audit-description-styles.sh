#!/usr/bin/env bash
set -euo pipefail

# Every YAML description style a SKILL.md may legally use must be measured the
# way YAML defines it, not just the inline form the bundled skills happen to use
# today. Each style folds, chomps, and strips comments by its own rules.
#
# Regression: the audit reconstructed the description by hand instead of parsing
# it, so a bare "description:" followed by indented continuation lines (a valid
# plain multi-line scalar) matched no rule, was dropped, and the skill was
# reported with a zero-character description. That is silent: nothing errors,
# the row is simply wrong, and any total built from it is wrong too. Five more
# styles were measured wrong in quieter ways, from a trailing comment counted as
# description text to a multi-line quoted scalar truncated at its first line.

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
audit="${repo_root}/scripts/audit-skill-context.sh"

fixture="$(mktemp -d)"
output="$(mktemp)"
trap 'rm -rf "${fixture}" "${output}"' EXIT

# The audit derives a skill name by stripping everything up to "/skills/",
# so the fixture tree needs that component.
mkdir -p "${fixture}/skills"

# Writes one fixture skill, reading its description block from stdin.
write_skill() {
  local name="$1"
  mkdir -p "${fixture}/skills/${name}"
  {
    echo "---"
    echo "name: ${name}"
    cat
    echo "---"
    echo
    echo "Body line."
  } > "${fixture}/skills/${name}/SKILL.md"
}

# Nearly every fixture carries the same 19-character description "Alpha bravo
# charlie" through a different YAML style. The exceptions are called out where
# they appear, and each is 20 for a reason YAML defines.
write_skill inline <<'EOF'
description: Alpha bravo charlie
EOF

# A "#" preceded by whitespace opens a comment, even on the key line.
write_skill inline-comment <<'EOF'
description: Alpha bravo charlie # not part of the description
EOF

write_skill double-quoted <<'EOF'
description: "Alpha bravo charlie"
EOF

# "\n" inside a double-quoted scalar is one character, not two.
write_skill double-quoted-escape <<'EOF'
description: "Alpha\nbravo charlie"
EOF

# A quoted scalar may continue on the next line; the break folds to a space.
write_skill double-quoted-multiline <<'EOF'
description: "Alpha bravo
  charlie"
EOF

write_skill single-quoted <<'EOF'
description: 'Alpha bravo charlie'
EOF

# Clip chomping: ">" keeps the final line break, so this one is 20.
write_skill folded <<'EOF'
description: >
  Alpha bravo
  charlie
EOF

write_skill folded-strip <<'EOF'
description: >-
  Alpha bravo
  charlie
EOF

# A blank line inside a folded scalar becomes a newline, not a space, and the
# clipped final break makes 20.
write_skill folded-blank-line <<'EOF'
description: >
  Alpha bravo

  charlie
EOF

# Clip chomping again, so 20.
write_skill literal <<'EOF'
description: |
  Alpha bravo charlie
EOF

write_skill literal-strip <<'EOF'
description: |-
  Alpha bravo charlie
EOF

# The original regression case: no block indicator at all.
write_skill plain <<'EOF'
description:
  Alpha bravo
  charlie
EOF

# A blank line inside a plain scalar folds to a newline, not a space.
write_skill plain-blank-line <<'EOF'
description:
  Alpha bravo

  charlie
EOF

# A full-line comment ends the scalar and contributes no characters.
write_skill plain-full-comment <<'EOF'
description:
  Alpha bravo
  charlie
  # not part of the description
EOF

write_skill plain-trailing-comment <<'EOF'
description:
  Alpha bravo
  charlie # not part of the description
EOF

# A "#" not preceded by whitespace is literal text, so this one is 20.
write_skill plain-hash-in-word <<'EOF'
description:
  Alpha bravo
  char#lie
EOF

"${audit}" "${fixture}/skills" > "${output}"

column() {
  awk -F '\t' -v skill="$1" -v col="$2" '$1 == skill { print $col }' "${output}"
}

# style                    chars  source lines
expectations="
inline                     19     1
inline-comment             19     1
double-quoted              19     1
double-quoted-escape       19     1
double-quoted-multiline    19     2
single-quoted              19     1
folded                     20     2
folded-strip               19     2
folded-blank-line          20     3
literal                    20     1
literal-strip              19     1
plain                      19     2
plain-blank-line           19     3
plain-full-comment         19     2
plain-trailing-comment     19     2
plain-hash-in-word         20     2
"

failed=0
while read -r style chars lines; do
  [ -n "${style}" ] || continue
  actual_chars="$(column "${style}" 2)"
  actual_lines="$(column "${style}" 4)"
  if [ "${actual_chars}" != "${chars}" ]; then
    echo "description style '${style}' measured ${actual_chars:-<missing>} chars; expected ${chars}" >&2
    failed=1
  fi
  if [ "${actual_lines}" != "${lines}" ]; then
    echo "description style '${style}' measured ${actual_lines:-<missing>} source lines; expected ${lines}" >&2
    failed=1
  fi
done <<< "${expectations}"

test "${failed}" = "0"

# Every fixture must also report a non-empty body and a token estimate, so a
# zero never passes as a legitimate measurement.
awk -F '\t' 'NR > 1 { if ($2 < 1 || $5 < 1 || $6 < 1) exit 1 }' "${output}"

# A skill with no description is an error, not a zero-character row.
mkdir -p "${fixture}/no-description/skills/orphan"
cat > "${fixture}/no-description/skills/orphan/SKILL.md" <<'EOF'
---
name: orphan
---

Body line.
EOF
if "${audit}" "${fixture}/no-description/skills" > /dev/null 2>&1; then
  echo "a skill with no description must fail the audit" >&2
  exit 1
fi

# The default invocation with no argument must still target this repository.
"${audit}" > "${output}"
grep -q '^occupancy-calculator[[:space:]]' "${output}"

echo "context audit description styles: ok"
