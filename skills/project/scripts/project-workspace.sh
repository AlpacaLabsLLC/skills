#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"

die() {
  printf 'project-workspace: %s\n' "$*" >&2
  exit 1
}

validate_safe_path() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe project target: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "project target contains control characters" ;;
  esac
}

validate_new_target() {
  local base
  validate_safe_path "$1"
  base=$(basename -- "$1")
  validate_project_id "$base"
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*$'\n'*|*$'\r'*|*$'\t'*) die "$1 contains a reserved character" ;;
  esac
}

validate_project_id() {
  local project_id=${1:-}
  printf '%s\n' "$project_id" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$' ||
    die "project id must use uppercase YYYY-MM-CCC-PROJECT-NAME format"
}

validate_project_type() {
  case "${1:-}" in internal|client) ;; *) die "project type must be internal or client" ;; esac
}

validate_project_status() {
  case "${1:-}" in prospective|active|on-hold|lost|withdrawn|completed|archived) ;;
    *) die "project status is invalid: ${1:-<empty>}" ;;
  esac
}

validate_client_code() {
  printf '%s\n' "${1:-}" | grep -Eq '^[A-Z]{3}$' || die "client code must be three uppercase letters"
}

validate_created_date() {
  printf '%s\n' "${1:-}" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{2}$' || die "created date must use YYYY-MM-DD"
}

validate_identity() {
  local project_id=$1
  local project_type=$2
  local project_status=$3
  local client_code=$4
  local client=$5
  local created=$6
  validate_project_id "$project_id"
  validate_project_type "$project_type"
  validate_project_status "$project_status"
  validate_client_code "$client_code"
  validate_text "client" "$client"
  validate_created_date "$created"
  case "$project_id" in "${created%-*}-$client_code-"*) ;; *) die "project id month must match created date and client code" ;; esac
  if [ "$project_type" = client ] && [ "$client" = — ]; then
    die "client projects require a client display name"
  fi
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

render_project() {
  source_file=$1
  target_file=$2
  name=$(escape_sed "$3")
  project_id=$(escape_sed "$4")
  created=$5
  project_type=$(escape_sed "$6")
  project_status=$(escape_sed "$7")
  client_code=$(escape_sed "$8")
  client=$(escape_sed "$9")
  tasks_record=$(escape_sed "${10:-[TASKS.md](TASKS.md)}")
  sed \
    -e "s|{{PROJECT_NAME}}|$name|g" \
    -e "s|{{PROJECT_ID}}|$project_id|g" \
    -e "s|{{CREATED_DATE}}|$created|g" \
    -e "s|{{PROJECT_TYPE}}|$project_type|g" \
    -e "s|{{PROJECT_STATUS}}|$project_status|g" \
    -e "s|{{CLIENT_CODE}}|$client_code|g" \
    -e "s|{{CLIENT}}|$client|g" \
    -e "s|{{TASKS_RECORD}}|$tasks_record|g" \
    "$source_file" > "$target_file"
}

render_record_readme() {
  target_file=$1
  record_type=$(escape_sed "$2")
  description=$(escape_sed "$3")
  sed -e "s|{{RECORD_TYPE}}|$record_type|g" -e "s|{{RECORD_DESCRIPTION}}|$description|g" "$TEMPLATE_DIR/record-directory-README.md" > "$target_file"
}

init_project() {
  target=$1
  name=$2
  project_id=$3
  project_type=$4
  project_status=$5
  client_code=$6
  client=$7
  task_mode=${8:-project}
  validate_new_target "$target"
  validate_text "project name" "$name"
  created=$(date +%Y-%m-%d)
  validate_identity "$project_id" "$project_type" "$project_status" "$client_code" "$client" "$created"
  case "$task_mode" in
    project|portfolio) ;;
    *) die "task mode must be project or portfolio" ;;
  esac
  [ "$(basename -- "$target")" = "$project_id" ] || die "project directory must equal Project ID exactly"

  if [ -e "$target" ] && [ ! -d "$target" ]; then
    die "target exists and is not a directory: $target"
  fi
  if [ -d "$target" ] && [ -n "$(find "$target" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    die "target directory is not empty: $target"
  fi

  mkdir -p "$target/decisions" "$target/meetings" "$target/site-reports" "$target/docs/plans" "$target/.claude/skills" "$target/.agents/skills"
  tasks_record="resolved by the tasklist skill from this project and the studio skill that owns it"
  render_project "$TEMPLATE_DIR/PROJECT.md" "$target/PROJECT.md" "$name" "$project_id" "$created" "$project_type" "$project_status" "$client_code" "$client" "$tasks_record"
  render_project "$TEMPLATE_DIR/CLAUDE.md" "$target/CLAUDE.md" "$name" "$project_id" "$created" "$project_type" "$project_status" "$client_code" "$client"
  render_project "$TEMPLATE_DIR/AGENTS.md" "$target/AGENTS.md" "$name" "$project_id" "$created" "$project_type" "$project_status" "$client_code" "$client"
  if [ "$task_mode" = project ]; then
    cp "$TEMPLATE_DIR/TASKS.md" "$target/TASKS.md"
  fi
  cp "$TEMPLATE_DIR/TIMELOG.md" "$target/TIMELOG.md"
  render_record_readme "$target/decisions/README.md" "Decision records" "numbered project decisions and their rationale"
  render_record_readme "$target/meetings/README.md" "Meeting minutes" "dated meeting records"
  render_record_readme "$target/site-reports/README.md" "Site reports" "dated field-observation records"
  render_record_readme "$target/docs/plans/README.md" "Work plans" "approved planning artifacts"
  printf 'created project: %s\n' "$target"
}

project_field() {
  awk -F'|' -v key="$2" 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)==key {print trim($3); exit}' "$1"
}

write_legacy_claude() {
  target=$1
  name=$2
  host_line=${3:-yes}
  printf '# %s — Project Instructions\n\n' "$name" > "$target"
  printf '%s\n' '- Read `PROJECT.md` before project work.' >> "$target"
  printf '%s\n' '- Treat `decisions/*.md` as the sole decision source of truth.' >> "$target"
  printf '%s\n' '- Preserve typed ownership for meetings, site reports, tasks, plans, and time.' >> "$target"
  printf '%s\n' '- Use project-relative links and never persist machine-specific absolute paths.' >> "$target"
  if [ "$host_line" = yes ]; then
    printf '%s\n' '- Project-specific Claude Code skills live in `.claude/skills/`; Codex skills use the parallel `.agents/skills/` root.' >> "$target"
  fi
}

claude_migration_state() {
  root=$1
  file="$root/CLAUDE.md"
  [ -e "$file" ] || { printf 'absent\n'; return 0; }
  [ -f "$file" ] && [ ! -L "$file" ] || die "custom CLAUDE.md requires separate user confirmation before migration; project left unchanged"
  if cmp -s "$file" "$TEMPLATE_DIR/CLAUDE.md"; then
    printf 'current\n'
    return 0
  fi
  legacy_name=$(project_field "$root/PROJECT.md" "Project")
  [ -n "$legacy_name" ] || die "custom CLAUDE.md requires separate user confirmation before migration; project left unchanged"
  expected=$(mktemp "$root/.project-legacy-claude.XXXXXX")
  write_legacy_claude "$expected" "$legacy_name" yes
  if cmp -s "$file" "$expected"; then
    rm -f "$expected"
    printf 'generated-v2\n'
    return 0
  fi
  write_legacy_claude "$expected" "$legacy_name" no
  if cmp -s "$file" "$expected"; then
    rm -f "$expected"
    printf 'generated-v2\n'
    return 0
  fi
  rm -f "$expected"
  die "custom CLAUDE.md requires separate user confirmation before migration; project left unchanged"
}

preflight_standalone_commercial_records() {
  root=$1
  [ ! -e "$root/PROPOSALS.md" ] && [ ! -L "$root/PROPOSALS.md" ] ||
    die "standalone format-2 PROPOSALS.md requires studio-owned migration; project left unchanged. Preserve the register and run /as:studio migrate from a user-confirmed version-2 studio manifest"
}

validate_legacy_decisions() {
  root=$1
  grep -q '^## Decisions$' "$root/PROJECT.md" || return 0
  [ -d "$root/decisions" ] || die "decisions directory not found at $root"
  rows=$(mktemp "$root/.project-migration-rows.XXXXXX")
  awk -F'|' '
    /^## Decisions$/ {inside=1; next}
    inside && /^## / {inside=0}
    inside && /^\|/ {
      id=$2; status=$4
      gsub(/^[ \t]+|[ \t]+$/, "", id)
      gsub(/^[ \t]+|[ \t]+$/, "", status)
      if (id != "" && id != "#" && id != "---") print id "\t" status
    }
  ' "$root/PROJECT.md" > "$rows"
  while IFS=$'\t' read -r id expected_status; do
    [ -n "$id" ] || continue
    case "$id" in (*[!0-9]*) rm -f "$rows"; die "malformed legacy decision number: $id" ;; esac
    matches=0
    matched=''
    for file in "$root"/decisions/"$(printf '%04d' "$((10#$id))")"-*.md; do
      [ -f "$file" ] || continue
      matches=$((matches + 1))
      matched=$file
    done
    [ "$matches" -eq 1 ] || { rm -f "$rows"; die "legacy decision $id matched $matches files"; }
    actual_status=$(sed -n 's/^- \*\*Status:\*\* *//p' "$matched" | head -1)
    [ -n "$actual_status" ] || { rm -f "$rows"; die "decision $id has no parseable status"; }
    [ -z "$expected_status" ] || [ "$expected_status" = "$actual_status" ] || {
      rm -f "$rows"
      die "decision $id status mismatch: table=$expected_status file=$actual_status"
    }
  done < "$rows"
  rm -f "$rows"
}

project_record_matches() {
  local file=$1
  awk -F'|' -v id="$2" -v name="$3" -v type="$4" -v status="$5" -v code="$6" -v client="$7" -v created="$8" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      key=trim($2); value=trim($3)
      if (key=="Format version") version=value
      else if (key=="Project ID") project_id=value
      else if (key=="Project") project_name=value
      else if (key=="Type") project_type=value
      else if (key=="Status") project_status=value
      else if (key=="Client code") client_code=value
      else if (key=="Client") project_client=value
      else if (key=="Created") project_created=value
    }
    END {exit !(version==3 && project_id==id && project_name==name && project_type==type &&
      project_status==status && client_code==code && project_client==client && project_created==created)}
  ' "$file"
}

migrate_project_record() {
  root=$1
  project_id=$2
  name=$3
  project_type=$4
  project_status=$5
  client_code=$6
  client=$7
  created=$8
  mode=${9:-preview}
  validate_safe_path "$root"
  validate_text "project name" "$name"
  validate_identity "$project_id" "$project_type" "$project_status" "$client_code" "$client" "$created"
  [ -f "$root/PROJECT.md" ] || die "PROJECT.md not found at $root"
  [ "$mode" = preview ] || [ "$mode" = --apply ] || die "migration mode must be preview or --apply"
  format_version=$(project_field "$root/PROJECT.md" "Format version")
  case "$format_version" in
    3)
      project_record_matches "$root/PROJECT.md" "$project_id" "$name" "$project_type" "$project_status" "$client_code" "$client" "$created" ||
        die "version 3 project identity does not match the confirmed migration manifest"
      printf 'already migrated: %s\n' "$root"
      return 0
      ;;
    ''|1|2) ;;
    *) die "unsupported project format version: $format_version" ;;
  esac
  validate_legacy_decisions "$root"
  grep -q '^## Identity$' "$root/PROJECT.md" || die "PROJECT.md has no Identity section"
  if [ "$mode" != --apply ]; then
    printf 'migration ready: project format %s -> 3 (%s)\n' "${format_version:-unversioned}" "$project_id"
    return 0
  fi

  tmp=$(mktemp "$root/.project-v3-migration.XXXXXX")
  awk -F'|' \
    -v id="$project_id" -v name="$name" -v type="$project_type" -v status="$project_status" \
    -v code="$client_code" -v client="$client" -v created="$created" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    function identity_rows() {
      print "| Format version | 3 | explicit v2-to-v3 migration | " created " |"
      print "| Project ID | " id " | explicit v2-to-v3 migration | " created " |"
      print "| Project | " name " | explicit v2-to-v3 migration | " created " |"
      print "| Type | " type " | explicit v2-to-v3 migration | " created " |"
      print "| Status | " status " | explicit v2-to-v3 migration | " created " |"
      print "| Created | " created " | explicit v2-to-v3 migration | " created " |"
      print "| Client code | " code " | explicit v2-to-v3 migration | " created " |"
      print "| Client | " client " | explicit v2-to-v3 migration | " created " |"
    }
    /^## Identity$/ {identity=1; identity_seen=1; print; next}
    identity && /^\|/ {
      field=trim($2)
      if (field=="Field") {print; next}
      if (field=="---") {print; identity_rows(); rows_written=1; next}
      if (field=="Format version" || field=="Project ID" || field=="Project" || field=="Type" ||
          field=="Status" || field=="Created" || field=="Client code" || field=="Client") next
      print
      next
    }
    identity && /^## / {identity=0}
    /^## Decisions$/ {
      if (!decisions_replaced) {
        print "## Project records"
        print ""
        print "- Decision records: [decisions/](decisions/)"
        decisions_replaced=1
      }
      legacy_decisions=1
      next
    }
    legacy_decisions && /^## / {legacy_decisions=0}
    legacy_decisions {next}
    {print}
    END {if (!identity_seen || !rows_written) exit 2}
  ' "$root/PROJECT.md" > "$tmp" || { rm -f "$tmp"; die "PROJECT.md Identity table is not parseable"; }
  mv "$tmp" "$root/PROJECT.md"
  [ "${ARCH_PROJECT_FAIL_AT:-}" != after-record ] || die "injected failure after project record migration"
  project_record_matches "$root/PROJECT.md" "$project_id" "$name" "$project_type" "$project_status" "$client_code" "$client" "$created" ||
    die "migrated PROJECT.md failed identity verification"
  printf 'migrated project record: %s\n' "$root"
}

migrate_project() {
  root=$1
  shift
  [ "$#" -ge 7 ] && [ "$#" -le 8 ] || die "usage: $0 migrate <project-root> <project-id> <project-name> <internal|client> <status> <client-code> <client> <created> [--apply]"
  project_id=$1; name=$2; project_type=$3; project_status=$4; client_code=$5; client=$6; created=$7; mode=${8:-preview}
  validate_safe_path "$root"
  [ -f "$root/PROJECT.md" ] && [ ! -L "$root/PROJECT.md" ] || die "PROJECT.md is missing or symlinked at $root"
  [ "$mode" = preview ] || [ "$mode" = --apply ] || die "migration mode must be preview or --apply"
  parent=$(dirname -- "$root")
  target="$parent/$project_id"
  validate_new_target "$target"
  format_version=$(project_field "$root/PROJECT.md" "Format version")
  case "$format_version" in
    ''|1|2)
      preflight_standalone_commercial_records "$root"
      claude_state=$(claude_migration_state "$root")
      ;;
    3) claude_state=current ;;
    *) claude_state=unsupported ;;
  esac
  if [ "$mode" != --apply ]; then
    migrate_project_record "$root" "$project_id" "$name" "$project_type" "$project_status" "$client_code" "$client" "$created" preview
    if [ "$claude_state" = generated-v2 ]; then
      printf 'CLAUDE.md: replace recognized generated version-2 instructions with @AGENTS.md import\n'
    fi
    [ "$root" = "$target" ] || printf 'rename: %s -> %s\n' "$root" "$target"
    return 0
  fi
  [ "$root" = "$target" ] || [ ! -e "$target" ] || die "migration target already exists: $target"
  transaction=$(mktemp -d "$parent/.project-v3-transaction.XXXXXX")
  cp "$root/PROJECT.md" "$transaction/PROJECT.md"
  had_claude=0
  if [ -f "$root/CLAUDE.md" ]; then cp "$root/CLAUDE.md" "$transaction/CLAUDE.md"; had_claude=1; fi
  moved=0
  committed=0
  rollback_failed_step=''
  rollback_project_migration() {
    [ "$committed" -eq 0 ] || return 0
    if [ "$moved" -eq 1 ] && [ -d "$target" ] && [ ! -e "$root" ]; then
      rollback_failed_step='restore project directory with mv'
      [ "${ARCH_PROJECT_ROLLBACK_FAIL_AT:-}" != restore-project-directory ] || return 1
      mv "$target" "$root" || return 1
    fi
    if [ ! -d "$root" ]; then
      rollback_failed_step='locate original project directory'
      return 1
    fi
    rollback_failed_step='restore PROJECT.md with cp'
    [ "${ARCH_PROJECT_ROLLBACK_FAIL_AT:-}" != restore-project-record ] || return 1
    cp "$transaction/PROJECT.md" "$root/PROJECT.md" || return 1
    if [ "$had_claude" -eq 1 ]; then
      rollback_failed_step='restore CLAUDE.md with cp'
      [ "${ARCH_PROJECT_ROLLBACK_FAIL_AT:-}" != restore-claude-record ] || return 1
      cp "$transaction/CLAUDE.md" "$root/CLAUDE.md" || return 1
    else
      rollback_failed_step='remove generated CLAUDE.md'
      rm -f "$root/CLAUDE.md" || return 1
    fi
    rollback_failed_step=''
    return 0
  }
  cleanup_project_migration() { rm -rf "$transaction"; }
  finalize_project_migration() {
    exit_status=$?
    trap - EXIT
    if [ "$committed" -eq 0 ]; then
      if rollback_project_migration; then
        if ! cleanup_project_migration; then
          printf 'project-workspace: rollback succeeded but transaction cleanup failed; recovery snapshot may remain at %s\n' "$transaction" >&2
          exit 1
        fi
      else
        printf 'project-workspace: rollback failed at %s; recovery snapshot preserved at %s\n' "$rollback_failed_step" "$transaction" >&2
        exit 1
      fi
    fi
    exit "$exit_status"
  }
  trap 'finalize_project_migration' EXIT
  migrate_project_record "$root" "$project_id" "$name" "$project_type" "$project_status" "$client_code" "$client" "$created" --apply
  if [ "$claude_state" = generated-v2 ]; then
    cp "$TEMPLATE_DIR/CLAUDE.md" "$root/CLAUDE.md"
    cmp -s "$root/CLAUDE.md" "$TEMPLATE_DIR/CLAUDE.md" || die "migrated CLAUDE.md failed @AGENTS.md import verification"
  fi
  if [ "$root" != "$target" ]; then mv "$root" "$target"; moved=1; fi
  [ "${ARCH_PROJECT_FAIL_AT:-}" != after-rename ] || die "injected failure after project directory rename"
  project_record_matches "$target/PROJECT.md" "$project_id" "$name" "$project_type" "$project_status" "$client_code" "$client" "$created" || die "migrated project failed verification"
  if [ "$claude_state" = generated-v2 ]; then cmp -s "$target/CLAUDE.md" "$TEMPLATE_DIR/CLAUDE.md" || die "migrated CLAUDE.md failed final verification"; fi
  committed=1
  if ! cleanup_project_migration; then
    trap - EXIT
    die "migration committed but transaction cleanup failed; recovery snapshot may remain at $transaction"
  fi
  trap - EXIT
  printf 'migrated project: %s\n' "$target"
}

case "${1:-}" in
  init) [ "$#" -ge 8 ] && [ "$#" -le 9 ] || die "usage: $0 init <target> <project-name> <project-id> <internal|client> <status> <client-code> <client> [project|portfolio]"; init_project "$2" "$3" "$4" "$5" "$6" "$7" "$8" "${9:-project}" ;;
  migrate-record) [ "$#" -ge 9 ] && [ "$#" -le 10 ] || die "usage: $0 migrate-record <project-root> <project-id> <project-name> <internal|client> <status> <client-code> <client> <created> [--apply]"; migrate_project_record "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9" "${10:-preview}" ;;
  migrate) [ "$#" -ge 9 ] && [ "$#" -le 10 ] || die "usage: $0 migrate <project-root> <project-id> <project-name> <internal|client> <status> <client-code> <client> <created> [--apply]"; migrate_project "$2" "${@:3}" ;;
  *) die "usage: $0 {init|migrate} ..." ;;
esac
