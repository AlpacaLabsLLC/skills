---
name: product-spec-bulk-fetch
description: Fetch structured FF&E product specs from a list of URLs. Extracts name, brand, dimensions, materials, price, and images into a standardized schedule.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebFetch
  - AskUserQuestion
  - mcp__google__sheets_values_get
  - mcp__google__sheets_values_update
  - mcp__google__sheets_spreadsheet_get
---

# /product-spec-bulk-fetch — Bulk Product Spec Fetcher

Extract structured FF&E data from a list of product page URLs. Outputs a standardized schedule ready for design specs, procurement, or import into Canoa.

## Input

The user provides product URLs in one of these ways:

1. **Inline list** — URLs pasted directly in the message (one per line, or comma-separated)
2. **File path** — A `.txt`, `.csv`, or `.md` file containing URLs (one per line)
3. **Google Sheet column** — A spreadsheet ID + column containing URLs to re-fetch

If the input format is unclear, ask.

## Output Schema

Every product is extracted into these fields, matching the Canoa Clipper FF&E schedule:

| Field | Description | Format |
|-------|-------------|--------|
| Product Name | Full product name as listed | Title Case |
| Brand | Manufacturer or vendor | Title Case |
| Collection | Product line or collection name | Title Case, blank if N/A |
| Category | Seating, Tables, Lighting, Storage, Accessories, etc. | Title Case, singular |
| W | Width, numeric only | Decimal number |
| D | Depth, numeric only | Decimal number |
| H | Height, numeric only | Decimal number |
| Unit | Dimension unit | `in`, `cm`, or `mm` |
| Materials | Primary materials | Comma-separated |
| Colors/Finishes | Available or selected finishes | Comma-separated |
| Price | Numeric price | Decimal number, no currency symbol |
| Currency | Currency code | `USD`, `EUR`, `UYU`, etc. |
| Lead Time | Delivery estimate | As stated (e.g., "4-6 weeks", "In Stock") |
| URL | Source page | Full URL |
| Image URL | Primary product image | Direct image URL |

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
- brand: Manufacturer or vendor name (Title Case)
- collection: Product line or collection name (empty string if not found)
- category: One of: Seating, Tables, Desks, Lighting, Storage, Accessories, Textiles, Acoustic, Planters, Other
- width: Numeric width value only (no units), or null
- depth: Numeric depth value only (no units), or null
- height: Numeric height value only (no units), or null
- unit: "in", "cm", or "mm" — whichever the page uses
- materials: Comma-separated list of primary materials
- colors_finishes: Comma-separated list of colors or finish options shown
- price: Numeric price (no currency symbol, no commas), or null if not shown
- currency: "USD", "EUR", "GBP", etc.
- lead_time: Delivery estimate as stated, or empty string
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

### Step 5: Ask about output format
Ask the user: **"Where should I save this?"**
Options:
- **Local CSV** — save to a specified path (default: `~/Documents/Work-Docs/ffe-fetch-YYYY-MM-DD.csv`)
- **Google Sheet** — write rows to a specified sheet (ask for spreadsheet ID or create new)
- **Just the table** — leave as markdown in the conversation

### Step 6: Save
Write the output in the chosen format. For CSV, use proper escaping. For Google Sheets, use the `mcp__google__sheets_values_update` tool to write rows.

## CSV Format

```csv
Product Name,Brand,Collection,Category,W,D,H,Unit,Materials,Colors/Finishes,Price,Currency,Lead Time,URL,Image URL
"Eames Lounge Chair",Herman Miller,Eames,Seating,32.75,32.5,33.5,in,"Molded plywood, leather","Walnut/Black leather",5695.00,USD,"8-10 weeks",https://example.com/eames,https://example.com/eames.jpg
```

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
