# NYC Zoning System Overview

## What is Zoning?

The NYC Zoning Resolution regulates land use, building size, and building placement on every lot in the five boroughs. Adopted in 1961, it replaced the 1916 resolution (the first comprehensive zoning law in the United States). The Resolution is maintained by the Department of City Planning (DCP) and amended by the City Council.

## District Types

NYC has three primary district types, each with numbered sub-districts that control density and use:

### Residential (R)
Districts R1 through R10. Lower numbers = lower density.

| Range | Character |
|-------|-----------|
| R1–R2 | Detached single-family homes |
| R3–R5 | Low-rise, one- and two-family, small apartments |
| R6–R7 | Medium-density apartments |
| R8–R10 | High-density towers and apartment buildings |

### Commercial (C)
Districts C1 through C8. Each permits a different range of uses and densities.

| Range | Character |
|-------|-----------|
| C1–C2 | Local retail and service (also used as overlays in R districts) |
| C3–C4 | General commercial, larger retail, offices |
| C5–C6 | Central commercial, high-density office and retail |
| C7 | Amusement (Coney Island) |
| C8 | Heavy commercial (auto, warehouse uses with commercial) |

### Manufacturing (M)
Districts M1 through M3.

| District | Character |
|----------|-----------|
| M1 | Light manufacturing, compatible with commercial |
| M2 | Medium manufacturing |
| M3 | Heavy manufacturing |

## Reading a Zoning District Code

District codes follow a pattern: **[Type][Number][-Suffix][Letter]**

Examples:
- `R6` — Residential 6, standard (height-factor or optional Quality Housing)
- `R7A` — Residential 7, contextual A (mandatory Quality Housing, lower height)
- `R7D` — Residential 7, contextual D (designed for narrow lots, taller and slimmer)
- `C6-2A` — Commercial 6-2, contextual A
- `M1-4` — Manufacturing 1, sub-group 4

### The Number
For residential: R1 (lowest density) through R10 (highest density). Higher numbers = higher FAR and taller buildings.

For commercial: C1 through C8, with sub-groups (C4-1 through C4-7, etc.) that set density equivalents.

For manufacturing: M1 (lightest) through M3 (heaviest).

### Contextual Suffixes (A, B, D, X)
These suffixes create **contextual districts** with mandatory height limits and streetwall requirements. They replaced the open-ended height-factor system in many neighborhoods.

| Suffix | Character |
|--------|-----------|
| A | Lower buildings, wider streetwall |
| B | Taller buildings, flexible streetwall (tower-on-base) |
| D | Narrow lot variant — taller/slimmer than A, for lots ≤45 ft wide |
| X | Hybrid — combines contextual base with some height-factor flexibility |

See `contextual-districts.md` for full rules.

## How Bulk is Controlled

NYC uses several overlapping mechanisms to control building size:

### Floor Area Ratio (FAR)
The primary density control. FAR = total floor area ÷ lot area.
- A 10,000 SF lot in an R7A district (FAR 4.0) allows up to 40,000 SF of floor area
- Different FARs apply for residential, commercial, and community facility uses
- Some districts have bonus FAR for inclusionary housing or public amenities

### Height and Setback
Two systems coexist:

**Height Factor (older, standard districts like R6, R7, R8 without suffix):**
- No absolute height limit
- Sky exposure plane controls: above a set height, the building must set back at a specified angle
- Taller = slimmer; FAR still limits total floor area

**Contextual (districts with A/B/D/X suffix):**
- Mandatory maximum building height
- Required base height range (streetwall)
- Required setback above base
- Quality Housing program mandatory

### Yards
- **Front yard:** Required in some districts (typically R1–R5), or 0 ft streetwall in contextual
- **Rear yard:** Almost always required, typically 30 ft for residential
- **Side yards:** Varies by district and lot type (corner, through, interior)

### Lot Coverage
Maximum percentage of the lot the building can cover. Primarily controls low-density districts. In medium/high-density contextual districts, lot coverage replaces the open space ratio.

### Open Space Ratio
In non-contextual R districts, open space ratio = required open space ÷ floor area. This effectively limits how much FAR can be used (you need enough open space to match your floor area).

## Commercial Overlays

C1 and C2 overlay districts are mapped within residential districts to allow local retail and service uses:

- **C1 overlays** (C1-1 through C1-5): Local shopping — retail, personal service, small restaurants
- **C2 overlays** (C2-1 through C2-5): Broader local service — adds funeral homes, repair shops, etc.

The overlay number (1–5) sets the commercial FAR (matching the underlying residential district's density tier). Commercial uses are typically limited to the ground floor and a depth of 150 ft from the street.

The overlay does NOT change the residential zoning — it adds commercial permissions on top.

## Special Purpose Districts

Over 60 special purpose districts modify or supplement the underlying zoning in specific areas. They address urban design, preservation, economic development, or infrastructure goals. Examples:

- Special Midtown District (MiD)
- Special Hudson Yards District (HY)
- Special Lower Manhattan District (LM)
- Special 125th Street District

Each has its own section of the Zoning Resolution with custom rules.

## Key References

- **Zoning Resolution:** Full text at [zr.planning.nyc.gov](https://zr.planning.nyc.gov)
- **ZoLa (Zoning & Land Use):** Interactive map at [zola.planning.nyc.gov](https://zola.planning.nyc.gov)
- **PLUTO:** Lot-level data via NYC Open Data
- **Zoning Handbook:** Plain-language guide published by DCP
