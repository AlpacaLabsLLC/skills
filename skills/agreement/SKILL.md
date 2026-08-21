---
name: agreement
description: Maintain project-local contract context — cite checksum-protected proposal terms when useful, check requests against recorded scope, record SOWs and amendments, and report term and budget context. Use for "is this in scope", "check against the contract", "record this SOW", scope-creep questions, or an optional handoff from /as:proposal.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:agreement — Contract context and scope guard

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:agreement` owns each project's `agreement/` directory: `AGREEMENT.md`, SOWs, and amendments. When a project-local proposal is useful source material, the agreement cites its path and issued-terms checksum; it does not copy or take ownership of the proposal.

## Commands

```text
/as:agreement init
/as:agreement promote <project-relative proposal path>
/as:agreement check <request>
/as:agreement amend
/as:agreement status
/as:agreement verify
```

## Hard rules

1. **One writer.** `/as:agreement` is the only writer of `agreement/`. It never writes project-local `proposals/`, `PROJECT.md`, `INVOICES.md`, `STUDIO.md`, `decisions/`, tasks, time records, or project status.
2. **Cite accepted proposal terms.** Promotion requires an accepted proposal and records its project-relative path plus the SHA-256 of its protected issued terms. The proposal is not copied into `agreement/`; later lifecycle metadata may change without invalidating the citation.
3. **Agreement documents are append-only.** SOWs and amendments placed under `agreement/` are never overwritten or deleted by this skill. A change uses a new dated document and Amendments row.
4. **Facts cite their document.** Every `AGREEMENT.md` value carries the governing document and date. Unknown stays blank — never inferred, never invented.
5. **Verdicts are advisory.** `check` classifies work as `in-scope`, `needs-SOW`, or `out-of-scope`, quoting the governing scope bullets. It informs; it never blocks, and the user always decides.
6. **User-owned workflow.** Direct engagements may initialize agreement context without a proposal. Promotion is the optional path for an existing accepted proposal. The agreement skill never changes project status; neither path creates a proposal or initializes invoicing automatically.
7. **Script-mediated integrity.** Initialization, promotion, and Amendments-table writes run through `<skill-root>/scripts/agreement-workspace.sh` after a preview and one confirmation. Malformed records or checksum mismatches are preserved and reported, not repaired.

## Resolve the project

Run the shared resolver at `<plugin-root>/skills/project/scripts/resolve-context.sh` and follow `skills/project/references/context-resolution.md`. `agreement/` always lives at the selected project root. Type and status may inform the conversation but never gate a user-confirmed agreement action.

## Terminology context

For neutral professional-practice terminology, AIA document-family orientation, or document purpose, consult `<plugin-root>/skills/architecture-knowledge/references/` as terminology context only. It is not record authority, a mutation path, permission, or gate. Actual signed project scope remains owned by this skill. Contract selection and clause interpretation remain outside the corpus boundary; use its bounded refusal and official-source orientation instead.

## `/as:agreement promote`

Use this command when the user wants a protected project-local proposal to seed agreement context. It is not a mandatory stage in the project lifecycle.

1. Resolve the project and proposal path. Require lifecycle status `accepted` and verify its issued-terms checksum. If the status is not accepted or the checksum is absent or invalid, stop; do not replace or relabel the proposal.
2. The helper refuses a second promotion when `agreement/AGREEMENT.md` already exists; use an amendment or user-directed edit instead.
3. Preview `agreement/AGREEMENT.md`, `agreement/sow/`, and the exact proposal path/checksum citation. One confirmation gate.
4. Run `promote <project-root> <project-relative-proposal-path> <date>`. The helper reads the project name and proposal metadata rather than duplicating user input.
5. Extract contract facts and scope from the cited terms through previewed edits: Identity and Terms values each cite their document/date; scope bullets live under exactly `### In scope`, `### Not in scope`, and `### Requires SOW` and cite the source section.
6. Offer one previewed line for project instructions, when useful: "Read `agreement/AGREEMENT.md` before committing to new work; flag out-of-scope requests." Do not add it automatically.
7. Re-read and verify the agreement plus proposal checksum. Report exact paths. Invoicing remains a separate user-directed action; no follow-up is required.

## `/as:agreement init`

Use this command for a direct engagement without a proposal. Resolve the project, preview `agreement/AGREEMENT.md` and `agreement/sow/`, and use one confirmation gate. Run `init <project-root> <date>`, then populate only user-supplied or governing-document facts with their source and date. The agreement records `—` for proposal path, checksum, and status; it does not create a proposal or infer proposal acceptance. Re-read and verify the agreement after creation.

## `/as:agreement check`

Read-only. Slice the three scope sections, classify the described work, and answer with the typed verdict plus the exact governing bullets. When no bullet governs, say so and use `needs-SOW` as an advisory classification. It never blocks, and the user always decides whether and how to proceed.

## `/as:agreement amend`

1. Gather the amendment: what changes, effective date, and the document drafted from `templates/amendment.md` or supplied by the user. Place it in `agreement/sow/` only after preview and confirmation.
2. Preview the Amendments row and any sourced Terms/Scope updates. One gate.
3. Run `record-amendment <project-root> <file-name> <summary> <date>`, apply the confirmed fact edits, re-read, and report. Preserve prior source citations.

## `/as:agreement status`

Read-only. Report the cited proposal path/checksum and recorded source status, term position, fee terms, amendment count, and open TO CONFIRM slots. When `INVOICES.md` exists, run `<plugin-root>/skills/invoice/scripts/invoice-ledger.sh status <project-root>` read-only with the already resolved project root and relay its numbers — never recompute them.

## `/as:agreement verify`

Run `agreement-workspace.sh verify <project-root>`. Report missing headings/documents and invalid or mismatched proposal citations verbatim. Never repair automatically.

## Typed record handoffs

- Proposal lifecycle and protected terms belong to `/as:proposal`.
- The invoice ledger belongs to `/as:invoice`; agreement status only relays its numbers.
- Facts worth adding to `PROJECT.md` go through `/as:project`.
- Work items become tasks only through `/as:tasklist`.

## Collaboration and harness boundary

Structured questions and cross-skill invocation are enhancements. When unavailable, preserve completed work and print the exact follow-up path or command. A harness permission prompt is a separate security boundary, never a reason to add another conversational confirmation.
