#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

codex_skill=".agents/skills/release"
claude_skill=".claude/skills/release"
validator="skills/skill-maker/scripts/validate-skill.sh"

bash "$validator" "$codex_skill"
bash "$validator" "$claude_skill"

cmp -s "$codex_skill/SKILL.md" "$claude_skill/SKILL.md"

[ ! -e skills/release ]
public_command="/as:"
public_command+="release"
! grep -Fq "$public_command" skills/README.md

grep -Fq 'docs/release-checklist.md' "$codex_skill/SKILL.md"
grep -Fq 'PATTERNS.md#6-clear-versioning-behavior' "$codex_skill/SKILL.md"
grep -Fq 'Studio Operations' "$codex_skill/SKILL.md"
grep -Fq 'original issue reports' "$codex_skill/SKILL.md"
grep -Fq 'Never move, delete, or recreate a published tag' "$codex_skill/SKILL.md"
grep -Fq 'A missing check rollup is not a pass' "$codex_skill/SKILL.md"

printf '✓ repository-local release skill stays cross-host, checklist-driven, credit-aware, and outside the public catalog\n'
