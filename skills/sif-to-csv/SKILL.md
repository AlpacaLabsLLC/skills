---
name: sif-to-csv
description: Parse a SIF (Standard Interchange Format) input into a readable preview and optionally append canonical product rows to the project's CSV library. Use when asked to convert or inspect SIF dealer data. For the reverse direction use /as:csv-to-sif.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# /as:sif-to-csv — SIF to CSV Converter

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Converts a SIF input from a dealer or procurement system into a human-readable preview and canonical product rows. Translates field codes, expands options and attributes, calculates pricing, and computes totals.

## When to Use

- Received a SIF file from a dealer and need to review it as CSV data
- Importing dealer pricing back into your FF&E schedule
- Comparing a dealer quote (SIF) against your original specification
- Loading dealer data into the project's `product-library.csv`

## SIF Format Reference

SIF is a text-based key-value format. Each line is `CODE=VALUE`, terminated by CRLF. Products are separated by records starting with `PN=`.

### Core fields

| Code | Name | Description |
|------|------|-------------|
| `SF` | Specification File | Project reference (header) |
| `ST` | Specification Title | Display title (header) |
| `PN` | Product Number | SKU — starts a new record |
| `PD` | Product Description | Product name |
| `MC` | Manufacturer Code | 3-5 char code |
| `MN` | Manufacturer Name | Full name |
| `QT` | Quantity | Integer |
| `NT` | Quantity (alt) | Some systems use NT instead of QT |
| `GC` | Category / Group Code | Product category |
| `G0` | Vendor / Group ID | Vendor identifier |

### Pricing fields

| Code | Name | Description |
|------|------|-------------|
| `PL` | List Price | Unit list price |
| `P1`-`P5` | Price Tiers | Alternate price tiers |
| `I1` | Unit List Price (Cyncly) | Cyncly Worksheet |
| `I2` | Purchase Price (Cyncly) | Cyncly Worksheet |
| `S-` / `S%` | Sell Discount % | Sell = PL - (PL × S- × 0.01) |
| `P%` / `B%` | Purchase/Buy % | Cost = PL × (P% × 0.01) |

### Product detail fields

| Code | Name | Description |
|------|------|-------------|
| `TG` | Side Mark / Tag | Room, area, or project tag |
| `ON` / `OD` | Option | Number + description pair |
| `AN` / `AD` | Attribute | Number + description pair |
| `WT` | Weight | Product weight |
| `VO` | Volume | Product volume |
| `PRC` | Product Category (Cyncly) | Cyncly category |

### Link fields

| Code | Name | Description |
|------|------|-------------|
| `ProductURL` | Product Page URL | Link to product page |
| `ImageURL` | Product Image URL | Link to product image |
| `PV` | Picture Path | Local file path |

### Alternate manufacturer codes

| System | Code | Purpose |
|--------|------|---------|
| Standard | `MC` | 3-5 char manufacturer code |
| Cyncly | `MG` | Manufacturer code (replaces MC) |
| CET | `EC` | Manufacturer code (alt) |

## Step 1: Accept Input

**SIF file:**
```
/as:sif-to-csv ./dealer-quote.sif
```

**Pasted SIF content:**
```
/as:sif-to-csv
SF=Project Alpha
ST=Dealer Quote - March 2026
PN=670
PD=Eames Lounge Chair and Ottoman
MC=HMI
QT=3
PL=5695.00
S-=42
TG=Executive Lounge
OD=Santos Palisander / Black MCL Leather
```

## Step 2: Parse SIF

Read the file and parse each record:

1. **Header fields**: Extract `SF` and `ST`
2. **Records**: Split on `PN=` boundaries
3. **For each record**, extract all fields
4. **Detect manufacturer code variant**: look for MC, MG, or EC — normalize to brand name
5. **Detect price variant**: look for PL, P1, I1 — use whichever is present
6. **Detect quantity variant**: look for QT or NT
7. **Calculate derived values**:
   - Sell Price: `PL - (PL × S- × 0.01)` if discount present
   - Net Price: `PL × (P% × 0.01)` if purchase % present
   - Extended List: `PL × QT`
   - Extended Sell: `Sell Price × QT`

### Manufacturer code expansion

| MC | Brand | MC | Brand |
|----|-------|----|-------|
| HMI | Herman Miller | BLU | Blu Dot |
| MKN | MillerKnoll | DWR | Design Within Reach |
| KNL | Knoll | FRH | Fritz Hansen |
| STC | Steelcase | VIT | Vitra |
| HAW | Haworth | ARP | Arper |
| TEK | Teknion | FLS | Flos |
| HUM | Humanscale | LPO | Louis Poulsen |
| KIM | Kimball | ART | Artemide |
| OFS | OFS | HBF | HBF |
| GEI | Geiger | BRN | Bernhardt |

For unknown codes, keep as-is and flag.

### Options and attributes
- Multiple `ON`/`OD` pairs → concatenate into "Options" column, separated by ` | `
- Multiple `AN`/`AD` pairs → concatenate into "Attributes" column, separated by ` | `
- If `AN=DIM`, parse dimension string back into W/D/H if possible

## Step 3: Present Preview

```
## SIF Import: Project Alpha — Dealer Quote March 2026

3 records parsed from dealer-quote.sif

| # | SKU | Product | Brand | Qty | List $ | Disc % | Sell $ | Ext Sell | Options | Tag |
|---|-----|---------|-------|-----|--------|--------|--------|----------|---------|-----|
| 1 | 670 | Eames Lounge Chair | Herman Miller | 3 | $5,695 | 42% | $3,303 | $9,909 | Palisander/Black | Exec Lounge |
| 2 | 164-500 | Saarinen Table 54" | Knoll | 1 | $4,750 | 38% | $2,945 | $2,945 | Arabescato/White | Dining |
| 3 | 462-CG | Gesture Chair | Steelcase | 8 | $1,189 | 45% | $654 | $5,232 | Cogent/Licorice | Open Office |

**Totals:**
- List: $22,147 · Sell: $18,086 · Savings: $4,061 (18.3%)
```

## Step 4: Output

Show the parsed table in Markdown. For persistence, write only to the nearest project-root `product-library.csv`. Read `../../schema/product-schema.md`, `../../schema/csv-conventions.md`, and `../../schema/sif-crosswalk.md`. Map by these named fields:

- `Link` ← ProductURL; `Product Name` ← PD; `SKU` ← PN; `Brand` ← expanded MC
- `Category` ← GC or PRC; dimensions ← AD where AN=DIM; `Weight` ← WT
- `List Price` ← PL/P1/I1; `Sale Price` ← calculated sell price; `Selected Color/Finish` ← OD
- `Image URL` ← ImageURL; `Tags` ← TG; `Status` ← `quoted`; `Source` ← `sif-to-csv`
- `Notes` ← `From SIF: {ST}. Discount: {S-}%. Qty: {QT} · Ext: ${ext_sell}`

Preview the complete batch's row mappings, totals, warnings, and target path, then use the single confirmation gate. After approval, serialize all complete rows as one JSON array and invoke `python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" append product --project <project-root> --row-json <batch.json>` exactly once. The helper validates the complete batch and library before one atomic replacement; never loop per row.

## Step 5: Summary

```
✓ Parsed dealer-quote.sif
  Specification: Project Alpha — Dealer Quote March 2026
  3 records · 12 units
  Total list: $22,147 · Total sell: $18,086 (18.3% avg discount)
  Manufacturers: HMI (1), KNL (1), STC (1)
  Saved to: ./product-library.csv
```

## Pairs With

- `/as:csv-to-sif` — round-trip: create SIF, send to dealer, parse their quote back
- `/as:product-data-cleanup` — normalize the parsed data
- `/as:product-data-import` — reformulate dealer data into a formatted schedule
- `/as:product-enrich` — add categories and tags to imported products
