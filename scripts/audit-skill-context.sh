#!/usr/bin/env bash
set -euo pipefail

# Keep byte classification and sort order stable across developer and CI locales.
export LC_ALL=C
export LANG=C

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# Optional skills root, so this can be pointed at a fixture tree in tests.
# Defaults to this repository's skills/ directory.
skills_root="${1:-${repo_root}/skills}"

awk '
function ceil4(n) { return int((n + 3) / 4) }
function emit() {
  if (!seen_desc) {
    printf "ERROR: missing description in %s\n", file > "/dev/stderr"
    exit 2
  }
  body_chars = length(body)
  desc_words = split(desc, dw, /[[:space:]]+/)
  body_words = split(body, bw, /[[:space:]]+/)
  printf "%s\t%d\t%d\t%d\t%d\t%d\t%d\t%d\n", skill, length(desc), desc_words, desc_lines, ceil4(length(desc)), body_chars, body_words, body_lines
}
FNR == 1 {
  if (NR != 1) emit()
  file = FILENAME
  skill = FILENAME
  sub(/^.*\/skills\//, "", skill)
  sub(/\/SKILL\.md$/, "", skill)
  in_front = 0; front_done = 0; in_desc = 0; seen_desc = 0
  desc = ""; body = ""; desc_lines = 0; body_lines = 0
}
$0 == "---" && !front_done {
  if (!in_front) { in_front = 1; next }
  in_front = 0; front_done = 1; in_desc = 0; next
}
in_front && /^description:[[:space:]]*/ {
  line = $0; sub(/^description:[[:space:]]*/, "", line)
  style = line
  if (style == ">" || style == "|-" || style == "|" || style == ">-") {
    in_desc = 1; folded = (substr(style, 1, 1) == ">"); seen_desc = 1; next
  }
  # A bare "description:" followed by indented lines is a valid plain
  # multi-line YAML scalar and folds like ">". Without this branch the
  # continuation lines match no rule, are dropped, and the skill is reported
  # with a zero-character description.
  if (style == "") { in_desc = 1; folded = 1; seen_desc = 1; next }
  if ((substr(line,1,1) == "\"" && substr(line,length(line),1) == "\"") || (substr(line,1,1) == "\047" && substr(line,length(line),1) == "\047")) line = substr(line,2,length(line)-2)
  desc = line; desc_lines = 1; seen_desc = 1; in_desc = 0; next
}
in_front && in_desc {
  if ($0 ~ /^[^[:space:]]/) { in_desc = 0 }
  else {
    line = $0; sub(/^[[:space:]]+/, "", line)
    if (desc != "") desc = desc (folded ? " " : "\n")
    desc = desc line; desc_lines++; next
  }
}
front_done {
  if (body != "") body = body "\n"
  body = body $0; body_lines++
}
END { emit() }
' "${skills_root}"/*/SKILL.md | {
  printf 'skill\tdescription_chars\tdescription_words\tdescription_lines\tdescription_est_tokens\tbody_chars\tbody_words\tbody_lines\n'
  sort -t $'\t' -k5,5nr
}
