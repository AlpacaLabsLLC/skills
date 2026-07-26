# /as:timetracker

Reconstructs daily or weekly work descriptions from dated project artifacts and appends only user-confirmed manual time to `TIMELOG.md`.

```text
/as:timetracker today
/as:timetracker this week
/as:timetracker 2026-07-13 through 2026-07-17
/as:timetracker correct E0012
```

The skill searches plans, decisions, meeting minutes, site reports, tasks, `PROJECT.md`, and other dated artifacts. Explicit dates inside artifacts take precedence; git history is secondary evidence; filesystem modification time is a visibly low-confidence fallback.

Candidates always have a blank duration. File activity, commit counts, timestamp spans, task status, and meeting duration can never determine hours. The user selects entries, supplies a decimal duration for each, reviews the exact rows, and confirms before anything is appended.

`TIMELOG.md` uses permanent `E0001`-style IDs and project-relative source links. It is append-only: corrections receive a new ID and reference the original entry rather than rewriting it.
