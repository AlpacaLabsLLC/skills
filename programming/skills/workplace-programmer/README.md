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

Everything the skill knows lives in editable JSON files. No code to change — just data.

### Add a space type

Your firm uses a 120 SF focus pod that ships don't exist in the defaults? Add it to `data/space-types.json`:

```json
{
  "id": "focus-pod-2p",
  "name": "Focus Pod (2p)",
  "category": "meeting",
  "default_sf": 120,
  "capacity": 2,
  "utilization_rsf": 1500,
  "source": "custom",
  "is_global": true,
  "project_id": null,
  "created_at": "2026-03-01T00:00:00Z"
}
```

The skill will immediately use it when building room schedules. `utilization_rsf` sets the ratio (1 per 1,500 RSF here) — set to `null` if it doesn't apply (desks, support spaces).

### Add an archetype

Run a program, like it, want to reuse it as a starting benchmark? Save it as an archetype in `data/archetypes.json`:

```json
{
  "id": "healthcare-clinic",
  "name": "Healthcare Clinic",
  "description": "High BOH for medical storage, exam rooms in meeting zone, minimal common. Designed for outpatient clinics and medical offices.",
  "sf_per_seat": 200,
  "area_splits": {
    "work": 25,
    "meeting": 22,
    "common": 8,
    "circulation": 27,
    "boh": 18
  },
  "private_office_pct": 40,
  "desk_type_mix": {
    "bench-60x36": 60,
    "private-office": 40
  },
  "room_ratios": {},
  "source": "custom",
  "created_at": "2026-03-01T00:00:00Z"
}
```

The five zone percentages must sum to 100. `desk_type_mix` percentages should also sum to 100. The skill uses archetypes as benchmarks during synthesis — it won't apply them as templates, but it will reference them when explaining where your program sits relative to industry norms.

### Add research findings

Drop new findings into `data/findings.json` and the skill will cite them during discovery and synthesis:

```json
{
  "id": "your-source-topic-year",
  "topics": ["hybrid", "density"],
  "source": "Source Name",
  "source_year": 2025,
  "study": "Study or Report Title",
  "finding": "The concrete finding with numbers. Be specific — the skill quotes these directly in conversation.",
  "confidence": "high",
  "added": "2026-03-01"
}
```

Tag with relevant `topics` so the skill surfaces findings at the right moment: `hybrid`, `density`, `meeting-rooms`, `focus`, `acoustics`, `amenity-roi`, `abw`, `neighborhoods`, `open-vs-private`.

### Change the persona

Edit `SKILL.md` to change who the skill thinks it is. Swap "senior workplace strategy consultant" for "lab planning specialist" or "retail space planner" — the conversation flow and domain expertise adapt to whatever you write.

## License

MIT
