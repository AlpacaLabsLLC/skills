# /workplace-programmer

AI workplace strategy consultant for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Builds office space programs through conversation — area splits, room schedules, seat counts, and exportable reports — backed by industry research from JLL, CBRE, Gensler, VergeSense, and others.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/workplace-programmer" ~/.claude/skills/workplace-programmer
```

## Usage

```
/workplace-programmer 30,000 RSF tech company, 200 people, 3 days hybrid
```

Or start with no context and let the skill ask discovery questions:

```
/workplace-programmer
```

### Conversation Flow

The skill works through four phases:

1. **Discover** — asks about your organization, headcount, work policy, and culture while sharing relevant research (e.g., JLL occupancy benchmarks, Gensler workspace surveys)
2. **Synthesize** — generates area splits across five zones: Work, Meeting, Common, Circulation, and BOH
3. **Detail** — proposes seat types, conference room schedules, and support spaces with square footage calculations
4. **Refine** — handles adjustments with explicit tradeoff analysis ("adding 2 large conference rooms means removing 10 desks")

## Sample Output

Mid-conversation, the skill produces structured recommendations:

```
Based on your 30,000 RSF hybrid tech office with 200 people on a 3-day
in-office policy, here's my recommendation:

| Zone        |  Pct |      SF |
|-------------|------:|--------:|
| Work        |  28% |   8,400 |
| Meeting     |  22% |   6,600 |
| Common      |  16% |   4,800 |
| Circulation |  27% |   8,100 |
| BOH         |   7% |   2,100 |
| **Total**   | 100% |  30,000 |

I'm pulling work down to 28% because JLL's 2024 data shows hybrid
offices with 3-day policies allocate 15-20% less to individual work
than pre-pandemic baselines. Your 200 people at 3 days means ~120
concurrent on peak days — we're designing for that mid-week peak,
not full capacity.
```

The program state saves to `program.json` in your working directory:

```json
{
  "inputs": {
    "name": "Tech HQ",
    "rsf": 30000,
    "headcount": 200,
    "hybrid_policy": "3 days in office"
  },
  "area_splits": {
    "work":        { "pct": 28, "sf": 8400 },
    "meeting":     { "pct": 22, "sf": 6600 },
    "common":      { "pct": 16, "sf": 4800 },
    "circulation": { "pct": 27, "sf": 8100 },
    "boh":         { "pct": 7,  "sf": 2100 }
  },
  "seats": [
    { "name": "60\"x36\" Adjustable Desk", "count": 100, "sf_each": 65, "sf_total": 6500 },
    { "name": "48\"x24\" Bench", "count": 40, "sf_each": 48, "sf_total": 1920 }
  ],
  "rooms": [
    { "name": "Large Conference (10p)", "count": 2, "sf_each": 300, "sf_total": 600 },
    { "name": "Medium Conference (6p)", "count": 3, "sf_each": 225, "sf_total": 675 },
    { "name": "Small Huddle (4p)", "count": 5, "sf_each": 100, "sf_total": 500 },
    { "name": "Phone Booth", "count": 8, "sf_each": 25, "sf_total": 200 }
  ]
}
```

Ask for a report and the skill writes `report.md` and `report.csv` with the full breakdown.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Persona, domain expertise, conversation flow, formatting rules |
| `data/archetypes.json` | 8 benchmark office profiles (Dense Open at 65 SF/seat through Legal at 300 SF/seat) |
| `data/space-types.json` | 22 room and desk types with default SF and capacity |
| `data/findings.json` | 31 research findings from JLL, CBRE, Gensler, VergeSense, Density, Leesman, Steelcase, Hassell |

## Customization

Edit any file to adapt the skill for your practice:

- **Change the persona** — edit the identity section in `SKILL.md`
- **Add archetypes** — append entries to `data/archetypes.json` (e.g., a healthcare or lab archetype)
- **Update research** — add findings to `data/findings.json` with source, date, and topic tags
- **Add space types** — extend `data/space-types.json` with your firm's standard room catalog

## License

MIT
