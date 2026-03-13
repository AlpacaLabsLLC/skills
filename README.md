# Skills for Architects

> Agentic skills, commands, and plugins for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — from site research to zoning, programming, specifications, and creative delivery.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**17 skills** and **3 commands** across **6 plugins** for architects, designers, and AEC professionals.

## What Are Skills and Commands?

- **Skills** are domain knowledge units (nouns). They teach Claude about a design topic — like calculating occupancy loads, analyzing zoning envelopes, or writing CSI specs.
- **Commands** are workflows (verbs). They chain multiple skills together to accomplish a task — like running a full FF&E extraction pipeline or complete site due diligence.
- **Plugins** are the containers. Each groups related skills and commands by topic.

## Plugins

Organized by project lifecycle — from site research through delivery.

| # | Plugin | Skills | Commands | Description |
|---|--------|--------|----------|-------------|
| 1 | [01-site-planning](./01-site-planning) | 5 | 1 | Site research: environmental, mobility, demographics, neighborhood history, design briefs. |
| 2 | [02-zoning-analysis](./02-zoning-analysis) | 1 | — | Buildable envelope analysis from zoning regulations and public data APIs. |
| 3 | [03-programming](./03-programming) | 2 | 1 | Workplace strategy: space programs, occupancy loads, IBC compliance. |
| 4 | [04-specifications](./04-specifications) | 2 | — | CSI outline specs and construction punch lists. |
| 5 | [05-product-materials](./05-product-materials) | 5 | 1 | FF&E product research, spec extraction, cleanup, and image processing. |
| 6 | [06-presentations](./06-presentations) | 2 | — | Slide deck generation and color palette creation. |

## Quick Start

### Install a Single Plugin

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/01-site-planning
```

### Install All Plugins

```bash
claude install github:AlpacaLabsLLC/skills-for-architects
```

Skills are symlinked into `~/.claude/skills/` so they stay in sync when you update.

## All Commands

| Command | Plugin | Description |
|---------|--------|-------------|
| `/site-due-diligence-nyc` | site-planning | Full NYC site due diligence — environmental, mobility, demographics, history, and zoning. |
| `/space-program` | programming | Build a complete space program — occupancy loads then workplace programming. |
| `/spec-package` | product-materials | Full FF&E pipeline — fetch specs, clean data, process images. |

## All Skills

### 1. Site Planning

| Skill | Description |
|-------|-------------|
| [`/environmental-analysis`](./01-site-planning/skills/environmental-analysis) | Climate and environmental site analysis — temperature, precipitation, wind, sun angles, flood zones, seismic risk, soil, topography. |
| [`/mobility-analysis`](./01-site-planning/skills/mobility-analysis) | Transit and mobility site analysis — subway, bus, bike, pedestrian infrastructure, walk scores, airport access. |
| [`/demographics-analysis`](./01-site-planning/skills/demographics-analysis) | Demographics and market site analysis — population, income, age, housing market, employment. |
| [`/neighborhood-history`](./01-site-planning/skills/neighborhood-history) | Neighborhood context and history — adjacent uses, architectural character, landmarks, commercial activity, planned development. |
| [`/design-brief-builder`](./01-site-planning/skills/design-brief-builder) | Structured design briefs from vague requirements — program, adjacencies, criteria, and open questions. |

### 2. Zoning Analysis

| Skill | Description |
|-------|-------------|
| [`/zoning-analysis-nyc`](./02-zoning-analysis/skills/zoning-analysis-nyc) | Buildable envelope analysis for lots in New York City — FAR, height, setbacks, use groups from PLUTO data and the Zoning Resolution. |

### 3. Programming

| Skill | Description |
|-------|-------------|
| [`/workplace-programmer`](./03-programming/skills/workplace-programmer) | AI workplace strategy consultant — area splits, room schedules, seat counts from 10 archetypes and 43 research findings. |
| [`/occupancy-calculator`](./03-programming/skills/occupancy-calculator) | IBC occupancy load calculator — per-area loads from Table 1004.5, egress requirements, use group classification. |

### 4. Specifications

| Skill | Description |
|-------|-------------|
| [`/spec-writer`](./04-specifications/skills/spec-writer) | CSI outline specs from a materials list — MasterFormat divisions, three-part sections, performance criteria. |
| [`/redline-punch-list`](./04-specifications/skills/redline-punch-list) | Field notes to structured punch lists — CSI divisions, trade assignments, priority levels. |

### 5. Product & Materials Research

| Skill | Description |
|-------|-------------|
| [`/product-research`](./05-product-materials/skills/product-research) | Product research companion — captures and organizes products into a persistent library as you browse. |
| [`/product-spec-bulk-fetch`](./05-product-materials/skills/product-spec-bulk-fetch) | Extract FF&E specs from product URLs at scale — names, dimensions, materials, pricing, images. |
| [`/product-spec-bulk-cleanup`](./05-product-materials/skills/product-spec-bulk-cleanup) | Normalize messy FF&E schedules — casing, dimensions, materials, categories, deduplication. |
| [`/product-spec-pdf-parser`](./05-product-materials/skills/product-spec-pdf-parser) | Extract FF&E specs from PDFs — price books, fact sheets, spec sheets into standardized schedules. |
| [`/product-image-processor`](./05-product-materials/skills/product-image-processor) | Batch download, resize, and remove backgrounds from product images. |

### 6. Presentations

| Skill | Description |
|-------|-------------|
| [`/slide-deck-generator`](./06-presentations/skills/slide-deck-generator) | Self-contained HTML slide decks — Helvetica, editorial layout, 22 slide types, keyboard/touch navigation. |
| [`/color-palette-generator`](./06-presentations/skills/color-palette-generator) | Color palettes from descriptions, images, or hex codes — swatches, WCAG contrast, example pairings. |

## Contributing

Have a skill for the built environment? Open a PR. Each skill needs:

1. A `SKILL.md` with clear instructions and domain knowledge
2. A `README.md` with install, usage, and sample output
3. Any supporting data files in a `data/` or `zoning-rules/` directory

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.
