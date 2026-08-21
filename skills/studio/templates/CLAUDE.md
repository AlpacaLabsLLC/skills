# {{STUDIO_NAME}} — Studio Instructions

This folder is the studio worksurface.

- Read `STUDIO.md` to find registered projects.
- Use the working-unit and default-jurisdiction settings in `STUDIO.md` unless a project records an explicit override.
- Firm-created Claude Code skills live in `.claude/skills/`; Codex skills use the parallel `.agents/skills/` root.
- Firm-wide standards and reusable templates live in `standards/`.
- External references, including code references, live in `references/`.
- Project work and project outputs stay inside `projects/`.
- Project facts live in each project’s `PROJECT.md`.
- Decision rationale lives in each project’s `decisions/` directory.
- Never treat the installed Architecture Studio plugin cache as a project or private-skill destination.
- This local version does not store workspace data with ALPA. Treat the configured LLM provider and account terms as the boundary for content sent to the model.
