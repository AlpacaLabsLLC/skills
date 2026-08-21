---
name: proposal
description: Create and maintain project-local fee proposals — draft, send, accept, decline, supersede, list, or verify a proposal, quote, fee letter, or scope-of-services offer. Use when the user wants to propose work to a client, issue a quote, or record a proposal outcome. Issued terms are checksum-protected and acceptance may hand off to /as:agreement.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:proposal — Project-local fee proposals

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:proposal` owns only project-local `proposals/`. Each proposal markdown file is its own canonical record; there is no studio-wide register, allocation ledger, permanent firm-wide number, or duplicate proposal summary in `PROJECT.md`.

## Commands

```text
/as:proposal create
/as:proposal list
/as:proposal status <project-relative proposal path>
/as:proposal send <project-relative proposal path>
/as:proposal accept <project-relative proposal path>
/as:proposal decline <project-relative proposal path>
/as:proposal supersede <project-relative proposal path>
/as:proposal verify
```

## Hard rules

1. **One writer.** `/as:proposal` is the only writer of project-local `proposals/`. It never writes `STUDIO.md`, `PROJECT.md`, `decisions/`, `agreement/`, `INVOICES.md`, tasks, time records, or project status.
2. **Local identity.** The normal filename is `YYYY-MM-SHORT-TITLE-proposal-rev-NN.md`: lowercase kebab-case short title, explicit local revision, no global number. Show the revision in documents as `Rev. NN` (`Rev. 01`, `Rev. 02`, and so on); use the filesystem-safe `rev-NN` token only in filenames and script arguments. The user chooses a new revision or clearer short title when a path collides; never overwrite, silently suffix, or infer that two differently named records are revisions of one another.
3. **Resolved project.** Run `<plugin-root>/skills/project/scripts/resolve-context.sh` and follow `skills/project/references/context-resolution.md`. A selected format-version-3 project is the only proposal root. Never reimplement resolution or make the studio root a proposal owner.
4. **Issued-term integrity.** The exact content between `<!-- issued-terms:start -->` and `<!-- issued-terms:end -->` is the proposal's terms. `send` records its SHA-256 checksum outside that block. Later lifecycle evidence stays outside the block; changing issued terms requires a new revision rather than replacing the checksum.
5. **User-owned workflow.** Type and status are context. The tool records the user's action and does not enforce a proposal → agreement → invoice sequence, project-status transition, or commercial-management policy. Acceptance can freeze a draft directly when an earlier send was not recorded.
6. **Malformed means preserved.** Marker, metadata, filename, or checksum failures block script mutation and are reported without repair. The user decides the correction.
7. **Legal caution is mandatory.** Any assembled terms and conditions carry this sentence verbatim: "These clauses are drafting guidance, not legal advice; have a licensed attorney review before signing."

## Resolve the project

Run the shared resolver from the current directory. `project` uses its returned project root, type, and status; `studio-picker` requires the user to choose one returned project before writing; `no-projects`, `no-context`, or `invalid` stops proposal work. Do not filter by status. An archived, lost, prospective, internal, or otherwise unusual project may merit a short warning, but a valid selected project remains usable.

## `/as:proposal create`

1. Gather the client, normal-case title, proposal date, short lowercase kebab title, and explicit local revision. Suggest `Rev. 01` for a new proposal series, but do not assume lineage merely because another proposal exists.
2. Build `proposals/YYYY-MM-SHORT-TITLE-proposal-rev-NN.md`. If it exists, stop and ask the user whether this is a new revision or a distinct proposal with another short title.
3. Preview the exact path and initial issued-terms template, then wait for one confirmation.
4. Run `<skill-root>/scripts/proposal-workspace.sh create <project-root> <client> <title> <short-title> <date> <rev-NN>`.
5. Fill scope, fees, exclusions, payment terms, and selected clauses from `references/tc-library.md` through previewed edits. Unknowns remain TO CONFIRM; do not invent them or block creation.
6. Re-read and report the exact project-relative path. For a client-facing HTML letter, prefer `<studio-root>/standards/proposal-letter.html` when it exists; use the bundled `<skill-root>/templates/proposal-letter.html` as the fallback. Render from the markdown record and keep that markdown file canonical.

## `/as:proposal list` and `status`

Read-only. `list` discovers markdown records directly in the selected project's `proposals/` directory and may filter the returned rows conversationally. `status` reports metadata, lifecycle, open TO CONFIRM text, and checksum integrity. Neither command repairs or creates an index.

## `/as:proposal send`

1. Read the complete record and point out remaining TO CONFIRM text as context, without treating it as a software gate.
2. Preview the lifecycle event and checksum that will freeze the current issued terms. Confirm once.
3. Run `<skill-root>/scripts/proposal-workspace.sh send <proposal-file> <date> [actor] [evidence]`, re-read the record, and verify the stored SHA-256.
4. If an existing checksum no longer matches, stop. Preserve the issued record and create a new revision for changed terms.

## `/as:proposal accept`, `decline`, and `supersede`

Gather whatever date, actor, evidence, and related-path detail the user wants recorded; do not invent missing evidence or police the business sequence. Preview one lifecycle row and status update, then run:

```text
proposal-workspace.sh set-status <proposal-file> <accepted|declined|superseded|draft> <date> [actor] [evidence] [related-path]
```

`accept` verifies an existing issued checksum or freezes the current terms if no earlier send was recorded. Other lifecycle events preserve and verify any existing checksum. A successor is normally another project-relative proposal path, but the tool does not create it or require one automatically.

After acceptance, offer the optional handoff `agreement promote <project-relative proposal path>`. The agreement cites the proposal path and checksum; it does not copy the proposal. `/as:proposal` never changes project status.

## `/as:proposal verify`

Run `<skill-root>/scripts/proposal-workspace.sh verify <project-root>`. Report invalid filenames, metadata, marker boundaries, symlinks, and checksum mismatches verbatim. Do not repair or re-freeze a record automatically.

Format-version-2 studio migration is owned by `/as:studio`. It converts every registered global proposal into a project-local file, preserves the old document inside the protected terms, records the former firm-wide number as `Legacy number`, carries its lifecycle status, and checksums any issued record. The obsolete global register is removed only after the complete workspace transaction verifies; rollback restores it and the original files.

## Typed record handoffs

- `/as:agreement` may cite an accepted proposal by project-relative path and checksum, but either record remains independently owned.
- `/as:invoice` may use proposal context or explicit user direction; `/as:proposal` never authorizes or blocks billing.
- Facts worth adding to `PROJECT.md` go through `/as:project`.

## Collaboration and harness boundary

Structured questions and cross-skill invocation are enhancements. When unavailable, preserve completed work and print the exact follow-up path or command. A harness permission prompt is a separate security boundary, never a reason to add another conversational confirmation.
