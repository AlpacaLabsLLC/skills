# /as:studio

Architecture Studio’s control plane: initialize a portable studio workspace, list or register projects, create a project through the project-owned scaffold, or route an architecture task.

Invoking `/as:studio` with no arguments shows the Architecture Studio mark, creator and ALPA ownership, license, contact, and repository provenance. If no studio is open, it offers four paths: set up a studio, use the installed tools without setup, learn with an example, or open an existing studio. Tools-only use creates no files or copied skills, and `/as:studio` remains available whenever persistent settings and project records become useful.

Studio setup records working units, default country/state-or-region/city, and the local-data governance boundary before creating files. Each question or confirmation uses one interaction gate rather than a prose question followed by a duplicate UI prompt.

```text
/as:studio init
/as:studio status
/as:studio create-project
/as:studio register-project projects/2401-museum-expansion
/as:studio archive-project 2401
/as:studio updates status
/as:studio updates enable
/as:studio updates disable
/as:studio I need a space program for 200 people
```

`STUDIO.md` is the sole studio manifest and the studio skill is its only writer. Studio-owned custom skills live in `.agents/skills/` on Codex or `.claude/skills/` on Claude Code; project memory remains owned by the project skill. New studios also reserve a studio-only connector boundary with an empty `.mcp.json`; no connector or authentication is configured, and project scaffolds never receive this file.

Studios default to project task mode, with one canonical `TASKS.md` per project. `/as:studio tasks mode portfolio` can move an empty studio to one studio-root register; populated registers require an explicit migration so two writable task sources can never drift.

Background update checking is disabled by default. The `updates` commands manage a global local preference explicitly. When enabled, the check sends no project content or Architecture Studio identifier, but Cloudflare handles ordinary web-request metadata such as IP address, headers, and timestamps.
