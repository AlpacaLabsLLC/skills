# /as:proposal

Project-local fee proposals with human-readable date/title/revision filenames and checksum-protected issued terms.

```text
/as:proposal create
/as:proposal list
/as:proposal status proposals/2026-08-design-services-proposal-rev-01.md
/as:proposal send proposals/2026-08-design-services-proposal-rev-01.md
/as:proposal accept proposals/2026-08-design-services-proposal-rev-01.md
/as:proposal decline proposals/2026-08-design-services-proposal-rev-01.md
/as:proposal supersede proposals/2026-08-design-services-proposal-rev-01.md
/as:proposal verify
```

Every markdown file in the selected project's `proposals/` directory is canonical. There is no studio-wide proposal register or firm-wide proposal number. Human-facing revisions use `Rev. 01`, `Rev. 02`, and so on; filenames use the filesystem-safe equivalent `rev-01`, `rev-02`. Sending stores a SHA-256 checksum of the issued-terms block; lifecycle evidence remains editable outside that block, while changed terms use a new revision. The skill records user-directed actions without enforcing a proposal, agreement, invoice, or project-status sequence. The bundled clause library remains drafting guidance, not legal advice.

For client-facing HTML, put the studio's branded template at `standards/proposal-letter.html`. The skill prefers that firm-owned standard and falls back to its bundled neutral template. HTML exports are derived from the canonical project-local Markdown proposal and use the project ID plus local revision rather than a global proposal number.
