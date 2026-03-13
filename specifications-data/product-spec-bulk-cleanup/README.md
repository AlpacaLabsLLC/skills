# /product-spec-bulk-cleanup

FF&E schedule normalizer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Takes a messy furniture schedule — mixed casing, combined dimensions, Spanish material names, inconsistent categories — and cleans it into consistent, procurement-ready data.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/product-spec-bulk-cleanup" ~/.claude/skills/product-spec-bulk-cleanup
```

## Usage

```
/product-spec-bulk-cleanup ~/Documents/ffe-schedule.csv
```

Or point to a Google Sheet:

```
/product-spec-bulk-cleanup 1FMScYW9guezOWc_m4ClTQxxFIpS6TNRr373R-MJGzgE
```

Or paste a markdown table directly in the conversation.

### Input formats

- **File path** — `.csv`, `.tsv`, or `.md`
- **Google Sheet** — spreadsheet ID (+ optional tab name)
- **Pasted table** — markdown or tab-separated data

## What It Cleans

### Casing

```
eames lounge chair    →  Eames Lounge Chair
HERMAN MILLER         →  Herman Miller
HAY                   →  HAY  (preserved — known abbreviation)
```

Preserves abbreviations: HAY, USM, DWR, CB2, HBF, OFS, SitOnIt, 3form, ICF.

### Categories

Maps free text to 11 canonical categories:

| Input | → Canonical |
|-------|-------------|
| chairs, silla, task chair, stool | Seating |
| mesa, escritorio, conference table | Tables |
| luminaria, pendant, sconce | Lighting |
| cabinet, shelving, credenza, estante | Storage |
| acoustic panel, baffle, sound panel | Acoustic |
| biombo, mampara, divider | Partitions |

Also: Desks, Accessories, Textiles, Planters, Other.

### Dimensions

Splits combined strings into separate W/D/H + Unit columns:

| Before | W | D | H | Unit |
|--------|---|---|---|------|
| `32 x 24 x 30 in` | 32 | 24 | 30 | in |
| `80 × 60 × 75 cm` | 80 | 60 | 75 | cm |
| `32"W x 24"D x 30"H` | 32 | 24 | 30 | in |
| `Ancho: 80, Prof: 60, Alto: 75 cm` | 80 | 60 | 75 | cm |
| `2'6"` (feet-inches) | — | — | 30 | in |

Units are never converted. The manufacturer's original spec is preserved for ordering accuracy.

### Language

Translates Spanish material and finish terms (common when sourcing from Uruguay, Argentina, or Spain):

| Spanish | → English |
|---------|-----------|
| Madera | Wood |
| Cuero | Leather |
| Acero | Steel |
| Vidrio | Glass |
| Mármol | Marble |
| Cromado | Chrome |
| Nogal | Walnut |
| Roble | Oak |

Product names and brands stay untouched. Use `/keep in Spanish` to skip translation.

### Materials vocabulary

Standardizes common abbreviations:

| Variations | → Standard |
|-----------|------------|
| SS, Stainless, S/S | Stainless steel |
| Ply, Plywood, Mold ply | Molded plywood |
| PC, Powder coat, Pwdr | Powder-coated |
| Chrm, Chrome plated | Chrome |
| COM, C.O.M. | COM (Customer's Own Material) |
| HPL | HPL |

### Price & currency

- Strips symbols: `$5,695.00` → `5695.00`
- Detects locale: `1.234,56` (EU) vs `1,234.56` (US)
- "Contact for pricing", "A consultar" → empty cell
- Currency inferred from context: `$` on a UY site → `UYU`, US site → `USD`

### Duplicates

Flags rows with identical Product Name + Brand, or identical URL. Presents them for review — never auto-deletes.

## Workflow

The skill works in steps:

1. **Load** — reads the schedule, maps columns to schema, reports row count
2. **Analyze** — scans all rows and shows a cleanup preview:

```
Cleanup Preview
- Casing: 12 product names need Title Case
- Categories: 8 rows have non-standard categories
- Dimensions: 5 rows have combined dimensions to split
- Language: 6 rows have Spanish-language fields
- Materials: 4 rows have non-standard terms
- Duplicates: 2 potential duplicate rows
```

3. **Confirm** — apply all fixes, or pick selectively
4. **Apply** — processes every row
5. **Review** — before/after diff for a sample of changed rows
6. **Save** — overwrite original, save as new file (`-clean` suffix), write to Google Sheet, or keep in conversation

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Cleanup rules, vocabulary mappings, category normalization, workflow |

## Pairs With

Use [`/product-spec-bulk-fetch`](../product-spec-bulk-fetch) to extract specs from product URLs, then run this skill to normalize the output. **Fetch → cleanup → spec-ready schedule.**

## License

MIT
