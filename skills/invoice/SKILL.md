---
name: invoice
description: Maintain a project's append-only invoice ledger — record invoices, track sent and paid status, watch the running balance against a recorded Maximum Total Cost, and detect billing-period gaps. Use for "record this invoice", "what's outstanding", "how much of the cap is left", invoice status, billing schedule, or reconciliation questions.
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# /as:invoice — Invoice Ledger

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

`/as:invoice` owns each project's `INVOICES.md`: an append-only ledger with script-computed totals, cap consumption, and coverage-gap detection. An agreement is optional context, not a prerequisite.

## Commands

```text
/as:invoice init
/as:invoice record
/as:invoice status
/as:invoice reconcile
/as:invoice send <row-id>
/as:invoice void <row-id>
```

## Hard rules

1. **Every amount comes from the agreement or the user.** No amount, hour count, billing status, or completeness is ever derived from activity signals — not from `TIMELOG.md`, tasks, commits, artifact counts, or meeting records. Amounts come from `agreement/AGREEMENT.md` terms or explicit user input.
2. **Amounts are immutable.** A recorded amount is never edited; a mistake is corrected by a new row whose Correction column reads `Corrects I#### — reason`. Corrected rows are excluded from totals by the script; both rows stay in the ledger.
3. **Lifecycle is mutable, history is kept.** Sent, Paid, and Status update in place through the script, and every change appends a `## History` bullet.
4. **The script does the math.** Running total, outstanding, cap percentage, `CAP WARNING` at ≥80% of Maximum Total Cost, and coverage gaps come from `<skill-root>/scripts/invoice-ledger.sh status` — never from model arithmetic. Report its output; do not recompute it.
5. **The skill never asserts payment happened.** `reconcile` previews a user-driven checklist against the user's own payment records and applies only user-confirmed paid dates.
6. **One writer.** `/as:invoice` is the only writer of `INVOICES.md`. It never writes `agreement/`, project-local `proposals/`, `PROJECT.md`, `STUDIO.md`, tasks, or time records. A malformed ledger blocks mutation and is preserved byte-for-byte.
7. **User-owned billing judgment.** A missing proposal or agreement and the current project status never gate ledger creation or a user-confirmed invoice. The skill may surface context, but the user is responsible for whether billing is commercially appropriate.

## Resolve the project

Run the shared resolver at `<plugin-root>/skills/project/scripts/resolve-context.sh` and follow `skills/project/references/context-resolution.md`. `INVOICES.md` lives at the project root. Resolve every valid selected project regardless of type or status.

## `/as:invoice init`

1. Read `agreement/AGREEMENT.md` Terms when present — currency, billing cadence, base fee, Maximum Total Cost — citing it as the source; otherwise gather the values from the user in one grouped question (source: user input). A missing cap is recorded as `none`.
2. Preview the exact settings and file path. One gate.
3. Run `invoice-ledger.sh init <project-root> <project-name> <currency> <cadence> <base-fee> <max-total|none> <terms-source> <date>`, re-read, and report the exact path.

## `/as:invoice record`

1. Gather the invoice: external invoice number, period start and end, base, expenses, total, and — for historical imports — sent/paid dates and status. Ask once for what's missing. For a correction, require the corrected row ID and reason.
2. Preview the exact row (ID allocated by the script) and any cap consequence from a dry read of `status`. One gate.
3. Run `append`, then `status`, re-read, and report the row plus the script's totals — including any `CAP WARNING` or `coverage gap` lines verbatim.

## `/as:invoice status`

Read-only. Run `invoice-ledger.sh status` and report its output faithfully: total invoiced, outstanding, cap consumption, warnings, gaps, and last period end. Add context from the ledger rows (which invoices are outstanding, upcoming cycle per the cadence) without recomputing any number the script prints.

## `/as:invoice reconcile`

1. Run `status` and list rows marked `sent`.
2. Present a checklist for the user to confirm against their payment records — the skill proposes nothing as paid.
3. For each user-confirmed payment, preview and run `set-lifecycle <id> paid <date>`. Unconfirmed rows stay `sent`; report what remains outstanding.

## `/as:invoice send <row-id>`

1. Re-read the named ledger row and gather the actual sent date from the user.
2. Preview the exact row, transition, and date, then ask the user to confirm once.
3. Run `set-lifecycle <row-id> sent <date>`, then re-read the ledger, run `status`, and report the recorded transition and updated script output.

## `/as:invoice void <row-id>`

1. Re-read the named ledger row and gather the effective void date from the user.
2. Preview the exact row, transition, and date, explain that void rows leave the ledger but drop out of computed totals, then ask the user to confirm once.
3. Run `set-lifecycle <row-id> void <date>`, then re-read the ledger, run `status`, and report the recorded transition and updated script output.

## Typed record handoffs

- When an agreement exists, its fee terms and caps are useful sourced context; explicit user input remains valid without one.
- Reconstructing what work happened in a period belongs to `/as:timetracker` — and its record never feeds amounts here.
- Facts worth `PROJECT.md` go through `/as:project`.

## Collaboration and harness boundary

Structured questions and cross-skill invocation are enhancements; when unavailable, preserve completed work and print the exact follow-up command. A harness permission prompt is a separate security boundary, never a reason to add another conversational confirmation.
