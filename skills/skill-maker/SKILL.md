---
name: skill-maker
description: Scaffold a new Claude Code skill following this repo's conventions — copy a canonical template, apply the PATTERNS.md checklist, verify with lint. Use when the user runs /as:skill-maker, asks to create or package a new skill, or wants to turn a procedure into a slash command.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
---

# /as:skill-maker — Scaffold a New Skill

You turn a described procedure into a working skill: a directory with a `SKILL.md` and a `README.md` that follows this repo's conventions. Input is the user's request; output is a card Claude can follow.

## Usage

```
/as:skill-maker a skill that turns raw site photos into a numbered photo log
/as:skill-maker package our submittal-review checklist as a slash command
/as:skill-maker <any procedure worth repeating>
```

## Hard rule: no routine interview

Derive everything — name, description, tools, steps — from the request. Do not ask routine setup questions. Ask exactly one question only when the skill's purpose is genuinely indecipherable, the user requests a global skill without explicitly authorizing the global target, or an existing target would have to be updated. Otherwise make the reasonable call and note it when presenting the result.

## Anatomy of what you're producing

A skill is a procedure card. Four load-bearing parts:

| Part | Job |
|---|---|
| `name` | Kebab-case, matches the directory, becomes the slash command |
| `description` | The **trigger**, not a label — how Claude knows to reach for the card unasked |
| `allowed-tools` | The blast radius — the minimum set the steps need |
| Steps | The procedure itself: numbered, concrete, in execution order |

## Step 1 — Scaffold from the template

Resolve the bundled template from `${CLAUDE_PLUGIN_ROOT}/skills/skill-maker/templates/example-skill/` and adapt every line. **This skill's output is files on disk, not a proposal**: for a new, safely resolved target, state the exact path and write both `SKILL.md` and `README.md` without presenting a draft first. Do not promise that a permission prompt will appear; permission behavior depends on the active Claude Code settings. If the bundled template can't be located, scaffold from the Anatomy table above.

- **Name**: kebab-case, derived from the request. Directory name and frontmatter `name` must match.
- **Description**: trigger-phrased — what the skill does AND when to invoke it, with phrases the user would actually say. A description that only labels never fires.
- **allowed-tools**: only what the steps actually need. Read-only skill? No Write. No shell work? No Bash.
- **Steps**: concrete and numbered, in the order the work happens. Include an output-format block when the skill produces a document or record. Nothing from the template survives verbatim except the shape.
- **README.md**: adapt alongside — what it does, usage, nothing more.

**Where it goes** — resolve catalog, studio, and project boundaries before choosing a target:

1. Run `git rev-parse --show-toplevel` and inspect its `.claude-plugin/plugin.json`. If its `name` is `as`, this is the public catalog even when the current directory is nested inside it. Catalog detection has highest priority.
2. Otherwise search upward for the nearest `STUDIO.md`. Its parent is the studio root, including when the current directory is a descendant project. This is the ordinary firm-skill boundary.
3. Separately resolve the nearest `PROJECT.md` or project marker only for an explicitly requested project-only skill. Do not let a nearer project silently override a resolved studio.
4. If no catalog, studio, or project marker is found, say that the current directory is only a fallback and ask the single allowed target question before writing.
5. Resolve the target from the table, then show the exact absolute path before writing. State that the installed plugin cache is never a private-skill target.
6. Check the target before creating anything. If it already contains `SKILL.md` or `README.md`, stop without editing. Update it only when the user explicitly asked to update that named skill; otherwise derive a distinct name or ask one question.

| Condition | Target |
|---|---|
| project root is the skills-for-architects repo — `.claude-plugin/plugin.json` has name `as` | `{project-root}/skills/{name}/` |
| nearest `STUDIO.md` exists and the user did not explicitly request narrower scope | `{studio-root}/.claude/skills/{name}/` |
| user explicitly requests a project-only skill | `{project-root}/.claude/skills/{name}/` |
| user explicitly asks for a global skill | `$HOME/.claude/skills/{name}/` |

For a project-only skill, warn that Claude Code’s discovery is narrower and that starting inside a nested project repository may not load parent studio configuration. Do not duplicate the skill as a workaround. For a studio skill created after the session began, mention that a restart may be required only when Claude Code was not already watching the top-level `.claude/skills/` directory.

## Step 2 — Apply the conventions checklist

Read `${CLAUDE_PLUGIN_ROOT}/PATTERNS.md` at runtime and apply its rules to the scaffolded skill. Do not work from a remembered copy; the file is the authority.

Enforce these portable essentials regardless of target:

1. Description states **what** and **when**.
2. `README.md` exists alongside `SKILL.md`.
3. No `~/` paths in the SKILL.md body — they break on every machine but the author's. Use project-relative paths, or `$HOME` in the rare case a home path is the point.
4. `allowed-tools` is the minimum blast radius for the steps as written.
5. If the skill produces code, zoning, or life-safety analysis, its steps must instruct ending every report with the canonical disclaimer block followed by the marker `<!-- architecture-studio:requires-disclaimer -->` — see how `skills/occupancy-calculator/SKILL.md` does it.

## Step 3 — Verify

For every target, run `bash "${CLAUDE_PLUGIN_ROOT}/skills/skill-maker/scripts/validate-skill.sh" <absolute-skill-directory>` and fix every finding. This deterministic check verifies the directory/name contract, required files and frontmatter, and portable paths.

**Inside the repo:** after the scaffold validator passes, run `${CLAUDE_PLUGIN_ROOT}/scripts/lint.sh` from the resolved repository root and fix findings until green. Repository lint additionally verifies catalog membership and shared plugin contracts. No aggregate skill count needs updating.

**Outside the repo:** run the Step 2 checklist explicitly, item by item, and say so. The house lint applies only to catalog contributions — a studio-owned, project-only, or global private skill owes it nothing.

## Finish

The job is done only when both files exist on disk — confirm their paths, then show the finished SKILL.md to the user. Tell them:

- **How to invoke it**: studio and project skills use `/{name}` when Claude Code discovers that workspace scope; catalog contributions use the `/as:{name}` namespace (for example, `/as:site-history`). If the skill was created after this session began, restart Claude Code from the studio or project root when it does not appear in autocomplete.
- **How to iterate**: edit the SKILL.md like any file — change a step, tighten the description, run it again.

Never commit anything; that's the author's call.
