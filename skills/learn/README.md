# Learn — Codex and Claude Code

A resumable, hands-on course teaching architects how to use Codex or Claude Code. Six modules, most ~15–20 minutes, each built around an exercise on the bundled sandbox project — a fictional Brooklyn art museum planning a rooftop expansion (`sandbox/art-museum/`, six deliberately messy files).

## Usage

| Host | Start | Resume |
|---|---|---|
| Codex | `$learn` | `$learn` reads `PROGRESS.md` and resumes |
| Claude Code | `/as:learn` | `/as:learn` reads `PROGRESS.md` and resumes |

Progress is tracked in `PROGRESS.md` in the practice folder (default `~/architecture-studio-101`; the earlier `~/claude-code-101` location is recognized). Delete it to restart the course.

On Claude Code, the first-session notice points to `/as:studio` or `/as:learn`. Codex has no equivalent Claude hook; start with `$studio` or `$learn` directly.

## Design

- **Do, then explain** — the learner's hands are on the keyboard within a few sentences of any teach beat.
- **The tutor never does the exercise for them** — it guides and reviews.
- **Studio analogies throughout** — `AGENTS.md` (Codex) or `CLAUDE.md` (Claude Code) is the standards binder, skills are laminated procedures, markdown is plain paper.
- **Three ideas thread the course**: this version stores project files locally while sending prompts and needed file contents to the configured Codex or Claude service, Architecture Studio is an open-source harness on both hosts (fork it, make it your own), and course/project memory is plain files you can read. Future cloud-based versions may require accounts and work differently.
- **One worksurface for firm extensions**: the course uses a sandbox-local skill, while real firm-created skills default to the initialized studio’s `.agents/skills/` on Codex or `.claude/skills/` on Claude Code; ordinary users do not maintain the installed plugin source.
- **Module 6 closes with real work** — a source-check drill (trace claims to their lines, then ask about what the document *doesn't* say), a short professional checklist (firm policy, low-stakes, work on a copy — recommended, never imposed), and one real task end to end. Data privacy is taught back in Module 2, where consent is taught. The learner can quit `$learn` or `/as:learn` at any moment, no questions asked.
- The sandbox files are engineered: the CSV has a duplicate row, mixed units, and a TBD; `IMG_4032.txt` is a mislabeled voice memo; `Scan_001.txt` is a regulatory excerpt with enough specifics to make an invented claim plausible — and deliberate silences to plant it in.

An advanced track — bigger jobs, plan mode, subagents, skill authorship in depth, running the office skill library — is planned as a follow-on course; the `examples/` skills below are its precedent material.

## Bundled material

| Directory | Used in | Contents |
|-----------|---------|----------|
| `sandbox/` | Modules 1–6 | The fictional Greenpoint Museum of Art — six deliberately messy files with engineered flaws |
| `templates/` | Module 3 | `office-CLAUDE.md`, copied as `AGENTS.md` on Codex or `CLAUDE.md` on Claude Code |
| `examples/` | Advanced track (planned) | Three finished skills to study and modify; invoke them as `$ascii-name`, `$clean-downloads`, `$tasklist` on Codex or `/ascii-name`, `/clean-downloads`, `/as:tasklist` on Claude Code |
