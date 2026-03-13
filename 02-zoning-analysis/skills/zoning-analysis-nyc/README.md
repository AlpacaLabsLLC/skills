# /zoning-analysis-nyc

Zoning envelope analyzer for lots in New York City as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. Provide an address, BBL, or BIN and get a full building envelope analysis using the [PLUTO](https://data.cityofnewyork.us/City-Government/Primary-Land-Use-Tax-Lot-Output-PLUTO-/64uk-42ks) open data API and the NYC Zoning Resolution.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../../LICENSE)

## Install

```bash
claude install github:AlpacaLabsLLC/skills-for-architects/02-zoning-analysis
```

## Usage

```
/zoning-analysis-nyc
```

Then provide an address, BBL (Borough-Block-Lot), or BIN. The skill:

1. **Queries PLUTO** — fetches lot data from NYC Open Data (no API key needed)
2. **Identifies the district** — maps zoning district code to R/C/M type, flags split zones and overlays
3. **Loads zoning rules** — reads the relevant regulation files for the district, overlays, and special districts
4. **Calculates the envelope** — FAR, max height, setbacks, yards, lot coverage, sky exposure plane
5. **Checks overlays** — commercial overlays, special districts, inclusionary housing, landmarks
6. **Presents the analysis** — structured markdown with bulk parameters, permitted uses, parking, and development potential

## Sample Output

```
# Zoning Analysis — 375 Sterling Place, Brooklyn

## Lot Summary
| Parameter             | Value                              |
|-----------------------|------------------------------------|
| BBL                   | 3-01166-0092                       |
| Lot Area              | 2,620 SF                           |
| Current FAR (built)   | 1.49                               |
| Year Built            | 1901                               |
| Historic District     | Prospect Heights Historic District |

## Zoning Classification
| Parameter        | Value      |
|------------------|------------|
| Primary District | R6B        |
| Contextual       | Yes        |
| Historic District| Prospect Heights |

## Bulk Parameters
| Use         | Max FAR | Max Floor Area (SF) |
|-------------|---------|---------------------|
| Residential | 2.00    | 5,240               |
| Comm. Fac.  | 2.00    | 5,240               |

### Height & Setback
| Parameter          | Value              |
|--------------------|--------------------|
| Max Building Height| 50 ft              |
| Base Height        | 30–40 ft           |
| Setback above base | 15 ft              |
| Max Lot Coverage   | 60%                |

## Development Potential
| Scenario               | FAR  | Floor Area |
|------------------------|------|------------|
| As-of-right residential| 2.00 | 5,240 SF   |
| With UAP (+20%)        | 2.40 | 6,288 SF   |
| Unused rights          | 0.51 | 1,336 SF   |
```

## Coverage

All five boroughs are supported. The skill queries PLUTO for any tax lot in NYC and applies rules from 10 bundled zoning reference files:

| File | Content |
|------|---------|
| `overview.md` | NYC zoning system primer — district types, how to read codes |
| `residential.md` | R1–R10: FAR, height, setbacks, yards, sky exposure, IH bonuses |
| `commercial.md` | C1–C8 + commercial overlay rules (C1/C2 in R districts) |
| `manufacturing.md` | M1–M3: FAR, performance standards, MX mixed-use |
| `contextual-districts.md` | A/B/D/X suffixes, Quality Housing, bulk tables for all variants |
| `special-districts.md` | Top 10 special districts (Midtown, Hudson Yards, LM, etc.) |
| `use-groups.md` | All 18 use groups with permissions by district |
| `parking.md` | Post-City of Yes rules, loading berths, bicycle parking |
| `city-of-yes.md` | Dec 2024 reforms: UAP, parking, town centers, TOD, ADUs |
| `pluto-fields.md` | PLUTO API field reference and query examples |

## File Structure

```
zoning-analysis-nyc/
├── SKILL.md                          # Skill instructions and workflow
├── README.md
└── zoning-rules/
    ├── overview.md                   # NYC zoning system primer
    ├── residential.md                # R1–R10 districts
    ├── commercial.md                 # C1–C8 districts + overlays
    ├── manufacturing.md              # M1–M3 districts
    ├── contextual-districts.md       # A/B/D/X suffix rules
    ├── special-districts.md          # Special purpose districts
    ├── use-groups.md                 # Use Groups 1–18
    ├── parking.md                    # Parking & loading requirements
    ├── city-of-yes.md                # Dec 2024 zoning reforms
    └── pluto-fields.md               # PLUTO API reference
```

## Data Sources

- **PLUTO** — [NYC Open Data](https://data.cityofnewyork.us/City-Government/Primary-Land-Use-Tax-Lot-Output-PLUTO-/64uk-42ks), updated quarterly by the Department of City Planning
- **Zoning Resolution** — [zr.planning.nyc.gov](https://zr.planning.nyc.gov)
- **ZoLa** — [zola.planning.nyc.gov](https://zola.planning.nyc.gov) (visual zoning map)

No warranty of completeness or accuracy — always verify with the NYC Department of City Planning for permit applications.

## License

MIT
