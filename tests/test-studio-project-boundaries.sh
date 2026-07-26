#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

STUDIO="skills/studio/SKILL.md"
PROJECT="skills/project/SKILL.md"

grep -q '^## Studio and project workspace boundaries$' PATTERNS.md
grep -q 'mutated only by `/as:studio`' PATTERNS.md
grep -q 'mutated only by `/as:project`' PATTERNS.md
grep -q 'installed plugin cache is never a studio' PATTERNS.md

for file in "$STUDIO" "$PROJECT"; do
  [ -f "$file" ] || { echo "missing workspace skill: $file" >&2; exit 1; }
  grep -q 'STUDIO.md' "$file"
  grep -q 'PROJECT.md' "$file"
  grep -qi 'never.*nested project\|nested project.*never' "$file"
done

grep -q '`/as:studio` alone.*`STUDIO.md`\|Only `/as:studio`.*`STUDIO.md`' "$STUDIO"
grep -q '`/project`.*does not.*`STUDIO.md`\|Never write `STUDIO.md`' "$PROJECT"
grep -q 'Created by Federico Negro in 2026' "$STUDIO"
grep -q 'Author / owner: ALPA — https://alpa.llc (contact: hello@alpa.llc)' "$STUDIO"
grep -q 'Copyright: © 2026 Alpaca Design Lab LLC, MIT-licensed' "$STUDIO"
grep -q 'github.com/AlpacaLabsLLC/skills-for-architects' "$STUDIO"
grep -q '^ █████╗ ██████╗' "$STUDIO"
grep -q 'begin with this exact mark' "$STUDIO"
grep -q '`question` field must begin with the exact mark' "$STUDIO"
grep -q 'without opening or closing Markdown fences' "$STUDIO"
grep -q 'include the provenance block.*before.*How would you like to start?' "$STUDIO"
grep -q 'Never use Bash or another tool to print or display the welcome' "$STUDIO"
grep -q 'working units' "$STUDIO"
grep -q 'default jurisdiction' "$STUDIO"
grep -q 'does not send them to or store them with ALPA' "$STUDIO"
grep -q 'configured LLM' "$STUDIO"
grep -q '^## Single-gate interaction pattern$' PATTERNS.md
grep -q 'Never ask a setup or confirmation question twice' "$STUDIO"
grep -q 'Do not ask for confirmation in prose before opening it' "$STUDIO"
grep -q 'Set up a studio' "$STUDIO"
grep -q 'Use tools without setup' "$STUDIO"
grep -q 'Learn with an example' "$STUDIO"
grep -q 'Open an existing studio' "$STUDIO"
grep -q 'creates no files, preferences, or copied skills' "$STUDIO"
grep -q 'Run `/as:studio` later' "$STUDIO"
grep -q 'Would you like this to automatically check for updates?' "$STUDIO"
! grep -q 'any already-known basics' "$STUDIO"
grep -q 'do not gather facts that this creation flow does not persist' "$STUDIO"
grep -q 'exact absolute project path and its `.claude/skills/` path' "$STUDIO"
grep -q 'restart Claude Code from that project root' "$STUDIO"
grep -q 'exact absolute studio path and `.claude/skills/` path' "$STUDIO"
grep -q 'restart Claude Code from the studio root' "$STUDIO"
! grep -q 'skip for now' "$STUDIO"
grep -q '\.mcp\.json' "$STUDIO"
grep -q 'empty-reserved' "$STUDIO"
grep -qi 'never.*OAuth\|OAuth.*never' "$STUDIO"
grep -qi 'project.*never.*\.mcp\.json\|\.mcp\.json.*never.*project' "$STUDIO"
if find skills/project -name .mcp.json -print -quit | grep -q .; then
  echo "project skill unexpectedly contains an MCP manifest" >&2
  exit 1
fi

echo "✓ studio and project boundaries have distinct owners"
