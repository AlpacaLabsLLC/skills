# Commercial records — proposals, agreements, invoicing, scope guard

**Status:** planned · **Target:** v1.5.0 · **Author:** ALPA · **Date:** 2026-08-06

Architecture Studio has typed records for decisions, meetings, site reports, plans, tasks, and time — but nothing for the commercial life of a project. This plan adds the missing spine: **proposal → agreement → invoices**, plus contract context that guards day-to-day work against scope creep.

## Design principles (inherited)

- Small skills, one verb each; typed records with a single canonical home; no duplicate indexes (PATTERNS.md).
- `/as:studio` remains the sole writer of `STUDIO.md`. New record types get their own owner skills.
- Every durable mutation is previewed and confirmed.
- The timetracker firewall stands: **nothing infers billable amounts from activity**. Money enters records only from agreement terms or explicit user input.
- Templates ship neutral with brand slots. ALPA's own editorial-ink proposal design stays private; the plugin ships an unbranded letter-format template a studio can override.

## Record model

```text
studio-root/
├── STUDIO.md                      (unchanged; /as:studio only)
├── PROPOSALS.md                   (NEW — studio-wide proposal register, /as:proposal only)
└── projects/<id>/
    ├── proposals/                 (NEW — numbered proposal docs, /as:proposal only)
    ├── agreement/                 (NEW — created on acceptance, /as:agreement only)
    │   ├── AGREEMENT.md           (contract context: sourced facts + scope blocks)
    │   ├── <accepted proposal>    (append-only: accepted doc, SOWs, amendments, signed PDFs)
    │   └── sow/
    └── INVOICES.md                (NEW — schedule + running balance, /as:invoice only)
```

**Numbering.** Studio-wide sequential, chronological by issue date: `{PREFIX}-{NNNN}` (e.g. `ALPA-0005`). The prefix and format version live in `PROPOSALS.md` front matter (keeps `STUDIO.md` ownership untouched). Numbers are never reused; a replaced proposal is `superseded`, like decisions.

**Register row:** number · project ID · client · title · issued · status (`draft / sent / accepted / declined / superseded`) · relative path. Files are canonical; the register is the allocation ledger that makes cross-project numbering atomic.

## New skills (three, one verb each)

### 1. `/as:proposal`

Owns `PROPOSALS.md` + every project `proposals/` directory.

- `create` — allocate next number, scaffold from template (letter-format HTML or MD), place in the project, register as `draft`. Pending decisions render as visible highlight slots.
- `list` / `status` — read the register + verify files exist (report drift, never silently fix).
- `send` / `decline` / `supersede` — status transitions with preview.
- `accept <number>` — records acceptance (date, who, how) then hands off: "Run `/as:agreement promote <number>`."
- Template: neutral single-page skeleton — masthead slot, meta grid (date/to/from/term), scope tables, fees table, T&C list, signature blocks. A `references/tc-library.md` with standard consulting clauses (independent contractor, IP split, AI services, non-solicit, liability cap, entire agreement) the user assembles from — guidance, not legal advice; the professional-disclaimer marker applies.

### 2. `/as:agreement`

Owns `agreement/` — exists only after an acceptance.

- `promote <number>` — copy the accepted proposal into `agreement/` (append-only), extract **AGREEMENT.md**: parties, term, fees, caps, invoicing terms, IP, and machine-readable scope blocks (`In scope` / `Not in scope` / `Requires SOW`) — every fact sourced to the doc + date. Scaffold `INVOICES.md` from the agreement's fee terms. Offer (previewed) one line into the project `CLAUDE.md`: *"Read `agreement/AGREEMENT.md` before committing to new work; flag out-of-scope requests."*
- `check <request>` — classify a described piece of work against the scope blocks → `in-scope / needs-SOW / out-of-scope`, quoting the governing lines. Advisory verdict, never a block.
- `amend` — record an SOW or amendment as a new append-only file + sourced fact updates in AGREEMENT.md (history preserved, like decision supersede).
- `status` — term countdown, cap consumption (from INVOICES.md totals), open SOWs.

### 3. `/as:invoice`

Owns `INVOICES.md` (formalizes the schedule + running-balance pattern proven on a real 19-invoice engagement).

- `record` — append an invoice row: number, period, base, expenses, total, sent/paid dates, status. Period and amount come from AGREEMENT.md terms or user input — never from TIMELOG.
- `status` — running balance, outstanding, next expected cycle, **cap warning when totals cross 80% of any Maximum Total Cost**, gap detection between billing periods (the continuous-coverage check).
- `reconcile` — user-driven checklist against payment records; the skill never asserts payment happened.

## Scope-guard integration (the "watch for scope creep" piece)

Per the PATTERNS rule that cross-skill hard rules are repeated in every skill that touches them:

- `/as:tasklist` add/import and `/as:workplan` create gain one repeated rule: *if `agreement/AGREEMENT.md` exists, check proposed work against its scope blocks; surface `needs-SOW` / `out-of-scope` findings in the preview before recording.* Advisory only — the user always decides.
- `/as:project status` reports agreement presence, term, and cap consumption alongside decisions and tasks.
- Dispatcher routing table gains rows: proposal/quote → `/as:proposal`; contract/agreement/scope question → `/as:agreement`; invoice/billing/balance → `/as:invoice`.
- No new hooks in v1.5 — scope guard lives in skill flows, marker-driven hooks can come later if the advisory pattern proves insufficient.

## Hard boundaries (new)

1. `PROPOSALS.md` and `proposals/` — written only by `/as:proposal`.
2. `agreement/` — written only by `/as:agreement`; accepted documents are append-only, never edited.
3. `INVOICES.md` — written only by `/as:invoice`; no amount is ever derived from activity signals.
4. Proposal numbers are never reused or renumbered.
5. None of the three skills writes `STUDIO.md`, `PROJECT.md`, `decisions/`, tasks, or time records. Facts worth promoting to `PROJECT.md` go through `/as:project` handoff.
6. Templates and clause library are guidance, not legal advice — regulatory-disclaimer marker on generated T&C output.

## Phases

1. **Spec** — finalize the four record formats (PROPOSALS.md, proposal template, AGREEMENT.md, INVOICES.md) + fixture examples. Review before code.
2. **`/as:proposal`** — skill + allocation script + register verify + tests (`tests/test-proposal-contract.sh`).
3. **`/as:agreement`** — promote/check/amend/status + project CLAUDE.md line + tests.
4. **`/as:invoice`** — ledger + cap/gap logic + tests.
5. **Integration** — dispatcher routing, tasklist/workplan scope-guard rule, tool-catalog, README, marketplace counts, lint green.
6. **Ship v1.5.0** — CHANGELOG entry, JSON version + git tag + GitHub release (three-artifact discipline).
7. **Dogfood** — in the ALPA studio: import ALPA-0001…0004 into the register, promote Slantis 0003 on signature, run the first live invoice cycle against it.

## Decisions taken in this plan (revisit if they chafe)

- **Three skills, not one "commercial" monolith** — one-verb rule; also lets `allowed-tools` stay tight per skill.
- **Register at studio root, not in STUDIO.md** — preserves the single-writer rule for the manifest.
- **Agreement is a promotion, not a status** — an accepted proposal becomes a different kind of record (append-only, fact-extracted) rather than a proposal with `status: accepted` doing double duty.
- **Advisory scope guard, no blocking** — the plugin informs; the architect decides.
