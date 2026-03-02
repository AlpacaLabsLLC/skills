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

## Demo: Law Firm — 20,000 RSF

Real output from a session where the brief was "20K RSF law firm, maximize attorney headcount, 1 private office per 10 attorneys, 1 support staff per 10 attorneys, 5 days in office."

The skill pushed the work zone to 41% and landed at **111 attorneys + 11 support = 122 total headcount at 164 SF/seat**:

```
| Zone        |    % |      SF |
|-------------|-----:|--------:|
| Work        |  41% |   8,200 |
| Meeting     |  17% |   3,400 |
| Common      |   7% |   1,400 |
| Circulation |  27% |   5,400 |
| BOH         |   8% |   1,600 |
| **Total**   | 100% |  20,000 |
```

With the full room schedule:

```
| Type                    | Count | SF Each | Total SF |
|-------------------------|------:|--------:|---------:|
| Boardroom (14p)         |     1 |     500 |      500 |
| Large Conference (10p)  |     2 |     300 |      600 |
| Medium Conference (6p)  |     4 |     225 |      900 |
| Small Huddle (4p)       |     8 |     100 |      800 |
| Phone Booth (1p)        |    10 |      25 |      250 |
| Lounge / Informal (4p)  |     5 |      56 |      280 |
| **Subtotal**            |  **30** |      |  **3,330** |
```

Every recommendation includes research citations and tradeoff analysis. The full program exports to `program.json`, `.md`, and `.csv`.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Persona, domain expertise, conversation flow, formatting rules |
| `data/archetypes.json` | 10 benchmark office profiles (Dense Open at 65 SF/seat through Creative Agency at 233 SF/seat) |
| `data/space-types.json` | 22 room and desk types with default SF and capacity |
| `data/findings.json` | 43 research findings from JLL, CBRE, Gensler, VergeSense, Density, Leesman, Steelcase, Hassell (incl. 6 years of Hassell Workplace Futures Survey 2020–2025) |

## Customization

Edit any file to adapt the skill for your practice:

- **Change the persona** — edit the identity section in `SKILL.md`
- **Add archetypes** — append entries to `data/archetypes.json` (e.g., a healthcare or lab archetype)
- **Update research** — add findings to `data/findings.json` with source, date, and topic tags
- **Add space types** — extend `data/space-types.json` with your firm's standard room catalog

## License

MIT
