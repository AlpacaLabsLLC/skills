# CSV Library Conventions

Architecture Studio stores persistent product data in project-local CSV files:

- `product-library.csv` uses the exact 33-column header in [product-schema.md](product-schema.md).
- `epd-library.csv` uses the exact 42-column header in [epd-schema.md](epd-schema.md) and is optional.

## File contract

- UTF-8 without a byte-order mark (BOM).
- One header row followed by zero or more data rows.
- Exact, case-sensitive header names and deterministic column order.
- RFC 4180-compatible quoting. Fields containing commas, double quotes, CR, or LF are quoted; embedded double quotes are doubled.
- CRLF record endings for deterministic writes. Embedded newlines remain part of quoted fields.
- Empty fields represent unavailable values. Do not write `null`, `N/A`, `—`, or `-` as placeholders.
- URL fields contain plain URLs, never spreadsheet formulas.

## Project boundary

Resolve the project root by walking from the working directory toward the filesystem root and selecting the nearest directory containing `PROJECT.md`. Store both libraries at that root. Do not create a library outside a recognized project.

## Safe mutation

Before any mutation:

1. Decode as UTF-8 without accepting a BOM.
2. parse the entire CSV in strict mode;
3. verify the exact header and every row's field count;
4. construct and validate the complete replacement in memory;
5. preview material changes and use the repository's single confirmation gate when user approval is required;
6. write a temporary file in the target directory, flush and sync it, then replace the target atomically.

If decoding, parsing, or validation fails, leave the target byte-for-byte unchanged and remove any temporary file. Last-writer conflicts remain possible because CSV does not provide multi-user locking; validate again immediately before replacement.

## Legacy configuration

`master-schedule.json` and `canoa.json` are evidence of an older cloud configuration, not local row data. Preserve them byte-for-byte. If no CSV exists, ask the user to export the former sheet as CSV and explicitly import that file. Never contact a remote sheet or claim its rows were migrated from JSON.
