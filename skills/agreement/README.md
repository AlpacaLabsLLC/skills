# /as:agreement

Contract context and scope guard for a project's accepted proposal.

```text
/as:agreement promote ALPA-0004
/as:agreement check "client wants a fifth facade option"
/as:agreement amend
/as:agreement status
/as:agreement verify
```

`agreement/` holds the accepted proposal, SOWs, and amendments — append-only — and `AGREEMENT.md` distills them into sourced facts plus three scope blocks: In scope, Not in scope, Requires SOW. `check` classifies any described work against those blocks with an advisory verdict; `/as:tasklist` and `/as:workplan` consult the same blocks before recording new work. Promotion follows `/as:proposal accept`; the invoice ledger is `/as:invoice`'s.
