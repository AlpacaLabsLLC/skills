#!/usr/bin/env bash
# One-time first-session notice. Full branded onboarding belongs to the studio skill;
# this hook only makes that entry point discoverable before the first prompt.
# Exit 0 always: onboarding must never block a Claude Code session.

set -u

DATA_DIR="${ARCHITECTURE_STUDIO_STATE_DIR:-$HOME/.claude}"
MARKER="$DATA_DIR/.architecture-studio-welcomed"

[ -f "$MARKER" ] && exit 0
mkdir -p "$DATA_DIR" 2>/dev/null || exit 0

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-}"
MISSING=""

check_sentinel() {
  [ -e "$PLUGIN_ROOT/$1" ] || MISSING="${MISSING}${MISSING:+, }$1"
}

if [ -n "$PLUGIN_ROOT" ] && [ -d "$PLUGIN_ROOT" ]; then
  check_sentinel ".claude-plugin/plugin.json"
  check_sentinel "skills/studio/SKILL.md"
  check_sentinel "skills/project/SKILL.md"
  check_sentinel "skills/learn/SKILL.md"
  check_sentinel "hooks/hooks.json"
else
  MISSING="plugin root"
fi

if [ -z "$MISSING" ]; then
  STATUS="Architecture Studio is installed and its required setup, project, learning, and hook surfaces are available."
else
  STATUS="Architecture Studio appears incomplete; missing: $MISSING. Suggest updating the skills-for-architects marketplace and reinstalling as@skills-for-architects."
fi

SYSTEM_MESSAGE="$STATUS The built-in tools are ready: use /as:tool-catalog to browse or call a skill directly. Run /as:studio for optional local workspace setup, or /as:learn for the course."
CONTEXT="[architecture-studio first run] Architecture Studio is available. Do not interrupt or rewrite the user's first request with onboarding. If setup is relevant, mention /as:studio briefly. Full branding and setup are owned by the /as:studio skill."

emit_context() {
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg message "$SYSTEM_MESSAGE" --arg ctx "$CONTEXT" '{systemMessage:$message,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}'
  else
    ESCAPED=$(printf '%s' "$CONTEXT" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' | awk '{printf "%s\\n", $0}' | sed -e 's/\\n$//')
    MESSAGE_ESCAPED=$(printf '%s' "$SYSTEM_MESSAGE" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
    printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$MESSAGE_ESCAPED" "$ESCAPED"
  fi
}

if emit_context; then
  touch "$MARKER" 2>/dev/null || true
fi
exit 0
