# /as:nyc-dob-violations

DOB and ECB violation lookup for any NYC building as a [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill. Queries DOB violations, ECB (Environmental Control Board) violations, and active/open violations — flagging open items prominently. No API key required.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

```
/as:nyc-dob-violations 120 Broadway, Manhattan
/as:nyc-dob-violations 1000770001          (BBL)
/as:nyc-dob-violations 1001389             (BIN)
```

The skill:

1. **Resolves the property** via PLUTO — gets BBL and building metadata (BIN via Building Footprints when needed)
2. **Queries three violation datasets** — DOB violations, ECB violations, and active/open violations
3. **Flags open violations** with a warning indicator at the top of the report
4. **Presents all violations** — with types, dates, dispositions, and ECB penalty amounts

## Data Sources

| Source | Dataset ID | What it provides |
|--------|-----------|-----------------|
| PLUTO | `64uk-42ks` | Address resolution, BBL/BIN |
| DOB Violations | `3h2n-5cm9` | Violation type, issue date, category, disposition |
| DOB ECB Violations | `6bgk-3dad` | ECB violation type, date, penalties assessed/paid/balance due |
| DOB Active Violations | `sjhj-bc8q` | Pre-filtered currently open violations |

## Output

Inline markdown with open violation count, open violations table, full DOB violations history, ECB violations with penalty amounts, and total penalties assessed/balance due.

## License

MIT
