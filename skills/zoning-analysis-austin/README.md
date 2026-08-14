# /as:zoning-analysis-austin

Preliminary City of Austin parcel zoning and development-capacity analysis from official zoning, parcel, overlay, environmental, case, and Land Development Code sources.

Invoke `/as:zoning-analysis-austin` on Claude Code or `$zoning-analysis-austin` on Codex, then provide an Austin address, coordinates, legal description, or appraisal/geographic ID.

The skill resolves jurisdiction and parcel geometry, assembles the complete zoning and ordinance stack, verifies current development controls, shows sourced capacity calculations, and prepares optional envelope data for `/as:zoning-envelope`.

## Outputs

- `zoning-analysis-[address-slug]-austin.md`
- A source register with access and dataset dates
- Verified, calculated, reported, and unresolved findings kept distinct
- Machine-readable envelope data when geometry and controls are sufficient

## Important limitation

Austin's Zoning By Address dataset is a useful locator but is not sufficient for a zoning determination. The workflow verifies parcel intersections, overlays, combining districts, and site-specific ordinances through current official sources. All results remain preliminary and require licensed-professional and authority-having-jurisdiction verification before design, acquisition, permitting, or regulatory reliance.
