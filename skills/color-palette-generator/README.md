# /as:color-palette-generator

Generates harmonious color palettes from descriptions, moods, images, or reference brands for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Outputs a self-contained HTML file with visual swatches, color codes, contrast ratios, and example pairings.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

## Usage

From a text description:

```
/as:color-palette-generator warm earth tones for a desert spa
```

From an image:

```
/as:color-palette-generator ~/Documents/Screenshots/inspiration.png
```

From a single starting color:

```
/as:color-palette-generator build a palette from #2D5A3D
```

From a brand reference:

```
/as:color-palette-generator Aesop meets Ace Hotel
```

The skill generates 8-12 colors (primary, secondary, neutral, accent), checks WCAG contrast ratios, and writes a styled `.html` file to `./palette-[name-slug].html` in the current working directory.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Persona, color theory rules, palette structure, HTML output spec |

## License

MIT
