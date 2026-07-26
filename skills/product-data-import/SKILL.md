---
name: product-data-import
description: Generate a formatted FF&E specification schedule from notes, CSV, or pasted lists and optionally save it to the project's 33-column CSV library. Use when asked to import products or build a schedule.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# /as:product-data-import — Product Data Importer

Takes raw product data and formats it as a Markdown preview or as rows in the nearest project's `product-library.csv`, using the shared 33-column schema.

## When to Use

- Designer has a list of products in notes or conversation and needs it formatted for a deliverable
- A rough product list needs to become a spec-ready schedule with item numbers, quantities, and extended pricing
- Products from multiple sources need to be consolidated into one formatted schedule
- An existing schedule needs to be reformatted to match the standard schema

## Step 1: Accept Input

The designer provides product data in any format:

**Raw notes:**
```
3x Eames Lounge Chair, Herman Miller, walnut/black leather, $5,695 each
2x Nelson Platform Bench 48", Herman Miller, natural maple, $2,195
1x Noguchi Coffee Table, Herman Miller, walnut/glass, $2,095
Pendant light for above the table - something by Flos, budget $800-1200
```

**Pasted CSV:**
```
Product, Brand, Qty, Price
Eames Lounge Chair, Herman Miller, 3, $5695
Nelson Bench 48, Herman Miller, 2, $2195
```

**A file path:**
```
/as:product-data-import ./product-list.csv
```

**Conversational:**
```
"We need 8 task chairs — Steelcase Leap V2, black, about $1,200 each.
 Also 4 monitor arms, any brand, under $300."
```

Accept whatever the designer gives. Don't ask for more structure — work with what you have.

## Step 2: Parse and Enrich

For each product in the input:

1. **Extract known fields:** product name, brand, quantity, price, dimensions, materials, finish, category
2. **Fill in from knowledge:** If the product is well-known (Eames Lounge Chair, Steelcase Leap, etc.), fill in standard dimensions, materials, and weight from your training data. Mark these as "from reference" in notes.
3. **Assign categories:** Map to the canonical vocabulary defined in `../../schema/product-schema.md`
4. **Calculate extended prices:** Unit price × quantity
5. **Assign item numbers:** Sequential within each category group (S-01, S-02 for Seating; T-01 for Tables; L-01 for Lighting, etc.)
6. **Flag unknowns:** If a product is vague ("pendant light, Flos, $800-1200"), note it as "TBD — needs specification" and include budget range

### Category prefixes for item numbers

Item number prefixes are defined in `../../schema/product-schema.md` under **Item Number Prefixes**. Read that file for the full mapping of canonical categories to prefixes (e.g. Chair → S, Table → T, Light → L).

## Step 3: Present the Schedule

Show the formatted schedule as a markdown table:

```
## FF&E Schedule — [Project Name if known]

[n] items · [total qty] units · $[total extended] estimated

| Item # | Product | Brand | Qty | W | D | H | Unit | Materials | Finish | Unit $ | Ext $ | Lead | Notes |
|--------|---------|-------|-----|---|---|---|------|-----------|--------|--------|-------|------|-------|
| S-01 | Eames Lounge Chair | Herman Miller | 3 | 32.75 | 32.5 | 33.5 | in | Molded plywood, leather | Walnut/Black | $5,695 | $17,085 | 8-12w | |
| T-01 | Nelson Platform Bench 48" | Herman Miller | 2 | 48 | 18.5 | 14 | in | Solid maple | Natural | $2,195 | $4,390 | 6-8w | |
| T-02 | Noguchi Coffee Table | Herman Miller | 1 | 50 | 36 | 15.75 | in | Walnut, glass | — | $2,095 | $2,095 | 6-8w | |
| L-01 | TBD Pendant | Flos | 1 | — | — | — | — | — | — | $800-$1,200 | $800-$1,200 | — | Needs specification |

**Subtotals by category:**
- Seating: $17,085 (3 units)
- Tables: $6,485 (3 units)
- Lighting: $800-$1,200 (1 unit, TBD)
- **Total: $24,370-$24,770**
```

### Presentation rules

- **Group by category**, sorted by item number within each group
- **Show subtotals** per category and a grand total
- **Flag TBD items** clearly — include budget range if given
- **Show dimensions** from reference data when you know the product; leave blank and note "dims TBD" when you don't
- **Don't fabricate prices** — if you're unsure, note "price TBD" or "estimated" and use the designer's stated budget
- **Currency** — default USD unless the designer specifies otherwise

## Step 4: Choose persistence

The Markdown schedule is always available without a write. Persist structured product data only to the nearest project-root `product-library.csv`. If no ancestor contains `PROJECT.md`, stop and direct the user to `/as:project`.

## Step 5: Save

Read `../../schema/product-schema.md` for the exact header, category vocabulary, and values. Read `../../schema/csv-conventions.md` for parsing and mutation rules. Preview the complete batch, row count, totals, target path, and material field changes, then use the single confirmation gate. After approval, serialize all complete rows as one JSON array and invoke `python3 "${CLAUDE_PLUGIN_ROOT}/skills/master-schedule/scripts/csv-library.py" append product --project <project-root> --row-json <batch.json>` exactly once. The helper owns batch validation and one atomic replacement; never loop per row or rewrite the persistent CSV directly.

Skill-specific column values:
- **AG (Source):** `product-data-import`
- **AF (Status):** `specified`
- **AD (Tags):** Item number (e.g. "S-01") + any project tags
- **AE (Notes):** `Qty: 3 · Ext: $17,085` (quantity and extended price, since the schema has no dedicated Qty column)

### Quantity handling

The product library is one row per product, not per unit. Put quantity and extended price in `Notes`, for example `Qty: 3 · Ext: $17,085`.

## Step 6: Summary

After saving:

```
✓ FF&E Schedule saved to [product-library.csv path]
  [n] line items · [total qty] units · $[total] estimated
  [n] items fully specified, [n] items need specification (TBD)
```

If there are TBD items, offer to research them:

```
Want me to research the TBD items? I can use /as:product-research to find specific products for:
- L-01: Flos pendant, $800-$1,200 budget
```

## Pairs With

- `/as:product-research` — research specific products to fill TBD slots
- `/as:product-spec-bulk-fetch` — pull full specs from product URLs
- `/as:product-data-cleanup` — normalize the schedule after assembly
- `/as:product-enrich` — auto-tag categories, colors, and materials
- `/as:csv-to-sif` — convert the schedule to SIF for dealer procurement
