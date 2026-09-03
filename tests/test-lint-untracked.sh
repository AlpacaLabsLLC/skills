#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

PROBE_DIR="skills/skill-maker/.lint-untracked-probe"
PROBE="$PROBE_DIR/README.md"
SKILL_PROBE="skills/skill-maker/UNTRACKED-LINT-PROBE-SKILL.md"
EXAMPLE_PROBE="assets/UNTRACKED-LINT-PROBE-SKILL.example.md"
LOG=$(mktemp)
[ ! -e "$PROBE_DIR" ] || { echo "probe path already exists: $PROBE_DIR" >&2; exit 1; }
[ ! -e "$SKILL_PROBE" ] || { echo "probe path already exists: $SKILL_PROBE" >&2; exit 1; }
[ ! -e "$EXAMPLE_PROBE" ] || { echo "probe path already exists: $EXAMPLE_PROBE" >&2; exit 1; }
trap 'rm -rf "$PROBE_DIR"; rm -f "$SKILL_PROBE" "$EXAMPLE_PROBE" "$LOG"' EXIT

mkdir -p "$PROBE_DIR"
printf '[broken untracked link](./does-not-exist.md)\n' > "$PROBE"

if ./scripts/lint.sh >"$LOG" 2>&1; then
  echo "lint passed despite an untracked markdown file with a broken link" >&2
  exit 1
fi

grep -q '.lint-untracked-probe/README.md: broken link' "$LOG"

printf '`/definitely-not-a-real-skill`\n' > "$PROBE"
if ./scripts/lint.sh >"$LOG" 2>&1; then
  echo "lint passed despite an unresolved command in an untracked markdown file" >&2
  exit 1
fi
grep -q '.lint-untracked-probe/README.md:1: `/definitely-not-a-real-skill` does not resolve' "$LOG"

printf 'not frontmatter\n' > "$SKILL_PROBE"
if ./scripts/lint.sh >"$LOG" 2>&1; then
  echo "lint passed despite malformed frontmatter in an untracked SKILL.md" >&2
  exit 1
fi
grep -q 'UNTRACKED-LINT-PROBE-SKILL.md: missing frontmatter delimiter' "$LOG"

rm -f "$SKILL_PROBE"
printf 'not frontmatter\n' > "$EXAMPLE_PROBE"
if ./scripts/lint.sh >"$LOG" 2>&1; then
  echo "lint passed despite malformed frontmatter in an untracked SKILL.example.md" >&2
  exit 1
fi
grep -q 'UNTRACKED-LINT-PROBE-SKILL.example.md: missing frontmatter delimiter' "$LOG"

echo "✓ lint rejects broken links, commands, and available frontmatter checks in untracked files"
