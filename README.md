<div align="center">

```
 █████╗ ██████╗  ██████╗██╗  ██╗    ███████╗████████╗██╗   ██╗██████╗ ██╗ ██████╗
██╔══██╗██╔══██╗██╔════╝██║  ██║    ██╔════╝╚══██╔══╝██║   ██║██╔══██╗██║██╔═══██╗
███████║██████╔╝██║     ███████║    ███████╗   ██║   ██║   ██║██║  ██║██║██║   ██║
██╔══██║██╔══██╗██║     ██╔══██║    ╚════██║   ██║   ██║   ██║██║  ██║██║██║   ██║
██║  ██║██║  ██║╚██████╗██║  ██║    ███████║   ██║   ╚██████╔╝██████╔╝██║╚██████╔╝
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝    ╚══════╝   ╚═╝    ╚═════╝ ╚═════╝ ╚═╝ ╚═════╝
```

**Architecture Studio**

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/AlpacaLabsLLC/skills-for-architects)](https://github.com/AlpacaLabsLLC/skills-for-architects/releases)

</div>

> A local-first framework for architecture firms to build, govern, and share their own AI-assisted workflows—use with [Claude](https://claude.ai) or [Claude Code](https://code.claude.com/docs).

**Architecture Studio** provides a governance layer, persistent studio and project memory, and clear extension points for firm-wide and project-specific skills. The bundled AEC skills and agents are working reference implementations and starting templates: use them directly, study their patterns, or build procedures that reflect how your own practice works.

Firm-created skills remain in the user-owned studio workspace, outside the installed plugin cache. They can stay private to a firm or project, or be developed for contribution back to the open-source project.

**One plugin**—`as` v1.4.0—with **7 agents**, **7 rules**, and **4 hooks (handlers across 3 events)**. Created by Federico Negro in 2026 and built by [ALPA](https://alpa.llc) (`hello@alpa.llc`). Copyright © 2026 Alpaca Design Lab LLC; MIT-licensed.

## What’s new in 1.4

**Architecture Studio v1.4.0 is a breaking migration release.** It preserves the project’s public `1.x` release sequence while replacing the installed plugin identity and introducing the studio/project workspace architecture described below.

- **A framework firms can extend.** Create firm-wide and project-specific skills that remain in the user-owned workspace and survive plugin updates.
- **Working AEC reference implementations.** Bundled skills and agents demonstrate governed patterns for research, calculations, project records, provenance, and professional review.
- **Local studio workspace.** `/as:studio` initializes user-owned settings, a project registry, firm skills, and an empty connector boundary without creating an ALPA account or cloud store.
- **Durable project memory.** `/as:project` owns sourced facts and numbered decisions; meetings, site reports, plans, tasks, and confirmed time remain linked without duplicating canonical records.
- **Extensible practice.** `/as:skill-maker` creates firm-wide or project-specific procedures outside the installed plugin cache.
- **Portable product data.** FF&E uses project-local `product-library.csv`; EPD work remains PDF-first with optional `epd-library.csv` persistence. Google Sheets connectivity and XLS/XLSX support are not part of v1.4.
- **Consent-based support.** `/as:studio-feedback` prepares reports for review without submitting them. Background update checking is disabled by default and can be enabled explicitly during studio setup.
- **One installation, two use modes.** Use any built-in tool immediately, or create a studio workspace when persistent settings and records become useful. Choosing tools-only onboarding creates no workspace; a tool may still create the output you explicitly request.

Full history is in the [CHANGELOG](./CHANGELOG.md).

## Architecture

ARCHITECTURE STUDIO PLUGIN                    USER-OWNED STUDIO
─────────────────────────                    ─────────────────

skills-for-architects/                       studio/
│                                            │
├── rules/          GOVERNANCE               ├── STUDIO.md
├── hooks/                                   ├── CLAUDE.md
│                                            ├── .mcp.json
├── skills/         REFERENCE TOOLING        ├── .claude/skills/
├── agents/         REFERENCE ORCHESTRATION  │       FIRM EXTENSIONS
│                                            ├── TASKS.md (optional portfolio mode)
└── schema/         DATA CONTRACTS           └── projects/
                                                 └── project/
                                                     ├── PROJECT.md
                                                     ├── decisions/
                                                     ├── meetings/
                                                     ├── site-reports/
                                                     ├── docs/plans/
                                                     ├── TASKS.md (default project mode)
                                                     ├── TIMELOG.md
                                                     ├── product-library.csv
                                                     ├── epd-library.csv
                                                     └── .claude/skills/
                                                             PROJECT EXTENSIONS
```

Architecture Studio supplies the framework, governance, and maintained reference implementations. The user-owned studio is where a firm’s own practice layer grows. Studio memory, custom skills, and resulting work products remain local files; plugin updates replace plugin code without silently taking ownership of that workspace.

**Governance** establishes defaults, professional boundaries, evidence practices, and consent. **Tooling** applies those constraints through skills, agents, and workflows. **Memory** preserves studio and project context as linked plain files. Read the complete [workspace and memory model](./docs/workspace-model.md) and [data-governance boundary](./docs/data-governance.md).

## Extend Architecture Studio

Architecture Studio separates maintained plugin capabilities from the procedures a firm creates for itself:

| Layer | Location | Purpose |
|-------|----------|---------|
| Bundled reference skills | Installed plugin | Working AEC tools, examples, and reusable patterns maintained upstream |
| Studio skills | `studio/.claude/skills/` | Firm standards, internal procedures, shared templates, and practice-specific workflows |
| Project skills | `projects/<project>/.claude/skills/` | Client-, jurisdiction-, delivery-, or project-specific procedures |
| Upstream contributions | This repository | General-purpose capabilities proposed for the open-source project |

`/as:skill-maker` helps turn a firm procedure into a structured skill at the correct ownership level. It follows Architecture Studio’s governance, provenance, and testing patterns without writing into the installed plugin cache.

## Quick start

### Install

**Claude:** Open **Customize → Plugins → + → Add marketplace**, choose a repository source, enter `AlpacaLabsLLC/skills-for-architects`, and install **Architecture Studio**. Workspace, hook, and subagent behavior depends on the Claude surface and permissions your organization enables; the workflow below is tested with Claude Code.

**Claude Code:**

```bash
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
claude
```

After Claude Code opens, run:

```text
/as:studio
```

The welcome offers four paths: set up a studio, use the tools without setup, learn with an example, or open an existing studio. Architecture Studio creates no studio, project, ALPA account, cloud store, or git repository until you approve an exact local target.

### Use

Describe a task through the studio entry point. It routes the request to the appropriate skill or agent:

```text
/as:studio task chair, mesh back, under $800
/as:studio 123 Main St, Brooklyn NY
/as:studio I need a space program for 200 people
/as:studio parse this EPD
```

Use `/as:tool-catalog` for the complete menu. You can also select any Architecture Studio command from autocomplete—for example, `/as:environmental-analysis 123 Main St`. New to Claude Code? Start with `/as:learn`.

`as` is the technical plugin namespace for Architecture Studio. Copyable plugin commands combine that namespace with a skill name—for example, `/as:site-history`. Claude Code autocomplete may show a shorter label when it is unambiguous, but the namespaced form is the public documentation contract.

### Upgrading to v1.4.0 (reinstall required)

Architecture Studio v1.4.0 changes the installable plugin identifier from `architecture-studio` to `as`. Refreshing the marketplace alone does not replace the old identity.

**If you installed v1.3.0:**

```bash
claude plugin marketplace update skills-for-architects
claude plugin uninstall architecture-studio@skills-for-architects
claude plugin install as@skills-for-architects
```

**If you installed v1.2.1 or earlier:** uninstall any numbered Architecture Studio plugins you installed, then update the marketplace and install `as`:

```bash
for p in 00-due-diligence 01-site-planning 02-zoning-analysis 03-programming \
         04-specifications 05-sustainability 06-materials-research \
         07-presentations 08-dispatcher 09-project-dossier; do
  claude plugin uninstall "$p@skills-for-architects"
done
claude plugin marketplace update skills-for-architects
claude plugin install as@skills-for-architects
```

Reload plugins or restart Claude Code and confirm that only `as@skills-for-architects` is installed. Run `/as:studio` to use the built-in tools, create a studio, or reopen a studio created while testing the prerelease. Reinstalling changes plugin code only: it does not delete or rewrite project folders, `PROJECT.md`, decision records, custom skills, or user-owned studio files.

If an existing project uses the v1.x `PROJECT.md` Decisions table, open that project and run `/as:project migrate`. Review the proposed migration before approving it; reinstalling the plugin does not migrate project records automatically.

If you manually added the old identifier to a Claude settings file, replace only the settings key or entry `architecture-studio@skills-for-architects` with `as@skills-for-architects`. Architecture Studio does not edit Claude settings automatically.

Existing local welcome and update-check preferences remain in place because their stable `.architecture-studio-*` filenames and state location do not change with the plugin identifier.

### Three ways to use Architecture Studio

- **Use the references.** Invoke the bundled skills and agents as installed. No studio workspace is required. Selecting tools-only onboarding creates no workspace files; an invoked tool may create only the output you ask it to produce.
- **Build your practice layer.** Create a studio when you want persistent settings, linked projects, and firm- or project-specific skills.
- **Contribute upstream.** Generalize a capability that benefits other practices and propose it to the open-source project.

All three paths use the same plugin architecture. You can begin with the reference tools and create a studio later without migration or cleanup.

### Claude Code dependency

To use Architecture Studio with Claude Code, open the terminal available on your operating system and install Claude Code by following the current [Claude Code setup instructions](https://code.claude.com/docs/en/setup). Then launch Claude Code, run the two plugin commands under **Install** above, and invoke `/as:studio`. The optional `/as:learn` course begins after Claude Code is running.

## Bundled reference agents

Agents are working orchestration examples as well as immediately usable tools. Describe your task and the agent decides which skills to call, in what order, and where professional judgment is required.

| Agent | Domain | What it does |
|-------|--------|--------------|
| [site-planner](./agents/site-planner.md) | Site planning | Runs separate environmental, mobility, demographic, and history streams before synthesis |
| [nyc-zoning-expert](./agents/nyc-zoning-expert.md) | Due diligence + zoning | Combines NYC property research, zoning analysis, buildable envelope, and visualization |
| [workplace-strategist](./agents/workplace-strategist.md) | Programming | Translates headcount and work style into occupancy-informed programs and room schedules |
| [product-and-materials-researcher](./agents/product-and-materials-researcher.md) | Materials research | Finds products, extracts specifications, classifies data, and identifies alternatives |
| [ffe-designer](./agents/ffe-designer.md) | FF&E design | Builds schedules and room packages, performs QA, and prepares dealer interchange |
| [sustainability-specialist](./agents/sustainability-specialist.md) | Sustainability | Researches EPDs, compares GWP, checks eligibility, and prepares specification thresholds |
| [brand-manager](./agents/brand-manager.md) | Presentations | Builds decks, creates palettes, and checks deliverables for presentation readiness |

See the [agents index](./docs/agents.md) for complete workflows and handoff logic.

## Bundled reference skills

All bundled skills live in one flat catalog and install together. They make Architecture Studio useful immediately and provide concrete patterns firms can build from; they do not define the limits of the system or prescribe one firm’s way of practicing. These groups describe their role in practice, not separate plugins.

| Layer | Group | Description |
|-------|-------|-------------|
| Firm operations | Dispatcher | Studio setup and routing, the tool menu, skill creation, and reviewed feedback |
| Firm operations | Learn | Guided, resumable introduction to Claude Code for architects |
| Project management | Project records | Facts, decisions, `/as:workplan`, meetings, site reports, tasks, and confirmed time |
| Practice and design | Due diligence | NYC landmarks, permits, violations, ownership, housing, and BSA records |
| Practice and design | Site planning | Environmental, mobility, demographic, and site-history research |
| Practice and design | Zoning analysis | NYC zoning analysis and interactive buildable-envelope visualization |
| Practice and design | Programming | Workplace programs, occupancy loads, egress, and plumbing fixtures |
| Practice and design | Specifications | CSI outline specifications with professional-review markers |
| Practice and design | Sustainability | EPD parsing, research, comparison, and GWP requirements |
| Practice and design | FF&E and materials | Product research, extraction, cleanup, schedules, imagery, CSV, and SIF |
| Practice and design | Presentations | Slide decks, color palettes, and image preparation |

Browse the [complete tooling catalog](./skills/README.md) for every command, input, output, and supporting skill document.

## Rules

Cross-cutting conventions shape every skill’s output. Two are hook-enforced; five are advisory references carried by the skills and agents that need them.

| Rule | What it governs |
|------|-----------------|
| [units-and-measurements](./rules/units-and-measurements.md) | Imperial and metric defaults, area types, and dimensions |
| [code-citations](./rules/code-citations.md) | Edition years, jurisdiction awareness, and building-code references |
| [professional-disclaimer](./rules/professional-disclaimer.md) | Required disclaimer language and limits on regulated output |
| [csi-formatting](./rules/csi-formatting.md) | MasterFormat section numbers and three-part structure |
| [terminology](./rules/terminology.md) | AEC terminology, abbreviations, and material names |
| [output-formatting](./rules/output-formatting.md) | Tables, source attribution, file naming, and list structure |
| [transparency](./rules/transparency.md) | Visible inputs, assumptions, calculations, and sources |

See the [rules index](./rules/README.md) for the enforcement boundary.

## Hooks

Event-driven automations ship with the plugin and register when it is enabled. No manual settings merge is required.

| Hook | Event | What it does |
|------|-------|--------------|
| [session-start-welcome](./hooks/session-start-welcome.sh) | First session after install | Confirms that built-in tools are ready and points to optional studio setup and learning |
| [post-write-disclaimer-check](./hooks/post-write-disclaimer-check.sh) | After Write or Edit | Flags marked regulatory output that is missing the professional disclaimer |
| [pre-commit-spec-lint](./hooks/pre-commit-spec-lint.sh) | Before git commit | Flags malformed CSI section numbers |
| [version-check](./hooks/version-check.sh) | Enabled startup sessions, at most daily | Checks for a newer release only after explicit opt-in |

Background update checking is disabled by default. If enabled, it makes at most one bare request per 24 hours to `version.alpa.llc`, sends no project content or Architecture Studio identifier, and fails silently. Cloudflare still processes ordinary request metadata such as IP address, headers, and timestamps.

See the [hooks index](./hooks/README.md) for behavior and customization.

## Data and privacy

Architecture Studio runs inside the user’s own Claude or Claude Code session. Model-side data controls, retention, and account or organization policies remain managed directly between the user and Anthropic; available settings depend on the Anthropic account, plan, and administrator policy. Review and manage those controls through Anthropic’s [Privacy Center](https://privacy.claude.com/) and the settings provided for the user’s Claude account or organization.

- Architecture Studio does not upload or store studio or project records with ALPA.
- Prompts and files sent to the configured LLM are handled under that provider account and its data terms.
- Research skills contact the public sources named in their documentation when the user runs them.
- New studios reserve `.mcp.json` with an empty `mcpServers` object. Architecture Studio does not select providers, configure OAuth, or bundle credentials.
- `/as:studio-feedback` prepares fields locally. Opening the prefilled GitHub URL sends the displayed query parameters immediately; Architecture Studio never submits the issue.

Read the complete [data-governance documentation](./docs/data-governance.md).

## Extend your own studio

Firms can create private studio and project skills without forking this repository. Those skills live in the user-owned workspace, can follow internal standards, and are not overwritten by plugin updates. Start with `/as:skill-maker` and choose the studio or project destination.

## Contribute upstream

When a capability has value across practices, it can be proposed to the shared plugin. A strong upstream skill contains no firm or client secrets, has clear inputs and outputs, preserves provenance and professional-review boundaries, and includes representative tests or examples.

Read [CONTRIBUTING.md](./CONTRIBUTING.md) before proposing a skill or changing a shared contract. Repository conventions live in [PATTERNS.md](./PATTERNS.md), and shared data contracts live in [`schema/`](./schema).

Firms preparing a controlled pilot should also read the concise [firm deployment guide](./docs/firm-deployment.md) for ownership, access, backup, rollout, and incident responsibilities.

For guidance on organizing skills across a team, read [Distributing Skills to Teams](https://alpa.llc/articles/distributing-skills-to-teams).

## License

MIT—see [LICENSE](LICENSE).

---

Built by [ALPA](https://alpa.llc)—research, strategy, and technology for the built environment.

**Read more:** [Claude Code Cheat Sheet for Architects](https://alpa.llc/articles/claude-code-cheat-sheet) · [Distributing Skills to Teams](https://alpa.llc/articles/distributing-skills-to-teams)
