# /as:skill-maker

Scaffolds a new skill that follows this repo's conventions — copies the bundled canonical template, adapts it to the request, applies the [`PATTERNS.md`](../../PATTERNS.md) checklist, verifies. Inside an Architecture Studio workspace, firm skills default to `.agents/skills/` on Codex or `.claude/skills/` on Claude Code; the installed plugin cache is never modified.

## Usage

```
/as:skill-maker a skill that turns raw site photos into a numbered photo log
/as:skill-maker package our submittal-review checklist as a slash command
/as:skill-maker a skill that drafts meeting minutes from a transcript
```

No routine interview — name, description, tools, and steps are derived from the request. Existing targets and unauthorized global writes stop before editing.

## The three steps

1. **Scaffold** — resolve catalog, studio, project, and active-harness boundaries; copy the bundled template; adapt it with a kebab-case name, trigger-phrased description, host-appropriate tool metadata, and concrete steps. Target `skills/` in this repo, the active host's studio skill root for normal firm work, or project/global scope only when explicitly requested. Existing targets are never overwritten implicitly.
2. **Checklist** — apply [`PATTERNS.md`](../../PATTERNS.md) plus the portable essentials: description states what AND when, README alongside, no `~/` paths, minimum blast radius, disclaimer marker for regulatory output.
3. **Verify** — in this repo, [`scripts/lint.sh`](../../scripts/lint.sh) until green (the new skill must appear in the catalog; no aggregate count needs updating). Elsewhere, the portable checklist runs explicitly.

## House rules vs. your rules

Inside this repo the lint is law: catalog coverage, frontmatter, links, markers — enforced on every commit. Outside it, none of that applies. The portable checklist (trigger description, README, no home paths, minimal tools) is what makes a skill good anywhere, and it's all a private skill owes. Adopt the rest if you like how it feels.
