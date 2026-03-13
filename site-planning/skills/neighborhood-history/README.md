# /neighborhood-history

Neighborhood context and history analysis for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Provide an address and get development history, architectural character, historic district status, landmarks, commercial activity, and planned development — sourced from landmarks commissions, planning departments, and archives.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/site-planning
```

## Usage

```
/neighborhood-history 375 Sterling Place, Brooklyn, NY
```

Or start with no context:

```
/neighborhood-history
```

The skill researches:

- **Development history** — how the area was built out, key construction periods, demographic shifts
- **Historic preservation** — historic district status, landmark designations, LPC context
- **Adjacent land uses** — what's in every direction
- **Architectural character** — styles, materials, heights, streetscape
- **Landmarks & institutions** — notable buildings, parks, cultural institutions within ~1 km
- **Commercial activity** — retail corridors, restaurants, market character
- **Planned development** — major projects approved or under construction

Output is saved to `~/Documents/neighborhood-history-[location-slug].md`.

## Data Sources

Only governmental, university, museum, and non-profit sources are used:

| Source | Data |
|--------|------|
| NYC LPC Designation Reports | Historic district reports, landmark designations |
| NYC LPC LAMP | Landmarks and historic districts map |
| National Register of Historic Places | Federal historic designations |
| NYC DCP Community Profiles | Land use, development activity |
| NYC Open Data — Permits | Building permits, new construction |
| National Park Service | Historic places, cultural landscapes |
| Library of Congress / HABS | Historic American Buildings Survey |

Commercial real estate sites and neighborhood blogs are never used.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Research workflow, output template, preferred sources, guidelines |

## License

MIT
