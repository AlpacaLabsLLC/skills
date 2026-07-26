# /as:product-spec-bulk-fetch

Bulk FF&E product spec extractor for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Feed it product-page URLs and optionally save standardized rows to `product-library.csv`.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Usage

```
/as:product-spec-bulk-fetch
```

Then provide URLs inline, point to a text/CSV/Markdown file, or use links already stored in the project library.

```
/as:product-spec-bulk-fetch

https://www.hermanmiller.com/products/seating/lounge-seating/eames-lounge-chair-and-ottoman/
https://www.steelcase.com/products/collaborative-chairs/gesture/
https://www.ikea.pr/puertorico/es/pd/vardagen-vaso-art-70313106
```

### Input formats

- **Inline URLs** — one per line or comma-separated
- **File path** — a `.txt`, `.csv`, or `.md` file with URLs (one per line)
- **Project library** — values from the named `Link` field

### Output

Shows a Markdown preview and, after approval, appends rows atomically to the 33-column project library.

## How it fits

This is a **utility** — it can be called standalone or as part of a larger workflow:

| Context | How it's used |
|---------|--------------|
| Standalone | Designer has a list of URLs to batch-process |
| `/as:product-research` | Claude found candidates → bulk-fetch pulls full specs from their URLs |
| Product & Materials Researcher agent | Agent delegates to this skill for URL-based spec extraction |

## Output Schema

33 columns matching the master schema. Key fields populated:

| Field | Example |
|-------|---------|
| Product Name | Eames Lounge Chair |
| Brand | Herman Miller |
| Category | Chair |
| W × D × H | 32.75 × 32.5 × 33.5 in |
| Materials | Molded plywood, leather |
| List Price | 5695.00 USD |
| Source | `bulk-fetch` |

Also extracts when available: Description, SKU, Designer, Vendor, Collection, Seat H, Weight, Sale Price, Warranty, Certifications, COM/COL, Indoor/Outdoor.

## Error Handling

Never stops a batch on a single failure:

- **Trade/dealer sites** with hidden pricing → row included, price left blank
- **JS-rendered pages** → may return partial data or fail
- **Login-required pages** → logged as failed, batch continues
- **Non-product pages** → detected and skipped

After every batch: `Fetched: X/Y successful, Z partial, W failed`

## Works with

| Skill | Relationship |
|-------|-------------|
| `/as:product-research` | Research finds candidates, this pulls full specs |
| `/as:product-data-cleanup` | Run after fetching to normalize the library |
| `/as:product-image-processor` | Run after fetching to process product images |

## License

MIT
