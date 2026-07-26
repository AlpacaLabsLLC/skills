# /as:sif-to-csv

Convert SIF (Standard Interchange Format) files from dealers into readable CSV data, for Claude Code.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:sif-to-csv ~/Documents/as:project/dealer-quote.sif
```

Parses SIF field codes, expands manufacturer codes, calculates sell prices from discounts, and outputs clean CSV rows. Handles Standard, CET, and Cyncly Worksheet SIF dialects.

## SIF Field Reference

| Code | Name | Description |
|------|------|-------------|
| `SF` | Specification File | Project reference (header) |
| `ST` | Specification Title | Display title (header) |
| `PN` | Product Number | SKU — starts each record |
| `PD` | Product Description | Product name |
| `MC` | Manufacturer Code | 3-5 char code (HMI, KNL, STC) |
| `MN` | Manufacturer Name | Full brand name |
| `QT` / `NT` | Quantity | Integer (QT standard, NT alternate) |
| `PL` | List Price | Unit price |
| `P1`-`P5` | Price Tiers | Alternate price tiers |
| `I1` / `I2` | Cyncly Prices | List / purchase price |
| `GC` | Category | Product category |
| `G0` | Vendor ID | Vendor identifier |
| `TG` | Side Mark / Tag | Room or area |
| `S-` / `S%` | Sell Discount % | Sell = PL - (PL × S- × 0.01) |
| `P%` / `B%` | Purchase % | Cost = PL × (P% × 0.01) |
| `ON`/`OD` | Option | Finish, fabric, color (paired) |
| `AN`/`AD` | Attribute | Dimensions, weight (paired) |
| `WT` | Weight | Product weight |
| `VO` | Volume | Product volume |
| `ProductURL` | Product URL | Link to product page |
| `ImageURL` | Image URL | Link to product image |

Manufacturer code variants: `MC` (standard), `MG` (Cyncly), `EC` (CET).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition with full SIF spec, parsing rules, and manufacturer code expansion |

## License

MIT
