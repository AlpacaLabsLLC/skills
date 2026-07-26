# /as:zoning-envelope

Interactive 3D zoning envelope viewer as a Claude Code skill. Generates a single HTML file (Three.js loaded from a CDN) that renders the buildable envelope for any lot — exact lot polygon from GIS data, setback zones, extruded volumes, height caps, and interactive orbit controls.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

First, run a zoning analysis to generate a report:

```
/as:zoning-analysis-nyc 250 Hudson St, New York NY
```

Then generate the 3D viewer:

```
/as:zoning-envelope path/to/zoning-analysis-250-hudson-st.md
```

Or search by keyword:

```
/as:zoning-envelope 250 hudson
```

Or auto-detect the most recent report:

```
/as:zoning-envelope
```

## What it renders

- **Exact lot polygon** from GIS data (MapPLUTO for NYC) — not a simplified rectangle
- **Setback zones** as colored ground overlays with dashed inset boundaries
- **Buildable volumes** — base, tower, galibo — extruded from the lot polygon at correct heights
- **Height cap** — amber plane at maximum building height
- **Edge-length labels** on lot boundary edges
- **Height labels** with dashed reference lines
- **Parameters panel** — FAR, max floor area, height limits, setbacks
- **Interactive controls** — orbit, zoom, pan (Three.js OrbitControls)

## How it works

The skill reads the `## Envelope Data` JSON block from a zoning analysis report. This block contains:

```json
{
  "lot_poly": [[155.8, 171.8], [144.6, 85.7], ...],
  "unit": "ft",
  "setbacks": { "front": 0, "rear": 20, "lateral1": 0, "lateral2": 0 },
  "volumes": [
    { "type": "base", "inset": 20, "h_bottom": 0, "h_top": 85, "label": "base" },
    { "type": "tower", "inset": 10, "h_bottom": 85, "h_top": 290, "label": "tower" }
  ],
  "height_cap": 290,
  "info": { "title": "250 Hudson Street", "zone": "C6-4A", ... },
  "stats": { "Commercial FAR": "10.0", ... }
}
```

The skill then:

1. Parses the polygon and envelope parameters
2. Computes inset polygons for setback zones and building volumes
3. Triangulates the polygons (ear-clipping) for 3D extrusion
4. Generates a single HTML file that loads Three.js from a CDN (internet required to view)
5. Opens it in the browser

## Key features

- **Self-correcting polygon inset** — automatically detects and corrects for different polygon winding directions across data sources
- **Multi-volume envelopes** — base + tower for contextual districts
- **Multi-scenario support** — toggle buttons for comparing development scenarios (individual, party-wall, unified)
- **Works with any polygon source** — NYC MapPLUTO (WGS84) or manual coordinates

## Dependency

This skill requires a zoning analysis report as input. It does not perform zoning calculations — run `/as:zoning-analysis-nyc` first.

## Demo

[Live demo (250 Hudson Street)](https://alpa.llc/demos/zoning-envelope.html)

## License

MIT
