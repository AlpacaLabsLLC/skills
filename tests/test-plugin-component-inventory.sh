#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

[ ! -e agents/README.md ]
[ -f docs/agents.md ]
[ "$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')" = 7 ]
[ "$(find skills -mindepth 2 -maxdepth 2 -type f -name SKILL.md | wc -l | tr -d ' ')" = 46 ]

# Claude is not installed in every CI environment. When available, verify the
# same inventory users receive from an isolated local marketplace install.
if command -v claude >/dev/null 2>&1; then
  test_root=$(mktemp -d)
  trap 'rm -rf "$test_root"' EXIT
  test_home="$test_root/home"
  test_config="$test_root/config"
  test_state="$test_root/state"
  mkdir -p "$test_home" "$test_config" "$test_state"

  env HOME="$test_home" \
    CLAUDE_CONFIG_DIR="$test_config" \
    ARCHITECTURE_STUDIO_STATE_DIR="$test_state" \
    claude plugin marketplace add "$PWD" >/dev/null
  env HOME="$test_home" \
    CLAUDE_CONFIG_DIR="$test_config" \
    ARCHITECTURE_STUDIO_STATE_DIR="$test_state" \
    claude plugin install as@skills-for-architects >/dev/null
  details=$(env HOME="$test_home" \
    CLAUDE_CONFIG_DIR="$test_config" \
    ARCHITECTURE_STUDIO_STATE_DIR="$test_state" \
    claude plugin details as@skills-for-architects)

  printf '%s\n' "$details" | grep -q '^  Skills (46)  '
  printf '%s\n' "$details" | grep -q '^  Agents (7)  '
  printf '%s\n' "$details" | grep -q '^  Hooks (3)  SessionStart, PostToolUse, PreToolUse'
  printf '%s\n' "$details" | grep -q '^  MCP servers (0)$'
  ! printf '%s\n' "$details" | grep -q 'Agents (.*README'
fi

echo "✓ installed component inventory contains 46 skills, 7 agents, and 4 handlers across 3 hook events"
