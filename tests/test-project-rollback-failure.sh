#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="$PWD/skills/project/scripts/project-workspace.sh"
ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

fail() { echo "FAIL: $*" >&2; exit 1; }

make_v2_standalone() {
  project=$1
  mkdir -p "$project/decisions" "$project/meetings"
  printf '# Project — Legacy Standalone\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Format version | 2 | setup | 2026-07-03 |\n| Project ID | legacy-standalone | setup | 2026-07-03 |\n| Project | Legacy Standalone | setup | 2026-07-03 |\n| Client | Smith Institution | setup | 2026-07-03 |\n\n## Project records\n\n- Decision records: [decisions/](decisions/)\n' > "$project/PROJECT.md"
  printf '# Legacy Standalone — Project Instructions\n\n- Read `PROJECT.md` before project work.\n- Treat `decisions/*.md` as the sole decision source of truth.\n- Preserve typed ownership for meetings, site reports, tasks, plans, and time.\n- Use project-relative links and never persist machine-specific absolute paths.\n- Project-specific Codex skills live in `.agents/skills/`; Claude Code skills use the parallel `.claude/skills/` root.\n' > "$project/AGENTS.md"
  printf '# Legacy Standalone — Project Instructions\n\n- Read `PROJECT.md` before project work.\n- Treat `decisions/*.md` as the sole decision source of truth.\n- Preserve typed ownership for meetings, site reports, tasks, plans, and time.\n- Use project-relative links and never persist machine-specific absolute paths.\n- Project-specific Claude Code skills live in `.claude/skills/`; Codex skills use the parallel `.agents/skills/` root.\n' > "$project/CLAUDE.md"
  printf '# 0001 — Preserve migration evidence\n\n- **Status:** decided\n' > "$project/decisions/0001-preserve-migration-evidence.md"
  printf 'standalone durable bytes\n' > "$project/meetings/2026-07-03-kickoff.md"
}

run_migration() {
  project=$1
  "$SCRIPT" migrate "$project" 2026-07-SMI-LEGACY-STANDALONE "Legacy Standalone" client active SMI "Smith Institution" 2026-07-03 --apply
}

transaction_for() {
  parent=$1
  find "$parent" -mindepth 1 -maxdepth 1 -type d -name '.project-v3-transaction.*' -print -quit
}

# A normal successful migration removes its transaction snapshot.
success_parent="$ROOT/success"
success_root="$success_parent/legacy"
mkdir -p "$success_parent"
make_v2_standalone "$success_root"
run_migration "$success_root" >/dev/null
[ -d "$success_parent/2026-07-SMI-LEGACY-STANDALONE" ] || fail "successful migration target missing"
[ -z "$(transaction_for "$success_parent")" ] || fail "successful migration left transaction material"

# Ordinary rollback restores bytes/topology and then removes its snapshot.
for checkpoint in after-record after-rename; do
  rollback_parent="$ROOT/rollback-$checkpoint"
  rollback_root="$rollback_parent/legacy"
  mkdir -p "$rollback_parent"
  make_v2_standalone "$rollback_root"
  cp -R "$rollback_root" "$rollback_parent/before"
  if ARCH_PROJECT_FAIL_AT="$checkpoint" run_migration "$rollback_root" >/dev/null 2>&1; then
    fail "injected $checkpoint failure unexpectedly succeeded"
  fi
  diff -qr "$rollback_parent/before" "$rollback_root" >/dev/null || fail "$checkpoint rollback changed bytes or topology"
  [ ! -e "$rollback_parent/2026-07-SMI-LEGACY-STANDALONE" ] || fail "$checkpoint rollback left renamed target"
  [ -z "$(transaction_for "$rollback_parent")" ] || fail "$checkpoint rollback left transaction material"
done

# A failed PROJECT.md restore reports the cp step and preserves recovery material.
record_parent="$ROOT/restore-record-failure"
record_root="$record_parent/legacy"
mkdir -p "$record_parent"
make_v2_standalone "$record_root"
cp -R "$record_root" "$record_parent/before"
if record_output=$(ARCH_PROJECT_FAIL_AT=after-record ARCH_PROJECT_ROLLBACK_FAIL_AT=restore-project-record run_migration "$record_root" 2>&1); then
  fail "injected PROJECT.md restore failure unexpectedly succeeded"
fi
printf '%s\n' "$record_output" | grep -Fq 'rollback failed at restore PROJECT.md with cp; recovery snapshot preserved at ' || fail "missing PROJECT.md restore failure report"
record_transaction=$(printf '%s\n' "$record_output" | sed -n 's/^project-workspace: rollback failed at restore PROJECT.md with cp; recovery snapshot preserved at //p' | tail -1)
[ -d "$record_transaction" ] || fail "PROJECT.md recovery transaction was deleted"
cmp -s "$record_transaction/PROJECT.md" "$record_parent/before/PROJECT.md" || fail "PROJECT.md recovery snapshot changed"
cmp -s "$record_transaction/CLAUDE.md" "$record_parent/before/CLAUDE.md" || fail "CLAUDE.md recovery snapshot changed"
[ -d "$record_root" ] || fail "record-restore failure lost original directory"

# A failed directory restore reports the mv step and preserves both target and snapshot.
directory_parent="$ROOT/restore-directory-failure"
directory_root="$directory_parent/legacy"
directory_target="$directory_parent/2026-07-SMI-LEGACY-STANDALONE"
mkdir -p "$directory_parent"
make_v2_standalone "$directory_root"
cp -R "$directory_root" "$directory_parent/before"
if directory_output=$(ARCH_PROJECT_FAIL_AT=after-rename ARCH_PROJECT_ROLLBACK_FAIL_AT=restore-project-directory run_migration "$directory_root" 2>&1); then
  fail "injected directory restore failure unexpectedly succeeded"
fi
printf '%s\n' "$directory_output" | grep -Fq 'rollback failed at restore project directory with mv; recovery snapshot preserved at ' || fail "missing directory restore failure report"
directory_transaction=$(printf '%s\n' "$directory_output" | sed -n 's/^project-workspace: rollback failed at restore project directory with mv; recovery snapshot preserved at //p' | tail -1)
[ -d "$directory_transaction" ] || fail "directory recovery transaction was deleted"
cmp -s "$directory_transaction/PROJECT.md" "$directory_parent/before/PROJECT.md" || fail "directory recovery PROJECT.md snapshot changed"
cmp -s "$directory_transaction/CLAUDE.md" "$directory_parent/before/CLAUDE.md" || fail "directory recovery CLAUDE.md snapshot changed"
[ ! -e "$directory_root" ] || fail "directory restore injection unexpectedly moved target back"
[ -d "$directory_target" ] || fail "directory restore failure lost renamed target"

echo "✓ standalone rollback preserves and reports recovery snapshots when cp or mv restoration fails"
