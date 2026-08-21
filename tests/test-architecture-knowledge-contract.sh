#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

python3 - <<'PY'
from __future__ import annotations

import re
import tempfile
from pathlib import Path

ROOT = Path("skills/architecture-knowledge/references")
SKILL = Path("skills/architecture-knowledge/SKILL.md")
SKILL_README = Path("skills/architecture-knowledge/README.md")
RECORD = re.compile(r"^## (SRC-[A-Z0-9-]+)\s*$", re.M)
CONCEPT = re.compile(r"^## (AK-[A-Z0-9-]+)\s*$", re.M)
FIELD = re.compile(r"^- \*\*([^*]+):\*\*\s*(.+)$", re.M)
SOURCE_REF = r"`SRC-[A-Z0-9-]+`"
SOURCE_LIST = rf"{SOURCE_REF}(?:, {SOURCE_REF})*"
RELATION = re.compile(
    rf"- `(AK-[A-Z0-9-]+)` — ([a-z-]+) → `(AK-[A-Z0-9-]+)` \| Sources: ({SOURCE_LIST})"
)
ASSERTION = re.compile(rf"- `(A[0-9]+)` \| .+ \| Sources: ({SOURCE_LIST})")
AMBIGUOUS_ALIAS = re.compile(
    r"^- `([^`]+)` → ((?:`AK-[A-Z0-9-]+`(?:, )?)+) \| Ask: (.+)$", re.M
)

SOURCE_FIELDS = {
    "Status", "Publisher", "Title", "Canonical URL", "Terms or license URL",
    "Document ID or edition", "Publication or revision date", "Access/review date",
    "Permitted-use note", "Rights class", "Editorial review status", "Editorial reviewer", "Editorial review date",
}
CONCEPT_FIELDS = {
    "Canonical term", "Aliases", "Authority class", "Boundaries", "Source IDs",
}
PROHIBITED_FIELDS = {
    "Contract text", "Excerpt", "Clause", "Clause crosswalk", "Licensed table", "Template",
}
REQUIRED_CONCEPTS = {
    "AK-SCHEMATIC-DESIGN", "AK-DESIGN-DEVELOPMENT", "AK-CONSTRUCTION-DOCUMENTS",
    "AK-PROCUREMENT", "AK-CONSTRUCTION-PHASE", "AK-BASIC-SERVICES",
    "AK-SUPPLEMENTAL-SERVICES", "AK-ADDITIONAL-SERVICES", "AK-CD-SET",
    "AK-CONTRACT-DOCUMENTS", "AK-50-PERCENT-CD", "AK-OWNER", "AK-ARCHITECT",
    "AK-CONTRACTOR", "AK-DESIGN-BID-BUILD", "AK-CM-AT-RISK", "AK-DESIGN-BUILD",
    "AK-AIA-A-SERIES", "AK-AIA-B-SERIES", "AK-AIA-C-SERIES", "AK-AIA-G-SERIES",
    "AK-AIA-B101-2017", "AK-AIA-A201-2017", "AK-MASTERFORMAT", "AK-UNIFORMAT",
    "AK-OMNICLASS", "AK-SECTIONFORMAT", "AK-PAGEFORMAT", "AK-NCS-V7",
}


def fail(message: str) -> None:
    raise AssertionError(message)


def records(text: str):
    matches = list(RECORD.finditer(text))
    for i, match in enumerate(matches):
        yield match.group(1), text[match.end():matches[i + 1].start() if i + 1 < len(matches) else len(text)]


def concepts(root: Path):
    for path in sorted(root.glob("*.md")):
        if path.name in {"README.md", "sources.md"}:
            continue
        text = path.read_text(encoding="utf-8")
        matches = list(CONCEPT.finditer(text))
        for i, match in enumerate(matches):
            yield path, match.group(1), text[match.end():matches[i + 1].start() if i + 1 < len(matches) else len(text)]


def source_ids(value: str):
    return [item.strip() for item in value.split(",") if item.strip()]


def cited_source_ids(value: str):
    return re.findall(r"`(SRC-[A-Z0-9-]+)`", value)


def validate(root: Path) -> None:
    readme = root / "README.md"
    sources = root / "sources.md"
    if not readme.is_file() or not sources.is_file():
        fail("knowledge contract requires references/README.md and references/sources.md")
    schema = readme.read_text(encoding="utf-8")
    if "ambiguous aliases" not in schema.lower() or "unsupported" not in schema.lower():
        fail("README.md must define ambiguous-alias and unsupported-claim behavior")
    ambiguous_aliases = {}
    for alias, targets, question in AMBIGUOUS_ALIAS.findall(schema):
        normalized = alias.casefold()
        if normalized in ambiguous_aliases:
            fail(f"duplicate ambiguous alias: {alias}")
        target_ids = re.findall(r"`(AK-[A-Z0-9-]+)`", targets)
        if len(target_ids) < 2 or not question.strip():
            fail(f"ambiguous alias must name multiple targets and a question: {alias}")
        ambiguous_aliases[normalized] = target_ids

    source_text = sources.read_text(encoding="utf-8")
    known_sources = {}
    for source_id, body in records(source_text):
        if source_id in known_sources:
            fail(f"duplicate source ID: {source_id}")
        fields = dict(FIELD.findall(body))
        missing = SOURCE_FIELDS - fields.keys()
        if missing:
            fail(f"{source_id} missing source metadata: {', '.join(sorted(missing))}")
        if fields["Status"] not in {"active", "reserved", "superseded"}:
            fail(f"{source_id} has invalid status")
        if fields["Rights class"] not in {"public-summary", "license-required"}:
            fail(f"{source_id} has invalid rights class")
        if fields["Editorial review status"] not in {"pending-human-review", "reviewed"}:
            fail(f"{source_id} has invalid editorial review status")
        for name in ("Canonical URL", "Terms or license URL"):
            if not fields[name].startswith("https://"):
                fail(f"{source_id} {name} must use HTTPS")
        for name in SOURCE_FIELDS - {"Canonical URL", "Terms or license URL"}:
            if not fields[name].strip():
                fail(f"{source_id} {name} cannot be empty")
        known_sources[source_id] = fields
    if not known_sources:
        fail("sources.md must contain at least one source record")

    seen_concepts = {}
    ordinary_aliases = {}
    used_sources = set()
    for path, concept_id, body in concepts(root):
        if concept_id in seen_concepts:
            fail(f"duplicate concept ID: {concept_id}")
        fields = dict(FIELD.findall(body))
        missing = CONCEPT_FIELDS - fields.keys()
        if missing:
            fail(f"{concept_id} missing concept metadata: {', '.join(sorted(missing))}")
        if fields["Authority class"] not in {"first-party", "industry-shorthand", "project-or-firm-specific"}:
            fail(f"{concept_id} has invalid authority class")
        for alias in source_ids(fields["Aliases"]):
            normalized = alias.casefold()
            if normalized in ambiguous_aliases:
                fail(f"{concept_id} repeats ambiguous alias in ordinary aliases: {alias}")
            previous = ordinary_aliases.get(normalized)
            if previous:
                fail(f"ordinary alias maps to multiple concepts: {alias} ({previous}, {concept_id})")
            ordinary_aliases[normalized] = concept_id
        refs = source_ids(fields["Source IDs"])
        if not refs:
            fail(f"{concept_id} has no source IDs")
        for ref in refs:
            if ref not in known_sources:
                fail(f"{concept_id} references missing source {ref}")
            used_sources.add(ref)
        assertion_ids = set()
        assertion_count = 0
        for line in body.splitlines():
            if not (line.startswith("- `A") or "| Sources:" in line):
                continue
            relation_match = RELATION.fullmatch(line)
            assertion_match = ASSERTION.fullmatch(line)
            if not relation_match and not assertion_match:
                fail(f"{concept_id} has malformed assertion or relationship: {line}")
            if assertion_match:
                assertion_count += 1
                assertion_id, citations = assertion_match.groups()
                if assertion_id in assertion_ids:
                    fail(f"{concept_id} has duplicate assertion ID: {assertion_id}")
                assertion_ids.add(assertion_id)
                for ref in cited_source_ids(citations):
                    if ref not in known_sources:
                        fail(f"{concept_id} assertion references missing source {ref}")
                    used_sources.add(ref)
            if relation_match:
                for ref in cited_source_ids(relation_match.group(4)):
                    if ref not in known_sources:
                        fail(f"{concept_id} relationship references missing source {ref}")
                    used_sources.add(ref)
        if not assertion_count:
            fail(f"{concept_id} has no factual assertions")
        seen_concepts[concept_id] = (path, body)

    for alias, targets in ambiguous_aliases.items():
        for target in targets:
            if target not in seen_concepts:
                fail(f"ambiguous alias {alias} targets missing concept {target}")

    for concept_id, (path, body) in seen_concepts.items():
        for target, relation, destination, refs in RELATION.findall(body):
            if target != concept_id:
                fail(f"{path}: relationship target must equal its enclosing concept ID")
            if destination not in seen_concepts:
                fail(f"{concept_id} relationship {relation} targets missing concept {destination}")
            for ref in cited_source_ids(refs):
                if ref not in known_sources:
                    fail(f"{concept_id} relationship references missing source {ref}")
                used_sources.add(ref)

    for source_id, fields in known_sources.items():
        if fields["Status"] == "active" and source_id not in used_sources:
            fail(f"active source is unused: {source_id}")
        if fields["Status"] == "reserved" and source_id in used_sources:
            fail(f"reserved source is used: {source_id}")

    for path in sorted(root.glob("*.md")):
        text = path.read_text(encoding="utf-8")
        for field in PROHIBITED_FIELDS:
            if re.search(rf"^- \*\*{re.escape(field)}:\*\*", text, re.M | re.I):
                fail(f"{path} exposes prohibited content field: {field}")
            if re.search(rf"^#{{1,6}}\s+{re.escape(field)}\s*$", text, re.M | re.I):
                fail(f"{path} exposes prohibited content section: {field}")

    if root == ROOT:
        missing_concepts = REQUIRED_CONCEPTS - seen_concepts.keys()
        if missing_concepts:
            fail(f"initial corpus is missing required concepts: {', '.join(sorted(missing_concepts))}")
        corpus_text = "\n".join(
            path.read_text(encoding="utf-8")
            for path in sorted(root.glob("*.md"))
            if path.name not in {"README.md", "sources.md"}
        )
        for phrase in (
            "CD set", "Construction Documents", "Contract Documents", "50% CDs",
            "CD is context-dependent",
            "agreement and project-specific", "not a universal fixed-content package",
            "does not select a form", "does not provide clause interpretation",
            "MasterFormat 2026", "NCS Version 7",
        ):
            if phrase not in corpus_text:
                fail(f"initial corpus is missing required distinction or boundary: {phrase}")


# The compact fixture proves the graph validator independently of the bundled
# corpus content.
with tempfile.TemporaryDirectory() as temp:
    fixture = Path(temp)
    fixture.joinpath("README.md").write_text(
        "Ambiguous aliases require disambiguation; unsupported claims are disclosed.\n",
        encoding="utf-8",
    )
    fixture.joinpath("sources.md").write_text(
        "## SRC-TEST-1\n"
        "- **Status:** active\n- **Publisher:** Test\n- **Title:** Test source\n"
        "- **Canonical URL:** https://example.com/source\n"
        "- **Terms or license URL:** https://example.com/terms\n"
        "- **Document ID or edition:** Test 1\n"
        "- **Publication or revision date:** 2026-08-20\n"
        "- **Access/review date:** 2026-08-20\n"
        "- **Permitted-use note:** Metadata and original summaries only.\n"
        "- **Rights class:** public-summary\n"
        "- **Editorial review status:** reviewed\n"
        "- **Editorial reviewer:** Test reviewer\n"
        "- **Editorial review date:** 2026-08-20\n",
        encoding="utf-8",
    )
    fixture.joinpath("concepts.md").write_text(
        "## AK-TEST\n"
        "- **Canonical term:** Test\n- **Aliases:** test\n- **Authority class:** first-party\n"
        "- **Boundaries:** Orientation only.\n- **Source IDs:** SRC-TEST-1\n"
        "- `A1` | A concise original summary. | Sources: `SRC-TEST-1`\n",
        encoding="utf-8",
    )
    validate(fixture)

    source_path = fixture / "sources.md"
    concept_path = fixture / "concepts.md"
    readme_path = fixture / "README.md"
    readme_fixture = readme_path.read_text(encoding="utf-8")
    source_fixture = source_path.read_text(encoding="utf-8")
    concept_fixture = concept_path.read_text(encoding="utf-8")

    def expect_rejected(
        label: str,
        *,
        readme: str = readme_fixture,
        sources: str = source_fixture,
        concepts: str = concept_fixture,
    ) -> None:
        readme_path.write_text(readme, encoding="utf-8")
        source_path.write_text(sources, encoding="utf-8")
        concept_path.write_text(concepts, encoding="utf-8")
        try:
            validate(fixture)
        except AssertionError:
            pass
        else:
            fail(f"negative fixture unexpectedly passed: {label}")

    expect_rejected("duplicate source", sources=source_fixture + source_fixture)
    expect_rejected("duplicate concept", concepts=concept_fixture + concept_fixture)
    expect_rejected(
        "missing review metadata",
        sources=source_fixture.replace("- **Editorial reviewer:** Test reviewer\n", ""),
    )
    expect_rejected(
        "non-HTTPS source URL",
        sources=source_fixture.replace("https://example.com/source", "http://example.com/source"),
    )
    expect_rejected(
        "dangling source ID",
        concepts=concept_fixture.replace("SRC-TEST-1", "SRC-MISSING", 1),
    )
    expect_rejected(
        "dangling relationship target",
        concepts=concept_fixture + "- `AK-TEST` — related-to → `AK-MISSING` | Sources: `SRC-TEST-1`\n",
    )
    expect_rejected(
        "unused active source",
        sources=source_fixture + source_fixture.replace("SRC-TEST-1", "SRC-UNUSED"),
    )
    expect_rejected(
        "prohibited field",
        concepts=concept_fixture + "- **Clause:** copied text\n",
    )
    expect_rejected(
        "prohibited section",
        concepts=concept_fixture + "## Excerpt\n\ncopied text\n",
    )
    expect_rejected(
        "malformed assertion",
        concepts=concept_fixture + "- `A2` | Missing source syntax.\n",
    )
    expect_rejected(
        "malformed multi-source assertion",
        concepts=concept_fixture + "- `A2` | Bad citation list. | Sources: `SRC-TEST-1`, SRC-MISSING\n",
    )
    expect_rejected(
        "duplicate assertion ID",
        concepts=concept_fixture + "- `A1` | Duplicate ID. | Sources: `SRC-TEST-1`\n",
    )
    expect_rejected(
        "duplicate ordinary alias",
        concepts=concept_fixture + concept_fixture.replace("AK-TEST", "AK-SECOND"),
    )
    expect_rejected(
        "dangling ambiguous alias target",
        readme=readme_fixture
        + "- `shared` → `AK-TEST`, `AK-MISSING` | Ask: Which meaning?\n",
    )

validate(ROOT)

if not SKILL.is_file() or not SKILL_README.is_file():
    fail("lookup-skill contract requires architecture-knowledge SKILL.md and README.md")
skill_text = SKILL.read_text(encoding="utf-8")
readme_text = SKILL_README.read_text(encoding="utf-8")
expected_harness_note = (
    "> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. "
    "Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and "
    "`<plugin-root>` as the plugin root that contains `skills/`, and use equivalent "
    "native tools when host tool names differ."
)
required_skill_phrases = (
    "name: architecture-knowledge",
    "architecture-studio:harness-compatibility",
    expected_harness_note,
    "`references/README.md`",
    "`references/sources.md`",
    "smallest pertinent",
    "do not load the entire corpus",
    "direct meaning first",
    "material distinctions",
    "clickable official sources",
    "governing project agreement",
    "confirmed firm standards",
    "bundled national baseline",
    "industry shorthand",
    "ambiguous `CD`",
    "CD set",
    "Construction Documents",
    "Contract Documents",
    "50% CDs",
    "unsupported",
    "does not select a form",
    "clause interpretation",
    "MasterFormat tables",
    "NCS modules",
    "code/jurisdiction",
    "outline-spec",
    "agreement-scope",
    "work-plan",
    "pending human editorial review",
    "stale or superseded",
    "without a studio or project",
    "never reads project records",
)
for phrase in required_skill_phrases:
    assert phrase in skill_text, f"SKILL.md missing lookup-skill contract phrase: {phrase}"
assert "allowed-tools:\n  - Read" in skill_text
assert "  - Grep" in skill_text
for forbidden in ("  - Write", "  - Edit", "  - Bash", "  - WebSearch", "  - WebFetch"):
    assert forbidden not in skill_text, f"read-only skill exposes forbidden tool: {forbidden}"
for syntax in ("$architecture-knowledge", "/as:architecture-knowledge"):
    assert syntax in skill_text or syntax in readme_text, f"missing invocation syntax: {syntax}"
for phrase in ("read-only", "no studio or project", "does not create or modify workspace files"):
    assert phrase in readme_text, f"README.md missing lookup-skill boundary: {phrase}"

print("✓ architecture knowledge contract: ok")
PY
