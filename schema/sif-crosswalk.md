# SIF ↔ Product Schema Crosswalk

Maps between the 33-column product schema and SIF (Standard Interchange Format) field codes. Used by `/as:csv-to-sif` and `/as:sif-to-csv`.

## Column-to-SIF Mapping

| Col | Schema Field | SIF Code | Direction | Notes |
|-----|-------------|----------|-----------|-------|
| A | Category | `GC` | ↔ | Also `PRC` in Cyncly |
| B | Brand | `MC` + `MN` | ↔ | MC = 3-5 char code, MN = full name. Also `MG` (Cyncly), `EC` (CET) |
| C | Vendor | `G0` | → | Vendor/group identifier |
| E | Product Name | `PD` | ↔ | |
| I | SKU | `PN` | ↔ | Required. Starts a new SIF record |
| J | Link | `ProductURL` | ↔ | |
| K | Collection | — | — | No SIF equivalent |
| L–P | W, D, H, Seat H, Unit | `AN`=`DIM` + `AD` | ↔ | Combined as `AD=32.75W x 32.5D x 33.5H in`. Parse back into separate cols on import |
| Q | Weight | `WT` | ↔ | |
| R | Materials | `AN`=`MAT` + `AD` | → | Encoded as attribute pair |
| S | Colors/Finishes | `OD` (with `ON`=`FIN`) | → | All available finishes |
| T | Selected Color/Finish | `OD` | ↔ | If present, replaces S as the primary option description |
| U | List Price | `PL` | ↔ | Also `P1` or `I1` depending on system |
| V | Sale Price | — | ← | Calculated: `PL - (PL × S- × 0.01)`. Not a native SIF field |
| W | Currency | — | — | SIF assumes USD. No currency field |
| X | Lead Time | — | — | No SIF equivalent |
| Y | Warranty | — | — | No SIF equivalent |
| Z | Certifications | — | — | No SIF equivalent |
| AA | COM/COL | — | — | No SIF equivalent |
| AC | Image URL | `ImageURL` | ↔ | |
| AD | Tags | `TG` | ↔ | Side mark / room tag |
| AE | Notes | — | ← | Skill writes: "From SIF: {ST}. Discount: {S-}%. Qty: {QT} · Ext: ${ext_sell}" |
| AF | Status | — | ← | Set to `quoted` on import |
| AG | Source | — | ← | Set to `sif-to-csv` on import, `csv-to-sif` on export |

**Direction key:** `→` = schema to SIF (export) · `←` = SIF to schema (import) · `↔` = both

## Fields in SIF Without a Schema Column

These SIF fields are used during conversion but don't map to a single schema column:

| SIF Code | Name | Handling |
|----------|------|----------|
| `SF` | Specification File | File header — project reference |
| `ST` | Specification Title | File header — display title |
| `QT` / `NT` | Quantity | Not in schema. Required for SIF export — skill must ask user or pull from Notes |
| `S-` / `S%` | Sell Discount % | Used to calculate Sale Price on import |
| `P%` / `B%` | Purchase/Buy % | Used to calculate net cost on import |
| `I2` | Purchase Price (Cyncly) | Maps to cost, not in schema |
| `P2`–`P5` | Price Tiers | Alternate pricing tiers, not in schema |
| `VO` | Volume | Not in schema |
| `PV` | Picture Path | Local file path, not used |
| `ON` | Option Number | Paired with OD |
| `AN` | Attribute Number | Paired with AD |

## Manufacturer Code Lookup

| MC | Brand | MC | Brand |
|----|-------|----|-------|
| HMI | Herman Miller | BLU | Blu Dot |
| MKN | MillerKnoll | DWR | Design Within Reach |
| KNL | Knoll | FRH | Fritz Hansen |
| STC | Steelcase | VIT | Vitra |
| HAW | Haworth | ARP | Arper |
| TEK | Teknion | MUU | Muuto |
| HUM | Humanscale | HAY | HAY |
| KIM | Kimball | FLS | Flos |
| NAT | National | LPO | Louis Poulsen |
| OFS | OFS | ART | Artemide |
| HBF | HBF | RHB | Restoration Hardware |
| GEI | Geiger | WEL | West Elm |
| BRN | Bernhardt | CB2 | CB2 |

For unknown brands, use first 3-5 characters uppercased. Flag for user to verify.
