---
name: studio
description: Architecture Studio control plane — initialize or inspect a studio workspace, create and register projects, or route an architecture/AEC task to the right agent or skill. Use when the user runs /as:studio, asks to set up or open their studio, manage its projects, or describes a task without naming a skill.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:studio — Studio Control Plane

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:studio` has two jobs that share one boundary: it owns the studio workspace and routes architecture work. It never performs delegated domain work itself.

## Welcome and no-argument behavior

When the user invokes `/as:studio` with no arguments, begin with this exact mark in a plain-text fence. Do not omit, abbreviate, or paraphrase it:

```text
 █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
███████║██████╔╝██║     ███████║    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
██║  ██║██║  ██║╚██████╗██║  ██║    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝
```

Immediately below the mark show this compact provenance block verbatim:

```text
Created by Federico Negro in 2026.
Author / owner: ALPA — https://alpa.llc (contact: hello@alpa.llc)
Copyright: © 2026 Alpaca Design Lab LLC, MIT-licensed
Repo: github.com/AlpacaLabsLLC/skills-for-architects (the "skills-for-architects" marketplace)
```

### Mandatory visible rendering

The mark and provenance are part of the visible welcome, not background context. Never use Bash or another tool to print or display the welcome; shell output may be collapsed by the harness.

- When a structured-question tool is available, its `question` field must begin with the exact mark above as raw text, without opening or closing Markdown fences. Immediately include the provenance block as raw text before `How would you like to start?`, and then present the host-appropriate choices below. The structured gate must be self-contained; do not rely on a preceding assistant preamble because the harness may suppress it when the gate opens.
- When `AskUserQuestion` is unavailable, the ordinary assistant response must begin with the same exact mark and provenance before asking once in natural language.
- Do not run a boundary search, shell command, file read, or any other tool before the branded welcome is visible. Resolve an existing studio only after displaying the welcome; if one is found, adapt the choices on the next interaction.

Keep the rest light. If a studio is already resolved, offer to open its status or create a project. Otherwise explain that the built-in tools are already available and that studio setup adds persistent settings, projects, and records. Branch on the active host before building the structured gate:

- **Claude Code:** present these four outcomes:
  1. **Set up a studio** — continue directly into `/as:studio init`; do not repeat the mark.
  2. **Use tools without setup** — end onboarding without mutation. State that this creates no files, preferences, or copied skills; point to `/as:tool-catalog` and representative direct commands; and say, “Run `/as:studio` later whenever you want persistent settings and project records.”
  3. **Learn with an example** — hand off to `/as:learn`.
  4. **Open an existing studio** — ask for or resolve its path, then show status.
- **Codex:** present these four outcomes:
  1. **Set up a studio** — continue directly into `$studio init`; do not repeat the mark.
  2. **Use tools without setup** — end onboarding without mutation. State that this creates no files, preferences, or copied skills; point to `$tool-catalog` and representative direct skills; and say, “Run `$studio` later whenever you want persistent settings and project records.”
  3. **Learn with an example** — hand off to `$learn`.
  4. **Open an existing studio** — ask for or resolve its path, then show status.

Tools-only use is not a stored mode. Built-in skills continue to run from the installed plugin, and the user can invoke `$studio` on Codex or `/as:studio` on Claude Code later without migration or cleanup. Never direct an ordinary user to download or copy the repository’s `skills/` directory.

### Single-gate rule

Never ask a setup or confirmation question twice. For the no-argument welcome, put the required branding and question together inside the structured gate as specified above. For later gates, give context or a preview without ending in a prose question, then open the structured gate immediately. The user’s answer to that gate is the answer; do not restate the question in chat. If the tool is unavailable, ask once in natural language. A later Claude Code permission prompt is a separate harness security boundary, not a reason to add another conversational confirmation.

## Commands

```text
# Codex
$studio init
$studio status
$studio projects
$studio create-project
$studio register-project <project folder>
$studio set-project-status <project id> <status>
$studio archive-project <project id>
$studio migrate <confirmed manifest>
$studio updates status
$studio updates enable
$studio updates disable
$studio tasks mode project|portfolio
$studio <describe an architecture task>

# Claude Code
/as:studio init
/as:studio status
/as:studio projects
/as:studio create-project
/as:studio register-project <project folder>
/as:studio set-project-status <project id> <status>
/as:studio archive-project <project id>
/as:studio migrate <confirmed manifest>
/as:studio updates status
/as:studio updates enable
/as:studio updates disable
/as:studio tasks mode project|portfolio
/as:studio <describe an architecture task>
```

## Hard boundaries

1. `STUDIO.md` marks the studio root. **Only `/as:studio` writes `STUDIO.md`.**
2. `PROJECT.md` marks a project root. Project facts and decision records belong to `/as:project`; `/as:studio` reads project identity for registration and verification and writes only the synchronized `Status` field during a confirmed status mutation.
3. The studio-root `.mcp.json` is the reserved connector manifest and is owned only by `/as:studio`. A project never receives or owns `.mcp.json`.
4. The installed Architecture Studio plugin cache is never a studio, project, or private-skill destination.
5. Never create a studio or project merely because the plugin was installed. Setup requires an exact-path preview and affirmative confirmation.
6. Never create a nested project inside a directory already containing `PROJECT.md`.
7. Registry paths are relative descendants below `projects/`; never persist arbitrary absolute project paths.
8. Every project directory equals its immutable uppercase `YYYY-MM-CCC-PROJECT-NAME` ID. The normal-case display name remains separate.
9. The Projects table is parsed only between `<!-- projects:start -->` and `<!-- projects:end -->` and every column is addressed by its header, never by a fixed position.
10. Firm-wide standards and reusable templates live in `standards/`; external material such as code references lives in `references/`. Project work and outputs remain in the owning directory under `projects/`.

## Resolve the studio and project boundaries

- Search upward for the nearest `STUDIO.md`; its parent is the studio root.
- Separately search upward for the nearest `PROJECT.md`; its parent is the current project root.
- A `STUDIO.md` is never a project marker and a `PROJECT.md` is never the studio manifest.
- If the current path is inside an existing project, `/as:studio init` must not initialize there and `create-project` must target the studio’s `projects/` directory.
- If multiple plausible boundaries genuinely conflict, show the candidates and ask one target question.

## Studio setup

### `/as:studio init`

1. If a `STUDIO.md` is already resolved, show status instead of overwriting it.
2. Determine whether the user wants to create a new studio through one gate only. Infer known answers, then use one compact structured question for the studio name, location, working units (`imperial`, `metric`, or `project-specific / mixed`), and default jurisdiction (country, state/region, city). Permit `No default` for any jurisdiction level; never invent one from the machine location. Do not first ask for these values in prose.
3. Explain the data boundary before confirmation: this local version stores studio and project records in the chosen local workspace; Architecture Studio does not send them to or store them with ALPA; content the user provides to the configured LLM is handled under that provider account and its data terms; future cloud-based versions may require an account and differ. Then branch on the active host:
   - **Claude Code:** background update checking is **disabled by default**. If no update preference exists, ask exactly, “Would you like this to automatically check for updates?” with `Yes, automatically check` / `Not now` choices in the setup gate. Enabling permits at most one bare request per 24 hours to ALPA's Cloudflare endpoint; it sends no project content or Architecture Studio identifier, though Cloudflare processes ordinary request metadata such as IP address, headers, and timestamps. Ask the user to acknowledge this note as part of setup confirmation.
   - **Codex:** background update checking is unavailable because this package does not install the Claude Code lifecycle hook. Do not ask for an update preference, resolve the update state directory, run `update-preference.sh`, or create an enablement marker.
4. Normalize the directory name to lowercase kebab-case. Reject empty names, `.`/`..`, absolute names supplied as names, separators inside names, control characters, reserved ambiguous names, existing files, and non-empty target directories.
5. Preview the display name, exact absolute target, units, jurisdiction, files created, and data-governance note. Explain that `standards/` is for firm-wide standards and reusable templates, `references/` is for external source material such as code references, and project work stays under `projects/`. State that setup does not initialize git, create an ALPA account, or configure cloud storage.
6. Open one confirmation gate covering the target, defaults, and data note. Do not ask for confirmation in prose before opening it and do not reconfirm after it returns.
7. Run `<skill-root>/scripts/studio-workspace.sh init <target> <studio-name> <working-units> <country> <state-region> <city>` with safely quoted arguments. Use the literal value `No default` for omitted jurisdiction levels. On Claude Code only, when the user selected enablement, run `<skill-root>/scripts/update-preference.sh enable`; `Not now` runs no preference command and does not disable a preference previously enabled elsewhere. On Codex, never run the preference helper or create the enablement marker.
8. Verify `STUDIO.md`, `AGENTS.md`, `CLAUDE.md`, `.mcp.json`, `.agents/skills/`, `.claude/skills/`, `standards/`, `references/`, and `projects/`, including the rendered units, jurisdiction, studio-resource links, data-governance statement, and the exact empty connector shape `{ "mcpServers": {} }`. This reserves a studio-only integration boundary; do not add a provider, URL, command, arguments, OAuth flow, or credentials. Finish by reporting the exact absolute studio path and both skill roots. If a new firm skill is not visible, restart the active harness from the studio root; invoke it as `$skill-name` on Codex or `/{skill-name}` on Claude Code.
9. Offer `/as:studio create-project`.

The created structure is:

```text
studio-root/
├── STUDIO.md
├── AGENTS.md
├── CLAUDE.md
├── .mcp.json
├── .agents/
│   └── skills/
├── .claude/
│   └── skills/
├── standards/
│   └── README.md
├── references/
│   └── README.md
└── projects/
```

### `/as:studio status` and `/as:studio projects`

Read the nearest `STUDIO.md`, then inspect its relative registered paths. Report:

- internal and client registrations across `prospective`, `active`, `on-hold`, `lost`, `withdrawn`, `completed`, and `archived` status;
- registered paths missing `PROJECT.md`;
- descendant folders containing `PROJECT.md` but absent from the manifest;
- duplicate project IDs or paths; and
- mismatches between manifest ID/name and `PROJECT.md` identity.
- connector manifest state: `missing`, `empty-reserved`, `configured`, or `invalid`.
- task register mode: `project`, `portfolio`, or `invalid`, including whether the canonical register expected by that mode exists.

These are read-only operations. Never silently add, remove, or rewrite a row or `.mcp.json`. Status must not attempt authentication, OAuth, network access, or connector startup.

### `/as:studio updates status|enable|disable`

Branch on the active host before resolving any path or running any helper.

- **Codex:** background update checking is unavailable because the Codex package does not install the Claude Code lifecycle hook. For `status`, `enable`, and `disable`, report that limitation and stop. Do not open a confirmation gate, resolve or create a state directory, run `<skill-root>/scripts/update-preference.sh`, or create, remove, or inspect `.architecture-studio-update-check-enabled` or its cache.
- **Claude Code:** update checking is a global local preference, not a studio or project record. Resolve `${ARCHITECTURE_STUDIO_STATE_DIR:-$HOME/.claude}` and use `.architecture-studio-update-check-enabled` as the sole permission marker. The stable state root is intentionally independent of the installed plugin identifier.

  - `status`: run `<skill-root>/scripts/update-preference.sh status`; it reports enabled or disabled without creating directories, files, caches, or network traffic.
  - `enable`: explain the request and Cloudflare metadata boundary, then use one confirmation gate. After confirmation, run `<skill-root>/scripts/update-preference.sh enable`; it writes the marker with user-only permissions and removes any stale cache so the next session seeds silently without a request.
  - `disable`: use one confirmation gate, then run `<skill-root>/scripts/update-preference.sh disable`. It removes the enablement marker and leaves the cache as inert local history. With no marker, the hook exits before filesystem or network work.

Never enable checking from installation, ordinary `/as:studio status`, or inferred consent. Never describe endpoint traffic as anonymous users, daily active users, or zero metadata.

### `/as:studio tasks mode project|portfolio`

`STUDIO.md` owns the portable task-storage choice. New studios default to `project`: each project owns `TASKS.md`. `portfolio` means one studio-root `TASKS.md` is canonical and every row carries a Project ID. The two modes are never simultaneously writable.

1. Resolve the studio and read its current `Task register` setting. If the requested mode already matches, report it without mutation.
2. Inspect the current canonical register or every registered project's register, regardless of status. If any task row exists, stop and explain that a dedicated merge or split migration is required; never renumber, move, or copy populated task records implicitly.
3. Preview the exact files affected. Moving an empty studio to portfolio creates the studio register and removes only empty registered-project task templates. Moving an empty studio to project recreates missing project templates and removes only the empty studio register.
4. Use one confirmation gate without a duplicate prose question.
5. Run `<skill-root>/scripts/studio-workspace.sh task-mode <studio-root> <project|portfolio>`, then verify `STUDIO.md` and every expected register boundary.

`/as:tasklist` owns task rows and task operations. `/as:studio` owns only this storage-mode setting and the guarded empty-register transition.

### `/as:studio create-project`

1. Require a resolved studio. If none exists, offer `/as:studio init` or standalone `/as:project init`.
2. Refuse to run from a path that would create a project inside an existing project.
3. Gather the normal-case display name, project type (`internal` or `client`), status, and a confirmed three-letter uppercase code. Client work uses its client code. Internal work uses the studio's own code or another user-confirmed internal code and may use `—` for Client; never substitute a reserved code. Keep the Project and Client fields distinct: when the user gives “client SOM, project Strategy consulting,” the project display name is `Strategy consulting`. Do not prefix the project display name or project-name slug with the client name merely because Client is recorded separately. These are the identity facts this flow persists; do not gather facts that this creation flow does not persist, including unrelated AEC or commercial details.
4. Generate the permanent ID as `YYYY-MM-CCC-PROJECT-NAME` from the current creation month, confirmed code, and uppercase ASCII kebab slug. The folder basename equals that ID exactly. Preview a meaningful user-confirmed disambiguator on collision; never overwrite, silently suffix, or reuse an identity.
5. Preview the exact folder, universal `PROJECT.md` identity, complete project bundle, and exact eight-column `STUDIO.md` row. Wait for one affirmative confirmation covering both operations.
6. Read the studio's `Task register` setting and require `project` or `portfolio`. Run the project-owned helper at `<plugin-root>/skills/project/scripts/project-workspace.sh init <target> <name> <project-id> <internal|client> <status> <client-code> <client> <task-mode>`. In portfolio mode the project helper must not create a competing project-local `TASKS.md`. Do not slash-invoke `/as:project init`; that would route back here.
7. Re-read the created `PROJECT.md` and verify the bundle.
8. Run `<skill-root>/scripts/studio-workspace.sh register <studio-root> <id> <name> <relative-path>`. The helper reads Client, Code, Type, Status, and Opened from the verified project record and writes the bounded registry in canonical header order.
9. Re-read `STUDIO.md` and the project bundle. If registration fails after project creation, keep the project intact, report the partial state, and offer registration of that exact folder. Never create another folder as recovery.
10. On success, report the exact absolute project path plus its `.agents/skills/` and `.claude/skills/` paths. Tell the user that project-only skills are discovered from project scope; if a new skill does not appear, restart the active harness from that project root and invoke it as `$skill-name` on Codex or `/{skill-name}` on Claude Code. Offer the project skill as the next step for adding sourced project facts.

### `/as:studio register-project <folder>`

Accept only a direct child of the resolved studio’s `projects/` directory whose uppercase basename exactly equals the format-version-3 Project ID in `PROJECT.md`. Read its universal identity, detect duplicate ID/path rows inside the bounded Projects section, preview all eight fields, confirm, register, and verify. Never relocate or copy client files.

### `/as:studio archive-project <id>`

This is a convenience alias for `set-project-status <id> archived`. Archiving does not delete files, move or rename the project, or change its immutable identity. Status is advisory: archived work remains resolvable and can receive user-confirmed actions.

### `/as:studio set-project-status <id> <status>`

Preview changing the Status field in both the registry row and `PROJECT.md`, confirm, then run `<skill-root>/scripts/studio-workspace.sh set-status <studio-root> <id> <status>` and verify the two records together. Supported statuses are `prospective`, `active`, `on-hold`, `lost`, `withdrawn`, `completed`, and `archived`. The transaction restores and verifies both files on any failure. If either restore cannot be verified, report the exact failed operation and preserve the `.project-status-transaction.*` recovery bundle instead of deleting its snapshots. Status changes never delete, move, rename, or replace the project and do not enforce a transition graph.

### `/as:studio migrate <confirmed manifest>`

Format-version-2 workspaces require an explicit, recoverable migration before version-3 writers may change them.

1. Inventory every bounded registry row and ask the user to confirm its display name, creation date/month, client, three-letter code, type, and status. Never infer missing identity facts from activity.
2. Build one tab-separated manifest with the headers `Old Project ID`, `Old Folder`, `Project ID`, `Project`, `Client`, `Code`, `Type`, `Status`, and `Opened`. It must cover each registered project exactly once and preview every old-to-new ID/folder mapping.
3. Report structured references that will change: the bounded studio registry, each project identity table, Project ID cells in a portfolio `TASKS.md`, and any version-2 studio-wide proposal rows. Preview each old proposal number/path and its project-local `YYYY-MM-short-title-proposal-rev-NN.md` destination. Former numbers become read-only `Legacy number` metadata; existing proposal content and lifecycle status are preserved, and issued records receive a checksum.
4. After one confirmation, run `<skill-root>/scripts/studio-workspace.sh migrate <studio-root> <confirmed-manifest.tsv> --apply`. The helper snapshots affected files, journals every rename intent before mutation, preserves record directories through the rename, removes the obsolete studio-wide proposal register after converting every registered file, and restores the version-2 registry, proposal register/files, project records, task register, and directory names if mutation or verification fails. A verified rollback removes its transaction; an incomplete rollback reports each failed restore and preserves `.v3-migration-transaction.*` with its snapshots, rename journal, and `ROLLBACK-FAILURES.tsv` for recovery.
5. Require the machine-readable `migration-verification` summary, then re-read the v3 registry, every renamed `PROJECT.md`, every converted proposal, and the known structured references. Confirm all eight registry/project identity fields, exact ID/directory equality, complete structured task-ID rewrites, proposal metadata and lifecycle transformations, and checksums for every preserved project file. Report possible old IDs or paths in ordinary prose for manual review; do not rewrite prose speculatively.

## Task routing

If the input is not a studio-management command, classify and route it. Prefer the narrowest skill when the request names a concrete deliverable. Branch on the active host before choosing an agent or multi-skill sequence.

| Request involves | Route |
|---|---|
| Studio/project setup, project facts, project decisions, “remember this” | `$project` on Codex or `/as:project` on Claude Code (project creation inside a studio starts with `$studio create-project` or `/as:studio create-project`) |
| Meeting transcript or minutes | `$meeting-minutes` on Codex or `/as:meeting-minutes` on Claude Code |
| Field notes or site-visit report | `$site-visit-report` on Codex or `/as:site-visit-report` on Claude Code |
| Tasks or action register | `$tasklist` on Codex or `/as:tasklist` on Claude Code |
| Daily/weekly time reconstruction | `$timetracker` on Codex or `/as:timetracker` on Claude Code |
| Proposal, quote, or fee letter | `$proposal` on Codex or `/as:proposal` on Claude Code |
| Neutral professional-practice term, AIA document family, or document purpose | `$architecture-knowledge` on Codex or `/as:architecture-knowledge` on Claude Code |
| Actual signed project scope, agreement, SOW, or “is this in scope” | `$agreement` on Codex or `/as:agreement` on Claude Code |
| Contract selection or clause question | `$architecture-knowledge` on Codex or `/as:architecture-knowledge` on Claude Code for its bounded refusal and source orientation; it does not select a form or interpret clauses |
| Invoice, billing, running balance, or payment status | `$invoice` on Codex or `/as:invoice` on Claude Code |
| Actual work or submission plan, sequence, coordination, or delivery plan | `$workplan` on Codex or `/as:workplan` on Claude Code |
| Bug report, broken skill, or feature request for Architecture Studio | `$studio-feedback` on Codex or `/as:studio-feedback` on Claude Code |
| Outline specification or CSI specification writing without a sustainability focus | `$spec-writer` on Codex or `/as:spec-writer` on Claude Code |
| Regulatory conclusion | the existing regulatory skill appropriate to the stated jurisdiction (for example, `$zoning-analysis-nyc` on Codex or `/as:zoning-analysis-nyc` on Claude Code) |

### Claude Code native-agent routes

Keep these seven native-agent routes on Claude Code:

| Request involves | Route |
|---|---|
| Site context, feasibility, climate, transit, demographics, history | Site Planner agent |
| NYC property, zoning, FAR, envelope, permits, violations, landmarks | NYC Zoning Expert agent |
| Headcount, workplace program, occupancy, office sizing | Workplace Strategist agent |
| Products, materials, furniture search, alternatives | Product & Materials Researcher agent |
| FF&E schedules, room packages, SIF, schedule QA | FF&E Designer agent |
| EPD, GWP, embodied carbon, LEED materials | Sustainability Specialist agent |
| Presentations, slide decks, palettes, image preparation | Brand Manager agent |

### Codex skill routes and synthesis

Codex does not package those native agents. For `$studio <request>`, run the installed skills in the applicable lane below, preserve every source and uncertainty from their outputs, and synthesize the completed artifacts into one concise answer. Do not imitate an agent name or invent results that a listed skill did not produce.

| Codex lane | Installed skill sequence | `$studio` synthesis |
|---|---|---|
| Site context | `$environmental-analysis` → `$mobility-analysis` → `$demographics-analysis` → `$site-history` | Reconcile the four sourced outputs into one site-context brief, separating environmental constraints, access, people, neighborhood history, assumptions, and unresolved gaps. |
| NYC zoning | `$nyc-property-report` → `$zoning-analysis-nyc` → `$zoning-envelope` when the user requests a massing visualization | Join property due diligence and zoning capacity by address, BBL, and source date; call out conflicts and professional-review items before linking the optional envelope artifact. |
| Programming | `$workplace-programmer` → `$occupancy-calculator` when a jurisdiction-aware code occupant load is needed | Keep planned seats distinct from code occupant load, reconcile the room schedule and area totals, and surface jurisdiction assumptions. |
| Specifications | `$spec-writer`; for embodied-carbon requirements, use the sustainability lane and finish with `$epd-to-spec` | Assemble the applicable CSI sections, preserve review flags and source boundaries, and distinguish product selections from enforceable requirements. |
| Materials and FF&E | For sourcing, `$product-research` → `$product-match` for requested alternates → `$product-pair` for requested groupings. For a schedule, `$master-schedule` → `$product-data-import` → `$product-data-cleanup` → `$product-enrich`. | Produce one sourced candidate comparison or one reconciled schedule summary, state which rows were saved, and keep unknown commercial or performance data explicit. |
| Sustainability | `$epd-research` → `$epd-parser` → `$epd-compare` → `$epd-to-spec` when specification language is requested | Normalize declared units and system boundaries before comparing GWP, then separate sourced eligibility evidence from recommendations and optional spec language. |
| Presentations | `$color-palette-generator` when a palette is needed → `$resize-images` when source images need preparation → `$slide-deck-generator` | Carry the approved narrative, palette, and prepared asset paths into the deck; report generated files and any missing visual inputs. |

The README dispatcher examples are executable routing contracts: `$studio 123 Main St, Brooklyn NY` selects the **NYC zoning** lane and offers `$zoning-envelope` only after the property and zoning work; `$studio task chair, mesh back, under $800` selects **Materials and FF&E**, begins with `$product-research`, and may offer `$master-schedule` to save the reviewed shortlist.

### Routing rules

- A specific named skill wins over an agent.
- An explicit typed-record deliverable wins over a general plan. An explicit work-plan deliverable still routes to `/as:workplan` on Claude Code and `$workplan` on Codex.
- If two routes remain genuinely plausible, ask exactly one clarifying question.
- For a multi-agent or multi-skill request, state the sequence and start with the first natural dependency.
- If no route matches, show a condensed menu and suggest `$tool-catalog` on Codex or `/as:tool-catalog` on Claude Code.
- If `$studio` on Codex or `/as:studio` on Claude Code has no arguments, follow the branded welcome flow above; do not append the full task menu unless the user skips setup or asks what else is available.
- After routed work completes, offer at most three executable follow-ups. On Codex, render every suggested command as `$<skill-name>` (for example, `$tool-catalog`) and never emit a Claude-style slash command or a Claude native-agent name as a callable route. On Claude Code, render skills as `/as:<skill-name>` and retain native-agent routes where applicable.

## What `/as:studio` does not do

- It does not mutate `PROJECT.md`, `decisions/`, tasks, time, meetings, or reports.
- It does not initialize git, create accounts, upload files, or configure cloud storage.
- It does not select or configure connectors, authenticate services, or place `.mcp.json` in projects.
- It does not create compatibility aliases for retired commands.
