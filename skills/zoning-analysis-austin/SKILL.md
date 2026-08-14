---
name: zoning-analysis-austin
description: Analyze City of Austin parcels for preliminary zoning and development capacity using official parcel, zoning, ordinance, environmental, case, and Land Development Code sources. Use for Austin or COA address questions about base and combining districts, conditional overlays, permitted uses, height, setbacks, floor area, building or impervious cover, parking, compatibility, floodplain, prior site plans, and a preliminary buildable envelope. Do not use outside Austin's verified zoning jurisdiction.
---

# /as:zoning-analysis-austin - Austin Zoning Analysis

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Produce a sourced, preliminary analysis of what may be built on a parcel in the City of Austin. Austin has no single PLUTO-equivalent record. Resolve parcel geometry, zoning, overlays, site-specific ordinances, environmental constraints, and current code provisions independently.

## Source gate

Read `<skill-root>/references/data-sources.md` before research and `<skill-root>/references/regulatory-checklist.md` before calculations. Read `<skill-root>/references/gis-query-guide.md` before running automated GIS screening.

- Use current official City of Austin, county, appraisal-district, state, or code-host sources.
- Treat the City's Zoning By Address dataset as a locator only. It expressly omits some overlays and split zoning and may be stale.
- Verify zoning against the Property Profile/GIS polygon layers and identify every zoning polygon intersecting the parcel.
- Retrieve the controlling zoning ordinance when a conditional overlay, PUD, NCCD, TOD, ERC, or other site-specific district is present.
- Never supply a numeric development control from model memory. Cite the current provision or report `Not verified`.
- Record source URL, access date, dataset update date when exposed, and the parcel identifier used.

## Workflow

### 1. Resolve the property

Accept a street address, coordinates, legal description, or county appraisal/geographic ID.

1. Normalize the address without silently changing unit, street direction, or suffix.
2. Run `python3 <skill-root>/scripts/austin_property_lookup.py "<address>" --pretty` when Python and network access are available. Otherwise perform the same official-source queries manually.
3. Resolve the parcel polygon, place ID, appraisal property ID, geographic ID, and address-point coordinates. Treat calculated GIS acreage as **Calculated**, not verified legal area.
4. Confirm whether the parcel is in full-purpose City of Austin jurisdiction, limited-purpose jurisdiction, ETJ, or outside Austin.
5. Stop the Austin zoning calculation if jurisdiction is unresolved. Explain which authority must be checked.

### 2. Assemble the regulatory stack

Intersect the real parcel polygon against current official layers. Report:

- base zoning and every intersecting zoning polygon;
- combining districts, conditional overlays, and zoning text or ordinance references;
- special districts and adopted regulating plans;
- neighborhood-plan or future-land-use context, clearly separated from current zoning;
- historic designations and districts;
- watershed, floodplain, creek/waterway setbacks, aquifer zones, erosion hazards, and other mapped environmental constraints;
- recorded development agreements, approved site plans, subdivisions, variances, and active review cases when available.

For every `CO`, retrieve each ordinance returned by the zoning service, find the parcel's tract or exhibit, and transcribe its prohibited, conditional, and modified site-development standards. Do not infer conditional-overlay content from `CO` alone. Treat older or unreadable associated ordinances as **Not verified** and list them explicitly.

For environmental automation, use the parcel-envelope result only as a conservative discovery screen. Confirm every positive intersection against the parcel geometry and controlling source before calculating affected area. Phrase a negative result as “no mapped intersection returned.”

If boundaries do not align or the parcel is split-zoned, show each control separately. Do not average controls across the parcel unless the controlling rule expressly permits it.

### 3. Retrieve current controlling provisions

Use the current Land Development Code and the parcel's ordinances or regulating plans to verify:

- permitted, conditional, and prohibited uses;
- minimum lot area and dimensions;
- front, street-side, interior-side, and rear setbacks;
- maximum height and floor-to-area ratio when applicable;
- maximum building coverage and impervious cover;
- compatibility or transition constraints;
- parking, bicycle parking, loading, and access requirements;
- landscape, tree, screening, and design standards;
- residential-unit, density, affordability, or preservation incentives that actually apply;
- any vested-rights or approved-site-plan condition visible in official records.

A base-district table alone is never a complete Austin development analysis.

Search official development-review records by address and parcel identifiers. Record the case number, type, description, date, and visible status. An agenda mention or search hit proves only that a record exists; retrieve the case file before treating approval, expiration, or vested rights as established.

### 4. Calculate preliminary capacity

Calculate only from verified inputs. Show formulas and units.

- Gross lot area and constrained area
- Maximum impervious area
- Maximum building footprint from coverage and setbacks
- Maximum floor area when an FAR control applies
- Height-limited and compatibility-limited envelope
- Parking/loading area implications where verified
- Remaining capacity only when reliable existing-condition data is available

When multiple controls compete, identify the controlling minimum. Do not convert a code maximum into a promise of achievable yield. Trees, drainage, fire access, utilities, easements, subdivision restrictions, and engineering may reduce capacity.

When using an approximate GIS area, label resulting FAR, coverage, and impervious figures **Calculated screening upper bounds**. Keep them separate from buildable-area or yield conclusions.

### 5. Build envelope data

Use the actual parcel polygon transformed to local feet. Include a machine-readable `## Envelope Data` JSON block compatible with `/as:zoning-envelope`:

```json
{
  "lot_poly": [[0, 0], [0, 100], [75, 100], [75, 0]],
  "unit": "ft",
  "setbacks": { "front": null, "rear": null, "lateral1": null, "lateral2": null },
  "volumes": [],
  "height_cap": null,
  "info": { "title": "address", "zone": "verified zoning", "id": "parcel id", "area": "verified area" },
  "stats": { "Jurisdiction": "verified value", "Impervious cover": "verified value or Not verified" },
  "constraints": { "impervious_cover": null, "building_coverage": null, "compatibility": [], "environmental": [], "trees": [] },
  "scenarios": null
}
```

Use `null` for unresolved regulatory values. Never render an unresolved control as zero.

### 6. Present and save

Save `zoning-analysis-[address-slug]-austin.md` with:

1. Executive finding
2. Property and jurisdiction
3. Source register
4. Zoning and ordinance stack
5. Site-development controls and uses
6. Overlays and environmental constraints
7. Existing approvals, cases, and variances checked
8. Capacity calculations and scenarios
9. Unknowns, conflicts, and recommended verification steps
10. Envelope Data

Label every material statement as **Verified**, **Calculated**, **Reported**, or **Not verified**. Verified findings cite a current official source; calculated findings show their verified inputs and formula; reported findings are public-record observations not confirmed as controlling.

## Handoffs and limits

- Use `/as:zoning-envelope` only after verified geometry and controls support a meaningful envelope.
- Offer the Site Planner for broader mobility, demographics, climate, and neighborhood context.
- Recommend City zoning staff and appropriate licensed professionals for unresolved controlling questions.
- Do not provide legal advice, title opinions, surveys, permit-ready determinations, or approval guarantees.
- Do not infer deed restrictions or easements from an absence in City GIS.
- Do not apply City zoning tables to ETJ or other jurisdictions without verifying authority.

## Final Step: Disclaimer + Marker (required)

End every chat or saved report with the canonical disclaimer block from `<plugin-root>/rules/professional-disclaimer.md`, followed by one blank line and this single last-line marker:

```markdown
<!-- architecture-studio:requires-disclaimer -->
```
