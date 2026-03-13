# Skills for Architects

> Agentic skills, commands, and plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — from programming to site planning, specifications, and creative delivery.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**13 skills** and **3 commands** across **6 plugins** for architects, designers, and AEC professionals.

## What Are Skills and Commands?

- **Skills** are domain knowledge units (nouns). They teach Claude about a design topic — like calculating occupancy loads, analyzing zoning envelopes, or writing CSI specs.
- **Commands** are workflows (verbs). They chain multiple skills together to accomplish a task — like running a full FF&E extraction pipeline or complete site due diligence.
- **Plugins** are the containers. Each groups related skills and commands by topic.

## Plugins

| Plugin | Skills | Commands | Description |
|--------|--------|----------|-------------|
| [programming](./programming) | 2 | 1 | Workplace strategy: space programs, occupancy loads, IBC compliance. |
| [site-planning](./site-planning) | 2 | 1 | Site research, analysis, and design brief building. |
| [zoning-analysis](./zoning-analysis) | 1 | — | Buildable envelope analysis from zoning regulations and GIS data. |
| [specifications](./specifications) | 2 | — | CSI outline specs and construction punch lists. |
| [data-management](./data-management) | 4 | 1 | FF&E spec extraction, cleanup, and image processing. |
| [presentations](./presentations) | 2 | — | Slide deck generation and color palette creation. |

## Quick Start

### Install a Single Plugin

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/programming
```

### Install All Plugins

```bash
claude install github:AlpacaLabsLLC/skills-for-architects
```

Skills are symlinked into `~/.claude/skills/` so they stay in sync when you update.

## All Commands

| Command | Plugin | Description |
|---------|--------|-------------|
| `/space-program` | programming | Build a complete space program — occupancy loads then workplace programming. |
| `/site-due-diligence` | site-planning | Full site due diligence — site analysis followed by zoning envelope. |
| `/spec-package` | data-management | Full FF&E pipeline — fetch specs, clean data, process images. |

## All Skills

### Programming

| Skill | Description |
|-------|-------------|
| [`/workplace-programmer`](./programming/skills/workplace-programmer) | AI workplace strategy consultant — area splits, room schedules, seat counts from 10 archetypes and 43 research findings. |
| [`/occupancy-calculator`](./programming/skills/occupancy-calculator) | IBC occupancy load calculator — per-area loads from Table 1004.5, egress requirements, use group classification. |

### Site Planning

| Skill | Description |
|-------|-------------|
| [`/site-analysis-generator`](./site-planning/skills/site-analysis-generator) | Comprehensive site research — climate, zoning, transit, demographics, neighborhood context from an address. |
| [`/design-brief-builder`](./site-planning/skills/design-brief-builder) | Structured design briefs from vague requirements — program, adjacencies, criteria, and open questions. |

### Zoning

| Skill | Description |
|-------|-------------|
| [`/zoning-analysis-nyc`](./zoning-analysis/skills/zoning-analysis-nyc) | Buildable envelope analysis for lots in New York City — FAR, height, setbacks, use groups from PLUTO data and the Zoning Resolution. |

### Specifications

| Skill | Description |
|-------|-------------|
| [`/spec-writer`](./specifications/skills/spec-writer) | CSI outline specs from a materials list — MasterFormat divisions, three-part sections, performance criteria. |
| [`/redline-punch-list`](./specifications/skills/redline-punch-list) | Field notes to structured punch lists — CSI divisions, trade assignments, priority levels. |

### Data Management

| Skill | Description |
|-------|-------------|
| [`/product-spec-bulk-fetch`](./data-management/skills/product-spec-bulk-fetch) | Extract FF&E specs from product URLs at scale — names, dimensions, materials, pricing, images. |
| [`/product-spec-bulk-cleanup`](./data-management/skills/product-spec-bulk-cleanup) | Normalize messy FF&E schedules — casing, dimensions, materials, categories, deduplication. |
| [`/product-spec-pdf-parser`](./data-management/skills/product-spec-pdf-parser) | Extract FF&E specs from PDFs — price books, fact sheets, spec sheets into standardized schedules. |
| [`/product-image-processor`](./data-management/skills/product-image-processor) | Batch download, resize, and remove backgrounds from product images. |

### Presentations

| Skill | Description |
|-------|-------------|
| [`/slide-deck-generator`](./presentations/skills/slide-deck-generator) | Self-contained HTML slide decks — Helvetica, editorial layout, 22 slide types, keyboard/touch navigation. |
| [`/color-palette-generator`](./presentations/skills/color-palette-generator) | Color palettes from descriptions, images, or hex codes — swatches, WCAG contrast, example pairings. |

## Contributing

Have a skill for the built environment? Open a PR. Each skill needs:

1. A `SKILL.md` with clear instructions and domain knowledge
2. A `README.md` with install, usage, and sample output
3. Any supporting data files in a `data/` or `normativa/` directory

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.
