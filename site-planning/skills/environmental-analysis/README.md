# /environmental-analysis

Climate and environmental site analysis for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Provide an address and get temperature, precipitation, wind, sun angles, flood zones, seismic risk, soil conditions, and topography — sourced exclusively from governmental and scientific databases.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/site-planning
```

## Usage

```
/environmental-analysis 375 Sterling Place, Brooklyn, NY
```

Or start with no context:

```
/environmental-analysis
```

The skill researches two sections:

1. **Climate** — monthly temperature normals, precipitation, prevailing winds, sun angles, ASHRAE/Köppen classification, humidity, design temperatures
2. **Natural Features & Hazards** — topography, FEMA flood zones, seismic risk, soil conditions, vegetation, water bodies, contamination

Output is saved to `~/Documents/environmental-analysis-[location-slug].md`.

## Data Sources

Only governmental, university, and non-profit sources are used:

| Source | Data |
|--------|------|
| NOAA Climate Normals | Temperature, precipitation, wind — 30-year normals |
| NWS Local Climate Data | Station records, extremes, degree days |
| NOAA Solar Calculator | Sun angles, sunrise/sunset |
| DOE Building Energy Codes | ASHRAE climate zones |
| NREL Solar Resource | Solar radiation |
| FEMA Flood Map Service | Flood zone designation |
| USGS Earthquake Hazards | Seismic hazard, design values, faults |
| USGS National Map | Elevation, topography |
| NRCS Web Soil Survey | Soil types, engineering classifications |
| EPA Superfund/Brownfields | Contamination sites |
| NWI Wetlands Mapper | Wetlands, water bodies |

Commercial weather and environmental sites are never used.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Research workflow, output template, preferred sources, guidelines |

## License

MIT
