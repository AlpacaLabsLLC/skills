# /as:spec-writer

CSI outline specification writer for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Feed it a materials list, product schedule, or project description — get structured outline specs organized by MasterFormat 2020 divisions.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:spec-writer
```

Then provide your materials — paste a list, point to a file, or describe the project.

```
/as:spec-writer

Porcelain floor tile, ACT ceiling, painted gypsum board, aluminum curtain wall,
resilient base, ceramic wall tile, hollow metal doors and frames, joint sealants
```

From a file:

```
/as:spec-writer ~/Documents/finish-schedule.csv
```

By description:

```
/as:spec-writer

Ground-up 5-story commercial office. Curtain wall exterior, concrete structure,
TPO roof, porcelain tile in lobbies, carpet tile in offices, ACT ceilings throughout.
```

## What It Does

1. Maps each material to the correct CSI MasterFormat division and section number
2. Generates three-part outline specs (General / Products / Execution) for each section
3. Includes reference standards (ASTM, ANSI), acceptable manufacturers, performance criteria
4. Flags generic sections with `[REVIEW REQUIRED]` for senior specifier attention
5. Writes a single organized `.md` file to `./outline-specs-[project-slug].md` in the current working directory

## Divisions Covered

03 Concrete, 04 Masonry, 05 Metals, 06 Wood/Plastics/Composites, 07 Thermal & Moisture Protection, 08 Openings, 09 Finishes, 10 Specialties, 12 Furnishings, 22 Plumbing (fixtures), 26 Electrical (fixtures).

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Spec generation workflow, division mapping, three-part format rules |

## License

MIT
