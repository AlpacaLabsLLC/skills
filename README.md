# Claude Code Skills for Architects & Designers

> Slash-command skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that bring domain expertise to architecture, real estate, and workplace design. Clone, symlink, type `/skill-name` — done.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Available Skills

### [`/color-palette-generator`](./color-palette-generator)

Color palette generator. Describe a mood, paste an image, or give it a single hex code — get a harmonious 8-12 color palette as a self-contained `.html` file with swatches, HEX/RGB/HSL codes, WCAG contrast ratios, and example pairings. The HTML itself uses the generated palette.

### [`/design-brief-builder`](./design-brief-builder)

Design brief builder. Feed it vague client requirements, meeting notes, or a project description — get a structured brief with program requirements, adjacency matrix, design criteria, technical constraints, and open questions. Runs a guided discovery interview when input is sparse.

### [`/email-drafter`](./email-drafter)

AEC email drafter. Tell it who you're writing to and what about — get a project email with the right tone and structure. Handles RFIs, submittal reviews, client updates, consultant coordination, contractor correspondence, meeting follow-ups, and scope change notices.

### [`/redline-punch-list`](./redline-punch-list)

Construction punch list generator. Paste field notes or drag in site photos — get a structured punch list with CSI divisions, trade assignments, priority levels (critical/major/minor), and summary statistics. Exports to markdown or CSV for Procore/PlanGrid/BIM 360.

### [`/site-analysis-generator`](./site-analysis-generator)

Site analysis research assistant. Give it an address or coordinates — get a comprehensive brief with climate data, zoning, transit access, demographics, neighborhood context, and natural features. Uses web search to pull real data.

### [`/slide-deck-generator`](./slide-deck-generator)

HTML slide deck generator. Describe a topic, paste an outline, or feed it data — get a self-contained `.html` presentation with an editorial design system: Helvetica, left-aligned layout, monochrome palette, 22 slide types (stats, tables, bar charts, timelines, comparisons, image grids), keyboard/touch navigation, and a progress bar. Open in any browser.

### [`/spec-writer`](./spec-writer)

CSI outline specification writer. Feed it a materials list, product schedule, or project description — get structured specs organized by MasterFormat division with three-part sections (General, Products, Execution), performance criteria, and acceptable manufacturers.

### [`/workplace-programmer`](./workplace-programmer)

AI workplace strategy consultant that builds office space programs through conversation. Give it a headcount, square footage, and work policy — get area splits, room schedules, seat counts, and exportable reports backed by 10 archetypes, 43 research findings from JLL, CBRE, Gensler, Hassell (6 years of Workplace Futures Survey), and others.

### [`/occupancy-calculator`](./occupancy-calculator)

IBC occupancy load calculator. Describe your building or paste a room schedule — get per-area occupant loads from IBC Table 1004.5, with gross vs net area handling, use group classification, egress requirements, and exportable reports. Supports IBC 2021 with NYC Building Code variant notes. Integrates with `/workplace-programmer` to calculate occupancy from existing space programs.

### [`/zoning-analyzer`](./zoning-analyzer)

Zoning envelope analyzer for lots in Maldonado, Uruguay. Paste GIS JSON from the [municipal cadastral portal](https://ide.maldonado.gub.uy/), get a full building envelope analysis — zone determination, setbacks, height limits, FOS/FOT, and an ASCII buildable-area sketch — all referenced to the TONE regulations.

### [`/product-spec-bulk-fetch`](./product-spec-bulk-fetch)

Bulk FF&E product spec extractor. Feed it a list of product page URLs — get a standardized schedule with names, dimensions, materials, pricing, and images extracted from each page using AI. Outputs to CSV, Google Sheets, or markdown.

### [`/product-spec-bulk-cleanup`](./product-spec-bulk-cleanup)

FF&E schedule normalizer. Takes a messy furniture schedule — mixed casing, combined dimensions, Spanish material names, inconsistent categories — and cleans it into consistent, procurement-ready data. Pairs with `/product-spec-bulk-fetch` for a full fetch → cleanup pipeline.

### [`/product-spec-pdf-parser`](./product-spec-pdf-parser)

PDF product spec parser. Feed it price books, fact sheets, or spec sheets — Claude extracts text with PyMuPDF and reasons over it to produce a standardized 24-field FF&E schedule with variants, SKUs, pricing, and dimensions. Handles configurators (Aeron), SKU-based fact sheets (Alphabeta), and upholstery/finish variants (Puffy). Pairs with `/product-spec-bulk-cleanup` for a full parse → cleanup pipeline.

### [`/product-image-processor`](./product-image-processor)

Batch product image processor. Read image URLs from a Google Sheet, download at full resolution, normalize sizing (max 2000px, PNG), and remove backgrounds via rembg — saving output at each stage. Pairs with `/product-spec-bulk-fetch` for a full spec → image pipeline.

## Install

```bash
# Install all skills
git clone https://github.com/AlpacaLabsLLC/skills.git && skills/install.sh

# Or install just one
git clone https://github.com/AlpacaLabsLLC/skills.git && skills/install.sh workplace-programmer
```

Already cloned? Install more skills anytime:

```bash
cd skills
./install.sh occupancy-calculator product-spec-bulk-fetch   # one or more
./install.sh --list                                         # see what's available
```

Skills are symlinked into `~/.claude/skills/` so they stay in sync when you `git pull`.

Then in Claude Code:

```
/color-palette-generator warm earth tones for a desert spa
/design-brief-builder 15,000 SF coworking space in Brooklyn, 200 members, mixed use
/email-drafter RFI to the GC — the reflected ceiling plan doesn't match the mechanical drawings at grid line 4
/redline-punch-list paint scuffed in room 201, ceiling tile missing in corridor, exit sign out in stairwell B
/site-analysis-generator 250 Hudson St, New York NY
/slide-deck-generator Q1 results for our consulting practice — revenue up 40%, 3 new clients
/spec-writer porcelain tile, LVT flooring, painted gypsum board, acoustic ceiling tile, solid surface countertops
/workplace-programmer 30,000 RSF tech company, 200 people, 3 days hybrid
/occupancy-calculator 50,000 SF office building, 3 floors
/zoning-analyzer
/product-spec-bulk-fetch https://www.hermanmiller.com/products/seating/lounge-chairs/eames-lounge-chair/
/product-spec-bulk-cleanup ~/Documents/ffe-schedule.csv
/product-spec-pdf-parser ~/Documents/specs/aeron-price-book.pdf
/product-image-processor
```

## What Are Claude Code Skills?

[Skills](https://docs.anthropic.com/en/docs/claude-code/skills) are markdown files that extend Claude Code with domain knowledge and workflows. When you type a slash command, Claude reads the skill's `SKILL.md` and any referenced data files, then follows the instructions as a specialist in that domain.

Skills are:
- **Local** — they live in `~/.claude/skills/` on your machine
- **Portable** — just markdown and JSON, no dependencies
- **Composable** — use them alongside any other Claude Code workflow
- **Editable** — customize the persona, data, or workflow by editing the files

## Contributing

Have a skill for the built environment? Open a PR. Each skill needs:

1. A `SKILL.md` with clear instructions and domain knowledge
2. A `README.md` with install, usage, and sample output
3. Any supporting data files in a `data/` or `normativa/` directory

## License

MIT — see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc) — research, strategy, and technology for the built environment.
