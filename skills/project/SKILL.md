---
name: project
description: Create or maintain a universal Architecture Studio project — initialize internal or client work, remember sourced facts, capture or supersede decisions, inspect project status, or migrate an older PROJECT.md to format 3. Use when the user says “set up the project,” “remember this,” “we decided,” asks about project context, or runs /as:project.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:project — Project Setup and Memory

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:project` is the only project-memory interface. It owns current facts in `PROJECT.md` and durable reasoning in `decisions/*.md` without combining those record types or duplicating a decision index.

## Commands

```text
/as:project init
/as:project status
/as:project update
/as:project remember <information>
/as:project decisions
/as:project record-decision <choice>
/as:project supersede <number>
/as:project migrate
```

## Hard boundaries

1. `PROJECT.md` contains sourced current facts. Decision identity, status, rationale, and history live only in `decisions/*.md`.
2. `PROJECT.md` links to `decisions/` but has no Decisions table and never copies decision metadata.
3. Never write `STUDIO.md`. `/as:studio` alone owns the manifest.
4. Never create a nested project beneath an existing `PROJECT.md`.
5. Every durable mutation is previewed and requires affirmative confirmation.
6. Preserve malformed records. A parse failure means unknown, not absent or approved.
7. Use project-relative links; never persist machine-specific absolute paths.
8. A project’s immutable ID and directory are the same uppercase `YYYY-MM-CCC-PROJECT-NAME` value. Keep the display name in normal case.
9. Project type (`internal` or `client`) and status are advisory context. Neither makes a valid project invisible or blocks a user-confirmed action.

## Resolve the project root

Run `<plugin-root>/skills/project/scripts/resolve-context.sh` from the current or explicitly supplied directory and follow `references/context-resolution.md`. `PROJECT.md` is the only implicit project boundary. A nearer project inside a monorepo wins over outer repository metadata; typed-record directories, task/time files, Claude instructions, git roots, and the current directory never establish a project. Stop on `invalid`; use the validated picker for `studio-picker`; and never write before one exact project is resolved.

## `/as:project init`

1. If the current path resolves an existing `PROJECT.md`, show status and do not create a nested project.
2. If a `STUDIO.md` is resolved, route creation to `/as:studio create-project`. Do not mutate the studio manifest and do not call back recursively after `/as:studio` has begun its confirmed orchestration.
3. Outside a studio, ask whether to initialize a studio or create a standalone project. Standalone creation requires explicit confirmation.
4. Gather the normal-case project display name, type (`internal` or `client`), current status, and a confirmed three-letter uppercase code. Client work uses its client code. Internal work uses the studio's own code or another user-confirmed internal code and may record the client as `—`; never substitute a reserved code. Keep the Project and Client fields distinct: when the user gives “client SOM, project Strategy consulting,” the project display name is `Strategy consulting`. Do not prefix the project display name or project-name slug with the client name merely because Client is recorded separately. Do not require client, site, zoning, program, code, proposal, agreement, or invoice facts that are irrelevant to the project.
5. Build the permanent ID as `YYYY-MM-CCC-PROJECT-NAME`, using the creation month, confirmed code, and an uppercase ASCII kebab slug. The exact directory basename equals that ID. On collision, preview a meaningful user-confirmed disambiguator; never overwrite, silently suffix, renumber, or later rename the ID because a display name, client, or status changes.
6. Preview the exact path, identity fields, and full bundle. State that no git repository, ALPA account, or cloud service will be created.
7. After confirmation, run `<plugin-root>/skills/project/scripts/project-workspace.sh init <target> <name> <project-id> <internal|client> <status> <client-code> <client> project` and verify every file and directory. Standalone projects always use a project-local task register; portfolio mode belongs to a studio.
8. `PROJECT.md` starts with universal identity and record links. Add the optional `Site`, `Zoning`, `Program`, or `Code` sections only when relevant; they are not a separate project type and are not required scaffolding for internal work.
9. Report the exact created path plus the `.agents/skills/` (Codex) and `.claude/skills/` (Claude Code) extension paths. Explain that the active harness should be restarted from the intended project directory if new project-only skills are not visible.

## `/as:project status`

Read `PROJECT.md`, report its project type and status as advisory context, scan `decisions/*.md` directly, and summarize known facts, record counts, decision statuses, open tasks, and recent dated records. Resolve prospective, active, on-hold, lost, withdrawn, completed, and archived projects alike. An unusual status may produce a warning but never blocks a confirmed action. When `agreement/AGREEMENT.md` exists, also report the agreement term (Effective date → Term end) and, when `INVOICES.md` exists, relay cap consumption from the invoice skill's status script read-only — never recompute its numbers. If an owning `STUDIO.md` declares portfolio task mode, read open tasks for this Project ID from the studio-root register; otherwise read the project register. Report duplicate decision numbers or malformed files. Do not consult or create a decision index.

## Facts: `update` and `remember`

Every fact has a value, source, and date. Update an existing fact in place; append only genuinely new facts to the correct section. Git or the file-sharing system preserves history.

For `/as:project remember` or a natural memory request:

1. Read the exact input and relevant project records.
2. Classify each item as fact-like, decision-like, or mixed:
   - fact-like states a current, sourceable project condition;
   - decision-like expresses a choice, selection, rejection, approval, or rationale;
   - mixed contains separable facts and choices.
3. Preview grouped destinations. Facts show the `PROJECT.md` section, value, source, and date. Decisions show the proposed decision record.
4. Ask which grouped changes to apply. Confirmation of a source record is not authorization to promote every candidate.
5. Write only selected items, then re-read and verify.

When importing a selected item from minutes or a site report, require its exact project-relative path and stable item label. Read it and preserve its epistemic status. Reported, discussed, interpreted, proposed, or uncertain content cannot silently become a verified fact.

## Decisions

### `/as:project decisions`

Discover `decisions/*.md` independently. Report number, title, status, and path for each parseable record, plus duplicate numbers, missing/unrecognized statuses, and malformed files. Filenames and files are canonical; no `PROJECT.md` table participates.

### `/as:project record-decision`

1. Scan every decision filename. Allocate max parseable number + 1, zero-padded to four digits; never reuse a number because another record is malformed.
2. Capture one choice per record: context, at least two honestly stated options, status (`proposed` or `decided`), deciders, the call, consequences, and source links. Pull from conversation first and ask one grouped question only for missing pieces.
3. A proposed source item remains proposed unless the user affirmatively says the choice was made.
4. Preview the complete record and collision-free path. Wait for confirmation.
5. Write `decisions/NNNN-slug.md`, re-read it, and verify number, status, title, and backlinks. Do not update `PROJECT.md` with decision metadata.

### `/as:project supersede <number>`

1. Resolve exactly one parseable decided record. Stop on missing, ambiguous, malformed, or already-superseded records.
2. Allocate a replacement normally. Preview the complete new record and the old record’s single status change together.
3. After confirmation, create and verify the replacement first; only then change the old status to `superseded by NNNN` and verify both cross-links.
4. On a later failure, preserve the verified replacement, report the exact partial state, and offer recovery against those records. Never allocate another replacement number for recovery.

## `/as:project migrate`

Migration removes the legacy Decisions table only when it is lossless, and upgrades the project/studio identity contract to format version 3:

1. If the project belongs to a studio, route to the studio-owned migration so `STUDIO.md`, folder identities, and known structured references change in one recoverable transaction. Standalone migration uses the project helper directly.
2. Ask the user to confirm the display name, created month/date, client code, client, type, and status. Never infer missing identity facts from tasks, time, commits, or other activity.
3. Read `PROJECT.md` and discover all decision files. Parse every legacy Decisions row conservatively and match it to exactly one decision file by number plus compatible identity/status. Missing files, duplicate numbers, malformed rows, or status disagreements block mutation.
4. Preview the complete old-to-new manifest, including the uppercase ID/directory rename, format and identity rows, legacy Decisions replacement when present, recognized generated version-2 `CLAUDE.md` replacement with the canonical `@AGENTS.md` import, studio registry row, known structured references such as the Project ID column in portfolio `TASKS.md`, and any studio-wide proposal records moving into project-local date/title/revision files. Preserve former proposal numbers only as legacy metadata. A custom `CLAUDE.md` blocks mutation until the user separately reviews and confirms how its Claude-specific content should be preserved. Report possible prose references without rewriting them.
5. Back up only the confirmed files and directories, apply the manifest, then verify the format, exact directory/ID match, registry identity, structured Project ID fields, and unchanged durable decision/meeting/site-report/plan content. If any required mutation or verification fails, restore the confirmed backup rather than leaving a partial migration.
6. For a standalone project, first check for the valid version-2 standalone ownership shape: a root `PROPOSALS.md` with files under `proposals/`. The project-only helper cannot safely convert that commercial register, so it stops before mutation and directs the user to a separately confirmed studio-owned migration rather than stranding it. Otherwise run `<plugin-root>/skills/project/scripts/project-workspace.sh migrate <root> <project-id> <name> <internal|client> <status> <client-code> <client> <created> --apply` only after confirmation. A studio migration uses `<plugin-root>/skills/studio/scripts/studio-workspace.sh migrate <studio-root> <confirmed-manifest.tsv> --apply`.
7. A matching format-version-3 project reports “already migrated” without mutation.

## Typed record handoffs

- Minutes and site reports may propose selected facts or decisions; `/as:project` re-reads and confirms them.
- `/as:workplan` reads facts and decision files but writes only its plan.
- `/as:tasklist` owns task rows in the canonical project or portfolio `TASKS.md`; `/as:studio` alone owns the studio task-mode setting; `/as:timetracker` owns `TIMELOG.md`.
- Project registration and status mutation belong to `/as:studio`, not `/as:project`.
- `/as:proposal` owns project-local `proposals/`; `/as:agreement` owns `agreement/`; `/as:invoice` owns `INVOICES.md`. These links appear in `PROJECT.md` only when the corresponding records exist.

## Collaboration and harness boundary

These are plain local files shared however the project already is. This local plugin creates no ALPA account or server. Cross-skill invocation and structured questions are enhancements; when unavailable, preserve completed work and print the exact follow-up command.
