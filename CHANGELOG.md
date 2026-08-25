# Changelog

All notable changes to **Architecture Studio** (`AlpacaLabsLLC/skills-for-architects`) are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Architecture Studio uses a sequential `major.minor.patch` release scheme, marks breaking migrations explicitly, and reserves patch releases for compatible corrections.

## [Unreleased]

## [1.5.0] - 2026-08-28

### Breaking

- **Universal project and commercial records.** Version 1.5.0 introduces an explicit workspace migration from format 2 to format 3, gives every internal or client project one durable identity, and keeps proposals, agreement context, and invoice ledgers inside that project. This migration is not patch-compatible and remains release-gated on dogfood validation of migration and rollback behavior. Status and scope context remain advisory and user-directed.

### Added

- **Architecture knowledge.** Added the read-only `$architecture-knowledge` / `/as:architecture-knowledge` skill with a compact, source-backed US professional-practice corpus for phases, CD terminology, roles, delivery methods, high-level AIA family relationships, and CSI/NCS context. It supplies original summaries and source links only; it does not reproduce licensed material, select forms, interpret clauses, or decide project obligations.
- **Commercial workflows.** Added project-owned proposal, agreement, SOW, amendment, and invoice workflows with previewed mutations, issued-record preservation, advisory scope checks, billing-period gap detection, and running Maximum Total Cost context.
- **Codex session ambience.** Added one stateless, local `SessionStart` hook that supplies compact Architecture Studio routing context for Codex on macOS. It performs no reads, writes, networking, installation, or persistent-state changes, and remains subject to Codex's native hook-trust review.

### Changed

- **CSI edition clarity.** The specification writer retains its limited MasterFormat 2020 compatibility mapping while shared terminology records current CSI edition context separately and requires project-edition verification for applied work.
- **Release governance.** Added a canonical release checklist and cross-host repository-local maintainer skill covering scope and tracker disposition, version surfaces, verification, immutable tagging, post-release correction, and role-specific credit for issue reporters, investigators, workaround confirmers, implementers, and substantive reviewers.

## [1.4.3] - 2026-08-13

### Fixed

- `scripts/audit-skill-context.sh` now reads the description with the YAML parser instead of reconstructing it in AWK. A frontmatter description may be inline, quoted, folded, literal, or a plain multi-line scalar, and each form folds, chomps, and strips comments by its own rules. Six were measured wrong: a bare `description:` followed by indented continuation lines reported zero characters, a trailing `#` comment was counted as description text, a full-line comment likewise, a blank line inside a plain scalar folded to a space rather than a newline, a multi-line quoted scalar was truncated at its first line, and clip-chomped `>` and `|` scalars lost their final line break. Lengths are still byte lengths under `LC_ALL=C`, so every measured total is unchanged and `docs/reports/v1-4-skill-context-optimization.md` still reconciles exactly. PyYAML is now required to run the audit; it is already installed in CI for `scripts/lint.sh`. The script also accepts an optional skills root, which lets the parser be tested against fixtures, and `tests/test-context-audit-description-styles.sh` covers all sixteen description forms.

## [1.4.2] - 2026-08-10

### Added

- Added `.codex-plugin/plugin.json` and a repository Git marketplace at `.agents/plugins/marketplace.json`, allowing Codex to install Architecture Studio as `as@skills-for-architects`.
- Added Codex `AGENTS.md` templates and `.agents/skills/` roots to new studio and project workspaces alongside the existing Claude Code files.
- Added a Codex compatibility contract test covering manifests, marketplace metadata, skill portability, workspace scaffolds, and documented installation commands.

### Changed

- All bundled skills now translate Architecture Studio invocation syntax by host: `$skill-name` on Codex and `/as:skill-name` on Claude Code.
- Bundled scripts and references resolve from the loaded skill path through portable `<skill-root>` and `<plugin-root>` placeholders instead of requiring Claude-only environment variables.
- Skill Maker now targets `.agents/skills/` on Codex and `.claude/skills/` on Claude Code while preserving catalog, studio, project, and global ownership boundaries.
- Installation, data-governance, deployment, workspace, and contribution documentation now distinguishes the shared skill catalog from Claude Code-only native agents and hooks.

### Compatibility

- The studio/project record formats and `as` plugin identity are unchanged. Existing v1.4 workspaces remain valid; new scaffolds add empty Codex instruction and skill roots without moving or duplicating existing Claude Code skills.
- The bundled course is available as `$learn` on Codex and `/as:learn` on Claude Code. Its shared exercises preserve the six-module progress format while clearly branching for Codex's `AGENTS.md`, `.agents/skills/`, and new-session surfaces versus Claude Code's `CLAUDE.md`, `.claude/skills/`, and `/clear`; Claude-native agents and hooks remain unavailable on Codex.

## [1.4.1] - 2026-07-29

### Fixed

- `scripts/lint.sh` and `scripts/check-plugin-namespace.py` now read repository files as UTF-8 explicitly, and `lint.sh` exports `PYTHONIOENCODING=utf-8` for the Python processes it starts. Both previously relied on Python's platform default encoding, which is cp1252 on Windows, where eight of the fourteen lint checks aborted: reading a document containing box-drawing or em-dash characters raised `UnicodeDecodeError`, and printing a `✓` status mark raised `UnicodeEncodeError`. Linux and macOS behavior is unchanged. `tests/test-lint-untracked.sh` passes on Windows as a result.

## [1.4.0] - 2026-07-26

Architecture Studio v1.4.0 is a breaking migration release. It preserves the public `1.x` release sequence while replacing the installed plugin identity and introducing the studio/project workspace architecture.

### Breaking

- **Shorter technical namespace.** Architecture Studio now installs as `as@skills-for-architects`, and public commands use `/as:<skill>`. Existing users must remove the retired v1 install or installs, update the marketplace, install `as@skills-for-architects`, and reload plugins or restart Claude Code. User-owned project and workspace files are untouched. Manually maintained Claude settings must replace only the old plugin identifier with the new one.
- **One project-memory interface.** `/as:project` replaces `/as:project-dossier` and `/decision`; no compatibility aliases remain. Use `/as:project init`, `/as:project update` or `/as:project remember`, `/as:project decisions`, `/as:project record-decision`, and `/as:project supersede`.
- **Decision files are canonical.** `PROJECT.md` no longer maintains a Decisions table. Run `/as:project migrate` in an existing 1.x project; migration removes the table only after every row matches a decision file.

### Migration

Existing v1.3 users must update the `skills-for-architects` marketplace, uninstall `architecture-studio@skills-for-architects`, install `as@skills-for-architects`, and reload plugins or restart Claude Code. The reinstall changes plugin code only; it does not delete or rewrite user-owned project or workspace files.

Users moving directly from v1.2 or earlier should uninstall any installed numbered plugins (`00-due-diligence` through `09-project-dossier`), update the marketplace, and install `as@skills-for-architects`. They do not need to install v1.3 first.

After reinstalling, run `/as:studio`. If an existing project uses the v1.x `PROJECT.md` Decisions table, open that project and run `/as:project migrate`; review the proposed migration before approving it. Plugin reinstall does not migrate project records automatically.

Existing local welcome and update-check preferences remain in place because their stable `.architecture-studio-*` filenames and state location do not change with the plugin identifier.

### Architecture and extensibility

- **User-reviewed feedback** — `/as:studio-feedback` prepares minimal bug or feature fields, flags sensitive project information, explains that opening GitHub transmits the displayed URL parameters, and never submits an issue automatically.
- **GitHub issue forms** — bug and feature templates share exact field identifiers with `/as:studio-feedback` so users arrive at an editable, prefilled report.
- **Opt-in update notice** — update checking remains disabled until enabled through `/as:studio`; when enabled it is throttled to one bare request per day, fails silently, and notifies once per newer version.
- **Studio workspace setup** — `/as:studio init`, `/as:studio status`, `/as:studio projects`, `/as:studio create-project`, `/as:studio register-project`, and `/as:studio archive-project` manage a portable `STUDIO.md` registry and descendant project folders. Setup records working units, default country/state-or-region/city, and a plain-language data-governance boundary.
- **Firm-owned skills** — initialized studios include `.claude/skills/`, and `/as:skill-maker` defaults private firm procedures there from descendant projects.
- **Deterministic setup helpers and fixtures** — studio/project scaffolding, collision refusal, registration, archive, and lossless project migration have executable shell coverage.
- **Agent documentation moved outside `agents/`** so Claude registers exactly the seven intended native subagents rather than treating the former index README as an eighth agent.

### Data boundaries and onboarding

- **Lightweight onboarding** — running `/as:studio` displays the Architecture Studio mark, creator, ALPA ownership/contact, license, and repository provenance before moving into setup. Setup uses one structured interaction gate per question or confirmation instead of asking once in prose and again in the UI. The first-session hook is now a concise visible discovery notice rather than an instruction that rewrites the user’s first response.
- **Project-record integrations** — meeting minutes, site reports, analysis skills, work plans, tasks, and time tracking hand facts and decisions to `/as:project` and discover decision files directly.
- **Installation remains non-mutating** — installing the plugin creates no user workspace, account, cloud store, git repository, or project files.
- **Local CSV product data** — `product-library.csv` is the sole persistent FF&E library; EPD parsing remains PDF-first, with `epd-library.csv` created only when the user explicitly saves reusable records. SIF conversion remains available as bounded interchange, not as the persistent schedule source.
- **Honest legacy migration** — existing `master-schedule.json` and `canoa.json` files are preserved as cloud-configuration evidence. Users export their former cloud rows to CSV before import; Architecture Studio does not claim to migrate disconnected data.
- **Reserved connector boundary** — `/as:studio init` creates a root `.mcp.json` containing only an empty `mcpServers` object. It configures no provider, endpoint, credential, or OAuth flow, and projects do not receive MCP manifests.
- **Deferred formats and integrations** — XLS/XLSX product support and configured studio connectors remain outside v1.4.
- **Privacy disclosure** — documents the feedback transmission boundary and ordinary Cloudflare request metadata without treating endpoint traffic as anonymous users or daily active users.

### Project workflow and memory

- **Typed project-record workflow** — `/as:meeting-minutes` preserves discussion and promotion candidates, `/as:site-visit-report` separates observation from reported information and interpretation, `/as:tasklist` owns permanent action IDs and lifecycle history, and `/as:timetracker` reconstructs dated activity while requiring user-confirmed durations.
- **Linked record graph** — project facts, decisions, minutes, site reports, tasks, plans, and time entries remain independently owned, project-relative artifacts with explicit source links and non-destructive histories.

- **`/as:workplan` project context** — reads and cites relevant `PROJECT.md` facts, decision records, meetings, site reports, and tasks; decided records constrain plans, proposed decisions remain unresolved, and superseded decisions remain historical context.
- **`/as:studio` routing and `/as:tool-catalog` discoverability** — typed-record deliverables route to their owning skills, while an explicitly requested plan or coordination strategy retains `/as:workplan` precedence.
- **Project Dossier documentation renamed Project Records** to describe the connected workflow without implying one central record or database.

- **`/as:workplan`** — a self-contained, Markdown-only planning workflow for repository, operational, and AEC project-delivery work. It distinguishes work planning from floor plans and regulated analysis, separates facts from assumptions, traces requirements and decisions into verifiable work units, uses optional harness capabilities only when available, and stops at an explicit execution handoff.

### Learning and extension tooling

- **`/as:skill-maker`** — scaffold a new skill in three steps, no interview: copy the canonical bundled template, apply the PATTERNS.md checklist (read at runtime, single source), verify with `scripts/lint.sh` inside the catalog or a portable checklist outside it.
- **Post-install discovery** — a `SessionStart` hook (`session-start-welcome`) emits one concise notice that `/as:studio` and `/as:learn` are available, without changing the user’s first response. Together with the opt-in version notice, Architecture Studio now has four hook handlers across three events.
- **`/as:learn` teaches three framing concepts** threaded through the course: this version stores project files locally while sending prompts and needed file contents to the configured Claude service, Architecture Studio is an open-source harness on Claude Code, and course/project memory is plain markdown files — with an explicit markdown explainer at the first file creation. Future cloud-based versions may require accounts and use a different data model.
- **Terminal preflight** in the README — a hand-to-a-colleague page covering install → login → `/as:learn` for people who have never opened a terminal.

- **`/as:learn` restructured to six modules named for their lessons** (How we interact with each other · Nothing without your "yes" · Let's set some guidelines first · Plan first, build second · Creating your own skills · Get started) for an honest ~75-minute core plus a 30–60 min capstone. Plan mode, subagents, and the precedent study moved to a planned advanced track. Data privacy is taught in Module 2 alongside consent; Module 6 opens with a source-check and absence drill on a faithful summary (no planted errors), then a professional checklist offered but never imposed (firm data-governance policy, low-stakes project, work on a copy) and one real task; quitting /learn is honored immediately at any point. The deliverable thread is a site-visit report and a learner-built `/site-report` skill. The five sandbox project types were replaced by a single project — a fictional Brooklyn art museum expansion — one example path, same engineered flaws. Permission-prompt narration covers the "stop asking" option; the tutor spec itself was cut roughly in half. Old 0-indexed PROGRESS.md files migrate by content.
- Starter binder template: "Sign documents off as" → "Document attribution block" (AI documents are never signed or sealed), plus phase names and date-format lines.

### Fixes and optimization

- Clarified `/as:learn` and the welcome hook's data model: this version stores project files locally but sends prompts and needed contents to the configured Claude service; future cloud-based versions may require accounts and use a different model.
- Hardened `/as:skill-maker` target resolution, existing-skill collision handling, bundled-resource paths, and lint coverage for newly generated untracked files.
- Made the first-session welcome verify each bundled surface it reports and persist its one-time marker only after valid context is emitted.
- Removed the Shift+Tab plan-mode instruction (Shift+Tab cycles permission modes and can land in auto-accept — the opposite of the course's safety promise); plan-first is taught as a prompt phrase.
- Removed six stale duplicate sandbox files at the `sandbox/` root left over from the pre-selection layout.

## [1.3.0] - 2026-07-20

### Breaking

- **One plugin.** The 10-plugin marketplace (`00-due-diligence` … `09-project-dossier`) is consolidated into a single flat plugin, **`architecture-studio`** — one install now loads all 40 skills, all 7 agents, and both hooks. `marketplace.json` has a single entry with source `"./"`; the `plugins/` tree and all per-plugin manifests are gone. Existing per-plugin installs will not receive this or any future update — see Migration below.
- **Skill renames** — `skills-menu` → `skills` (help menu, still invoked as `/skills`) and `history` → `site-history` (invoke as `/site-history`, formerly `/history`). All other skill names are unchanged; they simply live flat under `skills/`.
- **`post-output-metadata` hook removed.** The Dispatcher's 3 hooks are now the plugin's 2: `post-write-disclaimer-check` and `pre-commit-spec-lint`, registered from the root `hooks/hooks.json`.

### Migration

Uninstall every old per-plugin install you have, refresh the marketplace, and install the single plugin:

```bash
# Uninstall the old per-plugin installs (skip any you never installed)
for p in 00-due-diligence 01-site-planning 02-zoning-analysis 03-programming \
         04-specifications 05-sustainability 06-materials-research \
         07-presentations 08-dispatcher 09-project-dossier; do
  claude plugin uninstall "$p@skills-for-architects"
done

# Refresh and install the one plugin
claude plugin marketplace update skills-for-architects
claude plugin install architecture-studio@skills-for-architects
```

Everything the ten plugins provided is included; no skill was dropped. **Community-marketplace maintainers:** listings that pin a pre-1.3.0 commit or reference `plugins/<name>` source paths no longer resolve — re-pin to the `v1.3.0` tag and replace the ten entries with the single `architecture-studio` entry (source `"./"`).

### Added

- **`/learn`** — a guided, resumable Claude Code course for architects: eight hands-on modules on a bundled sandbox project, a starter `CLAUDE.md` template distilled from the studio rules, and three example skills to study and modify. Progress persists in `PROGRESS.md`.
- **`/learn` sandbox choice** — the course opens with a menu of five fictional practice projects (Brooklyn loft conversion, healthcare campus, workplace fit-out, restaurant, ground-up school), each with the same six deliberately messy files and identical planted flaws, so every module works on any of them. All characters are roles (the owner, the zoning consultant) — no invented names.
- **`/learn` progress bar** — a 24-cell ASCII bar in the return check-in and after each completed module.
- **`/studio` → `/learn`** — the router now sends users who are new to Claude Code to the course, and the fallback menu points at it.

### Fixed

- **Socrata corrections** (`nyc-property-report` + the six NYC data skills `nyc-acris`, `nyc-bsa`, `nyc-dob-permits`, `nyc-dob-violations`, `nyc-hpd`, `nyc-landmarks`) — `socrata-reference.md` is now the single source of truth; dataset IDs and field names corrected and live-verified against NYC Open Data. New `pluto-resolution.md` documents address→BBL resolution for `nyc-property-report`.
- **Hooks** — `pre-commit-spec-lint` now detects real `git commit` invocations (compound commands, `-C` flags) and exits 2 with the CSI message on stderr; `post-write-disclaimer-check` reads the written file from disk, handles both `Write` and `Edit` tool payloads, and emits proper `{"decision":"block"}` JSON; `hooks.json` drops an invalid `"if"` key and matches `Write|Edit` on PostToolUse. Both scripts are BSD-safe (grep boundaries, `printf` over `echo -e`).
- **Skill-relative data paths** — `occupancy-calculator` reads its bundled `data/*.json` from the skill's own directory instead of a hardcoded `~/.claude/skills/...` path.
- **EPD baseline policy** (`epd-compare`, `epd-to-spec`) — industry-average baselines must be citable (named source + publication year, labeled in the comparison table); uncitable baselines are omitted, never guessed.
- **Zoning and occupancy content** — corrections across `zoning-analysis-nyc`'s zoning-rules references (contextual districts, manufacturing, commercial, residential) and `zoning-envelope`; `occupancy-calculator` gross/net guidance tightened. Smaller doc fixes in `workplace-programmer`, `mobility-analysis`, the EPD skills, and `slide-deck-generator`.

### Changed

- **Disclaimer pipeline wired end-to-end** — all 11 regulatory skills (`zoning-analysis-nyc`, `zoning-envelope`, `occupancy-calculator`, `epd-to-spec`, `nyc-property-report` and its six data skills) now end regulatory output with the canonical disclaimer block plus the `requires-disclaimer` marker the hook checks for; `zoning-envelope` carries an HTML-adapted variant for the 3D viewer. `rules/README.md` no longer claims rules auto-load.
- **Skill descriptions rewritten with trigger + boundary phrasing** across 32 skills — the description is the only signal Claude uses to auto-select among 40 skills.
- **`scripts/lint.sh` rewritten for the flat layout** — count consistency is derived from the tree (skills, agents, hooks, `/skills` menu, README, `marketplace.json`), plus regression checks pinning the 1.3.0 fixes; CI installs its own dependencies.
- **README and `/skills` menu rebuilt for one plugin** — single-entry install, counts derived (40 skills, 7 agents), and the old 00–09 taxonomy kept as documentation-only groups.

## [1.2.1] - 2026-06-10

### Changed

- **README** — "What's New in 1.2" section added below the headline, summarizing the dossier plugin, native subagents, and self-registering hooks; links to the CHANGELOG for full history.

## [1.2.0] - 2026-06-10

### Added

- **`09-project-dossier` plugin** (`1.0.0`) — persistent per-project state as plain files in the project folder. `/project-dossier` maintains `PROJECT.md`, the facts layer (identity, site, zoning, program, code — every entry sourced and dated, updated in place). `/decision` captures the reasoning layer: ADR-style records in `decisions/NNNN-slug.md` with context, options considered, the call, consequences, and a status (proposed / decided / superseded — never deleted, never renumbered). Eleven analysis skills now read the dossier before fetching, append their findings after completing, and propose `/decision` when an analysis forces a choice (zoning path, code edition, GWP threshold). Collaboration is deliberately git-native: files, not infrastructure.
- **Agents register as native Claude Code subagents.** The 7 agents moved from the repo root into their plugins' `agents/` directories with `name`/`description` frontmatter — installing a plugin now registers its agent (automatic delegation, routing by description). `/studio` still routes to them; reading the agent file inline is the documented fallback when a plugin isn't installed. `agents/README.md` remains as the cross-plugin index.
- **Hooks auto-register.** The 3 hooks moved to `plugins/08-dispatcher/hooks/` with a `hooks.json` — enabling the Dispatcher plugin registers them automatically. The manual `settings-snippet.json` merge is retired (users who merged it should remove those entries).

### Changed

- **`slide-deck-generator` restructured for progressive disclosure** — `SKILL.md` 869 → 145 lines; component markup moved to `slide-types.md`, the HTML/CSS/JS template to `html-template.md`, the image workflow to `image-handling.md`, each loaded on demand.
- **4 NYC due-diligence descriptions rewritten** (`nyc-acris`, `nyc-bsa`, `nyc-dob-permits`, `nyc-dob-violations`) with trigger + boundary phrasing — the description is the only signal Claude uses to auto-select among 39 skills.
- **`allowed-tools` added** to the 4 skills missing it: `occupancy-calculator`, `workplace-programmer`, `color-palette-generator`, `slide-deck-generator`.
- **`rules/` enforcement documented honestly** — 2 rules are hook-enforced (disclaimer, CSI), 5 are advisory conventions the skills are written against; nothing auto-loads a `rules/` directory.
- **README** — architecture diagram reflects plugin-native agents and hooks; counts now 39 skills / 10 plugins.

### Removed

- **`user-invocable` frontmatter field** from 25 skills — not part of the current SKILL.md schema; skills are slash-invocable by default. `PATTERNS.md` §1 updated.

## [1.1.3] - 2026-06-10

### Changed

- **README** — release badge added next to the license badge; Materials Research plugin row notes SIF + [Norma](https://norma.llc) export; CHANGELOG linked from Contributing.

## [1.1.2] - 2026-06-10

### Changed

- **`06-materials-research` is standalone** (plugin `1.1.0`). The plugin's config file is renamed `canoa.json` → `master-schedule.json`; `/master-schedule` migrates a legacy `canoa.json` automatically on its next run. `/product-spec-bulk-fetch` now points schedule export at [Norma](https://norma.llc). The Google Sheet workflow itself has no product dependency.
- **NYC zoning terminology** (plugin `02-zoning-analysis` `1.1.1`). `zoning-analysis-nyc`'s reference-file table header and step heading renamed from "Normativa" to "Zoning Rules" / "Rules File".
- **`PATTERNS.md` examples are self-contained.** External-org references removed from the conventions doc (sibling-repo list, naming tables, dispatcher reference implementations, layout names); examples now draw on this repo and canoa only.

## [1.1.1] - 2026-05-08

### Changed

- **`PATTERNS.md` rule #6 expanded.** Versioning discipline now spans three artifacts that must move together on every shipped change: the JSON `version` field (`plugin.json` and/or `marketplace.json` `metadata.version`), a git tag (`git tag -a vX.Y.Z`), and a GitHub release (`gh release create vX.Y.Z --notes-file <changelog-section>`). The rule previously stopped at JSON + CHANGELOG, leaving repo discoverability gaps — `git checkout v1.1.0` didn't resolve, no shareable release URL existed. Backfilled tags + releases for `v1.1.0` (this repo) and `v0.2.0` (canoa).

## [1.1.0] - 2026-05-08

### Added

- **`PATTERNS.md`** — canonical reference for ALPA's plugin and marketplace conventions. Ten principles distilled from canoa V1 and skills-for-architects v1.0: small one-verb skills, dispatcher matching plugin name, `<plugin>-<verb>` naming for single-plugin layouts, marker-driven rules, version bump per ship, public default, MCP bundling via `${CLAUDE_PLUGIN_ROOT}`, hard rules captured from real production bugs. Linked from README. Rule #6 (versioning) covers both `plugin.json` and `marketplace.json` `metadata.version`.
- `.gitignore` covering macOS, editor, and local-env artifacts.
- `scripts/lint.sh` — repo lint script with six structural checks: no tracked `.DS_Store`, JSON validity, SKILL.md frontmatter (`name` + `description` required), count consistency (plugins, per-plugin skill counts, marketplace.json), internal markdown link resolution, and shellcheck on `hooks/*.sh`.
- `.github/workflows/lint.yml` — runs `scripts/lint.sh` on push to `main` and on every PR.

### Changed

- **Disclaimer hook is now marker-driven, not keyword-sniffed.** `rules/professional-disclaimer.md` now requires every regulatory output to end with the canonical disclaimer block followed by `<!-- architecture-studio:requires-disclaimer -->`. The `post-write-disclaimer-check` hook checks for the marker and verifies the canonical block is present, instead of pattern-matching keywords like `FAR`, `setback`, `egress`. This eliminates false positives on non-regulatory documents that mention regulated terms in passing (READMEs, changelogs, meeting notes) and false negatives on terse regulatory replies that happen not to use those keywords.
- **Skill counts now reflect actual file count.** README headline, details summary, plugin table, and the dispatcher's `/skills` menu all read **37 skills** (up from "35"). The 2-skill gap was the dispatcher's `/studio` and `/skills`, which were uncounted by convention. The README catalog now includes a Dispatcher section listing them. `scripts/lint.sh` enforces that headline, details summary, catalog row count, plugin-table per-row counts, skills-menu, and `marketplace.json` plugin list all match the real file count — drift fails CI.

### Removed

- 11 tracked `.DS_Store` files. Now ignored repo-wide via `.gitignore`.

## [1.0.0] - 2026-05-06

First public release.

### Added

- **7 agents** — `site-planner`, `nyc-zoning-expert`, `workplace-strategist`, `product-and-materials-researcher`, `ffe-designer`, `sustainability-specialist`, `brand-manager`.
- **35 skills** across **9 plugins**:
  - `00-due-diligence` (7) — NYC landmarks, DOB permits, DOB violations, ACRIS, HPD, BSA, combined property report.
  - `01-site-planning` (4) — environmental, mobility, demographics, history.
  - `02-zoning-analysis` (2) — `/zoning-analysis-nyc` (PLUTO + Zoning Resolution), `/zoning-envelope` (Three.js 3D viewer).
  - `03-programming` (2) — workplace programmer, IBC occupancy calculator.
  - `04-specifications` (1) — CSI MasterFormat outline specs.
  - `05-sustainability` (4) — EPD parse, research, compare, spec.
  - `06-materials-research` (12) — product research, spec extraction, schedule cleanup, image processing, master schedule, SIF crosswalk.
  - `07-presentations` (3) — slide decks, color palettes, image resizing.
  - `08-dispatcher` (2) — `/studio` router, `/skills` menu.
- **7 rules** — units & measurements, code citations, professional disclaimer, CSI formatting, terminology, output formatting, transparency.
- **3 hooks** — post-write disclaimer check, post-output metadata, pre-commit spec lint.
- Marketplace install: `claude plugin marketplace add AlpacaLabsLLC/skills-for-architects`.

[Unreleased]: https://github.com/AlpacaLabsLLC/skills-for-architects/compare/v1.5.0...HEAD
[1.5.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/compare/v1.4.3...v1.5.0
[1.4.3]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.4.3
[1.4.2]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.4.2
[1.4.1]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.4.1
[1.4.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.4.0
[1.3.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.3.0
[1.2.1]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.2.1
[1.2.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.2.0
[1.1.3]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.1.3
[1.1.2]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.1.2
[1.1.1]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.1.1
[1.1.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.1.0
[1.0.0]: https://github.com/AlpacaLabsLLC/skills-for-architects/releases/tag/v1.0.0
