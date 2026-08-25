#!/bin/bash
# post-write-disclaimer-check.sh
# PostToolUse hook (matcher: Write|Edit). Verifies that markdown outputs
# claiming to be regulatory (via the architecture-studio:requires-disclaimer
# marker) also carry the canonical disclaimer block.
#
# Contract:
#   - A regulatory output ends with the canonical disclaimer block followed
#     by the HTML-comment marker `<!-- architecture-studio:requires-disclaimer -->`.
#   - This hook is marker-driven: if the marker is present, the canonical
#     disclaimer text must also be present. If the marker is absent, the
#     hook stays silent — the skill considered the output non-regulatory.
#   - "Present" means the marker occupies its own line. Prose that documents
#     the convention cites the marker inline inside backticks and is not a
#     regulatory output, so it is correctly ignored.
#   - Both Write and Edit provide `tool_input.file_path`; Edit carries no
#     full content, so the hook always reads the file from disk.
#   - On findings it emits PostToolUse JSON `{"decision": "block", ...}` on
#     stdout, which surfaces the reason to Claude (stderr + exit 0 is shown
#     to no one).
#   - See rules/professional-disclaimer.md for the canonical block.

INPUT=$(cat)
if command -v jq >/dev/null 2>&1; then
  if ! FILE_PATH=$(printf '%s' "$INPUT" | jq -er '.tool_input.file_path | strings' 2>/dev/null); then
    exit 0
  fi
elif command -v python3 >/dev/null 2>&1; then
  if ! FILE_PATH=$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    value = json.load(sys.stdin)["tool_input"]["file_path"]
    if not isinstance(value, str) or not value:
        raise ValueError("file_path is not a non-empty string")
    sys.stdout.write(value)
except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
    print(f"invalid hook payload: {exc}", file=sys.stderr)
    raise SystemExit(2)' 2>/dev/null); then
    exit 0
  fi
else
  exit 0
fi

# Only check writes/edits to markdown files.
[[ "$FILE_PATH" != *.md ]] && exit 0
[ -f "$FILE_PATH" ] || exit 0
[ -s "$FILE_PATH" ] || exit 0

# The marker is an end-of-file sentinel occupying its own line. Matching it
# as a whole line (rather than anywhere in the text) is what separates a
# marker in USE from a marker being DOCUMENTED: prose that explains the
# convention cites it inline, inside backticks, mid-sentence. Substring
# matching blocked every edit to CHANGELOG.md, PATTERNS.md, hooks/README.md,
# rules/README.md, and skills/skill-maker/SKILL.md — none of which is a
# regulatory output.
MARKER_RE='^[[:space:]]*<!-- architecture-studio:requires-disclaimer -->[[:space:]]*$'
DISCLAIMER_PHRASE='AI-generated analysis for preliminary planning purposes'

# If no marker, this isn't a regulatory output; nothing to check.
if ! grep -qE "$MARKER_RE" "$FILE_PATH"; then
  exit 0
fi

PROBLEMS=""

# Marker present → canonical disclaimer text must also be present.
if ! grep -qF "$DISCLAIMER_PHRASE" "$FILE_PATH"; then
  PROBLEMS="$FILE_PATH carries the architecture-studio:requires-disclaimer marker but is missing the canonical disclaimer block. Restore the block from ${CLAUDE_PLUGIN_ROOT:-<plugin-root>}/rules/professional-disclaimer.md."
fi

# Marker should be a single end-of-file sentinel; flag duplicates.
MARKER_COUNT=$(grep -cE "$MARKER_RE" "$FILE_PATH")
if [ "$MARKER_COUNT" -gt 1 ]; then
  [ -n "$PROBLEMS" ] && PROBLEMS="$PROBLEMS
"
  PROBLEMS="${PROBLEMS}$FILE_PATH contains the architecture-studio:requires-disclaimer marker $MARKER_COUNT times. It must appear exactly once, at end of file."
fi

if [ -n "$PROBLEMS" ]; then
  if command -v jq >/dev/null 2>&1; then
    jq -n --arg reason "$PROBLEMS" '{decision: "block", reason: $reason}'
  elif command -v python3 >/dev/null 2>&1; then
    PROBLEMS="$PROBLEMS" python3 -c 'import json,os; print(json.dumps({"decision":"block","reason":os.environ["PROBLEMS"]}))'
  else
    printf '{"decision":"block","reason":"Architecture Studio disclaimer check failed; restore the canonical block from %s/rules/professional-disclaimer.md."}\n' "${CLAUDE_PLUGIN_ROOT:-<plugin-root>}"
  fi
fi

exit 0
