#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="skills/studio/scripts/studio-workspace.sh"
PROJECT_SCRIPT="skills/project/scripts/project-workspace.sh"

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

make_v2_studio() {
  studio=$1
  mkdir -p "$studio/projects/2401-museum-expansion/decisions" "$studio/projects/2401-museum-expansion/meetings" "$studio/projects/2401-museum-expansion/proposals" "$studio/projects/internal-tools/decisions"
  printf '# Architecture Studio — Legacy\n\n## Studio defaults\n\n| Setting | Default |\n|---|---|\n| Format version | 2 |\n| Working units | imperial |\n| Country | US |\n| State / region | NY |\n| City | NYC |\n| Task register | portfolio |\n\n## Projects\n\n<!-- projects:start -->\n| Project ID | Project | Folder | Registration | Registered |\n|---|---|---|---|---|\n| 2401 | Museum Expansion | projects/2401-museum-expansion | active | 2026-07-03 |\n| internal-tools | Studio Tools | projects/internal-tools | active | 2025-12-01 |\n<!-- projects:end -->\n' > "$studio/STUDIO.md"
  printf '# Project — Museum Expansion\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 2 | setup | 2026-07-03 |\n| Project ID | 2401 | setup | 2026-07-03 |\n| Project | Museum Expansion | setup | 2026-07-03 |\n| Client | Smith Institution | setup | 2026-07-03 |\n\n## Site\n\nKeep the AEC section.\n\n## Project records\n\n- Decision records: [decisions/](decisions/)\n' > "$studio/projects/2401-museum-expansion/PROJECT.md"
  printf '# Project — Studio Tools\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 2 | setup | 2025-12-01 |\n| Project ID | internal-tools | setup | 2025-12-01 |\n| Project | Studio Tools | setup | 2025-12-01 |\n\n## Project records\n\n- Decision records: [decisions/](decisions/)\n' > "$studio/projects/internal-tools/PROJECT.md"
  printf '# 0001 — Keep history\n\n- **Status:** decided\n' > "$studio/projects/2401-museum-expansion/decisions/0001-keep-history.md"
  printf '# Kickoff\n\nPreserve meeting bytes and the prose reference 2401.\n' > "$studio/projects/2401-museum-expansion/meetings/2026-07-03-kickoff.md"
  printf '# Tasks\n\n| Description | Project ID | ID |\n|---|---|---|\n| Keep the text 2401 unchanged | 2401 | T0001 |\n| Improve internal tools | internal-tools | T0002 |\n' > "$studio/TASKS.md"
  printf '# Proposals — Legacy\n\n## Settings\n\n| Setting | Value |\n|---|---|\n| Format version | 2 |\n| Proposal prefix | TS |\n\n## Register\n\n<!-- proposals:start -->\n| Number | Project ID | Client | Title | Issued | Status | Path |\n|---|---|---|---|---|---|---|\n| TS-0001 | 2401 | Smith Institution | Design Services | 2026-07-05 | superseded by TS-0002 | projects/2401-museum-expansion/proposals/TS-0001-design-services.md |\n| TS-0002 | 2401 | Smith Institution | Additional Services | 2026-07-06 | accepted | projects/2401-museum-expansion/proposals/TS-0002-additional-services.md |\n<!-- proposals:end -->\n' > "$studio/PROPOSALS.md"
  printf '# TS-0001 — Design Services\n\nLegacy proposal terms remain intact.\n' > "$studio/projects/2401-museum-expansion/proposals/TS-0001-design-services.md"
  printf '# TS-0002 — Additional Services\n\nReplacement proposal terms remain intact.\n' > "$studio/projects/2401-museum-expansion/proposals/TS-0002-additional-services.md"
}

write_manifest() {
  manifest=$1
  printf 'Old Project ID\tOld Folder\tProject ID\tProject\tClient\tCode\tType\tStatus\tOpened\n2401\tprojects/2401-museum-expansion\t2026-07-SMI-MUSEUM-EXPANSION\tMuseum Expansion\tSmith Institution\tSMI\tclient\tcompleted\t2026-07-03\ninternal-tools\tprojects/internal-tools\t2025-12-ALP-STUDIO-TOOLS\tStudio Tools\t—\tALP\tinternal\tactive\t2025-12-01\n' > "$manifest"
}

make_empty_v2_studio() {
  studio=$1
  mkdir -p "$studio/projects"
  printf '# Architecture Studio — Empty Legacy\n\n## Studio defaults\n\n| Setting | Default |\n|---|---|\n| Format version | 2 |\n| Working units | metric |\n| Country | US |\n| State / region | NY |\n| City | NYC |\n| Task register | project |\n\n## Projects\n\n<!-- projects:start -->\n| Project ID | Project | Folder | Registration | Registered |\n|---|---|---|---|---|\n<!-- projects:end -->\n' > "$studio/STUDIO.md"
}

write_empty_manifest() {
  printf 'Old Project ID\tOld Folder\tProject ID\tProject\tClient\tCode\tType\tStatus\tOpened\n' > "$1"
}

# Header-only v2 studios and manifests are valid empty workspaces.
EMPTY="$ROOT/empty-legacy-studio"
EMPTY_MANIFEST="$ROOT/empty-migration.tsv"
make_empty_v2_studio "$EMPTY"
write_empty_manifest "$EMPTY_MANIFEST"
cp "$EMPTY/STUDIO.md" "$ROOT/empty-studio-before.md"
EMPTY_PREVIEW=$("$SCRIPT" migrate "$EMPTY" "$EMPTY_MANIFEST")
printf '%s\n' "$EMPTY_PREVIEW" | grep -Fq 'migration ready: studio/project format 2 -> 3'
cmp -s "$EMPTY/STUDIO.md" "$ROOT/empty-studio-before.md"
EMPTY_APPLY=$("$SCRIPT" migrate "$EMPTY" "$EMPTY_MANIFEST" --apply)
printf '%s\n' "$EMPTY_APPLY" | grep -Fq $'migration-verification\tprojects=0\tregistry=0\ttasks=absent\tproposals=0\tpreserved-files=0'
grep -Fq '| Format version | 3 |' "$EMPTY/STUDIO.md"
grep -Fq '| Project ID | Project | Client | Code | Type | Status | Folder | Opened |' "$EMPTY/STUDIO.md"
[ "$(find "$EMPTY/projects" -mindepth 1 -maxdepth 1 -print | wc -l | tr -d ' ')" -eq 0 ]

# Migration preview and apply reject studio-owned files that resolve through
# symlinks outside the workspace.
for linked_file in STUDIO.md TASKS.md; do
  LINKED="$ROOT/linked-${linked_file%.md}-studio"
  LINKED_MANIFEST="$ROOT/linked-${linked_file%.md}-migration.tsv"
  make_v2_studio "$LINKED"
  write_manifest "$LINKED_MANIFEST"
  external="$ROOT/external-${linked_file%.md}.md"
  mv "$LINKED/$linked_file" "$external"
  ln -s "$external" "$LINKED/$linked_file"
  external_before=$(shasum "$external" | awk '{print $1}')
  if "$SCRIPT" migrate "$LINKED" "$LINKED_MANIFEST" >/dev/null 2>&1; then
    echo "symlinked $linked_file unexpectedly passed migration preview" >&2
    exit 1
  fi
  if "$SCRIPT" migrate "$LINKED" "$LINKED_MANIFEST" --apply >/dev/null 2>&1; then
    echo "symlinked $linked_file unexpectedly passed migration apply" >&2
    exit 1
  fi
  [ "$external_before" = "$(shasum "$external" | awk '{print $1}')" ]
done

STUDIO="$ROOT/legacy-studio"
MANIFEST="$ROOT/migration.tsv"
make_v2_studio "$STUDIO"
write_manifest "$MANIFEST"

cp "$STUDIO/STUDIO.md" "$ROOT/studio-before.md"
cp "$STUDIO/TASKS.md" "$ROOT/tasks-before.md"
cp "$STUDIO/PROPOSALS.md" "$ROOT/proposals-before.md"
decision_before=$(shasum "$STUDIO/projects/2401-museum-expansion/decisions/0001-keep-history.md" | awk '{print $1}')
meeting_before=$(shasum "$STUDIO/projects/2401-museum-expansion/meetings/2026-07-03-kickoff.md" | awk '{print $1}')
PREVIEW=$("$SCRIPT" migrate "$STUDIO" "$MANIFEST")
printf '%s\n' "$PREVIEW" | grep -Fq 'migration ready: studio/project format 2 -> 3'
printf '%s\n' "$PREVIEW" | grep -Fq '2401 -> 2026-07-SMI-MUSEUM-EXPANSION'
printf '%s\n' "$PREVIEW" | grep -Fq 'TS-0001 -> projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-design-services-proposal-rev-01.md'
printf '%s\n' "$PREVIEW" | grep -Fq 'TS-0002 -> projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-additional-services-proposal-rev-01.md'
cmp -s "$STUDIO/STUDIO.md" "$ROOT/studio-before.md"
cmp -s "$STUDIO/TASKS.md" "$ROOT/tasks-before.md"
cmp -s "$STUDIO/PROPOSALS.md" "$ROOT/proposals-before.md"
[ -d "$STUDIO/projects/2401-museum-expansion" ]

MIGRATION_OUTPUT=$("$SCRIPT" migrate "$STUDIO" "$MANIFEST" --apply)
printf '%s\n' "$MIGRATION_OUTPUT" | grep -Fq $'migration-verification\tprojects=2\tregistry=2\ttasks=verified\tproposals=2\tpreserved-files=2'
grep -Fq '| Format version | 3 |' "$STUDIO/STUDIO.md"
grep -Fq '| Project ID | Project | Client | Code | Type | Status | Folder | Opened |' "$STUDIO/STUDIO.md"
grep -Fq '| 2026-07-SMI-MUSEUM-EXPANSION | Museum Expansion | Smith Institution | SMI | client | completed | projects/2026-07-SMI-MUSEUM-EXPANSION | 2026-07-03 |' "$STUDIO/STUDIO.md"
[ -d "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION" ]
[ ! -e "$STUDIO/projects/2401-museum-expansion" ]
grep -Fq '| Format version | 3 |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Project ID | 2026-07-SMI-MUSEUM-EXPANSION |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Project | Museum Expansion |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Client | Smith Institution |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Client code | SMI |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Type | client |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Status | completed |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Created | 2026-07-03 |' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq 'Keep the AEC section.' "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Keep the text 2401 unchanged | 2026-07-SMI-MUSEUM-EXPANSION | T0001 |' "$STUDIO/TASKS.md"
if awk -F'|' '
  function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
  /^\|/ && !header {for (i=2; i<NF; i++) if (trim($i)=="Project ID") project_column=i; if (project_column) {header=1; next}}
  header && /^\|/ && trim($(project_column)) ~ /^:?-+:?$/ {next}
  header && /^\|/ && (trim($(project_column))=="2401" || trim($(project_column))=="internal-tools") {found=1}
  END {exit found ? 0 : 1}
' "$STUDIO/TASKS.md"; then
  echo "migrated task register retained a structured legacy Project ID" >&2
  exit 1
fi
[ ! -e "$STUDIO/PROPOSALS.md" ]
migrated_proposal="$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-design-services-proposal-rev-01.md"
migrated_replacement="$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-additional-services-proposal-rev-01.md"
[ -f "$migrated_proposal" ]
[ -f "$migrated_replacement" ]
[ ! -e "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/TS-0001-design-services.md" ]
[ ! -e "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/TS-0002-additional-services.md" ]
grep -Fq '| Legacy number | TS-0001 |' "$migrated_proposal"
grep -Fq '| Project ID | 2026-07-SMI-MUSEUM-EXPANSION |' "$migrated_proposal"
grep -Fq '| Title | Design Services |' "$migrated_proposal"
grep -Fq '| Short title | design-services |' "$migrated_proposal"
grep -Fq '| Revision | Rev. 01 |' "$migrated_proposal"
grep -Fq '| Status | superseded |' "$migrated_proposal"
grep -Fq '| superseded | — | legacy migration | legacy number TS-0001 | proposals/2026-07-additional-services-proposal-rev-01.md |' "$migrated_proposal"
grep -Fq 'Legacy proposal terms remain intact.' "$migrated_proposal"
grep -Fq '| Status | accepted |' "$migrated_replacement"
grep -Fq '| accepted | — | legacy migration | legacy number TS-0002 | — |' "$migrated_replacement"
grep -Fq 'Replacement proposal terms remain intact.' "$migrated_replacement"
migrated_checksum=$(awk -F'|' '/^\| Issued terms SHA-256 / {gsub(/^[ \t]+|[ \t]+$/, "", $3); print $3}' "$migrated_proposal")
printf '%s\n' "$migrated_checksum" | grep -Eq '^[0-9a-f]{64}$'
skills/proposal/scripts/proposal-workspace.sh verify "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION" >/dev/null
decision_after=$(shasum "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/decisions/0001-keep-history.md" | awk '{print $1}')
[ "$decision_before" = "$decision_after" ]
meeting_after=$(shasum "$STUDIO/projects/2026-07-SMI-MUSEUM-EXPANSION/meetings/2026-07-03-kickoff.md" | awk '{print $1}')
[ "$meeting_before" = "$meeting_after" ]

# A legacy project may already occupy its canonical target folder.
SAME_PATH="$ROOT/same-path-studio"
SAME_PATH_MANIFEST="$ROOT/same-path-migration.tsv"
make_v2_studio "$SAME_PATH"
mv "$SAME_PATH/projects/2401-museum-expansion" "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION"
sed -i.bak 's|projects/2401-museum-expansion|projects/2026-07-SMI-MUSEUM-EXPANSION|g' "$SAME_PATH/STUDIO.md" "$SAME_PATH/PROPOSALS.md"
rm "$SAME_PATH/STUDIO.md.bak" "$SAME_PATH/PROPOSALS.md.bak"
write_manifest "$SAME_PATH_MANIFEST"
sed -i.bak 's|projects/2401-museum-expansion|projects/2026-07-SMI-MUSEUM-EXPANSION|' "$SAME_PATH_MANIFEST"
rm "$SAME_PATH_MANIFEST.bak"
"$SCRIPT" migrate "$SAME_PATH" "$SAME_PATH_MANIFEST" --apply
[ -d "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION" ]
grep -Fq '| Format version | 3 |' "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
grep -Fq '| Project ID | 2026-07-SMI-MUSEUM-EXPANSION |' "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION/PROJECT.md"
[ -f "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-design-services-proposal-rev-01.md" ]
[ -f "$SAME_PATH/projects/2026-07-SMI-MUSEUM-EXPANSION/proposals/2026-07-additional-services-proposal-rev-01.md" ]

# Supersession references are resolved during preflight and an unresolved
# legacy number fails without mutating the v2 studio.
UNRESOLVED="$ROOT/unresolved-studio"
UNRESOLVED_MANIFEST="$ROOT/unresolved-migration.tsv"
make_v2_studio "$UNRESOLVED"
write_manifest "$UNRESOLVED_MANIFEST"
sed -i.bak 's/superseded by TS-0002/superseded by TS-9999/' "$UNRESOLVED/PROPOSALS.md"
rm "$UNRESOLVED/PROPOSALS.md.bak"
cp "$UNRESOLVED/STUDIO.md" "$ROOT/unresolved-studio-before.md"
cp "$UNRESOLVED/PROPOSALS.md" "$ROOT/unresolved-proposals-before.md"
if "$SCRIPT" migrate "$UNRESOLVED" "$UNRESOLVED_MANIFEST" >/dev/null 2>&1; then
  echo "unresolved legacy supersession unexpectedly passed preflight" >&2
  exit 1
fi
cmp -s "$UNRESOLVED/STUDIO.md" "$ROOT/unresolved-studio-before.md"
cmp -s "$UNRESOLVED/PROPOSALS.md" "$ROOT/unresolved-proposals-before.md"
[ -d "$UNRESOLVED/projects/2401-museum-expansion" ]
[ ! -e "$UNRESOLVED/projects/2026-07-SMI-MUSEUM-EXPANSION" ]

DUPLICATE="$ROOT/duplicate-supersession-studio"
DUPLICATE_MANIFEST="$ROOT/duplicate-supersession-migration.tsv"
make_v2_studio "$DUPLICATE"
write_manifest "$DUPLICATE_MANIFEST"
awk '
  /^<!-- proposals:end -->$/ {
    print "| TS-0002 | 2401 | Smith Institution | Alternate Replacement | 2026-07-07 | accepted | projects/2401-museum-expansion/proposals/TS-0002-alternate-replacement.md |"
  }
  { print }
' "$DUPLICATE/PROPOSALS.md" > "$DUPLICATE/PROPOSALS.with-duplicate.md"
mv "$DUPLICATE/PROPOSALS.with-duplicate.md" "$DUPLICATE/PROPOSALS.md"
printf '# TS-0002 — Alternate Replacement\n\nAlternate replacement terms.\n' > "$DUPLICATE/projects/2401-museum-expansion/proposals/TS-0002-alternate-replacement.md"
cp "$DUPLICATE/PROPOSALS.md" "$ROOT/duplicate-supersession-proposals-before.md"
if "$SCRIPT" migrate "$DUPLICATE" "$DUPLICATE_MANIFEST" >/dev/null 2>&1; then
  echo "ambiguous legacy supersession unexpectedly passed preflight" >&2
  exit 1
fi
cmp -s "$DUPLICATE/PROPOSALS.md" "$ROOT/duplicate-supersession-proposals-before.md"
[ -d "$DUPLICATE/projects/2401-museum-expansion" ]
[ ! -e "$DUPLICATE/projects/2026-07-SMI-MUSEUM-EXPANSION" ]

# Every distinct migration checkpoint restores all bytes and topology and
# removes its transaction only after rollback verification succeeds.
for checkpoint in migration-after-first-rename migration-after-commercial migration-after-manifest migration-corrupt-project-client; do
  FAILED="$ROOT/failed-$checkpoint-studio"
  FAILED_MANIFEST="$ROOT/failed-$checkpoint-migration.tsv"
  FAILED_BEFORE="$ROOT/failed-$checkpoint-before"
  make_v2_studio "$FAILED"
  write_manifest "$FAILED_MANIFEST"
  cp -R "$FAILED" "$FAILED_BEFORE"
  if ARCH_STUDIO_FAIL_AT="$checkpoint" "$SCRIPT" migrate "$FAILED" "$FAILED_MANIFEST" --apply >/dev/null 2>&1; then
    echo "injected $checkpoint migration failure unexpectedly succeeded" >&2
    exit 1
  fi
  diff -qr "$FAILED_BEFORE" "$FAILED" >/dev/null
  if find "$FAILED" -mindepth 1 -maxdepth 1 -type d -name '.v3-migration-transaction.*' -print | grep -q .; then
    echo "$checkpoint rollback left a completed transaction snapshot" >&2
    exit 1
  fi
done

# A TERM after the first rename is recovered from the pre-mutation journal.
SIGNALLED="$ROOT/signalled-migration-studio"
SIGNALLED_MANIFEST="$ROOT/signalled-migration.tsv"
SIGNALLED_BEFORE="$ROOT/signalled-migration-before"
make_v2_studio "$SIGNALLED"
write_manifest "$SIGNALLED_MANIFEST"
cp -R "$SIGNALLED" "$SIGNALLED_BEFORE"
set +e
ARCH_STUDIO_FAIL_AT=migration-signal-after-first-rename "$SCRIPT" migrate "$SIGNALLED" "$SIGNALLED_MANIFEST" --apply >/dev/null 2>&1
signal_rc=$?
set -e
[ "$signal_rc" -eq 143 ] || { echo "migration TERM recovery returned $signal_rc instead of 143" >&2; exit 1; }
diff -qr "$SIGNALLED_BEFORE" "$SIGNALLED" >/dev/null
if find "$SIGNALLED" -mindepth 1 -maxdepth 1 -type d -name '.v3-migration-transaction.*' -print | grep -q .; then
  echo "signal rollback left a completed transaction snapshot" >&2
  exit 1
fi

# If a rename cannot be restored, report the exact operation and preserve the
# journal and snapshots for manual recovery.
RECOVERY="$ROOT/failed-restore-studio"
RECOVERY_MANIFEST="$ROOT/failed-restore-migration.tsv"
make_v2_studio "$RECOVERY"
write_manifest "$RECOVERY_MANIFEST"
set +e
recovery_output=$(ARCH_STUDIO_FAIL_AT=migration-after-first-rename ARCH_STUDIO_FAIL_RESTORE_AT=migration-rename "$SCRIPT" migrate "$RECOVERY" "$RECOVERY_MANIFEST" --apply 2>&1)
recovery_rc=$?
set -e
[ "$recovery_rc" -ne 0 ] || { echo "injected migration restore failure unexpectedly succeeded" >&2; exit 1; }
printf '%s\n' "$recovery_output" | grep -Fq 'rollback restore failed: migration-rename'
printf '%s\n' "$recovery_output" | grep -Fq 'rollback incomplete; transaction preserved:'
recovery_transaction=$(find "$RECOVERY" -mindepth 1 -maxdepth 1 -type d -name '.v3-migration-transaction.*' -print)
[ "$(printf '%s\n' "$recovery_transaction" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]
grep -Fq $'1\tprojects/2401-museum-expansion\tprojects/2026-07-SMI-MUSEUM-EXPANSION' "$recovery_transaction/rename-journal.tsv"
grep -Fq $'migration-rename\t' "$recovery_transaction/ROLLBACK-FAILURES.tsv"
[ -f "$recovery_transaction/STUDIO.md" ]
[ -f "$recovery_transaction/PROJECT.000001.md" ]
[ -f "$recovery_transaction/manifest-rows.tsv" ]

make_v2_standalone() {
  project=$1
  mkdir -p "$project/decisions" "$project/meetings"
  printf '# Project — Legacy Standalone\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 2 | setup | 2026-07-03 |\n| Project ID | legacy-standalone | setup | 2026-07-03 |\n| Project | Legacy Standalone | setup | 2026-07-03 |\n| Client | Smith Institution | setup | 2026-07-03 |\n\n## Project records\n\n- Decision records: [decisions/](decisions/)\n' > "$project/PROJECT.md"
  printf '# Legacy Standalone — Project Instructions\n\n- Read `PROJECT.md` before project work.\n- Treat `decisions/*.md` as the sole decision source of truth.\n- Preserve typed ownership for meetings, site reports, tasks, plans, and time.\n- Use project-relative links and never persist machine-specific absolute paths.\n- Project-specific Codex skills live in `.agents/skills/`; Claude Code skills use the parallel `.claude/skills/` root.\n' > "$project/AGENTS.md"
  printf '# Legacy Standalone — Project Instructions\n\n- Read `PROJECT.md` before project work.\n- Treat `decisions/*.md` as the sole decision source of truth.\n- Preserve typed ownership for meetings, site reports, tasks, plans, and time.\n- Use project-relative links and never persist machine-specific absolute paths.\n- Project-specific Claude Code skills live in `.claude/skills/`; Codex skills use the parallel `.agents/skills/` root.\n' > "$project/CLAUDE.md"
  printf '# 0001 — Preserve migration evidence\n\n- **Status:** decided\n' > "$project/decisions/0001-preserve-migration-evidence.md"
  printf 'standalone durable bytes\n' > "$project/meetings/2026-07-03-kickoff.md"
}

assert_unchanged_tree() {
  actual=$1
  expected=$2
  diff -qr "$expected" "$actual" >/dev/null
}

run_standalone_migration() {
  root=$1
  shift
  "$PROJECT_SCRIPT" migrate "$root" 2026-07-SMI-LEGACY-STANDALONE "Legacy Standalone" client active SMI "Smith Institution" 2026-07-03 "$@"
}

# Standalone preview is a byte-for-byte and topology-preserving dry run.
STANDALONE_PREVIEW="$ROOT/legacy-standalone-preview"
make_v2_standalone "$STANDALONE_PREVIEW"
cp -R "$STANDALONE_PREVIEW" "$ROOT/legacy-standalone-preview-before"
STANDALONE_PREVIEW_OUTPUT=$(run_standalone_migration "$STANDALONE_PREVIEW")
printf '%s\n' "$STANDALONE_PREVIEW_OUTPUT" | grep -Fq 'migration ready: project format 2 -> 3 (2026-07-SMI-LEGACY-STANDALONE)'
printf '%s\n' "$STANDALONE_PREVIEW_OUTPUT" | grep -Fq 'CLAUDE.md: replace recognized generated version-2 instructions with @AGENTS.md import'
printf '%s\n' "$STANDALONE_PREVIEW_OUTPUT" | grep -Fq "rename: $STANDALONE_PREVIEW -> $ROOT/2026-07-SMI-LEGACY-STANDALONE"
assert_unchanged_tree "$STANDALONE_PREVIEW" "$ROOT/legacy-standalone-preview-before"
[ ! -e "$ROOT/2026-07-SMI-LEGACY-STANDALONE" ]

# Standalone apply migrates the project record and recognized generated CLAUDE.md together.
STANDALONE_APPLY="$ROOT/legacy-standalone-apply"
make_v2_standalone "$STANDALONE_APPLY"
standalone_decision_before=$(shasum "$STANDALONE_APPLY/decisions/0001-preserve-migration-evidence.md" | awk '{print $1}')
standalone_meeting_before=$(shasum "$STANDALONE_APPLY/meetings/2026-07-03-kickoff.md" | awk '{print $1}')
run_standalone_migration "$STANDALONE_APPLY" --apply >/dev/null
STANDALONE_TARGET="$ROOT/2026-07-SMI-LEGACY-STANDALONE"
[ ! -e "$STANDALONE_APPLY" ]
[ -d "$STANDALONE_TARGET" ]
grep -Fq '| Format version | 3 |' "$STANDALONE_TARGET/PROJECT.md"
cmp -s "$STANDALONE_TARGET/CLAUDE.md" skills/project/templates/CLAUDE.md
[ "$standalone_decision_before" = "$(shasum "$STANDALONE_TARGET/decisions/0001-preserve-migration-evidence.md" | awk '{print $1}')" ]
[ "$standalone_meeting_before" = "$(shasum "$STANDALONE_TARGET/meetings/2026-07-03-kickoff.md" | awk '{print $1}')" ]

# Both injected standalone checkpoints restore every byte and the original directory topology.
rm -rf "$STANDALONE_TARGET"
for checkpoint in after-record after-rename; do
  FAILED_STANDALONE="$ROOT/legacy-standalone-$checkpoint"
  make_v2_standalone "$FAILED_STANDALONE"
  cp -R "$FAILED_STANDALONE" "$ROOT/legacy-standalone-$checkpoint-before"
  if ARCH_PROJECT_FAIL_AT="$checkpoint" run_standalone_migration "$FAILED_STANDALONE" --apply >/dev/null 2>&1; then
    echo "injected standalone $checkpoint failure unexpectedly succeeded" >&2
    exit 1
  fi
  [ -d "$FAILED_STANDALONE" ]
  [ ! -e "$STANDALONE_TARGET" ]
  assert_unchanged_tree "$FAILED_STANDALONE" "$ROOT/legacy-standalone-$checkpoint-before"
done
# A generated-looking file with custom content requires separate confirmation and stays unchanged.
CUSTOM_CLAUDE="$ROOT/legacy-standalone-custom-claude"
make_v2_standalone "$CUSTOM_CLAUDE"
printf '\nUse the firm-specific Claude workflow.\n' >> "$CUSTOM_CLAUDE/CLAUDE.md"
cp -R "$CUSTOM_CLAUDE" "$ROOT/legacy-standalone-custom-claude-before"
if custom_output=$(run_standalone_migration "$CUSTOM_CLAUDE" 2>&1); then
  echo "custom CLAUDE.md unexpectedly passed migration preview" >&2
  exit 1
fi
printf '%s\n' "$custom_output" | grep -Fq 'custom CLAUDE.md requires separate user confirmation before migration'
assert_unchanged_tree "$CUSTOM_CLAUDE" "$ROOT/legacy-standalone-custom-claude-before"

# A valid v2 standalone proposal register is never stranded by a project-only migration.
for proposal_mode in preview apply; do
  LEGACY_PROPOSALS="$ROOT/legacy-standalone-proposals-$proposal_mode"
  make_v2_standalone "$LEGACY_PROPOSALS"
  mkdir -p "$LEGACY_PROPOSALS/proposals"
  printf '# Proposals — Legacy Standalone\n\n## Settings\n\n| Setting | Value |\n|---|---|\n| Format version | 2 |\n| Proposal prefix | LS |\n\n## Register\n\n<!-- proposals:start -->\n| Number | Project ID | Client | Title | Issued | Status | Path |\n|---|---|---|---|---|---|---|\n| LS-0001 | legacy-standalone | Smith Institution | Legacy Services | 2026-07-05 | accepted | proposals/LS-0001-legacy-services.md |\n<!-- proposals:end -->\n' > "$LEGACY_PROPOSALS/PROPOSALS.md"
  printf '# LS-0001 — Legacy Services\n\nPreserve standalone commercial terms.\n' > "$LEGACY_PROPOSALS/proposals/LS-0001-legacy-services.md"
  cp -R "$LEGACY_PROPOSALS" "$ROOT/legacy-standalone-proposals-$proposal_mode-before"
  if [ "$proposal_mode" = apply ]; then
    if proposal_output=$(run_standalone_migration "$LEGACY_PROPOSALS" --apply 2>&1); then
      echo "standalone migration unexpectedly stranded legacy proposals during apply" >&2
      exit 1
    fi
  else
    if proposal_output=$(run_standalone_migration "$LEGACY_PROPOSALS" 2>&1); then
      echo "standalone migration unexpectedly accepted a legacy proposal register during preview" >&2
      exit 1
    fi
  fi
  printf '%s\n' "$proposal_output" | grep -Fq 'standalone format-2 PROPOSALS.md requires studio-owned migration; project left unchanged'
  printf '%s\n' "$proposal_output" | grep -Fq 'run /as:studio migrate from a user-confirmed version-2 studio manifest'
  assert_unchanged_tree "$LEGACY_PROPOSALS" "$ROOT/legacy-standalone-proposals-$proposal_mode-before"
done

echo "✓ v2-to-v3 studio and standalone migration preserve commercial ownership, instructions, bytes, and topology"
