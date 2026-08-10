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
  validate_safe_path "$1"
  base=$(basename -- "$1")
  case "$base" in
    ''|*[!a-z0-9-]*|-*|*-) die "project directory must be lowercase kebab-case" ;;
  esac
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *$'\n'*|*$'\r'*) die "$1 contains control characters" ;;
  esac
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
  tasks_record=$(escape_sed "${6:-[TASKS.md](TASKS.md)}")
  sed -e "s|{{PROJECT_NAME}}|$name|g" -e "s|{{PROJECT_ID}}|$project_id|g" -e "s|{{CREATED_DATE}}|$created|g" -e "s|{{TASKS_RECORD}}|$tasks_record|g" "$source_file" > "$target_file"
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
  task_mode=${4:-project}
  validate_new_target "$target"
  validate_text "project name" "$name"
  validate_text "project id" "$project_id"
  case "$task_mode" in
    project|portfolio) ;;
    *) die "task mode must be project or portfolio" ;;
  esac
  case "$(basename -- "$target")" in
    "$project_id"|"$project_id"-*) ;;
    *) die "project directory must equal or begin with project id $project_id" ;;
  esac

  if [ -e "$target" ] && [ ! -d "$target" ]; then
    die "target exists and is not a directory: $target"
  fi
  if [ -d "$target" ] && [ -n "$(find "$target" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    die "target directory is not empty: $target"
  fi

  mkdir -p "$target/decisions" "$target/meetings" "$target/site-reports" "$target/docs/plans" "$target/.claude/skills" "$target/.agents/skills"
  created=$(date +%Y-%m-%d)
  tasks_record="resolved by the tasklist skill from this project and the studio skill that owns it"
  render_project "$TEMPLATE_DIR/PROJECT.md" "$target/PROJECT.md" "$name" "$project_id" "$created" "$tasks_record"
  render_project "$TEMPLATE_DIR/CLAUDE.md" "$target/CLAUDE.md" "$name" "$project_id" "$created"
  render_project "$TEMPLATE_DIR/AGENTS.md" "$target/AGENTS.md" "$name" "$project_id" "$created"
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

migrate_project() {
  root=$1
  mode=${2:-preview}
  validate_safe_path "$root"
  [ -f "$root/PROJECT.md" ] || die "PROJECT.md not found at $root"
  [ -d "$root/decisions" ] || die "decisions directory not found at $root"
  format_version=$(awk -F'|' 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)=="Format version" {print trim($3); exit}' "$root/PROJECT.md")
  case "$format_version" in ''|2) ;; *) die "unsupported project format version: $format_version" ;; esac

  if ! grep -q '^## Decisions$' "$root/PROJECT.md"; then
    if grep -q 'decisions/' "$root/PROJECT.md"; then
      if [ "$format_version" = 2 ]; then
        printf 'already migrated: %s\n' "$root"
        return 0
      fi
      if [ "$mode" != "--apply" ]; then
        printf 'migration ready: add project format version 2 to link-only record\n'
        return 0
      fi
      tmp=$(mktemp "$root/.project-format-migration.XXXXXX")
      awk -v created="$(date +%Y-%m-%d)" '
        !format_added && /^\|---/ {print; print "| Format version | 2 | explicit project migration | " created " |"; format_added=1; next}
        {print}
        END {if (!format_added) exit 2}
      ' "$root/PROJECT.md" > "$tmp" || { rm -f "$tmp"; die "PROJECT.md has no parseable table for format migration"; }
      mv "$tmp" "$root/PROJECT.md"
      printf 'migrated project format: %s\n' "$root"
      return 0
    fi
    die "PROJECT.md has neither a legacy Decisions section nor a decisions link"
  fi

  rows=$(mktemp "$root/.project-migration-rows.XXXXXX")
  trap 'rm -f "$rows"' EXIT
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
    case "$id" in (*[!0-9]*) die "malformed legacy decision number: $id" ;; esac
    matches=0
    matched=''
    for file in "$root"/decisions/"$(printf '%04d' "$((10#$id))")"-*.md; do
      [ -f "$file" ] || continue
      matches=$((matches + 1))
      matched=$file
    done
    [ "$matches" -eq 1 ] || die "legacy decision $id matched $matches files"
    actual_status=$(sed -n 's/^- \*\*Status:\*\* *//p' "$matched" | head -1)
    [ -n "$actual_status" ] || die "decision $id has no parseable status"
    if [ -n "$expected_status" ] && [ "$expected_status" != "$actual_status" ]; then
      die "decision $id status mismatch: table=$expected_status file=$actual_status"
    fi
  done < "$rows"

  if [ "$mode" != "--apply" ]; then
    printf 'migration ready: replace legacy Decisions section with decisions/ link\n'
    return 0
  fi

  tmp=$(mktemp "$root/.project-migration.XXXXXX")
  awk -v add_format="$([ -z "$format_version" ] && printf 1 || printf 0)" -v created="$(date +%Y-%m-%d)" '
    add_format && !format_added && /^\|---/ {print; print "| Format version | 2 | explicit project migration | " created " |"; format_added=1; next}
    /^## Decisions$/ {
      if (!replaced) {
        print "## Project records"
        print ""
        print "- Decision records: [decisions/](decisions/)"
        replaced=1
      }
      inside=1
      next
    }
    inside && /^## / {inside=0}
    inside {next}
    {print}
  ' "$root/PROJECT.md" > "$tmp"
  mv "$tmp" "$root/PROJECT.md"
  printf 'migrated project: %s\n' "$root"
}

case "${1:-}" in
  init) [ "$#" -ge 4 ] && [ "$#" -le 5 ] || die "usage: $0 init <target> <project-name> <project-id> [project|portfolio]"; init_project "$2" "$3" "$4" "${5:-project}" ;;
  migrate) [ "$#" -ge 2 ] && [ "$#" -le 3 ] || die "usage: $0 migrate <project-root> [--apply]"; migrate_project "$2" "${3:-preview}" ;;
  *) die "usage: $0 {init|migrate} ..." ;;
esac
