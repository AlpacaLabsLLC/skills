#!/usr/bin/env python3
"""Validate Architecture Studio's public plugin namespace contract."""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

EXPECTED_NAMESPACE = "as"
EXPECTED_MARKETPLACE = "skills-for-architects"
EXPECTED_INSTALL_ID = f"{EXPECTED_NAMESPACE}@{EXPECTED_MARKETPLACE}"
RETIRED_NAMESPACE = "architecture-studio"
RETIRED_INSTALL_ID = f"{RETIRED_NAMESPACE}@{EXPECTED_MARKETPLACE}"
MIGRATION_ALLOWLIST = {
    "CHANGELOG.md",
}
VALIDATOR_ALLOWLIST = {
    "scripts/check-plugin-namespace.py",
    "tests/test-plugin-namespace.sh",
}
PERSISTENT_STATE_NAMES = {
    ".architecture-studio-update-check-enabled",
    ".architecture-studio-version-check",
    ".architecture-studio-welcomed",
}
RETIRED_STATE_NAMES = {
    ".as-update-check-enabled",
    ".as-version-check",
    ".as-welcomed",
}
TEXT_SUFFIXES = {
    ".json",
    ".md",
    ".py",
    ".sh",
    ".txt",
    ".yaml",
    ".yml",
}
BUILTINS = {
    "agents",
    "clear",
    "config",
    "help",
    "hooks",
    "init",
    "mcp",
    "plugin",
}


def repository_files(root: Path) -> list[Path]:
    """Return tracked and untracked repository files, or fixture files."""
    try:
        output = subprocess.check_output(
            [
                "git",
                "-C",
                str(root),
                "ls-files",
                "--cached",
                "--others",
                "--exclude-standard",
            ],
            stderr=subprocess.DEVNULL,
            text=True,
        )
    except (subprocess.CalledProcessError, FileNotFoundError):
        return sorted(
            path
            for path in root.rglob("*")
            if path.is_file() and ".git" not in path.relative_to(root).parts
        )
    return [
        root / line
        for line in output.splitlines()
        if line and (root / line).is_file()
    ]


def read_json(path: Path, errors: list[str]) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        errors.append(f"{path}: missing required manifest")
        return {}
    except json.JSONDecodeError as exc:
        errors.append(f"{path}: invalid JSON: {exc}")
        return {}
    if not isinstance(value, dict):
        errors.append(f"{path}: manifest root must be an object")
        return {}
    return value


def frontmatter_name(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    match = re.search(r"^name:\s*['\"]?([^'\"\s]+)", text[4:end], re.MULTILINE)
    return match.group(1) if match else None


def active_retired_identifier_text(relative: str, text: str) -> str:
    """Remove only the root README's explicitly labeled migration section."""
    if relative != "README.md":
        return text
    section = re.compile(
        r"(?ms)^### Upgrading to v1\.4\.0 \(reinstall required\)\s*$.*?(?=^###\s|\Z)"
    )
    return section.sub("", text)


def validate(root: Path) -> list[str]:
    errors: list[str] = []
    repo_files = repository_files(root)
    plugin_path = root / ".claude-plugin" / "plugin.json"
    marketplace_path = root / ".claude-plugin" / "marketplace.json"
    plugin = read_json(plugin_path, errors)
    marketplace = read_json(marketplace_path, errors)

    if plugin.get("name") != EXPECTED_NAMESPACE:
        errors.append(
            f"{plugin_path}: plugin name must be '{EXPECTED_NAMESPACE}', "
            f"found {plugin.get('name')!r}"
        )
    if marketplace.get("name") != EXPECTED_MARKETPLACE:
        errors.append(
            f"{marketplace_path}: marketplace name must remain "
            f"'{EXPECTED_MARKETPLACE}', found {marketplace.get('name')!r}"
        )
    entries = marketplace.get("plugins", [])
    if not isinstance(entries, list) or len(entries) != 1:
        errors.append(f"{marketplace_path}: must contain exactly one plugin entry")
    elif not isinstance(entries[0], dict) or entries[0].get("name") != EXPECTED_NAMESPACE:
        actual = entries[0].get("name") if isinstance(entries[0], dict) else entries[0]
        errors.append(
            f"{marketplace_path}: plugin entry name must be "
            f"'{EXPECTED_NAMESPACE}', found {actual!r}"
        )

    skills_root = root / "skills"
    misplaced_skill_files = sorted(
        path
        for path in repo_files
        if path.name == "SKILL.md"
        if path.parent.parent != skills_root
    )
    for skill_file in misplaced_skill_files:
        relative = skill_file.relative_to(root).as_posix()
        errors.append(
            f"{relative}: SKILL.md is allowed only at skills/<name>/SKILL.md; "
            "store non-installable examples under assets/ as SKILL.example.md"
        )

    skill_dirs = {
        path.name
        for path in skills_root.iterdir()
        if path.is_dir() and not path.name.startswith(".")
    } if skills_root.is_dir() else set()
    names: dict[str, Path] = {}
    for skill_dir in sorted(skill_dirs):
        skill_file = skills_root / skill_dir / "SKILL.md"
        if not skill_file.is_file():
            continue
        name = frontmatter_name(skill_file)
        if name is not None and name != skill_dir:
            errors.append(
                f"{skill_file}: frontmatter name '{name}' must match "
                f"directory '{skill_dir}'"
            )
        if name is not None and name in names:
            errors.append(
                f"{skill_file}: duplicate skill name '{name}' also used by {names[name]}"
            )
        elif name is not None:
            names[name] = skill_file
        if skill_dir.startswith(f"{RETIRED_NAMESPACE}-"):
            errors.append(
                f"{skill_dir}: retired namespace wrapper/alias directories are forbidden"
            )

    assets_root = root / "assets"
    example_skill_files = sorted(
        assets_root.rglob("SKILL.example.md")
    ) if assets_root.is_dir() else []
    example_names: dict[str, Path] = {}
    for example_file in example_skill_files:
        name = frontmatter_name(example_file)
        relative = example_file.relative_to(root).as_posix()
        if name is None:
            errors.append(
                f"{relative}: example skill must declare a frontmatter name"
            )
            continue
        if (
            relative.startswith("assets/learn-examples/")
            and name != example_file.parent.name
        ):
            errors.append(
                f"{relative}: example skill name '{name}' must match "
                f"directory '{example_file.parent.name}'"
            )
        if name in example_names:
            errors.append(
                f"{relative}: duplicate example skill name '{name}' also used by "
                f"{example_names[name].relative_to(root).as_posix()}"
            )
        else:
            example_names[name] = example_file
        if name in names:
            errors.append(
                f"{relative}: example skill name '{name}' overlaps canonical skill "
                f"{names[name].relative_to(root).as_posix()}"
            )

    # The negative lookbehind excludes path fragments such as
    # ~/Documents/as:project-epds/ while still covering prose, fenced command
    # examples, shell strings, JSON, and hook output.
    command_re = re.compile(
        r"(?<![A-Za-z0-9._~/-])/([a-z][a-z0-9-]*):([a-z][a-z0-9-]*)"
    )
    # Match command-shaped bare references while excluding namespaced commands
    # (`/as:project`), URLs, and filesystem/path fragments (`docs/project`).
    bare_command_re = re.compile(
        r"(?<![A-Za-z0-9._~/:=-])/([a-z][a-z0-9-]*)(?![:A-Za-z0-9-])"
    )
    for path in repo_files:
        relative = path.relative_to(root).as_posix()
        if path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue

        migration_history = (
            relative in MIGRATION_ALLOWLIST or relative.startswith("docs/plans/")
        )
        validator_fixture = relative in VALIDATOR_ALLOWLIST
        if not migration_history and not validator_fixture:
            guarded_text = active_retired_identifier_text(relative, text)
            if f"/{RETIRED_NAMESPACE}:" in guarded_text:
                errors.append(
                    f"{relative}: retired command namespace '/{RETIRED_NAMESPACE}:' "
                    "is allowed only in migration history"
                )
            if RETIRED_INSTALL_ID in guarded_text:
                errors.append(
                    f"{relative}: retired install ID '{RETIRED_INSTALL_ID}' "
                    "is allowed only in migration history"
                )

        if not validator_fixture:
            for retired_state in RETIRED_STATE_NAMES:
                if retired_state in text:
                    errors.append(
                        f"{relative}: '{retired_state}' would rename persistent state; "
                        "keep the .architecture-studio-* filename"
                    )

        example_material = relative.startswith("assets/learn-examples/")
        if migration_history or validator_fixture or example_material:
            continue
        for match in command_re.finditer(text):
            namespace, command = match.groups()
            if namespace != EXPECTED_NAMESPACE:
                continue
            if command not in skill_dirs and command not in BUILTINS:
                errors.append(
                    f"{relative}: '/{EXPECTED_NAMESPACE}:{command}' does not "
                    f"resolve to skills/{command}/"
                )
        command_text = active_retired_identifier_text(relative, text)
        active_plugin_surface = not relative.startswith(("scripts/", "tests/"))
        if active_plugin_surface:
            for match in bare_command_re.finditer(command_text):
                command = match.group(1)
                if command in skill_dirs:
                    errors.append(
                        f"{relative}: bare bundled command '/{command}' must use "
                        f"'/{EXPECTED_NAMESPACE}:{command}'"
                    )

    # The state prefix is intentionally stable across the command rename.
    all_text = "\n".join(
        path.read_text(encoding="utf-8", errors="ignore")
        for path in repo_files
        if path.suffix.lower() in TEXT_SUFFIXES
        and path.relative_to(root).as_posix() not in VALIDATOR_ALLOWLIST
    )
    missing_state = sorted(name for name in PERSISTENT_STATE_NAMES if name not in all_text)
    if missing_state:
        errors.append(
            "persistent state contract missing references to: " + ", ".join(missing_state)
        )

    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("root", nargs="?", default=".")
    args = parser.parse_args()
    root = Path(args.root).resolve()
    errors = validate(root)
    if errors:
        for error in errors:
            print(f"  ✗ {error}")
        return 1
    print(
        f"  ✓ namespace '{EXPECTED_NAMESPACE}', install ID "
        f"'{EXPECTED_INSTALL_ID}', commands, aliases, and persistent state"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
