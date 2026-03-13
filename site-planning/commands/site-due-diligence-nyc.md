---
description: Run full site due diligence for a New York City address — site analysis followed by zoning envelope from PLUTO data.
argument-hint: [NYC address, e.g. "375 Sterling Place, Brooklyn NY"]
---

Run this two-step pipeline in sequence. Complete each step fully before moving to the next.

## Step 1: Site Analysis Generator

Invoke the `/site-analysis-generator` skill with the user's NYC address. Research and produce the full site analysis brief covering climate, zoning context, transit, demographics, neighborhood, and natural features.

Save the analysis output before proceeding.

## Step 2: NYC Zoning Analysis

Invoke the `/zoning-analysis-nyc` skill for the same address. Query PLUTO for the lot data and walk through the full zoning envelope analysis — district classification, FAR, height, setbacks, yards, overlays, special districts, permitted uses, parking, and development potential.

Carry forward any relevant context from Step 1:
- Environmental constraints (flood zones, coastal erosion hazards)
- Transit proximity (relevant for City of Yes TOD provisions)
- Historic district or landmark status
- Neighborhood character notes (relevant for contextual district analysis)

## Output

Save both reports as separate markdown files:
1. `site-analysis-[address-slug].md`
2. `zoning-analysis-[address-slug].md`

Then present a brief combined summary highlighting the key development constraints and opportunities discovered across both analyses.
