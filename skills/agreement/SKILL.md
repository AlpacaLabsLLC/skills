---
name: agreement
description: Turn an accepted proposal into contract context and guard work against it — promote an accepted proposal into an append-only agreement record, check a request against the contract's scope, record SOWs and amendments, and report term and budget status. Use for "is this in scope", "check against the contract", "record this SOW", scope-creep questions, or after /as:proposal accept.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:agreement — Contract Context and Scope Guard

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:agreement` owns each project's `agreement/` directory: the accepted proposal, its SOWs and amendments, and `AGREEMENT.md` — sourced contract facts plus the scope blocks that day-to-day work is checked against.

## Commands

```text
/as:agreement promote <number>
/as:agreement check <request>
/as:agreement amend
/as:agreement status
/as:agreement verify
```

## Hard rules

1. **One writer.** `/as:agreement` is the only writer of `agreement/`. It never writes `PROPOSALS.md` (status changes belong to `/as:proposal`), `PROJECT.md`, `INVOICES.md`, `STUDIO.md`, `decisions/`, tasks, or time records.
2. **Accepted documents are append-only.** The promoted proposal, SOWs, and amendments are never edited, overwritten, or deleted; a change is a new dated amendment document plus a new Amendments row.
3. **Facts cite their document.** Every `AGREEMENT.md` value carries the governing document and date. Unknown stays blank — never inferred, never invented.
4. **Verdicts are advisory.** `check` classifies work as `in-scope`, `needs-SOW`, or `out-of-scope`, quoting the governing scope bullets. It informs; it never blocks, and the user always decides.
5. **Script-mediated mutation.** Directory scaffolding and Amendments-table writes run through `<skill-root>/scripts/agreement-workspace.sh` after a preview and one confirmation gate; fact and scope edits to `AGREEMENT.md` are previewed Edits confirmed in the same flow.
6. **Malformed means blocked, not empty.** An `AGREEMENT.md` that fails format validation blocks mutation and is preserved byte-for-byte.

## Resolve the project

Run the shared resolver at `<plugin-root>/skills/project/scripts/resolve-context.sh` and follow `skills/project/references/context-resolution.md`. `agreement/` always lives at the project root; the proposal register lives at the root the resolver establishes for `/as:proposal`.

## `/as:agreement promote`

1. Resolve the project and register root. The proposal must be registered `accepted` — the script refuses anything else, and refuses a second promotion (amend instead).
2. Preview: the exact files (`agreement/AGREEMENT.md`, the copied accepted document, `agreement/sow/`) and the register row it reads. One gate.
3. Run `promote <project-root> <register-root> <number> <accepted-path> <project-name> <date>`.
4. Extract contract facts and scope from the accepted document through previewed Edits: Identity and Terms values (each citing the document and date) and scope bullets under exactly `### In scope`, `### Not in scope`, and `### Requires SOW`, each bullet citing its source section.
5. Offer one previewed line for the project `CLAUDE.md` (skip if present): "Read `agreement/AGREEMENT.md` before committing to new work; flag out-of-scope requests."
6. Re-read everything, verify, report exact paths, and hand off: "Run `/as:invoice init` to set up the invoice ledger from these terms."

## `/as:agreement check`

Read-only. Slice the three scope H3 sections, classify the described work, and answer with the typed verdict plus the exact governing bullets quoted. When no bullet governs, say so and default the verdict to `needs-SOW` — silence in the contract is not permission. Suggest the follow-up (`/as:agreement amend` for a new SOW) without recording anything.

## `/as:agreement amend`

1. Gather the amendment: what changes, effective date, the document (drafted from `templates/amendment.md` or supplied by the user). Place the file in `agreement/sow/` via previewed Write.
2. Preview the Amendments row and any Terms/Scope fact updates it causes (new values cite the amendment). One gate.
3. Run `record-amendment <project-root> <file-name> <summary> <date>`, apply the fact Edits, re-read, and report. History is preserved — superseded values move to the row's Source citation, never erased.

## `/as:agreement status`

Read-only. Report: term position (Effective date → Term end), fee terms, cap consumption when `INVOICES.md` exists (run `<plugin-root>/skills/invoice/scripts/invoice-ledger.sh status` read-only and relay its numbers — never recompute them), amendment count, and open TO CONFIRM slots in the underlying documents.

## `/as:agreement verify`

Run `agreement-workspace.sh verify <project-root>` and report findings verbatim: missing headings, amendment rows whose file is gone. Never repair automatically.

## Typed record handoffs

- Proposal lifecycle (including acceptance) belongs to `/as:proposal`.
- The invoice ledger belongs to `/as:invoice`; `status` only relays its script's numbers.
- Facts worth `PROJECT.md` (client, term) go through `/as:project`.
- Work items surfaced by `check` become tasks only through `/as:tasklist`.

## Collaboration and harness boundary

Structured questions and cross-skill invocation are enhancements; when unavailable, preserve completed work and print the exact follow-up command. A harness permission prompt is a separate security boundary, never a reason to add another conversational confirmation.
