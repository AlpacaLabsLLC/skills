# FF&E Product Schema

Version 2.0 · 33 columns (A–AG)

One row per product. Persistent FF&E data uses the project-local `product-library.csv` and the rules in [csv-conventions.md](csv-conventions.md).

## Column Reference

### Product Identity (A–K)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| A | Category | Text | Title Case | One of 22 canonical terms. See **Category Vocabulary** below. |
| B | Brand | Text | Title Case | Manufacturer name. Preserve known abbreviations (HAY, USM, HBF, OFS, DWR, CB2). |
| C | Vendor | Text | Title Case | Retailer or website selling the product. May differ from Brand. |
| D | Thumbnail | URL | Plain URL | Optional thumbnail URL. Blank if no image is available. |
| E | Product Name | Text | Title Case | Full product name as listed by manufacturer. |
| F | Designer | Text | Title Case | Designer or design studio if attributed. Blank if N/A. |
| G | Indoor/Outdoor | Text | `Indoor`, `Outdoor`, or `Indoor/Outdoor` | Use context. Blank if unspecified. |
| H | Description | Text | Sentence case | 1–2 sentence description or tagline. |
| I | SKU | Text | As listed | Model number, part number, or catalog number. |
| J | Link | URL | Plain URL | Source page URL. Blank for PDFs or manually entered products. |
| K | Collection | Text | Title Case | Product line or collection name. Blank if N/A. |

### Dimensions (L–Q)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| L | W | Number | Decimal | Width. Numeric only, no units. |
| M | D | Number | Decimal | Depth. Numeric only, no units. |
| N | H | Number | Decimal | Height. Numeric only, no units. |
| O | Seat H | Number | Decimal | Seat height. Seating products only, blank otherwise. |
| P | Unit | Text | `in`, `cm`, or `mm` | Dimension unit. Keep manufacturer's original — do not convert. |
| Q | Weight | Text | As stated | Weight with unit, e.g. "45 lbs", "20 kg". |

### Materials & Finish (R–T)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| R | Materials | Text | Comma-separated | Primary materials, e.g. "Molded plywood, full grain leather". |
| S | Colors/Finishes | Text | Comma-separated | All available color and finish options. |
| T | Selected Color/Finish | Text | — | Designer's specific selection. Often blank initially. |

### Pricing (U–W)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| U | List Price | Number | Decimal, no symbol | Manufacturer list price. No currency symbols or commas. |
| V | Sale Price | Number | Decimal, no symbol | Discounted price if applicable. Blank otherwise. |
| W | Currency | Text | ISO code | `USD`, `EUR`, `GBP`, `UYU`, etc. Default `USD`. |

### Logistics (X–AA)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| X | Lead Time | Text | As stated | Delivery estimate, e.g. "8–12 weeks", "In stock". |
| Y | Warranty | Text | As stated | Warranty terms if found. |
| Z | Certifications | Text | Comma-separated | GREENGUARD, FSC, BIFMA, Cradle to Cradle, etc. |
| AA | COM/COL | Text | `COM`, `COL`, or `COM/COL` | Customer's Own Material / Leather availability. Blank if N/A. |

### Meta (AB–AC)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| AB | Clipped At | Text | ISO 8601 | Timestamp when row was created, e.g. `2026-03-30T14:30:00Z`. |
| AC | Image URL | Text | Direct URL | Primary product image URL. Blank for PDFs. |

### Research (AD–AG)

| Col | Field | Type | Format | Notes |
|-----|-------|------|--------|-------|
| AD | Tags | Text | Comma-separated | Project tags, room IDs, item numbers, cross-references. E.g. `S-01, lobby-reno, walnut`. |
| AE | Notes | Text | Free text | Skill-specific notes, reasoning, flags, variant info. See **Notes Conventions** below. |
| AF | Status | Text | Lowercase | Row lifecycle state. See **Status Values** below. |
| AG | Source | Text | Lowercase | Which skill created the row. See **Source Values** below. |

## Category Vocabulary

Use exactly ONE of these 22 terms in column A:

Chair · Table · Sofa · Bed · Light · Storage · Desk · Shelving · Rug · Mirror · Accessory · Tabletop · Kitchen · Bath · Window · Door · Outdoor Furniture · Textile · Acoustic · Planter · Partition · Other

### Category Aliases

Map free-text categories to canonical terms. This table covers English variations, Spanish translations, and legacy terms.

| Canonical | Also matches |
|-----------|-------------|
| Chair | Chairs, Seating, Silla, Sillas, Task Chair, Lounge Chair, Stool, Stools, Bench seating, Office Chair |
| Table | Tables, Mesa, Mesas, Conference Table, Coffee Table, Side Table, Dining Table |
| Sofa | Couch, Loveseat, Settee, Sofá |
| Bed | Beds, Cama, Daybed, Bunk |
| Light | Lights, Lighting, Lamp, Lamps, Luminaria, Luminarias, Pendant, Sconce, Fixture, Chandelier |
| Storage | Cabinet, Cabinets, Credenza, Filing, Locker, Estante |
| Desk | Desks, Escritorio, Workstation (only if clearly a desk, not a table) |
| Shelving | Shelf, Shelves, Bookcase, Bookshelf, Estantería |
| Rug | Rugs, Carpet, Alfombra, Tapete |
| Mirror | Mirrors, Espejo |
| Accessory | Accessories, Accesorios, Clock, Cushion, Throw, Tray, Vase |
| Tabletop | Dinnerware, Glassware, Flatware, Serveware, Vajilla |
| Kitchen | Kitchen fixtures, Cocina |
| Bath | Bathroom, Baño, Bath fixtures |
| Window | Curtain, Drape, Blind, Shade, Cortina, Persiana |
| Door | Doors, Puerta |
| Outdoor Furniture | Outdoor, Exterior, Mueble exterior |
| Textile | Textiles, Fabric, Upholstery, Tapiz |
| Acoustic | Acoustic panel, Sound panel, Baffle, Panel acústico |
| Planter | Planters, Plant pot, Maceta, Jardinera |
| Partition | Partitions, Divider, Screen, Panel, Biombo, Mampara |
| Other | Anything that doesn't fit above |

If a category is ambiguous, use the closest match and add `[?]` for the user to review.

## Item Number Prefixes

Used by `/as:product-data-import` to number items within a schedule. Each category maps to a prefix:

| Category | Prefix |
|----------|--------|
| Chair | S |
| Sofa | S |
| Table | T |
| Desk | D |
| Storage | ST |
| Shelving | ST |
| Light | L |
| Acoustic | AC |
| Textile | TX |
| Rug | TX |
| Accessory | AX |
| Tabletop | AX |
| Mirror | AX |
| Kitchen | FX |
| Bath | FX |
| Window | FX |
| Door | FX |
| Bed | EQ |
| Planter | PL |
| Partition | PT |
| Outdoor Furniture | OT |
| Other | OT |

Numbered sequentially within each prefix: S-01, S-02, T-01, L-01, etc.

## Status Values

| Value | Meaning |
|-------|---------|
| `saved` | Default after any skill writes a row. |
| `specified` | Product is part of a formal FF&E schedule. |
| `quoted` | Dealer has returned pricing. |
| `archived` | No longer under consideration. |

## Source Values

| Value | Written by |
|-------|-----------|
| `research` | `/as:product-research` |
| `bulk-fetch` | `/as:product-spec-bulk-fetch` |
| `pdf-parser` | `/as:product-spec-pdf-parser` |
| `product-data-import` | `/as:product-data-import` |
| `product-match` | `/as:product-match` |
| `product-pair` | `/as:product-pair` |
| `product-enrich` | `/as:product-enrich` |
| `sif-to-csv` | `/as:sif-to-csv` |

## Notes Conventions

Column AE (Notes) holds skill-specific metadata. Each skill appends structured data using `|` as delimiter:

| Skill | Notes format |
|-------|-------------|
| `/as:product-research` | The "Why" reasoning for each candidate |
| `/as:product-data-import` | `Qty: 3 · Ext: $17,085` (quantity and extended price) |
| `/as:product-spec-pdf-parser` | `Variant: Diamond, Black \| Origin: Sweden \| Source: filename.pdf` |
| `/as:product-match` | Similarity reasoning |
| `/as:product-pair` | Design pairing reasoning |
| `/as:sif-to-csv` | `Sell: $1,200 · Ext List: $4,180 · Ext Sell: $3,600` (dealer pricing) |

## Tags Conventions

Column AD (Tags) holds comma-separated identifiers. Skills append to existing tags — never overwrite.

| Skill | Tags format |
|-------|------------|
| `/as:product-data-import` | Item number: `S-01` |
| `/as:product-match` | `match:{source-product-name}` |
| `/as:product-pair` | `pair:{source-product-name}` |
| `/as:product-enrich` | Style tags: `Mid-Century Modern, Iconic` |
| Any skill | Project tags from designer: `lobby-reno, walnut` |

## CSV Header

Use this exact header row for `product-library.csv`:

```csv
Category,Brand,Vendor,Thumbnail,Product Name,Designer,Indoor/Outdoor,Description,SKU,Link,Collection,W,D,H,Seat H,Unit,Weight,Materials,Colors/Finishes,Selected Color/Finish,List Price,Sale Price,Currency,Lead Time,Warranty,Certifications,COM/COL,Clipped At,Image URL,Tags,Notes,Status,Source
```

## Empty Cells

Use empty string `""` for fields with no value. Do not use `null`, `N/A`, `—`, or `-`.
