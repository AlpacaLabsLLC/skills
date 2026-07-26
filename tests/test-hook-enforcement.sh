#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

doc="$root/report with space \"quote\" \\slash
newline.md"
printf 'Regulatory output\n<!-- architecture-studio:requires-disclaimer -->\n' > "$doc"
payload=$(FILE_PATH="$doc" python3 -c 'import json,os; print(json.dumps({"tool_input":{"file_path":os.environ["FILE_PATH"]}}))')

with_jq=$(printf '%s' "$payload" | CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
printf '%s' "$with_jq" | grep -q 'decision'
printf '%s' "$with_jq" | grep -Fq "$PWD/rules/professional-disclaimer.md"

fake_bin="$root/bin"
mkdir -p "$fake_bin"
for command in cat grep python3 git bash; do
  path=$(command -v "$command")
  [ -n "$path" ] && ln -s "$path" "$fake_bin/$command"
done
without_jq=$(printf '%s' "$payload" | PATH="$fake_bin" CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
printf '%s' "$without_jq" | grep -q 'decision'
printf '%s' "$without_jq" | grep -Fq "$PWD/rules/professional-disclaimer.md"

bad_payload=$(printf '%s' '{not-json' | PATH="$fake_bin" CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
printf '%s' "$bad_payload" | grep -q 'decision'
printf '%s' "$bad_payload" | grep -q 'stopped safely'

hook="$PWD/hooks/pre-commit-spec-lint.sh"
repo="$root/repo with space"
mkdir -p "$repo"
(
  cd "$repo"
  git init -q
  printf 'CSI section 092900 is malformed\n' > 'quoted "spec" \file.md'
  git add 'quoted "spec" \file.md'
)
command_text='printf "quoted value" \\ path
git commit -m "spec check"'
command_payload=$(COMMAND_TEXT="$command_text" python3 -c 'import json,os; print(json.dumps({"tool_input":{"command":os.environ["COMMAND_TEXT"]}}))')
set +e
command_error=$(cd "$repo" && printf '%s' "$command_payload" | PATH="$fake_bin" CLAUDE_PLUGIN_ROOT="$PWD" bash "$hook" 2>&1)
command_status=$?
set -e
[ "$command_status" -eq 2 ]
printf '%s' "$command_error" | grep -q 'CSI formatting issues found'

set +e
decode_error=$(printf '%s' '{not-json' | PATH="$fake_bin" CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/pre-commit-spec-lint.sh 2>&1)
decode_status=$?
set -e
[ "$decode_status" -eq 2 ]
printf '%s' "$decode_error" | grep -q 'stopped safely'

echo "✓ enforcement hooks keep plugin-root guidance and remain active without jq"
