---
description: Run full NYC site due diligence — environmental, mobility, demographics, neighborhood history, and zoning envelope from PLUTO.
argument-hint: [NYC address, e.g. "375 Sterling Place, Brooklyn NY"]
---

Run this five-step pipeline in sequence. Complete each step fully before moving to the next. Use the same address for all steps.

## Step 1: Environmental Analysis

Invoke the `/environmental-analysis` skill with the user's NYC address. Research and produce the climate and environmental brief — temperature, precipitation, wind, sun angles, flood zones, seismic risk, soil, and topography.

Save the output before proceeding.

## Step 2: Mobility Analysis

Invoke the `/mobility-analysis` skill for the same address. Research transit, walk/bike/transit scores, road access, airports, and pedestrian infrastructure.

Save the output before proceeding.

## Step 3: Demographics Analysis

Invoke the `/demographics-analysis` skill for the same address. Research population, income, age, housing market, and employment data.

Save the output before proceeding.

## Step 4: Neighborhood History

Invoke the `/neighborhood-history` skill for the same address. Research adjacent land uses, architectural character, historic districts, landmarks, commercial activity, and planned development.

Save the output before proceeding.

## Step 5: NYC Zoning Analysis

Invoke the `/zoning-analysis-nyc` skill for the same address. Query PLUTO for the lot data and produce the full zoning envelope analysis — district classification, FAR, height, setbacks, yards, overlays, special districts, permitted uses, parking, and development potential.

Carry forward relevant context from prior steps:
- Flood zones and environmental hazards (from Step 1)
- Transit proximity for City of Yes TOD provisions (from Step 2)
- Housing market context for development potential (from Step 3)
- Historic district and landmark status (from Step 4)

## Output

Each step saves its own markdown file to `~/Documents/`. After all 5 steps, present a brief combined summary highlighting the key development constraints and opportunities discovered across all analyses.
