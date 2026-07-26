#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SKILL="skills/studio-feedback/SKILL.md"
[ -f "$SKILL" ]
[ -f skills/studio-feedback/README.md ]
[ -f .github/ISSUE_TEMPLATE/bug-report.yml ]
[ -f .github/ISSUE_TEMPLATE/feature-request.yml ]
[ -f .github/ISSUE_TEMPLATE/config.yml ]

grep -Fq 'Opening GitHub sends the displayed fields immediately' "$SKILL"
grep -Fq 'closing the tab does not undo that transmission' "$SKILL"
grep -Fq 'Never submit the issue' "$SKILL"
grep -Fq 'single confirmation gate' "$SKILL"
grep -Fq 'project names' "$SKILL"
grep -Fq 'home-directory paths' "$SKILL"
grep -Fq 'likely secrets' "$SKILL"
grep -Fq '6,000' "$SKILL"

if rg -n 'close the tab to send nothing|submit.*on the user.s behalf|automatic[^\n]*submit' "$SKILL" skills/studio-feedback/README.md; then
  echo "feedback contract contains a false no-transmission or submission claim" >&2
  exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re

skill = Path('skills/studio-feedback/SKILL.md').read_text()
forms = {
    'bug-report.yml': {'version', 'os', 'skill', 'what-happened', 'expected'},
    'feature-request.yml': {'version', 'skill', 'problem', 'proposal'},
}
for filename, expected in forms.items():
    text = Path('.github/ISSUE_TEMPLATE', filename).read_text()
    ids = set(re.findall(r'^\s+id:\s*([a-z0-9-]+)\s*$', text, re.M))
    assert ids == expected, (filename, ids, expected)
    for field_id in expected:
        assert f'`{field_id}`' in skill, (filename, field_id)

assert 'allowed-tools:' in skill
assert 'AskUserQuestion' in skill
assert 'Bash' in skill
assert 'Write' not in skill.split('---', 2)[1]
PY

grep -Fq '| [`/as:studio-feedback`](./studio-feedback)' skills/README.md
grep -Fq '/as:studio-feedback' skills/tool-catalog/SKILL.md

echo "✓ feedback is review-first, field-compatible, and never auto-submits"
