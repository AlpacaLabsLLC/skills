#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
REGISTRY_PARSER="$SCRIPT_DIR/project-registry.awk"

die() { printf 'invalid\t%s\n' "$*"; exit 2; }
trim_field() { awk -F'|' -v key="$2" 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)==key {print trim($3); exit}' "$1"; }
find_up() {
  cursor=$(cd -P -- "$1" && pwd)
  marker=$2
  while :; do
    [ -f "$cursor/$marker" ] && { printf '%s\n' "$cursor"; return; }
    [ "$cursor" = / ] && return 1
    cursor=${cursor%/*}; [ -n "$cursor" ] || cursor=/
  done
}
require_version() {
  version=$(trim_field "$1" "Format version")
  [ "$version" = 3 ] || die "$(basename "$1") format version is ${version:-absent}; version 3 required"
}
validate_project_identity() {
  file=$1
  directory=$2
  project_id=$(trim_field "$file" "Project ID")
  project_type=$(trim_field "$file" "Type")
  project_status=$(trim_field "$file" "Status")
  client_code=$(trim_field "$file" "Client code")
  created=$(trim_field "$file" "Created")
  printf '%s\n' "$project_id" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$' || die "PROJECT.md has an invalid Project ID"
  [ "$(basename -- "$directory")" = "$project_id" ] || die "project directory does not equal its immutable Project ID"
  case "$project_type" in internal|client) ;; *) die "PROJECT.md has an invalid Type" ;; esac
  case "$project_status" in prospective|active|on-hold|lost|withdrawn|completed|archived) ;; *) die "PROJECT.md has an invalid Status" ;; esac
  printf '%s\n' "$client_code" | grep -Eq '^[A-Z]{3}$' || die "PROJECT.md has an invalid Client code"
  printf '%s\n' "$created" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{2}$' || die "PROJECT.md has an invalid Created date"
  case "$project_id" in "${created%-*}-$client_code-"*) ;; *) die "Project ID does not match Created month and Client code" ;; esac
}
read_registry() {
  awk -f "$REGISTRY_PARSER" "$1/STUDIO.md" > "$2" 2>/dev/null || die "STUDIO.md Projects table is invalid"
}

start=${1:-.}
[ -d "$start" ] || die "context path is not a directory: $start"
project=$(find_up "$start" PROJECT.md || true)
studio=$(find_up "$start" STUDIO.md || true)

if [ -n "$project" ]; then
  [ ! -L "$project" ] && [ ! -L "$project/PROJECT.md" ] || die "project boundary may not be symlinked"
  require_version "$project/PROJECT.md"
  validate_project_identity "$project/PROJECT.md" "$project"
  if [ -n "$studio" ]; then
    [ ! -L "$studio" ] && [ ! -L "$studio/STUDIO.md" ] || die "studio boundary may not be symlinked"
    require_version "$studio/STUDIO.md"
    studio_physical=$(cd -P -- "$studio" && pwd)
    projects_root=$(cd -P -- "$studio/projects" 2>/dev/null && pwd) || die "studio projects directory is missing"
    [ "$projects_root" = "$studio_physical/projects" ] || die "studio projects directory may not be symlinked"
    case "$project/" in "$projects_root"/*/) ;; *) die "project is inside a studio but outside its projects directory" ;; esac
    relative_path=${project#"$studio_physical/"}
    [ "$relative_path" = "projects/$project_id" ] || die "registered project folder does not equal its Project ID"
    rows=$(mktemp)
    trap 'rm -f "$rows"' EXIT
    read_registry "$studio" "$rows"
    registration_counts=$(awk -F'\t' -v id="$project_id" -v path="$relative_path" '
      $1==id {ids++}
      $7==path {paths++}
      $1==id && $7==path {exact++; type=$5; status=$6}
      END {print ids+0, paths+0, exact+0, type, status}
    ' "$rows")
    set -- $registration_counts
    [ "$1 $2 $3" = "1 1 1" ] || die "project is not uniquely registered in its owning studio"
    registry_type=$4
    registry_status=$5
    [ "$registry_type" = "$project_type" ] || die "project Type does not match its studio registration"
    [ "$registry_status" = "$project_status" ] || die "project Status does not match its studio registration"
    task_mode=$(trim_field "$studio/STUDIO.md" "Task register")
    case "$task_mode" in
      project) register="$project/TASKS.md" ;;
      portfolio)
        register="$studio_physical/TASKS.md"
        [ -f "$register" ] && [ ! -L "$register" ] || die "portfolio task register is missing or symlinked"
        ;;
      *) die "studio Task register setting is invalid: ${task_mode:-absent}" ;;
    esac
    printf 'project\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$project" "$project_id" "$studio_physical" "$task_mode" "$register" "$registry_type" "$registry_status"
  else
    printf 'project\t%s\t%s\t-\tproject\t%s/TASKS.md\t%s\t%s\n' "$project" "$project_id" "$project" "$project_type" "$project_status"
  fi
  exit 0
fi

if [ -n "$studio" ]; then
  [ ! -L "$studio" ] && [ ! -L "$studio/STUDIO.md" ] || die "studio boundary may not be symlinked"
  require_version "$studio/STUDIO.md"
  studio_physical=$(cd -P -- "$studio" && pwd)
  projects_root=$(cd -P -- "$studio/projects" 2>/dev/null && pwd) || die "studio projects directory is missing"
  [ "$projects_root" = "$studio_physical/projects" ] || die "studio projects directory may not be symlinked"
  rows=$(mktemp)
  choices=$(mktemp)
  invalids=$(mktemp)
  trap 'rm -f "$rows" "$choices" "$invalids"' EXIT
  read_registry "$studio" "$rows"

  append_invalid() {
    invalid_id=${1:--}
    invalid_path=${2:--}
    invalid_reason=$3
    printf 'invalid-project\t%s\t%s\t%s\n' "$invalid_id" "$invalid_path" "$invalid_reason" >> "$invalids"
  }

  while IFS=$'\t' read -r id name client code type status path opened; do
    id_count=$(awk -F'\t' -v value="$id" '$1==value {n++} END {print n+0}' "$rows")
    path_count=$(awk -F'\t' -v value="$path" '$7==value {n++} END {print n+0}' "$rows")
    if [ "$id_count" -ne 1 ]; then append_invalid "$id" "$path" "Project ID is registered $id_count times"; continue; fi
    if [ "$path_count" -ne 1 ]; then append_invalid "$id" "$path" "project path is registered $path_count times"; continue; fi
    if ! printf '%s\n' "$id" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$'; then append_invalid "$id" "$path" "studio registration has an invalid Project ID"; continue; fi
    if [ -z "$name" ]; then append_invalid "$id" "$path" "studio registration has an empty Project name"; continue; fi
    if [ -z "$client" ]; then append_invalid "$id" "$path" "studio registration has an empty Client"; continue; fi
    if ! printf '%s\n' "$code" | grep -Eq '^[A-Z]{3}$'; then append_invalid "$id" "$path" "studio registration has an invalid Code"; continue; fi
    case "$type" in internal|client) ;; *) append_invalid "$id" "$path" "studio registration has an invalid Type"; continue ;; esac
    case "$status" in prospective|active|on-hold|lost|withdrawn|completed|archived) ;; *) append_invalid "$id" "$path" "studio registration has an invalid Status"; continue ;; esac
    if ! printf '%s\n' "$opened" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{2}$'; then append_invalid "$id" "$path" "studio registration has an invalid Opened date"; continue; fi
    case "$id" in "${opened%-*}-$code-"*) ;; *) append_invalid "$id" "$path" "studio Project ID does not match Opened month and Code"; continue ;; esac
    if [ "$type" = client ] && [ "$client" = — ]; then append_invalid "$id" "$path" "client project registration requires a Client"; continue; fi
    if [ "$path" != "projects/$id" ]; then append_invalid "$id" "$path" "registered project folder does not equal its Project ID"; continue; fi
    candidate="$studio/$path"
    if [ ! -d "$candidate" ]; then append_invalid "$id" "$path" "registered project directory is missing"; continue; fi
    if [ -L "$candidate" ]; then append_invalid "$id" "$path" "registered project directory may not be symlinked"; continue; fi
    physical=$(cd -P -- "$candidate" && pwd)
    case "$physical/" in "$projects_root"/*/) ;; *) append_invalid "$id" "$path" "registered project resolves outside studio projects/"; continue ;; esac
    if [ ! -f "$candidate/PROJECT.md" ]; then append_invalid "$id" "$path" "PROJECT.md is missing"; continue; fi
    if [ -L "$candidate/PROJECT.md" ]; then append_invalid "$id" "$path" "PROJECT.md may not be symlinked"; continue; fi
    version=$(trim_field "$candidate/PROJECT.md" "Format version")
    file_id=$(trim_field "$candidate/PROJECT.md" "Project ID")
    file_name=$(trim_field "$candidate/PROJECT.md" "Project")
    file_type=$(trim_field "$candidate/PROJECT.md" "Type")
    file_status=$(trim_field "$candidate/PROJECT.md" "Status")
    file_code=$(trim_field "$candidate/PROJECT.md" "Client code")
    file_client=$(trim_field "$candidate/PROJECT.md" "Client")
    file_created=$(trim_field "$candidate/PROJECT.md" "Created")
    if [ "$version" != 3 ]; then append_invalid "$id" "$path" "PROJECT.md format version is ${version:-absent}; version 3 required"; continue; fi
    if [ "$file_id" != "$id" ]; then append_invalid "$id" "$path" "PROJECT.md Project ID does not match its studio registration"; continue; fi
    if [ "$file_name" != "$name" ]; then append_invalid "$id" "$path" "PROJECT.md Project does not match its studio registration"; continue; fi
    if [ "$file_type" != "$type" ]; then append_invalid "$id" "$path" "PROJECT.md Type does not match its studio registration"; continue; fi
    if [ "$file_status" != "$status" ]; then append_invalid "$id" "$path" "PROJECT.md Status does not match its studio registration"; continue; fi
    if [ "$file_code" != "$code" ]; then append_invalid "$id" "$path" "PROJECT.md Client code does not match its studio registration"; continue; fi
    if [ "$file_client" != "$client" ]; then append_invalid "$id" "$path" "PROJECT.md Client does not match its studio registration"; continue; fi
    if [ "$file_created" != "$opened" ]; then append_invalid "$id" "$path" "PROJECT.md Created does not match its studio registration"; continue; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$id" "$name" "$path" "$type" "$status" >> "$choices"
  done < "$rows"
  if [ ! -s "$rows" ]; then
    printf 'no-projects\t%s\n' "$studio_physical"
  else
    printf 'studio-picker\t%s\n' "$studio_physical"
    cat "$choices"
    cat "$invalids"
  fi
  exit 0
fi

printf 'no-context\n'
