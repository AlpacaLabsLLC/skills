#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SKILL="skills/skill-maker/SKILL.md"

grep -q 'nearest `STUDIO.md`' "$SKILL"
grep -q '{studio-root}/{host-skill-root}/{name}/' "$SKILL"
grep -q 'explicitly requests a project-only skill' "$SKILL"
grep -q '{host-global-skill-root}/{name}/' "$SKILL"
grep -q '\.agents/skills.*Codex' "$SKILL"
grep -q '\.claude/skills.*Claude Code' "$SKILL"
grep -q 'installed plugin cache is never a private-skill target' "$SKILL"
grep -q 'Catalog detection has highest priority' "$SKILL"
grep -q 'Do not let a nearer project silently override a resolved studio' "$SKILL"
grep -q 'validate-skill.sh' "$SKILL"
grep -q '<plugin-root>/assets/skill-maker-template/' "$SKILL"
[ -x skills/skill-maker/scripts/validate-skill.sh ]

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT
mkdir -p "$ROOT/example-skill"
cp assets/skill-maker-template/SKILL.example.md "$ROOT/example-skill/SKILL.md"
cp assets/skill-maker-template/README.md "$ROOT/example-skill/README.md"
sed -i.bak 's/^name:.*/name: example-skill/' "$ROOT/example-skill/SKILL.md"
rm -f "$ROOT/example-skill/SKILL.md.bak"
bash skills/skill-maker/scripts/validate-skill.sh "$ROOT/example-skill"

grep -q 'real initialized Architecture Studio workspace' skills/learn/SKILL.md
grep -q 'studio.*`.claude/skills/`' skills/learn/README.md

echo "✓ skill-maker targets catalog, studio, project-only, and global scopes safely"
