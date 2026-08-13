#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

die() {
  printf 'proposal-register: %s\n' "$*" >&2
  exit 1
}

validate_root() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe register root: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "register root contains control characters" ;;
  esac
  [ -d "$1" ] || die "register root is not a directory: $1"
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*$'\n'*|*$'\r'*) die "$1 contains a reserved character" ;;
  esac
}

validate_relative_dir() {
  case "${1:-}" in
    ''|/*) die "proposals directory must be a relative path" ;;
  esac
  case "/$1/" in
    */../*|*/./*|*//*) die "proposals directory may not contain dot segments" ;;
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

require_register() {
  validate_root "$1"
  [ -f "$1/PROPOSALS.md" ] || die "PROPOSALS.md not found at $1"
  version=$(trim_field "$1/PROPOSALS.md" "Format version")
  [ "$version" = 2 ] || die "register format version is ${version:-absent}; version 2 is required (migrate explicitly before writing)"
  prefix=$(trim_field "$1/PROPOSALS.md" "Proposal prefix")
  case "$prefix" in
    [A-Z]*) ;;
    *) die "register proposal prefix is missing or invalid" ;;
  esac
  printf '%s' "$prefix" | grep -Eq '^[A-Z][A-Z0-9]{1,5}$' || die "register proposal prefix is invalid: $prefix"
}

next_number() {
  root=$1
  prefix=$(trim_field "$root/PROPOSALS.md" "Proposal prefix")
  max=$(awk -F'|' -v prefix="$prefix" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      n = trim($2)
      if (n ~ ("^" prefix "-[0-9][0-9][0-9][0-9]$")) {
        num = substr(n, length(prefix) + 2) + 0
        if (num > max) max = num
      }
    }
    END {print max + 0}
  ' "$root/PROPOSALS.md")
  printf '%s-%04d\n' "$prefix" $((max + 1))
}

init_register() {
  root=$1
  owner=$2
  prefix=$3
  validate_root "$root"
  validate_text "owner name" "$owner"
  validate_text "proposal prefix" "$prefix"
  printf '%s' "$prefix" | grep -Eq '^[A-Z][A-Z0-9]{1,5}$' || die "proposal prefix must be 2-6 characters, uppercase letters and digits, starting with a letter"
  [ ! -e "$root/PROPOSALS.md" ] || die "PROPOSALS.md already exists at $root"
  owner_escaped=$(escape_sed "$owner")
  prefix_escaped=$(escape_sed "$prefix")
  sed \
    -e "s|{{OWNER_NAME}}|$owner_escaped|g" \
    -e "s|{{PROPOSAL_PREFIX}}|$prefix_escaped|g" \
    "$TEMPLATE_DIR/PROPOSALS.md" > "$root/PROPOSALS.md"
  printf 'created register: %s/PROPOSALS.md\n' "$root"
}

create_proposal() {
  root=$1
  relative_dir=$2
  project_id=$3
  client=$4
  title=$5
  slug=$6
  issued=$7
  require_register "$root"
  validate_relative_dir "$relative_dir"
  validate_text "project id" "$project_id"
  validate_text "client" "$client"
  validate_text "title" "$title"
  validate_text "issued date" "$issued"
  case "$slug" in
    ''|*[!a-z0-9-]*|-*|*-) die "slug must be lowercase kebab-case" ;;
  esac

  number=$(next_number "$root")
  file_name="$number-$slug.md"
  relative_path="$relative_dir/$file_name"
  [ ! -e "$root/$relative_path" ] || die "proposal file already exists: $relative_path"

  if awk -F'|' -v num="$number" -v path="$relative_path" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && (trim($2)==num || trim($8)==path) {found=1}
    END {exit found ? 0 : 1}
  ' "$root/PROPOSALS.md"; then
    die "proposal number or path is already registered"
  fi

  mkdir -p "$root/$relative_dir"
  number_escaped=$(escape_sed "$number")
  title_escaped=$(escape_sed "$title")
  date_escaped=$(escape_sed "$issued")
  client_escaped=$(escape_sed "$client")
  project_escaped=$(escape_sed "$project_id")
  sed \
    -e "s|{{PROPOSAL_NUMBER}}|$number_escaped|g" \
    -e "s|{{TITLE}}|$title_escaped|g" \
    -e "s|{{DATE}}|$date_escaped|g" \
    -e "s|{{CLIENT}}|$client_escaped|g" \
    -e "s|{{PROJECT_NAME}}|$project_escaped|g" \
    "$TEMPLATE_DIR/proposal.md" > "$root/$relative_path"

  tmp=$(mktemp "$root/.proposal-register.XXXXXX") || die "proposal file created at $relative_path but register update failed; register unchanged"
  if ! awk -v row="| $number | $project_id | $client | $title | $issued | draft | $relative_path |" '
    /<!-- proposals:end -->/ {print row}
    {print}
  ' "$root/PROPOSALS.md" > "$tmp"; then
    rm -f "$tmp"
    die "proposal file created at $relative_path but register update failed; register unchanged"
  fi
  mv "$tmp" "$root/PROPOSALS.md"
  printf 'created proposal: %s\n' "$relative_path"
}

set_status() {
  root=$1
  number=$2
  status=$3
  successor=${4:-}
  require_register "$root"
  validate_text "proposal number" "$number"
  case "$status" in
    sent|accepted|declined) [ -z "$successor" ] || die "successor applies only to superseded" ;;
    superseded)
      [ -n "$successor" ] || die "superseded requires a successor number"
      validate_text "successor number" "$successor"
      [ "$successor" != "$number" ] || die "a proposal may not supersede itself"
      status="superseded by $successor"
      ;;
    *) die "unknown status: $status (expected sent, accepted, declined, or superseded)" ;;
  esac

  tmp=$(mktemp "$root/.proposal-register.XXXXXX")
  if ! awk -F'|' -v num="$number" -v status="$status" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    BEGIN {found=0}
    /^\|/ && trim($2)==num {
      print "| " trim($2) " | " trim($3) " | " trim($4) " | " trim($5) " | " trim($6) " | " status " | " trim($8) " |"
      found=1
      next
    }
    {print}
    END {exit found ? 0 : 2}
  ' "$root/PROPOSALS.md" > "$tmp"; then
    rm -f "$tmp"
    die "proposal number is not registered: $number"
  fi
  mv "$tmp" "$root/PROPOSALS.md"
  printf 'status updated: %s -> %s\n' "$number" "$status"
}

verify_register() {
  root=$1
  require_register "$root"
  problems=0
  while IFS='|' read -r _ number _ _ _ _ status path _; do
    number=$(printf '%s' "$number" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    status=$(printf '%s' "$status" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    path=$(printf '%s' "$path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    case "$number" in
      Number|---|'') continue ;;
    esac
    case "/$path/" in
      */../*|*/./*|//*) printf 'unsafe path: %s (%s)\n' "$path" "$number"; problems=$((problems + 1)) ;;
      *)
        [ -f "$root/$path" ] || { printf 'missing file: %s (%s)\n' "$path" "$number"; problems=$((problems + 1)); }
        ;;
    esac
    case "$status" in
      draft|sent|accepted|declined|'superseded by '*) ;;
      *) printf 'unknown status: %s (%s)\n' "$status" "$number"; problems=$((problems + 1)) ;;
    esac
  done < <(sed -n '/<!-- proposals:start -->/,/<!-- proposals:end -->/p' "$root/PROPOSALS.md" | grep '^|' || true)
  if [ "$problems" -gt 0 ]; then
    printf 'verify found %s problem(s)\n' "$problems"
    exit 3
  fi
  printf 'register verified: %s/PROPOSALS.md\n' "$root"
}

case "${1:-}" in
  init)
    [ $# -eq 4 ] || die "usage: proposal-register.sh init <root> <owner-name> <prefix>"
    init_register "$2" "$3" "$4"
    ;;
  allocate)
    [ $# -eq 2 ] || die "usage: proposal-register.sh allocate <root>"
    require_register "$2"
    next_number "$2"
    ;;
  create)
    [ $# -eq 8 ] || die "usage: proposal-register.sh create <root> <relative-proposals-dir> <project-id> <client> <title> <slug> <issued-date>"
    create_proposal "$2" "$3" "$4" "$5" "$6" "$7" "$8"
    ;;
  set-status)
    [ $# -ge 4 ] && [ $# -le 5 ] || die "usage: proposal-register.sh set-status <root> <number> <sent|accepted|declined|superseded> [successor]"
    set_status "$2" "$3" "$4" "${5:-}"
    ;;
  verify)
    [ $# -eq 2 ] || die "usage: proposal-register.sh verify <root>"
    verify_register "$2"
    ;;
  *)
    die "usage: proposal-register.sh {init|allocate|create|set-status|verify} ..."
    ;;
esac
