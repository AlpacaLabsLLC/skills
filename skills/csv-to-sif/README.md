# /as:csv-to-sif

Convert the local CSV FF&E product library to SIF (Standard Interchange Format) for dealer and procurement systems, for Claude Code.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:csv-to-sif ~/Documents/as:project/product-schedule.csv
```

Supports Standard (Hedberg, CAP, ProjectMatrix), CET/Configura, Cyncly Worksheet, and Design Manager target systems.

## SIF Field Reference

| Code | Name | Required | Description |
|------|------|----------|-------------|
| `PN` | Product Number | Yes | SKU — starts each record |
| `PD` | Product Description | Yes | Product name |
| `MC` | Manufacturer Code | Yes | 3-5 char code (HMI, KNL, STC) |
| `MN` | Manufacturer Name | No | Full brand name |
| `QT` | Quantity | Yes | Integer |
| `PL` | List Price | Yes | Unit price, no currency symbol |
| `P1`-`P5` | Price Tiers | No | Alternate price tiers |
| `GC` | Category | No | Product category |
| `G0` | Vendor ID | No | Vendor or dealer identifier |
| `TG` | Side Mark / Tag | No | Room or area |
| `S-` | Sell Discount % | No | Sell = PL - (PL × S- × 0.01) |
| `P%` | Purchase % | No | Cost = PL × (P% × 0.01) |
| `ON`/`OD` | Option | No | Finish, fabric, color (paired) |
| `AN`/`AD` | Attribute | No | Dimensions, weight (paired) |
| `WT` | Weight | No | Product weight |
| `VO` | Volume | No | Product volume |
| `ProductURL` | Product URL | No | Link to product page |
| `ImageURL` | Image URL | No | Link to product image |

Cyncly variants: `MG` (manufacturer code), `I1` (list price), `I2` (purchase price), `PRC` (category). CET variant: `EC` (manufacturer code).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition with full SIF spec, column mappings, and manufacturer code lookup |

## License

MIT
