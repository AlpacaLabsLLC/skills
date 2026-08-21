# Project context resolution

Project-record skills must run `<plugin-root>/skills/project/scripts/resolve-context.sh` from the current directory or an explicit user-selected directory before reading or writing records. Its first tab-separated field is authoritative:

- `project`: use the returned project root and Project ID. The remaining fields give the validated owning studio (`-` for standalone), task mode, canonical task-register path, project type, and status. Type and status are advisory context; they may justify a warning but never block a user-confirmed action.
- `studio-picker`: show the following validated manifest rows, including their type and status, and require selection before writing. Lines beginning `invalid-project` are structured diagnostics (`Project ID`, registered path, reason), not choices; report them separately. If the result contains diagnostics but no valid choice rows, stop rather than offering project creation. Do not filter out prospective, lost, withdrawn, completed, or archived work.
- `no-projects`: offer project creation; do not infer another root.
- `no-context`: ask for a project or studio path, or offer `/as:studio`.
- `invalid`: stop and report the validation error.

`PROJECT.md` is the only implicit project boundary. Git roots, record folders, and the current directory do not establish project context.

When the resolver returns an owning studio, `standards/` contains firm-wide standards and reusable templates, while `references/` contains external source material such as code references. Load only files relevant to the task. Keep project work and outputs in the selected project, and do not treat a stored external reference as proof that it is current or applicable.

The resolver accepts format version 3 only. It reads the Projects table strictly between its section markers and maps values by header name, so unrelated Markdown tables and column reordering cannot change project identity. A studio-owned project is valid only when every registry identity field matches `PROJECT.md`, its immutable uppercase Project ID equals its directory name, and its ID and path each have one unique registry row; status is never part of that uniqueness test. `no-projects` means the bounded registry truly has no rows, not that its rows failed validation.
