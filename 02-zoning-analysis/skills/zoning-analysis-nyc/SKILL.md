---
name: zoning-analysis-nyc
description: Analyze zoning envelope rules for lots in New York City using PLUTO data and the NYC Zoning Resolution
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

# /zoning-analysis-nyc — Zoning Envelope Analysis (New York City)

Analyze building envelope rules for any lot in New York City using the PLUTO database (NYC Open Data) and the NYC Zoning Resolution.

## Workflow

### Step 1: Parse Input

Accept one of the following identifiers:
- **Address + Borough/Zip** — e.g., "123 Main St, Brooklyn 11201"
- **BBL** — 10-digit Borough-Block-Lot (e.g., 3012340056 = Brooklyn, Block 1234, Lot 56)
- **BIN** — Building Identification Number

Normalize to BBL format: `[borough 1 digit][block 5 digits][lot 4 digits]`

Borough codes:
| Code | Borough |
|------|---------|
| 1 | Manhattan |
| 2 | Bronx |
| 3 | Brooklyn |
| 4 | Queens |
| 5 | Staten Island |

### Step 2: Query PLUTO

Fetch lot data from the NYC PLUTO dataset via the Socrata Open Data API.

**Endpoint:** `https://data.cityofnewyork.us/resource/64uk-42ks.json`

**Query by BBL:**
```
https://data.cityofnewyork.us/resource/64uk-42ks.json?bbl=XXXXXXXXXX
```

**Query by address (fallback):**
```
https://data.cityofnewyork.us/resource/64uk-42ks.json?$where=address='123 MAIN STREET' AND zipcode='10001'
```

No authentication required for basic queries.

Read `zoning-rules/pluto-fields.md` for the full field reference.

**Extract these key fields:**
- `bbl` — Borough-Block-Lot
- `address`, `zipcode` — street address
- `zonedist1` through `zonedist4` — zoning district(s)
- `overlay1`, `overlay2` — commercial overlay districts
- `spdist1`, `spdist2`, `spdist3` — special purpose districts
- `ltdheight` — limited height district
- `splitzone` — Y if lot is split across zones
- `lotarea` — lot area in SF
- `bldgarea` — total building area in SF
- `builtfar` — as-built FAR
- `residfar` — maximum residential FAR
- `commfar` — maximum commercial FAR
- `facilfar` — maximum community facility FAR
- `numfloors` — existing number of floors
- `landuse` — current land use category
- `zonemap` — zoning map number
- `landmark` — landmark designation
- `histdist` — historic district name
- `borocode`, `block`, `lot` — parsed BBL components

If the query returns no results, inform the user and ask them to verify the address or BBL.

### Step 3: Identify Zoning District

Map the `zonedist1` value to its district type:

| Prefix | Type | Normativa File |
|--------|------|----------------|
| R | Residential | `zoning-rules/residential.md` |
| C | Commercial | `zoning-rules/commercial.md` |
| M | Manufacturing | `zoning-rules/manufacturing.md` |

Check for:
- **Split zones** (`splitzone = Y`): Analyze each `zonedist1`–`zonedist4` separately. Pro-rate FAR by estimated area in each zone if lot dimensions are available, otherwise present both sets of controls.
- **Contextual suffixes** (A, B, D, X): If the district code ends in a letter suffix (e.g., R7A, C6-2A), also load `zoning-rules/contextual-districts.md`.
- **Commercial overlays** (`overlay1`/`overlay2`): If present (e.g., C1-4, C2-5), load `zoning-rules/commercial.md` for overlay rules.
- **Special districts** (`spdist1`–`spdist3`): If present, load `zoning-rules/special-districts.md`.
- **Limited height** (`ltdheight`): Note the height cap.

State your district identification and reasoning clearly.

### Step 4: Load Normativa

Read the relevant regulation files from the skill's `zoning-rules/` directory:

1. **Always read:** `zoning-rules/overview.md` — system primer
2. **Primary district file:** One of `residential.md`, `commercial.md`, or `manufacturing.md`
3. **Conditionally read:**
   - `zoning-rules/contextual-districts.md` — if district has A/B/D/X suffix
   - `zoning-rules/special-districts.md` — if `spdist1`–`spdist3` are populated
   - `zoning-rules/use-groups.md` — for permitted use analysis
   - `zoning-rules/parking.md` — for parking requirements
   - `zoning-rules/city-of-yes.md` — for recent reform impacts

### Step 5: Determine Bulk Controls

Calculate the building envelope for the lot:

1. **Floor Area Ratio (FAR):**
   - Residential FAR (from `residfar` or district table)
   - Commercial FAR (from `commfar` or district table)
   - Community Facility FAR (from `facilfar` or district table)
   - Maximum zoning floor area = FAR × lot area

2. **Building Height:**
   - Base height range (contextual districts)
   - Maximum building height
   - Sky exposure plane angle and setback distance
   - Limited height district cap (if applicable)

3. **Setbacks:**
   - Front: initial setback distance and sky exposure plane
   - Side: narrow/wide street rules
   - Rear: standard 30 ft for residential, varies for commercial
   - Sky exposure plane: ratio and starting height

4. **Lot Coverage:**
   - Maximum lot coverage percentage
   - Open space ratio (for non-contextual R districts)

5. **Yards:**
   - Front yard requirements
   - Side yard requirements (corner lots, through lots)
   - Rear yard: typically 30 ft or 20% of lot depth

Apply contextual district rules when suffix is present — these override standard height/setback rules with mandatory streetwall, base height, and setback requirements.

### Step 6: Check Overlays & Special Districts

Layer additional regulations on top of base district controls:

1. **Commercial overlays** (C1-1 through C2-5 in residential districts):
   - Additional commercial FAR (typically 1.0 or 2.0)
   - Commercial use depth limit (typically 150 ft from street)
   - Permitted commercial uses (Use Groups 5–9 for C1, 5–14 for C2)

2. **Special purpose districts:**
   - Modified bulk controls, use restrictions, design requirements
   - Check `zoning-rules/special-districts.md` for the specific district

3. **Inclusionary Housing:**
   - Bonus FAR available in designated areas
   - Mandatory Inclusionary Housing (MIH) areas: must provide affordable units for bonus

4. **Landmark / Historic District:**
   - If `landmark` or `histdist` is populated, note that Landmarks Preservation Commission (LPC) review is required
   - Bulk controls still apply but modifications may need LPC approval

5. **City of Yes reforms:**
   - Check `zoning-rules/city-of-yes.md` for applicable changes
   - Universal Affordability Preference (UAP): +20% FAR for affordable housing
   - Town Center Zoning: ground-floor commercial in residential districts near transit
   - Parking: most mandates eliminated citywide

### Step 7: Present Analysis

Use the output format below to present a structured, comprehensive analysis.

### Step 8: Save Report

Write the analysis to a markdown file in the current working directory:
- Filename: `zoning-analysis-[address-slug].md`
- Example: `zoning-analysis-123-main-st-brooklyn.md`

## Output Format

```markdown
# Zoning Analysis — [Address], [Borough]

## Lot Summary
| Parameter | Value |
|-----------|-------|
| BBL | X-XXXXX-XXXX |
| Address | ... |
| Borough | ... |
| Lot Area | ... SF |
| Current Building Area | ... SF |
| Current FAR (built) | ... |
| Current Use | ... |
| Zoning Map | ... |

## Zoning Classification
| Parameter | Value |
|-----------|-------|
| Primary District | ... |
| Secondary District(s) | ... (or None) |
| Commercial Overlay | ... (or None) |
| Special District | ... (or None) |
| Limited Height | ... (or None) |
| Contextual | Yes/No |
| Split Zone | Yes/No |
| Landmark | ... (or None) |
| Historic District | ... (or None) |

## Bulk Parameters

### Floor Area
| Use | Max FAR | Max Floor Area (SF) |
|-----|---------|---------------------|
| Residential | ... | ... |
| Commercial | ... | ... |
| Community Facility | ... | ... |

### Height & Setback
| Parameter | Value |
|-----------|-------|
| Max Building Height | ... ft |
| Base Height (min–max) | ... ft (contextual only) |
| Sky Exposure Plane | starts at ... ft, ratio .../1 |
| Street Wall | required/not required |

### Yards & Coverage
| Parameter | Value |
|-----------|-------|
| Front Yard | ... ft |
| Rear Yard | ... ft |
| Side Yards | ... |
| Max Lot Coverage | ...% |
| Open Space Ratio | ... (if applicable) |

## Permitted Uses
Key permitted uses by Use Group for this district. Highlight the most relevant:
- Residential: ...
- Commercial: ...
- Community Facility: ...
- Manufacturing: ... (if applicable)

## Parking Requirements
Based on current rules (post-City of Yes where applicable):
| Use | Requirement |
|-----|-------------|
| Residential | ... |
| Commercial | ... |
| Other | ... |

## Bonuses & Incentives
- Inclusionary Housing bonus: ...
- UAP (City of Yes): ...
- Other applicable bonuses: ...

## Restrictions & Special Conditions
- Landmark/LPC review: ...
- Special district requirements: ...
- Environmental: ...
- Other: ...

## Development Potential
| Scenario | FAR | Floor Area (SF) | Est. Floors |
|----------|-----|------------------|-------------|
| As-of-right residential | ... | ... | ... |
| As-of-right commercial | ... | ... | ... |
| With IH bonus | ... | ... | ... |
| With UAP bonus | ... | ... | ... |

## Caveats
- This analysis is based on publicly available zoning data (PLUTO) and general Zoning Resolution rules
- Always verify with NYC Department of City Planning and ZoLa (zola.planning.nyc.gov)
- Special permits, variances, and BSA actions are not reflected in PLUTO data
- City of Yes provisions are being phased in — confirm effective dates for specific provisions
- Site-specific conditions (flood zones, coastal erosion, environmental restrictions) require additional review
- This is not a substitute for professional zoning analysis or legal advice
```

## Notes

- The NYC Zoning Resolution is maintained by the Department of City Planning
- PLUTO data is updated quarterly — verify currency for critical decisions
- Contextual districts (with letter suffixes) have mandatory streetwall and height rules that override standard bulk controls
- City of Yes for Housing Opportunity was adopted December 2024 — some provisions phase in over time
- When in doubt about district classification or applicable rules, always ask the user
- For split-zone lots, analyze each zone separately and note the complexity
- ZoLa (zola.planning.nyc.gov) is the authoritative visual reference — recommend users verify there
