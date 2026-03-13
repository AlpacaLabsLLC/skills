# /demographics-analysis

Demographics and market site analysis for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Provide an address and get population, income, age distribution, housing market data, and employment statistics — sourced exclusively from Census Bureau, BLS, HUD, and other governmental databases.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/01-site-planning
```

## Usage

```
/demographics-analysis 375 Sterling Place, Brooklyn, NY
```

Or start with no context:

```
/demographics-analysis
```

The skill researches:

- **Population** — count, density, 10-year growth trend
- **Income & employment** — median household income, major employers, dominant industries
- **Age & composition** — median age, cohort breakdown, racial/ethnic composition
- **Housing market** — median home price, rental rates, housing stock

All metrics are compared to metro and national benchmarks. Output is saved to `~/Documents/demographics-analysis-[location-slug].md`.

## Data Sources

Only governmental, university, and non-profit sources are used:

| Source | Data |
|--------|------|
| US Census Bureau | Population, income, age, race, housing (Decennial + ACS) |
| Census QuickFacts | Summary demographics by place/ZIP |
| BLS Local Area Unemployment | Unemployment rates |
| BLS Occupational Employment | Employment by industry |
| HUD User | Fair market rents, housing affordability |
| NYU Furman Center | NYC neighborhood housing and demographic profiles |
| NYC Open Data | NYC-specific datasets |
| FRED (St. Louis Fed) | Income, home prices, economic indicators |

Commercial real estate platforms (Zillow, Redfin, RentCafe, Niche) are never used.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Research workflow, output template, preferred sources, guidelines |

## License

MIT
