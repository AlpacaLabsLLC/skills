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
