#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

PLUGIN_ROOT="$TEST_ROOT/plugin"
DATA_DIR="$TEST_ROOT/data"
OLD_PLUGIN_DATA="$TEST_ROOT/plugin-data-old"
NEW_PLUGIN_DATA="$TEST_ROOT/plugin-data-new"
mkdir -p "$PLUGIN_ROOT/.claude-plugin" "$PLUGIN_ROOT/skills/studio" "$PLUGIN_ROOT/skills/project" "$PLUGIN_ROOT/skills/learn" "$PLUGIN_ROOT/hooks"
touch "$PLUGIN_ROOT/.claude-plugin/plugin.json" "$PLUGIN_ROOT/skills/studio/SKILL.md" "$PLUGIN_ROOT/skills/project/SKILL.md" "$PLUGIN_ROOT/skills/learn/SKILL.md" "$PLUGIN_ROOT/hooks/hooks.json"

OUTPUT=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_DATA="$OLD_PLUGIN_DATA" ARCHITECTURE_STUDIO_STATE_DIR="$DATA_DIR" ./hooks/session-start-welcome.sh)
printf '%s' "$OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); m=d["systemMessage"]; c=d["hookSpecificOutput"]["additionalContext"]; assert "Architecture Studio is installed" in m; assert "built-in tools are ready" in m; assert "/as:tool-catalog" in m; assert "optional" in m; assert "/as:studio" in m; assert "/as:learn" in m; assert "Do not interrupt" in c; assert "Full branding and setup are owned by the /as:studio skill" in c; assert "█████" not in m+c; assert not any(x in m+c for x in ["found 1 skills", "40 skills", "41 skills"])'
[ -f "$DATA_DIR/.architecture-studio-welcomed" ]
[ ! -e "$OLD_PLUGIN_DATA/.architecture-studio-welcomed" ]

# A different identifier-scoped plugin data root still sees the stable marker.
SECOND=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_DATA="$NEW_PLUGIN_DATA" ARCHITECTURE_STUDIO_STATE_DIR="$DATA_DIR" ./hooks/session-start-welcome.sh)
[ -z "$SECOND" ]

PARTIAL_DATA="$TEST_ROOT/partial-data"
rm -f "$PLUGIN_ROOT/skills/project/SKILL.md"
PARTIAL=$(CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_DATA="$NEW_PLUGIN_DATA" ARCHITECTURE_STUDIO_STATE_DIR="$PARTIAL_DATA" ./hooks/session-start-welcome.sh)
printf '%s' "$PARTIAL" | python3 -c 'import json,sys; d=json.load(sys.stdin); m=d["systemMessage"]; assert "appears incomplete" in m; assert "skills/project/SKILL.md" in m; assert "found 1" not in m'

FAKE_BIN="$TEST_ROOT/fake-bin"
FAILED_DATA="$TEST_ROOT/failed-data"
mkdir -p "$FAKE_BIN"
printf '#!/usr/bin/env sh\nexit 1\n' > "$FAKE_BIN/jq"
chmod +x "$FAKE_BIN/jq"
FAILED=$(PATH="$FAKE_BIN:$PATH" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" CLAUDE_PLUGIN_DATA="$NEW_PLUGIN_DATA" ARCHITECTURE_STUDIO_STATE_DIR="$FAILED_DATA" ./hooks/session-start-welcome.sh)
[ -z "$FAILED" ]
[ ! -e "$FAILED_DATA/.architecture-studio-welcomed" ]

echo "✓ session notice makes /as:studio visible without hijacking the first response"
