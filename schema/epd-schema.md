# Environmental Product Declaration Schema

Version 2.0 · 42 columns (A–AP)

EPD parsing remains PDF-first and does not require persistence. When the user explicitly saves a reusable collection, use the project-local `epd-library.csv` and the rules in [csv-conventions.md](csv-conventions.md). This schema is distinct from the 33-column FF&E schema.

## Column Reference

| Columns | Fields |
|---|---|
| A–H · Product identity | EPD Link; Manufacturer; Product Name; Description; Declared Unit; Functional Unit; CSI Division; Material Category |
| I–P · EPD metadata | EPD Registration No.; Program Operator; PCR Reference; PCR Expiry; Standard; System Boundary; Valid From; Valid To |
| Q–V · Product stage | GWP-total (A1-A3); GWP-fossil (A1-A3); GWP-biogenic (A1-A3); ODP (A1-A3); AP (A1-A3); EP (A1-A3) |
| W–AB · Other stages | GWP (A4-A5); GWP (B1-B7); GWP (C1-C4); GWP (D); GWP-total (all stages); POCP (A1-A3) |
| AC–AH · Resource use | PERE (A1-A3); PENRE (A1-A3); Total Energy (A1-A3); FW (A1-A3); Recycled Content; Waste (A1-A3) |
| AI–AP · Tracking | LEED Eligible; EC3 ID; Plant/Facility; Country; Parsed At; Tags; Notes; Source |

`EPD Link` is a plain URL. Dates use `YYYY-MM-DD`; `Parsed At` uses ISO 8601. Leave unavailable fields empty rather than guessing. Numeric environmental values must retain the declared unit context in the corresponding unit fields or notes.

## CSV Header

Use this exact header row for `epd-library.csv`:

```csv
EPD Link,Manufacturer,Product Name,Description,Declared Unit,Functional Unit,CSI Division,Material Category,EPD Registration No.,Program Operator,PCR Reference,PCR Expiry,Standard,System Boundary,Valid From,Valid To,GWP-total (A1-A3),GWP-fossil (A1-A3),GWP-biogenic (A1-A3),ODP (A1-A3),AP (A1-A3),EP (A1-A3),GWP (A4-A5),GWP (B1-B7),GWP (C1-C4),GWP (D),GWP-total (all stages),POCP (A1-A3),PERE (A1-A3),PENRE (A1-A3),Total Energy (A1-A3),FW (A1-A3),Recycled Content,Waste (A1-A3),LEED Eligible,EC3 ID,Plant/Facility,Country,Parsed At,Tags,Notes,Source
```

## Controlled values

- `LEED Eligible`: `Yes`, `No`, or `Partial`.
- `Source`: the skill that produced the row, such as `epd-parser` or `epd-research`.
- `Material Category`: Concrete, Steel, Aluminum, Wood/Timber, Insulation, Gypsum, Glass, Ceramic/Tile, Carpet, Resilient Flooring, Roofing Membrane, Sealant, Paint/Coating, Masonry, Stone, Composite Panel, Acoustic, Cladding, Rebar, Cement, Aggregate, Furniture, or Other.
