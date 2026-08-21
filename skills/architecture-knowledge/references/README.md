# Architecture knowledge contract

This directory is the read-only, bundled reference contract for
`architecture-knowledge`. It contains a small linked Markdown corpus, not a
database, parser service, RDF export, or generated-documentation pipeline.

## Ownership and boundary

`architecture-knowledge` owns these bundled reference files. They provide a
national US professional-practice baseline for orientation only. They never
determine whether work is permitted, complete, in scope, billable, or suitable
for a particular project.

Studio `standards/` and `references/` remain user-owned. A project agreement or
user-supplied licensed source may inform a user's work, but it is not copied
into this bundled corpus.

## Source records

`sources.md` is the only source registry. Every source record uses a stable
`SRC-…` ID and supplies these fields:

- Status: `active`, `reserved`, or `superseded`.
- Publisher, Title, Canonical URL, and Terms or license URL.
- Document ID or edition, using `Not applicable` only when neither exists.
- Publication or revision date, using `Not stated on public page` when the
  publisher does not provide one.
- Access/review date, Permitted-use note, Rights class, Editorial reviewer, and
  Editorial review date.

Canonical and terms/license URLs must be absolute HTTPS URLs. Rights classes
are `public-summary` for original, high-level editorial orientation based on a
public first-party page and `license-required` for metadata that identifies a
licensed source without reproducing it. Active source records must be cited by
at least one concept assertion or relationship; reserved records are prepared
for future approved concepts.

## Concept records

Vocabulary files added by later units contain `## AK-…` concept records. Each
record has these fields:

- Canonical term
- Aliases
- Authority class: `first-party`, `industry-shorthand`, or
  `project-or-firm-specific`
- Boundaries
- Source IDs

Each factual assertion is an individual list item in this exact form:

```markdown
- `A1` | Original concise summary. | Sources: `SRC-EXAMPLE-1`
```

Each relationship is an individual list item in this exact form:

```markdown
- `AK-EXAMPLE-A` — related-to → `AK-EXAMPLE-B` | Sources: `SRC-EXAMPLE-1`
```

Relationship verbs are lowercase kebab-case. Assertion and edge-level source
references are mandatory even when the enclosing concept has the same source.
Every source ID and relationship target must resolve within this directory.

## Alias and unsupported-claim behavior

Aliases are a lookup index, not an authority upgrade. An alias maps to one
concept only when the term is unambiguous. Ambiguous aliases must name the
candidate canonical terms and request disambiguation; they must not silently
select one. A term without a supported entry is disclosed as unsupported rather
than answered from model memory.

An alias never gives industry shorthand, project convention, or firm language
the authority of a first-party source. The answer must preserve the authority
class and boundaries of the resolved concept.

### Ambiguous alias index

This is the only multi-target alias map. Ordinary aliases in concept records
must resolve to exactly one concept.

- `CD` → `AK-CONSTRUCTION-DOCUMENTS`, `AK-CONTRACT-DOCUMENTS`, `AK-CD-SET`, `AK-50-PERCENT-CD` | Ask: Which phase, document category, package, or milestone does the surrounding context mean?

## Rights-safe editorial rule

Store original concise summaries, identifiers, relationship metadata, and links
only. Do not add fields or sections for contract text, excerpts, clauses, clause
crosswalks, licensed tables, or reconstructed templates. Do not copy source
prose into an assertion. Human editorial review is required for every summary;
the reviewer and review date are recorded on its cited source record.
