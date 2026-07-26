---
name: product-spec-pdf-parser
description: Extract structured FF&E specs from PDF price books, fact sheets, or spec sheets into a schedule. Use for product PDFs; not web URLs or EPDs.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# /as:product-spec-pdf-parser — PDF Product Spec Parser

Extract structured FF&E data from product PDF files — price books, fact sheets, configurator sheets, and spec sheets. Uses PyMuPDF for text extraction and Claude's reasoning to parse wildly varying PDF layouts into a standardized schedule.

## Input

The user provides PDFs in one of these ways:

1. **File paths** — one or more PDF file paths
2. **Folder path** — a directory containing PDFs (will process all `.pdf` files)
3. **Just invoked** — ask the user for file paths or a folder

Also ask (or use defaults):

- **Persistence** — Markdown preview by default; optionally save to the project library
- **Variant depth** — `expand` (one row per variant/SKU, default) or `summarize` (comma-separated variants in one row)

## Output Schema

Persistent products use the nearest project-root `product-library.csv` with no extra columns. Read `../../schema/product-schema.md` and `../../schema/csv-conventions.md`.

Skill-specific named values: `Source` is `pdf-parser`; `Status` is `saved`; `Link`, `Thumbnail`, `Vendor`, `Sale Price`, and `Image URL` are blank unless directly supported by the PDF.

### PDF-specific data in `Notes`

PDFs contain fields that don't have dedicated master columns. Append these to Notes using `|` as delimiter:

- **Variant**: `Variant: Diamond, Black`
- **Price Adder**: `Price adder: +$130 (PostureFit SL)`
- **Country of Origin**: `Origin: Sweden`
- **Source File**: `Source: alphabeta-fact-sheet.pdf`

Example Notes cell: `Variant: Diamond, Black | Origin: Sweden | Source: alphabeta-fact-sheet.pdf`

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

If persistence was requested, use this results table as the change preview and present the single confirmation gate. Do not ask the same confirmation first in prose.

### Step 5: Write output

Without persistence, leave the result as Markdown. After approval to persist, serialize all complete canonical rows as one JSON array and invoke `python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" append product --project <project-root> --row-json <batch.json>` exactly once. The shared helper validates the complete batch and CSV before one atomic replacement; never loop per row. PDF-specific data stays in `Notes`; do not create extra columns or secondary structured exports.

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
