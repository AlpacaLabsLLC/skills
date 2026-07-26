#!/usr/bin/env bash
# Architecture Studio repo lint — flat single-plugin layout.
#
# Layout assumptions (flat-plugin structure):
#   skills/<name>/SKILL.md + README.md   — all skills, flat, one dir each
#   agents/<name>.md                     — native subagents (documentation lives outside this directory)
#   hooks/<name>.sh + hooks/hooks.json   — event-driven automations
#   .claude-plugin/plugin.json           — the one plugin manifest
#   .claude-plugin/marketplace.json      — single-entry marketplace, source "./"
#
# Inventory is derived from the tree — never hardcoded here. Runs the full set
# of structural checks and exits non-zero if any fail.
#
# Locally, missing optional tools (shellcheck, jq, PyYAML) downgrade their
# checks to a warning. In CI (CI=true) a missing tool fails the run hard —
# CI is the one place these checks are guaranteed, so they must never
# silently stop running there (ALPA-366).

set -uo pipefail

cd "$(dirname "$0")/.." || exit 1

FAIL=0
fail_check() { echo "  ✗ $1"; FAIL=1; }
pass_check() { echo "  ✓ $1"; }

# Warn-and-skip locally; hard-fail in CI.
skip_or_fail() {
  if [ "${CI:-}" = "true" ]; then
    fail_check "$1 not installed — required in CI (install step missing from lint.yml?)"
  else
    echo "  ! $1 not installed; skipping locally — CI enforces this check"
  fi
}

if ! command -v python3 >/dev/null 2>&1; then
  echo "✗ python3 is required to run this lint" >&2
  exit 1
fi

# 1. No .DS_Store tracked
echo "→ no .DS_Store tracked"
DSSTORE=$(git ls-files | grep '\.DS_Store$' || true)
if [ -n "$DSSTORE" ]; then
  fail_check "tracked .DS_Store files:"
  echo "$DSSTORE" | awk '{ print "      " $0 }'
else
  pass_check "none"
fi

# 2. JSON validity
echo "→ JSON validity"
if command -v jq >/dev/null 2>&1; then
  JSON_BAD=0
  JSON_TOTAL=0
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    JSON_TOTAL=$((JSON_TOTAL + 1))
    if ! jq empty "$f" >/dev/null 2>&1; then
      fail_check "invalid JSON: $f"
      JSON_BAD=$((JSON_BAD + 1))
    fi
  done <<< "$(git ls-files --cached --others --exclude-standard -- '*.json')"
  [ "$JSON_BAD" -eq 0 ] && pass_check "$JSON_TOTAL files"
else
  skip_or_fail "jq"
fi

# 3. SKILL.md frontmatter
echo "→ SKILL.md frontmatter"
python3 - <<'PYEOF'
import os, re, sys, pathlib, subprocess
try:
    import yaml
except ImportError:
    if os.environ.get('CI') == 'true':
        print("  ✗ PyYAML not installed — required in CI (install step missing from lint.yml?)")
        sys.exit(1)
    yaml = None
    print("  ! PyYAML not installed; using structural frontmatter checks locally — CI enforces full YAML parsing")

files = subprocess.check_output([
    'git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', '*SKILL.md'
]).decode().splitlines()
files = [f for f in files if pathlib.Path(f).is_file()]
errors = 0
for f in files:
    text = pathlib.Path(f).read_text()
    if not text.startswith('---\n'):
        print(f"  ✗ {f}: missing frontmatter delimiter")
        errors += 1
        continue
    end = text.find('\n---\n', 4)
    if end < 0:
        print(f"  ✗ {f}: unterminated frontmatter")
        errors += 1
        continue
    frontmatter = text[4:end]
    if yaml is not None:
        try:
            meta = yaml.safe_load(frontmatter)
        except Exception as e:
            print(f"  ✗ {f}: YAML parse error: {e}")
            errors += 1
            continue
    else:
        meta = {}
        for line in frontmatter.splitlines():
            match = re.match(r'^([A-Za-z0-9_-]+):(?:\s*(.*))?$', line)
            if match:
                meta[match.group(1)] = match.group(2)
    if not isinstance(meta, dict):
        print(f"  ✗ {f}: frontmatter is not a mapping")
        errors += 1
        continue
    for key in ('name', 'description'):
        if key not in meta:
            print(f"  ✗ {f}: missing required key '{key}'")
            errors += 1
if errors:
    sys.exit(1)
suffix = " (structural fallback)" if yaml is None else ""
print(f"  ✓ {len(files)} files{suffix}")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 4. Skill directory completeness
echo "→ skill directory completeness"
python3 - <<'PYEOF'
import sys, pathlib
errors = 0
skills = sorted(p for p in pathlib.Path('skills').iterdir()
                if p.is_dir() and not p.name.startswith('.'))
for s in skills:
    for required in ('SKILL.md', 'README.md'):
        if not (s / required).is_file():
            print(f"  ✗ {s}: missing {required}")
            errors += 1
if errors:
    sys.exit(1)
print(f"  ✓ {len(skills)} skill dirs, each with SKILL.md + README.md")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 5. Count consistency (derived from tree; a regex that matches nothing is a
#    FAILURE, not a silent pass — ALPA-365 #4)
echo "→ count consistency"
python3 - <<'PYEOF'
import sys, re, json, pathlib

errors = []

skill_dirs = sorted(p.name for p in pathlib.Path('skills').iterdir()
                    if p.is_dir() and not p.name.startswith('.'))
skill_count = len(skill_dirs)
agent_count = sum(1 for p in pathlib.Path('agents').glob('*.md')
                  if p.name != 'README.md')
rule_count = sum(1 for p in pathlib.Path('rules').glob('*.md')
                 if p.name != 'README.md')
hook_count = len(list(pathlib.Path('hooks').glob('*.sh')))

readme = pathlib.Path('README.md').read_text()
skill_catalog = pathlib.Path('skills/README.md').read_text()
plugin_namespace = 'as'

# Every maintained numeric claim in the root README must match the tree. Skill
# inventory is represented by catalog coverage instead of an aggregate count.
for label, actual in (('agents', agent_count), ('rules', rule_count),
                      ('hooks', hook_count)):
    claims = re.findall(rf'\b(\d+) {label}\b', readme)
    if not claims:
        errors.append(f"README never states a '{label}' count (expected {actual})")
    for c in claims:
        if int(c) != actual:
            errors.append(f"README claims {c} {label}, actual {actual}")

# Skill catalog rows: [`/name`](./dir) or the Claude plugin form
# [`/plugin:name`](./dir). Every skill dir needs exactly one row.
rows = re.findall(r'\[`/([a-z0-9-]+(?::[a-z0-9-]+)?)`\]\(\./([a-z0-9-]+)\)', skill_catalog)
if not rows:
    errors.append("skills/README.md catalog regex matched no rows — table missing or reformatted")
else:
    linked = [d for _, d in rows]
    for slash, d in rows:
        parts = slash.split(':', 1)
        command = parts[-1]
        if len(parts) == 2 and parts[0] != plugin_namespace:
            errors.append(f"skills/README.md row `/{slash}` uses namespace {parts[0]}, expected {plugin_namespace}")
        if command != d:
            errors.append(f"skills/README.md row `/{slash}` links to ./{d} — slash name must equal dir name")
        if d not in skill_dirs:
            errors.append(f"skills/README.md row `/{slash}` points to missing dir skills/{d}")
    for d in skill_dirs:
        if d not in linked:
            errors.append(f"skills/{d} has no row in skills/README.md")
    for d in sorted(set(x for x in linked if linked.count(x) > 1)):
        errors.append(f"skills/{d} appears {linked.count(d)} times in skills/README.md")

# Tool catalog headline. Catalog membership is checked above; do not maintain
# an aggregate skill count in prose.
menu = pathlib.Path('skills/tool-catalog/SKILL.md').read_text()
if '**Architecture Studio tools and' not in menu:
    errors.append("skills/tool-catalog/SKILL.md missing Architecture Studio tools headline")

# Root plugin.json + single-entry marketplace.json.
plugin = json.loads(pathlib.Path('.claude-plugin/plugin.json').read_text())
mp = json.loads(pathlib.Path('.claude-plugin/marketplace.json').read_text())

for key in ('name', 'version', 'description'):
    if not plugin.get(key):
        errors.append(f"plugin.json missing '{key}'")
if not re.fullmatch(r'\d+\.\d+\.\d+', plugin.get('version', '')):
    errors.append(f"plugin.json version '{plugin.get('version')}' is not X.Y.Z")
if not mp.get('metadata', {}).get('version'):
    errors.append("marketplace.json missing metadata.version")
elif mp['metadata']['version'] != plugin.get('version'):
    errors.append(f"marketplace.json version {mp['metadata']['version']} != "
                  f"plugin.json version {plugin.get('version')}")

entries = mp.get('plugins', [])
if len(entries) != 1:
    errors.append(f"marketplace.json must list exactly 1 plugin (flat layout), found {len(entries)}")
else:
    entry = entries[0]
    if entry.get('name') != plugin.get('name'):
        errors.append(f"marketplace entry name '{entry.get('name')}' != plugin.json name '{plugin.get('name')}'")
    if entry.get('source') != './':
        errors.append(f"marketplace entry source must be './', found '{entry.get('source')}'")

if errors:
    for e in errors:
        print(f"  ✗ {e}")
    sys.exit(1)
print(f"  ✓ skill catalog covers all {skill_count} directories; maintained agent, "
      f"rule, and hook counts are consistent")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 6. Internal markdown links
echo "→ internal markdown links"
python3 - <<'PYEOF'
import sys, re, pathlib, subprocess
md_files = subprocess.check_output([
    'git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', '*.md'
]).decode().splitlines()
md_files = [f for f in md_files if pathlib.Path(f).is_file()]
link_re = re.compile(r'\]\((?!https?://|mailto:|#)([^)\s]+)(?:\s+"[^"]*")?\)')
errors = 0
for f in md_files:
    p = pathlib.Path(f)
    text = p.read_text()
    base = p.parent
    for m in link_re.finditer(text):
        target = m.group(1).split('#')[0]
        if not target:
            continue
        if f == 'skills/project/templates/PROJECT.md' and target in {
            'decisions/', 'meetings/', 'site-reports/', 'docs/plans/',
            'TASKS.md', 'TIMELOG.md'
        }:
            # These links are relative to the rendered project root, not the
            # bundled template's source directory.
            continue
        resolved = (base / target).resolve()
        if not resolved.exists():
            print(f"  ✗ {f}: broken link → {target}")
            errors += 1
if errors:
    sys.exit(1)
print(f"  ✓ {len(md_files)} markdown files scanned")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 7. No ~/ data paths in SKILL.md bodies (regression guard, ALPA-365 #1:
#    skills once hardcoded ~/Documents and ~/.claude paths that broke on
#    other machines). skills/learn is exempt — it TEACHES where personal
#    skills live (~/.claude/skills), which is instructional content, not a
#    data path the skill reads or writes.
echo "→ no ~/ paths in SKILL.md bodies"
TILDE_HITS=$(grep -n -e '[~]/\.claude' -e '[~]/Documents' skills/*/SKILL.md 2>/dev/null | grep -v '^skills/learn/' || true)
if [ -n "$TILDE_HITS" ]; then
  fail_check "tilde (~/) paths found in SKILL.md bodies:"
  echo "$TILDE_HITS" | awk '{ print "      " $0 }'
else
  pass_check "none (skills/learn exempt by design)"
fi

# 8. Slash-command resolution (regression guard, ALPA-365 #2: docs referenced
#    /architect, /history and skills-menu after renames). Every backticked
#    /name in a README.md, SKILL.md, or agents/*.md must resolve to a real
#    skills/<name>/ dir. skills/learn is exempt — it references skills the
#    learner builds in the sandbox (/minutes, /tasklist, ...) plus Claude Code
#    built-ins, none of which ship in this repo.
echo "→ slash-command resolution"
python3 - <<'PYEOF'
import sys, re, pathlib, subprocess

# Claude Code built-in commands that legitimately appear in our docs.
BUILTINS = {'hooks', 'plugin', 'config', 'clear', 'help', 'mcp', 'init', 'agents'}

files = [f for f in subprocess.check_output([
             'git', 'ls-files', '--cached', '--others', '--exclude-standard'
         ]).decode().splitlines()
         if f and pathlib.Path(f).is_file() and not f.startswith('skills/learn/')
         and (f.endswith('/README.md') or f == 'README.md'
              or f.endswith('SKILL.md') or re.fullmatch(r'agents/[^/]+\.md', f))]
skill_dirs = {p.name for p in pathlib.Path('skills').iterdir() if p.is_dir()}
plugin_namespace = 'as'
# Do not backtrack `/as:<skill>` into a bare `/as` command. Angle-bracket
# placeholders are documentation syntax, not invocable command names.
slash_re = re.compile(
    r'`/([a-z][a-z0-9-]*)(?::([a-z][a-z0-9-]*))?(?![:a-z0-9-])'
)
errors = 0
for f in files:
    text = pathlib.Path(f).read_text()
    for i, line in enumerate(text.split('\n'), 1):
        for m in slash_re.finditer(line):
            namespace, command = m.groups()
            name = command or namespace
            if command and namespace != plugin_namespace:
                print(f"  ✗ {f}:{i}: `/{namespace}:{command}` uses namespace {namespace}, expected {plugin_namespace}")
                errors += 1
                continue
            if name in skill_dirs or name in BUILTINS:
                continue
            print(f"  ✗ {f}:{i}: `/{name}` does not resolve to skills/{name}/")
            errors += 1
if errors:
    sys.exit(1)
print(f"  ✓ {len(files)} docs scanned, all slash commands resolve")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 9. Public plugin namespace, install identity, and state compatibility.
echo "→ plugin namespace contract"
if python3 scripts/check-plugin-namespace.py .; then
  :
else
  FAIL=1
fi

# 10. Disclaimer marker instruction in regulatory skills (regression guard,
#    ALPA-365 #3: the disclaimer pipeline is marker-driven — a regulatory
#    skill that never emits the marker silently escapes the hook). This list
#    mirrors the skills wired in the disclaimer-pipeline issue (ALPA-361);
#    grow it when a new regulatory skill ships.
echo "→ disclaimer marker in regulatory skills"
REGULATORY_SKILLS="
nyc-landmarks
nyc-dob-permits
nyc-dob-violations
nyc-acris
nyc-hpd
nyc-bsa
nyc-property-report
zoning-analysis-nyc
zoning-envelope
occupancy-calculator
epd-to-spec
site-visit-report
"
MARKER='architecture-studio:requires-disclaimer'
MARKER_MISSING=0
MARKER_TOTAL=0
while IFS= read -r s; do
  [ -z "$s" ] && continue
  MARKER_TOTAL=$((MARKER_TOTAL + 1))
  if [ ! -f "skills/$s/SKILL.md" ]; then
    fail_check "regulatory skill skills/$s/SKILL.md not found (stale list in lint.sh?)"
    MARKER_MISSING=$((MARKER_MISSING + 1))
  elif ! grep -q "$MARKER" "skills/$s/SKILL.md"; then
    fail_check "skills/$s/SKILL.md missing '$MARKER' marker instruction"
    MARKER_MISSING=$((MARKER_MISSING + 1))
  fi
done <<< "$REGULATORY_SKILLS"
[ "$MARKER_MISSING" -eq 0 ] && pass_check "$MARKER_TOTAL regulatory skills carry the marker"

# 11. Referenced-file existence (regression guard, ALPA-365 #5: SKILL.md
#     bodies referenced support files that had been moved or deleted). Checks
#     backticked relative paths whose first segment is a real directory next
#     to the skill (or at repo root) — output-file templates (./report.md,
#     [slug] placeholders) are not existence claims and are skipped.
echo "→ referenced files exist"
python3 - <<'PYEOF'
import sys, re, pathlib, subprocess
files = subprocess.check_output([
    'git', 'ls-files', '--cached', '--others', '--exclude-standard', '--',
    'skills/*/SKILL.md'
]).decode().splitlines()
files = [f for f in files if pathlib.Path(f).is_file()]
tok_re = re.compile(r'`([^`\s]+)`')
root = pathlib.Path('.')
errors = 0
checked = 0
runtime_outputs = {
    'docs/plans/',
}
for f in files:
    skill_dir = pathlib.Path(f).parent
    text = pathlib.Path(f).read_text()
    for m in tok_re.finditer(text):
        t = m.group(1)
        if t in runtime_outputs:
            # Workplan creates this project-local destination at runtime. It is
            # deliberately not bundled in the flat plugin package.
            continue
        if t.startswith('${CLAUDE_PLUGIN_ROOT}/'):
            rel = t[len('${CLAUDE_PLUGIN_ROOT}/'):]
            checked += 1
            if not (root / rel).exists():
                print(f"  ✗ {f}: references missing file {t}")
                errors += 1
            continue
        # Placeholders and non-path tokens are not existence claims.
        if '/' not in t or t.startswith(('/', '~', '.', 'http', '#')):
            continue
        if any(c in t for c in '[]*{}(') or 'YYYY' in t:
            continue
        first = t.split('/')[0]
        for base in (skill_dir, root):
            if (base / first).is_dir():
                checked += 1
                if not (base / t.rstrip('/')).exists():
                    print(f"  ✗ {f}: references missing file {t}")
                    errors += 1
                break
if errors:
    sys.exit(1)
print(f"  ✓ {checked} referenced paths exist")
PYEOF
RC=$?
[ "$RC" -ne 0 ] && FAIL=1

# 12. Active-surface product-data boundary. Planning artifacts and historical
#     release notes describe removed/deferred behavior and are intentionally
#     outside this guard.
echo "→ active product-data boundary"
ACTIVE_PRODUCT_PATHS=(
  agents
  README.md
  PATTERNS.md
  schema
  skills
)
GOOGLE_PRODUCT_HITS=$(grep -RInE \
  'mcp__google-sheets|sheet-conventions\.md|Google Sheets? (destination|setup|template|tab|range)|Google (Sheet|spreadsheet) ID|spreadsheet ID|sheet ID' \
  "${ACTIVE_PRODUCT_PATHS[@]}" \
  --include='*.md' --include='*.json' --include='*.sh' \
  --exclude-dir=learn --exclude-dir=sandbox 2>/dev/null || true)
if [ -n "$GOOGLE_PRODUCT_HITS" ]; then
  fail_check "retired Google Sheets product workflow found in an active surface:"
  echo "$GOOGLE_PRODUCT_HITS" | awk '{ print "      " $0 }'
else
  pass_check "no retired Google Sheets product workflow"
fi

PRODUCT_DIRS=(
  skills/master-schedule
  skills/product-data-cleanup
  skills/product-data-import
  skills/product-enrich
  skills/product-image-processor
  skills/product-match
  skills/product-pair
  skills/product-research
  skills/product-spec-bulk-fetch
  skills/product-spec-pdf-parser
  skills/epd-compare
  skills/epd-parser
  skills/epd-research
  skills/epd-to-spec
)
XLS_HITS=$(grep -RInEi '\.(xls|xlsx)\b|\b(xls|xlsx) (import|export|parser|support|sync)' \
  "${PRODUCT_DIRS[@]}" --include='*.md' --include='*.json' --include='*.sh' 2>/dev/null || true)
if [ -n "$XLS_HITS" ]; then
  fail_check "XLS/XLSX support found in an active product workflow:"
  echo "$XLS_HITS" | awk '{ print "      " $0 }'
else
  pass_check "no XLS/XLSX product support"
fi

# 13. Shellcheck every repository shell script, including nested helpers.
echo "→ shellcheck on repository shell scripts"
if command -v shellcheck >/dev/null 2>&1; then
  SHELL_FILES=()
  while IFS= read -r shell_file; do
    SHELL_FILES+=("$shell_file")
  done < <(find hooks scripts skills tests -type f -name '*.sh' | sort)
  # Warning-and-error findings are release blockers. Test-contract scripts use
  # literal shell-looking fixture text and deliberate negative pipelines, which
  # produce informational findings without identifying executable defects.
  if shellcheck --severity=warning "${SHELL_FILES[@]}"; then
    pass_check "${#SHELL_FILES[@]} scripts"
  else
    fail_check "shellcheck issues"
  fi
else
  skip_or_fail "shellcheck"
fi

echo
if [ "$FAIL" -ne 0 ]; then
  echo "lint failed"
  exit 1
fi
echo "all checks passed"
