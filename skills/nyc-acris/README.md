# /as:nyc-acris

ACRIS property transaction record lookup for any NYC property as a Claude Code skill. Queries deeds, mortgages, liens, and other recorded documents using a 3-table join across the ACRIS Legals, Master, and Parties datasets. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-acris 120 Broadway, Manhattan
/as:nyc-acris 1000770001          (BBL)
/as:nyc-acris 1001389             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL and building metadata (BIN via Building Footprints when needed)
2. **Gets document IDs** from the ACRIS Legals table by borough/block/lot
3. **Fetches document details** from the ACRIS Master table — type, date, amount
4. **Fetches parties** from the ACRIS Parties table — grantors and grantees
5. **Translates document codes** using the ACRIS Document Control Codes table
6. **Joins and groups results** — Deeds, Mortgages, and Other documents with party names

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN |
| ACRIS Real Property Legals | `8h5j-fqxa` | Document IDs linked to borough/block/lot |
| ACRIS Real Property Master | `bnx9-e6tj` | Document type, date, amount, CRFN |
| ACRIS Real Property Parties | `636b-3b5g` | Grantor/grantee names and addresses |
| ACRIS Document Control Codes | `7isb-wh4c` | Translates doc_type codes to descriptions |

## Output

Inline markdown with documents grouped by type — Deeds (with current owner from most recent deed), Mortgages (with lender and borrower), and Other documents. Shows 20 most recent records.

## License

MIT
