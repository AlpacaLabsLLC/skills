# Skills for Architects

> Agentic skills, commands, and plugins for Claude — use with [Claude Desktop (Cowork)](https://claude.ai/download) or [Claude Code](https://docs.anthropic.com/en/docs/claude-code). From site research to zoning, programming, specifications, and creative delivery.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**17 skills** and **3 commands** across **6 plugins** for architects, designers, and AEC professionals.

## Prerequisites

- **Claude Desktop** (recommended) or **Claude Code CLI**
- A [Claude subscription](https://claude.ai) (Pro, Team, or Enterprise)
- **Git** — to clone this repo and stay in sync

## What Are Skills and Commands?

- **Skills** are domain knowledge units (nouns). They teach Claude about a design topic — like calculating occupancy loads, analyzing zoning envelopes, or writing CSI specs.
- **Commands** are workflows (verbs). They chain multiple skills together to accomplish a task — like running a full FF&E extraction pipeline or complete site due diligence.
- **Plugins** are the containers. Each groups related skills and commands by topic.

## Quick Start

### Option A: Claude Desktop (Cowork) — recommended

Clone the repo and symlink the skills you want:

```bash
# Clone
git clone https://github.com/AlpacaLabsLLC/skills-for-architects.git ~/skills-for-architects

# Symlink all skills at once
for plugin in ~/skills-for-architects/0*/skills/*/; do
  ln -s "$plugin" ~/.claude/skills/$(basename "$plugin")
done

# Verify — open Claude Desktop and type:
/skills
```

To update later:

```bash
cd ~/skills-for-architects && git pull
```

Symlinks stay in sync automatically.

### Option B: Claude Code (CLI)

```bash
# Install a single plugin
claude install github:AlpacaLabsLLC/skills-for-architects/01-site-planning

# Or install all plugins
claude install github:AlpacaLabsLLC/skills-for-architects
```

Skills are symlinked into `~/.claude/skills/` so they stay in sync when you update.

## Where to Start

Pick your task, run the skill:

| I need to... | Run this | Plugin |
|--------------|----------|--------|
| Research a new site | `/environmental-analysis 123 Main St` | Site Planning |
| Understand neighborhood context | `/neighborhood-history 123 Main St` | Site Planning |
| Check NYC zoning | `/zoning-analysis-nyc 123 Main St` | Zoning Analysis |
| Build a space program | `/workplace-programmer` | Programming |
| Calculate occupancy loads | `/occupancy-calculator` | Programming |
| Write CSI specs | `/spec-writer` | Specifications |
| Find FF&E products | `/product-research` | Materials Research |
| Generate a slide deck | `/slide-deck-generator Q1 results` | Presentations |
| Full NYC site due diligence | `/site-due-diligence-nyc 123 Main St` | Site Planning |

## Plugins

Organized by project lifecycle — from site research through delivery.

| # | Plugin | Skills | Commands | Description |
|---|--------|--------|----------|-------------|
| 1 | [01-site-planning](./01-site-planning) | 5 | 1 | Site research: environmental, mobility, demographics, neighborhood history, design briefs. |
| 2 | [02-zoning-analysis](./02-zoning-analysis) | 1 | — | Buildable envelope analysis from zoning regulations and public data APIs. |
| 3 | [03-programming](./03-programming) | 2 | 1 | Workplace strategy: space programs, occupancy loads, IBC compliance. |
| 4 | [04-specifications](./04-specifications) | 2 | — | CSI outline specs and construction punch lists. |
| 5 | [05-materials-research](./05-materials-research) | 5 | 1 | FF&E product research, spec extraction, cleanup, and image processing. |
| 6 | [06-presentations](./06-presentations) | 2 | — | Slide deck generation and color palette creation. |

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
| [`/product-research`](./05-materials-research/skills/product-research) | Brief-based product research — describe what you need, Claude searches and returns curated candidates. |
| [`/product-spec-bulk-fetch`](./05-materials-research/skills/product-spec-bulk-fetch) | Extract FF&E specs from product URLs at scale — names, dimensions, materials, pricing, images. |
| [`/product-spec-bulk-cleanup`](./05-materials-research/skills/product-spec-bulk-cleanup) | Normalize messy FF&E schedules — casing, dimensions, materials, categories, deduplication. |
| [`/product-spec-pdf-parser`](./05-materials-research/skills/product-spec-pdf-parser) | Extract FF&E specs from PDFs — price books, fact sheets, spec sheets into standardized schedules. |
| [`/product-image-processor`](./05-materials-research/skills/product-image-processor) | Batch download, resize, and remove backgrounds from product images. |

### 6. Presentations

| Skill | Description |
|-------|-------------|
| [`/slide-deck-generator`](./06-presentations/skills/slide-deck-generator) | Self-contained HTML slide decks — Helvetica, editorial layout, 22 slide types, keyboard/touch navigation. |
| [`/color-palette-generator`](./06-presentations/skills/color-palette-generator) | Color palettes from descriptions, images, or hex codes — swatches, WCAG contrast, example pairings. |

## Contributing

Want to add a skill for the built environment? Here's how:

1. **Fork** this repo
2. Create your skill in the appropriate plugin folder (or propose a new plugin)
3. Each skill needs:
   - A `SKILL.md` with clear instructions and domain knowledge
   - A `README.md` with install, usage, and sample output
   - Any supporting data files in a `data/` or `zoning-rules/` directory
4. Open a **pull request** — describe what the skill does, how you tested it, and sample output

For guidance on organizing skills across a team, read [Distributing Skills to Teams](https://alpa.llc/articles/distributing-skills-to-teams).

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.

**Read more:** [Claude Code Cheat Sheet for Architects](https://alpa.llc/articles/claude-code-cheat-sheet) · [Distributing Skills to Teams](https://alpa.llc/articles/distributing-skills-to-teams)
