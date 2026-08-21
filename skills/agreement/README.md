# /as:agreement

Project-local contract context with optional checksum-protected proposal citations and advisory scope checks.

```text
/as:agreement init
/as:agreement promote proposals/2026-08-design-services-proposal-rev-01.md
/as:agreement check "client wants a fifth facade option"
/as:agreement amend
/as:agreement status
/as:agreement verify
```

`agreement/AGREEMENT.md` holds sourced contract facts plus In scope, Not in scope, and Requires SOW sections. Direct engagements can initialize it without a proposal. Promotion requires an accepted project-local proposal and cites its path and issued-terms SHA-256 without copying it. SOW and amendment documents remain append-only, and amendment effective dates must be real `YYYY-MM-DD` calendar dates. Scope verdicts inform the user; they do not block work, change project status, or control billing. When a project-local invoice ledger exists, agreement status relays the executable `invoice-ledger.sh status <project-root>` result without recomputing it.
