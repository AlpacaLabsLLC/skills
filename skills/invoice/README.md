# /as:invoice

Append-only invoice ledger with script-computed balances, cap warnings, and gap detection.

```text
/as:invoice init
/as:invoice record
/as:invoice status
/as:invoice reconcile
```

`INVOICES.md` at the project root records every invoice billed against the agreement. Amounts come from `agreement/AGREEMENT.md` terms or explicit user input — never from activity signals or `TIMELOG.md`. Recorded amounts are immutable; mistakes are corrected by new rows. The bundled script computes the running total, outstanding balance, percentage of Maximum Total Cost (warning at 80%), and billing-period coverage gaps; the skill reports those numbers and never recomputes them.
