#!/usr/bin/env bash
set -euo pipefail

# Keep byte classification and sort order stable across developer and CI locales.
export LC_ALL=C
export LANG=C
# The parser below reads UTF-8 documents and writes skill names back out, so pin
# the Python side explicitly rather than inheriting a cp1252 default on Windows.
export PYTHONIOENCODING=utf-8

if ! command -v python3 >/dev/null 2>&1; then
  echo "✗ python3 is required to run this audit" >&2
  exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
# Optional skills root, so this can be pointed at a fixture tree in tests.
# Defaults to this repository's skills/ directory.
skills_root="${1:-${repo_root}/skills}"

# The description is read with the YAML parser rather than reconstructed by hand.
# Frontmatter descriptions may legally be inline, quoted, folded, literal, or
# plain multi-line scalars, and each folds, chomps, and strips comments by its
# own rules. Reproducing those rules incrementally is how the audit came to
# report a zero-character description for a valid plain multi-line scalar, a
# 20-character one for a blank-line fold that is 19, and comment text as
# description content.
#
# Lengths stay byte lengths, matching LC_ALL=C above and the figures already
# published in docs/reports/v1-4-skill-context-optimization.md.
python3 - "${skills_root}"/*/SKILL.md <<'PY' | {
import sys

# Explicit encoding and line endings, so the TSV is byte-identical on Windows,
# where the platform default is cp1252 output and CRLF line endings.
sys.stdout.reconfigure(encoding="utf-8", newline="\n")

try:
    import yaml
except ModuleNotFoundError:
    sys.exit(
        "ERROR: PyYAML is required to measure skill descriptions "
        "(pip install pyyaml)"
    )


def ceil4(n):
    return (n + 3) // 4


def skill_name(path):
    name = path.replace("\\", "/")
    marker = "/skills/"
    if marker in name:
        name = name[name.rindex(marker) + len(marker):]
    if name.endswith("/SKILL.md"):
        name = name[: -len("/SKILL.md")]
    return name


def split_document(lines):
    """Return (frontmatter lines, body lines) using the document's --- fences."""
    front, body = [], []
    in_front = False
    front_done = False
    for line in lines:
        if line == "---" and not front_done:
            if not in_front:
                in_front = True
            else:
                in_front = False
                front_done = True
            continue
        if in_front:
            front.append(line)
        elif front_done:
            body.append(line)
    return front, body


def description_of(front, path):
    # The trailing newline matters: a clip-chomped block scalar (">" or "|")
    # keeps its final line break, and the document has one before the closing
    # fence even though the fence itself is not part of the frontmatter.
    text = "\n".join(front) + "\n"
    try:
        meta = yaml.safe_load(text)
        node = yaml.compose(text)
    except yaml.YAMLError as exc:
        sys.exit("ERROR: unparsable frontmatter in %s: %s" % (path, exc))
    if not isinstance(meta, dict) or "description" not in meta:
        sys.exit("ERROR: missing description in %s" % path)
    value = meta["description"]
    if value is None:
        value = ""
    # Source lines the description occupies, which the value alone cannot
    # report. Taken from the node's marks so that a trailing comment or a
    # chomped newline is not counted as description text.
    lines = 1
    for key_node, value_node in node.value:
        if key_node.value != "description":
            continue
        last = value_node.end_mark.line
        if value_node.end_mark.column == 0:
            last -= 1  # the mark sits at the start of the following line
        lines = last - value_node.start_mark.line + 1
        if value_node.style in ("|", ">"):
            lines -= 1  # the block indicator shares the "description:" line
        lines = max(1, lines)
        break
    return str(value), lines


def measure(path):
    with open(path, encoding="utf-8") as handle:
        lines = handle.read().splitlines()
    front, body_lines = split_document(lines)
    desc, desc_lines = description_of(front, path)
    # Body accumulation is left exactly as it was, so the figures in
    # docs/reports/v1-4-skill-context-optimization.md still reconcile. This
    # deliberately keeps the leading-blank-line quirk of the previous version;
    # changing it belongs in its own change, not in a description fix.
    body = ""
    for line in body_lines:
        if body != "":
            body += "\n"
        body += line
    desc_bytes = len(desc.encode("utf-8"))
    body_bytes = len(body.encode("utf-8"))
    return (
        skill_name(path),
        desc_bytes,
        len(desc.split()),
        desc_lines,
        ceil4(desc_bytes),
        body_bytes,
        len(body.split()),
        len(body_lines),
    )


for path in sys.argv[1:]:
    print("\t".join(str(field) for field in measure(path)))
PY
  printf 'skill\tdescription_chars\tdescription_words\tdescription_lines\tdescription_est_tokens\tbody_chars\tbody_words\tbody_lines\n'
  sort -t $'\t' -k5,5nr
}
