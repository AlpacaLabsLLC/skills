#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

TEST_ROOT=$(mktemp -d)
trap 'rm -rf "$TEST_ROOT"' EXIT

PLUGIN_ROOT="$TEST_ROOT/plugin"
FAKE_BIN="$TEST_ROOT/bin"
mkdir -p "$PLUGIN_ROOT/.claude-plugin" "$FAKE_BIN"
printf '{"version":"1.4.0"}\n' > "$PLUGIN_ROOT/.claude-plugin/plugin.json"

cat > "$FAKE_BIN/curl" <<'SH'
#!/usr/bin/env bash
printf 'called\n' >> "$CURL_MARKER"
if [ "${CURL_FAIL:-0}" = 1 ]; then exit 7; fi
if [ -n "${CURL_RESPONSE:-}" ]; then
  printf '%s\n' "$CURL_RESPONSE"
else
  printf '%s\n' '{"version":"v9.9.9"}'
fi
SH
chmod +x "$FAKE_BIN/curl"

run_hook() {
  response=${2:-'{"version":"v9.9.9"}'}
  PATH="$FAKE_BIN:$PATH" \
  CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
  CLAUDE_PLUGIN_DATA="${CLAUDE_PLUGIN_DATA_FIXTURE:-$TEST_ROOT/plugin-data-new}" \
  ARCHITECTURE_STUDIO_STATE_DIR="$1" \
  CURL_MARKER="$1/curl-called" \
  CURL_RESPONSE="$response" \
  CURL_FAIL="${3:-0}" \
  ./hooks/version-check.sh
}

# Preference changes are deterministic and status is read-only.
PREF="$TEST_ROOT/preference"
[ "$(CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data-old" ARCHITECTURE_STUDIO_STATE_DIR="$PREF" ./skills/studio/scripts/update-preference.sh status)" = disabled ]
[ ! -e "$PREF" ]
[ "$(CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data-old" ARCHITECTURE_STUDIO_STATE_DIR="$PREF" ./skills/studio/scripts/update-preference.sh enable)" = enabled ]
[ -f "$PREF/.architecture-studio-update-check-enabled" ]
[ ! -e "$TEST_ROOT/plugin-data-old/.architecture-studio-update-check-enabled" ]
mode=$(python3 -c 'import os,sys; print(oct(os.stat(sys.argv[1]).st_mode & 0o777)[2:])' "$PREF/.architecture-studio-update-check-enabled")
[ "$mode" = 600 ]
printf 'checked_at=0\nremote=9.9.9\nnudged_for=\n' > "$PREF/.architecture-studio-version-check"
[ "$(CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data-new" ARCHITECTURE_STUDIO_STATE_DIR="$PREF" ./skills/studio/scripts/update-preference.sh enable)" = enabled ]
[ ! -e "$PREF/.architecture-studio-version-check" ]
[ "$(CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data-new" ARCHITECTURE_STUDIO_STATE_DIR="$PREF" ./skills/studio/scripts/update-preference.sh disable)" = disabled ]
[ ! -e "$PREF/.architecture-studio-update-check-enabled" ]

# Opt in under the retired identifier's plugin-data root, then run the hook
# under the new identifier's distinct root. Both must use the stable state root.
CONTINUITY="$TEST_ROOT/continuity"
CLAUDE_PLUGIN_DATA_FIXTURE="$TEST_ROOT/plugin-data-new"
[ "$(CLAUDE_PLUGIN_DATA="$TEST_ROOT/plugin-data-old" ARCHITECTURE_STUDIO_STATE_DIR="$CONTINUITY" ./skills/studio/scripts/update-preference.sh enable)" = enabled ]
[ -z "$(run_hook "$CONTINUITY")" ]
[ -f "$CONTINUITY/.architecture-studio-version-check" ]
[ ! -e "$TEST_ROOT/plugin-data-old/.architecture-studio-update-check-enabled" ]
[ ! -e "$TEST_ROOT/plugin-data-new/.architecture-studio-version-check" ]

# Disabled is the default: no directory, cache, or request.
DISABLED="$TEST_ROOT/disabled"
[ -z "$(run_hook "$DISABLED")" ]
[ ! -e "$DISABLED" ]

# Enabled first session seeds silently without curl, independent of welcome state.
FIRST="$TEST_ROOT/first"
mkdir -p "$FIRST"
touch "$FIRST/.architecture-studio-update-check-enabled" "$FIRST/.architecture-studio-welcomed"
[ -z "$(run_hook "$FIRST")" ]
[ -f "$FIRST/.architecture-studio-version-check" ]
[ ! -e "$FIRST/curl-called" ]

# Stale cache and newer remote nudges once.
printf 'checked_at=0\nremote=\nnudged_for=\n' > "$FIRST/.architecture-studio-version-check"
NEW=$(run_hook "$FIRST")
printf '%s' "$NEW" | python3 -c 'import json,sys; d=json.load(sys.stdin); assert "9.9.9" in d["systemMessage"]; assert "1.4.0" in d["systemMessage"]; assert "do not bring this up unprompted" in d["hookSpecificOutput"]["additionalContext"]'
grep -q '^nudged_for=9.9.9$' "$FIRST/.architecture-studio-version-check"
[ -f "$FIRST/curl-called" ]

rm -f "$FIRST/curl-called"
[ -z "$(run_hook "$FIRST")" ]
[ ! -e "$FIRST/curl-called" ]

# Equal and older remote versions stay silent.
for remote in v1.4.0 v1.3.9; do
  CASE_DIR="$TEST_ROOT/${remote#v}"
  mkdir -p "$CASE_DIR"
  touch "$CASE_DIR/.architecture-studio-update-check-enabled"
  printf 'checked_at=0\nremote=\nnudged_for=\n' > "$CASE_DIR/.architecture-studio-version-check"
  [ -z "$(run_hook "$CASE_DIR" "{\"version\":\"$remote\"}")" ]
done

# Failure and malformed state are silent and always exit zero.
FAIL_DIR="$TEST_ROOT/fail"
mkdir -p "$FAIL_DIR"
touch "$FAIL_DIR/.architecture-studio-update-check-enabled"
printf 'checked_at=banana\nremote=bad\nnudged_for=bad\n' > "$FAIL_DIR/.architecture-studio-version-check"
[ -z "$(run_hook "$FAIL_DIR" '{}' 1)" ]
grep -Eq '^checked_at=[0-9]+$' "$FAIL_DIR/.architecture-studio-version-check"

MALFORMED="$TEST_ROOT/malformed"
mkdir -p "$MALFORMED"
touch "$MALFORMED/.architecture-studio-update-check-enabled"
printf 'checked_at=0\nremote=\nnudged_for=\n' > "$MALFORMED/.architecture-studio-version-check"
[ -z "$(run_hook "$MALFORMED" 'not-json')" ]

# Concurrent stale checks may duplicate a bounded request, but atomic cache
# replacement must always leave one complete, parseable three-line record.
CONCURRENT="$TEST_ROOT/concurrent"
mkdir -p "$CONCURRENT"
touch "$CONCURRENT/.architecture-studio-update-check-enabled"
printf 'checked_at=0\nremote=\nnudged_for=\n' > "$CONCURRENT/.architecture-studio-version-check"
run_hook "$CONCURRENT" >/dev/null & first_pid=$!
run_hook "$CONCURRENT" >/dev/null & second_pid=$!
wait "$first_pid" "$second_pid"
python3 - "$CONCURRENT/.architecture-studio-version-check" <<'PY'
from pathlib import Path
import re, sys
text = Path(sys.argv[1]).read_text()
assert re.fullmatch(r'checked_at=\d+\nremote=\d+\.\d+\.\d+\nnudged_for=(?:\d+\.\d+\.\d+)?\n', text), text
PY

grep -Fq '/as:studio updates enable' skills/studio/SKILL.md
grep -Fq '/as:studio updates disable' skills/studio/SKILL.md
grep -Fq '<skill-root>/scripts/update-preference.sh' skills/studio/SKILL.md
grep -Fq 'disabled by default' skills/studio/SKILL.md
rg -q 'Cloudflare.*processes ordinary request metadata' README.md

# The preference helper remains a Claude Code feature; Codex must stop before
# resolving update state or mutating its marker.
python3 - <<'PY'
from pathlib import Path

studio = Path('skills/studio/SKILL.md').read_text(encoding='utf-8')
updates = studio.split('### `/as:studio updates status|enable|disable`', 1)[1].split('### `/as:studio tasks mode project|portfolio`', 1)[0]
codex = updates.split('- **Codex:**', 1)[1].split('- **Claude Code:**', 1)[0]
claude = updates.split('- **Claude Code:**', 1)[1]

assert 'background update checking is unavailable' in codex
assert all(command in codex for command in ('`status`', '`enable`', '`disable`'))
assert 'Do not open a confirmation gate' in codex
assert 'run `<skill-root>/scripts/update-preference.sh`' in codex
assert 'create, remove, or inspect `.architecture-studio-update-check-enabled`' in codex

for command in ('status', 'enable', 'disable'):
    assert f'<skill-root>/scripts/update-preference.sh {command}' in claude

governance = Path('docs/data-governance.md').read_text(encoding='utf-8')
assert 'available only on Claude Code' in governance
assert 'The Codex package does not install that lifecycle hook' in governance
assert 'do not write an enablement marker or cache' in governance
PY

echo "✓ update checking is opt-in, throttled, fail-silent, and once per version"
