# /as:product-spec-pdf-parser

PDF product spec parser for Claude Code. Feed it price books, fact sheets, or spec sheets and optionally save structured FF&E data to `product-library.csv`.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

### Dependencies

- **PyMuPDF** — PDF text extraction
  ```bash
  pip install PyMuPDF
  ```

## Usage

```
/as:product-spec-pdf-parser
```

Then provide PDF paths — point to individual files or a folder.

```
/as:product-spec-pdf-parser ~/Documents/specs/alphabeta-floor-lamp.pdf
```

Or a folder:

```
/as:product-spec-pdf-parser ~/Documents/specs/
```

### Variant depth

- **expand** (default) — one row per variant/SKU. Best for procurement.
- **summarize** — one row per product, variants comma-separated. Best for quick reference.

### Output

Shows a Markdown preview and, after approval, appends rows atomically to the 33-column project library. PDF-specific data is stored in `Notes`.

## How it fits

This is a **utility** — it can be called standalone or as part of a larger workflow:

| Context | How it's used |
|---------|--------------|
| Standalone | Designer has spec sheets or catalogs to process |
| `/as:product-research` | Designer drops a PDF from a rep into the conversation |
| Product & Materials Researcher agent | Agent delegates to this skill for PDF-based spec extraction |

## Output Schema

33 columns matching the master schema. Key fields populated:

| Field | Example |
|-------|---------|
| Product Name | Alphabeta Floor Lamp |
| SKU | HEM-AF-DB |
| Brand | Hem |
| Designer | Luca Nichetto |
| Category | Light |
| Materials | Aluminium, Steel |
| List Price | 595.00 EUR |
| Notes | Variant: Diamond, Black \| Origin: Sweden \| Source: alphabeta-fact-sheet.pdf |
| Source | `pdf-parser` |

## PDF Types Supported

| Type | Variant strategy |
|------|-----------------|
| **Fact sheet with SKUs** | One row per SKU (shade × color) |
| **Fact sheet with finishes** | One row per upholstery option |
| **Price book / configurator** | One row per product type, options summarized |
| **Product catalog** | Rows for each distinct product |
| **Spec sheet** | One row with full detail |

## Error Handling

- **Scanned/image PDFs** — detected and flagged for OCR
- **Password-protected PDFs** — caught and reported
- **Large PDFs (100+ pages)** — processed in 10-page chunks with progress updates

After every batch: `Parsed: X products from Y PDF(s)`

## Works with

| Skill | Relationship |
|-------|-------------|
| `/as:product-research` | Designer drops a PDF during research, this extracts the data |
| `/as:product-data-cleanup` | Run after parsing to normalize the library |
| `/as:product-image-processor` | Run after parsing to process product images |

## License

MIT
