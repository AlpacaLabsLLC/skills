# /as:project

The single interface for Architecture Studio project setup and memory.

```text
/as:project init
/as:project status
/as:project remember the site area is 12,500 sf
/as:project record-decision the client selected Scheme B
/as:project decisions
/as:project supersede 0003
/as:project migrate
```

`PROJECT.md` owns sourced current facts. `decisions/*.md` owns durable reasoning and status. There is no duplicated Decisions table. When a project belongs to a studio, create it through the studio skill so that skill remains the only writer of `STUDIO.md`. Project scaffolds include `AGENTS.md` and `.agents/skills/` for Codex alongside `CLAUDE.md` and `.claude/skills/` for Claude Code.

Format version 3 uses one universal project record for internal and client work. Its immutable ID and exact directory name use uppercase `YYYY-MM-CCC-PROJECT-NAME`; the display name remains normal case. `PROJECT.md` records Type, Status, Created, Client code, and Client, while Site, Zoning, Program, and Code sections are added only when relevant. Project type and status are context, not action gates.

Client projects use their confirmed three-letter client code. Internal projects use the studio's own three-letter code or another user-confirmed internal code; no reserved code is substituted.

Project and Client are separate identity fields. For client `SOM` and project `Strategy consulting`, the ID is `YYYY-MM-SOM-STRATEGY-CONSULTING`, not `YYYY-MM-SOM-SOM-STRATEGY-CONSULTING`.

Older records migrate only through a confirmed preview. Standalone migration recognizes the generated version-2 `CLAUDE.md`, replaces it with the canonical `@AGENTS.md` import, and restores both the record and instruction bytes plus the original directory topology on failure; custom Claude instructions require separate review and confirmation. A valid legacy standalone root `PROPOSALS.md` blocks project-only migration before mutation because its register and proposal files require studio-owned conversion. Studio-owned migration updates the bounded registry, project identity/folder, and known structured Project ID references transactionally, restoring its backup on failure; possible prose references are reported rather than rewritten speculatively.
