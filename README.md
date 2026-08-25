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

> A local-first framework for architecture firms to build, govern, and share their own AI-assisted workflows—use with [Codex](https://developers.openai.com/codex/) or [Claude Code](https://code.claude.com/docs).

**Architecture Studio** provides a governance layer, persistent studio and project memory, and clear extension points for firm-wide and project-specific skills. The bundled AEC skills and agents are working reference implementations and starting templates: use them directly, study their patterns, or build procedures that reflect how your own practice works.

Firm-created skills remain in the user-owned studio workspace, outside the installed plugin cache. They can stay private to a firm or project, or be developed for contribution back to the open-source project.

**One plugin**—`as` v1.5.0—with a shared skill catalog for Codex and Claude Code. The repository contains **5 hooks**: Claude Code loads four handlers across three events, while Codex loads one ambient `SessionStart` hook. Claude Code also loads **7 agents** and **7 rules**. Created by Federico Negro in 2026 and built by [ALPA](https://alpa.llc) (`hello@alpa.llc`). Copyright © 2026 Alpaca Design Lab LLC; MIT-licensed.

## What’s new in 1.5.0

This branch adds a read-only, source-backed architecture-knowledge skill for shared US professional-practice vocabulary. Ask `$architecture-knowledge` on Codex or `/as:architecture-knowledge` on Claude Code about terms such as “CD set,” AIA document relationships, or CSI/NCS context. It gives concise orientation with sources and boundaries rather than contract text, legal interpretation, or project-specific conclusions.

The workspace migration from format 2 to format 3 is breaking, not a compatible patch update. Version 1.5.0 gives universal projects durable identity and moves commercial records into their owning project; release remains gated on dogfood validation of migration and rollback behavior.

## What’s new in 1.4.3

A maintenance patch. `scripts/audit-skill-context.sh` now reads skill descriptions with the YAML parser instead of reconstructing them, correcting six frontmatter forms that were measured wrong — most visibly a plain multi-line description, which reported zero characters. No bundled skill used an affected form, so every published measurement is unchanged and no skill, record format, or command behavior moves. Upgrading from 1.4.2 requires nothing.

## What’s new in 1.4.2

Architecture Studio v1.4.2 adds Codex as a supported host without changing the `as` plugin identity or the user-owned studio/project record formats introduced in v1.4.

- **Codex-native packaging.** `.codex-plugin/plugin.json` and the Git marketplace entry let Codex install the repository as `as@skills-for-architects`.
- **Cross-harness skills.** Every bundled skill maps Claude Code's `/as:<skill>` syntax to Codex's `$<skill>` syntax and resolves bundled scripts from the loaded skill path instead of a Claude-only environment variable.
- **Portable workspaces.** Studio and project scaffolds create `AGENTS.md` plus `.agents/skills/` for Codex alongside the existing Claude Code files.
- **Preserved boundaries.** Claude-specific agents and hooks remain available on Claude Code; Codex loads the shared skills and the same local project-record contracts.

Full history is in the [CHANGELOG](./CHANGELOG.md).

## Architecture

```text
ARCHITECTURE STUDIO PLUGIN                    USER-OWNED STUDIO
─────────────────────────                    ─────────────────

skills-for-architects/                       studio/
│                                            │
├── .codex-plugin/  CODEX PACKAGE            ├── STUDIO.md
├── .claude-plugin/ CLAUDE PACKAGE           ├── AGENTS.md + CLAUDE.md
├── rules/          GOVERNANCE               ├── .mcp.json
├── hooks/          CLAUDE AUTOMATION        ├── .agents/skills/
├── skills/         SHARED TOOLING           ├── .claude/skills/
├── agents/         CLAUDE ORCHESTRATION     │       FIRM EXTENSIONS
│                                            ├── standards/
│                                            ├── references/
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
                                                     ├── .agents/skills/
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
| Studio skills | `studio/.agents/skills/` (Codex) or `studio/.claude/skills/` (Claude Code) | Firm standards, internal procedures, shared templates, and practice-specific workflows |
| Project skills | `projects/<project>/.agents/skills/` or `.claude/skills/` | Client-, jurisdiction-, delivery-, or project-specific procedures |
| Upstream contributions | This repository | General-purpose capabilities proposed for the open-source project |

`/as:skill-maker` helps turn a firm procedure into a structured skill at the correct ownership level. It follows Architecture Studio’s governance, provenance, and testing patterns without writing into the installed plugin cache.

## Quick start

### Install

**Codex:** add the Git marketplace, install the plugin, and start Codex:

```bash
codex plugin marketplace add AlpacaLabsLLC/skills-for-architects
codex plugin add as@skills-for-architects
codex
```

Then invoke the dispatcher:

```text
$studio
```

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

The dispatcher offers paths to set up a studio, use the tools without setup, open an existing studio, or learn on a fictional practice project. Start the course with `$learn` on Codex or `/as:learn` on Claude Code. Architecture Studio creates no studio, project, ALPA account, cloud store, or git repository until you approve an exact local target.

### Use

Describe a task through the studio entry point. It routes the request to the appropriate skill; on Claude Code it can also route to the bundled agents:

```text
# Codex
$studio task chair, mesh back, under $800
$studio 123 Main St, Brooklyn NY

# Claude Code
/as:studio task chair, mesh back, under $800
/as:studio 123 Main St, Brooklyn NY
```

Use `$tool-catalog` on Codex or `/as:tool-catalog` on Claude Code for the complete menu. You can also invoke a skill directly—for example, `$environmental-analysis 123 Main St` on Codex or `/as:environmental-analysis 123 Main St` on Claude Code. New to AI-assisted project work? Start with `$learn` on Codex or `/as:learn` on Claude Code.

`as` is the technical plugin namespace for Architecture Studio. Claude Code commands combine that namespace with a skill name, such as `/as:site-history`. Codex mentions the installed skill directly as `$site-history`.

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

- **Use the references.** Invoke the bundled skills as installed; Claude Code also exposes the native agents. No studio workspace is required. Selecting tools-only onboarding creates no workspace files; an invoked tool may create only the output you ask it to produce.
- **Build your practice layer.** Create a studio when you want persistent settings, linked projects, and firm- or project-specific skills.
- **Contribute upstream.** Generalize a capability that benefits other practices and propose it to the open-source project.

All three paths use the same plugin architecture. You can begin with the reference tools and create a studio later without migration or cleanup.

### Host setup

For Codex, follow the current [Codex setup documentation](https://developers.openai.com/codex/) and the Codex install commands above. For Claude Code, follow the current [Claude Code setup instructions](https://code.claude.com/docs/en/setup), then run the marketplace and plugin commands above. Invoke `$studio` on Codex or `/as:studio` on Claude Code. The bundled course is available as `$learn` on Codex and `/as:learn` on Claude Code; it clearly branches where Claude-native agents, hooks, and `/clear` have no Codex equivalent.

## Bundled reference agents

These seven native agents are available on Claude Code. Codex users can run the same underlying skills directly or through `$studio`; the Codex package does not register the Claude agent files as Codex roles.

Agents are working orchestration examples as well as immediately usable Claude Code tools. Describe your task and the agent decides which skills to call, in what order, and where professional judgment is required.

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
| Firm operations | Learn | Guided, resumable introduction to Codex and Claude Code for architects |
| Project management | Project records | Facts, decisions, `/as:workplan`, meetings, site reports, tasks, and confirmed time |
| Project management | Commercial records | Project-local proposals with protected issued terms, optional agreement context with an advisory scope guard, and append-only invoice ledgers |
| Professional practice | Architecture knowledge | Source-backed US vocabulary for phases, CD terminology, AIA relationships, and CSI/NCS context |
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
| [csi-formatting](./rules/csi-formatting.md) | Limited MasterFormat 2020 compatibility baseline and edition-neutral three-part organization |
| [terminology](./rules/terminology.md) | Style and first-use conventions; architecture knowledge is linked from the rule |
| [output-formatting](./rules/output-formatting.md) | Tables, source attribution, file naming, and list structure |
| [transparency](./rules/transparency.md) | Visible inputs, assumptions, calculations, and sources |

See the [rules index](./rules/README.md) for the enforcement boundary.

## Hooks

These event-driven automations are Claude Code-specific. They register with the Claude package when it is enabled; the Codex manifest intentionally omits them.

| Hook | Event | What it does |
|------|-------|--------------|
| [session-start-welcome](./hooks/session-start-welcome.sh) | First session after install | Confirms that built-in tools are ready and points to optional studio setup and learning |
| [post-write-disclaimer-check](./hooks/post-write-disclaimer-check.sh) | After Write or Edit | Flags marked regulatory output that is missing the professional disclaimer |
| [pre-commit-spec-lint](./hooks/pre-commit-spec-lint.sh) | Before git commit | Flags malformed CSI section numbers |
| [version-check](./hooks/version-check.sh) | Enabled startup sessions, at most daily | Checks for a newer release only after explicit opt-in |

Background update checking is disabled by default. If enabled, it makes at most one bare request per 24 hours to `version.alpa.llc`, sends no project content or Architecture Studio identifier, and fails silently. Cloudflare still processes ordinary request metadata such as IP address, headers, and timestamps.

See the [hooks index](./hooks/README.md) for behavior and customization.

## Data and privacy

Architecture Studio runs inside the user's own Codex or Claude Code session. Model-side data controls, retention, and account or organization policies remain managed by the selected provider. Review OpenAI's [privacy policy](https://openai.com/policies/privacy-policy/) for Codex or Anthropic's [Privacy Center](https://privacy.claude.com/) for Claude, together with the settings and administrator policies for the active account.

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
