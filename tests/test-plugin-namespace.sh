#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECKER="$REPO_ROOT/scripts/check-plugin-namespace.py"
FIXTURE="$(mktemp -d)"
trap 'rm -rf "$FIXTURE"' EXIT

make_fixture() {
  rm -rf "$FIXTURE"
  mkdir -p \
    "$FIXTURE/.claude-plugin" \
    "$FIXTURE/skills/studio" \
    "$FIXTURE/skills/project" \
    "$FIXTURE/skills/tasklist" \
    "$FIXTURE/hooks"
  cp "$REPO_ROOT/.claude-plugin/plugin.json" "$FIXTURE/.claude-plugin/plugin.json"
  cp "$REPO_ROOT/.claude-plugin/marketplace.json" "$FIXTURE/.claude-plugin/marketplace.json"
  python3 - "$FIXTURE" <<'PY'
import json
import pathlib
import sys

root = pathlib.Path(sys.argv[1])
plugin = json.loads((root / ".claude-plugin/plugin.json").read_text())
plugin["name"] = "as"
(root / ".claude-plugin/plugin.json").write_text(json.dumps(plugin))
marketplace = json.loads((root / ".claude-plugin/marketplace.json").read_text())
marketplace["name"] = "skills-for-architects"
marketplace["plugins"] = [{"name": "as", "source": "./"}]
(root / ".claude-plugin/marketplace.json").write_text(json.dumps(marketplace))
PY
  printf '%s\n' \
    '---' \
    'name: studio' \
    'description: fixture' \
    '---' \
    '' \
    'Run `/as:studio`.' > "$FIXTURE/skills/studio/SKILL.md"
  printf '%s\n' \
    '---' \
    'name: project' \
    'description: fixture' \
    '---' \
    '' \
    'Run `/as:project`.' > "$FIXTURE/skills/project/SKILL.md"
  printf '%s\n' \
    '---' \
    'name: tasklist' \
    'description: fixture' \
    '---' \
    '' \
    'Run `/as:tasklist`.' > "$FIXTURE/skills/tasklist/SKILL.md"
  printf '%s\n' \
    '.architecture-studio-welcomed' \
    '.architecture-studio-update-check-enabled' \
    '.architecture-studio-version-check' > "$FIXTURE/hooks/state.txt"
}

expect_failure() {
  local expected="$1"
  if python3 "$CHECKER" "$FIXTURE" > "$FIXTURE-output" 2>&1; then
    echo "expected namespace validator to fail: $expected" >&2
    exit 1
  fi
  grep -Fq "$expected" "$FIXTURE-output"
}

make_fixture
python3 "$CHECKER" "$FIXTURE" >/dev/null

make_fixture
printf '\nUse `/as:<skill>` as the documented placeholder.\n' \
  >> "$FIXTURE/skills/studio/SKILL.md"
python3 "$CHECKER" "$FIXTURE" >/dev/null

make_fixture
printf '\nRun `/project`.\n' >> "$FIXTURE/skills/studio/SKILL.md"
expect_failure "bare bundled command '/project'"

make_fixture
printf '\nRun /tasklist.\n' >> "$FIXTURE/skills/studio/SKILL.md"
expect_failure "bare bundled command '/tasklist'"

make_fixture
mkdir -p "$FIXTURE/skills/learn/examples/tasklist"
printf '%s\n' \
  '---' \
  'name: tasklist' \
  'description: nested fixture' \
  '---' > "$FIXTURE/skills/learn/examples/tasklist/SKILL.md"
expect_failure "SKILL.md is allowed only at skills/<name>/SKILL.md"

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/tasklist"
printf '%s\n' \
  '---' \
  'name: tasklist-example' \
  'description: misplaced installable fixture' \
  '---' > "$FIXTURE/assets/learn-examples/tasklist/SKILL.md"
expect_failure "SKILL.md is allowed only at skills/<name>/SKILL.md"

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/ascii-name"
printf '%s\n' \
  '---' \
  'name: ascii-name' \
  'description: distinct example fixture' \
  '---' > "$FIXTURE/assets/learn-examples/ascii-name/SKILL.example.md"
python3 "$CHECKER" "$FIXTURE" >/dev/null

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/unnamed"
printf '%s\n' \
  '---' \
  'description: missing name fixture' \
  '---' > "$FIXTURE/assets/learn-examples/unnamed/SKILL.example.md"
expect_failure "example skill must declare a frontmatter name"

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/wrong-directory"
printf '%s\n' \
  '---' \
  'name: different-name' \
  'description: mismatched example fixture' \
  '---' > "$FIXTURE/assets/learn-examples/wrong-directory/SKILL.example.md"
expect_failure "example skill name 'different-name' must match directory 'wrong-directory'"

make_fixture
mkdir -p \
  "$FIXTURE/assets/learn-examples/first-example" \
  "$FIXTURE/assets/skill-maker-template"
printf '%s\n' \
  '---' \
  'name: first-example' \
  'description: first duplicate fixture' \
  '---' > "$FIXTURE/assets/learn-examples/first-example/SKILL.example.md"
printf '%s\n' \
  '---' \
  'name: first-example' \
  'description: second duplicate fixture' \
  '---' > "$FIXTURE/assets/skill-maker-template/SKILL.example.md"
expect_failure "duplicate example skill name 'first-example'"

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/tasklist"
printf '%s\n' \
  '---' \
  'name: tasklist' \
  'description: colliding example fixture' \
  '---' > "$FIXTURE/assets/learn-examples/tasklist/SKILL.example.md"
expect_failure "example skill name 'tasklist' overlaps canonical skill"

make_fixture
mkdir -p "$FIXTURE/assets/learn-examples/sandbox"
printf '\nThe sandbox teaches `/project` and `/tasklist`.\n' \
  > "$FIXTURE/assets/learn-examples/sandbox/README.md"
python3 "$CHECKER" "$FIXTURE" >/dev/null

python3 - "$FIXTURE/.claude-plugin/plugin.json" <<'PY'
import json, pathlib, sys
p = pathlib.Path(sys.argv[1])
d = json.loads(p.read_text())
d["name"] = "architecture-studio"
p.write_text(json.dumps(d))
PY
expect_failure "plugin name must be 'as'"

make_fixture
printf '\nRun /as:not-real.\n' >> "$FIXTURE/skills/studio/SKILL.md"
expect_failure "'/as:not-real' does not resolve"

make_fixture
printf '\nRead ~/Documents/as:project-epds/input.pdf.\n' \
  >> "$FIXTURE/skills/studio/SKILL.md"
python3 "$CHECKER" "$FIXTURE" >/dev/null

make_fixture
printf '\nRun `/architecture-studio:studio`.\n' >> "$FIXTURE/skills/studio/SKILL.md"
expect_failure "retired command namespace"

make_fixture
printf '\nInstall architecture-studio@skills-for-architects.\n' >> "$FIXTURE/skills/studio/SKILL.md"
expect_failure "retired install ID"

make_fixture
make_fixture
printf '%s\n' \
  '# Fixture' \
  '' \
  '### Upgrading to v1.4.0 (reinstall required)' \
  '' \
  'Uninstall architecture-studio@skills-for-architects.' \
  'The retired command was `/architecture-studio:studio`.' \
  '' \
  '### Use' \
  '' \
  'Run `/as:studio`.' > "$FIXTURE/README.md"
python3 "$CHECKER" "$FIXTURE" >/dev/null

printf '\nOutside: architecture-studio@skills-for-architects.\n' \
  >> "$FIXTURE/README.md"
expect_failure "retired install ID"

make_fixture
mkdir -p "$FIXTURE/skills/architecture-studio-studio"
cp "$FIXTURE/skills/studio/SKILL.md" \
  "$FIXTURE/skills/architecture-studio-studio/SKILL.md"
expect_failure "retired namespace wrapper/alias directories are forbidden"

make_fixture
printf '\n.as-version-check\n' >> "$FIXTURE/hooks/state.txt"
expect_failure "would rename persistent state"

echo "✓ plugin namespace validator accepts /as:* and rejects retired identities, aliases, and state renames"
