# /as:proposal

Numbered fee proposals with a studio-wide register and permanent numbering.

```text
/as:proposal create
/as:proposal list
/as:proposal status ALPA-0004
/as:proposal send ALPA-0004
/as:proposal accept ALPA-0004
/as:proposal decline ALPA-0004
/as:proposal supersede ALPA-0003
/as:proposal verify
```

`PROPOSALS.md` at the studio root (or standalone project root) is the allocation and status ledger; numbered markdown documents in each project's `proposals/` directory are the content records. Numbers are never reused. Accepting a proposal hands off to `/as:agreement promote`, which turns it into contract context; invoicing belongs to `/as:invoice`. The bundled terms-and-conditions clause library is drafting guidance, not legal advice.
