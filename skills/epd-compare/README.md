# /as:epd-compare

Compare 2+ products side-by-side on environmental impact metrics for Claude Code. Validates comparability, normalizes declared units, generates percentage deltas, and checks LEED v4.1 MRc2 eligibility.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

After parsing or researching EPDs:

```
/as:epd-compare compare the CLT EPDs I just found
```

Or with inline data:

```
/as:epd-compare concrete A: 320 kg CO2e/m3, concrete B: 280 kg CO2e/m3, concrete C: 410 kg CO2e/m3
```

## What it checks

- **Declared unit alignment** — warns if units differ and normalization isn't possible
- **System boundary** — flags cradle-to-gate vs. cradle-to-grave mismatch
- **PCR alignment** — notes when products use different Product Category Rules
- **EN 15804 version** — flags +A1 vs. +A2 differences
- **Validity** — marks expired EPDs
- **EPD type** — distinguishes product-specific from industry-average

Output includes side-by-side impact tables, percentage deltas relative to lowest-impact option, industry average baselines, and LEED v4.1 MRc2 assessment.

Inputs may be pasted values, structured results handed directly from `/as:epd-parser` or `/as:epd-research`, or a validated project-local `epd-library.csv` following [`schema/epd-schema.md`](../../schema/epd-schema.md).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Comparison workflow, comparability checks, industry baselines, LEED assessment |

## License

MIT
