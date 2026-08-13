---
name: proposal
description: Create and track numbered fee proposals — draft, send, accept, decline, or supersede a proposal, quote, fee letter, or scope-of-services offer, with a studio-wide register and permanent numbering. Use when the user wants to propose work to a client, issue a quote, list proposals, or record a proposal's outcome. Acceptance hands off to /as:agreement.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:proposal — Numbered Fee Proposals

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:proposal` owns the proposal register (`PROPOSALS.md`) and every registered `proposals/` directory. It creates numbered proposal documents, tracks their lifecycle, and hands accepted proposals to `/as:agreement`.

## Commands

```text
/as:proposal create
/as:proposal list
/as:proposal status <number>
/as:proposal send <number>
/as:proposal accept <number>
/as:proposal decline <number>
/as:proposal supersede <number>
/as:proposal verify
```

## Hard rules

1. **One writer.** `/as:proposal` is the only writer of `PROPOSALS.md` and of registered `proposals/` directories. It never writes `STUDIO.md`, `PROJECT.md`, `decisions/`, `agreement/`, `INVOICES.md`, tasks, or time records.
2. **Permanent identity.** Numbers are `{PREFIX}-{NNNN}`, allocated as max parseable number + 1, zero-padded to four digits. Numbers are never reused or renumbered; a replaced proposal is `superseded by {PREFIX}-{NNNN}`, never deleted.
3. **One register at the resolved root.** Run the shared resolver at `<plugin-root>/skills/project/scripts/resolve-context.sh` and follow `skills/project/references/context-resolution.md`. When a studio resolves, the register is `<studio-root>/PROPOSALS.md` and proposal files live in `projects/<folder>/proposals/`; for a standalone project, the register is `<project-root>/PROPOSALS.md` and files live in `proposals/`. Never reimplement resolution or maintain a second register.
4. **Script-mediated mutation.** Every register or file mutation runs through `<skill-root>/scripts/proposal-register.sh` after a preview and one confirmation gate. After the script runs, re-read the register and report exact paths.
5. **Malformed means blocked, not empty.** A register that fails format or prefix validation blocks mutation and is preserved byte-for-byte; report the problem instead of fixing it silently.
6. **Legal caution is mandatory.** Any assembled terms and conditions carry this sentence verbatim: "These clauses are drafting guidance, not legal advice; have a licensed attorney review before signing."
7. **Files are canonical.** The register row is the allocation and status ledger; the proposal document is the content record. Neither is duplicated into `PROJECT.md`; facts worth promoting go through `/as:project`.

## Resolve the register root

Run the shared resolver from the current directory. `project` verdict inside a studio → the studio root holds the register; standalone `project` verdict → the project root; `studio-picker` → require a selection before writing; `no-context` or `invalid` → stop and report. The register root and the owning project decide where the proposal file lives.

## `/as:proposal create`

1. Resolve the register root and owning project. Gather client, title, and issue date from the conversation; ask one grouped question only for missing pieces. Derive a lowercase kebab-case slug from the title.
2. If no `PROPOSALS.md` exists at the root, this is first use: propose a prefix (2–6 uppercase letters/digits, defaulting from the studio or project name) and include register creation in the same single gate as the first proposal — one gate covers both.
3. Preview the allocated number (via `proposal-register.sh allocate` when the register exists), the exact file path, and the register row. Wait for confirmation.
4. Run `init` (first use only), then `create <root> <relative-proposals-dir> <project-id> <client> <title> <slug> <date>`. The script scaffolds the document from the bundled template with `> **[TO CONFIRM: …]**` slots and registers it as `draft`.
5. Fill remaining content — scope of services, fees, terms assembled from `references/tc-library.md` — through previewed Edits to the proposal file. Unknown values stay as TO CONFIRM slots; never invent terms.
6. Re-read the register, verify the row and file, and report both exact paths. For a client-facing letter, offer to render `templates/proposal-letter.html` from the markdown record; the register always points at the `.md`.

## `/as:proposal list` and `status`

Read-only. `list` prints the register rows, optionally filtered by project or status, and flags drift (rows whose file is missing) without fixing it. `status <number>` shows the row plus the document's TO CONFIRM slots still open.

## `/as:proposal send`, `decline`

Preview the status transition, confirm once, run `set-status <root> <number> <sent|declined>`, re-read, and report. `send` is also the moment to remind the user of open TO CONFIRM slots — sending with unresolved slots requires an explicit acknowledgment in the same gate.

## `/as:proposal accept`

1. Gather acceptance evidence: date, who accepted, and how (signature, email, e-signature envelope). Ask once if missing.
2. Preview: the status transition and an Acceptance-section addendum on the proposal document recording date/who/how. One gate.
3. Run `set-status <root> <number> accepted`, apply the previewed Edit to the document, re-read both, and report.
4. Hand off: "Run `/as:agreement promote <number>`."

## `/as:proposal supersede`

A superseded proposal needs a successor. Create the replacement first (normal `create` flow), then preview and run `set-status <root> <number> superseded <successor>`. The old document is never edited or deleted.

## `/as:proposal verify`

Run `proposal-register.sh verify <root>` and report its findings verbatim: missing files, unknown statuses, unsafe paths. Never repair automatically; propose fixes as previewed follow-ups.

## Typed record handoffs

- Accepted proposals become contract context through `/as:agreement promote`; `/as:proposal` never writes `agreement/`.
- Invoicing against an accepted proposal belongs to `/as:invoice`.
- Facts worth `PROJECT.md` (client identity, engagement term) go through `/as:project`.

## Collaboration and harness boundary

Structured questions and cross-skill invocation are enhancements; when unavailable, preserve completed work and print the exact follow-up command. A harness permission prompt is a separate security boundary, never a reason to add another conversational confirmation.
