# Tooling catalog

Architecture Studio skills install together in one flat catalog so every workflow can be invoked directly. The links below use Claude Code's `/as:<skill>` namespace; Codex invokes the same installed skills as `$<skill>`. These groups describe what the tools do; they are not separate plugins or installation packages.

## Firm operations

| Skill | Description |
|-------|-------------|
| [`/as:studio`](./studio) | Set up and inspect the studio, route work, and create projects |
| [`/as:tool-catalog`](./tool-catalog) | Show the available skills and agents |
| [`/as:learn`](./learn) | Guided, resumable introduction to Codex and Claude Code for architects (use `$learn` on Codex) |
| [`/as:skill-maker`](./skill-maker) | Create studio-wide or project-specific procedures outside the plugin cache |
| [`/as:studio-feedback`](./studio-feedback) | Prepare a reviewed bug report or feature request without automatic submission |

## Project management

### Project Records

Project records form a linked graph of plain files. `/as:project` is the setup and memory interface: `PROJECT.md` owns sourced facts and `decisions/` owns durable reasoning. Meetings and site reports preserve source context, the canonically resolved project or studio `TASKS.md` owns action history, work plans read those records, and `TIMELOG.md` records only user-confirmed durations.

| Skill | Description |
|-------|-------------|
| [`/as:project`](./project) | Initialize a project, maintain sourced facts, and manage durable decisions |
| [`/as:workplan`](./workplan) | Plan repository, operational, or AEC delivery work before acting |
| [`/as:meeting-minutes`](./meeting-minutes) | Create source-linked meeting records with explicit promotion handoffs |
| [`/as:site-visit-report`](./site-visit-report) | Record field observations, reported information, limitations, and follow-up candidates |
| [`/as:tasklist`](./tasklist) | Maintain project tasks or an opted-in studio portfolio register |
| [`/as:timetracker`](./timetracker) | Reconstruct activity and append only user-confirmed time |

## Practice and design

### Due diligence

| Skill | Description |
|-------|-------------|
| [`/as:nyc-landmarks`](./nyc-landmarks) | LPC landmark and historic district check |
| [`/as:nyc-dob-permits`](./nyc-dob-permits) | DOB permit and filing history |
| [`/as:nyc-dob-violations`](./nyc-dob-violations) | DOB and ECB violations |
| [`/as:nyc-acris`](./nyc-acris) | ACRIS property transaction records |
| [`/as:nyc-hpd`](./nyc-hpd) | HPD violations, complaints, and registration |
| [`/as:nyc-bsa`](./nyc-bsa) | BSA variances and special permits |
| [`/as:nyc-property-report`](./nyc-property-report) | Combined NYC property report |

### Site and zoning

| Skill | Description |
|-------|-------------|
| [`/as:environmental-analysis`](./environmental-analysis) | Climate, wind, sun, flood, seismic, and soil research |
| [`/as:mobility-analysis`](./mobility-analysis) | Transit, walkability, cycling, and pedestrian infrastructure |
| [`/as:demographics-analysis`](./demographics-analysis) | Population, income, age, housing, and employment |
| [`/as:site-history`](./site-history) | Neighborhood context, landmarks, activity, and planned development |
| [`/as:zoning-analysis-austin`](./zoning-analysis-austin) | Austin zoning, overlays, site controls, mapped constraints, and preliminary development capacity |
| [`/as:zoning-analysis-nyc`](./zoning-analysis-nyc) | NYC FAR, height, setback, and use analysis |
| [`/as:zoning-envelope`](./zoning-envelope) | Self-contained interactive 3D zoning envelope |

### Programming and specifications

| Skill | Description |
|-------|-------------|
| [`/as:workplace-programmer`](./workplace-programmer) | Workplace programs from headcount and work style |
| [`/as:occupancy-calculator`](./occupancy-calculator) | IBC occupancy loads, egress, exits, and plumbing fixtures |
| [`/as:spec-writer`](./spec-writer) | CSI outline specifications with review markers |

### Sustainability

| Skill | Description |
|-------|-------------|
| [`/as:epd-parser`](./epd-parser) | Extract environmental data from EPD PDFs |
| [`/as:epd-research`](./epd-research) | Research EPD registries by material or category |
| [`/as:epd-compare`](./epd-compare) | Compare environmental impacts and LEED eligibility |
| [`/as:epd-to-spec`](./epd-to-spec) | Generate CSI language with EPD requirements and GWP thresholds |

### FF&E and materials

Persistent FF&E data uses project-local `product-library.csv`; optional EPD persistence uses `epd-library.csv`. Their canonical contracts live in [`schema/`](../schema).

| Skill | Description |
|-------|-------------|
| [`/as:master-schedule`](./master-schedule) | Initialize or inspect the project-local product library |
| [`/as:product-research`](./product-research) | Find products from a design brief |
| [`/as:product-spec-bulk-fetch`](./product-spec-bulk-fetch) | Extract specifications from product URLs at scale |
| [`/as:product-spec-pdf-parser`](./product-spec-pdf-parser) | Extract specifications from catalogs, price books, and sheets |
| [`/as:product-data-cleanup`](./product-data-cleanup) | Normalize product categories, dimensions, materials, and language |
| [`/as:product-data-import`](./product-data-import) | Turn product lists into formatted FF&E schedules |
| [`/as:product-enrich`](./product-enrich) | Tag products with categories, colors, materials, and styles |
| [`/as:product-match`](./product-match) | Find similar products from an image, name, or description |
| [`/as:product-pair`](./product-pair) | Suggest complementary products |
| [`/as:product-image-processor`](./product-image-processor) | Download, resize, and remove product-image backgrounds |
| [`/as:csv-to-sif`](./csv-to-sif) | Convert canonical product CSV to SIF |
| [`/as:sif-to-csv`](./sif-to-csv) | Convert SIF into the canonical product CSV schema |

### Presentations

| Skill | Description |
|-------|-------------|
| [`/as:slide-deck-generator`](./slide-deck-generator) | Create self-contained HTML slide decks |
| [`/as:color-palette-generator`](./color-palette-generator) | Create palettes with WCAG contrast checks |
| [`/as:resize-images`](./resize-images) | Resize images for web, social, slides, and print |

## Individual skill documentation

Each directory contains an authoritative `SKILL.md`, a human-facing `README.md`, and any scripts, references, templates, or data owned by that skill. Create studio or project procedures with `/as:skill-maker`; to contribute a built-in skill, read [CONTRIBUTING.md](../CONTRIBUTING.md).
