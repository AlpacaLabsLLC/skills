---
description: Build a complete space program — calculate occupancy loads then develop the full workplace program.
argument-hint: [building description, e.g. "50,000 SF office, 3 floors, ground floor cafe"]
---

Run this two-step pipeline in sequence. Complete each step fully before moving to the next.

## Step 1: Occupancy Calculator

Invoke the `/occupancy-calculator` skill with the user's input. Walk through all four phases (Discover, Calculate, Detail, Refine) until the occupancy analysis is complete and the user is satisfied.

Save the occupancy output before proceeding.

## Step 2: Workplace Programmer

Invoke the `/workplace-programmer` skill, passing forward the building parameters and occupancy results from Step 1. The workplace programmer should use the occupancy load as a baseline for headcount and egress-driven constraints.

Walk through all four phases (Discover, Synthesize, Detail, Refine) until the program is complete.

## Handoff

When transitioning from Step 1 to Step 2, summarize the key outputs being carried forward:
- Total building area and per-floor breakdown
- Total occupant load and dominant use types
- Egress requirements (exits, stair widths) that constrain the program
- Any special conditions (assembly spaces, high-density areas)
