---
name: product-spec-pdf-parser
description: Extract structured FF&E product specs from PDF files — price books, fact sheets, and spec sheets. Claude reads extracted text and structures products into a standardized schedule.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - mcp__google__sheets_values_get
  - mcp__google__sheets_values_update
  - mcp__google__sheets_spreadsheet_get
---

# /product-spec-pdf-parser — PDF Product Spec Parser

Extract structured FF&E data from product PDF files — price books, fact sheets, configurator sheets, and spec sheets. Uses PyMuPDF for text extraction and Claude's reasoning to parse wildly varying PDF layouts into a standardized schedule.

## Input

The user provides PDFs in one of these ways:

1. **File paths** — one or more PDF file paths
2. **Folder path** — a directory containing PDFs (will process all `.pdf` files)
3. **Just invoked** — ask the user for file paths or a folder

Also ask (or use defaults):

- **Output destination** — Google Sheet, local CSV, or markdown (default: ask)
- **Variant depth** — `expand` (one row per variant/SKU, default) or `summarize` (comma-separated variants in one row)

## Output Schema

24 fields per product row. Extends the Canoa Clipper FF&E format with fields commonly found in PDF spec sheets:

| # | Field | Description | Format |
|---|-------|-------------|--------|
| 1 | Product Name | Full product name | Title Case |
| 2 | Variant | What distinguishes this row (shade shape, color, size, upholstery) | Free text, blank if single variant |
| 3 | SKU | Model or part number | As listed |
| 4 | Brand | Manufacturer or vendor | Title Case |
| 5 | Designer | Credited designer(s) | Title Case, blank if not listed |
| 6 | Collection | Product line or collection name | Title Case, blank if N/A |
| 7 | Category | Seating, Lighting, Tables, Storage, Desks, Accessories, Textiles, Acoustic, Planters, Other | Title Case, singular |
| 8 | Description | 1-2 sentence product description | Sentence case |
| 9 | W | Width, numeric only | Decimal number |
| 10 | D | Depth, numeric only | Decimal number |
| 11 | H | Height, numeric only | Decimal number |
| 12 | Seat H | Seat height (seating only) | Decimal number, blank if N/A |
| 13 | Unit | Dimension unit | `in`, `cm`, or `mm` |
| 14 | Weight | Product weight with unit | As listed (e.g., "12 kg", "26.4 lbs") |
| 15 | Materials | Primary materials | Comma-separated |
| 16 | Colors/Finishes | For this specific variant | Comma-separated |
| 17 | List Price | Base or total price | Decimal number, no currency symbol |
| 18 | Price Adder | Incremental cost for configurator option | Decimal number, blank if N/A |
| 19 | Currency | Currency code | `USD`, `EUR`, etc. |
| 20 | Lead Time | Delivery estimate | As stated |
| 21 | Warranty | Warranty terms | As stated, blank if not listed |
| 22 | Certifications | Standards or certifications (CE, UL, EN, etc.) | Comma-separated |
| 23 | Country of Origin | Manufacturing origin | As stated, blank if not listed |
| 24 | Source File | PDF filename | Filename only, no path |

## Variant Handling

Different PDF types require different approaches:

### Fact sheets with SKUs (e.g., Alphabeta lamp)
- **One row per SKU.** Each shade shape × color = one row.
- Product Name stays the same across rows. Variant describes the distinguishing attributes.
- Example: "Alphabeta Floor Lamp" / Variant: "Diamond, Black" / SKU: "..."

### Fact sheets with upholstery/finish combos (e.g., Puffy lounge chair)
- **One row per upholstery option.** Frame finish goes in Colors/Finishes.
- Distinct products (chair + ottoman) each get their own set of rows.
- Example: "Puffy Lounge Chair" / Variant: "Traffic Red" / Colors/Finishes: "Chrome frame"

### Price books / configurators (e.g., Aeron price book)
- **One row per distinct product type** (e.g., Work Chair, Stool, Side Chair).
- Base configuration in main fields. Summarize configuration options — do NOT explode every permutation.
- Use Price Adder for incremental costs of add-ons or upgrades.
- Example: "Aeron Chair" / Variant: "Size B, Graphite" / List Price: 1395.00 / Price Adder: 130.00 (PostureFit SL)

### `expand` vs `summarize` mode
- **expand** (default): One row per variant, SKU, or distinct option. Best for procurement and ordering.
- **summarize**: One row per product. Colors/Finishes and Variant are comma-separated lists. Best for quick reference.

## Workflow

### Step 1: Get input

Parse the user's input to identify PDF file(s) and output preferences.

- If given a folder, list all `.pdf` files and report count
- If no PDFs found or path is invalid, ask the user
- Confirm variant depth — default to `expand` unless the user says otherwise
- Report: "Found N PDF(s) to process."

### Step 2: Extract text from PDF

Use PyMuPDF (fitz) to extract text from each PDF. Run this Python script via Bash:

```python
import fitz
import sys
import json

pdf_path = sys.argv[1]
doc = fitz.open(pdf_path)
pages = []
for i, page in enumerate(doc):
    text = page.get_text()
    pages.append({"page": i + 1, "text": text})
doc.close()

print(json.dumps({"filename": pdf_path.split("/")[-1], "total_pages": len(pages), "pages": pages}))
```

For each PDF, extract all pages and save the JSON output.

### Step 3: Parse products with Claude

Read the extracted text and identify all products, variants, and specifications. This is the core intelligence step — Claude reasons over the text to structure it.

**For small PDFs (≤20 pages):** Process all pages at once.

**For large PDFs (>20 pages):** Process in chunks of 10 pages at a time. After each chunk:
- Accumulate parsed products
- Carry forward context (product name, brand, any ongoing configuration table)
- At the end, deduplicate and merge

**Parsing instructions:**

1. **Identify the document type** — fact sheet, price book, configurator, spec sheet, catalog
2. **Extract global fields first** — brand, designer, collection, warranty, certifications, country of origin (these usually appear once)
3. **Find product boundaries** — headings, page breaks, or new product names signal a new product
4. **For each product, extract all variants** based on the variant handling rules above
5. **Map dimensions carefully** — PDFs often format dimensions as "W × D × H" or in a spec table. Parse into separate W, D, H fields.
6. **Prices** — distinguish between base price and adders. If a configurator shows "Base: $1,395 / Add: $130 for PostureFit", set List Price = 1395, Price Adder = 130
7. **Leave fields blank rather than guessing** — if a field isn't in the PDF, leave it empty

### Step 4: Present results

Show a summary markdown table with the parsed products. Include:
- Row count per PDF
- Any issues or assumptions made
- Sample of the first 10 rows if large

Ask: **"Does this look correct? Should I adjust anything before saving?"**

### Step 5: Write output

Ask the user (if not already specified): **"Where should I save this?"**

Options:
- **Google Sheet** — write rows to a specified sheet (ask for spreadsheet ID or create new)
- **Local CSV** — save to a specified path (default: `~/Documents/Work-Docs/ffe-pdf-parse-YYYY-MM-DD.csv`)
- **Just the table** — leave as markdown in the conversation

## CSV Format

```csv
Product Name,Variant,SKU,Brand,Designer,Collection,Category,Description,W,D,H,Seat H,Unit,Weight,Materials,Colors/Finishes,List Price,Price Adder,Currency,Lead Time,Warranty,Certifications,Country of Origin,Source File
"Alphabeta Floor Lamp","Diamond, Black","HEM-AF-DB",Hem,"Luca Nichetto",Alphabeta,Lighting,"Modular floor lamp with interchangeable shades",,,,,,,"Aluminium, Steel","Black",595.00,,EUR,,"","CE","Sweden","alphabeta-fact-sheet.pdf"
```

## Google Sheets Format

Write header row first, then data rows. Use the same 24-column order as the CSV. Wrap text fields in proper formatting — no extra quotes needed for Sheets API.

## Edge Cases

- **Scanned PDFs (image-only)**: PyMuPDF will return empty or garbage text. Detect this (very short text relative to page count) and tell the user: "This PDF appears to be scanned/image-based. Text extraction won't work — consider using an OCR tool first."
- **Multi-language PDFs**: Extract data as-is. Note the language. The cleanup skill handles translation.
- **PDFs with tables as images**: Common in price books. If a section seems to have missing data despite being a spec-heavy document, note it and flag for manual review.
- **Password-protected PDFs**: PyMuPDF will fail to open. Catch the error and tell the user.
- **Very large PDFs (100+ pages)**: Process in 10-page chunks. Give progress updates every 20 pages.
- **Mixed product types in one PDF**: Handle each product type independently. A catalog with chairs AND tables gets rows for both.

## Error Reporting

After processing, always report:
```
Parsed: X products from Y PDF(s)
- filename.pdf: N products extracted
- filename2.pdf: M products extracted
Issues: [list any problems]
```
