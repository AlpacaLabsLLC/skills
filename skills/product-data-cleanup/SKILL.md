---
name: product-data-cleanup
description: Clean a local FF&E CSV schedule by normalizing casing, dimensions, units, language, materials, and formatting. Use when asked to clean, fix, or standardize product data.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
---

# /as:product-data-cleanup — Product Data Normalizer

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Takes a messy FF&E schedule and normalizes everything: casing, dimensions, units, language, materials vocabulary, currency formatting, and duplicates. Outputs a clean, consistent, spec-ready schedule.

Persistent cleanup operates on the nearest project's `product-library.csv`. Pasted tables may be previewed in Markdown but are not another persistent format.

## Input

The user provides a schedule in one of these ways:

1. **Project library** — the nearest `product-library.csv` under an ancestor containing `PROJECT.md`.
2. **CSV file path** — import only after its exact 33-column header is validated.
3. **Pasted table** — preview a proposed canonical mapping before any persistence.

If the input format is unclear, ask.

## Cleanup Rules

### 1. Casing

| Field | Rule | Example |
|-------|------|---------|
| Product Name | Title Case | `eames lounge chair` → `Eames Lounge Chair` |
| Brand | Title Case, preserve known abbreviations | `HERMAN MILLER` → `Herman Miller`, `HAY` → `HAY` |
| Collection | Title Case | `cosm` → `Cosm` |
| Category | Title Case, singular | `chairs` → `Chair`, `TABLES` → `Table` |
| Materials | Sentence case, lowercase after first word | `MOLDED PLYWOOD, FULL GRAIN LEATHER` → `Molded plywood, full grain leather` |
| Colors/Finishes | Title Case per item | `walnut/black leather` → `Walnut / Black Leather` |

**Known brand abbreviations to preserve**: HAY, USM, B&B, DWR, CB2, HBF, OFS, SitOnIt, 3form, ICF

### 2. Category Normalization

Map free-text categories to the canonical vocabulary and alias table defined in `../../schema/product-schema.md`. Read that file for the full mapping of variations (English, Spanish, legacy terms) to canonical category names.

If a category is ambiguous, keep the closest match and add a `[?]` flag for the user to review.

### 3. Dimensions

**Splitting combined dimensions:**
| Input | → W | → D | → H | → Unit |
|-------|-----|-----|-----|--------|
| `32 x 24 x 30 in` | 32 | 24 | 30 | in |
| `80 × 60 × 75 cm` | 80 | 60 | 75 | cm |
| `W32 D24 H30` | 32 | 24 | 30 | (infer) |
| `32"W x 24"D x 30"H` | 32 | 24 | 30 | in |
| `Ancho: 80, Prof: 60, Alto: 75 cm` | 80 | 60 | 75 | cm |

**Dimension rules:**
- Always store as **separate W, D, H columns** with a **Unit column**
- If dimensions are already split, validate they're numeric (strip any unit text from the number)
- Interpret `"` as inches, `'` as feet (convert to inches: `2'6"` → `30`)
- Accept `×`, `x`, `X`, `by`, `por` as separators
- Convention: W × D × H (width × depth × height). If only 2 values, ask which is missing.
- Round to 2 decimal places max
- If unit is missing but values suggest inches (all < 100 for furniture), assume `in`. If values suggest cm (> 100 or explicit), use `cm`. If truly ambiguous, flag with `[?]`.

**Do NOT convert units.** Keep the original unit. Designers need the manufacturer's spec for ordering.

### 4. Language Normalization

Detect the language of each field value and normalize to **English** unless the user specifies otherwise.

| Spanish (common in UY sources) | → English |
|-------------------------------|-----------|
| Silla | Chair (category) |
| Mesa | Table (category) |
| Escritorio | Desk (category) |
| Madera | Wood (material) |
| Cuero | Leather (material) |
| Acero | Steel (material) |
| Vidrio | Glass (material) |
| Tela | Fabric (material) |
| Mármol | Marble (material) |
| Roble | Oak (material) |
| Nogal | Walnut (material) |
| Blanco | White (color) |
| Negro | Black (color) |
| Natural | Natural (keep as-is) |
| Cromado | Chrome (finish) |

**Rule:** Translate category, material, and color/finish fields. Leave Product Name and Brand as-is (proper nouns).

If the user says "keep in Spanish" or specifies a target language, respect that.

### 5. Materials & Finishes Vocabulary

Standardize common material terms:

| Variations | → Standard |
|-----------|------------|
| SS, Stainless, S/S | Stainless steel |
| Ply, Plywood, Mold ply | Molded plywood |
| MDF, Medium density | MDF |
| HPL, High pressure laminate | HPL |
| Lam, Laminate | Laminate |
| Fab, Textile | Fabric |
| COM, C.O.M. | COM (Customer's Own Material) |
| COL, C.O.L. | COL (Customer's Own Leather) |
| Powder coat, PC, Pwdr | Powder-coated |
| Chrm, Chrome plated | Chrome |
| Anodized alum, Anod. | Anodized aluminum |
| Ven, Veneer | Veneer |
| Sol. wood, Solid | Solid wood |

### 6. Price & Currency

- Strip currency symbols (`$`, `€`, `£`, `¥`) — store symbol as currency code in separate column
- Remove thousands separators (both `.` and `,` — detect locale: `1.234,56` is EU format, `1,234.56` is US)
- Store as plain decimal number: `5695.00`
- If price says "Contact", "Quote", "Trade", "A consultar", "Consultar" → set to empty
- Currency detection: `$` alone defaults to `USD` unless context suggests otherwise (UY site → `UYU`, EU site → `EUR`)
- If a schedule mixes currencies, keep each row's original currency. Add a note at the top.

### 7. Duplicate Detection

- Flag rows with identical Product Name + Brand as potential duplicates
- Flag rows with identical URL as definite duplicates
- Don't auto-delete — present duplicates to the user and ask what to keep

### 8. Whitespace & Formatting

- Trim leading/trailing whitespace from all fields
- Collapse multiple spaces to single space
- Remove line breaks within field values
- Normalize list separators: `wood / metal / glass` → `Wood, Metal, Glass` (comma-separated)
- Remove trailing commas or semicolons

## Workflow

### Step 1: Load the schedule
Read the input. Report: "Loaded N rows with M columns."
Map input columns to the canonical schema. If column mapping is ambiguous (e.g., a column called "Size" could be combined dimensions), ask the user.

### Step 2: Analyze issues
Scan all rows and produce a summary:
```
## Cleanup Preview

- **Casing**: X product names need Title Case
- **Categories**: Y rows have non-standard categories (mapping: "chairs" → Seating, etc.)
- **Dimensions**: Z rows have combined dimensions to split
- **Language**: W rows have Spanish-language fields to translate
- **Materials**: V rows have non-standard material terms
- **Prices**: U rows need currency formatting cleanup
- **Duplicates**: T potential duplicate rows found
- **Empty fields**: S rows missing dimensions, R rows missing price
```

### Step 3: Confirm scope
The issue summary is the change preview. Present selectable cleanup groups directly through the single confirmation gate; do not ask the same question first in prose.

### Step 4: Apply fixes
Process every row through the active cleanup rules. Track every change made.

### Step 5: Present results
Show a **before/after diff** for a sample of changed rows (up to 5 examples). Then show the full cleaned table.

Report:
```
## Cleanup Complete

- Rows processed: N
- Changes made: X
- Flagged for review: Y (marked with [?])
```

### Step 6: Save
Read `../../schema/product-schema.md` and `../../schema/csv-conventions.md`. For multiple changed rows, materialize the complete proposed 33-column CSV as a temporary or user-visible review file, validate that candidate, preview the whole change once, and use the single confirmation gate. After approval, invoke `python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" import product --project <project-root> --source <review.csv>` exactly once for one atomic replacement; never loop `update`. A genuinely single-record edit may instead invoke the same plugin-root helper's `update` command once with one uniquely matching stable field. Never overwrite an arbitrary input or hand-edit `product-library.csv`.

## Edge Cases

- **Mixed-language schedule**: Detect dominant language per column, normalize to one language
- **Merged cells or irregular formatting**: Flag and ask user how to handle
- **Extra columns not in schema**: Reject persistence and preview how they would map to canonical fields
- **Empty rows**: Remove silently
- **Header detection**: Auto-detect header row (first row with text that matches known field names). If uncertain, ask.
