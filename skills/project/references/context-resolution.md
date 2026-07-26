# Project context resolution

Project-record skills must run `${CLAUDE_PLUGIN_ROOT}/skills/project/scripts/resolve-context.sh` from the current directory or an explicit user-selected directory before reading or writing records. Its first tab-separated field is authoritative:

- `project`: use the returned project root and Project ID. The remaining fields give the validated owning studio (`-` for standalone), task mode, and canonical task-register path. Never independently guess portfolio versus project task storage.
- `studio-picker`: show only the following validated manifest rows and require selection before writing.
- `no-projects`: offer project creation; do not infer another root.
- `no-context`: ask for a project or studio path, or offer `/as:studio`.
- `invalid`: stop and report the validation error.

`PROJECT.md` is the only implicit project boundary. Git roots, record folders, and the current directory do not establish project context.
