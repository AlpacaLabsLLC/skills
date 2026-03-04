# Claude Code Skills for Architects & Designers

> Slash-command skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that bring domain expertise to architecture, real estate, and workplace design. Clone, symlink, type `/skill-name` — done.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Available Skills

### [`/workplace-programmer`](./workplace-programmer)

AI workplace strategy consultant that builds office space programs through conversation. Give it a headcount, square footage, and work policy — get area splits, room schedules, seat counts, and exportable reports backed by 10 archetypes, 43 research findings from JLL, CBRE, Gensler, Hassell (6 years of Workplace Futures Survey), and others.

### [`/occupancy-calculator`](./occupancy-calculator)

IBC occupancy load calculator. Describe your building or paste a room schedule — get per-area occupant loads from IBC Table 1004.5, with gross vs net area handling, use group classification, egress requirements, and exportable reports. Supports IBC 2021 with NYC Building Code variant notes. Integrates with `/workplace-programmer` to calculate occupancy from existing space programs.

### [`/zoning-analyzer`](./zoning-analyzer)

Zoning envelope analyzer for lots in Maldonado, Uruguay. Paste GIS JSON from the [municipal cadastral portal](https://ide.maldonado.gub.uy/), get a full building envelope analysis — zone determination, setbacks, height limits, FOS/FOT, and an ASCII buildable-area sketch — all referenced to the TONE regulations.

### [`/product-spec-bulk-fetch`](./product-spec-bulk-fetch)

Bulk FF&E product spec extractor. Feed it a list of product page URLs — get a standardized schedule with names, dimensions, materials, pricing, and images extracted from each page using AI. Outputs to CSV, Google Sheets, or markdown.

### [`/product-spec-bulk-cleanup`](./product-spec-bulk-cleanup)

FF&E schedule normalizer. Takes a messy furniture schedule — mixed casing, combined dimensions, Spanish material names, inconsistent categories — and cleans it into consistent, procurement-ready data. Pairs with `/product-spec-bulk-fetch` for a full fetch → cleanup pipeline.

### [`/product-image-processor`](./product-image-processor)

Batch product image processor. Read image URLs from a Google Sheet, download at full resolution, normalize sizing (max 2000px, PNG), and remove backgrounds via rembg — saving output at each stage. Pairs with `/product-spec-bulk-fetch` for a full spec → image pipeline.

## Quick Start

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
cd skills

# Symlink the skills you want (recommended — stays in sync with updates)
ln -s "$(pwd)/workplace-programmer" ~/.claude/skills/workplace-programmer
ln -s "$(pwd)/occupancy-calculator" ~/.claude/skills/occupancy-calculator
ln -s "$(pwd)/zoning-analyzer" ~/.claude/skills/zoning-analyzer
ln -s "$(pwd)/product-spec-bulk-fetch" ~/.claude/skills/product-spec-bulk-fetch
ln -s "$(pwd)/product-spec-bulk-cleanup" ~/.claude/skills/product-spec-bulk-cleanup
ln -s "$(pwd)/product-image-processor" ~/.claude/skills/product-image-processor
```

Then in Claude Code:

```
/workplace-programmer 30,000 RSF tech company, 200 people, 3 days hybrid
/occupancy-calculator 50,000 SF office building, 3 floors
/zoning-analyzer
/product-spec-bulk-fetch https://www.hermanmiller.com/products/seating/lounge-chairs/eames-lounge-chair/
/product-spec-bulk-cleanup ~/Documents/ffe-schedule.csv
/product-image-processor
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
