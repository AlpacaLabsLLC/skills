# /as:master-schedule

Initializes and inspects the current Architecture Studio project's local FF&E library at `product-library.csv`.

## Usage

```text
/as:master-schedule
```

The skill finds the nearest `PROJECT.md`, validates the complete 33-column CSV, and reports its status. With confirmation, it can create an empty library or import a user-exported CSV. Writes use deterministic RFC 4180 quoting, UTF-8 without BOM, CRLF record endings, and atomic replacement.

Legacy `master-schedule.json` and `canoa.json` files are preserved as evidence. They are not treated as product rows and are never contacted or migrated automatically.

## Files

| File | Purpose |
|---|---|
| `SKILL.md` | Local setup, status, import, and safety workflow |
| `scripts/csv-library.py` | Exact-schema validation and atomic CSV mutation |

## License

MIT
