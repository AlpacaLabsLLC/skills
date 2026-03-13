# Site Analysis Generator

A Claude Code skill that researches a site location and produces a comprehensive analysis brief with climate, zoning, transit, demographics, and environmental data.

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git && skills/install.sh site-analysis-generator
```

Or if you already have the repo:

```bash
cd skills && ./install.sh site-analysis-generator
```

## Usage

```
/site-analysis-generator 500 Terry Francine St, San Francisco, CA — mixed-use
/site-analysis-generator Punta del Este, Maldonado, Uruguay
/site-analysis-generator 40.7128, -74.0060 — commercial
```

If invoked without arguments, the skill will ask for a location and project type.

## What's Included

The skill searches the web for publicly available data across six categories:

| Section | Key data points |
|---------|----------------|
| Climate & Environment | Temperature ranges, precipitation, winds, sun angles, ASHRAE/Köppen zone |
| Zoning & Land Use | Designation, height limits, setbacks, FAR/FOS, parking, overlays |
| Transit & Access | Nearest stops/stations, Walk Score, major roads, airport proximity |
| Demographics & Market | Population, income, growth trends, housing costs, employers |
| Neighborhood Context | Adjacent uses, landmarks, planned development, character |
| Natural Features & Hazards | Topography, flood zones, seismic risk, soil, contamination |

Output is a structured markdown file saved to `~/Documents/site-analysis-[location-slug].md`.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill prompt with research workflow and output template |
| `README.md` | This file |
