# Claude Code Skills for AEC & Workplace Strategy

> Slash-command skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that bring domain expertise to architecture, real estate, and workplace design. Clone, symlink, type `/skill-name` — done.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Available Skills

### [`/workplace-programmer`](./workplace-programmer)

AI workplace strategy consultant that builds office space programs through conversation. Give it a headcount, square footage, and work policy — get area splits, room schedules, seat counts, and exportable reports backed by research from JLL, CBRE, Gensler, and others.

### [`/zoning`](./zoning)

Zoning envelope analyzer for lots in Maldonado, Uruguay. Paste GIS JSON from the [municipal cadastral portal](https://ide.maldonado.gub.uy/), get a full building envelope analysis — zone determination, setbacks, height limits, FOS/FOT, and an ASCII buildable-area sketch — all referenced to the TONE regulations.

## Quick Start

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
cd skills

# Symlink the skills you want (recommended — stays in sync with updates)
ln -s "$(pwd)/workplace-programmer" ~/.claude/skills/workplace-programmer
ln -s "$(pwd)/zoning" ~/.claude/skills/zoning
```

Then in Claude Code:

```
/workplace-programmer 30,000 RSF tech company, 200 people, 3 days hybrid
/zoning
```

## What Are Claude Code Skills?

[Skills](https://docs.anthropic.com/en/docs/claude-code/skills) are markdown files that extend Claude Code with domain knowledge and workflows. When you type a slash command, Claude reads the skill's `SKILL.md` and any referenced data files, then follows the instructions as a specialist in that domain.

Skills are:
- **Local** — they live in `~/.claude/skills/` on your machine
- **Portable** — just markdown and JSON, no dependencies
- **Composable** — use them alongside any other Claude Code workflow
- **Editable** — customize the persona, data, or workflow by editing the files

## Contributing

Have a skill for the built environment? Open a PR. Each skill needs:

1. A `SKILL.md` with clear instructions and domain knowledge
2. A `README.md` with install, usage, and sample output
3. Any supporting data files in a `data/` or `normativa/` directory

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.
