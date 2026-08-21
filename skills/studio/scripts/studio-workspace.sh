#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TEMPLATE_DIR="$SCRIPT_DIR/../templates"
PROJECT_TEMPLATE_DIR="$SCRIPT_DIR/../../project/templates"
TASK_TEMPLATE_DIR="$SCRIPT_DIR/../../tasklist/templates"
PROJECT_SCRIPT="$SCRIPT_DIR/../../project/scripts/project-workspace.sh"
PROPOSAL_SCRIPT="$SCRIPT_DIR/../../proposal/scripts/proposal-workspace.sh"
REGISTRY_PARSER="$SCRIPT_DIR/../../project/scripts/project-registry.awk"

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
  [ ! -L "$1" ] || die "studio target may not be a symlink: $1"
  base=$(basename -- "$1")
  case "$base" in
    ''|*[!a-z0-9-]*|-*|*-) die "studio directory must be lowercase kebab-case" ;;
  esac
}

validate_text() {
  [ -n "${2:-}" ] || die "$1 is required"
  case "$2" in
    *'|'*|*$'\n'*|*$'\r'*|*$'\t'*) die "$1 contains a reserved character" ;;
  esac
}

escape_sed() {
  printf '%s' "$1" | sed 's/[\\&|]/\\&/g'
}

file_sha256() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v openssl >/dev/null 2>&1; then
    openssl dgst -sha256 "$1" | awk '{print $NF}'
  else
    die "no SHA-256 tool is available"
  fi
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
  [ "$version" = 3 ] || die "$label format version is ${version:-absent}; version 3 is required (migrate explicitly before writing)"
}

project_field() {
  awk -F'|' -v key="$2" 'function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s} /^\|/ && trim($2)==key {print trim($3); exit}' "$1"
}

validate_project_id() {
  printf '%s\n' "${1:-}" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[A-Z]{3}-[A-Z0-9]+(-[A-Z0-9]+)*$' ||
    die "project id must use uppercase YYYY-MM-CCC-PROJECT-NAME format"
}

validate_project_type() {
  case "${1:-}" in internal|client) ;; *) die "project type is invalid: ${1:-<empty>}" ;; esac
}

validate_project_status() {
  case "${1:-}" in prospective|active|on-hold|lost|withdrawn|completed|archived) ;;
    *) die "project status is invalid: ${1:-<empty>}" ;;
  esac
}

validate_client_code() {
  printf '%s\n' "${1:-}" | grep -Eq '^[A-Z]{3}$' || die "client code must be three uppercase letters"
}

validate_opened_date() {
  printf '%s\n' "${1:-}" | grep -Eq '^[0-9]{4}-(0[1-9]|1[0-2])-[0-9]{2}$' || die "project opened date must use YYYY-MM-DD"
}

registry_rows() {
  awk -f "$REGISTRY_PARSER" "$1/STUDIO.md" > "$2" || die "STUDIO.md Projects table is invalid"
}

write_registry() {
  local studio=$1
  local rows=$2
  local target=$3
  local source=${4:-$studio/STUDIO.md}
  awk -v rows_file="$rows" '
    /<!-- projects:start -->/ {
      print
      print "| Project ID | Project | Client | Code | Type | Status | Folder | Opened |"
      print "|---|---|---|---|---|---|---|---|"
      while ((getline row < rows_file) > 0) {
        split(row, value, "\t")
        print "| " value[1] " | " value[2] " | " value[3] " | " value[4] " | " value[5] " | " value[6] " | " value[7] " | " value[8] " |"
      }
      close(rows_file)
      inside=1
      next
    }
    /<!-- projects:end -->/ {inside=0; print; next}
    !inside {print}
  ' "$source" > "$target"
}

require_studio() {
  validate_root "$1"
  [ -d "$1" ] || die "studio root is not a directory: $1"
  [ -f "$1/STUDIO.md" ] && [ ! -L "$1/STUDIO.md" ] || die "STUDIO.md is missing or symlinked at $1"
  [ -d "$1/projects" ] && [ ! -L "$1/projects" ] || die "studio projects directory is missing or symlinked"
  physical_studio=$(cd -P -- "$1" && pwd)
  physical_projects=$(cd -P -- "$1/projects" && pwd)
  [ "$physical_projects" = "$physical_studio/projects" ] || die "studio projects directory may not be symlinked"
  require_format "$1/STUDIO.md" "Studio"
}

require_owned_studio_file() {
  owned_studio=$1
  owned_name=$2
  owned_requirement=$3
  owned_file="$owned_studio/$owned_name"
  if [ ! -e "$owned_file" ]; then
    [ "$owned_requirement" = optional ] && return 0
    die "$owned_name is missing at $owned_studio"
  fi
  [ -f "$owned_file" ] && [ ! -L "$owned_file" ] || die "$owned_name must be a non-symlink regular file owned by the studio"
  owned_physical_studio=$(cd -P -- "$owned_studio" && pwd)
  owned_physical_parent=$(cd -P -- "$(dirname -- "$owned_file")" && pwd)
  [ "$owned_physical_parent" = "$owned_physical_studio" ] || die "$owned_name resolves outside the studio root"
}

require_safe_project() {
  local studio=$1
  local relative_path=$2
  local project physical_studio physical_projects physical_project
  local project_id project_name project_type project_status client_code client created
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
  project_id=$(project_field "$project/PROJECT.md" "Project ID")
  project_name=$(project_field "$project/PROJECT.md" "Project")
  project_type=$(project_field "$project/PROJECT.md" "Type")
  project_status=$(project_field "$project/PROJECT.md" "Status")
  client_code=$(project_field "$project/PROJECT.md" "Client code")
  client=$(project_field "$project/PROJECT.md" "Client")
  created=$(project_field "$project/PROJECT.md" "Created")
  validate_project_id "$project_id"
  validate_text "project name" "$project_name"
  validate_project_type "$project_type"
  validate_project_status "$project_status"
  validate_client_code "$client_code"
  validate_text "client" "$client"
  validate_opened_date "$created"
  [ "$relative_path" = "projects/$project_id" ] || die "project folder must equal immutable Project ID: $relative_path"
  case "$project_id" in "${created%-*}-$client_code-"*) ;; *) die "project identity month/code does not match its Created and Client code fields" ;; esac
  if [ "$project_type" = client ] && [ "$client" = — ]; then die "client project requires a client display name"; fi
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

  mkdir -p "$target/.claude/skills" "$target/.agents/skills" "$target/standards" "$target/references" "$target/projects"
  render "$TEMPLATE_DIR/STUDIO.md" "$target/STUDIO.md" "$name" "$working_units" "$country" "$state_region" "$city"
  render "$TEMPLATE_DIR/CLAUDE.md" "$target/CLAUDE.md" "$name" "$working_units" "$country" "$state_region" "$city"
  render "$TEMPLATE_DIR/AGENTS.md" "$target/AGENTS.md" "$name" "$working_units" "$country" "$state_region" "$city"
  cp "$TEMPLATE_DIR/standards-README.md" "$target/standards/README.md"
  cp "$TEMPLATE_DIR/references-README.md" "$target/references/README.md"
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

  file_id=$(project_field "$studio/$relative_path/PROJECT.md" "Project ID")
  file_name=$(project_field "$studio/$relative_path/PROJECT.md" "Project")
  [ "$file_id" = "$project_id" ] || die "registration Project ID does not match PROJECT.md"
  [ "$file_name" = "$project_name" ] || die "registration project name does not match PROJECT.md"
  client=$(project_field "$studio/$relative_path/PROJECT.md" "Client")
  client_code=$(project_field "$studio/$relative_path/PROJECT.md" "Client code")
  project_type=$(project_field "$studio/$relative_path/PROJECT.md" "Type")
  project_status=$(project_field "$studio/$relative_path/PROJECT.md" "Status")
  opened=$(project_field "$studio/$relative_path/PROJECT.md" "Created")

  rows=$(mktemp "$studio/.studio-register-rows.XXXXXX")
  registry_rows "$studio" "$rows"
  if awk -F'\t' -v id="$project_id" -v path="$relative_path" '$1==id || $7==path {found=1} END {exit found ? 0 : 1}' "$rows"; then
    rm -f "$rows"
    die "project id or path is already registered"
  fi

  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$project_id" "$project_name" "$client" "$client_code" "$project_type" "$project_status" "$relative_path" "$opened" >> "$rows"
  tmp=$(mktemp "$studio/.studio-manifest.XXXXXX")
  write_registry "$studio" "$rows" "$tmp"
  rm -f "$rows"
  mv "$tmp" "$studio/STUDIO.md"
  printf 'registered project: %s\n' "$relative_path"
}

set_project_status() {
  studio=$1
  project_id=$2
  requested_status=$3
  require_studio "$studio"
  validate_text "project id" "$project_id"
  validate_project_id "$project_id"
  validate_project_status "$requested_status"
  rows=$(mktemp "$studio/.studio-status-rows.XXXXXX")
  registry_rows "$studio" "$rows"
  matches=$(awk -F'\t' -v id="$project_id" '$1==id {n++} END {print n+0}' "$rows")
  if [ "$matches" -ne 1 ]; then
    rm -f "$rows"
    die "project id is not registered: $project_id"
  fi
  relative_path=$(awk -F'\t' -v id="$project_id" '$1==id {print $7; exit}' "$rows")
  require_safe_project "$studio" "$relative_path"
  transaction=$(mktemp -d "$studio/.project-status-transaction.XXXXXX")
  cp "$studio/STUDIO.md" "$transaction/STUDIO.md"
  cp "$studio/$relative_path/PROJECT.md" "$transaction/PROJECT.md"
  committed=0
  rollback_status_failure() {
    rollback_status_label=$1
    rollback_status_target=$2
    rollback_status_reason=$3
    printf '%s\t%s\t%s\n' "$rollback_status_label" "$rollback_status_target" "$rollback_status_reason" >> "$transaction/ROLLBACK-FAILURES.tsv"
    printf 'studio-workspace: rollback restore failed: %s (%s)\n' "$rollback_status_label" "$rollback_status_reason" >&2
    rollback_status_failed=1
  }
  restore_status_snapshot() {
    restore_status_label=$1
    restore_status_source=$2
    restore_status_target=$3
    if [ "${ARCH_STUDIO_FAIL_RESTORE_AT:-}" = "$restore_status_label" ]; then
      rollback_status_failure "$restore_status_label" "$restore_status_target" "injected restore failure"
    elif ! cp "$restore_status_source" "$restore_status_target"; then
      rollback_status_failure "$restore_status_label" "$restore_status_target" "copy failed"
    elif ! cmp -s "$restore_status_source" "$restore_status_target"; then
      rollback_status_failure "$restore_status_label" "$restore_status_target" "verification failed"
    fi
  }
  rollback_project_status() {
    [ "$committed" -eq 0 ] || return 0
    rollback_status_failed=0
    : > "$transaction/ROLLBACK-FAILURES.tsv"
    restore_status_snapshot status-studio "$transaction/STUDIO.md" "$studio/STUDIO.md"
    restore_status_snapshot status-project "$transaction/PROJECT.md" "$studio/$relative_path/PROJECT.md"
    [ "$rollback_status_failed" -eq 0 ]
  }
  finalize_project_status() {
    final_status=$1
    trap - EXIT HUP INT TERM
    if [ "$committed" -eq 0 ]; then
      if rollback_project_status; then
        rm -rf "$transaction"
      else
        printf 'studio-workspace: rollback incomplete; transaction preserved: %s\n' "$transaction" >&2
      fi
    else
      rm -rf "$transaction"
    fi
    rm -f "$rows"
    exit "$final_status"
  }
  trap 'finalize_project_status $?' EXIT
  trap 'finalize_project_status 129' HUP
  trap 'finalize_project_status 130' INT
  trap 'finalize_project_status 143' TERM

  project_tmp=$(mktemp "$studio/$relative_path/.project-status.XXXXXX")
  awk -F'|' -v changed="$(date +%Y-%m-%d)" -v requested="$requested_status" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)=="Status" {print "| Status | " requested " | studio status update | " changed " |"; found=1; next}
    {print}
    END {if (!found) exit 2}
  ' "$studio/$relative_path/PROJECT.md" > "$project_tmp" || { rm -f "$project_tmp"; die "PROJECT.md has no Status field"; }
  mv "$project_tmp" "$studio/$relative_path/PROJECT.md"
  updated_rows=$(mktemp "$studio/.studio-status-updated.XXXXXX")
  awk -F'\t' -v OFS='\t' -v id="$project_id" -v requested="$requested_status" '$1==id {$6=requested} {print}' "$rows" > "$updated_rows"
  tmp=$(mktemp "$studio/.studio-manifest.XXXXXX")
  write_registry "$studio" "$updated_rows" "$tmp"
  rm -f "$updated_rows"
  mv "$tmp" "$studio/STUDIO.md"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != status-after-manifest ] || die "injected failure after status manifest replacement"
  [ "$(project_field "$studio/$relative_path/PROJECT.md" "Status")" = "$requested_status" ] || die "project status verification failed"
  verify_rows=$(mktemp "$studio/.studio-status-verify.XXXXXX")
  registry_rows "$studio" "$verify_rows"
  [ "$(awk -F'\t' -v id="$project_id" '$1==id {print $6}' "$verify_rows")" = "$requested_status" ] || { rm -f "$verify_rows"; die "registry status verification failed"; }
  rm -f "$verify_rows"
  committed=1
  rm -rf "$transaction"
  rm -f "$rows"
  trap - EXIT HUP INT TERM
  printf 'project status: %s -> %s\n' "$project_id" "$requested_status"
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
  findings=$(mktemp "$studio/.studio-status-findings.XXXXXX")
  trap 'rm -f "$rows" "$findings"' EXIT
  registry_rows "$studio" "$rows"
  report_identity_drift() {
    drift_path=$1
    drift_field=$2
    drift_manifest=$3
    drift_project=$4
    [ "$drift_manifest" = "$drift_project" ] && return 0
    printf 'identity mismatch: %s field=%s manifest=%s project=%s\n' "$drift_path" "$drift_field" "$drift_manifest" "$drift_project"
    printf 'drift\n' >> "$findings"
  }

  awk -F'\t' '{ids[$1]++; paths[$7]++} END {for (i in ids) if (ids[i]>1) print "duplicate id: " i; for (p in paths) if (paths[p]>1) print "duplicate path: " p}' "$rows"

  while IFS=$'\t' read -r project_id project_name client client_code project_type project_status relative_path opened; do
    [ -n "$relative_path" ] || continue
    project="$studio/$relative_path"
    audit_reason=
    case "$relative_path" in projects/*) ;; *) audit_reason="unsafe registry path" ;; esac
    case "/$relative_path/" in */../*|*/./*|*//*) audit_reason="unsafe registry path" ;; esac
    if [ -z "$audit_reason" ] && { [ ! -d "$project" ] || [ -L "$project" ]; }; then audit_reason="project directory is missing or symlinked"; fi
    if [ -z "$audit_reason" ] && { [ ! -f "$project/PROJECT.md" ] || [ -L "$project/PROJECT.md" ]; }; then audit_reason="PROJECT.md is missing or symlinked"; fi
    if [ -z "$audit_reason" ]; then
      audit_physical_projects=$(cd -P -- "$studio/projects" && pwd)
      if audit_physical_project=$(cd -P -- "$project" 2>/dev/null && pwd); then
        case "$audit_physical_project/" in "$audit_physical_projects"/*/) ;; *) audit_reason="project resolves outside studio projects/" ;; esac
      else
        audit_reason="project path cannot be resolved"
      fi
    fi
    if [ -n "$audit_reason" ]; then
      printf 'project invalid: %s reason=%s\n' "$relative_path" "$audit_reason"
      printf 'invalid\n' >> "$findings"
      continue
    fi

    file_version=$(project_field "$project/PROJECT.md" "Format version")
    if [ "$file_version" != 3 ]; then
      printf 'project invalid: %s reason=format-version-%s\n' "$relative_path" "${file_version:-absent}"
      printf 'invalid\n' >> "$findings"
    fi
    file_id=$(project_field "$project/PROJECT.md" "Project ID")
    file_name=$(project_field "$project/PROJECT.md" "Project")
    file_client=$(project_field "$project/PROJECT.md" "Client")
    file_code=$(project_field "$project/PROJECT.md" "Client code")
    file_type=$(project_field "$project/PROJECT.md" "Type")
    file_status=$(project_field "$project/PROJECT.md" "Status")
    file_opened=$(project_field "$project/PROJECT.md" "Created")
    report_identity_drift "$relative_path" "Project ID" "$project_id" "$file_id"
    report_identity_drift "$relative_path" Project "$project_name" "$file_name"
    report_identity_drift "$relative_path" Client "$client" "$file_client"
    report_identity_drift "$relative_path" Code "$client_code" "$file_code"
    report_identity_drift "$relative_path" Type "$project_type" "$file_type"
    report_identity_drift "$relative_path" Status "$project_status" "$file_status"
    report_identity_drift "$relative_path" Folder "$relative_path" "projects/$file_id"
    report_identity_drift "$relative_path" Opened "$opened" "$file_opened"
  done < "$rows"

  while IFS= read -r project_file; do
    project_dir=${project_file%/PROJECT.md}
    relative_path=${project_dir#"$studio/"}
    if ! awk -F'\t' -v path="$relative_path" '$7==path {found=1} END {exit found ? 0 : 1}' "$rows"; then
      printf 'unregistered: %s\n' "$relative_path"
      printf 'unregistered\n' >> "$findings"
    fi
  done < <(find "$studio/projects" -mindepth 2 -maxdepth 2 -name PROJECT.md -type f 2>/dev/null)

  registered_count=$(wc -l < "$rows" | tr -d ' ')
  drift_count=$(awk '$0=="drift" {n++} END {print n+0}' "$findings")
  invalid_count=$(awk '$0=="invalid" {n++} END {print n+0}' "$findings")
  unregistered_count=$(awk '$0=="unregistered" {n++} END {print n+0}' "$findings")
  printf 'status-summary\tregistered=%s\tdrift=%s\tinvalid=%s\tunregistered=%s\n' "$registered_count" "$drift_count" "$invalid_count" "$unregistered_count"
  rm -f "$rows" "$findings"
  trap - EXIT
}

parse_migration_manifest() {
  manifest=$1
  output=$2
  awk -F'\t' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    NR==1 {
      for (i=1; i<=NF; i++) {
        heading=trim($i)
        if (heading in column) exit 3
        column[heading]=i
      }
      required[1]="Old Project ID"; required[2]="Old Folder"; required[3]="Project ID"
      required[4]="Project"; required[5]="Client"; required[6]="Code"
      required[7]="Type"; required[8]="Status"; required[9]="Opened"
      for (i=1; i<=9; i++) if (!(required[i] in column)) exit 3
      next
    }
    NF>1 {
      print trim($(column["Old Project ID"])) "\t" trim($(column["Old Folder"])) "\t" \
            trim($(column["Project ID"])) "\t" trim($(column["Project"])) "\t" \
            trim($(column["Client"])) "\t" trim($(column["Code"])) "\t" \
            trim($(column["Type"])) "\t" trim($(column["Status"])) "\t" \
            trim($(column["Opened"]))
      rows++
    }
    END {if (NR<1) exit 3}
  ' "$manifest" > "$output" || die "migration manifest is invalid"
}

legacy_registry_rows() {
  studio=$1
  output=$2
  awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /<!-- projects:start -->/ {starts++; inside=1; next}
    /<!-- projects:end -->/ {ends++; inside=0; next}
    inside && /^\|/ && !header {
      for (i=2; i<NF; i++) column[trim($i)]=i
      required[1]="Project ID"; required[2]="Project"; required[3]="Folder"; required[4]="Registration"; required[5]="Registered"
      for (i=1; i<=5; i++) if (!(required[i] in column)) exit 3
      header=1
      next
    }
    inside && /^\|/ {
      id=trim($(column["Project ID"]))
      if (id ~ /^:?-+:?$/) next
      print id "\t" trim($(column["Project"])) "\t" trim($(column["Folder"])) "\t" trim($(column["Registration"])) "\t" trim($(column["Registered"]))
      rows++
    }
    END {if (starts!=1 || ends!=1 || !header) exit 3}
  ' "$studio/STUDIO.md" > "$output" || die "version 2 STUDIO.md Projects table is invalid"
}

legacy_proposal_rows() {
  studio=$1
  manifest_rows=$2
  output=$3
  : > "$output"
  [ -e "$studio/PROPOSALS.md" ] || return 0
  [ -f "$studio/PROPOSALS.md" ] && [ ! -L "$studio/PROPOSALS.md" ] || die "legacy PROPOSALS.md must be a regular file"
  proposal_version=$(project_field "$studio/PROPOSALS.md" "Format version")
  [ "$proposal_version" = 2 ] || die "legacy proposal register format is ${proposal_version:-absent}; version 2 is required"
  raw=$(mktemp "$studio/.v2-proposal-register.XXXXXX")
  if ! awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /<!-- proposals:start -->/ {starts++; inside=1; next}
    /<!-- proposals:end -->/ {ends++; inside=0; next}
    inside && /^\|/ && !header {
      for (i=2; i<NF; i++) column[trim($i)]=i
      required[1]="Number"; required[2]="Project ID"; required[3]="Client"; required[4]="Title"
      required[5]="Issued"; required[6]="Status"; required[7]="Path"
      for (i=1; i<=7; i++) if (!(required[i] in column)) exit 3
      header=1
      next
    }
    inside && /^\|/ {
      number=trim($(column["Number"]))
      if (number ~ /^:?-+:?$/) next
      print number "\t" trim($(column["Project ID"])) "\t" trim($(column["Client"])) "\t" \
        trim($(column["Title"])) "\t" trim($(column["Issued"])) "\t" trim($(column["Status"])) "\t" trim($(column["Path"]))
    }
    END {if (starts!=1 || ends!=1 || !header) exit 3}
  ' "$studio/PROPOSALS.md" > "$raw"; then
    rm -f "$raw"
    die "legacy PROPOSALS.md register is invalid"
  fi

  while IFS=$'\t' read -r number old_id client title issued status old_path; do
    [ -n "$number" ] || continue
    printf '%s\n' "$number" | grep -Eq '^[A-Z][A-Z0-9]{1,5}-[0-9]{4}$' || { rm -f "$raw"; die "legacy proposal number is invalid: $number"; }
    validate_text "legacy proposal project id" "$old_id"
    validate_text "legacy proposal client" "$client"
    validate_text "legacy proposal title" "$title"
    validate_opened_date "$issued"
    case "$status" in draft|sent|accepted|declined|superseded|'superseded by '*) ;; *) rm -f "$raw"; die "legacy proposal status is invalid: $status" ;; esac
    mapping_count=$(awk -F'\t' -v id="$old_id" '$1==id {n++} END {print n+0}' "$manifest_rows")
    [ "$mapping_count" -eq 1 ] || { rm -f "$raw"; die "legacy proposal does not map to exactly one project: $number"; }
    old_folder=$(awk -F'\t' -v id="$old_id" '$1==id {print $2; exit}' "$manifest_rows")
    new_id=$(awk -F'\t' -v id="$old_id" '$1==id {print $3; exit}' "$manifest_rows")
    case "$old_path" in "$old_folder"/proposals/*.md) ;; *) rm -f "$raw"; die "legacy proposal path is outside its registered project: $number" ;; esac
    [ "$(dirname -- "$old_path")" = "$old_folder/proposals" ] || { rm -f "$raw"; die "legacy proposal must be directly inside proposals/: $number"; }
    [ -f "$studio/$old_path" ] && [ ! -L "$studio/$old_path" ] || { rm -f "$raw"; die "legacy proposal file is missing or symlinked: $old_path"; }
    old_name=$(basename -- "$old_path")
    case "$old_name" in "$number"-*.md) ;; *) rm -f "$raw"; die "legacy proposal filename does not match its number: $number" ;; esac
    slug=${old_name#"$number"-}
    slug=${slug%.md}
    case "$slug" in ''|*[!a-z0-9-]*|-*|*-) rm -f "$raw"; die "legacy proposal slug is invalid: $old_path" ;; esac
    month=${issued%-??}
    series_count=$(awk -F'\t' -v id="$new_id" -v month="$month" -v slug="$slug" '$5==id && $10==month && $11==slug {n++} END {print n+0}' "$output")
    revision=$(printf 'rev-%02d' $((series_count + 1)))
    new_path="projects/$new_id/proposals/$month-$slug-proposal-$revision.md"
    if awk -F'\t' -v path="$new_path" '$9==path {found=1} END {exit found ? 0 : 1}' "$output"; then rm -f "$raw"; die "proposal migration target collides: $new_path"; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$number" "$old_id" "$client" "$title" "$new_id" "$issued" "$status" "$old_path" "$new_path" "$month" "$slug" "$revision" >> "$output"
  done < "$raw"
  rm -f "$raw"

  resolved=$(mktemp "$studio/.v2-proposal-resolved.XXXXXX")
  while IFS=$'\t' read -r number old_id client title new_id issued status old_path new_path month slug revision; do
    [ -n "$number" ] || continue
    related=—
    case "$status" in
      'superseded by '*)
        related_number=${status#superseded by }
        related_count=$(awk -F'\t' -v number="$related_number" '$1==number {n++} END {print n+0}' "$output")
        if [ "$related_count" -ne 1 ]; then
          rm -f "$resolved" "$output"
          die "legacy proposal supersession must resolve exactly once: $number -> $related_number"
        fi
        related_project=$(awk -F'\t' -v number="$related_number" '$1==number {print $5; exit}' "$output")
        if [ "$related_project" != "$new_id" ]; then
          rm -f "$resolved" "$output"
          die "legacy proposal supersession crosses project boundaries: $number -> $related_number"
        fi
        related_target=$(awk -F'\t' -v number="$related_number" '$1==number {print $9; exit}' "$output")
        related_prefix="projects/$new_id/"
        case "$related_target" in
          "$related_prefix"proposals/*.md) related=${related_target#"$related_prefix"} ;;
          *)
            rm -f "$resolved" "$output"
            die "resolved supersession is not a project-relative proposal path: $number -> $related_number"
            ;;
        esac
        ;;
    esac
    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$number" "$old_id" "$client" "$title" "$new_id" "$issued" "$status" "$old_path" "$new_path" "$month" "$slug" "$revision" "$related" >> "$resolved"
  done < "$output"
  mv "$resolved" "$output"
}

write_v3_registry_from_migration() {
  local studio=$1
  local manifest_rows=$2
  local target=$3
  local projected versioned
  projected=$(mktemp "$studio/.v3-registry-rows.XXXXXX")
  versioned=$(mktemp "$studio/.v3-studio-version.XXXXXX")
  awk -F'\t' -v OFS='\t' '{print $3, $4, $5, $6, $7, $8, "projects/" $3, $9}' "$manifest_rows" > "$projected"
  awk -F'|' '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    /^\|/ && trim($2)=="Format version" {print "| Format version | 3 |"; next}
    {print}
  ' "$studio/STUDIO.md" > "$versioned"
  write_registry "$studio" "$projected" "$target" "$versioned"
  rm -f "$projected" "$versioned"
}

rewrite_portfolio_project_ids() {
  source=$1
  manifest_rows=$2
  target=$3
  awk -F'|' -v OFS='|' -v mapping_file="$manifest_rows" '
    function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
    BEGIN {
      while ((getline row < mapping_file)>0) {
        split(row, value, "\t")
        replacement[value[1]]=value[3]
      }
      close(mapping_file)
    }
    /^\|/ && !table {
      project_column=0
      for (i=2; i<NF; i++) if (trim($i)=="Project ID") project_column=i
      if (project_column) table=1
      print
      next
    }
    table && !/^\|/ {table=0; project_column=0; print; next}
    table && /^\|/ {
      current=trim($(project_column))
      if (current in replacement) $(project_column)=" " replacement[current] " "
      print
      next
    }
    {print}
  ' "$source" > "$target"
}

migrate_studio() {
  studio=$1
  manifest=$2
  mode=${3:-preview}
  validate_root "$studio"
  [ -d "$studio" ] || die "studio root is not a directory: $studio"
  require_owned_studio_file "$studio" STUDIO.md required
  require_owned_studio_file "$studio" TASKS.md optional
  [ -f "$manifest" ] && [ ! -L "$manifest" ] || die "migration manifest must be a regular file"
  [ "$mode" = preview ] || [ "$mode" = --apply ] || die "migration mode must be preview or --apply"
  version=$(project_field "$studio/STUDIO.md" "Format version")
  [ "$version" = 2 ] || die "studio migration requires format version 2; found ${version:-absent}"
  [ -d "$studio/projects" ] && [ ! -L "$studio/projects" ] || die "studio projects directory is missing or symlinked"

  manifest_rows=$(mktemp "$studio/.v3-manifest-rows.XXXXXX")
  legacy_rows=$(mktemp "$studio/.v2-registry-rows.XXXXXX")
  parse_migration_manifest "$manifest" "$manifest_rows"
  legacy_registry_rows "$studio" "$legacy_rows"
  [ "$(wc -l < "$manifest_rows" | tr -d ' ')" = "$(wc -l < "$legacy_rows" | tr -d ' ')" ] || { rm -f "$manifest_rows" "$legacy_rows"; die "migration manifest must cover every registered project exactly once"; }
  awk -F'\t' '{old_ids[$1]++; old_paths[$2]++; new_ids[$3]++} END {for (x in old_ids) if(old_ids[x]!=1) exit 1; for(x in old_paths) if(old_paths[x]!=1) exit 1; for(x in new_ids) if(new_ids[x]!=1) exit 1}' "$manifest_rows" || { rm -f "$manifest_rows" "$legacy_rows"; die "migration manifest contains duplicate identities or folders"; }

  physical_studio=$(cd -P -- "$studio" && pwd)
  physical_projects=$(cd -P -- "$studio/projects" && pwd)
  [ "$physical_projects" = "$physical_studio/projects" ] || { rm -f "$manifest_rows" "$legacy_rows"; die "studio projects directory may not be a symlink"; }
  while IFS=$'\t' read -r old_id old_folder new_id name client code project_type project_status opened; do
    validate_text "old project id" "$old_id"
    validate_text "old project folder" "$old_folder"
    validate_project_id "$new_id"
    validate_text "project name" "$name"
    validate_text "client" "$client"
    validate_client_code "$code"
    validate_project_type "$project_type"
    validate_project_status "$project_status"
    validate_opened_date "$opened"
    case "$new_id" in "${opened%-*}-$code-"*) ;; *) rm -f "$manifest_rows" "$legacy_rows"; die "new Project ID month/code does not match manifest for $old_id" ;; esac
    case "$old_folder" in projects/*) ;; *) rm -f "$manifest_rows" "$legacy_rows"; die "unsafe legacy project path: $old_folder" ;; esac
    case "/$old_folder/" in */../*|*/./*|*//*) rm -f "$manifest_rows" "$legacy_rows"; die "unsafe legacy project path: $old_folder" ;; esac
    legacy_match=$(awk -F'\t' -v id="$old_id" -v path="$old_folder" '$1==id && $3==path {n++} END {print n+0}' "$legacy_rows")
    [ "$legacy_match" -eq 1 ] || { rm -f "$manifest_rows" "$legacy_rows"; die "manifest row does not uniquely match version 2 registry: $old_id"; }
    old_root="$studio/$old_folder"
    [ -d "$old_root" ] && [ ! -L "$old_root" ] && [ -f "$old_root/PROJECT.md" ] && [ ! -L "$old_root/PROJECT.md" ] || { rm -f "$manifest_rows" "$legacy_rows"; die "legacy project is missing or symlinked: $old_folder"; }
    case "$(cd -P -- "$old_root" && pwd)/" in "$physical_projects"/*/) ;; *) rm -f "$manifest_rows" "$legacy_rows"; die "legacy project resolves outside projects/: $old_folder" ;; esac
    old_version=$(project_field "$old_root/PROJECT.md" "Format version")
    [ "$old_version" = 2 ] || { rm -f "$manifest_rows" "$legacy_rows"; die "legacy project format is not version 2: $old_folder"; }
    file_old_id=$(project_field "$old_root/PROJECT.md" "Project ID")
    [ -z "$file_old_id" ] || [ "$file_old_id" = "$old_id" ] || { rm -f "$manifest_rows" "$legacy_rows"; die "legacy Project ID mismatch: $old_folder"; }
    new_root="$studio/projects/$new_id"
    [ "$new_root" = "$old_root" ] || [ ! -e "$new_root" ] || { rm -f "$manifest_rows" "$legacy_rows"; die "migration target already exists: projects/$new_id"; }
    if [ "$project_type" = client ] && [ "$client" = — ]; then rm -f "$manifest_rows" "$legacy_rows"; die "client project requires a client display name: $old_id"; fi
  done < "$manifest_rows"
  proposal_rows=$(mktemp "$studio/.v2-proposal-rows.XXXXXX")
  legacy_proposal_rows "$studio" "$manifest_rows" "$proposal_rows"

  if [ "$mode" != --apply ]; then
    printf 'migration ready: studio/project format 2 -> 3\n'
    while IFS=$'\t' read -r old_id _old_folder new_id _rest; do printf '%s -> %s\n' "$old_id" "$new_id"; done < "$manifest_rows"
    while IFS=$'\t' read -r number _old_id _client _title _new_id _issued _status _old_path new_path _rest; do
      [ -n "$number" ] || continue
      printf '%s -> %s\n' "$number" "$new_path"
    done < "$proposal_rows"
    rm -f "$manifest_rows" "$legacy_rows" "$proposal_rows"
    return 0
  fi

  transaction=$(mktemp -d "$studio/.v3-migration-transaction.XXXXXX")
  cp "$studio/STUDIO.md" "$transaction/STUDIO.md"
  had_tasks=0
  if [ -f "$studio/TASKS.md" ]; then
    cp "$studio/TASKS.md" "$transaction/TASKS.md"
    had_tasks=1
  fi
  had_proposals=0
  if [ -f "$studio/PROPOSALS.md" ]; then cp "$studio/PROPOSALS.md" "$transaction/PROPOSALS.md"; had_proposals=1; fi
  cp "$manifest_rows" "$transaction/manifest-rows.tsv"
  cp "$proposal_rows" "$transaction/proposal-rows.tsv"
  write_v3_registry_from_migration "$studio" "$manifest_rows" "$transaction/STUDIO.expected.md"
  if [ "$had_tasks" -eq 1 ]; then
    rewrite_portfolio_project_ids "$transaction/TASKS.md" "$manifest_rows" "$transaction/TASKS.expected.md"
  fi
  preserved_inventory="$transaction/preserved-files.tsv"
  : > "$preserved_inventory"
  snapshot_index=0
  while IFS=$'\t' read -r _old_id old_folder _rest; do
    snapshot_index=$((snapshot_index + 1))
    cp "$studio/$old_folder/PROJECT.md" "$transaction/PROJECT.$(printf '%06d' "$snapshot_index").md"
    while IFS= read -r -d '' preserved_source; do
      preserved_relative=${preserved_source#"$studio/$old_folder/"}
      case "$preserved_relative" in PROJECT.md|proposals/*.md) continue ;; esac
      case "$preserved_relative" in *$'\n'*|*$'\r'*|*$'\t'*) die "preserved project path contains control characters: $old_folder/$preserved_relative" ;; esac
      printf '%s\t%s\t%s\n' "$snapshot_index" "$preserved_relative" "$(file_sha256 "$preserved_source")" >> "$preserved_inventory"
    done < <(find "$studio/$old_folder" -type f -print0)
  done < "$manifest_rows"
  proposal_snapshot_index=0
  while IFS=$'\t' read -r _number _old_id _client _title _new_id _issued _status old_path _new_path _rest; do
    [ -n "$old_path" ] || continue
    proposal_snapshot_index=$((proposal_snapshot_index + 1))
    cp "$studio/$old_path" "$transaction/PROPOSAL.$(printf '%06d' "$proposal_snapshot_index").md"
  done < "$proposal_rows"
  rename_journal="$transaction/rename-journal.tsv"
  : > "$rename_journal"
  committed=0
  rollback_migration_failure() {
    rollback_migration_label=$1
    rollback_migration_target=$2
    rollback_migration_reason=$3
    printf '%s\t%s\t%s\n' "$rollback_migration_label" "$rollback_migration_target" "$rollback_migration_reason" >> "$transaction/ROLLBACK-FAILURES.tsv"
    printf 'studio-workspace: rollback restore failed: %s (%s)\n' "$rollback_migration_label" "$rollback_migration_reason" >&2
    rollback_migration_failed=1
  }
  restore_migration_snapshot() {
    restore_migration_label=$1
    restore_migration_source=$2
    restore_migration_target=$3
    if [ "${ARCH_STUDIO_FAIL_RESTORE_AT:-}" = "$restore_migration_label" ]; then
      rollback_migration_failure "$restore_migration_label" "$restore_migration_target" "injected restore failure"
    elif ! cp "$restore_migration_source" "$restore_migration_target"; then
      rollback_migration_failure "$restore_migration_label" "$restore_migration_target" "copy failed"
    elif ! cmp -s "$restore_migration_source" "$restore_migration_target"; then
      rollback_migration_failure "$restore_migration_label" "$restore_migration_target" "verification failed"
    fi
  }
  remove_migration_path() {
    remove_migration_label=$1
    remove_migration_target=$2
    if [ "${ARCH_STUDIO_FAIL_RESTORE_AT:-}" = "$remove_migration_label" ]; then
      rollback_migration_failure "$remove_migration_label" "$remove_migration_target" "injected restore failure"
    elif [ -e "$remove_migration_target" ] || [ -L "$remove_migration_target" ]; then
      if ! rm -f "$remove_migration_target"; then
        rollback_migration_failure "$remove_migration_label" "$remove_migration_target" "remove failed"
      elif [ -e "$remove_migration_target" ] || [ -L "$remove_migration_target" ]; then
        rollback_migration_failure "$remove_migration_label" "$remove_migration_target" "verification failed"
      fi
    fi
  }
  rollback_v3_migration() {
    [ "$committed" -eq 0 ] || return 0
    rollback_migration_failed=0
    : > "$transaction/ROLLBACK-FAILURES.tsv"
    reverse_journal="$transaction/rename-journal.reverse.tsv"
    if sort -r -n -k1,1 "$rename_journal" > "$reverse_journal"; then
      while IFS=$'\t' read -r _index old_folder new_folder; do
        [ -n "$old_folder" ] || continue
        old_location="$studio/$old_folder"
        new_location="$studio/$new_folder"
        if [ "${ARCH_STUDIO_FAIL_RESTORE_AT:-}" = migration-rename ]; then
          rollback_migration_failure migration-rename "$new_location -> $old_location" "injected restore failure"
        elif [ -d "$new_location" ] && [ ! -e "$old_location" ]; then
          if ! mv "$new_location" "$old_location"; then
            rollback_migration_failure migration-rename "$new_location -> $old_location" "rename failed"
          elif [ ! -d "$old_location" ] || [ -e "$new_location" ]; then
            rollback_migration_failure migration-rename "$new_location -> $old_location" "verification failed"
          fi
        elif [ -d "$old_location" ] && [ ! -e "$new_location" ]; then
          :
        else
          rollback_migration_failure migration-rename "$new_location -> $old_location" "ambiguous topology"
        fi
      done < "$reverse_journal"
    else
      rollback_migration_failure migration-journal "$rename_journal" "journal sort failed"
    fi
    restore_migration_snapshot migration-studio "$transaction/STUDIO.md" "$studio/STUDIO.md"
    if [ "$had_tasks" -eq 1 ]; then
      restore_migration_snapshot migration-tasks "$transaction/TASKS.md" "$studio/TASKS.md"
    else
      remove_migration_path migration-tasks "$studio/TASKS.md"
    fi
    snapshot_index=0
    while IFS=$'\t' read -r _old_id old_folder _rest; do
      snapshot_index=$((snapshot_index + 1))
      if [ -d "$studio/$old_folder" ]; then
        restore_migration_snapshot migration-project "$transaction/PROJECT.$(printf '%06d' "$snapshot_index").md" "$studio/$old_folder/PROJECT.md"
      else
        rollback_migration_failure migration-project "$studio/$old_folder/PROJECT.md" "project directory missing after rename rollback"
      fi
    done < "$transaction/manifest-rows.tsv"
    proposal_snapshot_index=0
    while IFS=$'\t' read -r _number _old_id _client _title _new_id _issued _status old_path new_path _rest; do
      [ -n "$old_path" ] || continue
      proposal_snapshot_index=$((proposal_snapshot_index + 1))
      old_dir=$(dirname -- "$old_path")
      new_name=$(basename -- "$new_path")
      remove_migration_path migration-proposal-target "$studio/$old_dir/$new_name"
      if [ -d "$studio/$old_dir" ]; then
        restore_migration_snapshot migration-proposal "$transaction/PROPOSAL.$(printf '%06d' "$proposal_snapshot_index").md" "$studio/$old_path"
      else
        rollback_migration_failure migration-proposal "$studio/$old_path" "proposal directory missing after rename rollback"
      fi
    done < "$transaction/proposal-rows.tsv"
    if [ "$had_proposals" -eq 1 ]; then
      restore_migration_snapshot migration-proposal-register "$transaction/PROPOSALS.md" "$studio/PROPOSALS.md"
    else
      remove_migration_path migration-proposal-register "$studio/PROPOSALS.md"
    fi
    [ "$rollback_migration_failed" -eq 0 ]
  }
  finalize_v3_migration() {
    final_status=$1
    trap - EXIT HUP INT TERM
    if [ "$committed" -eq 0 ]; then
      if rollback_v3_migration; then
        rm -rf "$transaction"
      else
        printf 'studio-workspace: rollback incomplete; transaction preserved: %s\n' "$transaction" >&2
      fi
    else
      rm -rf "$transaction"
    fi
    rm -f "$manifest_rows" "$legacy_rows" "$proposal_rows"
    exit "$final_status"
  }
  trap 'finalize_v3_migration $?' EXIT
  trap 'finalize_v3_migration 129' HUP
  trap 'finalize_v3_migration 130' INT
  trap 'finalize_v3_migration 143' TERM

  move_index=0
  while IFS=$'\t' read -r old_id old_folder new_id name client code project_type project_status opened; do
    move_index=$((move_index + 1))
    "$PROJECT_SCRIPT" migrate-record "$studio/$old_folder" "$new_id" "$name" "$project_type" "$project_status" "$code" "$client" "$opened" --apply >/dev/null
    new_folder="projects/$new_id"
    if [ "$old_folder" != "$new_folder" ]; then
      printf '%s\t%s\t%s\n' "$move_index" "$old_folder" "$new_folder" >> "$rename_journal"
      mv "$studio/$old_folder" "$studio/$new_folder"
    fi
    if [ "$move_index" -eq 1 ] && [ "${ARCH_STUDIO_FAIL_AT:-}" = migration-signal-after-first-rename ]; then kill -TERM "$$"; fi
    if [ "$move_index" -eq 1 ] && [ "${ARCH_STUDIO_FAIL_AT:-}" = migration-after-first-rename ]; then die "injected failure after first project rename"; fi
  done < "$manifest_rows"

  while IFS=$'\t' read -r number _old_id client title new_id issued status old_path _new_path _month slug revision related; do
    [ -n "$number" ] || continue
    old_name=$(basename -- "$old_path")
    legacy_file="$studio/projects/$new_id/proposals/$old_name"
    "$PROPOSAL_SCRIPT" migrate-legacy "$legacy_file" "$studio/projects/$new_id" "$number" "$client" "$title" "$issued" "$status" "$slug" "$revision" --related "$related" --apply >/dev/null
  done < "$proposal_rows"
  [ ! -f "$studio/PROPOSALS.md" ] || rm "$studio/PROPOSALS.md"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != migration-after-commercial ] || die "injected failure after commercial-record migration"

  if [ -f "$studio/TASKS.md" ]; then
    tasks_tmp=$(mktemp "$studio/.v3-tasks.XXXXXX")
    rewrite_portfolio_project_ids "$studio/TASKS.md" "$manifest_rows" "$tasks_tmp"
    mv "$tasks_tmp" "$studio/TASKS.md"
  fi
  studio_tmp=$(mktemp "$studio/.v3-studio.XXXXXX")
  write_v3_registry_from_migration "$studio" "$manifest_rows" "$studio_tmp"
  mv "$studio_tmp" "$studio/STUDIO.md"
  [ "${ARCH_STUDIO_FAIL_AT:-}" != migration-after-manifest ] || die "injected failure after v3 manifest replacement"

  if [ "${ARCH_STUDIO_FAIL_AT:-}" = migration-corrupt-project-client ]; then
    corrupt_project=$(awk -F'\t' 'NR==1 {print $3; exit}' "$manifest_rows")
    corrupt_tmp=$(mktemp "$studio/projects/$corrupt_project/.migration-corrupt.XXXXXX")
    awk -F'|' '
      function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
      /^\|/ && trim($2)=="Client" {print "| Client | CORRUPTED CLIENT | injected verification fault | 2026-01-01 |"; next}
      {print}
    ' "$studio/projects/$corrupt_project/PROJECT.md" > "$corrupt_tmp"
    mv "$corrupt_tmp" "$studio/projects/$corrupt_project/PROJECT.md"
  fi

  verify_rows="$transaction/registry-verify.tsv"
  registry_rows "$studio" "$verify_rows"
  manifest_count=$(wc -l < "$manifest_rows" | tr -d ' ')
  registry_count=$(wc -l < "$verify_rows" | tr -d ' ')
  [ "$registry_count" = "$manifest_count" ] || die "v3 registry verification failed"
  [ "$(project_field "$studio/STUDIO.md" "Format version")" = 3 ] || die "migrated studio version verification failed"
  cmp -s "$transaction/STUDIO.expected.md" "$studio/STUDIO.md" || die "migrated studio content verification failed"
  project_verify_index=0
  while IFS=$'\t' read -r old_id old_folder new_id name client code project_type project_status opened; do
    project_verify_index=$((project_verify_index + 1))
    project_root="$studio/projects/$new_id"
    [ -d "$project_root" ] && [ ! -L "$project_root" ] || die "migrated project directory is missing or symlinked: $new_id"
    [ "$(basename -- "$project_root")" = "$new_id" ] || die "migrated project folder verification failed: $new_id"
    [ "$old_folder" = "projects/$new_id" ] || [ ! -e "$studio/$old_folder" ] || die "legacy project directory remains after migration: $old_folder"
    [ "$(project_field "$project_root/PROJECT.md" "Format version")" = 3 ] || die "migrated project version verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Project ID")" = "$new_id" ] || die "migrated project identity verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Project")" = "$name" ] || die "migrated project name verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Client")" = "$client" ] || die "migrated project client verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Client code")" = "$code" ] || die "migrated project code verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Type")" = "$project_type" ] || die "migrated project type verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Status")" = "$project_status" ] || die "migrated project status verification failed: $new_id"
    [ "$(project_field "$project_root/PROJECT.md" "Created")" = "$opened" ] || die "migrated project opened-date verification failed: $new_id"
    awk -F'\t' -v id="$new_id" -v name="$name" -v client="$client" -v code="$code" -v type="$project_type" -v status="$project_status" -v path="projects/$new_id" -v opened="$opened" '
      $1==id && $2==name && $3==client && $4==code && $5==type && $6==status && $7==path && $8==opened {found++}
      END {exit found==1 ? 0 : 1}
    ' "$verify_rows" || die "migrated registry row verification failed: $new_id"
  done < "$manifest_rows"

  tasks_state=absent
  if [ "$had_tasks" -eq 1 ]; then
    [ -f "$studio/TASKS.md" ] && [ ! -L "$studio/TASKS.md" ] || die "migrated TASKS.md is missing or symlinked"
    cmp -s "$transaction/TASKS.expected.md" "$studio/TASKS.md" || die "migrated task register differs from the expected structured-ID rewrite"
    awk -F'\t' '{print $1}' "$manifest_rows" > "$transaction/legacy-project-ids.tsv"
    awk -F'|' -v old_ids_file="$transaction/legacy-project-ids.tsv" '
      function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
      BEGIN {while ((getline id < old_ids_file)>0) old[id]=1; close(old_ids_file)}
      /^\|/ && !header {
        for (i=2; i<NF; i++) if (trim($i)=="Project ID") project_column=i
        if (project_column) {header=1; next}
      }
      header && /^\|/ {
        value=trim($(project_column))
        if (value !~ /^:?-+:?$/ && value in old) found=1
      }
      END {exit found ? 1 : 0}
    ' "$studio/TASKS.md" || die "migrated task register retains a legacy Project ID"
    tasks_state=verified
  else
    [ ! -e "$studio/TASKS.md" ] || die "migration created an unexpected TASKS.md"
  fi

  proposal_verify_index=0
  while IFS=$'\t' read -r number _old_id proposal_client title new_id issued legacy_status old_path new_path _month slug revision related; do
    [ -n "$new_path" ] || continue
    proposal_verify_index=$((proposal_verify_index + 1))
    proposal_file="$studio/$new_path"
    [ ! -e "$studio/projects/$new_id/proposals/$(basename -- "$old_path")" ] || die "legacy proposal remains after migration: $old_path"
    "$PROPOSAL_SCRIPT" status "$studio/$new_path" >/dev/null || die "migrated proposal verification failed: $new_path"
    [ "$(project_field "$proposal_file" "Project ID")" = "$new_id" ] || die "migrated proposal Project ID verification failed: $new_path"
    [ "$(project_field "$proposal_file" "Title")" = "$title" ] || die "migrated proposal title verification failed: $new_path"
    [ "$(project_field "$proposal_file" "Short title")" = "$slug" ] || die "migrated proposal short-title verification failed: $new_path"
    expected_revision="Rev. ${revision#rev-}"
    [ "$(project_field "$proposal_file" "Revision")" = "$expected_revision" ] || die "migrated proposal revision verification failed: $new_path"
    [ "$(project_field "$proposal_file" "Legacy number")" = "$number" ] || die "migrated proposal legacy-number verification failed: $new_path"
    case "$legacy_status" in 'superseded by '*|superseded) expected_proposal_status=superseded ;; *) expected_proposal_status=$legacy_status ;; esac
    [ "$(project_field "$proposal_file" "Status")" = "$expected_proposal_status" ] || die "migrated proposal status verification failed: $new_path"
    grep -Fq -- "| Proposal date | $issued |" "$proposal_file" || die "migrated proposal date verification failed: $new_path"
    grep -Fq -- "| To | $proposal_client |" "$proposal_file" || die "migrated proposal client verification failed: $new_path"
    grep -Fq -- "| Project | $new_id |" "$proposal_file" || die "migrated proposal issued-project verification failed: $new_path"
    grep -Fq -- "| $expected_proposal_status | — | legacy migration | legacy number $number | $related |" "$proposal_file" || die "migrated proposal lifecycle verification failed: $new_path"
    extracted_legacy="$transaction/PROPOSAL.$(printf '%06d' "$proposal_verify_index").extracted.md"
    awk -v project_id="$new_id" '
      $0=="| Project | " project_id " |" {project_row=1; next}
      project_row && !content && $0=="" {content=1; next}
      content && $0=="<!-- issued-terms:end -->" {done=1; exit}
      content {line[++count]=$0}
      END {
        if (!done) exit 3
        if (count>0 && line[count]=="") count--
        for (i=1; i<=count; i++) print line[i]
      }
    ' "$proposal_file" > "$extracted_legacy" || die "migrated proposal content boundary verification failed: $new_path"
    cmp -s "$transaction/PROPOSAL.$(printf '%06d' "$proposal_verify_index").md" "$extracted_legacy" || die "migrated proposal legacy content changed: $new_path"
  done < "$proposal_rows"

  preserved_count=0
  while IFS=$'\t' read -r inventory_index preserved_relative expected_hash; do
    [ -n "$preserved_relative" ] || continue
    preserved_count=$((preserved_count + 1))
    preserved_project=$(awk -F'\t' -v row="$inventory_index" 'NR==row {print $3; exit}' "$manifest_rows")
    preserved_target="$studio/projects/$preserved_project/$preserved_relative"
    [ -f "$preserved_target" ] && [ ! -L "$preserved_target" ] || die "preserved project content is missing or symlinked: projects/$preserved_project/$preserved_relative"
    [ "$(file_sha256 "$preserved_target")" = "$expected_hash" ] || die "preserved project content changed: projects/$preserved_project/$preserved_relative"
  done < "$preserved_inventory"
  [ ! -e "$studio/PROPOSALS.md" ] || die "legacy proposal register remains after migration"
  proposal_count=$(wc -l < "$proposal_rows" | tr -d ' ')
  printf 'migration-verification\tprojects=%s\tregistry=%s\ttasks=%s\tproposals=%s\tpreserved-files=%s\n' \
    "$manifest_count" "$registry_count" "$tasks_state" "$proposal_count" "$preserved_count"
  committed=1
  rm -rf "$transaction"
  rm -f "$manifest_rows" "$legacy_rows" "$proposal_rows"
  trap - EXIT HUP INT TERM
  printf 'migrated studio: %s\n' "$studio"
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
  all_rows=$(mktemp "$studio/.studio-task-mode-all.XXXXXX")
  registry_rows "$studio" "$all_rows"
  awk -F'\t' '{print $1 "\t" $7}' "$all_rows" > "$rows"
  rm -f "$all_rows"

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
  set-status) [ "$#" -eq 4 ] || die "usage: $0 set-status <studio-root> <project-id> <prospective|active|on-hold|lost|withdrawn|completed|archived>"; set_project_status "$2" "$3" "$4" ;;
  archive) [ "$#" -eq 3 ] || die "usage: $0 archive <studio-root> <project-id>"; set_project_status "$2" "$3" archived ;;
  migrate) [ "$#" -ge 3 ] && [ "$#" -le 4 ] || die "usage: $0 migrate <studio-root> <confirmed-manifest.tsv> [--apply]"; migrate_studio "$2" "$3" "${4:-preview}" ;;
  status) [ "$#" -eq 2 ] || die "usage: $0 status <studio-root>"; status_studio "$2" ;;
  task-mode) [ "$#" -eq 3 ] || die "usage: $0 task-mode <studio-root> <project|portfolio>"; task_mode_studio "$2" "$3" ;;
  *) die "usage: $0 {init|register|set-status|archive|migrate|status|task-mode} ..." ;;
esac
