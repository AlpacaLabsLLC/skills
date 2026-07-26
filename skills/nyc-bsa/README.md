# /as:nyc-bsa

BSA variance and special permit lookup for any NYC property as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. Queries the Board of Standards and Appeals application database for variances, special permits, and appeals — records available from 1998 to present. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-bsa 120 Broadway, Manhattan
/as:nyc-bsa 1000770001          (BBL)
/as:nyc-bsa 1001389             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL and building metadata (BIN via Building Footprints when needed)
2. **Queries BSA applications** by BBL, with address fallback
3. **Presents results** — application number, type (variance/special permit), decision, date, and description

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN |
| BSA Applications Status | `yvxd-uipr` | Application number, type, status, decision, calendar date |

## Output

Inline markdown with a table of BSA applications — type, decision status, date, and description. Notes that approved variances remain with the land and may affect proposed work.

## License

MIT
