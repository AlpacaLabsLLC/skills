# Workspace and memory model

Architecture Studio separates the installed plugin from the user-owned worksurface. Plugin updates replace plugin code; they do not own or migrate studio records silently.

## Studio

```text
studio/
├── STUDIO.md                 settings and project registry
├── AGENTS.md                 Codex working instructions
├── CLAUDE.md                 Claude Code working instructions
├── .mcp.json                 studio-only connector boundary
├── .agents/skills/           firm-created Codex skills
├── .claude/skills/           firm-created Claude Code skills
├── standards/                firm-wide standards and reusable templates
├── references/               external source material and code references
├── TASKS.md                  optional portfolio-mode action register
└── projects/
```

`/as:studio` creates or inspects this structure only after the user confirms the exact target. The empty connector manifest belongs at studio level because credentials and integrations are organizational concerns, not project records. Firm-wide standards and reusable templates live in `standards/`; external source material such as building codes lives in `references/`. Project work and project outputs stay inside the owning project under `projects/`. There is no separate studio `templates/` directory.

`STUDIO.md` and `PROJECT.md` carry integer `Format version` fields. Workspace format 3 writers accept format `3`, fail closed on older or unknown versions, and require an explicit previewed migration before changing them. Registered projects must resolve physically below the studio's non-symlinked `projects/` directory.

The `STUDIO.md` Projects table is bounded by `<!-- projects:start -->` / `<!-- projects:end -->` and parsed by header name. Its columns are Project ID, Project, Client, Code, Type, Status, Folder, and Opened. One unique valid row remains resolvable in every supported status; status is advisory context rather than an action gate. Studio-root resolution returns structured `invalid-project` diagnostics for registered rows whose complete identity or filesystem boundary fails validation, while `no-projects` is reserved for a truly empty registry.

## Project

```text
projects/2026-08-SMI-MUSEUM-EXPANSION/
├── PROJECT.md                sourced project facts
├── AGENTS.md                 Codex project instructions
├── CLAUDE.md                 Claude Code project instructions
├── decisions/                durable reasoning and supersession history
├── meetings/                 typed meeting records
├── site-reports/             field observations and limitations
├── docs/plans/               work plans
├── proposals/                optional project-local fee proposals
├── agreement/                optional contract context, SOWs, and amendments
├── INVOICES.md               optional user-directed invoice ledger
├── TASKS.md                  default project-mode action register
├── TIMELOG.md                user-confirmed time
├── product-library.csv       optional FF&E library
├── epd-library.csv           optional EPD library
├── .agents/skills/           project-only Codex skills
└── .claude/skills/           project-only Claude Code skills
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
| Proposal terms and lifecycle | Individual files in `proposals/` |
| Agreement context, SOWs, and amendments | `agreement/` |
| Invoice facts and billing history | `INVOICES.md` |
| Actions and status history | Project `TASKS.md`, or one studio `TASKS.md` in portfolio mode |
| Confirmed durations | `TIMELOG.md` |
| FF&E product data | `product-library.csv` |
| Optional persisted EPD data | `epd-library.csv` |

Records cross-reference one another by stable identifiers. Meetings and site reports may propose facts, decisions, or tasks, but promotion into the canonical record requires an explicit handoff and user confirmation. `PROJECT.md` points to decisions rather than maintaining a second decision index.

Format 3 uses the project as the single durable entity for internal and client work. Its immutable Project ID and exact directory name use uppercase `YYYY-MM-CCC-PROJECT-NAME`; its display name keeps normal capitalization. Universal identity records Type, Status, Created, Client code, and Client. AEC sections such as Site, Zoning, Program, and Code are optional and added only when relevant.

Canonical singleton records use uppercase names such as `PROJECT.md`, `TASKS.md`, `TIMELOG.md`, and `INVOICES.md`. Directories and individual repeatable records use lowercase kebab-case, including `decisions/`, `meetings/`, `site-reports/`, `docs/plans/`, `proposals/`, and `agreement/sow/`. Proposal filenames use `YYYY-MM-short-title-proposal-rev-NN.md`, while the document itself shows `Rev. NN`. The project ID is the deliberate exception: it stays uppercase because it is both immutable identity and directory name.

Commercial records remain inside their owning project. Proposal files are discovered directly without a studio-wide register or firm-wide number. Sending records a SHA-256 checksum for the protected issued-terms block; later lifecycle evidence stays outside it, and changed terms use a new revision. Agreement context may cite that project-relative path and checksum without copying the proposal. Invoice records may use an agreement when one exists or explicit user input when it does not. These tools surface context but do not enforce a proposal, agreement, invoice, or project-status sequence.

Studios default to project task mode: each project has one writable `TASKS.md`, and an all-project list is a read-only merged view. A studio may explicitly choose portfolio task mode, where one studio-root `TASKS.md` is authoritative and every task carries a Project ID. The modes are mutually exclusive; populated registers require a previewed migration rather than an automatic merge or split.

Canonical studio and project records use a one-writer operating model in workspace format 3. Task-mode changes preflight all affected registers and keep rollback copies until the new topology and manifest commit together. The format-2 migration similarly previews a complete identity manifest, updates only known structured references, converts registered global proposal files into project-local records with legacy-number metadata, and restores its scoped backup if mutation or verification fails. Standalone migration also snapshots a recognized generated `CLAUDE.md` before replacing it with the canonical `@AGENTS.md` import; custom instructions require separate review, and a valid standalone root `PROPOSALS.md` blocks project-only mutation until a studio-owned commercial migration is confirmed. Simultaneous edits from multiple Codex or Claude sessions, or synchronized-folder clients, are not supported.

This structure keeps records readable without Architecture Studio and lets them travel through the firm’s existing local, network, or synchronized storage system.

Project initialization creates both empty skill roots shown above. Skills created under the active host's project root are project-only; firm-wide skills belong at the studio root. Start or restart Codex or Claude Code from the intended studio or project scope if a newly created skill is not visible.
