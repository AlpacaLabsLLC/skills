# /redline-punch-list

Construction punch list generator for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Feed it field notes, photos, or a walkthrough description — get a structured punch list with CSI divisions, trade assignments, priority levels, and summary statistics.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/redline-punch-list" ~/.claude/skills/redline-punch-list
```

## Usage

Paste field notes directly:

```
/redline-punch-list

Room 201 - paint scuffs above door, ceiling tile stained near diffuser
Room 202 - door won't latch, base is pulling away from wall
Lobby - exit sign is out, tile cracked near elevator
Stairwell B - handrail loose at 2nd floor landing
```

From photos:

```
/redline-punch-list ~/Documents/Screenshots/punch-walk-photo-01.jpg
```

Guided walkthrough:

```
/redline-punch-list

I'm doing a final punch walk on a 10,000 SF office tenant improvement, 3rd floor.
```

## What It Does

1. Parses field notes, photos, or verbal descriptions into individual deficiency items
2. Maps each item to CSI MasterFormat division and responsible trade
3. Assigns priority: Critical (safety/code), Major (functional), Minor (cosmetic)
4. Flags code and safety issues automatically (egress, ADA, fire protection, life safety)
5. Cross-references related items and suggests coordination
6. Writes a structured `.md` file to `~/Documents/punch-list-[project-slug].md` with summary tables
7. Optionally exports `.csv` for import into Procore, PlanGrid, or BIM 360

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Punch list generation workflow, CSI division mapping, smart categorization rules, output format |

## License

MIT
