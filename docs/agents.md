# Agents

Agents are autonomous specialists that orchestrate multiple skills to complete a complex task. Unlike skills (single-purpose, invoked directly), agents assess the situation, choose a path, and exercise judgment.

All seven agents ship with the **Architecture Studio** plugin (`as`; this `agents/` directory), so installing the plugin registers each one as a native Claude Code subagent — Claude can delegate to it automatically, and `/as:studio` routes to it by name.

## Available Agents

| Agent | Domain | Skills it orchestrates |
|-------|--------|----------------------|
| [site-planner](../agents/site-planner.md) | Site Planning | environmental-analysis, mobility-analysis, demographics-analysis, site-history |
| [nyc-zoning-expert](../agents/nyc-zoning-expert.md) | Due Diligence + Zoning | nyc-landmarks, nyc-dob-permits, nyc-dob-violations, nyc-acris, nyc-hpd, nyc-bsa, nyc-property-report, zoning-analysis-nyc, zoning-envelope |
| [workplace-strategist](../agents/workplace-strategist.md) | Programming | occupancy-calculator, workplace-programmer |
| [sustainability-specialist](../agents/sustainability-specialist.md) | Sustainability | epd-research, epd-compare, epd-parser, epd-to-spec |
| [product-and-materials-researcher](../agents/product-and-materials-researcher.md) | Materials Research | product-research, product-spec-bulk-fetch, product-spec-pdf-parser, product-match, product-enrich |
| [ffe-designer](../agents/ffe-designer.md) | FF&E Design | product-pair, product-data-cleanup, product-data-import, product-enrich, product-image-processor, csv-to-sif, sif-to-csv |
| [brand-manager](../agents/brand-manager.md) | Presentations | slide-deck-generator, color-palette-generator, resize-images |

## How Agents Differ from Skills

| Layer | Behavior | Example |
|-------|----------|---------|
| **Skill** | Does one thing when invoked | `/as:product-research` searches the web for products |
| **Agent** | Assesses the input, chooses a path, orchestrates skills, exercises judgment | The researcher decides whether to search, extract from PDFs, or find alternatives based on what you give it |

Use an **agent** when the task is open-ended and multi-step (the agent decides which skills to run and in what order). Call a **skill** directly when you know exactly which single operation you need.

## How They Work Together

```
Address or site
      ↓
site-planner
      → climate, transit, demographics, neighborhood context
      ↓
nyc-zoning-expert
      → property records, zoning envelope, 3D visualization
      ↓
workplace-strategist
      → occupancy compliance, zone allocation, room schedule
      ↓
product-and-materials-researcher
      → finds products, extracts specs, tags and classifies
      ↓
sustainability-specialist
      → evaluates environmental impact, compares GWP, checks LEED
      ↓
ffe-designer
      → composes room packages, builds schedule, runs QA, exports
      ↓
brand-manager
      → builds the presentation, ensures visual consistency
```

Each agent works standalone. Use one, several, or all depending on the task.

## Usage

Three ways in:

1. **Automatic delegation** — with the plugin installed, Claude Code registers the agent and can delegate matching work to it on its own (the agent's `description` frontmatter drives this).
2. **`/as:studio` routing** — describe your task; the dispatcher classifies it and hands off to the right agent.
3. **Direct** — name the agent in your request ("have the ffe-designer clean this schedule up").
