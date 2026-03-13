# /design-brief-builder

Turns vague client requirements into structured design briefs for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Covers program, adjacencies, design criteria, technical requirements, and open questions — ready for schematic design.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/design-brief-builder" ~/.claude/skills/design-brief-builder
```

## Usage

Provide project context up front:

```
/design-brief-builder 5-story mixed-use in Brooklyn, ground floor retail, 40 residential units above
```

Or paste a meeting transcript / client email:

```
/design-brief-builder [paste notes here]
```

Or start with no context and let the skill run discovery:

```
/design-brief-builder
```

The skill asks follow-up questions in batches of 3-5, then generates a `.md` brief to `~/Documents/design-brief-[project-slug].md`.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Persona, discovery flow, brief structure, formatting rules |

## License

MIT
