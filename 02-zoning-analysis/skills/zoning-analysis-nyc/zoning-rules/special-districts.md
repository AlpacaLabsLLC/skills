# Special Purpose Districts

NYC has over 60 special purpose districts that modify or supplement the underlying zoning. Each has its own section in the Zoning Resolution with custom rules for bulk, use, urban design, or infrastructure.

This file covers the most commonly encountered special districts. For lots in a special district, always note that additional rules apply and recommend the user consult the specific ZR section.

## How Special Districts Work

1. **Layered on top of underlying zoning** — the base R/C/M district still applies unless explicitly overridden
2. **Identified in PLUTO** via `spdist1`, `spdist2`, `spdist3` fields
3. **Each has a ZR Article** — Article IX (Special Purpose Districts) or individual articles
4. **May modify:** FAR, height, setbacks, use, streetwall, signage, parking, public space requirements

## Key Special Districts

### Special Midtown District (MiD)
**ZR Article VIII, Chapter 1**
- **Location:** Midtown Manhattan (roughly 31st–61st Streets, 3rd–8th Avenues)
- **Purpose:** Control tower form, protect light/air to streets, encourage pedestrian circulation
- **Key rules:**
  - Daylight evaluation system for towers (daylight score required)
  - Mandatory setbacks at specified heights based on street frontage
  - Bonus FAR for public plazas, subway improvements, theater preservation
  - Signage controls (bright-light signage required in Times Square subdistrict)
  - Maximum FAR: 15.0–18.0 depending on subdistrict and bonuses
- **Subdistricts:** Theater, Penn Center, East Midtown, Fifth Avenue, Preservation

### Special Hudson Yards District (HY)
**ZR Article IX, Chapter 3**
- **Location:** West Midtown (roughly 28th–43rd Streets, 7th Avenue to Hudson River)
- **Purpose:** Transform former rail yards into mixed-use district, extend Midtown west
- **Key rules:**
  - Maximum FAR: 10.0–33.0 depending on subdistrict
  - Inclusionary housing requirements
  - District Improvement Bonus (DIB) for infrastructure funding
  - Tower form rules (max coverage, setbacks)
  - Active ground-floor use requirements
  - Waterfront access plan requirements along Hudson

### Special Lower Manhattan District (LM)
**ZR Article IX, Chapter 1**
- **Location:** Below Chambers Street
- **Purpose:** Promote mixed-use development, residential conversion of commercial buildings
- **Key rules:**
  - Residential FAR bonuses for conversion of office buildings
  - Flexible ground-floor use provisions
  - Modified height and setback rules from underlying C5/C6 districts
  - Fresh food store bonus

### Special Clinton District (CL)
**ZR Article IX, Chapter 6**
- **Location:** Hell's Kitchen (roughly 41st–59th Streets, 8th Avenue to Hudson River)
- **Purpose:** Preserve neighborhood character, prevent displacement
- **Key rules:**
  - Perimeter Area: modified bulk, anti-harassment provisions
  - Preservation Area: strict limits on demolition and new construction
  - Maximum FAR varies by subdistrict (4.0–10.0)

### Special West Chelsea District (WCh)
**ZR Article IX, Chapter 8**
- **Location:** West Chelsea (roughly 14th–30th Streets, 10th–11th Avenues)
- **Purpose:** Support High Line, promote arts, allow high-density development
- **Key rules:**
  - High Line Transfer Corridor (development rights transfer)
  - Maximum FAR: up to 7.5 with bonuses
  - Inclusionary housing required for bonus FAR
  - Ground-floor use requirements along High Line

### Special 125th Street District
**ZR Article IX, Chapter 7**
- **Location:** 125th Street corridor in Harlem
- **Purpose:** Promote mixed-use, arts, and commercial development
- **Key rules:**
  - Modified FAR and height along 125th Street
  - Arts bonus (additional FAR for visual/performing arts space)
  - Required ground-floor retail continuity

### Special Willets Point District
**ZR Article IX, Chapter 9**
- **Location:** Willets Point, Queens (adjacent to Citi Field)
- **Purpose:** Facilitate redevelopment of industrial area
- **Key rules:**
  - Large-scale development plan requirements
  - Affordable housing mandates
  - Phased development schedule

### Special Downtown Brooklyn District (DB)
**ZR Article X, Chapter 1**
- **Location:** Downtown Brooklyn core
- **Purpose:** Strengthen Brooklyn's central business district
- **Key rules:**
  - Maximum FAR: up to 12.0 with bonus
  - Bonus FAR for affordable housing, public parking
  - Modified height and setback from underlying C6 districts

### Special Long Island City Mixed Use District (LIC)
**ZR Article XII, Chapter 3**
- **Location:** Long Island City, Queens (Court Square area)
- **Purpose:** Promote mixed-use development, maintain industrial uses
- **Key rules:**
  - Subdistricts with varying FAR (4.8–11.0)
  - Industrial retention requirements in some subdistricts
  - Height controls along Queens waterfront

### Special Bay Ridge District (BR)
**ZR Article XI, Chapter 3**
- **Location:** Bay Ridge, Brooklyn (4th Avenue corridor)
- **Purpose:** Contextual zoning along 4th Avenue, protect side streets
- **Key rules:**
  - Higher density on 4th Avenue, lower on side streets
  - Mandatory base heights and setbacks
  - Ground-floor commercial on 4th Avenue

## Special District Codes in PLUTO

Common `spdist` codes:

| Code | Special District |
|------|-----------------|
| MiD | Midtown |
| HY | Hudson Yards |
| LM | Lower Manhattan |
| CL | Clinton |
| WCh | West Chelsea |
| 125 | 125th Street |
| DB | Downtown Brooklyn |
| LIC | Long Island City |
| BR | Bay Ridge |
| EC | East Harlem Corridors |
| GC | Garment Center |
| TA | Transit Land Use (various) |
| TMU | Tribeca Mixed Use |
| SHP | Southern Hunters Point |
| HP | Hudson Park |

## How to Handle Special Districts in Analysis

1. **Note the special district** in the Zoning Classification section
2. **State the underlying zoning** and its base controls
3. **Flag key modifications** — especially FAR changes, height overrides, and use restrictions
4. **Add a caveat** that special district rules are complex and may require detailed review of the specific ZR article
5. **Recommend ZoLa** for visual confirmation of district boundaries and subdistricts
6. **Do NOT attempt** to calculate precise bulk for highly complex special districts (Midtown daylight evaluation, Hudson Yards phased development) — instead, present the range and note that specialized analysis is needed
