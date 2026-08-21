# /as:invoice

Append-only invoice ledger with script-computed balances, cap warnings, and gap detection.

```text
/as:invoice init
/as:invoice record
/as:invoice status
/as:invoice reconcile
/as:invoice send <row-id>
/as:invoice void <row-id>
```

`INVOICES.md` at the project root records user-directed billing. Amounts come from `agreement/AGREEMENT.md` terms when useful or from explicit user input — never from activity signals or `TIMELOG.md`. A proposal, agreement, or particular project status is not required by the tool. Recorded amounts are immutable; mistakes are corrected by new rows. `send` and `void` preview one confirmed lifecycle transition and apply it through the ledger helper. The bundled script computes the running total, outstanding balance, percentage of Maximum Total Cost (warning at 80%), and billing-period coverage gaps; the skill reports those numbers and never recomputes them.
