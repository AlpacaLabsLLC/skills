#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
PROJECT_TEMPLATE_DIR="$SCRIPT_DIR/../../project/templates"
TASK_TEMPLATE_DIR="$SCRIPT_DIR/../../tasklist/templates"

die() {
  printf 'studio-workspace: %s\n' "$*" >&2
  exit 1
}

validate_root() {
  case "${1:-}" in
    ''|/|.|..|"$HOME") die "unsafe studio target: ${1:-<empty>}" ;;
  esac
  case "$1" in
    *$'\n'*|*$'\r'*|*$'\t'*) die "studio target contains control characters" ;;
  esac
  base=$(basename -- "$1")
  case "$base" in
    ''|*[!a-z0-9-]*|-*|*-) die "studio directory must be lowercase kebab-case" ;;
  esac
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

render() {
  source_file=$1
  target_file=$2
  studio_name=$(escape_sed "$3")
  working_units=$(escape_sed "$4")
  country=$(escape_sed "$5")
  state_region=$(escape_sed "$6")
  city=$(escape_sed "$7")
  sed \
    -e "s|{{STUDIO_NAME}}|$studio_name|g" \
    -e "s|{{WORKING_UNITS}}|$working_units|g" \
    -e "s|{{COUNTRY}}|$country|g" \
    -e "s|{{STATE_REGION}}|$state_region|g" \
    -e "s|{{CITY}}|$city|g" \
    "$source_file" > "$target_file"
}

require_format() {
  file=$1
  label=$2
  version=$(awk -F'|' 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)=="Format version" {print trim($3); exit}' "$file")
  [ "$version" = 2 ] || die "$label format version is ${version:-absent}; version 2 is required (migrate explicitly before writing)"
}

require_studio() {
  validate_root "$1"
  [ -f "$1/STUDIO.md" ] || die "STUDIO.md not found at $1"
  require_format "$1/STUDIO.md" "Studio"
}

require_safe_project() {
  studio=$1
  relative_path=$2
  case "$relative_path" in projects/*) ;; *) die "unsafe registered project path: $relative_path" ;; esac
  case "/$relative_path/" in */../*|*/./*|*//* ) die "unsafe registered project path: $relative_path" ;; esac
  project="$studio/$relative_path"
  [ ! -L "$project" ] || die "registered project may not be a symlink: $relative_path"
  [ -f "$project/PROJECT.md" ] || die "PROJECT.md not found at $relative_path"
  [ ! -L "$project/PROJECT.md" ] || die "PROJECT.md may not be a symlink: $relative_path"
  require_format "$project/PROJECT.md" "Project"
  physical_studio=$(cd -P -- "$studio" && pwd)
  physical_projects=$(cd -P -- "$studio/projects" && pwd)
  physical_project=$(cd -P -- "$project" && pwd)
  [ "$physical_projects" = "$physical_studio/projects" ] || die "studio projects directory may not be a symlink"
  case "$physical_project/" in "$physical_projects"/*/) ;; *) die "project resolves outside studio projects/: $relative_path" ;; esac
  if [ -e "$project/TASKS.md" ] && [ -L "$project/TASKS.md" ]; then
    die "TASKS.md may not be a symlink: $relative_path"
  fi
}

init_studio() {
  target=$1
  name=$2
  working_units=$3
  country=$4
  state_region=$5
  city=$6
  validate_root "$target"
  validate_text "studio name" "$name"
  validate_text "working units" "$working_units"
  validate_text "country" "$country"
  validate_text "state or region" "$state_region"
  validate_text "city" "$city"

  if [ -e "$target" ] && [ ! -d "$target" ]; then
    die "target exists and is not a directory: $target"
  fi
  if [ -d "$target" ] && [ -n "$(find "$target" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]; then
    die "target directory is not empty: $target"
  fi

  mkdir -p "$target/.claude/skills" "$target/.agents/skills" "$target/projects"
  render "$TEMPLATE_DIR/STUDIO.md" "$target/STUDIO.md" "$name" "$working_units" "$country" "$state_region" "$city"
  render "$TEMPLATE_DIR/CLAUDE.md" "$target/CLAUDE.md" "$name" "$working_units" "$country" "$state_region" "$city"
  render "$TEMPLATE_DIR/AGENTS.md" "$target/AGENTS.md" "$name" "$working_units" "$country" "$state_region" "$city"
  cp "$TEMPLATE_DIR/.mcp.json" "$target/.mcp.json"
  printf 'created studio: %s\n' "$target"
}

register_project() {
  studio=$1
  project_id=$2
  project_name=$3
  relative_path=$4
  require_studio "$studio"
  validate_text "project id" "$project_id"
  validate_text "project name" "$project_name"
  validate_text "project path" "$relative_path"
  case "$relative_path" in
    projects/*) ;;
    *) die "project path must be below projects/" ;;
  esac
  case "/$relative_path/" in
    */../*|*/./*) die "project path may not contain dot segments" ;;
  esac
  require_safe_project "$studio" "$relative_path"

  if awk -F'|' -v id="$project_id" -v path="$relative_path" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && (trim($2)==id || trim($4)==path) {found=1}
    END {exit found ? 0 : 1}
  ' "$studio/STUDIO.md"; then
    die "project id or path is already registered"
  fi

  registered=$(date +%Y-%m-%d)
  tmp=$(mktemp "$studio/.studio-manifest.XXXXXX")
  awk -v row="| $project_id | $project_name | $relative_path | active | $registered |" '
    /<!-- projects:end -->/ {print row}
    {print}
  ' "$studio/STUDIO.md" > "$tmp"
  mv "$tmp" "$studio/STUDIO.md"
  printf 'registered project: %s\n' "$relative_path"
}

archive_project() {
  studio=$1
  project_id=$2
  require_studio "$studio"
  validate_text "project id" "$project_id"
  tmp=$(mktemp "$studio/.studio-manifest.XXXXXX")
  if ! awk -F'|' -v id="$project_id" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    BEGIN {found=0}
    /^\|/ && trim($2)==id {
      print "| " trim($2) " | " trim($3) " | " trim($4) " | archived | " trim($6) " |"
      found=1
      next
    }
    {print}
    END {exit found ? 0 : 2}
  ' "$studio/STUDIO.md" > "$tmp"; then
    rm -f "$tmp"
    die "project id is not registered: $project_id"
  fi
  mv "$tmp" "$studio/STUDIO.md"
  printf 'archived registration: %s\n' "$project_id"
}

status_studio() {
  studio=$1
  require_studio "$studio"
  task_mode=$(awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)=="Task register" {print trim($3); exit}
  ' "$studio/STUDIO.md")
  case "$task_mode" in
    project) task_state=project ;;
    portfolio)
      if [ -f "$studio/TASKS.md" ]; then task_state=portfolio; else task_state="invalid (portfolio TASKS.md missing)"; fi
      ;;
    *) task_state=invalid ;;
  esac
  printf 'tasks: %s\n' "$task_state"

  connector_manifest="$studio/.mcp.json"
  if [ ! -e "$connector_manifest" ]; then
    connector_state=missing
  elif [ ! -f "$connector_manifest" ]; then
    connector_state=invalid
  else
    connector_state=$(node -e '
      const fs = require("fs");
      try {
        const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
        const servers = value && value.mcpServers;
        if (typeof value !== "object" || Array.isArray(value) ||
            typeof servers !== "object" || servers === null || Array.isArray(servers)) {
          process.exit(2);
        }
        const isReserved = Object.keys(value).length === 1 && Object.keys(servers).length === 0;
        process.stdout.write(isReserved ? "empty-reserved" : "configured");
      } catch (_) {
        process.exit(2);
      }
    ' "$connector_manifest" 2>/dev/null) || connector_state=invalid
  fi
  printf 'connectors: %s\n' "$connector_state"

  rows=$(mktemp "$studio/.studio-status.XXXXXX")
  trap 'rm -f "$rows"' EXIT
  awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      id=trim($2); name=trim($3); path=trim($4)
      if (id!="Project ID" && id!="---" && path!="") print id "\t" name "\t" path
    }
  ' "$studio/STUDIO.md" > "$rows"

  awk -F'\t' '{ids[$1]++; paths[$3]++} END {for (i in ids) if (ids[i]>1) print "duplicate id: " i; for (p in paths) if (paths[p]>1) print "duplicate path: " p}' "$rows"

  while IFS=$'\t' read -r project_id project_name relative_path; do
    [ -n "$relative_path" ] || continue
    require_safe_project "$studio" "$relative_path"
    file_id=$(awk -F'|' 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)=="Project ID" {print trim($3); exit}' "$studio/$relative_path/PROJECT.md")
    file_name=$(awk -F'|' 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)=="Project" {print trim($3); exit}' "$studio/$relative_path/PROJECT.md")
    [ -z "$file_id" ] || [ "$file_id" = "$project_id" ] || printf 'identity mismatch: %s manifest-id=%s project-id=%s\n' "$relative_path" "$project_id" "$file_id"
    [ -z "$file_name" ] || [ "$file_name" = "$project_name" ] || printf 'identity mismatch: %s manifest-name=%s project-name=%s\n' "$relative_path" "$project_name" "$file_name"
  done < "$rows"

  find "$studio/projects" -mindepth 2 -maxdepth 2 -name PROJECT.md -type f 2>/dev/null | while IFS= read -r project_file; do
    project_dir=${project_file%/PROJECT.md}
    relative_path=${project_dir#"$studio/"}
    if ! awk -F'\t' -v path="$relative_path" '$3==path {found=1} END {exit found ? 0 : 1}' "$rows"; then
      printf 'unregistered: %s\n' "$relative_path"
    fi
  done
}

task_mode_studio() {
  studio=$1
  requested=$2
  require_studio "$studio"
  case "$requested" in
    project|portfolio) ;;
    *) die "task mode must be project or portfolio" ;;
  esac

  current=$(awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)=="Task register" {print trim($3); exit}
  ' "$studio/STUDIO.md")
  [ -n "$current" ] || die "STUDIO.md has no Task register setting"
  [ "$current" != "$requested" ] || die "task mode is already $requested"

  rows=$(mktemp "$studio/.studio-task-mode-rows.XXXXXX")
  awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ {
      id=trim($2); path=trim($4); state=trim($5)
      if (id!="Project ID" && id!="---" && path!="" && state!="archived") print id "\t" path
    }
  ' "$studio/STUDIO.md" > "$rows"

  if awk -F'\t' '{ids[$1]++; paths[$2]++} END {for (i in ids) if (ids[i]>1) exit 1; for (p in paths) if (paths[p]>1) exit 1}' "$rows"; then
    :
  else
    die "task mode requires unique project ids and paths"
  fi
  while IFS=$'\t' read -r _ relative_path; do
    [ -n "$relative_path" ] || continue
    case "$relative_path" in
      projects/*) ;;
      *) die "unsafe registered project path: $relative_path" ;;
    esac
    case "/$relative_path/" in
      */../*|*/./*|*//* ) die "unsafe registered project path: $relative_path" ;;
    esac
    require_safe_project "$studio" "$relative_path"
  done < "$rows"

  # Snapshot every touched file. The EXIT trap restores the snapshot unless the
  # manifest replacement and topology verification both complete.
  transaction=$(mktemp -d "$studio/.task-mode-transaction.XXXXXX")
  cp "$studio/STUDIO.md" "$transaction/STUDIO.md"
  [ ! -f "$studio/TASKS.md" ] || cp "$studio/TASKS.md" "$transaction/studio.TASKS.md"
  snapshot_index=0
  while IFS=$'\t' read -r _ relative_path; do
    [ -n "$relative_path" ] || continue
    snapshot_index=$((snapshot_index + 1))
    snapshot=$(printf 'project-%06d.TASKS.md' "$snapshot_index")
    [ ! -f "$studio/$relative_path/TASKS.md" ] || cp "$studio/$relative_path/TASKS.md" "$transaction/$snapshot"
  done < "$rows"
  committed=0
  rollback_task_mode() {
    [ "$committed" -eq 0 ] || return 0
    cp "$transaction/STUDIO.md" "$studio/STUDIO.md" 2>/dev/null || true
    if [ -f "$transaction/studio.TASKS.md" ]; then cp "$transaction/studio.TASKS.md" "$studio/TASKS.md"; else rm -f "$studio/TASKS.md"; fi
    snapshot_index=0
    while IFS=$'\t' read -r _ relative_path; do
      [ -n "$relative_path" ] || continue
      snapshot_index=$((snapshot_index + 1))
      snapshot=$(printf 'project-%06d.TASKS.md' "$snapshot_index")
      if [ -f "$transaction/$snapshot" ]; then cp "$transaction/$snapshot" "$studio/$relative_path/TASKS.md"; else rm -f "$studio/$relative_path/TASKS.md"; fi
    done < "$rows"
  }
  cleanup_task_mode() { rm -rf "$transaction"; rm -f "$rows"; }
  signal_task_mode() {
    signal_status=$1
    trap - EXIT HUP INT TERM
    rollback_task_mode
    cleanup_task_mode
    exit "$signal_status"
  }
  trap 'rollback_task_mode; cleanup_task_mode' EXIT
  trap 'signal_task_mode 129' HUP
  trap 'signal_task_mode 130' INT
  trap 'signal_task_mode 143' TERM

  if [ "$requested" = portfolio ]; then
    [ ! -e "$studio/TASKS.md" ] || die "studio TASKS.md already exists"
    while IFS=$'\t' read -r project_id relative_path; do
      [ -n "$relative_path" ] || continue
      register="$studio/$relative_path/TASKS.md"
      if [ -f "$register" ] && grep -Eq '^\| T[0-9]{4} \|' "$register"; then
        die "project $project_id has task rows; migration is required"
      fi
    done < "$rows"
    cp "$TASK_TEMPLATE_DIR/portfolio-tasks.md" "$transaction/studio.TASKS.new"
    [ "${ARCH_STUDIO_FAIL_AT:-}" != after-stage ] || die "injected failure after staging task mode"
    mv "$transaction/studio.TASKS.new" "$studio/TASKS.md"
    while IFS=$'\t' read -r _ relative_path; do
      [ -n "$relative_path" ] || continue
      [ ! -f "$studio/$relative_path/TASKS.md" ] || rm "$studio/$relative_path/TASKS.md"
    done < "$rows"
  else
    [ -f "$studio/TASKS.md" ] || die "studio TASKS.md not found"
    if grep -Eq '^\| T[0-9]{4} \|' "$studio/TASKS.md"; then
      die "portfolio register has task rows; split migration is required"
    fi
    while IFS=$'\t' read -r _ relative_path; do
      [ -n "$relative_path" ] || continue
      [ -f "$studio/$relative_path/PROJECT.md" ] || continue
      [ -e "$studio/$relative_path/TASKS.md" ] || cp "$PROJECT_TEMPLATE_DIR/TASKS.md" "$studio/$relative_path/TASKS.md"
    done < "$rows"
    rm "$studio/TASKS.md"
  fi

  tmp=$(mktemp "$studio/.studio-task-mode.XXXXXX")
  awk -F'|' -v requested="$requested" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)=="Task register" {print "| Task register | " requested " |"; next}
    {print}
  ' "$studio/STUDIO.md" > "$tmp"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != before-manifest ] || die "injected failure before task-mode manifest replacement"
  mv "$tmp" "$studio/STUDIO.md"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != signal-after-manifest ] || kill -TERM "$$"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != after-manifest ] || die "injected failure after task-mode manifest replacement"
  committed=1
  rm -rf "$transaction"
  rm -f "$rows"
  trap - EXIT HUP INT TERM
  printf 'task mode: %s\n' "$requested"
}

case "${1:-}" in
  init) [ "$#" -eq 7 ] || die "usage: $0 init <target> <studio-name> <working-units> <country> <state-region> <city>"; init_studio "$2" "$3" "$4" "$5" "$6" "$7" ;;
  register) [ "$#" -eq 5 ] || die "usage: $0 register <studio-root> <project-id> <project-name> <relative-path>"; register_project "$2" "$3" "$4" "$5" ;;
  archive) [ "$#" -eq 3 ] || die "usage: $0 archive <studio-root> <project-id>"; archive_project "$2" "$3" ;;
  status) [ "$#" -eq 2 ] || die "usage: $0 status <studio-root>"; status_studio "$2" ;;
  task-mode) [ "$#" -eq 3 ] || die "usage: $0 task-mode <studio-root> <project|portfolio>"; task_mode_studio "$2" "$3" ;;
  *) die "usage: $0 {init|register|archive|status|task-mode} ..." ;;
esac
