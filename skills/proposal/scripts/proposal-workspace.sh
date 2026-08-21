#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE="$SCRIPT_DIR/../templates/proposal.md"

die() {
  printf 'proposal-workspace: %s\n' "$*" >&2
  exit 1
}

validate_safe_path() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe path: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "path contains control characters" ;;
  esac
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*$'\n'*|*$'\r'*|*$'\t'*) die "$1 contains a reserved character" ;;
  esac
}

validate_optional_text() {
  case "${2:-}" in
    *'|'*|*$'\n'*|*$'\r'*|*$'\t'*) die "$1 contains a reserved character" ;;
  esac
}

validate_date() {
  printf '%s\n' "${1:-}" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$' ||
    die "$2 must use YYYY-MM-DD"
}

validate_slug() {
  case "${1:-}" in
    ''|*[!a-z0-9-]*|-*|*-) die "short title must be lowercase kebab-case" ;;
  esac
}

validate_revision_token() {
  printf '%s\n' "${1:-}" | grep -Eq '^rev-[0-9]{2}$' || die "revision token must use rev-NN"
}

validate_revision_label() {
  printf '%s\n' "${1:-}" | grep -Eq '^Rev\. [0-9]{2}$' || die "Revision must use Rev. NN"
}

revision_label_from_token() {
  validate_revision_token "$1"
  printf 'Rev. %s\n' "${1#rev-}"
}

revision_token_from_label() {
  validate_revision_label "$1"
  printf 'rev-%s\n' "${1#Rev. }"
}

trim_field() {
  awk -F'|' -v key="$2" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)==key {print trim($3); exit}
  ' "$1"
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

require_project() {
  project_root=$1
  validate_safe_path "$project_root"
  [ -d "$project_root" ] && [ ! -L "$project_root" ] || die "project root is missing or symlinked: $project_root"
  [ -f "$project_root/PROJECT.md" ] && [ ! -L "$project_root/PROJECT.md" ] || die "PROJECT.md is missing or symlinked"
  project_version=$(trim_field "$project_root/PROJECT.md" "Format version")
  [ "$project_version" = 3 ] || die "PROJECT.md format version is ${project_version:-absent}; version 3 is required"
  project_id=$(trim_field "$project_root/PROJECT.md" "Project ID")
  printf '%s\n' "$project_id" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$' || die "PROJECT.md has an invalid Project ID"
  [ "$(basename -- "$project_root")" = "$project_id" ] || die "project directory must equal its immutable Project ID"
}

require_owned_proposals_directory() {
  owned_project_root=$1
  owned_proposals_root="$owned_project_root/proposals"
  [ -d "$owned_proposals_root" ] && [ ! -L "$owned_proposals_root" ] ||
    die "project proposals directory is missing or symlinked: $owned_proposals_root"
  owned_physical_project=$(cd -P -- "$owned_project_root" && pwd)
  owned_physical_proposals=$(cd -P -- "$owned_proposals_root" && pwd)
  [ "$owned_physical_proposals" = "$owned_physical_project/proposals" ] ||
    die "project proposals directory must be physically owned by the project"
}

require_proposal_path() {
  proposal_file=$1
  validate_safe_path "$proposal_file"
  [ -f "$proposal_file" ] && [ ! -L "$proposal_file" ] || die "proposal is missing or symlinked: $proposal_file"
  proposals_root=$(dirname -- "$proposal_file")
  [ "$(basename -- "$proposals_root")" = proposals ] || die "proposal must be directly inside project-local proposals/"
  proposal_project=$(dirname -- "$proposals_root")
  require_project "$proposal_project"
  physical_project=$(cd -P -- "$proposal_project" && pwd)
  physical_proposals=$(cd -P -- "$proposals_root" && pwd)
  [ "$physical_proposals" = "$physical_project/proposals" ] || die "proposals directory may not be symlinked"
}

validate_markers() {
  awk '
    /^<!-- issued-terms:start -->$/ {issued_starts++; if (issued || lifecycle) exit 3; issued=1; next}
    /^<!-- issued-terms:end -->$/ {issued_ends++; if (!issued) exit 3; issued=0; issued_closed=1; next}
    /^<!-- proposal-lifecycle:start -->$/ {life_starts++; if (issued || lifecycle || !issued_closed) exit 3; lifecycle=1; next}
    /^<!-- proposal-lifecycle:end -->$/ {life_ends++; if (!lifecycle) exit 3; lifecycle=0; next}
    END {
      if (issued_starts!=1 || issued_ends!=1 || life_starts!=1 || life_ends!=1 || issued || lifecycle) exit 3
    }
  ' "$1" || die "proposal has invalid protected-term or lifecycle markers"
}

issued_terms_hash() {
  file=$1
  if command -v shasum >/dev/null 2>&1; then
    awk '/^<!-- issued-terms:start -->$/ {inside=1; next} /^<!-- issued-terms:end -->$/ {inside=0; exit} inside {print}' "$file" |
      shasum -a 256 | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    awk '/^<!-- issued-terms:start -->$/ {inside=1; next} /^<!-- issued-terms:end -->$/ {inside=0; exit} inside {print}' "$file" |
      sha256sum | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    awk '/^<!-- issued-terms:start -->$/ {inside=1; next} /^<!-- issued-terms:end -->$/ {inside=0; exit} inside {print}' "$file" |
      openssl dgst -sha256 | awk '{print $NF}'
  else
    die "no SHA-256 tool is available"
  fi
}

validate_proposal_contents() {
  file=$1
  expected_name=$2
  validate_markers "$file"

  record_version=$(trim_field "$file" "Format version")
  record_project_id=$(trim_field "$file" "Project ID")
  record_title=$(trim_field "$file" "Title")
  short_title=$(trim_field "$file" "Short title")
  revision=$(trim_field "$file" "Revision")
  status=$(trim_field "$file" "Status")
  proposal_date=$(trim_field "$file" "Proposal date")
  checksum=$(trim_field "$file" "Issued terms SHA-256")
  frozen_on=$(trim_field "$file" "Frozen on")

  [ "$record_version" = 1 ] || die "proposal format version is ${record_version:-absent}; version 1 is required"
  [ "$record_project_id" = "$project_id" ] || die "proposal Project ID does not match PROJECT.md"
  validate_text "title" "$record_title"
  validate_slug "$short_title"
  validate_revision_label "$revision"
  revision_token=$(revision_token_from_label "$revision")
  validate_date "$proposal_date" "proposal date"
  case "$status" in draft|sent|accepted|declined|superseded) ;; *) die "proposal status is invalid: ${status:-<empty>}" ;; esac
  record_name="${proposal_date%-??}-$short_title-proposal-$revision_token.md"
  [ "$expected_name" = "$record_name" ] || die "proposal filename does not match its date, short title, and revision"

  case "$checksum" in
    —)
      [ "$frozen_on" = — ] || die "unfrozen proposal has a Frozen on date"
      ;;
    *)
      printf '%s\n' "$checksum" | grep -Eq '^[0-9a-f]{64}$' || die "proposal has an invalid issued-terms checksum"
      validate_date "$frozen_on" "Frozen on"
      actual_checksum=$(issued_terms_hash "$file")
      [ "$actual_checksum" = "$checksum" ] || die "issued terms differ from the recorded SHA-256 checksum; create a new revision"
      ;;
  esac
}

validate_proposal() {
  file=$1
  require_proposal_path "$file"
  validate_proposal_contents "$file" "$(basename -- "$file")"
}

create_proposal() {
  root=$1
  client=$2
  title=$3
  slug=$4
  proposal_date=$5
  revision_token=$6
  require_project "$root"
  validate_text "client" "$client"
  validate_text "title" "$title"
  validate_slug "$slug"
  validate_date "$proposal_date" "proposal date"
  validate_revision_token "$revision_token"
  revision=$(revision_label_from_token "$revision_token")

  proposals_dir="$root/proposals"
  [ ! -e "$proposals_dir" ] || { [ -d "$proposals_dir" ] && [ ! -L "$proposals_dir" ] || die "proposals path exists but is not a regular directory"; }
  file_name="${proposal_date%-??}-$slug-proposal-$revision_token.md"
  target="$proposals_dir/$file_name"
  [ ! -e "$target" ] && [ ! -L "$target" ] || die "proposal already exists; choose a new revision or short title: $file_name"
  mkdir -p "$proposals_dir"
  require_owned_proposals_directory "$root"

  title_escaped=$(escape_sed "$title")
  project_id_escaped=$(escape_sed "$project_id")
  client_escaped=$(escape_sed "$client")
  slug_escaped=$(escape_sed "$slug")
  date_escaped=$(escape_sed "$proposal_date")
  revision_escaped=$(escape_sed "$revision")
  tmp=$(mktemp "$proposals_dir/.proposal-create.XXXXXX")
  create_tmp=$tmp
  cleanup_create() { rm -f -- "$create_tmp"; }
  trap cleanup_create EXIT

  if [ "${ARCH_PROPOSAL_FAIL_AT:-}" = create-render-failure ]; then
    printf '# incomplete proposal render\n' > "$tmp"
    render_ok=false
  elif sed \
    -e "s|{{TITLE}}|$title_escaped|g" \
    -e "s|{{PROJECT_ID}}|$project_id_escaped|g" \
    -e "s|{{CLIENT}}|$client_escaped|g" \
    -e "s|{{SHORT_TITLE}}|$slug_escaped|g" \
    -e "s|{{PROPOSAL_DATE}}|$date_escaped|g" \
    -e "s|{{REVISION}}|$revision_escaped|g" \
    -e "s|{{LEGACY_NUMBER}}|—|g" \
    "$TEMPLATE" > "$tmp"; then
    render_ok=true
  else
    render_ok=false
  fi
  [ "$render_ok" = true ] || die "proposal render failed; canonical proposal unchanged"

  if [ "${ARCH_PROPOSAL_FAIL_AT:-}" = create-invalid-temp ]; then
    printf '\n<!-- issued-terms:end -->\n' >> "$tmp"
  fi
  if message=$(validate_proposal_contents "$tmp" "$file_name" 2>&1); then
    :
  else
    die "created proposal failed verification: $message"
  fi

  [ ! -e "$target" ] && [ ! -L "$target" ] || die "proposal appeared during creation; refusing to overwrite it: $file_name"
  if ! mv "$tmp" "$target"; then
    die "proposal publication failed; canonical proposal unchanged"
  fi
  create_tmp=
  trap - EXIT
  printf 'created proposal: proposals/%s\n' "$file_name"
}

migrate_legacy_proposal() {
  [ "$#" -ge 9 ] || die "usage: proposal-workspace.sh migrate-legacy <legacy-file> <project-root> <legacy-number> <client> <title> <proposal-date> <legacy-status> <short-title> <rev-NN> [--related <project-relative-path>] [--migration-date <YYYY-MM-DD>] [--apply]"
  legacy_file=$1
  root=$2
  legacy_number=$3
  client=$4
  title=$5
  proposal_date=$6
  legacy_status=$7
  slug=$8
  revision_token=$9
  shift 9
  mode=preview
  related=—
  migration_date=—
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --related)
        [ "$#" -ge 2 ] || die "--related requires a project-relative proposal path"
        related=$2
        shift 2
        ;;
      --migration-date)
        [ "$#" -ge 2 ] || die "--migration-date requires YYYY-MM-DD"
        migration_date=$2
        shift 2
        ;;
      --apply)
        mode=--apply
        shift
        ;;
      *) die "unknown legacy migration option: $1" ;;
    esac
  done
  require_project "$root"
  require_owned_proposals_directory "$root"
  validate_safe_path "$legacy_file"
  [ -f "$legacy_file" ] && [ ! -L "$legacy_file" ] || die "legacy proposal is missing or symlinked: $legacy_file"
  [ "$(dirname -- "$legacy_file")" = "$root/proposals" ] || die "legacy proposal must be inside the target project's proposals/ directory"
  validate_text "legacy number" "$legacy_number"
  validate_text "client" "$client"
  validate_text "title" "$title"
  validate_date "$proposal_date" "proposal date"
  validate_slug "$slug"
  validate_revision_token "$revision_token"
  revision=$(revision_label_from_token "$revision_token")
  [ "$migration_date" = — ] || validate_date "$migration_date" "migration date"
  case "$related" in
    —) ;;
    proposals/*.md)
      [ "$(dirname -- "$related")" = proposals ] || die "related proposal must be directly inside project-local proposals/"
      ;;
    *) die "related proposal must use a project-relative proposals/*.md path" ;;
  esac
  case "$legacy_status" in
    draft|sent|accepted|declined) status=$legacy_status ;;
    superseded) status=superseded ;;
    'superseded by '*)
      status=superseded
      [ "$related" != — ] || die "legacy supersession must be resolved to exactly one project-relative proposal path"
      ;;
    *) die "legacy proposal status is invalid: $legacy_status" ;;
  esac
  [ "$status" = superseded ] || [ "$related" = — ] || die "only a superseded proposal may have a related proposal"

  file_name="${proposal_date%-??}-$slug-proposal-$revision_token.md"
  target="$root/proposals/$file_name"
  [ "$legacy_file" = "$target" ] || [ ! -e "$target" ] || die "proposal migration target already exists: $file_name"
  if [ "$mode" != --apply ]; then
    printf 'migration ready: %s -> proposals/%s\n' "$legacy_number" "$file_name"
    return 0
  fi

  tmp=$(mktemp "$root/proposals/.proposal-migration.XXXXXX")
  {
    printf '# Proposal — %s\n\n' "$title"
    printf '## Record\n\n| Field | Value |\n|---|---|\n'
    printf '| Format version | 1 |\n'
    printf '| Project ID | %s |\n' "$project_id"
    printf '| Title | %s |\n' "$title"
    printf '| Short title | %s |\n' "$slug"
    printf '| Revision | %s |\n' "$revision"
    printf '| Legacy number | %s |\n' "$legacy_number"
    printf '| Status | %s |\n' "$status"
    printf '| Issued terms SHA-256 | — |\n'
    printf '| Frozen on | — |\n\n'
    printf '<!-- issued-terms:start -->\n'
    printf '## Migrated issued terms\n\n'
    printf '| Item | Value |\n|---|---|\n'
    printf '| Proposal | %s |\n' "$title"
    printf '| Proposal date | %s |\n' "$proposal_date"
    printf '| To | %s |\n' "$client"
    printf '| Project | %s |\n\n' "$project_id"
    cat "$legacy_file"
    printf '\n<!-- issued-terms:end -->\n\n'
    printf '## Lifecycle\n\n'
    printf 'Lifecycle evidence is record metadata. It is outside the protected issued-terms block.\n\n'
    printf '<!-- proposal-lifecycle:start -->\n'
    printf '| Event | Date | Actor | Evidence | Related proposal |\n'
    printf '|---|---|---|---|---|\n'
    printf '| %s | %s | legacy migration | legacy number %s | %s |\n' "$status" "$migration_date" "$legacy_number" "$related"
    printf '<!-- proposal-lifecycle:end -->\n'
  } > "$tmp"

  if [ "$status" != draft ]; then
    migrated_checksum=$(issued_terms_hash "$tmp")
    checksum_tmp=$(mktemp "$root/proposals/.proposal-checksum.XXXXXX")
    awk -F'|' -v checksum="$migrated_checksum" -v frozen="$proposal_date" '
      function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
      /^\|/ && trim($2)=="Issued terms SHA-256" {print "| Issued terms SHA-256 | " checksum " |"; next}
      /^\|/ && trim($2)=="Frozen on" {print "| Frozen on | " frozen " |"; next}
      {print}
    ' "$tmp" > "$checksum_tmp"
    mv "$checksum_tmp" "$tmp"
  fi

  if message=$(validate_proposal_contents "$tmp" "$file_name" 2>&1); then
    :
  else
    rm -f "$tmp"
    die "migrated proposal failed verification: $message"
  fi
  mv "$tmp" "$target"
  [ "$legacy_file" = "$target" ] || rm "$legacy_file"
  printf 'migrated proposal: proposals/%s\n' "$file_name"
}

write_lifecycle_event() {
  file=$1
  new_status=$2
  event_date=$3
  actor=${4:-—}
  evidence=${5:-—}
  related=${6:-—}
  freeze=${7:-no}
  validate_proposal "$file"
  validate_date "$event_date" "event date"
  [ -n "$actor" ] || actor=—
  [ -n "$evidence" ] || evidence=—
  [ -n "$related" ] || related=—
  validate_optional_text "actor" "$actor"
  validate_optional_text "evidence" "$evidence"
  validate_optional_text "related proposal" "$related"
  source_issued_hash=$(issued_terms_hash "$file")

  new_checksum=$checksum
  new_frozen_on=$frozen_on
  if [ "$freeze" = yes ] && [ "$checksum" = — ]; then
    new_checksum=$(issued_terms_hash "$file")
    new_frozen_on=$event_date
  fi

  tmp=$(mktemp "$(dirname -- "$file")/.proposal-update.XXXXXX")
  if ! awk -F'|' \
    -v status="$new_status" -v checksum="$new_checksum" -v frozen="$new_frozen_on" \
    -v event="$new_status" -v event_date="$event_date" -v actor="$actor" \
    -v evidence="$evidence" -v related="$related" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^## Record$/ {in_record=1; print; next}
    /^## / && in_record {in_record=0}
    in_record && /^\|/ {
      field=trim($2)
      if (field=="Status") {print "| Status | " status " |"; status_written++; next}
      if (field=="Issued terms SHA-256") {print "| Issued terms SHA-256 | " checksum " |"; checksum_written++; next}
      if (field=="Frozen on") {print "| Frozen on | " frozen " |"; frozen_written++; next}
    }
    /^<!-- proposal-lifecycle:end -->$/ {
      print "| " event " | " event_date " | " actor " | " evidence " | " related " |"
      event_written++
    }
    {print}
    END {if (status_written!=1 || checksum_written!=1 || frozen_written!=1 || event_written!=1) exit 3}
  ' "$file" > "$tmp"; then
    rm -f "$tmp"
    die "proposal metadata or lifecycle table is malformed"
  fi
  if [ "${ARCH_PROPOSAL_FAIL_AT:-}" = lifecycle-invalid-temp ]; then
    printf '\n<!-- issued-terms:end -->\n' >> "$tmp"
  fi
  if message=$(validate_proposal_contents "$tmp" "$(basename -- "$file")" 2>&1); then
    :
  else
    rm -f "$tmp"
    die "updated proposal failed verification: $message"
  fi
  updated_issued_hash=$(issued_terms_hash "$tmp")
  if [ "$updated_issued_hash" != "$source_issued_hash" ]; then
    rm -f "$tmp"
    die "lifecycle update changed protected issued terms"
  fi
  mv "$tmp" "$file"
  printf 'proposal status: %s -> %s\n' "$(basename -- "$file")" "$new_status"
}

send_proposal() {
  [ "$#" -ge 2 ] && [ "$#" -le 4 ] || die "usage: proposal-workspace.sh send <proposal-file> <date> [actor] [evidence]"
  write_lifecycle_event "$1" sent "$2" "${3:-—}" "${4:-—}" — yes
}

set_status() {
  [ "$#" -ge 3 ] && [ "$#" -le 6 ] || die "usage: proposal-workspace.sh set-status <proposal-file> <accepted|declined|superseded|draft> <date> [actor] [evidence] [related-path]"
  file=$1
  requested=$2
  case "$requested" in accepted|declined|superseded|draft) ;; *) die "unknown proposal status: $requested" ;; esac
  freeze=no
  [ "$requested" != accepted ] || freeze=yes
  write_lifecycle_event "$file" "$requested" "$3" "${4:-—}" "${5:-—}" "${6:-—}" "$freeze"
}

relative_proposal_path() {
  file=$1
  printf 'proposals/%s\n' "$(basename -- "$file")"
}

status_proposal() {
  file=$1
  validate_proposal "$file"
  printf 'path\t%s\n' "$(relative_proposal_path "$file")"
  printf 'status\t%s\n' "$status"
  printf 'title\t%s\n' "$record_title"
  printf 'date\t%s\n' "$proposal_date"
  printf 'revision\t%s\n' "$revision"
  printf 'issued-terms-sha256\t%s\n' "$checksum"
  printf 'integrity\tverified\n'
}

list_proposals() {
  root=$1
  require_project "$root"
  proposals_dir="$root/proposals"
  [ ! -e "$proposals_dir" ] || { [ -d "$proposals_dir" ] && [ ! -L "$proposals_dir" ] || die "proposals path is not a regular directory"; }
  [ -d "$proposals_dir" ] || return 0
  while IFS= read -r file; do
    validate_proposal "$file"
    printf 'proposals/%s\t%s\t%s\t%s\t%s\n' "$(basename -- "$file")" "$status" "$record_title" "$proposal_date" "$revision"
  done < <(find "$proposals_dir" -mindepth 1 -maxdepth 1 -type f -name '*.md' -print | LC_ALL=C sort)
}

verify_proposals() {
  root=$1
  require_project "$root"
  proposals_dir="$root/proposals"
  [ ! -e "$proposals_dir" ] || { [ -d "$proposals_dir" ] && [ ! -L "$proposals_dir" ] || die "proposals path is not a regular directory"; }
  [ -d "$proposals_dir" ] || { printf 'verified proposals: 0\n'; return 0; }
  problems=0
  count=0
  while IFS= read -r file; do
    count=$((count + 1))
    if message=$(validate_proposal "$file" 2>&1); then
      :
    else
      printf 'invalid: proposals/%s — %s\n' "$(basename -- "$file")" "$message"
      problems=$((problems + 1))
    fi
  done < <(find "$proposals_dir" -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name '*.md' -print | LC_ALL=C sort)
  [ "$problems" -eq 0 ] || { printf 'verify found %s problem(s)\n' "$problems"; exit 3; }
  printf 'verified proposals: %s\n' "$count"
}

case "${1:-}" in
  create)
    [ "$#" -eq 7 ] || die "usage: proposal-workspace.sh create <project-root> <client> <title> <short-title> <proposal-date> <rev-NN>"
    create_proposal "$2" "$3" "$4" "$5" "$6" "$7"
    ;;
  send)
    shift
    send_proposal "$@"
    ;;
  set-status)
    shift
    set_status "$@"
    ;;
  status)
    [ "$#" -eq 2 ] || die "usage: proposal-workspace.sh status <proposal-file>"
    status_proposal "$2"
    ;;
  list)
    [ "$#" -eq 2 ] || die "usage: proposal-workspace.sh list <project-root>"
    list_proposals "$2"
    ;;
  verify)
    [ "$#" -eq 2 ] || die "usage: proposal-workspace.sh verify <project-root>"
    verify_proposals "$2"
    ;;
  migrate-legacy)
    shift
    migrate_legacy_proposal "$@"
    ;;
  *)
    die "usage: proposal-workspace.sh {create|send|set-status|status|list|verify|migrate-legacy} ..."
    ;;
esac
