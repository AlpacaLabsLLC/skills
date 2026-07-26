# /as:nyc-hpd

HPD violations, complaints, and building registration lookup for NYC residential buildings as a Claude Code skill. Queries Housing Preservation & Development data — only applies to residential building classes (A, B, C, D, R, S). No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-hpd 1055 Bergen Street, Brooklyn
/as:nyc-hpd 3012120065          (BBL)
/as:nyc-hpd 3030348             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL, building class, and metadata (BIN via Building Footprints when needed)
2. **Checks building class** — HPD only applies to residential classes. Non-residential buildings get an early exit with a note.
3. **Queries four HPD datasets** — violations, open violations, complaints, and registrations
4. **Flags hazardous violations** — Class C (immediately hazardous) violations are flagged prominently
5. **Presents the report** — registration info, open violations by class, all violations, and recent complaints

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN, building class |
| HPD Violations | `wvxf-dwi5` | Violation class (A/B/C), inspection date, description |
| HPD Open Violations | `csn4-vhvf` | Pre-filtered currently open violations |
| HPD Complaints | `ygpa-z7cr` | Complaint date, status, status date |
| HPD Registrations | `tesw-yqqr` | Registration ID, owner name, expiry date |

## Output

Inline markdown with building registration details, open violation counts by class (C/B/A), open violations table, full violation history, and recent complaints. Class C violations are always flagged as immediately hazardous.

## License

MIT
