# /as:product-data-import

Turn raw product lists into formatted FF&E specification schedules for Claude Code.

Markdown previews remain in conversation; approved persistent rows are appended to the nearest project's `product-library.csv` using the shared 33-column schema.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:product-data-import
```

Then provide products in any format — notes, CSV, file path, or conversation.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition and implementation |

## License

MIT
