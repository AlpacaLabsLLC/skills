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
grep -q 'writes only the synchronized `Status` field' "$STUDIO"
grep -q 'registration and status mutation belong to `/as:studio`' "$PROJECT"
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
grep -q 'Do not prefix the project display name or project-name slug with the client name' "$STUDIO"
grep -q 'set-project-status' "$STUDIO"
grep -q 'prospective.*active.*on-hold.*lost.*withdrawn.*completed.*archived' "$STUDIO"
grep -q 'exact absolute project path plus its `.agents/skills/` and `.claude/skills/` paths' "$STUDIO"
grep -q 'restart the active harness from that project root' "$STUDIO"
grep -q 'exact absolute studio path and both skill roots' "$STUDIO"
grep -q 'restart the active harness from the studio root' "$STUDIO"
! grep -q 'skip for now' "$STUDIO"
grep -q '\.mcp\.json' "$STUDIO"
grep -q 'empty-reserved' "$STUDIO"
grep -qi 'never.*OAuth\|OAuth.*never' "$STUDIO"
grep -qi 'project.*never.*\.mcp\.json\|\.mcp\.json.*never.*project' "$STUDIO"
if find skills/project -name .mcp.json -print -quit | grep -q .; then
  echo "project skill unexpectedly contains an MCP manifest" >&2
  exit 1
fi

# Host-specific onboarding and dispatch must not expose Claude-only affordances
# as executable Codex routes.
python3 - <<'PY'
from pathlib import Path

studio = Path('skills/studio/SKILL.md').read_text(encoding='utf-8')
welcome = studio.split('## Welcome and no-argument behavior', 1)[1].split('### Single-gate rule', 1)[0]
routing = studio.split('## Task routing', 1)[1].split('## What `/as:studio` does not do', 1)[0]

assert '**Claude Code:** present these four outcomes' in welcome
assert '**Codex:** present these four outcomes' in welcome
assert 'continue directly into `$studio init`' in welcome
assert 'point to `$tool-catalog`' in welcome
assert 'hand off to `$learn`' in welcome

claude_routes = routing.split('### Claude Code native-agent routes', 1)[1].split('### Codex skill routes and synthesis', 1)[0]
for agent in (
    'Site Planner agent',
    'NYC Zoning Expert agent',
    'Workplace Strategist agent',
    'Product & Materials Researcher agent',
    'FF&E Designer agent',
    'Sustainability Specialist agent',
    'Brand Manager agent',
):
    assert agent in claude_routes, agent

codex_routes = routing.split('### Codex skill routes and synthesis', 1)[1]
expected_lanes = {
    'Site context': ('$environmental-analysis', '$mobility-analysis', '$demographics-analysis', '$site-history'),
    'NYC zoning': ('$nyc-property-report', '$zoning-analysis-nyc', '$zoning-envelope'),
    'Programming': ('$workplace-programmer', '$occupancy-calculator'),
    'Specifications': ('$spec-writer', '$epd-to-spec'),
    'Materials and FF&E': ('$product-research', '$master-schedule'),
    'Sustainability': ('$epd-research', '$epd-parser', '$epd-compare', '$epd-to-spec'),
    'Presentations': ('$color-palette-generator', '$resize-images', '$slide-deck-generator'),
}
for lane, skills in expected_lanes.items():
    assert f'| {lane} |' in codex_routes, lane
    for skill in skills:
        assert skill in codex_routes, f'{lane}: {skill}'

assert '$studio 123 Main St, Brooklyn NY' in codex_routes
assert '$studio task chair, mesh back, under $800' in codex_routes
assert 'On Codex, render every suggested command as `$<skill-name>`' in codex_routes
assert 'never emit a Claude-style slash command' in codex_routes
assert 'On Claude Code, render skills as `/as:<skill-name>`' in codex_routes
PY

echo "✓ studio and project boundaries have distinct owners"
