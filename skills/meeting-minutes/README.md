# /as:meeting-minutes

Creates typed, source-linked project meeting records at `meetings/YYYY-MM-DD-slug.md` from transcripts, notes, files, or the current conversation.

The minutes distinguish discussion, participant-stated information, confirmed decisions, proposed decisions, proposed tasks, and open questions. An event date, artifact creation date, and project-relative source references remain distinct.

## Usage

```text
/as:meeting-minutes from notes/owner-meeting.md
/as:meeting-minutes turn this transcript into minutes
/as:meeting-minutes revise meetings/2026-07-21-design-team.md
```

Saving minutes changes only the meeting artifact. It never updates `PROJECT.md`, `decisions/`, or `TASKS.md`. After saving, the skill previews potential promotions and requires exact item-level selection before handing a fact to `/as:project remember`, a durable choice to `/as:project record-decision`, or an action to `/as:tasklist`.

The skill resolves the nearest project boundary, uses deterministic suffixes rather than overwriting collisions, and provides exact copyable follow-up commands when the active harness cannot invoke another skill directly.
