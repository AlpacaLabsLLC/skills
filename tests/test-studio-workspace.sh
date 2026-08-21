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
[ -f "$STUDIO/AGENTS.md" ]
[ -f "$STUDIO/.mcp.json" ]
[ -d "$STUDIO/.claude/skills" ]
[ -d "$STUDIO/.agents/skills" ]
[ -d "$STUDIO/standards" ]
[ -d "$STUDIO/references" ]
[ -f "$STUDIO/standards/README.md" ]
[ -f "$STUDIO/references/README.md" ]
[ -d "$STUDIO/projects" ]
[ ! -e "$STUDIO/templates" ]
node -e 'const fs=require("fs"); const v=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); if (Object.keys(v).length!==1 || typeof v.mcpServers!=="object" || v.mcpServers===null || Array.isArray(v.mcpServers) || Object.keys(v.mcpServers).length!==0) process.exit(1)' "$STUDIO/.mcp.json"
grep -Fq '| Working units | imperial |' "$STUDIO/STUDIO.md"
grep -Fq '| Country | United States |' "$STUDIO/STUDIO.md"
grep -Fq '| State / region | New York |' "$STUDIO/STUDIO.md"
grep -Fq '| City | New York City |' "$STUDIO/STUDIO.md"
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
grep -Fq '| Format version | 3 |' "$STUDIO/STUDIO.md"
grep -Fq '| Project ID | Project | Client | Code | Type | Status | Folder | Opened |' "$STUDIO/STUDIO.md"
grep -Fq 'does not send them to or store them with ALPA' "$STUDIO/STUDIO.md"
grep -Fq 'The studio skill is the only writer of this registry.' "$STUDIO/STUDIO.md"
grep -Fq 'Firm-wide standards and reusable templates: `standards/`' "$STUDIO/STUDIO.md"
grep -Fq 'External references, including code references: `references/`' "$STUDIO/STUDIO.md"
if grep -Fq '/as:' "$STUDIO/STUDIO.md"; then
  echo "generated studio record contains a host-specific slash command" >&2
  exit 1
fi
grep -Fq 'Firm-created Codex skills live in `.agents/skills/`.' "$STUDIO/AGENTS.md"
grep -Fq 'Firm-wide standards and reusable templates live in `standards/`.' "$STUDIO/AGENTS.md"
grep -Fq 'External references, including code references, live in `references/`.' "$STUDIO/AGENTS.md"
grep -Fq 'Project work and project outputs stay inside `projects/`.' "$STUDIO/AGENTS.md"
grep -Fq 'Firm-wide standards and reusable templates belong here.' "$STUDIO/standards/README.md"
grep -Fq 'External source material, including code references, belongs here.' "$STUDIO/references/README.md"

# Writers reject a symlinked studio root.
SYMLINK_STUDIO="$ROOT/linked/smith-architects"
mkdir -p "$ROOT/linked"
ln -s "$STUDIO" "$SYMLINK_STUDIO"
if "$SCRIPT" task-mode "$SYMLINK_STUDIO" portfolio; then
  echo "symlinked studio root unexpectedly accepted" >&2
  exit 1
fi
grep -Fq '| Task register | project |' "$STUDIO/STUDIO.md"
[ ! -e "$STUDIO/TASKS.md" ]

# Writers reject a symlinked studio-owned projects directory.
PROJECTS_LINK_STUDIO="$ROOT/projects-link-studio"
PROJECTS_LINK_TARGET="$ROOT/external-projects"
"$SCRIPT" init "$PROJECTS_LINK_STUDIO" "Projects Link Studio" metric US NY NYC >/dev/null
rmdir "$PROJECTS_LINK_STUDIO/projects"
mkdir -p "$PROJECTS_LINK_TARGET"
ln -s "$PROJECTS_LINK_TARGET" "$PROJECTS_LINK_STUDIO/projects"
if "$SCRIPT" task-mode "$PROJECTS_LINK_STUDIO" portfolio; then
  echo "symlinked studio projects directory unexpectedly accepted" >&2
  exit 1
fi
grep -Fq '| Task register | project |' "$PROJECTS_LINK_STUDIO/STUDIO.md"

cp "$STUDIO/STUDIO.md" "$ROOT/studio-v3.md"
sed '/| Format version | 3 |/d' "$ROOT/studio-v3.md" > "$STUDIO/STUDIO.md"
if "$SCRIPT" status "$STUDIO"; then echo "unversioned studio unexpectedly accepted" >&2; exit 1; fi
sed 's/| Format version | 3 |/| Format version | 99 |/' "$ROOT/studio-v3.md" > "$STUDIO/STUDIO.md"
if "$SCRIPT" status "$STUDIO"; then echo "unknown studio version unexpectedly accepted" >&2; exit 1; fi
cp "$ROOT/studio-v3.md" "$STUDIO/STUDIO.md"

PROJECT_ID=2026-08-SMI-MUSEUM-EXPANSION
PROJECT="$STUDIO/projects/$PROJECT_ID"
skills/project/scripts/project-workspace.sh init "$PROJECT" "Museum Expansion" "$PROJECT_ID" client active SMI "Smith Institution" >/dev/null

printf '\n| Project ID | Project | Folder | Status |\n|---|---|---|---|\n| %s | Decoy | projects/%s | archived |\n' "$PROJECT_ID" "$PROJECT_ID" >> "$STUDIO/STUDIO.md"
if "$SCRIPT" register "$STUDIO" 2026-08-SMI-WRONG-ID "Museum Expansion" "projects/$PROJECT_ID"; then
  echo "registration accepted an ID that disagrees with PROJECT.md" >&2
  exit 1
fi
if "$SCRIPT" register "$STUDIO" "$PROJECT_ID" "Wrong display name" "projects/$PROJECT_ID"; then
  echo "registration accepted a display name that disagrees with PROJECT.md" >&2
  exit 1
fi
"$SCRIPT" register "$STUDIO" "$PROJECT_ID" "Museum Expansion" "projects/$PROJECT_ID"
[ "$(grep -Fc "| $PROJECT_ID | Museum Expansion | Smith Institution | SMI | client | active | projects/$PROJECT_ID |" "$STUDIO/STUDIO.md")" -eq 1 ]
if "$SCRIPT" register "$STUDIO" "$PROJECT_ID" "Museum Expansion" "projects/$PROJECT_ID"; then
  echo "duplicate registration unexpectedly succeeded" >&2
  exit 1
fi

# Read-only status aggregates every identity drift instead of aborting through
# the stricter writer guard on the first mismatch.
cp "$PROJECT/PROJECT.md" "$ROOT/project-before-status-drift.md"
sed \
  -e 's/| Project ID | 2026-08-SMI-MUSEUM-EXPANSION |/| Project ID | 2026-08-SMI-DRIFTED-IDENTITY |/' \
  -e 's/| Project | Museum Expansion |/| Project | Drifted Display Name |/' \
  -e 's/| Client code | SMI |/| Client code | BAD |/' \
  -e 's/| Status | active |/| Status | on-hold |/' \
  "$ROOT/project-before-status-drift.md" > "$PROJECT/PROJECT.md"
cp "$STUDIO/STUDIO.md" "$ROOT/studio-before-status-audit.md"
STATUS_DRIFT=$($SCRIPT status "$STUDIO")
printf '%s\n' "$STATUS_DRIFT" | grep -Fq "identity mismatch: projects/$PROJECT_ID field=Project ID manifest=$PROJECT_ID project=2026-08-SMI-DRIFTED-IDENTITY"
printf '%s\n' "$STATUS_DRIFT" | grep -Fq "identity mismatch: projects/$PROJECT_ID field=Project manifest=Museum Expansion project=Drifted Display Name"
printf '%s\n' "$STATUS_DRIFT" | grep -Fq "identity mismatch: projects/$PROJECT_ID field=Code manifest=SMI project=BAD"
printf '%s\n' "$STATUS_DRIFT" | grep -Fq "identity mismatch: projects/$PROJECT_ID field=Status manifest=active project=on-hold"
printf '%s\n' "$STATUS_DRIFT" | grep -Fq "identity mismatch: projects/$PROJECT_ID field=Folder manifest=projects/$PROJECT_ID project=projects/2026-08-SMI-DRIFTED-IDENTITY"
printf '%s\n' "$STATUS_DRIFT" | grep -Fq $'status-summary\tregistered=1\tdrift=5\tinvalid=0\tunregistered=0'
cmp -s "$STUDIO/STUDIO.md" "$ROOT/studio-before-status-audit.md"
cp "$ROOT/project-before-status-drift.md" "$PROJECT/PROJECT.md"

cp skills/project/templates/TASKS.md "$PROJECT/TASKS.md"

mv "$PROJECT/TASKS.md" "$ROOT/project-tasks-real.md"
ln -s "$ROOT/project-tasks-real.md" "$PROJECT/TASKS.md"
if "$SCRIPT" task-mode "$STUDIO" portfolio; then echo "symlinked task register unexpectedly accepted" >&2; exit 1; fi
rm "$PROJECT/TASKS.md"
mv "$ROOT/project-tasks-real.md" "$PROJECT/TASKS.md"

OUTSIDE="$ROOT/outside"
mkdir -p "$OUTSIDE"
printf '# Project\n\n| Field | Value |\n|---|---|\n| Format version | 3 |\n' > "$OUTSIDE/PROJECT.md"
ln -s "$OUTSIDE" "$STUDIO/projects/escape-link"
if "$SCRIPT" register "$STUDIO" 2026-08-ESC-ESCAPE Escape projects/escape-link; then
  echo "symlinked external project unexpectedly registered" >&2
  exit 1
fi

cp "$STUDIO/STUDIO.md" "$ROOT/studio-before-unsafe.md"
awk '/<!-- projects:end -->/ {print "| 2026-08-ESC-ESCAPE | Escape | Escape Client | ESC | client | active | projects/../outside | 2026-07-22 |"} {print}' "$ROOT/studio-before-unsafe.md" > "$STUDIO/STUDIO.md"
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

printf '%s\n' "| T0001 | $PROJECT_ID | Existing portfolio task | Alex | — | open | 2026-07-22 | 2026-07-22 | — | — | conversation:2026-07-22#instruction-1 | — |" >> "$STUDIO/TASKS.md"
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

awk -F'|' '
  function trim(s){gsub(/^[ \t]+|[ \t]+$/, "", s); return s}
  /<!-- projects:start -->/ {inside=1; print; next}
  /<!-- projects:end -->/ {inside=0; print; next}
  inside && trim($2)=="Project ID" {print "| Folder | Status | Project | Project ID | Opened | Type | Code | Client |"; next}
  inside && trim($2)=="---" {print "|---|---|---|---|---|---|---|---|"; next}
  inside && /^\|/ {print "| " trim($8) " | " trim($7) " | " trim($3) " | " trim($2) " | " trim($9) " | " trim($6) " | " trim($5) " | " trim($4) " |"; next}
  {print}
' "$STUDIO/STUDIO.md" > "$STUDIO/STUDIO.reordered"
mv "$STUDIO/STUDIO.reordered" "$STUDIO/STUDIO.md"

for project_status in prospective active on-hold lost withdrawn completed archived; do
  "$SCRIPT" set-status "$STUDIO" "$PROJECT_ID" "$project_status"
  grep -Fq "| $PROJECT_ID | Museum Expansion | Smith Institution | SMI | client | $project_status | projects/$PROJECT_ID |" "$STUDIO/STUDIO.md"
  grep -Fq "| Status | $project_status | studio status update |" "$PROJECT/PROJECT.md"
done

# The legacy archive command remains a narrow alias for the general status mutation.
"$SCRIPT" set-status "$STUDIO" "$PROJECT_ID" active
"$SCRIPT" archive "$STUDIO" "$PROJECT_ID"
grep -Fq "| $PROJECT_ID | Museum Expansion | Smith Institution | SMI | client | archived | projects/$PROJECT_ID |" "$STUDIO/STUDIO.md"
grep -Fq '| Status | archived | studio status update |' "$PROJECT/PROJECT.md"

cp "$STUDIO/STUDIO.md" "$ROOT/status-studio-before.md"
cp "$PROJECT/PROJECT.md" "$ROOT/status-project-before.md"
if "$SCRIPT" set-status "$STUDIO" "$PROJECT_ID" invalid; then
  echo "invalid project status unexpectedly accepted" >&2
  exit 1
fi
cmp -s "$STUDIO/STUDIO.md" "$ROOT/status-studio-before.md"
cmp -s "$PROJECT/PROJECT.md" "$ROOT/status-project-before.md"

if ARCH_STUDIO_FAIL_AT=status-after-manifest "$SCRIPT" set-status "$STUDIO" "$PROJECT_ID" active; then
  echo "injected project status failure unexpectedly succeeded" >&2
  exit 1
fi
cmp -s "$STUDIO/STUDIO.md" "$ROOT/status-studio-before.md"
cmp -s "$PROJECT/PROJECT.md" "$ROOT/status-project-before.md"
if find "$STUDIO" -mindepth 1 -maxdepth 1 -type d -name '.project-status-transaction.*' -print | grep -q .; then
  echo "successful status rollback left a transaction snapshot" >&2
  exit 1
fi

# A failed restore is reported and keeps its snapshots for manual recovery.
set +e
status_restore_output=$(ARCH_STUDIO_FAIL_AT=status-after-manifest ARCH_STUDIO_FAIL_RESTORE_AT=status-project "$SCRIPT" set-status "$STUDIO" "$PROJECT_ID" active 2>&1)
status_restore_rc=$?
set -e
[ "$status_restore_rc" -ne 0 ] || { echo "injected status restore failure unexpectedly succeeded" >&2; exit 1; }
printf '%s\n' "$status_restore_output" | grep -Fq 'rollback restore failed: status-project'
printf '%s\n' "$status_restore_output" | grep -Fq 'rollback incomplete; transaction preserved:'
status_transaction=$(find "$STUDIO" -mindepth 1 -maxdepth 1 -type d -name '.project-status-transaction.*' -print)
[ "$(printf '%s\n' "$status_transaction" | sed '/^$/d' | wc -l | tr -d ' ')" -eq 1 ]
cmp -s "$status_transaction/STUDIO.md" "$ROOT/status-studio-before.md"
cmp -s "$status_transaction/PROJECT.md" "$ROOT/status-project-before.md"
grep -Fq $'status-project\t' "$status_transaction/ROLLBACK-FAILURES.tsv"
cp "$status_transaction/STUDIO.md" "$STUDIO/STUDIO.md"
cp "$status_transaction/PROJECT.md" "$PROJECT/PROJECT.md"
rm -rf "$status_transaction"

UNREGISTERED_ID=2026-08-NYC-LIBRARY
skills/project/scripts/project-workspace.sh init "$STUDIO/projects/$UNREGISTERED_ID" Library "$UNREGISTERED_ID" client prospective NYC "New York City" >/dev/null
STATUS=$("$SCRIPT" status "$STUDIO")
printf '%s' "$STATUS" | grep -q "unregistered: projects/$UNREGISTERED_ID"
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

# An injected task-mode failure must restore every distinct project snapshot.
COLLISION_STUDIO="$ROOT/collision-studio"
"$SCRIPT" init "$COLLISION_STUDIO" "Collision Studio" metric US NY NYC >/dev/null
for spec in '2026-08-ONE-ALPHA projects/2026-08-ONE-ALPHA' '2026-08-TWO-BETA projects/2026-08-TWO-BETA'; do
  id=${spec%% *}; path=${spec#* }
  code=$(printf '%s' "$id" | cut -d- -f3)
  skills/project/scripts/project-workspace.sh init "$COLLISION_STUDIO/$path" "$id" "$id" client active "$code" "$id Client" >/dev/null
  cp skills/project/templates/TASKS.md "$COLLISION_STUDIO/$path/TASKS.md"
  printf '<!-- %s -->\n' "$id" >> "$COLLISION_STUDIO/$path/TASKS.md"
  "$SCRIPT" register "$COLLISION_STUDIO" "$id" "$id" "$path" >/dev/null
done
ARCH_STUDIO_FAIL_AT=after-manifest "$SCRIPT" task-mode "$COLLISION_STUDIO" portfolio && exit 1
grep -Fq '<!-- 2026-08-ONE-ALPHA -->' "$COLLISION_STUDIO/projects/2026-08-ONE-ALPHA/TASKS.md"
grep -Fq '<!-- 2026-08-TWO-BETA -->' "$COLLISION_STUDIO/projects/2026-08-TWO-BETA/TASKS.md"

echo "✓ studio helper owns the section-bounded, header-keyed v3 project registry"
