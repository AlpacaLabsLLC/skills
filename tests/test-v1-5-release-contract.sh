#!/usr/bin/env bash
set -euo pipefail
trap 'printf "release contract failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2' ERR

cd "$(dirname "$0")/.."

python3 - <<'PY'
import json
from pathlib import Path

plugin = json.loads(Path('.claude-plugin/plugin.json').read_text())
codex_plugin = json.loads(Path('.codex-plugin/plugin.json').read_text())
marketplace = json.loads(Path('.claude-plugin/marketplace.json').read_text())
assert plugin['version'] == '1.5.0'
assert codex_plugin['version'] == plugin['version']
assert marketplace['metadata']['version'] == plugin['version']
assert plugin['description'].startswith('Architecture Studio —')
assert marketplace['plugins'][0]['description'].startswith('Architecture Studio —')
PY

grep -q '^## \[Unreleased\]$' CHANGELOG.md
grep -q '^## \[1\.5\.0\] - 2026-08-28$' CHANGELOG.md
! grep -q '^## \[1\.4\.4\]' CHANGELOG.md
grep -q '^## \[1\.4\.3\] - 2026-08-13$' CHANGELOG.md
grep -q '^## \[1\.4\.2\] - 2026-08-10$' CHANGELOG.md
grep -q '^## \[1\.4\.1\] - 2026-07-29$' CHANGELOG.md
grep -q '^## \[1\.4\.0\] - 2026-07-26$' CHANGELOG.md
grep -q 'sequential `major.minor.patch` release scheme' CHANGELOG.md
grep -q '^\[Unreleased\]: .*compare/v1\.5\.0\.\.\.HEAD$' CHANGELOG.md
grep -q '^\[1\.5\.0\]: .*compare/v1\.4\.3\.\.\.v1\.5\.0$' CHANGELOG.md
! grep -q '^\[1\.4\.4\]:' CHANGELOG.md
grep -q '^\[1\.4\.3\]: .*releases/tag/v1\.4\.3$' CHANGELOG.md
grep -q '^\[1\.4\.2\]: .*releases/tag/v1\.4\.2$' CHANGELOG.md
grep -q '^\[1\.4\.1\]: .*releases/tag/v1\.4\.1$' CHANGELOG.md
grep -q '^\[1\.4\.0\]: .*releases/tag/v1\.4\.0$' CHANGELOG.md
grep -q 'product-library.csv' README.md
grep -q 'epd-library.csv' README.md
grep -q 'empty `mcpServers` object' README.md
grep -q 'user-exported CSV' PATTERNS.md
grep -q 'SIF is not a persistent schedule source' PATTERNS.md
grep -Fq '[operational release checklist](./docs/release-checklist.md)' PATTERNS.md
grep -Fq '[release checklist](./docs/release-checklist.md)' CONTRIBUTING.md
[ -f docs/release-checklist.md ]
grep -q '^# Architecture Studio Release Checklist$' docs/release-checklist.md
grep -q '^## Contribution-credit audit$' docs/release-checklist.md
grep -Fq 'original issue author' docs/release-checklist.md
grep -Fq 'reproduction or diagnosis' docs/release-checklist.md
grep -Fq 'confirmed a workaround' docs/release-checklist.md
grep -Fq 'Do not move, delete, or recreate a published tag' docs/release-checklist.md
grep -q '/as:master-schedule.*product-library.csv' skills/tool-catalog/SKILL.md
grep -q '/as:studio-feedback' skills/tool-catalog/SKILL.md
grep -q '/as:architecture-knowledge' skills/tool-catalog/SKILL.md
grep -Fq '[`/as:architecture-knowledge`](./architecture-knowledge)' skills/README.md
grep -q 'Background update checking is disabled by default' README.md
grep -q 'Opening the prefilled GitHub URL sends' README.md
grep -q '^### Three ways to use Architecture Studio$' README.md
grep -q 'No studio workspace is required' README.md
grep -qi 'install.*plugin' README.md
grep -q '/as:studio' README.md
grep -q '/as:tool-catalog' README.md
grep -q '/as:studio-feedback' README.md
grep -q 'as@skills-for-architects' README.md
grep -q '^### Upgrading to v1\.4\.0 (reinstall required)$' README.md
grep -q '/as:project migrate' README.md
grep -q 'welcome and update-check preferences remain in place' README.md
[ ! -e agents/README.md ]
[ "$(find agents -maxdepth 1 -type f -name '*.md' | wc -l | tr -d ' ')" = 7 ]
grep -Fq 'repository contains **5 hooks**' README.md
grep -Fq 'Codex loads one ambient `SessionStart` hook' README.md
grep -Fq '**One plugin**—`as` v1.5.0' README.md
grep -q '^## What.s new in 1\.5\.0$' README.md
! grep -q '^## What.s new in 1\.4\.4$' README.md
grep -qi 'format 2.*format 3.*breaking\|breaking.*format 2.*format 3' README.md
grep -q 'Version 1\.5\.0' README.md
grep -Fq '**Release governance.** Added a canonical release checklist' CHANGELOG.md
! rg -n '1\.4\.4|v1\.4\.4' .claude-plugin .codex-plugin README.md CHANGELOG.md docs/firm-deployment.md

python3 - <<'PY'
import re
import subprocess
from pathlib import Path, PurePosixPath

PROTECTED_PLANS = {
    "docs/plans/2026-08-19-001-feat-us-architecture-knowledge-plan.md",
    "docs/plans/commercial-records/design.md",
}
TEMPORARY_NAME = re.compile(
    r"(?:^|[-_. ])(?:draft|tmp|temp|copy|wip)(?:[-_. ]|$)|(?:^| )2$",
    re.IGNORECASE,
)


def metadata_from_frontmatter(text: str):
    lines = text.splitlines()
    if not lines or lines[0] != "---":
        return None
    try:
        end = lines.index("---", 1)
    except ValueError as exc:
        raise AssertionError("unterminated YAML frontmatter") from exc
    metadata: dict[str, str] = {}
    for line in lines[1:end]:
        if ":" in line and not line.startswith((" ", "\t")):
            key, value = line.split(":", 1)
            metadata[key.strip()] = value.strip()
    return metadata


def validate_plan(path: str, text: str) -> None:
    pure_path = PurePosixPath(path)
    assert pure_path.parts[:2] == ("docs", "plans"), f"plan is outside docs/plans: {path}"
    assert not TEMPORARY_NAME.search(pure_path.stem), f"temporary plan filename: {path}"
    assert text.startswith(("---\n", "# ")), f"plan lacks metadata or a title: {path}"

    metadata = metadata_from_frontmatter(text)
    if metadata is not None:
        assert metadata.get("artifact_contract") == "ce-unified-plan/v1", f"invalid plan contract: {path}"
        assert metadata.get("artifact_readiness") == "implementation-ready", f"unready unified plan: {path}"
        assert metadata.get("execution") in {"code", "knowledge-work"}, f"invalid execution mode: {path}"
        return

    assert re.search(r"^\*\*Status:\*\*\s*[^·\n]+\s*·\s*\*\*Target:\*\*\s*[^\n]+$", text, re.MULTILINE), (
        f"legacy design artifact lacks Status and Target metadata: {path}"
    )


tracked = subprocess.check_output(
    ["git", "ls-files", "--", ":(glob)docs/plans/**/*.md"], text=True
).splitlines()
assert PROTECTED_PLANS.issubset(tracked), "protected durable plans must remain tracked"
for plan_path in tracked:
    validate_plan(plan_path, Path(plan_path).read_text(encoding="utf-8"))

for bad_path, bad_text in (
    ("docs/plans/example-draft.md", "# Draft\n\n**Status:** proposed · **Target:** later\n"),
    (
        "docs/plans/unready.md",
        "---\nartifact_contract: ce-unified-plan/v1\nartifact_readiness: requirements-only\nexecution: code\n---\n\n# Unready\n",
    ),
):
    try:
        validate_plan(bad_path, bad_text)
    except AssertionError:
        pass
    else:
        raise AssertionError(f"release-plan validator accepted known unready artifact: {bad_path}")
PY

python3 - <<'PY'
from pathlib import Path

text = Path("CHANGELOG.md").read_text()
release = text.split("## [1.5.0] - 2026-08-28", 1)[1].split("## [1.4.3]", 1)[0]
assert "### Breaking" in release
assert "Architecture knowledge" in release
assert "Universal project and commercial records" in release
assert "Commercial workflows" in release
assert "Codex session ambience" in release
assert "format 2" in release and "format 3" in release
assert "not patch-compatible" in release
PY

python3 - <<'PY'
from pathlib import Path

text = Path("CHANGELOG.md").read_text()
release = text.split("## [1.4.0] - 2026-07-26", 1)[1].split("## [1.3.0]", 1)[0]
expected = [
    "### Breaking",
    "### Migration",
    "### Architecture and extensibility",
    "### Data boundaries and onboarding",
    "### Project workflow and memory",
    "### Learning and extension tooling",
    "### Fixes and optimization",
]
for heading in expected:
    assert release.count(heading) == 1, heading
assert "### Added" not in release
assert "### Changed" not in release
assert "welcome and update-check preferences remain in place" in release
PY

python3 - <<'PY'
import json
from pathlib import Path

plugin = json.loads(Path(".claude-plugin/plugin.json").read_text())
marketplace = json.loads(Path(".claude-plugin/marketplace.json").read_text())
assert plugin["name"] == "as"
assert marketplace["name"] == "skills-for-architects"
assert len(marketplace["plugins"]) == 1
assert marketplace["plugins"][0]["name"] == "as"
assert marketplace["plugins"][0]["source"] == "./"
PY
! rg -n '^name: (skills|feedback)$' skills/*/SKILL.md
! grep -q 'claude "/studio"' README.md
! grep -Eqi 'download (the )?`?skills/?`?|copy.*repository.*skills/' README.md
! rg -n '2\.0\.0|2\.1\.0' .claude-plugin .codex-plugin README.md CHANGELOG.md skills hooks

echo "✓ v1.5 release contract documents its local data, feedback, update, connector, and migration boundaries"
