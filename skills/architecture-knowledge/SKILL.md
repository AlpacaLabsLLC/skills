---
name: architecture-knowledge
description: Explain US architecture professional-practice terms, phases, deliverables, roles, delivery methods, AIA contract families, CSI documentation systems, or NCS at a high level. Use for questions such as “what is a CD set?” or “what does 50% CDs mean?”; do not use for code/jurisdiction, outline-spec, agreement-scope, or work-plan work.
allowed-tools:
  - Read
  - Grep
---

# /as:architecture-knowledge — US Architecture Knowledge

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Provide read-only orientation on the bundled US professional-practice vocabulary. Direct invocation works as `/as:architecture-knowledge` or `$architecture-knowledge` without a studio or project. This skill never creates or modifies workspace files, never reads project records, and never polices user behavior.

## Read the smallest relevant corpus slice

1. Read `references/README.md` first. It defines the corpus contract, authority classes, alias behavior, relationship syntax, and rights boundary.
2. Use read-only search to resolve the user's words and aliases to the smallest pertinent concept entries in `references/phases-and-deliverables.md`, `references/roles-and-delivery.md`, `references/contract-families.md`, or `references/documentation-standards.md`, then read only those bounded entries.
3. Search `references/sources.md` by the selected entries' source IDs and read only those bounded source records; do not load the entire corpus by default.
4. If a cited source is `pending human editorial review`, `stale or superseded`, disclose that status beside the source. Do not present it as current verified authority.

## Answer contract

Answer with direct meaning first, then material distinctions and qualifications, then clickable official sources with edition/review date:

1. **Direct meaning** — give the shortest supported explanation first.
2. **Distinctions and qualifications** — explain adjacent concepts, authority class, boundaries, and project-specific variation.
3. **Sources** — provide clickable official source URLs with the source's edition or document identifier and access/review date.

Authority order is: governing project agreement, confirmed firm standards, bundled national baseline, then industry shorthand. Explain the governing agreement when it is supplied by the user, but never interpret it, replace it, or infer missing obligations from this corpus.

An ambiguous `CD` asks for context before selecting a meaning. Keep these concepts distinct and resolve them to their separate corpus entries: `CD set`, `Construction Documents`, `Contract Documents`, and `50% CDs`. A term or claim without a supported entry is disclosed as unsupported rather than answered from model memory.

## Boundaries and handoffs

- Contract-selection or clause-interpretation questions receive high-level family orientation plus a clear boundary; this skill does not select a form, interpret a clause, or provide a legal conclusion. It does not provide clause interpretation.
- Never reproduce protected contract wording, MasterFormat tables, NCS modules, excerpts, clause mappings, or reconstructed templates.
- Code/jurisdiction questions hand off to the relevant code or zoning skill. Outline-spec requests hand off to `spec-writer`; agreement-scope requests hand off to `agreement`; work-plan requests hand off to `workplan`.
- These handoffs preserve the owning workflow's authority. This skill never invokes another workflow as authority, mutates records, or turns terminology into a permission, scope, phase, or completeness gate.

If the request combines terminology with an owned deliverable, answer only the terminology orientation that is useful as context and direct the user to the owning skill for the work.
