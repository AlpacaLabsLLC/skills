# Invoices — {{PROJECT_NAME}}

> Append-only invoice ledger maintained by `/as:invoice`. Amounts come from
> agreement terms or explicit user input — never from activity signals or `TIMELOG.md`.

## Settings

| Setting | Value | Source | Date |
|---|---|---|---|
| Format version | 2 | invoice setup | {{CREATED_DATE}} |
| Currency | {{CURRENCY}} | {{TERMS_SOURCE}} | {{CREATED_DATE}} |
| Billing cadence | {{CADENCE}} | {{TERMS_SOURCE}} | {{CREATED_DATE}} |
| Base fee | {{BASE_FEE}} | {{TERMS_SOURCE}} | {{CREATED_DATE}} |
| Maximum Total Cost | {{MAX_TOTAL}} | {{TERMS_SOURCE}} | {{CREATED_DATE}} |

## Ledger

<!-- invoices:start -->
| ID | Invoice # | Period start | Period end | Base | Expenses | Total | Sent | Paid | Status | Correction |
|---|---|---|---|---|---|---|---|---|---|---|
<!-- invoices:end -->

## History
