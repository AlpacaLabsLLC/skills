# /as:epd-parser

Extract structured environmental impact data from EPD PDFs for Claude Code. Parses Environmental Product Declaration PDFs — extracting GWP, life cycle stages, program operator metadata, and LEED eligibility into a standardized 42-column schema.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:epd-parser ~/Downloads/EPD11075.pdf
```

A folder of EPDs:

```
/as:epd-parser ~/Documents/as:project-epds/
```

## What it extracts

- **Product identity** — manufacturer, product name, declared unit, CSI division
- **EPD metadata** — registration number, program operator, PCR, standard version, validity dates, system boundary
- **Impact indicators** — GWP-total, GWP-fossil, GWP-biogenic (A1-A3), plus A4-A5, B1-B7, C1-C4, D when available
- **Additional impacts** — ODP, AP, EP, POCP
- **Resource use** — renewable/non-renewable primary energy, fresh water, recycled content, waste
- **LEED eligibility** — flags product-specific vs. industry-average, third-party verification status

Handles EN 15804+A1 and +A2 formats, multi-product EPDs, non-English documents, and varying table layouts across program operators (UL, NSF, Environdec, IBU, ASTM).

Parsing is file-free by default: results can pass directly to `/as:epd-compare` or `/as:epd-to-spec`. On explicit request, records can be saved to the nearest project's `epd-library.csv` using the canonical schema in [`schema/epd-schema.md`](../../schema/epd-schema.md).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Extraction workflow, 42-column schema, edge case handling |

## License

MIT
