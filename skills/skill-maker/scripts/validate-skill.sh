#!/usr/bin/env bash
set -euo pipefail

target=${1:-}
[ -n "$target" ] || { echo "usage: validate-skill.sh <skill-directory>" >&2; exit 2; }
[ -d "$target" ] || { echo "skill directory not found: $target" >&2; exit 1; }
[ -f "$target/SKILL.md" ] || { echo "missing SKILL.md: $target" >&2; exit 1; }
[ -f "$target/README.md" ] || { echo "missing README.md: $target" >&2; exit 1; }

directory=$(basename -- "$target")
case "$directory" in
  ''|*[!a-z0-9-]*|-*|*-) echo "skill directory must be lowercase kebab-case: $directory" >&2; exit 1 ;;
esac

name=$(sed -n 's/^name:[[:space:]]*//p' "$target/SKILL.md" | head -1)
description=$(sed -n 's/^description:[[:space:]]*//p' "$target/SKILL.md" | head -1)
[ "$name" = "$directory" ] || { echo "frontmatter name '$name' must match directory '$directory'" >&2; exit 1; }
[ -n "$description" ] || { echo "frontmatter description is required" >&2; exit 1; }
grep -q '^---$' "$target/SKILL.md" || { echo "SKILL.md requires YAML frontmatter" >&2; exit 1; }
# shellcheck disable=SC2088 # This is the literal shortcut the generated file must reject.
home_shortcut_pattern='~/'
if rg -n --fixed-strings "$home_shortcut_pattern" "$target/SKILL.md"; then
  echo "SKILL.md must not contain ~/ paths" >&2
  exit 1
fi

printf 'valid skill scaffold: %s\n' "$target"
