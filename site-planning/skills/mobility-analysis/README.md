# /mobility-analysis

Transit and mobility site analysis for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Provide an address and get subway/bus/rail stations, walk/transit/bike scores, road access, airport distances, and pedestrian/cycling infrastructure — sourced from transit authorities and government data.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/site-planning
```

## Usage

```
/mobility-analysis 375 Sterling Place, Brooklyn, NY
```

Or start with no context:

```
/mobility-analysis
```

The skill researches:

- **Public transit** — subway, bus, commuter rail, ferry with walking distances
- **Walk/Transit/Bike scores** — from walkscore.com
- **Roads & driving** — highways, arterials, airport access
- **Pedestrian & cycling** — sidewalks, bike lanes, bike share stations

Output is saved to `~/Documents/mobility-analysis-[location-slug].md`.

## Data Sources

Only governmental, transit authority, and non-profit sources are used:

| Source | Data |
|--------|------|
| MTA | Subway/bus maps, routes, stations |
| NYC DOT | Bike lanes, street infrastructure |
| NJ Transit / LIRR / Metro-North | Commuter rail |
| NYC Open Data | Station locations, bike routes |
| Walk Score | Walk/Transit/Bike scores |
| FAA | Airport locations |
| USDOT BTS | Transportation statistics |

Commercial mapping and real estate platforms are never used.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Research workflow, output template, preferred sources, guidelines |

## License

MIT
