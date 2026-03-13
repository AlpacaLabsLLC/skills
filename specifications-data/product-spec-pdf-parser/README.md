# /product-spec-pdf-parser

PDF product spec parser for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Feed it price books, fact sheets, or spec sheets — get a standardized FF&E schedule with names, variants, SKUs, dimensions, materials, and pricing extracted using AI.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/product-spec-pdf-parser" ~/.claude/skills/product-spec-pdf-parser
```

### Dependencies

- **PyMuPDF** — PDF text extraction
  ```bash
  pip install PyMuPDF
  ```

## Usage

```
/product-spec-pdf-parser
```

Then provide PDF paths — point to individual files or a folder.

```
/product-spec-pdf-parser

~/Documents/specs/alphabeta-floor-lamp.pdf
~/Documents/specs/aeron-price-book.pdf
```

Or a folder:

```
/product-spec-pdf-parser ~/Documents/specs/
```

### Variant depth

- **expand** (default) — one row per variant/SKU. Best for procurement.
- **summarize** — one row per product, variants comma-separated. Best for quick reference.

### Output formats

After extraction, choose where to save:

- **Local CSV** — default: `~/Documents/Work-Docs/ffe-pdf-parse-YYYY-MM-DD.csv`
- **Google Sheet** — writes rows to a specified spreadsheet
- **Markdown table** — stays in the conversation

## How It Works

1. **PyMuPDF** extracts raw text from each PDF page
2. **Claude** reads the text and reasons about the structure — identifying products, variants, dimensions, pricing
3. Results are structured into a 24-field schema and presented for review
4. Output is saved in the chosen format

No custom extraction code or regex — Claude IS the parser. This handles the wild variation in PDF layouts that rule-based parsers can't.

## Output Schema

24 fields per product row, extending the Canoa Clipper FF&E format:

| Field | Example |
|-------|---------|
| Product Name | Alphabeta Floor Lamp |
| Variant | Diamond, Black |
| SKU | HEM-AF-DB |
| Brand | Hem |
| Designer | Luca Nichetto |
| Collection | Alphabeta |
| Category | Lighting |
| Description | Modular floor lamp with interchangeable shades |
| W / D / H | — / — / 135.5 |
| Seat H | — |
| Unit | cm |
| Weight | 4.5 kg |
| Materials | Aluminium, Steel |
| Colors/Finishes | Black |
| List Price | 595.00 |
| Price Adder | — |
| Currency | EUR |
| Lead Time | — |
| Warranty | — |
| Certifications | CE |
| Country of Origin | Sweden |
| Source File | alphabeta-fact-sheet.pdf |

## PDF Types Supported

| Type | Example | Variant strategy |
|------|---------|-----------------|
| **Fact sheet with SKUs** | Hem Alphabeta | One row per SKU (shade × color) |
| **Fact sheet with finishes** | Hem Puffy | One row per upholstery option |
| **Price book / configurator** | Herman Miller Aeron | One row per product type, options summarized |
| **Product catalog** | Multi-product catalogs | Rows for each distinct product |
| **Spec sheet** | Single-product tech specs | One row with full detail |

## Error Handling

- **Scanned/image PDFs** — detected (no extractable text) and flagged for OCR
- **Password-protected PDFs** — caught and reported
- **Tables as images** — flagged for manual review
- **Mixed languages** — extracted as-is, cleanup skill handles translation
- **Large PDFs (100+ pages)** — processed in 10-page chunks with progress updates

After every batch: `Parsed: X products from Y PDF(s)` with per-file counts and any issues.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Parsing workflow, schema, variant handling rules |

## Pairs With

- Use [`/product-spec-bulk-fetch`](../product-spec-bulk-fetch) to extract specs from web URLs instead of PDFs
- Use [`/product-spec-bulk-cleanup`](../product-spec-bulk-cleanup) after parsing to normalize casing, translate, and deduplicate
- Use [`/product-image-processor`](../product-image-processor) to download and process product images

**PDF parse → cleanup → spec-ready schedule.**

## License

MIT
