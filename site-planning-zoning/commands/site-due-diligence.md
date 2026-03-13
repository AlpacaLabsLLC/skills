---
description: Run full site due diligence — comprehensive site analysis followed by zoning envelope calculation.
argument-hint: [address or coordinates, e.g. "Ruta 10 km 164, La Barra, Maldonado"]
---

Run this two-step pipeline in sequence. Complete each step fully before moving to the next.

## Step 1: Site Analysis Generator

Invoke the `/site-analysis-generator` skill with the user's location. Research and produce the full site analysis brief covering climate, zoning context, transit, demographics, neighborhood, and natural features.

Save the analysis output before proceeding.

## Step 2: Zoning Analyzer

Invoke the `/zoning-analyzer` skill for the same site. If the user has GIS JSON data from the cadastral portal, use it. Otherwise, work with the address and any parcel information gathered in Step 1.

Walk through all phases until the zoning envelope analysis is complete — lot dimensions, applicable zone, occupation factors, height, setbacks, and buildable area.

## Handoff

When transitioning from Step 1 to Step 2, summarize the key context being carried forward:
- Site location and parcel identification
- Zoning designation discovered during site analysis
- Any height or density overlays noted
- Environmental constraints (flood zones, topography) that may affect the envelope
