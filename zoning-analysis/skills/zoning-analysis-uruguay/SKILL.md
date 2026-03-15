---
name: zoning-analyzer
description: Analyze zoning envelope rules for lots in Maldonado, Uruguay using GIS data and TONE regulations
allowed-tools:
  - Read
  - Write
  - Edit
  - WebFetch
  - AskUserQuestion
  - Bash
  - Glob
  - Grep
user-invocable: true
---

# /zoning-analyzer — Zoning Envelope Analysis (Maldonado, Uruguay)

Analyze building envelope rules for any lot in Maldonado using GIS data from the ArcGIS cadastral portal and the TONE (Volume V of the Digesto Departamental).

## Workflow

### Step 1: Parse GIS Input

Accept pasted JSON from the Maldonado ArcGIS cadastral portal. Extract key attributes:
- `nomloccat` — locality name (e.g., "LA BARRA")
- `padron` — lot number
- `nummancat` — block (manzana) number
- `valaream2` — lot area in m²
- `tiporegime` — property regime (PC = Propiedad Común, PH = Propiedad Horizontal)
- `geometry.rings` — polygon coordinates in Web Mercator (EPSG:3857)

### Step 2: Convert Coordinates

Use the geometry rings to calculate approximate lot dimensions:
1. Rings are in Web Mercator (EPSG:3857) — units are meters but distorted by projection
2. For x-axis (east-west): multiply distances by `cos(latitude)` where latitude ≈ -34.8° → cos factor ≈ 0.821
3. For y-axis (north-south): distances are approximately correct
4. Convert first ring to pairs, calculate edge lengths, estimate front × depth
5. Verify calculated area against `valaream2`

To convert EPSG:3857 to lat/lon for reference:
- `lon = x / 20037508.34 × 180`
- `lat = (atan(exp(y / 20037508.34 × π)) × 360 / π) - 90`

### Step 3: Look Up Location

Read `~/.claude/skills/zoning-analyzer/normativa/location-map.md` to match `nomloccat` to a TONE sector/region.

If no match is found, search the digesto website at `https://digesto.maldonado.gub.uy/` for the location.

### Step 4: Load Normativa

Read the corresponding normativa file from `~/.claude/skills/zoning-analyzer/normativa/`.

If the file doesn't exist yet:
1. Fetch the relevant articles from the digesto using WebFetch
2. The section index pages are at `https://digesto.maldonado.gub.uy/index.php/armado-seccion/{id}`
3. Individual articles are at `https://digesto.maldonado.gub.uy/index.php/detalle-articulo/{id}`
4. Present the raw content to the user
5. Offer to save it as a new normativa reference file for future use

### Step 5: Determine Zone/Subzone

Based on the lot's attributes, determine the applicable zone:
- Use `nomloccat` and `nummancat` (block number) to match zone boundary descriptions
- Check position relative to Ruta 10, coastline, and named streets
- If the zone is ambiguous, present the possible options via AskUserQuestion
- State your reasoning for the zone determination

### Step 6: Calculate Building Envelope

Apply the normativa rules to the specific lot:

1. **Permitted building types**: Check lot area against minimum lot requirements for each type
2. **Maximum height and floors**: Based on building type and lot area
3. **Setbacks**: Front, lateral, rear — accounting for:
   - Ruta 10 frontage (larger setbacks)
   - Small-lot provisions (frente ≤ 15m)
   - Auxiliary construction allowances in setbacks
4. **Occupation factors**: FOS, FOS SS, FOS V, FOT
   - Interpolate by lot area when between defined ranges
   - Calculate actual m² from percentages
5. **Buildable footprint**: Lot area minus setback areas
6. **Maximum built area**: FOT × lot area
7. **Special conditions**: Galibo (last floor setback), overhangs, piloti requirements

### Step 7: Present Analysis

Use the output format below to present a structured analysis.

### Step 8: Save Normativa (if fetched)

If new articles were fetched from the digesto during this analysis:
1. Ask the user if they want to save them as a local normativa reference file
2. If yes, write to `~/.claude/skills/zoning-analyzer/normativa/` with a descriptive filename
3. Update `location-map.md` with the new mapping

## Output Format

```markdown
# Zoning Envelope Analysis — Padrón [number], [location]

## Lot Data
| Parameter | Value |
|-----------|-------|
| Padrón | ... |
| Manzana | ... |
| Location | ... |
| Area | ... m² |
| Regime | ... |
| Approx. dimensions | ... m × ... m |
| Coordinates | lat, lon |

## Applicable Zone
**[Zone name] → [Subzone name]**
Reasoning for zone determination.

## Permitted Building Types
Which types are viable given this lot's area, with minimum area requirements listed.

## Building Envelope

### Height
| Parameter | Value |
|-----------|-------|
| Max height | ... m |
| Floors | ... |
| Notes | ... |

### Occupation Factors
| Factor | % | m² |
|--------|---|-----|
| FOS SS | ... | ... |
| FOS | ... | ... |
| FOS V | ... | ... |
| FOT | ... | ... |

(Interpolated by lot area if between defined ranges)

### Setbacks
| Direction | Distance | Notes |
|-----------|----------|-------|
| Front | ... m | ... |
| Lateral 1 | ... m | ... |
| Lateral 2 | ... m | ... |
| Rear | ... m | ... |

### Auxiliary Constructions in Setbacks
What can be built in setbacks, with limits (area, height).

### Overhangs (Salientes)
Projection allowances over setbacks.

## Buildable Envelope Sketch
ASCII diagram showing the lot with setbacks and buildable zone, oriented with front at bottom.

## Key Constraints
- Bullet list of the most important limiting factors
- Compliance issues (undersized lot, etc.)
- Special conditions that apply
```

## Notes

- The TONE is Volume V of the Digesto Departamental de Maldonado
- Normativa files are organized by Título/Capítulo/Sector following the digesto structure
- Zone-specific rules override general sector rules
- When in doubt about zone boundaries, always ask the user — zone determination is the most critical step
- Occupation factors between defined area ranges should be linearly interpolated
