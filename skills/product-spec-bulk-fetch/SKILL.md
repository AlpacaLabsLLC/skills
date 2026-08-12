---
name: product-spec-bulk-fetch
description: Extract structured FF&E specs from a list of product URLs into a schedule. Use to pull or bulk-import product-page data; not for PDF catalogs.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - AskUserQuestion
---

# /as:product-spec-bulk-fetch — Bulk Product Spec Fetcher

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Extract structured FF&E data from a list of product page URLs. Outputs a standardized schedule ready for design specs, procurement, or import into [Norma](https://norma.llc).

## Input

The user provides product URLs in one of these ways:

1. **Inline list** — URLs pasted directly in the message (one per line, or comma-separated)
2. **File path** — A `.txt`, `.csv`, or `.md` file containing URLs (one per line)
3. **Project library** — URLs from the named `Link` field in `product-library.csv`

If the input format is unclear, ask.

## Output Schema

Persistent results use the nearest project-root `product-library.csv`. Read `../../schema/product-schema.md` for the exact 33-column contract and `../../schema/csv-conventions.md` for safe local-file behavior.

Skill-specific column values:
- **AF (Status):** `saved`
- **AG (Source):** `bulk-fetch`
- **AD (Tags):** Blank (set by user later)
- **AE (Notes):** Blank
- **T (Selected Color/Finish):** Blank (unknown from URL)

## Extraction Process

For each URL:

1. **Fetch the page** using WebFetch with the prompt below
2. **Parse the response** into the schema fields
3. **Flag issues** — missing price, missing dimensions, non-product page
4. **Continue to next URL** — never stop the batch on a single failure

### WebFetch Extraction Prompt

Use this prompt (or close variant) for each URL:

```
Extract structured product/furniture specification data from this page. Return a JSON object with these exact fields:

- product_name: Full product name (Title Case)
- description: Short description or tagline (1-2 sentences), or null
- sku: Product ID, SKU, model number, or catalog number, or null
- brand: Manufacturer name (Title Case)
- designer: Designer or design studio name if attributed, or null
- vendor: The retailer/website selling the product (may differ from brand), or null
- collection: Product line or collection name, or null
- category: One of: Chair, Table, Sofa, Bed, Light, Storage, Desk, Shelving, Rug, Mirror, Accessory, Tabletop, Kitchen, Bath, Window, Door, Outdoor Furniture, Textile, Acoustic, Planter, Partition, Other
- width: Numeric width value only (no units), or null
- depth: Numeric depth value only (no units), or null
- height: Numeric height value only (no units), or null
- seat_height: Numeric seat height for seating products, or null
- unit: "in", "cm", or "mm" — whichever the page uses
- weight: Weight as stated with unit (e.g. "45 lbs"), or null
- materials: Comma-separated list of primary materials
- colors_finishes: Comma-separated list of ALL available colors or finish options
- list_price: Numeric price (no currency symbol, no commas), or null
- sale_price: Discounted/sale price if shown, or null
- currency: "USD", "EUR", "GBP", etc.
- lead_time: Delivery estimate as stated, or null
- warranty: Warranty info as stated, or null
- certifications: Comma-separated certifications (GREENGUARD, FSC, BIFMA, etc.), or null
- com_col: "COM", "COL", "COM/COL" if mentioned, or null
- indoor_outdoor: "Indoor", "Outdoor", or "Indoor/Outdoor" if specified, or null
- image_url: URL of the primary product image (largest/hero image)

If this is NOT a product page, return: {"error": "not_a_product_page"}
If dimensions use a combined format like "32 x 24 x 30 in", split them into W x D x H.
If price says "Contact for pricing" or similar, set price to null.
Return ONLY the JSON object, no other text.
```

## Workflow

### Step 1: Parse input
Extract all URLs from the user's input. Report count: "Found N product URLs."

### Step 2: Fetch in parallel
Process URLs using WebFetch. Use parallel tool calls — fetch up to 5 URLs simultaneously to maximize speed. Report progress after each batch.

### Step 3: Compile results
Build a results table. Group into:
- **Successful** — all key fields extracted
- **Partial** — some fields missing (still include in output)
- **Failed** — non-product page or fetch error

### Step 4: Present results
Show a summary table in markdown with all successful + partial results. Flag any issues:
- "Price not found" for trade/dealer sites
- "Dimensions not found" if missing
- "Failed to fetch" for errors

### Step 5: Preview persistence
The results table is the Markdown output. If the user asks to save, preview the selected row count, incomplete fields, and target `product-library.csv`, then use the single confirmation gate.

### Step 6: Save
After approval, serialize all complete canonical rows as one JSON array and invoke `python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" append product --project <project-root> --row-json <batch.json>` exactly once. Set `Clipped At` to the current timestamp and `Source` to `bulk-fetch`. The helper validates the complete batch and library before one atomic replacement; never loop per row.

Do not write a secondary structured export. A Markdown report may be retained separately.

## Edge Cases

- **Redirects or blocked pages**: Note the URL as failed, move on
- **Multiple products on one page**: Extract only the primary/featured product
- **Non-English pages**: Extract data as-is, note the language. The cleanup skill handles translation.
- **Vendor sites requiring login**: Will likely fail — note as "Login required" and move on
- **Duplicate URLs in input**: Skip duplicates, note them

## Error Reporting

After the batch completes, always report:
```
Fetched: X/Y successful, Z partial, W failed
```
List any failed URLs with the reason.
