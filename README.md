# Skills for Architects

> Agentic skills, commands, and plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — from programming to site planning, specifications, and creative delivery.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**13 skills** and **3 commands** across **4 plugins** for architects, designers, and AEC professionals.

## Plugins

| Plugin | Skills | Commands | Description |
|--------|--------|----------|-------------|
| [programming](./programming) | 2 | 1 | Workplace strategy: space programs, occupancy loads, IBC compliance. |
| [site-planning-zoning](./site-planning-zoning) | 3 | 1 | Site research, zoning envelope analysis, and design brief building. |
| [specifications-data](./specifications-data) | 6 | 1 | FF&E spec extraction, cleanup, image processing, CSI specs, and punch lists. |
| [creative-presenting](./creative-presenting) | 2 | — | Slide deck generation and color palette creation. |

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
| `/site-due-diligence` | site-planning-zoning | Full site due diligence — site analysis followed by zoning envelope. |
| `/spec-package` | specifications-data | Full FF&E pipeline — fetch specs, clean data, process images. |

## All Skills

### Programming

| Skill | Description |
|-------|-------------|
| [`/workplace-programmer`](./programming/skills/workplace-programmer) | AI workplace strategy consultant — area splits, room schedules, seat counts from 10 archetypes and 43 research findings. |
| [`/occupancy-calculator`](./programming/skills/occupancy-calculator) | IBC occupancy load calculator — per-area loads from Table 1004.5, egress requirements, use group classification. |

### Site Planning & Zoning

| Skill | Description |
|-------|-------------|
| [`/site-analysis-generator`](./site-planning-zoning/skills/site-analysis-generator) | Comprehensive site research — climate, zoning, transit, demographics, neighborhood context from an address. |
| [`/zoning-analyzer`](./site-planning-zoning/skills/zoning-analyzer) | Buildable envelope analysis for lots in Maldonado, Uruguay — setbacks, heights, FOS/FOT from TONE regulations. |
| [`/design-brief-builder`](./site-planning-zoning/skills/design-brief-builder) | Structured design briefs from vague requirements — program, adjacencies, criteria, and open questions. |

### Specifications & Data

| Skill | Description |
|-------|-------------|
| [`/product-spec-bulk-fetch`](./specifications-data/skills/product-spec-bulk-fetch) | Extract FF&E specs from product URLs at scale — names, dimensions, materials, pricing, images. |
| [`/product-spec-bulk-cleanup`](./specifications-data/skills/product-spec-bulk-cleanup) | Normalize messy FF&E schedules — casing, dimensions, materials, categories, deduplication. |
| [`/product-spec-pdf-parser`](./specifications-data/skills/product-spec-pdf-parser) | Extract FF&E specs from PDFs — price books, fact sheets, spec sheets into standardized schedules. |
| [`/product-image-processor`](./specifications-data/skills/product-image-processor) | Batch download, resize, and remove backgrounds from product images. |
| [`/spec-writer`](./specifications-data/skills/spec-writer) | CSI outline specs from a materials list — MasterFormat divisions, three-part sections, performance criteria. |
| [`/redline-punch-list`](./specifications-data/skills/redline-punch-list) | Field notes to structured punch lists — CSI divisions, trade assignments, priority levels. |

### Creative & Presenting

| Skill | Description |
|-------|-------------|
| [`/slide-deck-generator`](./creative-presenting/skills/slide-deck-generator) | Self-contained HTML slide decks — Helvetica, editorial layout, 22 slide types, keyboard/touch navigation. |
| [`/color-palette-generator`](./creative-presenting/skills/color-palette-generator) | Color palettes from descriptions, images, or hex codes — swatches, WCAG contrast, example pairings. |

## What Are Skills and Commands?

- **Skills** are domain knowledge units (nouns). They teach Claude about a design topic — like calculating occupancy loads, analyzing zoning envelopes, or writing CSI specs.
- **Commands** are workflows (verbs). They chain multiple skills together to accomplish a task — like running a full FF&E extraction pipeline or complete site due diligence.

## Contributing

Have a skill for the built environment? Open a PR. Each skill needs:

1. A `SKILL.md` with clear instructions and domain knowledge
2. A `README.md` with install, usage, and sample output
3. Any supporting data files in a `data/` or `normativa/` directory

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.
