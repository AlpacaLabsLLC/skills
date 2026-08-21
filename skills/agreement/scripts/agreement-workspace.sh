#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
PROPOSAL_SCRIPT="$SCRIPT_DIR/../../proposal/scripts/proposal-workspace.sh"

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
  [ -d "$1" ] && [ ! -L "$1" ] || die "root is missing or symlinked: $1"
}

require_owned_directory() {
  parent=$1
  child=$2
  label=$3
  [ -d "$child" ] && [ ! -L "$child" ] || die "$label is missing or symlinked"
  physical_parent=$(cd -P -- "$parent" && pwd)
  physical_child=$(cd -P -- "$child" && pwd)
  [ "$physical_child" = "$physical_parent/$(basename -- "$child")" ] || die "$label may not be symlinked"
}

require_project() {
  validate_root "$1"
  [ -f "$1/PROJECT.md" ] && [ ! -L "$1/PROJECT.md" ] || die "PROJECT.md is missing or symlinked"
  project_version=$(trim_field "$1/PROJECT.md" "Format version")
  [ "$project_version" = 3 ] || die "PROJECT.md format version is ${project_version:-absent}; version 3 is required"
  project_id=$(trim_field "$1/PROJECT.md" "Project ID")
  printf '%s\n' "$project_id" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$' || die "PROJECT.md has an invalid Project ID"
  [ "$(basename -- "$1")" = "$project_id" ] || die "project directory must equal its immutable Project ID"
  project_name=$(trim_field "$1/PROJECT.md" "Project")
  validate_text "project name" "$project_name"
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
  require_project "$1"
  require_owned_directory "$1" "$1/agreement" "agreement directory"
  require_owned_directory "$1/agreement" "$1/agreement/sow" "agreement/sow directory"
  [ -f "$1/agreement/AGREEMENT.md" ] && [ ! -L "$1/agreement/AGREEMENT.md" ] || die "agreement/AGREEMENT.md is missing or symlinked at $1"
  version=$(trim_field "$1/agreement/AGREEMENT.md" "Format version")
  [ "$version" = 2 ] || die "agreement format version is ${version:-absent}; version 2 is required (migrate explicitly before writing)"
}

validate_date() {
  value=${1:-}
  printf '%s\n' "$value" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' ||
    die "$2 must use YYYY-MM-DD"
  year=${value%%-*}
  remainder=${value#*-}
  month=${remainder%%-*}
  day=${remainder##*-}
  year_number=$((10#$year))
  month_number=$((10#$month))
  day_number=$((10#$day))
  [ "$year_number" -ge 1 ] || die "$2 must be a real calendar date in YYYY-MM-DD"
  case "$month_number" in
    1|3|5|7|8|10|12) max_day=31 ;;
    4|6|9|11) max_day=30 ;;
    2)
      max_day=28
      if (( year_number % 400 == 0 || (year_number % 4 == 0 && year_number % 100 != 0) )); then max_day=29; fi
      ;;
  esac
  [ "$day_number" -le "$max_day" ] || die "$2 must be a real calendar date in YYYY-MM-DD"
}

proposal_context() {
  project_root=$1
  relative_path=$2
  validate_text "proposal path" "$relative_path"
  case "$relative_path" in proposals/*.md) ;; *) die "proposal path must be a markdown file directly inside project-local proposals/" ;; esac
  case "/$relative_path/" in */../*|*/./*|*//*) die "proposal path contains unsafe segments" ;; esac
  [ "$(dirname -- "$relative_path")" = proposals ] || die "proposal path must be directly inside project-local proposals/"
  proposal_file="$project_root/$relative_path"
  [ -f "$proposal_file" ] && [ ! -L "$proposal_file" ] || die "proposal is missing or symlinked: $relative_path"
  proposal_output=$("$PROPOSAL_SCRIPT" status "$proposal_file") || die "proposal failed integrity verification: $relative_path"
  proposal_status=$(printf '%s\n' "$proposal_output" | awk -F'\t' '$1=="status" {print $2; exit}')
  proposal_checksum=$(printf '%s\n' "$proposal_output" | awk -F'\t' '$1=="issued-terms-sha256" {print $2; exit}')
  printf '%s\n' "$proposal_checksum" | grep -Eq '^[0-9a-f]{64}$' || die "proposal has no frozen issued-terms checksum: $relative_path"
  printf '%s\t%s\n' "$proposal_status" "$proposal_checksum"
}

render_agreement() {
  project_root=$1
  created=$2
  proposal_path=$3
  proposal_checksum=$4
  proposal_status=$5
  source_kind=$6
  if [ -e "$project_root/agreement" ] || [ -L "$project_root/agreement" ]; then
    require_owned_directory "$project_root" "$project_root/agreement" "agreement directory"
    if [ -e "$project_root/agreement/sow" ] || [ -L "$project_root/agreement/sow" ]; then
      require_owned_directory "$project_root/agreement" "$project_root/agreement/sow" "agreement/sow directory"
    fi
  fi
  [ ! -e "$project_root/agreement/AGREEMENT.md" ] && [ ! -L "$project_root/agreement/AGREEMENT.md" ] || die "agreement already exists at $project_root/agreement (append amendments instead of re-promoting)"

  name_escaped=$(escape_sed "$project_name")
  path_escaped=$(escape_sed "$proposal_path")
  checksum_escaped=$(escape_sed "$proposal_checksum")
  status_escaped=$(escape_sed "$proposal_status")
  source_kind_escaped=$(escape_sed "$source_kind")
  created_escaped=$(escape_sed "$created")
  if [ "$proposal_path" = — ]; then
    proposal_document="- Proposal source: — (direct agreement initialization)"
  else
    proposal_document="- Proposal source: $proposal_path — issued terms cited at SHA-256 $proposal_checksum"
  fi
  proposal_document_escaped=$(escape_sed "$proposal_document")
  tmp=$(mktemp "$project_root/.agreement.XXXXXX")
  sed \
    -e "s|{{PROJECT_NAME}}|$name_escaped|g" \
    -e "s|{{PROPOSAL_PATH}}|$path_escaped|g" \
    -e "s|{{PROPOSAL_CHECKSUM}}|$checksum_escaped|g" \
    -e "s|{{PROPOSAL_STATUS}}|$status_escaped|g" \
    -e "s|{{SOURCE_KIND}}|$source_kind_escaped|g" \
    -e "s|{{PROPOSAL_DOCUMENT}}|$proposal_document_escaped|g" \
    -e "s|{{CREATED_DATE}}|$created_escaped|g" \
    "$TEMPLATE_DIR/AGREEMENT.md" > "$tmp" || { rm -f "$tmp"; die "agreement render failed"; }
  mkdir -p "$project_root/agreement/sow"
  mv "$tmp" "$project_root/agreement/AGREEMENT.md"
}

init_agreement() {
  project_root=$1
  created=$2
  require_project "$project_root"
  validate_date "$created" "created date"
  render_agreement "$project_root" "$created" — — — "direct agreement initialization"
  printf 'initialized: agreement/AGREEMENT.md without a proposal source\n'
}

promote_agreement() {
  project_root=$1
  proposal_path=$2
  created=$3
  require_project "$project_root"
  validate_date "$created" "created date"
  context=$(proposal_context "$project_root" "$proposal_path")
  IFS=$'\t' read -r proposal_status proposal_checksum <<< "$context"
  [ "$proposal_status" = accepted ] || die "proposal must be accepted before agreement promotion: $proposal_path"
  render_agreement "$project_root" "$created" "$proposal_path" "$proposal_checksum" "$proposal_status" "project-local accepted proposal"
  printf 'promoted: agreement/AGREEMENT.md cites %s\n' "$proposal_path"
}

record_amendment() {
  project_root=$1
  file_name=$2
  summary=$3
  amended=$4
  require_agreement "$project_root"
  validate_text "amendment file name" "$file_name"
  validate_text "summary" "$summary"
  validate_date "$amended" "amendment date"
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
    /<!-- amendments:end -->/ {print row; inserted=1}
    {print}
    END {if (!inserted) exit 3}
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
  source_path=$(trim_field "$project_root/agreement/AGREEMENT.md" "Source proposal")
  source_checksum=$(trim_field "$project_root/agreement/AGREEMENT.md" "Source proposal SHA-256")
  if [ -n "$source_path" ] && [ "$source_path" != — ]; then
    if context=$(proposal_context "$project_root" "$source_path" 2>&1); then
      IFS=$'\t' read -r _current_status current_checksum <<< "$context"
      [ "$current_checksum" = "$source_checksum" ] || { printf 'proposal checksum citation mismatch: %s\n' "$source_path"; problems=$((problems + 1)); }
    else
      printf 'invalid source proposal: %s — %s\n' "$source_path" "$context"
      problems=$((problems + 1))
    fi
  fi
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
  init)
    [ $# -eq 3 ] || die "usage: agreement-workspace.sh init <project-root> <date>"
    init_agreement "$2" "$3"
    ;;
  promote)
    [ $# -eq 4 ] || die "usage: agreement-workspace.sh promote <project-root> <project-relative-proposal-path> <date>"
    promote_agreement "$2" "$3" "$4"
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
    die "usage: agreement-workspace.sh {init|promote|record-amendment|verify} ..."
    ;;
esac
