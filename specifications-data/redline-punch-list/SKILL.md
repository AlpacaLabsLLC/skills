---
description: Construction punch list generator — turns field notes and photos into structured punch lists with CSI divisions, trade assignments, priority levels, and exportable reports.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
---

# /redline-punch-list — Construction Punch List Generator

Takes field observations — raw notes, photos, walkthrough descriptions — and produces a structured punch list with CSI division mapping, trade assignments, priority levels, and summary statistics. Output is a `.md` file with optional `.csv` export.

## Input

The user provides punch list observations in one of these ways:

1. **Pasted field notes** — raw text, bullet points, stream-of-consciousness notes from a site walk
2. **Photo files** — image paths that Claude can read and analyze visually. Describe what is visible, identify deficiencies, and flag issues
3. **File path** — path to an existing notes file (.md, .txt, .csv) containing observations
4. **Guided walkthrough** — the user says something like "I'm doing a punch walk on a 10,000 SF office TI" and provides items one at a time or in batches

If the user invokes the skill without input, start the guided walkthrough:

1. **What is the project?** (name, type, approximate SF)
2. **What phase are you in?** (substantial completion, final, warranty, pre-occupancy)
3. **Ready to start — paste your notes, drop photos, or describe items one at a time.**

## Item Schema

For each punch list item, capture the following fields:

| Field | Description |
|-------|-------------|
| **#** | Sequential item number (auto-assigned) |
| **Location** | Room name, number, or area (e.g., "Room 201", "Main Lobby", "Corridor 2A", "Roof") |
| **CSI Division** | MasterFormat division mapped from the deficiency type (see division reference below) |
| **Trade** | Responsible trade: GC, Electrical, Mechanical, Plumbing, Fire Protection, Finishes, Ceilings, Flooring, Millwork, Glazing, Doors/Hardware, Drywall, Painting, Roofing, Concrete, Steel, Landscape, Controls, Low Voltage, or other |
| **Description** | Clear, specific, actionable description. Always include the deficiency, its precise location within the space, and approximate size or extent when visible. Good: "Paint touch-up needed at NE corner of Room 201, 2'x3' area above door frame — scuff marks and drywall mud visible." Bad: "Paint issue." |
| **Priority** | **Critical** (safety hazard, code violation, prevents occupancy), **Major** (functional deficiency, system not operating correctly), **Minor** (cosmetic, fit-and-finish) |
| **Status** | Open / In Progress / Complete (default: Open) |
| **Photo** | File reference if an image was provided, otherwise "—" |
| **Notes** | Additional context, cross-references, or follow-up actions |

## CSI Division Reference

Map each deficiency to the appropriate MasterFormat division:

| Division | Title | Common Punch Items |
|----------|-------|--------------------|
| 03 | Concrete | Cracks, spalls, uneven slabs, honeycombing, popouts |
| 04 | Masonry | Mortar joints, efflorescence, cracked units, sealant failures |
| 05 | Metals | Loose handrails, scratched steel, missing bollards, weld touch-ups |
| 06 | Wood, Plastics, Composites | Millwork gaps, scratched casework, warped panels, trim issues |
| 07 | Thermal & Moisture Protection | Roof issues, flashing, sealant gaps, waterproofing, insulation |
| 08 | Openings | Door alignment, hardware issues, glazing scratches, frame damage, ADA clearances |
| 09 | Finishes | Paint, drywall, tile, flooring, ceiling tiles, wall coverings, base |
| 10 | Specialties | Signage, toilet accessories, fire extinguisher cabinets, corner guards |
| 11 | Equipment | Appliances, specialty equipment deficiencies |
| 12 | Furnishings | Window treatments, countertops, casework (if furnishing scope) |
| 21 | Fire Suppression | Sprinkler head alignment, escutcheon rings, head coverage |
| 22 | Plumbing | Fixture operation, leaks, trim plates, valve labels |
| 23 | HVAC | Diffuser alignment, thermostat operation, duct leaks, grille damage, balancing |
| 25 | Integrated Automation | BAS/controls issues, sensor calibration |
| 26 | Electrical | Cover plates, fixture alignment, switching, labeling, exit signs |
| 27 | Communications | Data outlet plates, cable management, AV rough-ins |
| 28 | Electronic Safety & Security | Access control, cameras, fire alarm devices |
| 31 | Earthwork | Grading, settlement, erosion |
| 32 | Exterior Improvements | Pavement, curbs, site concrete, landscaping |
| 33 | Utilities | Site drainage, utility connections |

## Smart Categorization

When processing items, apply these rules:

### Infer fields from context

- "Ceiling tile is stained near the diffuser in the conference room" → **Location**: Conference Room, **CSI Div**: 09 Finishes, **Trade**: Ceilings, **Priority**: Minor
  - Also add a **Note**: "Check with mechanical — stain near diffuser may indicate condensation or leak above. Verify no active drip before closing as cosmetic only."
- "Exit sign is out in stairwell B" → **CSI Div**: 26 Electrical, **Trade**: Electrical, **Priority**: Critical (life safety)
- "Door 204 won't latch" → **CSI Div**: 08 Openings, **Trade**: Doors/Hardware, **Priority**: Major (security/function)

### Cross-reference related items

- If multiple paint items exist across rooms, group them in the output and add a note: "Consider issuing a single paint touch-up directive to painting contractor covering items #X, #Y, #Z."
- If multiple items affect the same room, flag for coordinated access: "Room 301 has [N] open items across [N] trades — coordinate access."

### Flag code and safety issues

Automatically escalate to **Critical** priority and add a note when any of these are detected:

- Missing or non-functional exit signs or emergency lighting
- Blocked egress paths (doors, corridors, stairwells)
- Missing fire extinguishers or blocked cabinets
- ADA clearance violations (door maneuvering clearances, fixture reach ranges, grab bar issues)
- Missing or damaged fire-rated assemblies (labeled doors, firestopping)
- Tripping hazards (threshold transitions, uneven surfaces, missing nosings)
- Missing handrails or guards
- Exposed electrical wiring or open junction boxes

When flagging, include the relevant code reference where applicable (IBC, ADA/ABA, NFPA 101, local amendments).

### Handle photos

When the user provides an image file path:

1. Read and analyze the image
2. Describe what is visible — materials, conditions, deficiencies
3. Create one or more punch list items from the photo
4. Reference the photo filename in the **Photo** field
5. If the location is not obvious from the image, ask the user

## Output

### Default: Structured Markdown

Write the punch list to `~/Documents/punch-list-[project-slug].md`.

- Derive `[project-slug]` from the project name (lowercase, hyphenated)
- If no project name is given, use `punch-list-draft.md`
- Ask the user if they want a different path

**File structure:**

```markdown
# Punch List — [Project Name]

Generated: [date]
Project: [name]
Phase: [phase]
Total Items: [count]

## Summary

### By Priority

| Priority | Count | % |
|----------|-------|---|
| Critical | X | X% |
| Major | X | X% |
| Minor | X | X% |
| **Total** | **X** | **100%** |

### By Trade

| Trade | Open | In Progress | Complete | Total |
|-------|------|-------------|----------|-------|
| Painting | X | X | X | X |
| Electrical | X | X | X | X |
| ... | | | | |
| **Total** | **X** | **X** | **X** | **X** |

### Completion

- Open: X items
- In Progress: X items
- Complete: X items
- **Completion: X%**

---

## Critical Items

| # | Location | Trade | Description | Status |
|---|----------|-------|-------------|--------|
| 1 | Stairwell B | Electrical | Exit sign non-functional — life safety, replace immediately | Open |

---

## All Items

### Room 201

| # | CSI Div | Trade | Description | Priority | Status | Photo | Notes |
|---|---------|-------|-------------|----------|--------|-------|-------|
| 3 | 09 | Painting | Paint touch-up needed at NE corner, 2'x3' area above door frame — scuff marks and drywall mud visible | Minor | Open | — | — |
| 4 | 08 | Doors/Hardware | Door does not latch — striker plate misaligned | Major | Open | — | — |

### Conference Room

| # | CSI Div | Trade | Description | Priority | Status | Photo | Notes |
|---|---------|-------|-------------|----------|--------|-------|-------|
| 5 | 09 | Ceilings | Ceiling tile stained adjacent to supply diffuser, 2'x2' tile, NW quadrant | Minor | Open | — | Check with mechanical — possible condensation |

---
```

**Organization rules:**

- Critical items get their own section at the top, always visible
- Remaining items are grouped by location (room/area)
- Within each location, sort by CSI division number
- If a room has items across 3+ trades, add a coordination note

### Optional: CSV Export

If the user requests CSV, also write `~/Documents/punch-list-[project-slug].csv` with these columns:

```
Item #,Location,CSI Division,Trade,Description,Priority,Status,Photo,Notes
```

This format is compatible with import into Procore, PlanGrid, BIM 360, and most construction management platforms.

## Workflow

### Step 1: Receive and parse input

Read the user's notes, photos, or walkthrough input. Extract individual deficiency items. For ambiguous items, ask for clarification:

- "You mentioned 'HVAC issue in lobby' — can you describe the issue? (noise, temperature, diffuser alignment, controls)"
- "Where exactly is the 'cracked tile'? (room number, which wall/floor, approximate location)"

### Step 2: Categorize and enrich

For each extracted item:

1. Assign a sequential item number
2. Map to CSI division
3. Assign the responsible trade
4. Write a clear, specific description (expand terse notes into actionable language)
5. Set priority level
6. Flag code/safety issues
7. Cross-reference related items
8. Default status to Open

Present the categorized list to the user:

```
Parsed X items from your notes:
- X Critical, X Major, X Minor
- Trades: Painting (X), Electrical (X), Mechanical (X), ...
- Locations: Room 201 (X items), Lobby (X items), ...

Shall I proceed with writing the punch list, or do you want to review/edit items first?
```

### Step 3: Write output

Generate the markdown file (and CSV if requested). Report the result:

```
Punch list written: X items across Y locations
Output: ~/Documents/punch-list-[project-slug].md
Critical items: X (requiring immediate attention)
Completion: X%
```

### Step 4: Additions and updates

After the initial list is written, the user may:

- **Add items**: "Add: Room 305, ceiling grid is sagging near the window" — append to the existing list, increment item numbers
- **Update status**: "Items 3, 7, 12 are complete" — update status and recalculate summary
- **Change priority**: "Item 5 is actually critical, it's a trip hazard" — update and move to critical section
- **Re-export**: Regenerate the file with current state

When updating, always rewrite the file with current summary statistics.

## Writing Style

- Descriptions shall be specific, measurable, and actionable
- Use construction industry terminology: "substrate", "rough-in", "punch", "deficiency", "close out"
- Include dimensions or extent when describing deficiencies ("2'x3' area", "3 LF of base", "2 tiles")
- Reference compass directions or grid lines for locations within rooms when possible
- Do not editorialize — state the deficiency, not an opinion about it
- Measurements in imperial units unless the user specifies metric

## Edge Cases

- **Single item**: Generate the full document with summary (even if trivial). The structure supports future additions.
- **No location provided**: Ask once. If the user cannot provide a location, use "Unassigned" and flag for field verification.
- **Ambiguous trade**: Assign the most likely trade and note the ambiguity. Example: "Stain on ceiling tile near diffuser — assigned to Ceilings, but may be Mechanical if caused by condensation. Verify source before issuing."
- **Photo with multiple issues**: Create a separate item for each deficiency visible in the photo. Reference the same photo file for all.
- **Very large lists (50+ items)**: Process all of them. Give a progress update after every 20 items parsed. At the end, highlight the critical items and suggest prioritization.
- **Warranty walk items**: If the user specifies warranty phase, add a "Warranty" tag to items and note the warranty expiration date if provided.
- **Items already complete**: Accept items marked as complete. Include them in the list with Complete status and factor into completion percentage.
