#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
from pathlib import Path

plugin = json.loads(Path('.claude-plugin/plugin.json').read_text())
marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())
assert plugin['version'] == '1.4.0'
assert marketplace['metadata']['version'] == '1.4.0'
assert plugin['description'].startswith('Architecture Studio —')
assert marketplace['plugins'][0]['description'].startswith('Architecture Studio —')
PY

grep -q '^## \[Unreleased\]$' CHANGELOG.md
grep -q '^## \[1\.4\.0\] - 2026-07-26$' CHANGELOG.md
grep -q 'sequential `major.minor.patch` release scheme' CHANGELOG.md
grep -q '^\[Unreleased\]: .*compare/v1\.4\.0\.\.\.HEAD$' CHANGELOG.md
grep -q '^\[1\.4\.0\]: .*releases/tag/v1\.4\.0$' CHANGELOG.md
grep -q 'product-library.csv' README.md
grep -q 'epd-library.csv' README.md
grep -q 'empty `mcpServers` object' README.md
grep -q 'user-exported CSV' PATTERNS.md
grep -q 'SIF is not a persistent schedule source' PATTERNS.md
grep -q '/as:master-schedule.*product-library.csv' skills/tool-catalog/SKILL.md
grep -q '/as:studio-feedback' skills/tool-catalog/SKILL.md
grep -q 'Background update checking is disabled by default' README.md
grep -q 'Opening the prefilled GitHub URL sends' README.md
grep -q '^### Three ways to use Architecture Studio$' README.md
grep -q 'No studio workspace is required' README.md
grep -qi 'install.*plugin' README.md
grep -q '/as:studio' README.md
grep -q '/as:tool-catalog' README.md
grep -q '/as:studio-feedback' README.md
grep -q 'as@skills-for-architects' README.md
grep -q '^### Upgrading to v1\.4\.0 (reinstall required)$' README.md
grep -q '/as:project migrate' README.md
grep -q 'welcome and update-check preferences remain in place' README.md
[ ! -e agents/README.md ]
[ "$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')" = 7 ]
grep -q '4 hooks (handlers across 3 events)' README.md
[ -z "$(find docs/plans -maxdepth 1 -type f -name '*.md' -print 2>/dev/null)" ]

python3 - <<'PY'
from pathlib import Path

text = Path("CHANGELOG.md").read_text()
release = text.split("## [1.4.0] - 2026-07-26", 1)[1].split("## [1.3.0]", 1)[0]
expected = [
    "### Breaking",
    "### Migration",
    "### Architecture and extensibility",
    "### Data boundaries and onboarding",
    "### Project workflow and memory",
    "### Learning and extension tooling",
    "### Fixes and optimization",
]
for heading in expected:
    assert release.count(heading) == 1, heading
assert "### Added" not in release
assert "### Changed" not in release
assert "welcome and update-check preferences remain in place" in release
PY

python3 - <<'PY'
import json
from pathlib import Path

plugin = json.loads(Path(".claude-plugin/plugin.json").read_text())
marketplace = json.loads(Path(".claude-plugin/marketplace.json").read_text())
assert plugin["name"] == "as"
assert marketplace["name"] == "skills-for-architects"
assert len(marketplace["plugins"]) == 1
assert marketplace["plugins"][0]["name"] == "as"
assert marketplace["plugins"][0]["source"] == "./"
PY
! rg -n '^name: (skills|feedback)$' skills/*/SKILL.md
! grep -q 'claude "/studio"' README.md
! grep -Eqi 'download (the )?`?skills/?`?|copy.*repository.*skills/' README.md
! rg -n '2\.0\.0|2\.1\.0' .claude-plugin README.md CHANGELOG.md skills hooks

echo "✓ v1.4 release contract documents its local data, feedback, update, connector, and migration boundaries"
