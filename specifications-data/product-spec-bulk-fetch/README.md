# /product-spec-bulk-fetch

Bulk FF&E product spec extractor for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Feed it a list of product page URLs — get a standardized schedule with names, dimensions, materials, pricing, and images extracted from each page using AI.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/product-spec-bulk-fetch" ~/.claude/skills/product-spec-bulk-fetch
```

## Usage

```
/product-spec-bulk-fetch
```

Then provide URLs — paste inline, point to a file, or give a Google Sheet ID with a column of product links.

```
/product-spec-bulk-fetch

https://www.hermanmiller.com/products/seating/lounge-chairs/eames-lounge-chair/
https://www.steelcase.com/products/collaborative-chairs/gesture/
https://www.ikea.pr/puertorico/es/pd/vardagen-vaso-art-70313106
https://rfrsh.ar/products/roma-mesa
https://www.target.com/p/ateco-icing-spatula/-/A-93709686
```

### Input formats

- **Inline URLs** — one per line or comma-separated in the message
- **File path** — a `.txt`, `.csv`, or `.md` file with URLs (one per line)
- **Google Sheet** — spreadsheet ID + column containing product URLs

### Output formats

After extraction, choose where to save:

- **Local CSV** — default: `~/Documents/Work-Docs/ffe-fetch-YYYY-MM-DD.csv`
- **Google Sheet** — writes rows to a specified spreadsheet
- **Markdown table** — stays in the conversation

## Demo: 5-Product Batch

Real output from a batch of 5 URLs across Herman Miller, IKEA Puerto Rico, and RH:

```
| Product Name               | Brand          | Category  | W     | D     | H     | Unit | Price    | Currency |
|----------------------------|----------------|-----------|-------|-------|-------|------|----------|----------|
| Eames Lounge Chair (LCW)   | Herman Miller  | Seating   | 21.75 | 25.25 | 26.50 | in   | 1235.00  | USD      |
| VARDAGEN Vaso               | IKEA           | Accessories|      |       | 5.00  | in   | 13.99    | USD      |
| KVOT Escurreplatos          | IKEA           | Accessories| 11.38| 18.88 | 9.00  | in   | 12.99    | USD      |
| Soria Teak Lounge Chair     | RH             | Seating   | 30.00 | 34.00 | 23.50 | in   | 3855.00  | USD      |
| Roma Mesa                   | Ries           | Tables    | 40.00 | 40.00 | 51.00 | cm   | 850.00   | ARS      |

Fetched: 4/5 successful, 1 partial, 0 failed
```

Partial results (missing price, missing dimensions) are still included — blanks are better than skipped rows.

## Output Schema

15 fields per product, matching the Canoa Clipper FF&E format:

| Field | Format | Example |
|-------|--------|---------|
| Product Name | Title Case | Eames Lounge Chair |
| Brand | Title Case | Herman Miller |
| Collection | Title Case or blank | Eames Molded Plywood |
| Category | Controlled vocab | Seating |
| W | Decimal | 21.75 |
| D | Decimal | 25.25 |
| H | Decimal | 26.50 |
| Unit | in, cm, or mm | in |
| Materials | Comma-separated | Molded plywood, leather |
| Colors/Finishes | Comma-separated | Walnut, Black Leather |
| Price | Decimal, no symbol | 1235.00 |
| Currency | ISO code | USD |
| Lead Time | As stated | 8-10 weeks |
| URL | Full URL | (source page) |
| Image URL | Direct URL | (hero image) |

## Error Handling

The skill never stops a batch on a single failure:

- **Trade/dealer sites** with hidden pricing → row included, price left blank
- **Login-required pages** → logged as failed, batch continues
- **Non-product pages** → detected and skipped
- **Duplicate URLs** → deduplicated before fetching

After every batch: `Fetched: X/Y successful, Z partial, W failed` with a list of failed URLs and reasons.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Extraction workflow, WebFetch prompts, output formatting rules |

## Pairs With

Use [`/product-spec-bulk-cleanup`](../product-spec-bulk-cleanup) after fetching to normalize casing, translate Spanish fields, standardize dimensions, and deduplicate. **Fetch → cleanup → spec-ready schedule.**

## License

MIT
