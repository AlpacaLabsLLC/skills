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

- When `AskUserQuestion` is available, its `question` field must begin with the exact mark above as raw text, without opening or closing Markdown fences. Immediately include the provenance block as raw text before `How would you like to start?`, and then present the four choices below. The structured gate must be self-contained; do not rely on a preceding assistant preamble because the harness may suppress it when the gate opens.
- When `AskUserQuestion` is unavailable, the ordinary assistant response must begin with the same exact mark and provenance before asking once in natural language.
- Do not run a boundary search, shell command, file read, or any other tool before the branded welcome is visible. Resolve an existing studio only after displaying the welcome; if one is found, adapt the choices on the next interaction.

Keep the rest light. If a studio is already resolved, offer to open its status or create a project. Otherwise explain that the built-in tools are already available and that studio setup adds persistent settings, projects, and records. Present these four outcomes in one structured gate:

1. **Set up a studio** — continue directly into `/as:studio init`; do not repeat the mark.
2. **Use tools without setup** — end onboarding without mutation. State that this creates no files, preferences, or copied skills; point to `/as:tool-catalog` and representative direct commands; and say, “Run `/as:studio` later whenever you want persistent settings and project records.”
3. **Learn with an example** — hand off to `/as:learn`.
4. **Open an existing studio** — ask for or resolve its path, then show status.

Tools-only use is not a stored mode. Built-in skills continue to run from the installed plugin, and the user can invoke `/as:studio` later without migration or cleanup. Never direct an ordinary user to download or copy the repository’s `skills/` directory.

### Single-gate rule

Never ask a setup or confirmation question twice. For the no-argument welcome, put the required branding and question together inside the structured gate as specified above. For later gates, give context or a preview without ending in a prose question, then open the structured gate immediately. The user’s answer to that gate is the answer; do not restate the question in chat. If the tool is unavailable, ask once in natural language. A later Claude Code permission prompt is a separate harness security boundary, not a reason to add another conversational confirmation.

## Commands

```text
/as:studio init
/as:studio status
/as:studio projects
/as:studio create-project
/as:studio register-project <project folder>
/as:studio archive-project <project id>
/as:studio updates status
/as:studio updates enable
/as:studio updates disable
/as:studio tasks mode project|portfolio
/as:studio <describe an architecture task>
```

## Hard boundaries

1. `STUDIO.md` marks the studio root. **Only `/as:studio` writes `STUDIO.md`.**
2. `PROJECT.md` marks a project root. Project facts and decision records belong to `/as:project`; `/as:studio` reads only enough project identity to register or verify it.
3. The studio-root `.mcp.json` is the reserved connector manifest and is owned only by `/as:studio`. A project never receives or owns `.mcp.json`.
4. The installed Architecture Studio plugin cache is never a studio, project, or private-skill destination.
5. Never create a studio or project merely because the plugin was installed. Setup requires an exact-path preview and affirmative confirmation.
6. Never create a nested project inside a directory already containing `PROJECT.md`.
7. Registry paths are relative descendants below `projects/`; never persist arbitrary absolute project paths.

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
3. Explain the data boundary before confirmation: this local version stores studio and project records in the chosen local workspace; Architecture Studio does not send them to or store them with ALPA; content the user provides to the configured LLM is handled under that provider account and its data terms; future cloud-based versions may require an account and differ. Background update checking is **disabled by default**. If no update preference exists, ask exactly, “Would you like this to automatically check for updates?” with `Yes, automatically check` / `Not now` choices in the setup gate. Enabling permits at most one bare request per 24 hours to ALPA's Cloudflare endpoint; it sends no project content or Architecture Studio identifier, though Cloudflare processes ordinary request metadata such as IP address, headers, and timestamps. Ask the user to acknowledge this note as part of setup confirmation.
4. Normalize the directory name to lowercase kebab-case. Reject empty names, `.`/`..`, absolute names supplied as names, separators inside names, control characters, reserved ambiguous names, existing files, and non-empty target directories.
5. Preview the display name, exact absolute target, units, jurisdiction, files created, and data-governance note. State that setup does not initialize git, create an ALPA account, or configure cloud storage.
6. Open one confirmation gate covering the target, defaults, and data note. Do not ask for confirmation in prose before opening it and do not reconfirm after it returns.
7. Run `${CLAUDE_SKILL_DIR}/scripts/studio-workspace.sh init <target> <studio-name> <working-units> <country> <state-region> <city>` with safely quoted arguments. Use the literal value `No default` for omitted jurisdiction levels. Only when the user selected enablement, run `${CLAUDE_SKILL_DIR}/scripts/update-preference.sh enable`; `Not now` runs no preference command and does not disable a preference previously enabled elsewhere.
8. Verify `STUDIO.md`, `CLAUDE.md`, `.mcp.json`, `.claude/skills/`, and `projects/`, including the rendered units, jurisdiction, data-governance statement, and the exact empty connector shape `{ "mcpServers": {} }`. This reserves a studio-only integration boundary; do not add a provider, URL, command, arguments, OAuth flow, or credentials. Finish by reporting the exact absolute studio path and `.claude/skills/` path. Tell the user to restart Claude Code from the studio root if a newly created firm skill does not appear in autocomplete; after restart, invoke it by its local `/{skill-name}` command.
9. Offer `/as:studio create-project`.

The created structure is:

```text
studio-root/
├── STUDIO.md
├── CLAUDE.md
├── .mcp.json
├── .claude/
│   └── skills/
└── projects/
```

### `/as:studio status` and `/as:studio projects`

Read the nearest `STUDIO.md`, then inspect its relative registered paths. Report:

- active, on-hold, and archived registrations;
- registered paths missing `PROJECT.md`;
- descendant folders containing `PROJECT.md` but absent from the manifest;
- duplicate project IDs or paths; and
- mismatches between manifest ID/name and `PROJECT.md` identity.
- connector manifest state: `missing`, `empty-reserved`, `configured`, or `invalid`.
- task register mode: `project`, `portfolio`, or `invalid`, including whether the canonical register expected by that mode exists.

These are read-only operations. Never silently add, remove, or rewrite a row or `.mcp.json`. Status must not attempt authentication, OAuth, network access, or connector startup.

### `/as:studio updates status|enable|disable`

Update checking is a global local preference, not a studio or project record. Resolve `${ARCHITECTURE_STUDIO_STATE_DIR:-$HOME/.claude}` and use `.architecture-studio-update-check-enabled` as the sole permission marker. The stable state root is intentionally independent of the installed plugin identifier.

- `status`: run `${CLAUDE_SKILL_DIR}/scripts/update-preference.sh status`; it reports enabled or disabled without creating directories, files, caches, or network traffic.
- `enable`: explain the request and Cloudflare metadata boundary, then use one confirmation gate. After confirmation, run `${CLAUDE_SKILL_DIR}/scripts/update-preference.sh enable`; it writes the marker with user-only permissions and removes any stale cache so the next session seeds silently without a request.
- `disable`: use one confirmation gate, then run `${CLAUDE_SKILL_DIR}/scripts/update-preference.sh disable`. It removes the enablement marker and leaves the cache as inert local history. With no marker, the hook exits before filesystem or network work.

Never enable checking from installation, ordinary `/as:studio status`, or inferred consent. Never describe endpoint traffic as anonymous users, daily active users, or zero metadata.

### `/as:studio tasks mode project|portfolio`

`STUDIO.md` owns the portable task-storage choice. New studios default to `project`: each project owns `TASKS.md`. `portfolio` means one studio-root `TASKS.md` is canonical and every row carries a Project ID. The two modes are never simultaneously writable.

1. Resolve the studio and read its current `Task register` setting. If the requested mode already matches, report it without mutation.
2. Inspect the current canonical register or every non-archived registered project's register. If any task row exists, stop and explain that a dedicated merge or split migration is required; never renumber, move, or copy populated task records implicitly.
3. Preview the exact files affected. Moving an empty studio to portfolio creates the studio register and removes only empty registered-project task templates. Moving an empty studio to project recreates missing project templates and removes only the empty studio register.
4. Use one confirmation gate without a duplicate prose question.
5. Run `${CLAUDE_SKILL_DIR}/scripts/studio-workspace.sh task-mode <studio-root> <project|portfolio>`, then verify `STUDIO.md` and every expected register boundary.

`/as:tasklist` owns task rows and task operations. `/as:studio` owns only this storage-mode setting and the guarded empty-register transition.

### `/as:studio create-project`

1. Require a resolved studio. If none exists, offer `/as:studio init` or standalone `/as:project init`.
2. Refuse to run from a path that would create a project inside an existing project.
3. Gather the project display name and optional project ID. Folder grammar is `{project-id}-{kebab-name}` when an ID exists, otherwise `{kebab-name}`. Project facts are added later through `/as:project`; do not gather facts that this creation flow does not persist.
4. Preview the exact folder, complete project bundle, and exact `STUDIO.md` row. Wait for one affirmative confirmation covering both operations.
5. Use the supplied project ID, or the normalized folder slug as a stable local ID when none is supplied. Read the studio's `Task register` setting and require `project` or `portfolio`. Run the project-owned helper at `${CLAUDE_PLUGIN_ROOT}/skills/project/scripts/project-workspace.sh init <target> <name> <project-id> <task-mode>`. In portfolio mode the project helper must not create a competing project-local `TASKS.md`. Do not slash-invoke `/as:project init`; that would route back here.
6. Re-read the created `PROJECT.md` and verify the bundle.
7. Run `${CLAUDE_SKILL_DIR}/scripts/studio-workspace.sh register <studio-root> <id> <name> <relative-path>`.
8. Re-read `STUDIO.md` and the project bundle. If registration fails after project creation, keep the project intact, report the partial state, and offer registration of that exact folder. Never create another folder as recovery.
9. On success, report the exact absolute project path and its `.claude/skills/` path. Tell the user that project-only skills created there are discovered from the project scope; if a new skill does not appear in autocomplete, restart Claude Code from that project root and invoke it by its local `/{skill-name}` command. Offer `/as:project update` as the next step for adding sourced project facts.

### `/as:studio register-project <folder>`

Accept only a descendant of the resolved studio’s `projects/` directory containing `PROJECT.md`. Read its identity, detect duplicate ID/path rows, preview the relative row, confirm, register, and verify. Never relocate or copy client files.

### `/as:studio archive-project <id>`

Preview changing only the manifest registration state to `archived`, confirm, then use the helper and verify. Archiving does not change the project’s design phase, delete files, or move its folder.

## Task routing

If the input is not a studio-management command, classify and route it. Prefer the narrowest skill when the request names a concrete deliverable; use an agent when judgment or multiple skills are required.

| Request involves | Route |
|---|---|
| Studio/project setup, project facts, project decisions, “remember this” | `/as:project` (project creation inside a studio starts with `/as:studio create-project`) |
| Meeting transcript or minutes | `/as:meeting-minutes` |
| Field notes or site-visit report | `/as:site-visit-report` |
| Tasks or action register | `/as:tasklist` |
| Daily/weekly time reconstruction | `/as:timetracker` |
| Explicit work plan, sequence, coordination, delivery plan | `/as:workplan` |
| Bug report, broken skill, or feature request for Architecture Studio | `/as:studio-feedback` |
| Site context, feasibility, climate, transit, demographics, history | Site Planner agent |
| NYC property, zoning, FAR, envelope, permits, violations, landmarks | NYC Zoning Expert agent |
| Headcount, workplace program, occupancy, office sizing | Workplace Strategist agent |
| Products, materials, furniture search, alternatives | Product & Materials Researcher agent |
| FF&E schedules, room packages, SIF, schedule QA | FF&E Designer agent |
| EPD, GWP, embodied carbon, LEED materials | Sustainability Specialist agent |
| Presentations, slide decks, palettes, image preparation | Brand Manager agent |
| CSI specification writing without a sustainability focus | `/as:spec-writer` |

### Routing rules

- A specific named skill wins over an agent.
- An explicit typed-record deliverable wins over a general plan. An explicit work-plan deliverable still routes to `/as:workplan`.
- If two routes remain genuinely plausible, ask exactly one clarifying question.
- For a multi-agent request, state the sequence and start with the first natural dependency.
- If no route matches, show a condensed menu and suggest `/as:tool-catalog`.
- If `/as:studio` has no arguments, follow the branded welcome flow above; do not append the full task menu unless the user skips setup or asks what else is available.

## What `/as:studio` does not do

- It does not mutate `PROJECT.md`, `decisions/`, tasks, time, meetings, or reports.
- It does not initialize git, create accounts, upload files, or configure cloud storage.
- It does not select or configure connectors, authenticate services, or place `.mcp.json` in projects.
- It does not create compatibility aliases for retired commands.
