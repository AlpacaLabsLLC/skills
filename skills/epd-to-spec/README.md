# /as:epd-to-spec

Generate CSI-formatted specification sections requiring EPDs and setting maximum GWP thresholds for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). References ISO 14025, ISO 21930, and EN 15804.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

With explicit thresholds:

```
/as:epd-to-spec concrete max 350 kg CO2e/m3, rebar max 1.0 kg CO2e/kg, CLT max 125 kg CO2e/m3
```

From a project description:

```
/as:epd-to-spec write EPD requirements for a mass timber office — CLT floors and walls, steel connections, mineral wool insulation
```

## What it generates

For each material, a three-part CSI section:

- **Part 1** — EPD submittal requirements (ISO 14025, third-party verification), sustainability article with GWP thresholds, quality assurance
- **Part 2** — Maximum GWP per declared unit, sustainable sourcing requirements, manufacturer EPD qualification
- **Part 3** — Standard execution

Plus optional LEED v4.1 MRc2 language (Option 1 disclosure + Option 2 optimization).

Inputs can come directly from `/as:epd-parser` or `/as:epd-compare`, from pasted structured data, or from a validated project-local `epd-library.csv` using [`schema/epd-schema.md`](../../schema/epd-schema.md).

Covers divisions 03 (Concrete), 05 (Metals), 06 (Wood/CLT/Glulam), 07 (Insulation, Roofing), 08 (Curtain Wall), 09 (Gypsum, Tile, Flooring), and 32 (Paving).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Spec generation workflow, CSI three-part structure, LEED language, industry baselines |

## License

MIT
