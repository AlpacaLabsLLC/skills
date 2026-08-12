---
name: master-schedule
description: Initialize, validate, inspect, or import the current project's local FF&E product library. Use when a product workflow needs product-library.csv, when the user invokes /as:master-schedule, or when legacy master-schedule.json or canoa.json configuration is present.
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

# /as:master-schedule — Local product library

<!-- architecture-studio:harness-compatibility -->
> Harness note: use `/as:<skill>` on Claude Code and `$<skill>` on Codex. Resolve `<skill-root>` as the directory containing this loaded `SKILL.md` and `<plugin-root>` as the plugin root that contains `skills/`, and use equivalent native tools when host tool names differ.

Manage the current project's `product-library.csv`. This workflow is local-only: do not use a network service, connector, account, spreadsheet identifier, or MCP tool.

Use the deterministic helper instead of constructing or changing CSV with ad hoc shell or prompt logic:

```bash
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" status product
```

The helper resolves the nearest project root by walking upward to `PROJECT.md`. The canonical schema is `<plugin-root>/schema/product-schema.md`; storage rules are in `<plugin-root>/schema/csv-conventions.md`.

## Automatic use by product skills

1. Run `status product` from the user's current working directory.
2. If the valid library exists, continue silently.
3. If it is missing and no legacy configuration exists, preview creation at the resolved project root. Use the single interaction gate once, then run `init product` after confirmation.
4. If the library is invalid, stop. Explain the header or row error and leave the file unchanged.
5. Never initialize outside a directory governed by `PROJECT.md`.

## Manual use

When the user invokes `/as:master-schedule` directly:

- Existing valid library: report its path and data-row count from `status product`.
- Missing library: preview the exact path, explain that initialization creates only the 33-column header, use one confirmation gate, then run `init product`.
- Invalid library: report the validation failure without writing.
- Empty existing file: it may be initialized after the same preview and confirmation.

Do not ask in prose whether to proceed immediately before presenting an approval gate. The gate itself is the question.

## User-exported CSV import

Import is explicit and never automatic:

```bash
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" import product --source "/absolute/path/to/user-exported.csv"
```

Before import, state the source and target paths and that the complete source will be validated against the exact 33-column schema. Use one confirmation gate. The helper refuses a malformed source and refuses to overwrite a populated target.

For a reviewed operation that intentionally replaces the complete populated library, use the explicit replacement flag after preview and confirmation:

```bash
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" import product --source "/absolute/path/to/reviewed-library.csv" --replace-existing
```

This validates the complete candidate and current library before one guarded atomic replacement. It fails closed if either file is malformed or if the target changes after validation. Never add this flag to ordinary setup or import.

## Legacy evidence

`master-schedule.json` and `canoa.json` may point to a library used by an earlier release. They contain configuration, not recoverable rows.

- Preserve both files byte-for-byte.
- Do not rename, delete, rewrite, or contact anything named inside them.
- Explain that connectivity was removed in Architecture Studio 1.4.
- Ask the user to export the former library as CSV, then use the explicit user-exported CSV import flow.

## Mutation boundary for other skills

Use the same helper for safe operations:

```bash
# Validate the complete file
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" validate product

# Append values supplied as a JSON object keyed by schema column
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" append product --row-json "/path/to/row.json"

# Update exactly one matched row with a partial JSON object
python3 "<plugin-root>/skills/master-schedule/scripts/csv-library.py" update product --match-column "SKU" --match-value "ABC-123" --row-json "/path/to/changes.json"
```

All mutations validate the complete existing file before writing and atomically replace it from a temporary file in the same directory. A failed validation or mutation must leave the source unchanged.
