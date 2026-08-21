# Universal projects and commercial records

**Status:** proposed · **Target:** undecided, after the current release · **Author:** ALPA · **Revised:** 2026-08-19

Architecture Studio will use one durable entity for every bounded body of studio work: the **project**. A project begins when the studio starts tracking meaningful work, whether that work is internal, prospective, or commissioned. It keeps one identity for its entire life.

Commercial records live inside the project that produced them: **proposal → agreement → invoices**. Winning work changes the project's status and adds agreement context; it does not create a second entity, allocate a second ID, or move the project.

This plan replaces the separate initiative/pursuit/project proposal and revises the earlier commercial-records plan. There will be no initiative registry, pursuit registry, pursuit-to-project conversion, or studio-wide proposal register.

## Goals

1. Give internal work, prospective work, and commissioned work one consistent home.
2. Keep the commercial history of a project inside that project.
3. Preserve one permanent, human-readable project identity from first work through closure.
4. Expose project type and status as useful context without using either to infer billability or block user-directed work.
5. Keep filesystem conventions obvious to people and reliable for tools.

## Design principles

- One universal entity: a project is a durable container for bounded studio work.
- One identity for life: a project is never replaced or renumbered when its commercial status changes.
- Typed records have one canonical home and one writer; duplicate indexes are avoided.
- `/as:studio` remains the sole writer of `STUDIO.md`.
- Every durable mutation is previewed and confirmed.
- Money, billability, payment, and acceptance are never inferred from activity.
- The software enforces record integrity, not business discipline. It prevents ambiguity, malformed mutation, accidental overwrite, and silent alteration of accepted terms; project status and commercial sequencing remain advisory context under user control.
- The format remains neutral across Claude Code and Codex.

## Universal project model

Projects cover three ordinary situations without becoming three entities:

| Situation | Type | Typical status | Commercial records |
|---|---|---|---|
| Studio-funded work | `internal` | `active`, `on-hold`, `completed`, `archived` | None required |
| Opportunity being pursued | `client` | `prospective` | Proposals |
| Commissioned client work | `client` | `active`, `on-hold`, `completed`, `archived` | Agreement and invoices as applicable |

Client work may also close as `lost` or `withdrawn`. Those projects remain in the registry as durable win/loss history.

The type and status are classifications on a project, not entities with separate identities or folders. A client project normally moves through:

```text
prospective → active → completed → archived
            ↘ lost
            ↘ withdrawn
```

The diagram describes a common path, not an enforced transition graph. Status is a user-owned fact: skills may suggest a likely update and warn when an action looks unusual, but they do not prevent the user from continuing. Direct engagements may begin as `active` without first recording a proposal.

## Project identity and naming

The project ID and directory name use one permanent, uppercase, filesystem-safe format:

```text
YYYY-MM-CCC-PROJECT-NAME
```

Example:

```text
2026-08-TGS-SECONDARY-SCHOOL
```

Rules:

1. `YYYY-MM` is the month in which the studio first creates the project record. It is not the agreement date and never changes.
2. `CCC` is a studio-assigned, three-letter uppercase client code. Internal work uses the studio's own code, such as `ALP`.
3. `PROJECT-NAME` is an uppercase kebab-case slug derived from the user-facing project name.
4. Only ASCII letters, digits, and hyphens are allowed in the ID.
5. The full ID is immutable even if the client or display name later changes.
6. A collision must be resolved during the creation preview with a meaningful disambiguator; the skill never silently overwrites or reuses an ID.

The display name in `PROJECT.md` keeps normal capitalization. The uppercase format applies to the permanent ID and directory, not to prose.

Date-first naming makes ordinary filesystem sorting chronological. Client grouping remains available from `STUDIO.md` and project search.

## File and directory casing

Canonical singleton records use uppercase filenames:

```text
PROJECT.md
TASKS.md
TIMELOG.md
INVOICES.md
AGENTS.md
CLAUDE.md
agreement/AGREEMENT.md
```

Project instructions use one canonical source rather than duplicated files:

- `AGENTS.md` contains the shared project instructions and is read directly by Codex.
- `CLAUDE.md` exists because Claude Code does not load `AGENTS.md` automatically. It imports
  the canonical file with `@AGENTS.md` and contains only Claude-specific additions, if any.
- Template and migration code must not maintain a second copy of shared instructions in
  `CLAUDE.md`.

The default `CLAUDE.md` is therefore:

```markdown
@AGENTS.md

## Claude Code

<!-- Claude-specific instructions, if any -->
```

Record collections use lowercase kebab-case directories:

```text
proposals/
agreement/
agreement/sow/
decisions/
meetings/
site-reports/
docs/plans/
```

Individual records use lowercase kebab-case filenames, normally prefixed with an ISO date or a permanent local sequence:

```text
proposals/2026-08-design-services-proposal-rev-01.md
agreement/sow/2026-09-additional-services.md
decisions/0001-use-mass-timber.md
meetings/2026-08-19-client-kickoff.md
site-reports/2026-09-03-foundation-inspection.md
```

## Workspace layout

```text
studio-root/
├── STUDIO.md
└── projects/
    └── 2026-08-TGS-SECONDARY-SCHOOL/
        ├── PROJECT.md
        ├── TASKS.md
        ├── TIMELOG.md
        ├── AGENTS.md
        ├── CLAUDE.md
        ├── proposals/
        │   └── 2026-08-design-services-proposal-rev-01.md
        ├── agreement/
        │   ├── AGREEMENT.md
        │   └── sow/
        │       └── 2026-09-additional-services.md
        ├── INVOICES.md
        ├── decisions/
        ├── meetings/
        ├── site-reports/
        └── docs/plans/
```

Directories and records are created only when relevant. An internal project does not need empty proposal, agreement, or invoice records. A prospective project may have proposals without an agreement. `INVOICES.md` is initialized only when the user is ready to invoice against agreement terms or explicit billing instructions.

## Studio registry

`STUDIO.md` keeps one Projects table. It does not gain Initiative or Pursuit tables.

```markdown
| Project ID | Project | Client | Code | Type | Status | Folder | Opened |
|---|---|---|---|---|---|---|---|
| 2026-08-TGS-SECONDARY-SCHOOL | TGS Secondary School | The Garzón School | TGS | client | active | projects/2026-08-TGS-SECONDARY-SCHOOL | 2026-08-19 |
| 2026-08-ALP-ARCHITECTURE-STUDIO | Architecture Studio | — | ALP | internal | active | projects/2026-08-ALP-ARCHITECTURE-STUDIO | 2026-08-19 |
```

`/as:studio` remains the only writer. It creates projects, validates the naming convention, updates status, and preserves closed rows. The registry is the source for client, type, status, and chronological views; it is not a second copy of project content.

`STUDIO.md` and `PROJECT.md` move to format version 3. Existing version-2 skills already reject unknown versions; the explicit bump makes an older installation stop clearly rather than interpret the redesigned columns as the old schema.

Before changing the table shape, every registry reader must be bounded by the existing `<!-- projects:start -->` markers and address columns by header rather than fixed position. The current position-based, table-agnostic parser cannot safely accept new columns.

The shared resolver becomes status-neutral. It resolves any valid, uniquely registered project and returns its type and status as context. Individual skills may show contextual warnings, but status alone never makes a valid project invisible or prevents a user-confirmed action.

## Project record

`PROJECT.md` becomes usable for every project type:

- Identity always includes format version, project ID, display name, type, status, created date, client code, and client when applicable.
- AEC-specific sections such as Site, Zoning, Program, and Code remain available to architectural projects but are optional rather than required scaffolding for internal work.
- Commercial links appear only when the corresponding records exist.
- `PROJECT.md` does not duplicate proposal, agreement, invoice, decision, task, or time-register contents.

## Commercial record flow

### Proposal

`/as:proposal` owns each project's `proposals/` directory.

- A proposal belongs to exactly one project and uses a project-local lowercase filename: `YYYY-MM-SHORT-TITLE-proposal-rev-NN.md`. The human-facing revision is `Rev. NN`.
- There is no studio-wide `PROPOSALS.md` and no permanent firm-wide proposal number.
- Proposal identity, revision, issue date, and lifecycle (`draft`, `sent`, `accepted`, `declined`, `superseded`) live in the proposal record itself.
- The generated filename is a default, not a business identifier. If the proposed path already exists, the skill previews the collision and asks the user for a different short title or filename; it never overwrites the existing record or introduces another number sequence.
- `list` and `status` discover proposal files directly and report malformed or conflicting records without creating a duplicate index.
- `send` seals the issued commercial-content block with a SHA-256 checksum. Lifecycle events may be appended outside that block, but issued scope, fees, schedule, exclusions, and conditions cannot change in place; changes require a new revision.
- `accept` verifies the issued-content checksum, records who accepted, how, and when, then may suggest agreement or project-status actions. Those handoffs are optional and resumable, not a required commercial workflow.
- Templates remain neutral and may be overridden by a studio.

### Agreement

`/as:agreement` owns each project's `agreement/` directory.

- `promote` uses an accepted proposal in the same project when the user chooses to create agreement context from it.
- The accepted proposal remains canonical in `proposals/`; `AGREEMENT.md` cites its project-relative path and issued-content checksum rather than copying or moving it.
- `AGREEMENT.md` records sourced parties, term, fees, caps, invoicing terms, IP terms, and advisory scope blocks: In scope, Not in scope, and Requires SOW.
- Signed agreements, SOWs, and amendments are append-only records under `agreement/`.
- `check` classifies proposed work against the scope blocks and reports `in-scope`, `needs-SOW`, or `out-of-scope`. The result is advisory; the user decides.
- `amend` adds a new append-only record and updates sourced current facts without rewriting history.

Accepting a proposal does not automatically change project status, create agreement context, create a new project, change the project ID, or move the directory. The skill reports useful next actions and leaves the sequence to the user.

### Invoice

`/as:invoice` owns the project's `INVOICES.md`.

- `record` appends user-supplied or agreement-derived invoice facts: external invoice number, period, base, expenses, total, sent date, paid date, and status.
- `status` computes running totals, outstanding amounts, cap consumption, warnings, and billing-period gaps from the ledger.
- `reconcile` is user-driven and never asserts that payment occurred without evidence.
- No amount, billability, payment status, or completion status is inferred from `TIMELOG.md`, tasks, commits, or other activity.

## Scope-guard integration

- `/as:tasklist` and `/as:workplan` consult `agreement/AGREEMENT.md` when it exists and surface `needs-SOW` or `out-of-scope` findings before recording work.
- Project status and scope guards are advisory. A closed or unusual status produces a clear preview warning, but never blocks the architect's confirmed decision.
- `/as:project status` reports project type/status and, when present, the agreement term and invoice cap consumption.
- Dispatcher routing sends proposal work to `/as:proposal`, agreement and scope questions to `/as:agreement`, and billing questions to `/as:invoice`.

## Ownership boundaries

1. `/as:studio` alone writes `STUDIO.md` and project registration/status fields.
2. `/as:project` alone writes sourced current facts in `PROJECT.md` and decision records in `decisions/`.
3. `/as:proposal` alone writes `proposals/`.
4. `/as:agreement` alone writes `agreement/`; signed documents and amendments are append-only.
5. `/as:invoice` alone writes `INVOICES.md`; recorded amounts are corrected by append-only entries rather than silent edits.
6. None of the commercial skills writes tasks, time records, or `STUDIO.md` directly; they may offer an optional status handoff to the owning skill.
7. Templates and clause guidance are not legal advice.

## Migration and compatibility

This is workspace format version 3 and must fail loudly against version-2 skills.

1. Build and preview an old-to-new manifest for every project ID, folder rename, structured reference, registry change, and record change before mutation.
2. Ask the user to confirm the client code, display name, and creation month for each existing project; never infer missing identity facts from activity.
3. Back up only the files and directories named in the confirmed manifest, then rename each project directory and set `Project ID` to the same immutable `YYYY-MM-CCC-PROJECT-NAME` value.
4. Classify each existing project as `internal` or `client` and confirm its status.
5. Rewrite known structured references owned by Architecture Studio, including registry paths, project IDs in portfolio tasks, and commercial-record paths. Report possible references in ordinary prose for the user to handle; never rewrite prose speculatively.
6. Preserve task, time, decision, meeting, site-report, and plan records in place during the directory rename.
7. Replace any studio-wide proposal register with project-local proposal metadata, preserving every proposal document, former number as legacy metadata, and lifecycle history.
8. Re-read and verify the studio registry, every project, and every known structured reference. If any required mutation or verification fails, restore the confirmed backup rather than leaving a partially migrated workspace.

There is no entity conversion migration. Internal work, opportunities, and commissioned work remain projects throughout.

## Implementation impact

| Area | Required change |
|---|---|
| Shared resolver | Resolve every valid registered project regardless of status; return type/status as advisory context; add coverage for every status |
| `/as:studio` | Header-keyed registry parser; new naming validation; create and update universal projects; preserve user-directed status and closed project history |
| `/as:project` | Format version 3; universal identity fields; optional AEC sections; recoverable migration; project ID equals directory name |
| `/as:proposal` | Remove studio-wide register and numbering; generate flexible collision-safe local filenames; seal issued terms; keep lifecycle metadata in each proposal |
| `/as:agreement` | Optionally promote from the same project's accepted proposal; cite its path and checksum rather than copy it; offer optional status handoff |
| `/as:invoice` | Remains project-local; initialize only when requested; retain deterministic ledger calculations |
| `/as:tasklist` | Accept every resolved project after confirmation; warn on unusual status; allow views filtered by type/status; retain advisory scope check |
| `/as:workplan` | Retain conditional agreement scope check |
| Tests and docs | Replace three-entity and global-proposal assumptions; add naming, lifecycle, migration, and casing contracts |

The current commercial-records branch is useful source work but does not yet match this plan. In particular, its studio-wide proposal register and numbering must be removed before release.

## Delivery sequence

1. Finalize the format-version-3 `PROJECT.md` and `STUDIO.md` contracts plus proposal metadata, `AGREEMENT.md`, and `INVOICES.md`.
2. Make registry parsing section-bounded and header-keyed before adding columns.
3. Implement project naming, status-neutral resolution, advisory type/status behavior, and recoverable migration.
4. Refactor proposal storage from studio-wide numbering to collision-safe project-local records with sealed issued terms.
5. Align agreement promotion and retain the invoice ledger and advisory scope guard.
6. Update integrations, documentation, fixtures, and contract tests; run lint and the full test suite.
7. Dogfood the migration in the ALPA studio before assigning a release number.

## Success criteria

- A studio can represent internal, prospective, active, lost, withdrawn, completed, and archived work without any entity other than a project.
- A project receives one permanent ID when first tracked and keeps it through every lifecycle change.
- Project directories sort chronologically and comply with the uppercase naming contract.
- Commercial records never leave their owning project and require no studio-wide proposal index.
- Winning or losing work requires no folder move, second ID, or entity conversion.
- Internal projects do not require irrelevant client, site, zoning, agreement, or invoice data.
- Project status and the presence or absence of commercial records never prevent a user-confirmed action.
- Accepted proposal terms are tamper-evident and change only through a new revision, SOW, or amendment.
- Existing durable records survive migration unchanged except for previewed identity/path references.
- Scope guidance remains advisory, and financial facts are never inferred from activity.
- Older-format workspaces fail loudly until migrated.

## Explicitly excluded

- Separate initiative and pursuit entities, registries, directories, and IDs.
- Pursuit-to-project conversion or folder movement.
- Firm-wide numbering for proposals or other project outputs.
- Client folder tiers or a new client entity.
- Automatic billability classification or invoice generation from activity.
- External-source alias resolution, private-git policy, and large-file hooks from the prior v3 exploration; these may be considered separately if real use justifies them.
- A per-time-entry billable field; it remains a separate future decision.

## Decisions settled in this revision

- **One universal project entity.** Internal work and pursuits are project classifications, not separate entities.
- **Commercial records live inside projects.** No studio-wide proposal register or number sequence.
- **One permanent project identity.** Winning work changes status, not identity or location.
- **Date-first project naming.** `YYYY-MM-CCC-PROJECT-NAME`, uppercase and immutable.
- **Tiered file casing.** Canonical singleton records are uppercase; directories and individual records use lowercase kebab case.
- **User responsibility over workflow enforcement.** Skills surface context, warnings, and optional handoffs; they do not require a proposal/agreement/invoice sequence or police project status.
- **Integrity remains enforced.** Format boundaries, collision prevention, recoverable migration, and sealed accepted terms protect records without making business decisions.
- **Advisory scope guard.** The system informs; the architect confirms.
