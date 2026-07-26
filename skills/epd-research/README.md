# /as:epd-research

Search for Environmental Product Declarations by product category, CSI division, or material type for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Finds EPDs from EC3, program operator registries, and manufacturer sites. Returns candidates sorted by GWP with LEED eligibility flags.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:epd-research CLT
```

With more detail:

```
/as:epd-research ready-mix concrete, 4000 PSI, plants within 500 miles of NYC, GWP under 350
```

## What it searches

| Source | Coverage |
|--------|----------|
| Building Transparency / EC3 | Largest open EPD database |
| UL Environment | Major US program operator |
| NSF International | Strong in concrete, masonry |
| Environdec | Largest international registry |
| IBU | European products |
| ASTM International | US program operator |
| Manufacturer sites | Direct sustainability pages |

Claude runs 3-5 searches across registries, fetches EPD listings, and returns 6-12 candidates sorted by GWP (lowest first) with LEED eligibility flags.

Results stay in conversation by default. On explicit request, selected records can be saved to the nearest project's `epd-library.csv` using [`schema/epd-schema.md`](../../schema/epd-schema.md).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Research workflow, registry search strategy, presentation rules |

## License

MIT
