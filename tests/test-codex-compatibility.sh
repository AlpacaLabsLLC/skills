#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
from pathlib import Path

claude = json.loads(Path('.claude-plugin/plugin.json').read_text(encoding='utf-8'))
claude_marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text(encoding='utf-8'))
codex = json.loads(Path('.codex-plugin/plugin.json').read_text(encoding='utf-8'))
codex_marketplace = json.loads(Path('.agents/plugins/marketplace.json').read_text(encoding='utf-8'))

assert codex['name'] == claude['name'] == 'as'
assert codex['version'] == claude['version'] == claude_marketplace['metadata']['version']
assert codex['skills'] == './skills/'
assert codex['repository'] == 'https://github.com/AlpacaLabsLLC/skills-for-architects'

interface = codex['interface']
for field in ('displayName', 'shortDescription', 'longDescription', 'developerName', 'category', 'capabilities', 'websiteURL', 'defaultPrompt'):
    assert interface.get(field), field

assert codex_marketplace['name'] == 'skills-for-architects'
assert len(codex_marketplace['plugins']) == 1
entry = codex_marketplace['plugins'][0]
assert entry['name'] == 'as'
assert entry['source'] == {'source': 'local', 'path': './'}
assert entry['policy'] == {'installation': 'AVAILABLE', 'authentication': 'ON_INSTALL'}
assert entry['category'] == interface['category']

expected_harness_note = (
    '> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. '
    'Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and '
    '`<plugin-root>` as the plugin root that contains `skills/`, and use equivalent '
    'native tools when host tool names differ.'
)
skill_files = sorted(Path('skills').glob('*/SKILL.md'))
assert skill_files, 'no bundled skills found'
for skill_file in skill_files:
    skill_text = skill_file.read_text(encoding='utf-8')
    assert 'architecture-studio:harness-compatibility' in skill_text, (
        f'missing harness compatibility contract: {skill_file}'
    )
    assert expected_harness_note in skill_text.splitlines(), (
        f'incorrect portable root contract: {skill_file}'
    )

forbidden_roots = ('${CLAUDE_PLUGIN_ROOT}', '${CLAUDE_SKILL_DIR}')
violations = []
for asset in sorted(Path('skills').rglob('*')):
    if not asset.is_file():
        continue
    asset_bytes = asset.read_bytes()
    if b'\0' in asset_bytes:
        continue
    try:
        asset_text = asset_bytes.decode('utf-8')
    except UnicodeDecodeError:
        continue
    for line_number, line in enumerate(asset_text.splitlines(), start=1):
        for forbidden_root in forbidden_roots:
            if forbidden_root in line:
                violations.append(f'{asset}:{line_number}: {forbidden_root}')

assert not violations, (
    'Claude-only bundled path variables remain in portable skill assets:\n'
    + '\n'.join(violations)
)
PY

grep -q 'mkdir -p.*\.agents/skills' skills/studio/scripts/studio-workspace.sh
grep -q 'mkdir -p.*\.agents/skills' skills/project/scripts/project-workspace.sh
grep -q 'AGENTS.md' skills/studio/scripts/studio-workspace.sh
grep -q 'AGENTS.md' skills/project/scripts/project-workspace.sh

grep -q 'codex plugin marketplace add AlpacaLabsLLC/skills-for-architects' README.md
grep -q 'codex plugin add as@skills-for-architects' README.md

echo "✓ Codex manifest, marketplace, skills, workspace scaffolds, and install docs stay compatible"
