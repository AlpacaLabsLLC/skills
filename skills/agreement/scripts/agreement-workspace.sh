#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

die() {
  printf 'agreement-workspace: %s\n' "$*" >&2
  exit 1
}

validate_root() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe root: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "root contains control characters" ;;
  esac
  [ -d "$1" ] || die "root is not a directory: $1"
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*$'\n'*|*$'\r'*) die "$1 contains a reserved character" ;;
  esac
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

trim_field() {
  awk -F'|' -v key="$2" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)==key {print trim($3); exit}
  ' "$1"
}

require_agreement() {
  validate_root "$1"
  [ -f "$1/agreement/AGREEMENT.md" ] || die "agreement/AGREEMENT.md not found at $1"
  version=$(trim_field "$1/agreement/AGREEMENT.md" "Format version")
  [ "$version" = 2 ] || die "agreement format version is ${version:-absent}; version 2 is required (migrate explicitly before writing)"
}

register_status() {
  register=$1
  number=$2
  awk -F'|' -v num="$number" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)==num {print trim($7); exit}
  ' "$register"
}

promote_agreement() {
  project_root=$1
  register_root=$2
  number=$3
  accepted_path=$4
  project_name=$5
  created=$6
  validate_root "$project_root"
  validate_root "$register_root"
  validate_text "proposal number" "$number"
  validate_text "project name" "$project_name"
  validate_text "created date" "$created"

  [ -f "$register_root/PROPOSALS.md" ] || die "PROPOSALS.md not found at $register_root"
  status=$(register_status "$register_root/PROPOSALS.md" "$number")
  [ -n "$status" ] || die "proposal number is not registered: $number"
  [ "$status" = "accepted" ] || die "proposal $number is '$status'; only an accepted proposal can be promoted"

  [ -f "$register_root/$accepted_path" ] || die "accepted proposal file not found: $accepted_path"
  [ ! -e "$project_root/agreement/AGREEMENT.md" ] || die "agreement already exists at $project_root/agreement (append amendments instead of re-promoting)"

  accepted_file=$(basename -- "$accepted_path")
  mkdir -p "$project_root/agreement/sow"
  [ ! -e "$project_root/agreement/$accepted_file" ] || die "accepted document already present: agreement/$accepted_file (accepted documents are append-only)"
  cp "$register_root/$accepted_path" "$project_root/agreement/$accepted_file"

  name_escaped=$(escape_sed "$project_name")
  number_escaped=$(escape_sed "$number")
  path_escaped=$(escape_sed "$accepted_path")
  file_escaped=$(escape_sed "$accepted_file")
  created_escaped=$(escape_sed "$created")
  sed \
    -e "s|{{PROJECT_NAME}}|$name_escaped|g" \
    -e "s|{{PROPOSAL_NUMBER}}|$number_escaped|g" \
    -e "s|{{ACCEPTED_PATH}}|$path_escaped|g" \
    -e "s|{{ACCEPTED_FILE}}|$file_escaped|g" \
    -e "s|{{CREATED_DATE}}|$created_escaped|g" \
    "$TEMPLATE_DIR/AGREEMENT.md" > "$project_root/agreement/AGREEMENT.md"
  printf 'promoted: agreement/AGREEMENT.md and agreement/%s\n' "$accepted_file"
}

record_amendment() {
  project_root=$1
  file_name=$2
  summary=$3
  amended=$4
  require_agreement "$project_root"
  validate_text "amendment file name" "$file_name"
  validate_text "summary" "$summary"
  validate_text "date" "$amended"
  case "$file_name" in
    */*|..*) die "amendment file name must be a bare file name" ;;
  esac
  target="agreement/sow/$file_name"
  [ -f "$project_root/$target" ] || die "amendment document not found: $target (place the file first; recording never creates content)"

  next=$(awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      n = trim($2)
      if (n ~ /^[0-9]+$/ && n + 0 > max) max = n + 0
    }
    END {print max + 1}
  ' "$project_root/agreement/AGREEMENT.md")

  tmp=$(mktemp "$project_root/agreement/.agreement.XXXXXX")
  if ! awk -v row="| $next | $amended | [$file_name](sow/$file_name) | $summary |" '
    /<!-- amendments:end -->/ {print row}
    {print}
  ' "$project_root/agreement/AGREEMENT.md" > "$tmp"; then
    rm -f "$tmp"
    die "amendment row insert failed; AGREEMENT.md unchanged"
  fi
  mv "$tmp" "$project_root/agreement/AGREEMENT.md"
  printf 'recorded amendment %s: %s\n' "$next" "$target"
}

verify_agreement() {
  project_root=$1
  require_agreement "$project_root"
  problems=0
  for heading in '## Identity' '## Terms' '## Scope' '### In scope' '### Not in scope' '### Requires SOW' '## Amendments' '## Documents'; do
    grep -q "^$heading\$" "$project_root/agreement/AGREEMENT.md" || { printf 'missing heading: %s\n' "$heading"; problems=$((problems + 1)); }
  done
  while IFS='|' read -r _ num _ doc _; do
    num=$(printf '%s' "$num" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    doc=$(printf '%s' "$doc" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    case "$num" in
      '#'|---|'') continue ;;
    esac
    file=$(printf '%s' "$doc" | sed -n 's/.*(\(.*\)).*/\1/p')
    [ -n "$file" ] && [ -f "$project_root/agreement/$file" ] || { printf 'missing amendment file: %s (row %s)\n' "${file:-unparseable}" "$num"; problems=$((problems + 1)); }
  done < <(sed -n '/<!-- amendments:start -->/,/<!-- amendments:end -->/p' "$project_root/agreement/AGREEMENT.md" | grep '^|' || true)
  if [ "$problems" -gt 0 ]; then
    printf 'verify found %s problem(s)\n' "$problems"
    exit 3
  fi
  printf 'agreement verified: %s/agreement/AGREEMENT.md\n' "$project_root"
}

case "${1:-}" in
  promote)
    [ $# -eq 7 ] || die "usage: agreement-workspace.sh promote <project-root> <register-root> <number> <accepted-path> <project-name> <date>"
    promote_agreement "$2" "$3" "$4" "$5" "$6" "$7"
    ;;
  record-amendment)
    [ $# -eq 5 ] || die "usage: agreement-workspace.sh record-amendment <project-root> <file-name> <summary> <date>"
    record_amendment "$2" "$3" "$4" "$5"
    ;;
  verify)
    [ $# -eq 2 ] || die "usage: agreement-workspace.sh verify <project-root>"
    verify_agreement "$2"
    ;;
  *)
    die "usage: agreement-workspace.sh {promote|record-amendment|verify} ..."
    ;;
esac
