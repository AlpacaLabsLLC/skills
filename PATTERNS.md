# Architecture Studio extension patterns

This is the canonical reference for extending Architecture Studio and contributing to its maintained Codex and Claude Code plugin. It applies to:

- [`AlpacaLabsLLC/skills-for-architects`](https://github.com/AlpacaLabsLLC/skills-for-architects) — one flat `as` plugin (this repo)
- [`AlpacaLabsLLC/canoa`](https://github.com/AlpacaLabsLLC/canoa) — single-plugin marketplace, AI specifications manager for FF&E
- Any future plugin we ship

The patterns are deliberately opinionated. They emerged from real iteration cycles — we tried alternatives, hit problems, encoded the fixes here. WHY each rule exists is documented inline; treat that as a constraint when judging edge cases.

## 1. Small skills, one verb each

Each skill does one thing. Frontmatter is short, body is focused. If a `SKILL.md` exceeds ~500 lines or starts handling multiple verbs in sequence (onboard + work + audit + write), decompose it into separate skills.

- `name` matches the directory and is kebab-case
- `description` is pushy and trigger-phrase-rich — model invocation depends on it picking your skill out of the dispatcher's pool
- `allowed-tools` is a Claude Code permission hint scoped to what THIS skill needs. Codex uses its own permission model, so portable bodies must name capabilities generically and map host-specific tool names.
- Optional flags: `disable-model-invocation: true` when a skill is slash-only. (Skills are slash-invocable by default; the legacy `user-invocable` flag is not part of the current frontmatter schema and was removed repo-wide in v1.2.0.)

**Why:** smaller skills are easier to test, slash-invoke directly, restrict tool access on, and reason about. Monoliths drift; small skills stay honest. We split canoa's monolithic SKILL.md into 8 verb-scoped skills the same day we couldn't keep `/canoa:start`'s 200-line body internally consistent.

## 2. Clear contracts between skills

Skills hand off via explicit cross-references in their bodies — never via implicit shared state.

- Each skill documents what input it expects, what it produces, what it hands off to next
- Cross-references use the actual slash invocation: "After this completes, run `/canoa-add-to-sheet`"
- Outputs are typed (named JSON schemas, file paths with conventions, not freeform)
- Hard rules that span multiple skills (audit-on-touch, read-before-write) live in the dispatcher AND get repeated in each sub-skill that touches them — never assume the user invoked the dispatcher first

**Why:** designers (and Claude) shouldn't have to remember which skill writes what file or which expects which keys. The contract is in the SKILL.md body, in plain English, with examples.

## 3. Clean naming conventions

| Layer | Format | Example |
|---|---|---|
| Marketplace name | kebab-case product family | `canoa`, `skills-for-architects` |
| Plugin name | kebab-case | `as`, `canoa` |
| Dispatcher skill name | matches plugin name | `canoa`, `studio` |
| Sub-skill name (single-plugin marketplace) | `<plugin>-<verb>` | `canoa-find`, `canoa-audit`, `canoa-add-to-sheet` |
| Architecture Studio skill name | `<verb>`; public docs use the plugin namespace | `nyc-landmarks` → `/as:nyc-landmarks` |

User-facing slash invocation:

- Single-plugin: `/canoa`, `/canoa-find`, `/canoa-audit` (plugin name = dispatcher; sub-skills carry the prefix)
- Multi-plugin: `/<plugin>:<skill>` (Claude Code/Cowork's namespacing) — but mention the family in marketplace docs
- Codex: `$<skill>` after the plugin is installed; plugin namespacing remains package metadata rather than invocation syntax

**Why:** the slash UX should immediately tell the user which product family they're invoking. `/canoa-find` and `/canoa-audit` are obviously a family. `/start` and `/audit` are anonymous.

## 4. A single orchestrator (dispatcher)

Every plugin has ONE entry-point skill (the dispatcher) that:

1. Reads the user's intent (everything after the slash command).
2. Classifies against a routing table.
3. Hands off to the right sub-skill.
4. Falls back to working mode (relay through MCP / agent persona) for ambiguous freeform messages.

The dispatcher is named the same as the plugin (`canoa`, `studio`). Its `SKILL.md` includes:

- A routing table (what intent → which sub-skill)
- A working-mode fallback section (how to handle ambiguous requests)
- Any hard rules that apply globally across all sub-skills

Reference implementations:
- [`AlpacaLabsLLC/canoa/skills/canoa/SKILL.md`](https://github.com/AlpacaLabsLLC/canoa/blob/main/skills/canoa/SKILL.md)
- [`AlpacaLabsLLC/skills-for-architects/skills/studio/SKILL.md`](https://github.com/AlpacaLabsLLC/skills-for-architects/blob/main/skills/studio/SKILL.md)

**Why:** users shouldn't have to memorize which sub-skill handles which intent. The dispatcher does the routing. New users can just type `/canoa` (or `/as:studio`) and describe what they need in plain English.

## 5. Clear rules across all plugins

Rules are cross-cutting conventions that apply to multiple skills. Examples: voice / tone, professional disclaimers, units & measurements, citation style, audit-on-touch.

- For multi-plugin marketplaces, put rules in a top-level `rules/` directory — referenced by per-plugin READMEs, enforced by hooks at marketplace level. See [`skills-for-architects/rules/`](./rules/).
- For single-plugin marketplaces, rules live in the dispatcher skill body and are repeated in each sub-skill that touches them.
- **Marker-driven hooks** — for enforceable rules, use HTML comment markers (e.g., `<!-- architecture-studio:requires-disclaimer -->`) that skills emit when they want the rule applied. Hooks check for the marker, not for keywords like "FAR" or "audit." See [`post-write-disclaimer-check.sh`](./hooks/post-write-disclaimer-check.sh).
- Hard rules in skills are stated explicitly in the body, with WHY they exist (often a past incident or strong invariant). E.g.: "Audit always re-parses. Reason: Eames bug where agent reported sheet value as verified when catalog had drifted to a newer price."

**Why:** keyword-sniffing hooks misfire on docs that mention regulated terms in passing (READMEs, changelogs, meeting notes) AND miss terse regulatory replies that happen not to use those keywords. Marker-driven enforcement eliminates both. Documenting WHY the rule exists lets future maintainers judge edge cases instead of blindly following the rule.

## 6. Clear versioning behavior

Two version fields, two scopes — both pinned, both bumped on every shipped change.

Use the [operational release checklist](./docs/release-checklist.md) for scope, tracker disposition, contribution credit, verification, publication, and post-release correction. This section remains authoritative for versioning invariants.

| Field | Where | Bumps when |
|---|---|---|
| `.claude-plugin/plugin.json` `version` | Claude package | The plugin's behavior changes — new skill, edited skill body, MCP tool added, etc. |
| `.codex-plugin/plugin.json` `version` | Codex package | Every cross-harness release; keep it equal to the Claude package version |
| `marketplace.json` `metadata.version` | Marketplace-wide | Anything the repo ships changes — including marketplace-level docs, top-level scripts/hooks/lint, marketplace.json structure itself, even if no individual plugin's behavior moves |

On EVERY shipped change:

1. Bump the relevant `version`. Cross-harness releases keep both plugin manifests and the Claude marketplace metadata on the same version. Patch releases are compatible corrections. Minor releases normally add behavior and may carry an explicitly labeled breaking migration when preserving the project's public release sequence is the clearer user contract. Major releases remain available for broader product-generation boundaries.
2. Add a `CHANGELOG.md` entry under `## [X.Y.Z] - YYYY-MM-DD` describing what changed.
3. Stage version bump + CHANGELOG + actual change in a single commit and push.
4. **Tag the commit:** `git tag -a vX.Y.Z <sha> -m "vX.Y.Z — short description"` and `git push origin vX.Y.Z`.
5. **Cut the GitHub release:** `gh release create vX.Y.Z --title "vX.Y.Z — …" --notes-file <changelog-section>` (extract the CHANGELOG section for that version into a temp file with `sed -n '/^## \[X\.Y\.Z\]/,/^## \[/p' CHANGELOG.md | sed '$d'`).

If a single change touches both plugin behavior and marketplace-level state, bump both versions in the same commit (one tag, one release — pick the higher-scope version for the tag name).

**The version string is hardcoded in more places than the manifests.** A release that bumps only the JSON files fails the suite. Grep before committing — `grep -rn '<previous-version>' --include='*.json' --include='*.sh' --include='*.md' .` — and expect to touch:

| Location | What |
|---|---|
| `.claude-plugin/plugin.json`, `.codex-plugin/plugin.json`, `.claude-plugin/marketplace.json` | The three `version` fields |
| `CHANGELOG.md` | The `## [X.Y.Z] - YYYY-MM-DD` heading **and** both link refs at the bottom — the `[Unreleased]: …compare/vX.Y.Z...HEAD` target moves to the new tag, and a `[X.Y.Z]: …releases/tag/vX.Y.Z` line is added |
| `tests/test-v1-5-release-contract.sh` | Asserts the plugin and marketplace versions, the CHANGELOG headings, and the exact compare-link target. **Fails until updated.** |
| `tests/test-project-records-integration.sh` | Asserts the installed plugin version. **Fails until updated.** |
| `README.md` | The `as vX.Y.Z` identity line, and a "What's new" section for anything user-facing |
| `docs/firm-deployment.md` | Opens by naming the current version |

Run the full suite before tagging. The two tests above encode the release contract deliberately, so a bump that forgets a surface cannot ship quietly.

**Three artifacts must move together:** JSON `version` field, git tag, GitHub release. Bumping JSON without tagging leaves discoverability holes (no `git checkout v1.1.0`, no shareable release URL). Tagging without bumping JSON breaks Cowork's update mechanism. Cutting a release without a CHANGELOG entry leaves the release notes empty.

**Why:** Cowork and Claude Code pin to `plugin.json` `version` for plugin updates — without a bump, `/plugin marketplace update` reports "already up to date" even when new commits exist (canoa 2026-05-08: three commits, no bump, Cowork served `0.1.0` indefinitely). The marketplace `metadata.version` is more of a documentation pin than a functional one (`/plugin marketplace update` re-fetches regardless), but bumping it gives every shipped change a clear version trail in CHANGELOG. Git tags + GitHub releases give the same change a discoverable surface for humans — release URLs link from PRs, CHANGELOGs, and external docs; tags let `git checkout` against a known release point. We hit the gap three times on 2026-05-08: canoa shipped without a plugin.json bump; skills-for-architects shipped PATTERNS.md without a marketplace bump; both repos accumulated commits without git tags or GitHub releases. Bump discipline = every push leaves a trail across all three artifacts.

If you ever need auto-publish on every commit (during very heavy iteration), drop the `version` field entirely — Cowork/Code falls through to commit SHAs for plugin updates, and you can also skip per-commit tags. But default is the pin + bump + tag + release.

## 7. Layout pattern selection

| Layout | When | Marketplace source | Skills location |
|---|---|---|---|
| **Flat single-plugin** (canoa-style) | One plugin in the marketplace; the marketplace IS the plugin | `"./"` | `skills/<verb>/` at repo root |
| **Multi-plugin nested** | Two or more independently installed plugins | `"./plugins/<name>"` | `plugins/<name>/skills/<verb>/` |

For Claude Code, `.claude-plugin/marketplace.json` lives at the repo root. Codex-compatible repositories also carry `.agents/plugins/marketplace.json`. For a flat single plugin, `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` both live at the plugin root; their versions and names stay aligned.

Don't pick the multi-plugin layout for a single plugin — adds nesting without payoff and forces awkward `/plugin:start` slash UX. Don't pick the flat layout when shipping multiple plugins — they'll collide on skill names.

## 8. MCP server bundling

Plugins that depend on an MCP server bundle it inside the plugin via `.mcp.json` at the plugin root, using `${CLAUDE_PLUGIN_ROOT}` to resolve paths:

```json
{
  "mcpServers": {
    "canoa": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/dist/server.js"]
    }
  }
}
```

The MCP server source lives under `mcp/` (or `<plugin>/mcp/` for multi-plugin), with `dist/` committed so a fresh clone runs the MCP without rebuild. `mcp/node_modules/` is gitignored.

**Never require per-user wrangler / config-file edits.** The plugin install IS the MCP install.

This generic plugin-packaging pattern is distinct from an Architecture Studio
workspace. A studio root reserves its own `.mcp.json`, owned by `/as:studio`, for
shared future connector configuration. New studios create it with only an empty
`mcpServers` object. The plugin must not populate it, projects must not create
another manifest, and provider selection, credentials, endpoints, and OAuth are
not part of studio initialization.

## Local product-data boundary

- `product-library.csv` is the only persistent FF&E library. Optional reusable EPD records use `epd-library.csv`; EPD parsing remains PDF-first and can hand results directly to comparison or specification workflows without saving a library.
- Existing `master-schedule.json` and `canoa.json` files are legacy cloud-configuration evidence, not row data. Preserve them byte-for-byte and require a user-exported CSV before import; never imply that disconnected cloud rows were migrated.
- XLS and XLSX product-library support and configured connectors are deferred. Do not add format adapters, provider setup, authentication, sheet identifiers, ranges, tabs, or formulas to active product workflows.
- CSV-only persistence does not remove explicit SIF interchange. `/as:csv-to-sif` and `/as:sif-to-csv` remain bounded conversion commands; SIF is not a persistent schedule source.

## 9. Public over private

Default plugin marketplaces to **public GitHub repos** unless there's a deliberate strategic reason to keep them private. Public removes Cowork/Code auth friction, simplifies install for testers, and matches the OSS posture of Claude's plugin ecosystem.

Strategy moats live in **server-side product surface** (e.g. Canoa's catalog cache) — not in plugin packaging or skill bodies. The plugin shape is mostly product surface, not strategy.

If kept private: use Cowork's Admin → Private Marketplace flow with the Claude GitHub App; expect [bug #28125](https://github.com/anthropics/claude-code/issues/28125); have a ZIP-upload fallback ready.

## 10. Hard rules captured from real bugs

When a real bug surfaces in production / testing, encode the fix as a hard rule in the relevant skill body — not just a code patch. The rule survives refactors; the patch may not.

Examples from canoa V1:

- **Audit always re-parses** (Eames LCW bug 2026-05-07): agent reported stale sheet value as "verified-tier from Herman Miller." Rule: every audit invocation runs `parse_product_url` against the row's URL, even if the catalog cache is recent. Surfaces drift between sheet ↔ catalog ↔ live with provenance.
- **Read before write** (Norma Jean header bug 2026-05-07): agent guessed at column headers, USD landed in wrong column. Rule: `append_to_sheet` always preceded by `read_master_sheet` to map keys to actual headers. Use exact header names verbatim. Don't invent columns.
- **Update in place** (Eames LCW dupes 2026-05-07): refresh appended new rows instead of patching existing ones. Rule: when SKU match exists, use `update_row_by_match` — never append.
- **No fabricated capabilities**: agent claimed "background refresh" that doesn't exist. Rule: state only what the tools you just called actually did. Canoa V1 has no async workers.

Hard rules belong in the dispatcher skill (so they're inherited globally) AND in each sub-skill that touches the affected behavior (so they're enforced even if the dispatcher is bypassed).

## Cross-record project conventions

When skills maintain linked project records such as dossiers, decisions, plans, meetings, reports, tasks, or time logs:

- Resolve the nearest project boundary once per invocation. For `/as:tasklist`, `PROJECT.md` is the only implicit project marker and `STUDIO.md` supplies registered project choices; generic record folders and git roots never become task projects. Other legacy record skills may still recognize their established typed-record markers inside a monorepo while migrating to the canonical boundary.
- Keep one owner per record type. Cross-links do not transfer authority: a meeting statement is not a dossier fact, and an indexed decision is not current merely because its row exists.
- Use project-relative Markdown links, preferably with a heading or stable item ID. Never persist machine-specific absolute paths.
- Treat indexes as navigation aids. Discover canonical files independently when completeness matters, report stale or unindexed entries, and never silently repair drift from a read-only workflow.
- Preserve malformed artifacts and report the path and parse problem. A parse failure means unknown, not absent and not approved.
- Repeat these semantic constraints inside every touching skill. Cross-skill invocation, agents, git, web access, and structured question tools are optional enhancements, not required runtime dependencies.

## Single-gate interaction pattern

When a workflow needs user input or confirmation, ask once:

- If a structured question or confirmation tool is available, provide any necessary context or preview, then invoke the tool directly. Do not end the prose with the same question and do not ask the user to reply before opening the gate.
- Put the complete decision in one gate: exact target, material defaults, side effects, and any required acknowledgement. After the user answers, act on that answer without asking again.
- If no structured gate is available, ask once in natural language and treat the answer as the gate.
- A harness permission prompt may still appear when the actual tool runs. That security boundary is not a reason to add another conversational “are you sure?” before or after the semantic confirmation.

**Why:** asking in prose and then presenting the same structured gate makes users approve one action twice and teaches them to click through confirmations without reading them.

## Studio and project workspace boundaries

Architecture Studio has two nested but distinct boundaries:

- `STUDIO.md` marks the studio root. It is a portable registry of descendant projects and is mutated only by `/as:studio`.
- `PROJECT.md` marks a project root. Project facts and decision records are mutated only by `/as:project`; typed records keep their existing owners.
- A studio is never inferred from plugin installation and the installed plugin cache is never a studio, project, or private-skill target.
- Studio-owned skills live in `{studio-root}/.agents/skills/` on Codex or `{studio-root}/.claude/skills/` on Claude Code. A project-only or global skill requires explicit user intent. The public catalog remains a separate contributor target.
- `/as:studio create-project` may call the project-owned scaffold helper, verify the result, and then register it. `/as:project init` inside a studio routes to that flow and does not mutate `STUDIO.md` or create a nested project.
- Studio and project initialization preview exact targets, reject unsafe or colliding paths, and never overwrite or silently suffix identity-bearing folders.

**Dispatcher exception:** `/as:studio` is the Architecture Studio control plane. In addition to routing domain work, it may initialize and inspect its own studio workspace and orchestrate project registration. Setup details still belong in references, templates, and deterministic helpers so the dispatcher remains readable.

## CI lint

Every marketplace repo should ship a structural lint (`scripts/lint.sh` + GitHub Actions workflow) that fails CI on:

1. Tracked `.DS_Store` files
2. Invalid JSON (`marketplace.json`, `plugin.json`, `.mcp.json`, etc.)
3. SKILL.md frontmatter missing `name` or `description`
4. Catalog drift between documented skill rows, skill directories, and marketplace plugin entries
5. Broken internal markdown links
6. shellcheck on `hooks/*.sh`

See [`scripts/lint.sh`](./scripts/lint.sh) and [`.github/workflows/lint.yml`](./.github/workflows/lint.yml) for the reference implementation.

**Why:** catalog drift makes documented commands disappear. The lint derives membership from the filesystem and requires one catalog row per skill without maintaining an aggregate skill count.

## Quick checklist for starting a new plugin

1. Decide layout: single-plugin (flat) or multi-plugin (nested)?
2. Pick names: marketplace, plugin, dispatcher (= plugin name), sub-skills (`<plugin>-<verb>`)
3. Create `.claude-plugin/marketplace.json` + `plugin.json` (version `0.1.0`, X.Y.Z pinned)
4. Write the dispatcher skill first — establish the routing table
5. Write each sub-skill as a thin shell with `allowed-tools` scoped
6. Resolve bundled paths from the loaded `SKILL.md`. Claude Code may expose `${CLAUDE_PLUGIN_ROOT}`, but portable skill bodies use `<plugin-root>` and must not require that variable.
7. Create top-level `agents/` for orchestration personas; multi-plugin: also `rules/`, `hooks/`
8. README at repo root with diagram + skill table + install instructions
9. CHANGELOG.md, LICENSE (MIT default), AGENTS.md and/or CLAUDE.md as supported, `.gitignore` (`**/node_modules/`, per-user state dirs, `.wrangler/`)
10. Public visibility unless strategy says otherwise
11. CI lint on push (validates SKILL.md frontmatter, JSON manifests, and catalog consistency)

## Versions of these patterns

- **2026-05-08** — Initial version. Distilled from canoa V1 (single-plugin) and skills-for-architects v1.0 (multi-plugin). Six core principles requested by Federico; expanded to ten with layout / MCP bundling / public-default / hard-rules / lint additions.
- **2026-06-10** — Examples made self-contained: external-org references removed; all examples now draw on this repo and canoa.
