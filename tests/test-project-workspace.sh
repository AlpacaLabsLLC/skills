#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="skills/project/scripts/project-workspace.sh"
[ -x "$SCRIPT" ] || { echo "missing executable project helper" >&2; exit 1; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

PROJECT="$ROOT/2026-08-SMI-MUSEUM-EXPANSION"
"$SCRIPT" init "$PROJECT" "Museum Expansion" 2026-08-SMI-MUSEUM-EXPANSION client active SMI "Smith Institution"

for file in PROJECT.md CLAUDE.md AGENTS.md TASKS.md TIMELOG.md; do
  [ -f "$PROJECT/$file" ] || { echo "missing project file: $file" >&2; exit 1; }
done
for dir in decisions meetings site-reports docs/plans .claude/skills .agents/skills; do
  [ -d "$PROJECT/$dir" ] || { echo "missing project directory: $dir" >&2; exit 1; }
done
grep -q 'decisions/' "$PROJECT/PROJECT.md"
grep -Fq '| Format version | 3 |' "$PROJECT/PROJECT.md"
grep -Fq '| Project ID | 2026-08-SMI-MUSEUM-EXPANSION |' "$PROJECT/PROJECT.md"
grep -Fq '| Project | Museum Expansion |' "$PROJECT/PROJECT.md"
grep -Fq '| Type | client |' "$PROJECT/PROJECT.md"
grep -Fq '| Status | active |' "$PROJECT/PROJECT.md"
grep -Fq '| Client code | SMI |' "$PROJECT/PROJECT.md"
grep -Fq '| Client | Smith Institution |' "$PROJECT/PROJECT.md"
! grep -q '^## Decisions$' "$PROJECT/PROJECT.md"
! grep -q '^## \(Site\|Zoning\|Program\|Code\)$' "$PROJECT/PROJECT.md"
grep -Fq 'Maintained by the project skill and the project team.' "$PROJECT/PROJECT.md"
if grep -Fq '/as:' "$PROJECT/PROJECT.md"; then
  echo "generated project record contains a host-specific slash command" >&2
  exit 1
fi
grep -q 'Read `PROJECT.md` before project work' "$PROJECT/AGENTS.md"
grep -Fq 'Before making scope commitments, read `agreement/AGREEMENT.md` when it exists.' "$PROJECT/AGENTS.md"
grep -Fq 'For commercial work, discover the project-local `proposals/`, `agreement/`, and `INVOICES.md` records read-only before acting.' "$PROJECT/AGENTS.md"
grep -Fq 'Project-specific Codex skills live in `.agents/skills/`' "$PROJECT/AGENTS.md"
grep -Fxq '@AGENTS.md' "$PROJECT/CLAUDE.md"
grep -Fxq '## Claude Code' "$PROJECT/CLAUDE.md"
if grep -Fq 'Read `PROJECT.md` before project work' "$PROJECT/CLAUDE.md"; then
  echo "generated CLAUDE.md duplicates shared AGENTS.md instructions" >&2
  exit 1
fi

INTERNAL_PROJECT="$ROOT/2026-08-ALP-ARCHITECTURE-STUDIO"
"$SCRIPT" init "$INTERNAL_PROJECT" "Architecture Studio" 2026-08-ALP-ARCHITECTURE-STUDIO internal active ALP —
grep -Fq '| Type | internal |' "$INTERNAL_PROJECT/PROJECT.md"
grep -Fq '| Client code | ALP |' "$INTERNAL_PROJECT/PROJECT.md"
grep -Fq '| Client | — |' "$INTERNAL_PROJECT/PROJECT.md"
! grep -q '^## \(Site\|Zoning\|Program\|Code\)$' "$INTERNAL_PROJECT/PROJECT.md"

if "$SCRIPT" init "$ROOT/2026-08-A1P-INTERNAL" Internal 2026-08-A1P-INTERNAL internal active A1P —; then
  echo "internal project unexpectedly accepted a non-letter code" >&2
  exit 1
fi

PORTFOLIO_PROJECT="$ROOT/2026-08-NYC-LIBRARY"
"$SCRIPT" init "$PORTFOLIO_PROJECT" "Library" 2026-08-NYC-LIBRARY client prospective NYC "New York City" portfolio
[ ! -f "$PORTFOLIO_PROJECT/TASKS.md" ]
grep -Fq 'resolved by the tasklist skill from this project and the studio skill that owns it' "$PORTFOLIO_PROJECT/PROJECT.md"
grep -Fq 'resolved by the tasklist skill from this project and the studio skill that owns it' "$PROJECT/PROJECT.md"

if "$SCRIPT" init "$PROJECT" "Museum Expansion" 2026-08-SMI-MUSEUM-EXPANSION client active SMI "Smith Institution"; then
  echo "project overwrite unexpectedly succeeded" >&2
  exit 1
fi

if "$SCRIPT" init "$ROOT/2026-08-smi-INVALID" Invalid 2026-08-smi-INVALID client active SMI "Smith Institution"; then
  echo "lowercase project identity unexpectedly accepted" >&2
  exit 1
fi

if "$SCRIPT" init "$ROOT/2026-08-SMI-WRONG-FOLDER" Invalid 2026-08-SMI-RIGHT-ID client active SMI "Smith Institution"; then
  echo "project directory different from Project ID unexpectedly accepted" >&2
  exit 1
fi

echo "✓ project helper creates universal v3 project bundles with immutable uppercase identities"
