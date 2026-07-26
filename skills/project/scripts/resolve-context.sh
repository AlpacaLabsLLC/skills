#!/usr/bin/env bash
set -euo pipefail

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
  [ "$version" = 2 ] || die "$(basename "$1") format version is ${version:-absent}; version 2 required"
}

start=${1:-.}
[ -d "$start" ] || die "context path is not a directory: $start"
project=$(find_up "$start" PROJECT.md || true)
studio=$(find_up "$start" STUDIO.md || true)

if [ -n "$project" ]; then
  [ ! -L "$project" ] && [ ! -L "$project/PROJECT.md" ] || die "project boundary may not be symlinked"
  require_version "$project/PROJECT.md"
  project_id=$(trim_field "$project/PROJECT.md" "Project ID")
  [ -n "$project_id" ] || die "PROJECT.md has no Project ID"
  if [ -n "$studio" ]; then
    [ ! -L "$studio" ] && [ ! -L "$studio/STUDIO.md" ] || die "studio boundary may not be symlinked"
    require_version "$studio/STUDIO.md"
    studio_physical=$(cd -P -- "$studio" && pwd)
    projects_root=$(cd -P -- "$studio/projects" 2>/dev/null && pwd) || die "studio projects directory is missing"
    [ "$projects_root" = "$studio_physical/projects" ] || die "studio projects directory may not be symlinked"
    case "$project/" in "$projects_root"/*/) ;; *) die "project is inside a studio but outside its projects directory" ;; esac
    relative_path=${project#"$studio_physical/"}
    registration_counts=$(awk -F'|' -v id="$project_id" -v path="$relative_path" '
      function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
      /^\|/ {row_id=trim($2); row_path=trim($4); state=trim($5); if(state=="active" || state=="on-hold") {if(row_id==id) ids++; if(row_path==path) paths++; if(row_id==id && row_path==path) exact++}}
      END {print ids+0, paths+0, exact+0}
    ' "$studio/STUDIO.md")
    [ "$registration_counts" = "1 1 1" ] || die "project is not uniquely registered as active or on-hold in its owning studio"
    task_mode=$(trim_field "$studio/STUDIO.md" "Task register")
    case "$task_mode" in
      project) register="$project/TASKS.md" ;;
      portfolio)
        register="$studio_physical/TASKS.md"
        [ -f "$register" ] && [ ! -L "$register" ] || die "portfolio task register is missing or symlinked"
        ;;
      *) die "studio Task register setting is invalid: ${task_mode:-absent}" ;;
    esac
    printf 'project\t%s\t%s\t%s\t%s\t%s\n' "$project" "$project_id" "$studio_physical" "$task_mode" "$register"
  else
    printf 'project\t%s\t%s\t-\tproject\t%s/TASKS.md\n' "$project" "$project_id" "$project"
  fi
  exit 0
fi

if [ -n "$studio" ]; then
  [ ! -L "$studio" ] && [ ! -L "$studio/STUDIO.md" ] || die "studio boundary may not be symlinked"
  require_version "$studio/STUDIO.md"
  projects_root=$(cd -P -- "$studio/projects" 2>/dev/null && pwd) || die "studio projects directory is missing"
  [ "$projects_root" = "$(cd -P -- "$studio" && pwd)/projects" ] || die "studio projects directory may not be symlinked"
  choices=$(mktemp)
  trap 'rm -f "$choices"' EXIT
  awk -F'|' 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ {id=trim($2); name=trim($3); path=trim($4); state=trim($5); if(id!="Project ID"&&id!="---"&&(state=="active"||state=="on-hold")) print id "\t" name "\t" path}' "$studio/STUDIO.md" > "$choices.raw"
  trap 'rm -f "$choices" "$choices.raw"' EXIT
  while IFS=$'\t' read -r id name path; do
    [ -n "$path" ] || continue
    [ "$(awk -F'\t' -v value="$id" '$1==value {n++} END {print n+0}' "$choices.raw")" -eq 1 ] || continue
    [ "$(awk -F'\t' -v value="$path" '$3==value {n++} END {print n+0}' "$choices.raw")" -eq 1 ] || continue
    case "$path" in projects/*) ;; *) continue ;; esac
    case "/$path/" in */../*|*/./*|*//*) continue ;; esac
    candidate="$studio/$path"
    [ -d "$candidate" ] && [ ! -L "$candidate" ] || continue
    physical=$(cd -P -- "$candidate" && pwd)
    case "$physical/" in "$projects_root"/*/) ;; *) continue ;; esac
    [ -f "$candidate/PROJECT.md" ] && [ ! -L "$candidate/PROJECT.md" ] || continue
    version=$(trim_field "$candidate/PROJECT.md" "Format version")
    file_id=$(trim_field "$candidate/PROJECT.md" "Project ID")
    [ "$version" = 2 ] && [ "$file_id" = "$id" ] || continue
    printf '%s\t%s\t%s\n' "$id" "$name" "$path" >> "$choices"
  done < "$choices.raw"
  if [ ! -s "$choices" ]; then printf 'no-projects\t%s\n' "$studio"; else printf 'studio-picker\t%s\n' "$studio"; cat "$choices"; fi
  exit 0
fi

printf 'no-context\n'
