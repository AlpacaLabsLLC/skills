# /as:nyc-dob-permits

DOB permit and job filing history for any NYC building as a Claude Code skill. Queries both the Legacy BIS and DOB NOW systems — covering permits, job applications, and filing statuses across four datasets. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-dob-permits 120 Broadway, Manhattan
/as:nyc-dob-permits 1000770001          (BBL)
/as:nyc-dob-permits 1001389             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL and building metadata (BIN via Building Footprints when needed)
2. **Queries four DOB datasets** — Legacy permits, Legacy job filings, DOB NOW approved permits, DOB NOW job filings
3. **Merges and groups results** — sorted by date, grouped by job type (NB, A1, A2, A3, DM, Other)
4. **Presents the history** — tables with permit numbers, job numbers, statuses, applicants, and dates

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN |
| DOB Permit Issuance (Legacy) | `ipu4-2q9a` | Issued permits from the BIS system |
| DOB Job Application Filings (Legacy) | `ic3t-wcy2` | Job applications and filing status |
| DOB NOW Build Approved Permits | `rbx6-tga4` | Permits approved through DOB NOW |
| DOB NOW Build Job Application Filings | `w9ak-ipjd` | Job filings submitted through DOB NOW |

## Output

Inline markdown with total permit count, tables grouped by job type (New Building, Alteration Type 1/2/3, Demolition, Other), and a note about pre-BIS records for buildings predating 1989.

## License

MIT
