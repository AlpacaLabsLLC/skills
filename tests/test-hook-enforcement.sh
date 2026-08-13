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

# Documenting the marker is not emitting it. Prose that cites the marker
# inline — inside backticks, mid-sentence — is not a regulatory output and
# must not be blocked. Substring matching blocked every edit to CHANGELOG.md,
# PATTERNS.md, hooks/README.md, rules/README.md, and skill-maker's SKILL.md.
documented="$root/documents-the-marker.md"
printf 'Use HTML comment markers (e.g. `<!-- architecture-studio:requires-disclaimer -->`) that skills emit.\n' > "$documented"
documented_payload=$(FILE_PATH="$documented" python3 -c 'import json,os; print(json.dumps({"tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
documented_out=$(printf '%s' "$documented_payload" | CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
[ -z "$documented_out" ] || { echo "inline marker citation must not block: $documented_out" >&2; exit 1; }

# Every repository file that merely documents the convention stays silent.
for documented_file in CHANGELOG.md PATTERNS.md hooks/README.md rules/README.md skills/skill-maker/SKILL.md; do
  repo_payload=$(FILE_PATH="$PWD/$documented_file" python3 -c 'import json,os; print(json.dumps({"tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
  repo_out=$(printf '%s' "$repo_payload" | CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
  [ -z "$repo_out" ] || { echo "$documented_file documents the marker and must not block: $repo_out" >&2; exit 1; }
done

# A real regulatory output still carries both, and still passes.
compliant="$root/compliant-report.md"
printf 'FAR is 3.4.\n\nAI-generated analysis for preliminary planning purposes.\n\n<!-- architecture-studio:requires-disclaimer -->\n' > "$compliant"
compliant_payload=$(FILE_PATH="$compliant" python3 -c 'import json,os; print(json.dumps({"tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
compliant_out=$(printf '%s' "$compliant_payload" | CLAUDE_PLUGIN_ROOT="$PWD" bash hooks/post-write-disclaimer-check.sh)
[ -z "$compliant_out" ] || { echo "compliant regulatory output must not block: $compliant_out" >&2; exit 1; }

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
