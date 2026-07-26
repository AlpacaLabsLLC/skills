# /as:nyc-property-report

Combined NYC property report as a Claude Code skill. Runs all 6 NYC property data lookups in sequence and writes a comprehensive markdown report covering landmarks, DOB permits, violations, ACRIS records, HPD data, and BSA variances. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-property-report 120 Broadway, Manhattan
/as:nyc-property-report 1000770001          (BBL)
/as:nyc-property-report 1001389             (BIN)
```

## What it covers

This skill orchestrates all 6 standalone NYC property skills into a single report. Each skill can also be run independently:

| Skill | What it covers |
|-------|---------------|
| [`/as:nyc-landmarks`](../nyc-landmarks) | LPC landmark & historic district check |
| [`/as:nyc-dob-permits`](../nyc-dob-permits) | DOB permit & filing history (Legacy BIS + DOB NOW) |
| [`/as:nyc-dob-violations`](../nyc-dob-violations) | DOB & ECB violations with open violation flags |
| [`/as:nyc-acris`](../nyc-acris) | ACRIS property transaction records (deeds, mortgages, liens) |
| [`/as:nyc-hpd`](../nyc-hpd) | HPD violations, complaints & registration (residential only) |
| [`/as:nyc-bsa`](../nyc-bsa) | BSA variances & special permits |

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, property metadata |
| Building Footprints | `5zhs-2jue` | BBL-to-BIN resolution |
| LPC Individual Landmarks | `buis-pvji` | Landmark and historic district status |
| DOB Permit Issuance (Legacy) | `ipu4-2q9a` | Legacy permits |
| DOB Job Filings (Legacy) | `ic3t-wcy2` | Legacy job applications |
| DOB NOW Approved Permits | `rbx6-tga4` | DOB NOW permits |
| DOB NOW Job Filings | `w9ak-ipjd` | DOB NOW applications |
| DOB Violations | `3h2n-5cm9` | DOB violations |
| DOB ECB Violations | `6bgk-3dad` | ECB violations and penalties |
| DOB Active Violations | `sjhj-bc8q` | Currently open violations |
| ACRIS Legals | `8h5j-fqxa` | Document-to-lot mapping |
| ACRIS Master | `bnx9-e6tj` | Document details |
| ACRIS Parties | `636b-3b5g` | Grantor/grantee names |
| ACRIS Document Codes | `7isb-wh4c` | Document type translations |
| HPD Violations | `wvxf-dwi5` | Housing violations |
| HPD Open Violations | `csn4-vhvf` | Open housing violations |
| HPD Complaints | `ygpa-z7cr` | Housing complaints |
| HPD Registrations | `tesw-yqqr` | Building registrations |
| HPD Registration Contacts | `feu5-w2e2` | Owner and agent names |
| BSA Applications | `yvxd-uipr` | Variances and special permits |

## Output

A markdown file (`property-{address-slug}.md`) with 7 sections: property identification, landmark status, DOB permits, DOB violations, ACRIS records, HPD data, and BSA variances. After writing the file, prints a brief inline summary with key findings.

Pair with `/as:zoning-analysis-nyc` for a complete property and zoning picture.

## License

MIT
