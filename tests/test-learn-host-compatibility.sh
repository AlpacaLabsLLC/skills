#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

LEARN="skills/learn/SKILL.md"
LEARN_README="skills/learn/README.md"
CATALOG="skills/tool-catalog/SKILL.md"

grep -Fq '$learn' "$LEARN"
grep -Fq '/as:learn' "$LEARN"
grep -Fq '## Host branch — establish this first' "$LEARN"
grep -Fq 'AGENTS.md` on Codex or `CLAUDE.md` on Claude Code' "$LEARN"
grep -Fq '.agents/skills/site-report/SKILL.md' "$LEARN"
grep -Fq '.claude/skills/site-report/SKILL.md' "$LEARN"
grep -Fq 'start a new chat or session' "$LEARN"
grep -Fq 'do not invoke `/clear`' "$LEARN"

python3 - <<'PY'
from pathlib import Path

for path in (
    Path('skills/learn/SKILL.md'),
    Path('skills/learn/README.md'),
    Path('README.md'),
    Path('CHANGELOG.md'),
):
    text = path.read_text(encoding='utf-8').lower()
    for forbidden in (
        'course remains claude code-specific',
        'claude-only activation',
        'claude code-only activation',
    ):
        assert forbidden not in text, f'{path}: {forbidden}'
PY

grep -Fq 'guided hands-on Codex and Claude Code course' "$CATALOG"
grep -Fq '$learn' "$LEARN_README"
grep -Fq '$learn' README.md
grep -Fq '$learn' CHANGELOG.md

echo "✓ learn has accurate Codex and Claude Code branches"
