#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
plugin_root=$PWD
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT

fail() {
  echo "$1" >&2
  exit 1
}

assert_status() {
  expected=$1
  label=$2
  [ "$run_status" -eq "$expected" ] || fail "$label: expected exit $expected, got $run_status"
}

assert_stdout_empty() {
  label=$1
  [ ! -s "$stdout_file" ] || fail "$label: unexpected stdout: $(cat "$stdout_file")"
}

assert_contains() {
  file=$1
  text=$2
  label=$3
  grep -Fq "$text" "$file" || fail "$label: expected '$text' in $(cat "$file")"
}

bash_bin=$(command -v bash)
cat_bin=$(command -v cat)
git_bin=$(command -v git)
grep_bin=$(command -v grep)
jq_bin=$(command -v jq || true)
python_bin=$(command -v python3)

make_path() {
  path_dir=$1
  shift
  mkdir -p "$path_dir"
  for tool in "$@"; do
    case "$tool" in
      bash) tool_path=$bash_bin ;;
      cat) tool_path=$cat_bin ;;
      git) tool_path=$git_bin ;;
      grep) tool_path=$grep_bin ;;
      jq) tool_path=$jq_bin ;;
      python3) tool_path=$python_bin ;;
      *) fail "unknown fake-PATH tool: $tool" ;;
    esac
    ln -s "$tool_path" "$path_dir/$tool"
  done
}

jq_path="$root/jq-only"
python_path="$root/python-only"
no_decoder_path="$root/no-decoder"
make_path "$python_path" bash cat git grep python3
make_path "$no_decoder_path" bash cat git grep

[ -x "$python_path/python3" ] && [ ! -e "$python_path/jq" ] || fail "Python-only PATH fixture is invalid"
[ ! -e "$no_decoder_path/jq" ] && [ ! -e "$no_decoder_path/python3" ] || fail "no-decoder PATH fixture is invalid"

decoder_cases=("python:$python_path")
if [ -n "$jq_bin" ]; then
  make_path "$jq_path" bash cat git grep jq
  [ -x "$jq_path/jq" ] && [ ! -e "$jq_path/python3" ] || fail "jq-only PATH fixture is invalid"
  decoder_cases=("jq:$jq_path" "${decoder_cases[@]}")
else
  echo "! jq not installed; skipping jq-only hook cases locally (CI enforces them)" >&2
fi

post_hook="$PWD/hooks/post-write-disclaimer-check.sh"
pre_hook="$PWD/hooks/pre-commit-spec-lint.sh"
stdout_file="$root/hook.stdout"
stderr_file="$root/hook.stderr"

run_post() {
  hook_path=$1
  hook_payload=$2
  : > "$stdout_file"
  : > "$stderr_file"
  set +e
  printf '%s' "$hook_payload" | PATH="$hook_path" CLAUDE_PLUGIN_ROOT="$plugin_root" "$bash_bin" "$post_hook" > "$stdout_file" 2> "$stderr_file"
  run_status=$?
  set -e
}

run_pre() {
  hook_path=$1
  hook_payload=$2
  hook_repo=$3
  : > "$stdout_file"
  : > "$stderr_file"
  set +e
  (
    cd "$hook_repo"
    printf '%s' "$hook_payload" | PATH="$hook_path" CLAUDE_PLUGIN_ROOT="$plugin_root" "$bash_bin" "$pre_hook"
  ) > "$stdout_file" 2> "$stderr_file"
  run_status=$?
  set -e
}

# PostToolUse: real findings still block with either supported decoder. The
# awkward path also proves decoding preserves spaces, quotes, slashes, and
# newlines instead of treating them as shell syntax.
regulatory_doc="$root/report with space \"quote\" \\slash
newline.md"
printf 'Regulatory output\n<!-- architecture-studio:requires-disclaimer -->\n' > "$regulatory_doc"
regulatory_payload=$(FILE_PATH="$regulatory_doc" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":os.environ["FILE_PATH"]}}))')

for decoder_case in "${decoder_cases[@]}"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_post "$hook_path" "$regulatory_payload"
  assert_status 0 "$decoder disclaimer finding"
  assert_contains "$stdout_file" '"decision"' "$decoder disclaimer finding"
  assert_contains "$stdout_file" 'block' "$decoder disclaimer finding"
  assert_contains "$stdout_file" "$PWD/rules/professional-disclaimer.md" "$decoder disclaimer finding"
done

# A real regulatory output carrying the canonical phrase remains silent.
compliant="$root/compliant-report.md"
printf 'FAR is 3.4.\n\nAI-generated analysis for preliminary planning purposes.\n\n<!-- architecture-studio:requires-disclaimer -->\n' > "$compliant"
compliant_payload=$(FILE_PATH="$compliant" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
for decoder_case in "${decoder_cases[@]}"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_post "$hook_path" "$compliant_payload"
  assert_status 0 "$decoder compliant disclaimer"
  assert_stdout_empty "$decoder compliant disclaimer"
done

# Ordinary Write and Edit operations are silent with jq only, Python only,
# or no decoder. With no decoder, the hook cannot establish a finding and
# therefore must fail open.
ordinary_doc="$root/ordinary-notes.md"
printf 'Ordinary project notes.\n' > "$ordinary_doc"
for tool_name in Write Edit; do
  ordinary_payload=$(TOOL_NAME="$tool_name" FILE_PATH="$ordinary_doc" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":os.environ["TOOL_NAME"],"tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
  for decoder_case in "${decoder_cases[@]}" "none:$no_decoder_path"; do
    decoder=${decoder_case%%:*}
    hook_path=${decoder_case#*:}
    run_post "$hook_path" "$ordinary_payload"
    assert_status 0 "$tool_name with $decoder decoder"
    assert_stdout_empty "$tool_name with $decoder decoder"
  done
done

# Malformed PostToolUse input is an infrastructure failure, not a confirmed
# disclaimer finding. It must emit no blocking JSON with any decoder profile.
for decoder_case in "${decoder_cases[@]}" "none:$no_decoder_path"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_post "$hook_path" '{not-json'
  assert_status 0 "malformed PostToolUse payload with $decoder decoder"
  assert_stdout_empty "malformed PostToolUse payload with $decoder decoder"

  for malformed_payload in '{}' '{"tool_input":{"file_path":42}}'; do
    run_post "$hook_path" "$malformed_payload"
    assert_status 0 "valid malformed PostToolUse payload with $decoder decoder"
    assert_stdout_empty "valid malformed PostToolUse payload with $decoder decoder"
  done
done

# Documenting the marker is not emitting it. Prose that cites the marker
# inline — inside backticks, mid-sentence — is not a regulatory output and
# must not be blocked. Substring matching blocked every edit to CHANGELOG.md,
# PATTERNS.md, hooks/README.md, rules/README.md, and skill-maker's SKILL.md.
documented="$root/documents-the-marker.md"
printf 'Use HTML comment markers (e.g. `<!-- architecture-studio:requires-disclaimer -->`) that skills emit.\n' > "$documented"
documented_payload=$(FILE_PATH="$documented" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
for decoder_case in "${decoder_cases[@]}"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_post "$hook_path" "$documented_payload"
  assert_status 0 "$decoder inline marker citation"
  assert_stdout_empty "$decoder inline marker citation"
done

# Every repository file that merely documents the convention stays silent.
for documented_file in CHANGELOG.md PATTERNS.md hooks/README.md rules/README.md skills/skill-maker/SKILL.md; do
  repo_payload=$(FILE_PATH="$PWD/$documented_file" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":os.environ["FILE_PATH"]}}))')
  run_post "$python_path" "$repo_payload"
  assert_status 0 "$documented_file marker documentation"
  assert_stdout_empty "$documented_file marker documentation"
done

# PreToolUse: ordinary Bash commands are never blocked, including when no
# decoder is available to classify the command.
repo="$root/repo with space"
mkdir -p "$repo"
(
  cd "$repo"
  "$git_bin" init -q
  printf 'CSI section 092900 is malformed\n' > 'quoted "spec" \file.md'
  "$git_bin" add 'quoted "spec" \file.md'
)

ordinary_command_payload=$("$python_bin" -c 'import json; print(json.dumps({"tool_name":"Bash","tool_input":{"command":"printf ordinary"}}))')
for decoder_case in "${decoder_cases[@]}" "none:$no_decoder_path"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_pre "$hook_path" "$ordinary_command_payload" "$repo"
  assert_status 0 "ordinary Bash with $decoder decoder"
done

# Malformed PreToolUse input likewise fails open. A stderr warning is allowed,
# but the exit status—not message text—is the enforcement contract.
for decoder_case in "${decoder_cases[@]}" "none:$no_decoder_path"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_pre "$hook_path" '{not-json' "$repo"
  assert_status 0 "malformed PreToolUse payload with $decoder decoder"

  for malformed_payload in '{}' '{"tool_input":{"command":42}}'; do
    run_pre "$hook_path" "$malformed_payload" "$repo"
    assert_status 0 "valid malformed PreToolUse payload with $decoder decoder"
  done
done

# Confirmed malformed CSI references remain blocking with jq-only and
# Python-only decoding, including compound commands and awkward file names.
command_text='printf "quoted value" \\ path
git commit -m "spec check"'
command_payload=$(COMMAND_TEXT="$command_text" "$python_bin" -c 'import json,os; print(json.dumps({"tool_name":"Bash","tool_input":{"command":os.environ["COMMAND_TEXT"]}}))')
for decoder_case in "${decoder_cases[@]}"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_pre "$hook_path" "$command_payload" "$repo"
  assert_status 2 "$decoder CSI finding"
  assert_contains "$stderr_file" 'CSI formatting issues found' "$decoder CSI finding"
  assert_contains "$stderr_file" "$PWD/rules/csi-formatting.md" "$decoder CSI finding"
done

# Without a decoder, even a commit-shaped payload cannot be inspected and must
# fail open rather than claiming that a policy violation was confirmed.
run_pre "$no_decoder_path" "$command_payload" "$repo"
assert_status 0 "commit payload with no decoder"

# A decoded commit with valid CSI formatting remains allowed.
printf 'CSI section 09 29 00 — Gypsum Board is valid\n' > "$repo/quoted \"spec\" \file.md"
(
  cd "$repo"
  "$git_bin" add 'quoted "spec" \file.md'
)
for decoder_case in "${decoder_cases[@]}"; do
  decoder=${decoder_case%%:*}
  hook_path=${decoder_case#*:}
  run_pre "$hook_path" "$command_payload" "$repo"
  assert_status 0 "$decoder valid CSI commit"
done

echo "✓ enforcement hooks fail open on decoder infrastructure errors and block confirmed findings"
