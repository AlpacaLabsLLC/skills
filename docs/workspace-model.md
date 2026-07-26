# Workspace and memory model

Architecture Studio separates the installed plugin from the user-owned worksurface. Plugin updates replace plugin code; they do not own or migrate studio records silently.

## Studio

```text
studio/
├── STUDIO.md                 settings and project registry
├── CLAUDE.md                 shared working instructions
├── .mcp.json                 studio-only connector boundary
├── .claude/skills/           firm-created skills
├── TASKS.md                  optional portfolio-mode action register
└── projects/
```

`/as:studio` creates or inspects this structure only after the user confirms the exact target. The empty connector manifest belongs at studio level because credentials and integrations are organizational concerns, not project records.

`STUDIO.md` and `PROJECT.md` carry integer `Format version` fields. Workspace format 2 writers accept format `2`, fail closed on unknown versions, and require an explicit previewed migration before changing an unversioned record. Registered projects must resolve physically below the studio's non-symlinked `projects/` directory.

## Project

```text
projects/example/
├── PROJECT.md                sourced project facts
├── CLAUDE.md                 project working instructions
├── decisions/                durable reasoning and supersession history
├── meetings/                 typed meeting records
├── site-reports/             field observations and limitations
├── docs/plans/               work plans
├── TASKS.md                  default project-mode action register
├── TIMELOG.md                user-confirmed time
├── product-library.csv       optional FF&E library
├── epd-library.csv           optional EPD library
└── .claude/skills/           project-only skills
```

## Canonical ownership

| Information | Canonical owner |
|-------------|-----------------|
| Studio settings and project registry | `STUDIO.md` |
| Sourced project facts | `PROJECT.md` |
| Durable decisions and supersession | `decisions/` |
| Meeting source context | `meetings/` |
| Field observations and limitations | `site-reports/` |
| Planned work | `docs/plans/` |
| Actions and status history | Project `TASKS.md`, or one studio `TASKS.md` in portfolio mode |
| Confirmed durations | `TIMELOG.md` |
| FF&E product data | `product-library.csv` |
| Optional persisted EPD data | `epd-library.csv` |

Records cross-reference one another by stable identifiers. Meetings and site reports may propose facts, decisions, or tasks, but promotion into the canonical record requires an explicit handoff and user confirmation. `PROJECT.md` points to decisions rather than maintaining a second decision index.

Studios default to project task mode: each project has one writable `TASKS.md`, and an all-project list is a read-only merged view. A studio may explicitly choose portfolio task mode, where one studio-root `TASKS.md` is authoritative and every task carries a Project ID. The modes are mutually exclusive; populated registers require a previewed migration rather than an automatic merge or split.

Canonical studio and project records use a one-writer operating model in workspace format 2. Task-mode changes preflight all affected registers and keep rollback copies until the new topology and manifest commit together. Simultaneous edits from multiple Claude sessions or synchronized-folder clients are not supported.

This structure keeps records readable without Architecture Studio and lets them travel through the firm’s existing local, network, or synchronized storage system.

Project initialization creates the empty `.claude/skills/` directory shown above. Skills created there are project-only; firm-wide skills belong at the studio root. Start or restart Claude Code from the intended studio or project scope if a newly created skill is not visible in autocomplete.
