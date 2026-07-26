#!/usr/bin/env bash
# Optional daily release check. It must never block or delay a session after
# its bounded request, and it performs no I/O until the user has opted in.

set -u

DATA_DIR="${ARCHITECTURE_STUDIO_STATE_DIR:-$HOME/.claude}"
ENABLED="$DATA_DIR/.architecture-studio-update-check-enabled"
CACHE="$DATA_DIR/.architecture-studio-version-check"
ENDPOINT="https://version.alpa.llc/"

[ -f "$ENABLED" ] || exit 0
mkdir -p "$DATA_DIR" 2>/dev/null || exit 0
umask 077

now=$(date +%s 2>/dev/null) || exit 0
case "$now" in ''|*[!0-9]*) exit 0 ;; esac

read_key() {
  key=$1
  [ -f "$CACHE" ] || return 0
  grep -E "^${key}=" "$CACHE" 2>/dev/null | tail -n 1 | cut -d= -f2-
}

write_cache() {
  checked=$1
  remote_value=$2
  nudged=$3
  tmp=$(mktemp "$DATA_DIR/.architecture-studio-version-check.XXXXXX" 2>/dev/null) || return 1
  if ! printf 'checked_at=%s\nremote=%s\nnudged_for=%s\n' "$checked" "$remote_value" "$nudged" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  chmod 600 "$tmp" 2>/dev/null || true
  mv "$tmp" "$CACHE" 2>/dev/null || { rm -f "$tmp"; return 1; }
}

valid_version() {
  [[ $1 =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

version_gt() {
  valid_version "$1" && valid_version "$2" || return 1
  IFS=. read -r a1 a2 a3 <<< "$1"
  IFS=. read -r b1 b2 b3 <<< "$2"
  a1=$((10#$a1)); a2=$((10#$a2)); a3=$((10#$a3))
  b1=$((10#$b1)); b2=$((10#$b2)); b3=$((10#$b3))
  (( a1 > b1 )) || { (( a1 == b1 && a2 > b2 )) || { (( a1 == b1 && a2 == b2 && a3 > b3 )); }; }
}

parse_remote() {
  payload=$1
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$payload" | jq -er '.version | strings' 2>/dev/null
  else
    printf '%s' "$payload" | sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1
  fi
}

local_version() {
  manifest="${CLAUDE_PLUGIN_ROOT:-}/.claude-plugin/plugin.json"
  [ -f "$manifest" ] || return 1
  if command -v jq >/dev/null 2>&1; then
    jq -er '.version | strings' "$manifest" 2>/dev/null
  else
    sed -n 's/.*"version"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$manifest" | head -n 1
  fi
}

# Cache absence is the first-enabled-session boundary. This deliberately does
# not depend on the welcome hook or hook ordering.
if [ ! -f "$CACHE" ]; then
  write_cache "$now" "" "" >/dev/null 2>&1 || true
  exit 0
fi

checked_at=$(read_key checked_at)
remote=$(read_key remote)
nudged_for=$(read_key nudged_for)
case "$checked_at" in ''|*[!0-9]*) checked_at=0 ;; esac
valid_version "$remote" || remote=""
valid_version "$nudged_for" || nudged_for=""

if (( now - checked_at >= 86400 || now < checked_at )); then
  payload=$(curl -fsS --max-time 2 "$ENDPOINT" 2>/dev/null) || payload=""
  fetched=$(parse_remote "$payload" 2>/dev/null) || fetched=""
  fetched=${fetched#v}
  if valid_version "$fetched"; then
    remote=$fetched
  fi
  checked_at=$now
  write_cache "$now" "$remote" "$nudged_for" >/dev/null 2>&1 || true
fi

local=$(local_version 2>/dev/null) || exit 0
local=${local#v}
valid_version "$local" || exit 0
[ -n "$remote" ] || exit 0
version_gt "$remote" "$local" || exit 0
[ "$nudged_for" != "$remote" ] || exit 0

message="Architecture Studio $remote is available (you have $local). Update through /plugin → skills-for-architects → update. Disable checks with /as:studio updates disable."
context="[architecture-studio update] Installed version: $local. Available version: $remote. The user has already received the update notice; do not bring this up unprompted."

if command -v jq >/dev/null 2>&1; then
  jq -n --arg message "$message" --arg ctx "$context" '{systemMessage:$message,hookSpecificOutput:{hookEventName:"SessionStart",additionalContext:$ctx}}' || exit 0
else
  escaped_message=$(printf '%s' "$message" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  escaped_context=$(printf '%s' "$context" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')
  printf '{"systemMessage":"%s","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped_message" "$escaped_context" || exit 0
fi

write_cache "$checked_at" "$remote" "$remote" >/dev/null 2>&1 || true
exit 0
