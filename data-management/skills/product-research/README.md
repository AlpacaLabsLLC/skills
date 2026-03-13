# Product Research

FF&E product research companion for Claude Code. Captures, structures, and organizes products into a persistent library as the designer browses — no setup, no pipeline, just drop things in.

## Usage

```
/product-research
```

Then start dropping URLs, PDFs, screenshots, or notes into the conversation. The skill captures product data, structures it into a standard FF&E schema, and saves it to a growing library.

## What it does

- **Capture** — Drop a URL, PDF, screenshot, or verbal note. Claude extracts product specs and saves them.
- **Search** — "Find sustainable acoustic panels under $300" — Claude searches the web and presents candidates.
- **Recall** — "What chairs do we have?" — Filter and browse the library by category, brand, price, tags, or date.
- **Organize** — Tag products, create collections, add notes, shortlist favorites.
- **Compare** — Side-by-side comparison of products against any criteria.
- **Export** — Output as CSV or Google Sheet in the standard FF&E schema, compatible with the other data-management skills.

## Library

Products are stored in a `product-library.json` file. Each entry includes the standard 15-field FF&E schema plus research metadata (tags, collections, notes, status, sustainability).

The library persists across sessions and grows over time — useful for building a firm-wide product knowledge base.

## Works with

| Skill | How |
|-------|-----|
| `/product-spec-bulk-cleanup` | Export the library (or a collection) and clean it up |
| `/product-spec-pdf-parser` | Drop a PDF into the conversation — research companion parses it and adds to library |
| `/product-image-processor` | Export image URLs from the library and batch-process them |
| `/spec-package` | Export a collection and run the full pipeline |

## Examples

```
# Drop a URL while browsing
https://www.muuto.com/outline-sofa-3-seater

# Verbal note
Remember that walnut bench from the Hem showroom, around $1,200

# Search
Find me task chairs with GREENGUARD certification

# Recall
What do we have from HAY?
Show the reception-inspo collection

# Organize
Tag the last 3 as project-oak
Shortlist the Outline sofa
Create a collection called lobby-options

# Export
Export my shortlist as CSV
```

## License

MIT
