# /as:nyc-landmarks

LPC landmark and historic district check for any NYC building as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. Provide an address, BBL, or BIN and find out if the property is individually landmarked, in a historic district, or not designated — using the LPC Individual Landmark & Historic District Building Database. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-landmarks 120 Broadway, Manhattan
/as:nyc-landmarks 1000770001          (BBL)
/as:nyc-landmarks 1001389             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL and building metadata (BIN via Building Footprints when needed)
2. **Queries the LPC database** — checks for individual landmark designation by BBL, with block+lot fallback
3. **Cross-checks PLUTO** — the `histdist` field catches historic district membership even when the building isn't individually listed
4. **Presents the result** — designation status, LP number, designation date, type, historic district, and implications for permit work

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN, `histdist` field |
| LPC Individual Landmarks | `buis-pvji` | Landmark name, LP number, designation date, type, site description |

## Output

Inline markdown with landmark status (Landmarked / In Historic District / Not Designated), designation details table, and a note on LPC Certificate of Appropriateness requirements if designated.

## License

MIT
