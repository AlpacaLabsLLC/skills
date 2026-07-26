#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SCRIPT="skills/project/scripts/project-workspace.sh"

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

make_project() {
  project=$1
  mkdir -p "$project/decisions"
  printf '# Project Dossier — Test\n\n## Identity\n\nKeep this line.\n\n## Decisions\n\n| # | Decision | Status | Date |\n|---|---|---|---|\n| 0001 | Choose B | decided | 2026-07-21 |\n' > "$project/PROJECT.md"
}

CLEAN="$ROOT/Legacy Project"
make_project "$CLEAN"
printf '# 0001 — Choose B\n\n- **Status:** decided\n' > "$CLEAN/decisions/0001-choose-b.md"
before=$(shasum "$CLEAN/decisions/0001-choose-b.md" | awk '{print $1}')
"$SCRIPT" migrate "$CLEAN"
grep -q '^## Decisions$' "$CLEAN/PROJECT.md"
"$SCRIPT" migrate "$CLEAN" --apply
! grep -q '^## Decisions$' "$CLEAN/PROJECT.md"
grep -q '\[decisions/\](decisions/)' "$CLEAN/PROJECT.md"
grep -q 'Keep this line.' "$CLEAN/PROJECT.md"
after=$(shasum "$CLEAN/decisions/0001-choose-b.md" | awk '{print $1}')
[ "$before" = "$after" ]

LINK_ONLY="$ROOT/link-only"
mkdir -p "$LINK_ONLY/decisions"
printf '# Project — Link Only\n\n## Identity\n\n| Field | Value | Source | Date |\n|---|---|---|---|\n| Project ID | link-only | legacy | 2026-01-01 |\n\n## Project records\n\n- Decision records: [decisions/](decisions/)\n' > "$LINK_ONLY/PROJECT.md"
"$SCRIPT" migrate "$LINK_ONLY" | grep -Fq 'add project format version 2'
! grep -Fq '| Format version |' "$LINK_ONLY/PROJECT.md"
"$SCRIPT" migrate "$LINK_ONLY" --apply
grep -Fq '| Format version | 2 |' "$LINK_ONLY/PROJECT.md"
"$SCRIPT" migrate "$LINK_ONLY" | grep -Fq 'already migrated'

MISSING="$ROOT/missing"
make_project "$MISSING"
missing_before=$(shasum "$MISSING/PROJECT.md" | awk '{print $1}')
if "$SCRIPT" migrate "$MISSING" --apply; then
  echo "migration with a missing record unexpectedly succeeded" >&2
  exit 1
fi
missing_after=$(shasum "$MISSING/PROJECT.md" | awk '{print $1}')
[ "$missing_before" = "$missing_after" ]

MISMATCH="$ROOT/mismatch"
make_project "$MISMATCH"
printf '# 0001 — Choose B\n\n- **Status:** proposed\n' > "$MISMATCH/decisions/0001-choose-b.md"
if "$SCRIPT" migrate "$MISMATCH" --apply; then
  echo "status mismatch unexpectedly succeeded" >&2
  exit 1
fi
grep -q '^## Decisions$' "$MISMATCH/PROJECT.md"

echo "✓ project migration is previewed, lossless, and fails closed"
