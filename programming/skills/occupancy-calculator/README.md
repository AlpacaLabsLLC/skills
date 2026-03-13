# /occupancy-calculator

IBC occupancy load calculator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Describe your building — get per-area occupant loads from IBC Table 1004.5, gross vs net area handling, egress requirements, and exportable reports.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/occupancy-calculator" ~/.claude/skills/occupancy-calculator
```

## Usage

```
/occupancy-calculator 50,000 SF office building, 3 floors
```

Or describe a mixed-use building:

```
/occupancy-calculator ground floor retail (8,000 SF) + 4 floors office (40,000 SF)
```

Or start with no context:

```
/occupancy-calculator
```

### Conversation Flow

The skill works through four phases:

1. **Discover** — learns about your building, identifies use types, clarifies gross vs net measurements
2. **Calculate** — breaks the building into areas, assigns IBC Table 1004.5 load factors, calculates occupant loads per area and total
3. **Detail** — provides egress requirements (number of exits, stair/corridor/door widths) derived from the occupant load
4. **Refine** — handles adjustments with before/after comparison and updated egress implications

## Demo: Mixed-Use Office Building — 50,000 SF

Real output from a session. The brief: "50K SF office building, 3 floors, ground floor has a 2,000 SF café and 500 SF lobby."

```
| Area                  | Use Type                | SF     | Gross/Net | Load Factor | Occupants |
|-----------------------|-------------------------|-------:|-----------|------------:|----------:|
| Office (Floors 1-3)   | Business Areas          | 44,000 | Gross     |         150 |       294 |
| Ground Floor Café     | Assembly — Unconcentrated| 2,000 | Net       |          15 |       134 |
| Café Kitchen          | Kitchens — Commercial   |  1,500 | Gross     |         200 |         8 |
| Lobby                 | Business Areas          |    500 | Gross     |         150 |         4 |
| Storage/Mechanical    | Accessory Storage       |  2,000 | Gross     |         300 |         7 |
| **Total**             |                         | **50,000** |       |             |   **447** |
```

The café is only 4% of the floor area but contributes **30% of the occupant load** — assembly factors are that dense. This drives egress: 3 exits required (>250 occupants), 90" stair width, and 67" corridor width.

## Workplace Programmer Integration

If a `program.json` file exists in the working directory (from `/workplace-programmer`), the skill offers to calculate occupancy directly from the room schedule — mapping conference rooms to assembly factors, open desks to business, kitchens to commercial kitchen, and storage to accessory.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Persona, domain expertise, conversation flow, formatting rules |
| `data/occupancy-load-factors.json` | 39 IBC 2021 Table 1004.5 use types with load factors, gross/net designation, aliases, and NYC BC variant notes |
| `data/use-groups.json` | 21 IBC use group classifications (A through U) with descriptions and examples |

## Customization

Everything the skill knows lives in editable JSON files. No code to change — just data.

### Add a use type

Your project has a use type that doesn't exist in the defaults? Add it to `data/occupancy-load-factors.json`:

```json
{
  "id": "data-center",
  "use": "Data Center — Server Floor",
  "use_group": "B",
  "load_factor_sf": 300,
  "area_type": "gross",
  "ibc_table": "1004.5",
  "code_edition": "IBC 2021",
  "aliases": ["server room", "data hall", "colocation"],
  "notes": "Not explicitly listed in IBC — classified as accessory or business depending on jurisdiction."
}
```

The skill will immediately use it when classifying spaces. `aliases` enables fuzzy matching when the user describes spaces informally.

### Add jurisdiction variants

Working in a jurisdiction with amended occupancy factors? Add notes to existing entries or create jurisdiction-specific entries. The `notes` field on each use type is where jurisdiction differences are documented — the skill reads and cites these during calculations.

### Change the persona

Edit `SKILL.md` to adjust the personality or domain focus. Swap "code consultant" for "fire marshal" or "plan reviewer" — the conversation flow adapts to whatever role you write.

## License

MIT
