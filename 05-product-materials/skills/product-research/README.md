# Product Research

FF&E product research companion for Claude Code. Captures, structures, and organizes products into a shared Google Sheet as the designer browses — the same sheet used by [Norma Jean](https://github.com/AlpacaLabsLLC/norma-jean) and the other data-management skills.

## The idea

One master Google Sheet holds every product the firm has ever researched. Products get in through multiple doors:

| Source | How |
|--------|-----|
| **Norma Jean** | Browser extension — Alt+C on any product page |
| **This skill** | Conversational — screenshots, paste, verbal notes, PDFs, search |
| `/product-spec-bulk-fetch` | Batch URL extraction |
| `/product-spec-pdf-parser` | PDF catalog parsing |

Every source writes to the same 33-column schema. The sheet is the library.

## Usage

```
/product-research
```

Connect to your Google Sheet (or create one), then start dropping things in.

## What you can do

- **Capture** — Drop a screenshot, paste specs, describe a product, or share a PDF. Claude extracts what it can and appends to the sheet.
- **Search** — "Find sustainable acoustic panels under $300" — Claude searches the web and presents candidates to capture.
- **Recall** — "What chairs do we have?" — Filter and browse the library by category, brand, price, tags, or date.
- **Organize** — Tag products, add notes, shortlist favorites, update status.
- **Compare** — Side-by-side comparison of products on any criteria.
- **Stats** — "How's the library?" — Category counts, brand breakdown, gap analysis.

## Schema

29 columns from the Norma Jean standard + 4 research columns:

| Section | Columns |
|---------|---------|
| Product | Link, Thumbnail, Product Name, Description, SKU, Brand, Designer, Vendor, Collection, Category |
| Dimensions | W, D, H, Seat H, Unit, Weight |
| Materials & Finish | Materials, Colors/Finishes, Selected Color/Finish |
| Pricing | List Price, Sale Price, Currency |
| Logistics | Lead Time, Warranty, Certifications, COM/COL, Indoor/Outdoor |
| Meta | Clipped At, Image URL |
| Research | Tags, Notes, Status, Source |

## Works with

| Tool | How |
|------|-----|
| [Norma Jean](https://github.com/AlpacaLabsLLC/norma-jean) | Browser clipper — writes to the same sheet |
| `/product-spec-bulk-cleanup` | Normalize the sheet — casing, categories, dimensions, materials |
| `/product-spec-bulk-fetch` | Batch-add products from URLs to the sheet |
| `/product-spec-pdf-parser` | Extract products from PDF catalogs to the sheet |
| `/product-image-processor` | Download and process images from the sheet's Image URL column |

## License

MIT
