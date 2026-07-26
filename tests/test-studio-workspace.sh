#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

SCRIPT="skills/studio/scripts/studio-workspace.sh"
[ -x "$SCRIPT" ] || { echo "missing executable studio helper" >&2; exit 1; }

ROOT=$(mktemp -d)
trap 'rm -rf "$ROOT"' EXIT

STUDIO="$ROOT/smith-architects"
"$SCRIPT" init "$STUDIO" "Smith Architects" "imperial" "United States" "New York" "New York City"
[ -f "$STUDIO/STUDIO.md" ]
[ -f "$STUDIO/CLAUDE.md" ]
[ -f "$STUDIO/.mcp.json" ]
[ -d "$STUDIO/.claude/skills" ]
[ -d "$STUDIO/projects" ]
node -e 'const fs=require("fs"); const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if (Object.keys(v).length!==1 || typeof v.mcpServers!=="object" || v.mcpServers===null || Array.isArray(v.mcpServers) || Object.keys(v.mcpServers).length!==0) process.exit(1)' "$STUDIO/.mcp.json"
grep -Fq '| Working units | imperial |' "$STUDIO/STUDIO.md"
grep -Fq '| Country | United States |' "$STUDIO/STUDIO.md"
grep -Fq '| State / region | New York |' "$STUDIO/STUDIO.md"
grep -Fq '| City | New York City |' "$STUDIO/STUDIO.md"
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
grep -Fq '| Format version | 2 |' "$STUDIO/STUDIO.md"
grep -Fq 'does not send them to or store them with ALPA' "$STUDIO/STUDIO.md"

cp "$STUDIO/STUDIO.md" "$ROOT/studio-v2.md"
sed '/| Format version | 2 |/d' "$ROOT/studio-v2.md" > "$STUDIO/STUDIO.md"
if "$SCRIPT" status "$STUDIO"; then echo "unversioned studio unexpectedly accepted" >&2; exit 1; fi
sed 's/| Format version | 2 |/| Format version | 99 |/' "$ROOT/studio-v2.md" > "$STUDIO/STUDIO.md"
if "$SCRIPT" status "$STUDIO"; then echo "unknown studio version unexpectedly accepted" >&2; exit 1; fi
cp "$ROOT/studio-v2.md" "$STUDIO/STUDIO.md"

PROJECT="$STUDIO/projects/2401-museum-expansion"
mkdir -p "$PROJECT"
printf '# Project — Museum Expansion\n\n| Field | Value |\n|---|---|\n| Format version | 2 |\n| Project ID | 2401 |\n| Project | Museum Expansion |\n' > "$PROJECT/PROJECT.md"

"$SCRIPT" register "$STUDIO" 2401 "Museum Expansion" "projects/2401-museum-expansion"
[ "$(grep -Fc '| 2401 | Museum Expansion | projects/2401-museum-expansion | active |' "$STUDIO/STUDIO.md")" -eq 1 ]
if "$SCRIPT" register "$STUDIO" 2401 "Museum Expansion" "projects/2401-museum-expansion"; then
  echo "duplicate registration unexpectedly succeeded" >&2
  exit 1
fi

cp skills/project/templates/TASKS.md "$PROJECT/TASKS.md"

mv "$PROJECT/TASKS.md" "$ROOT/project-tasks-real.md"
ln -s "$ROOT/project-tasks-real.md" "$PROJECT/TASKS.md"
if "$SCRIPT" task-mode "$STUDIO" portfolio; then echo "symlinked task register unexpectedly accepted" >&2; exit 1; fi
rm "$PROJECT/TASKS.md"
mv "$ROOT/project-tasks-real.md" "$PROJECT/TASKS.md"

OUTSIDE="$ROOT/outside"
mkdir -p "$OUTSIDE"
printf '# Project\n\n| Field | Value |\n|---|---|\n| Format version | 2 |\n' > "$OUTSIDE/PROJECT.md"
ln -s "$OUTSIDE" "$STUDIO/projects/escape-link"
if "$SCRIPT" register "$STUDIO" escape Escape projects/escape-link; then
  echo "symlinked external project unexpectedly registered" >&2
  exit 1
fi

cp "$STUDIO/STUDIO.md" "$ROOT/studio-before-unsafe.md"
awk '/<!-- projects:end -->/ {print "| escape | Escape | projects/../outside | active | 2026-07-22 |"} {print}' "$ROOT/studio-before-unsafe.md" > "$STUDIO/STUDIO.md"
if "$SCRIPT" task-mode "$STUDIO" portfolio; then
  echo "unsafe manifest path unexpectedly accepted for task transition" >&2
  exit 1
fi
[ -f "$PROJECT/TASKS.md" ]
[ ! -f "$STUDIO/TASKS.md" ]
cp "$ROOT/studio-before-unsafe.md" "$STUDIO/STUDIO.md"

ARCH_STUDIO_FAIL_AT=after-manifest "$SCRIPT" task-mode "$STUDIO" portfolio && exit 1
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
[ -f "$PROJECT/TASKS.md" ]
[ ! -f "$STUDIO/TASKS.md" ]

"$SCRIPT" task-mode "$STUDIO" portfolio
grep -Fq '| Task register | portfolio |' "$STUDIO/STUDIO.md"
[ -f "$STUDIO/TASKS.md" ]
[ ! -f "$PROJECT/TASKS.md" ]
grep -Fq '| ID | Project ID | Description |' "$STUDIO/TASKS.md"

if "$SCRIPT" task-mode "$STUDIO" portfolio; then
  echo "unchanged task mode unexpectedly rewrote workspace" >&2
  exit 1
fi

printf '%s\n' '| T0001 | 2401 | Existing portfolio task | Alex | — | open | 2026-07-22 | 2026-07-22 | — | — | conversation:2026-07-22#instruction-1 | — |' >> "$STUDIO/TASKS.md"
if "$SCRIPT" task-mode "$STUDIO" project; then
  echo "populated portfolio register unexpectedly split" >&2
  exit 1
fi
grep -Fq '| Task register | portfolio |' "$STUDIO/STUDIO.md"
[ -f "$STUDIO/TASKS.md" ]
cp skills/tasklist/templates/portfolio-tasks.md "$STUDIO/TASKS.md"

"$SCRIPT" task-mode "$STUDIO" project
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
[ ! -f "$STUDIO/TASKS.md" ]
[ -f "$PROJECT/TASKS.md" ]

printf '%s\n' '| T0001 | Existing project task | Alex | — | open | 2026-07-22 | 2026-07-22 | — | — | conversation:2026-07-22#instruction-1 | — |' >> "$PROJECT/TASKS.md"
if "$SCRIPT" task-mode "$STUDIO" portfolio; then
  echo "populated project register unexpectedly merged" >&2
  exit 1
fi
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
[ -f "$PROJECT/TASKS.md" ]
cp skills/project/templates/TASKS.md "$PROJECT/TASKS.md"

set +e
ARCH_STUDIO_FAIL_AT=signal-after-manifest "$SCRIPT" task-mode "$STUDIO" portfolio
signal_status=$?
set -e
[ "$signal_status" -eq 143 ] || { echo "TERM recovery returned $signal_status instead of 143" >&2; exit 1; }
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
[ -f "$PROJECT/TASKS.md" ]
[ ! -f "$STUDIO/TASKS.md" ]

"$SCRIPT" archive "$STUDIO" 2401
grep -Fq '| 2401 | Museum Expansion | projects/2401-museum-expansion | archived |' "$STUDIO/STUDIO.md"

mkdir -p "$STUDIO/projects/2402-library"
printf '# Project — Library\n\n| Field | Value |\n|---|---|\n| Format version | 2 |\n' > "$STUDIO/projects/2402-library/PROJECT.md"
STATUS=$("$SCRIPT" status "$STUDIO")
printf '%s' "$STATUS" | grep -q 'unregistered: projects/2402-library'
printf '%s' "$STATUS" | grep -q 'connectors: empty-reserved'
printf '%s' "$STATUS" | grep -q 'tasks: project'

rm "$STUDIO/.mcp.json"
STATUS=$("$SCRIPT" status "$STUDIO")
printf '%s' "$STATUS" | grep -q 'connectors: missing'

printf '{"mcpServers":{"configured":{}}}\n' > "$STUDIO/.mcp.json"
cp "$STUDIO/.mcp.json" "$ROOT/configured-before.json"
STATUS=$("$SCRIPT" status "$STUDIO")
printf '%s' "$STATUS" | grep -q 'connectors: configured'
cmp -s "$STUDIO/.mcp.json" "$ROOT/configured-before.json"

printf '{not-json\n' > "$STUDIO/.mcp.json"
cp "$STUDIO/.mcp.json" "$ROOT/invalid-before.json"
STATUS=$("$SCRIPT" status "$STUDIO")
printf '%s' "$STATUS" | grep -q 'connectors: invalid'
cmp -s "$STUDIO/.mcp.json" "$ROOT/invalid-before.json"

mkdir -p "$ROOT/collision"
printf 'keep\n' > "$ROOT/collision/existing.txt"
if "$SCRIPT" init "$ROOT/collision" "Collision" "metric" "No default" "No default" "No default"; then
  echo "non-empty collision unexpectedly succeeded" >&2
  exit 1
fi
[ "$(cat "$ROOT/collision/existing.txt")" = keep ]

if "$SCRIPT" init / "Unsafe" "metric" "No default" "No default" "No default"; then
  echo "root target unexpectedly accepted" >&2
  exit 1
fi

# These two valid paths collided under the retired slash-to-underscore backup
# name. An injected failure must restore each distinct snapshot.
COLLISION_STUDIO="$ROOT/collision-studio"
"$SCRIPT" init "$COLLISION_STUDIO" "Collision Studio" metric US NY NYC >/dev/null
mkdir -p "$COLLISION_STUDIO/projects/alpha_beta" "$COLLISION_STUDIO/projects/alpha/beta"
for spec in 'one projects/alpha_beta' 'two projects/alpha/beta'; do
  id=${spec%% *}; path=${spec#* }
  printf '# Project\n\n| Field | Value |\n|---|---|\n| Format version | 2 |\n| Project ID | %s |\n' "$id" > "$COLLISION_STUDIO/$path/PROJECT.md"
  cp skills/project/templates/TASKS.md "$COLLISION_STUDIO/$path/TASKS.md"
  printf '<!-- %s -->\n' "$id" >> "$COLLISION_STUDIO/$path/TASKS.md"
  "$SCRIPT" register "$COLLISION_STUDIO" "$id" "$id" "$path" >/dev/null
done
ARCH_STUDIO_FAIL_AT=after-manifest "$SCRIPT" task-mode "$COLLISION_STUDIO" portfolio && exit 1
grep -Fq '<!-- one -->' "$COLLISION_STUDIO/projects/alpha_beta/TASKS.md"
grep -Fq '<!-- two -->' "$COLLISION_STUDIO/projects/alpha/beta/TASKS.md"

echo "✓ studio helper creates configured workspaces, reports connector state read-only, registers, archives, and refuses collisions"
