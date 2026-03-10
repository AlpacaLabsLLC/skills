# Evaluate Candidates

Evaluate new Typeform recruitment survey responses against the Slantis 10-dimension rubric and append results to the historical record.

## Trigger
Use when asked to evaluate candidates, run evaluations, score new applicants, or process a new Typeform batch.

## Base paths

- **Talent dir:** `~/Documents/_Alpaca Labs/_Slantis/talent/`
- **Historical record:** `eval_data.json` (the single source of truth for all evaluated candidates)
- **Rubric:** `rubric.py` (10-dimension system prompt + scoring logic)
- **Raw evals:** `eval_raw/` (one JSON per candidate)
- **Dashboard:** `dashboard.html`
- **Cohort dashboard:** `cohort_2026.html`

## Step 1 — Get the data

Ask the user where the new Typeform data is. Accept any of:

- **File path** to an `.xlsx` on disk (e.g., a new Typeform export)
- **Pasted data** — the user pastes candidate responses directly into the chat
- **Google Sheet ID** — read via `mcp__google__sheets_values_get`

If the user provides a file, read it. If they paste data, use it directly.

## Step 2 — Parse into candidate rows

Each candidate needs these fields to go through the rubric:

- `What's your full name?` (required)
- `Dirección de correo electrónico` (email, optional)
- All survey Q&A columns

**For xlsx files:** Use Python (openpyxl) to parse. The Typeform exports have multiple sheets — each sheet is a form variant. Row 1 = headers, remaining rows = candidates. Skip empty rows. Tag each candidate with:
- `_source_sheet` — sheet name
- `_form_variant` — "2022" if 30-31 cols, "2023" if 37-38 cols
- `_currency` — "USD" or "ARS" based on which salary question is present

**For pasted data:** Structure it into the same Q&A dict format.

## Step 3 — Deduplicate against historical record

Load `eval_data.json` and check each new candidate against existing records:

- Match by **email** (case-insensitive) if available
- Match by **name** (normalized: lowercase, stripped accents via unicodedata NFKD, stripped whitespace)
- If a candidate already exists in eval_data.json, **skip them** and report the duplicate

Report: "X new candidates found, Y already in historical record (skipped)"

## Step 4 — Evaluate new candidates

For each new candidate, call the Anthropic API using the rubric from `rubric.py`:

```python
import anthropic
from rubric import SYSTEM_PROMPT, USER_PROMPT_TEMPLATE, DIMENSION_KEYS, format_candidate

client = anthropic.Anthropic()
MODEL = "claude-haiku-4-5-20251001"
```

- Use `format_candidate(row, fieldnames)` to build the prompt
- Use `USER_PROMPT_TEMPLATE.format(candidate_text=...)` for the user message
- Parse the JSON response, validate all 10 dimension keys present
- Compute composite = sum of all 10 scores
- Save raw JSON to `eval_raw/{name}.json`
- Run up to 10 concurrent evaluations
- Retry up to 3 times on failure

## Step 5 — Append to eval_data.json

For each successfully evaluated candidate, add a record to `eval_data.json["candidates"]`:

```json
{
  "name": "Full Name",
  "email": "email@example.com",
  "composite": 35,
  "sheet": "source sheet name",
  "variant": "2023",
  "currency": "USD",
  "scores": { ... },
  "linkedin": "",
  "link": "",
  "cohort_2026": false,
  "rank": null,
  "is_employee": false,
  "employee_position": null,
  "employee_hive": null
}
```

Set `cohort_2026: true` if the data comes from a 2026 campaign file or if the user indicates it's a current cohort.

## Step 6 — Recompute aggregate stats

After appending, recompute ALL top-level stats in eval_data.json:

- `total` — len(candidates)
- `compositeRange` — [min, max]
- `compositeMedian` — median of all composites
- `compositeAvg` — mean rounded to 1 decimal
- `dimensions` — for each of the 10 dimensions:
  - `avg` — mean score rounded to 1 decimal
  - `counts` — {"1": n, "2": n, "3": n, "4": n, "5": n}
  - `high`, `medium`, `low` — confidence distribution
- `cohort2026Count` — count where cohort_2026 is true
- Re-rank all candidates by composite (rank 1 = highest)

**Do NOT recompute employeeBenchmark** — that requires separate employee matching.

## Step 7 — Report

Print a summary:

```
Batch complete:
- New candidates evaluated: X
- Duplicates skipped: Y
- Errors: Z
- Historical record: N total candidates (was M)
- New batch composite range: min–max
- New batch avg: X.X
- Updated historical avg: X.X
```

List any candidates that scored above the employee average (35.3) — these are standouts worth flagging.

## Notes

- The `ANTHROPIC_API_KEY` is stored in `~/Documents/_Alpaca Labs/_Slantis/talent/.env` and loaded automatically via `python-dotenv`.
- If the user asks about a specific candidate, look them up in eval_data.json by name.
- The dashboards (dashboard.html, cohort_2026.html) read from eval_data.json and cohort_2026.json — they don't need updating unless the user asks.
- If the new data is a 2026 campaign batch, also update `cohort_2026.json` with the new candidates and their scores.
