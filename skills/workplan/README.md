# /as:workplan

Creates a durable Markdown plan for repository work, operations, research, or AEC project delivery without executing the work.

## Usage

```text
/as:workplan add a new specification-review skill
/as:workplan coordinate the 50% design-development submission
/as:workplan prepare the consultant drawing package for owner review
```

The skill classifies the request as repository, AEC delivery, or general work; confirms material scope decisions; researches the available project context; and writes an execution-ready plan with requirements, assumptions, decisions, work units, verification scenarios, and a definition of done.

Before planning, it resolves the nearest project boundary and reads relevant `PROJECT.md` facts, directly discovered `decisions/*.md`, meeting records, site reports, and `TASKS.md`. Decided records constrain the plan, proposed records remain unresolved, and superseded records are historical context. Inspected and malformed sources are disclosed; project evidence is cited with project-relative links.

After saving, `/as:workplan` may offer an item-level `/as:tasklist` handoff for selected work units or action items. It never creates tasks automatically; `/as:tasklist` owns duplicate checking, preview, confirmation, and the canonical register.

The plan remains one node in the Project Records graph: approved work units may be handed to [`/as:tasklist`](../tasklist), and [`/as:timetracker`](../timetracker) may later use the plan's explicit dates and links as activity evidence. Neither handoff happens automatically.

`/as:workplan` plans work. It does not create floor plans, site plans, space plans, zoning calculations, building-code analyses, or architectural designs. Those requests route to Architecture Studio's specialist skills and agents.
