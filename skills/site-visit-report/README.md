# /as:site-visit-report

Creates typed, source-linked field records at `site-reports/YYYY-MM-DD-slug.md` from site notes, photos, files, or the current conversation.

The report separates direct observations, participant-reported information, limited interpretation, photographs and files, access or visibility limitations, issues, and proposed follow-ups. It never treats inaccessible or concealed conditions as observed and never makes compliance claims.

## Usage

```text
/as:site-visit-report from field-notes/2026-07-21.md
/as:site-visit-report document today's walkthrough and attached photos
/as:site-visit-report revise site-reports/2026-07-21-roof-walkthrough.md
```

Saving changes only the report. It never updates `PROJECT.md`, `decisions/`, or `TASKS.md`. After saving, exact user-selected items can be handed to `/as:project remember`, `/as:project record-decision`, or `/as:tasklist` with source backlinks and duplicate checks.

Client-facing, authority-facing, and regulated-conclusion reports receive Architecture Studio's canonical professional disclaimer. A purely internal administrative draft without regulated conclusions may omit it.
