# /as:resize-images

Batch-resizes project photos and renders for web, social, slides, and print — for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Asks for a source folder, outputs resized copies into clearly named subfolders. Originals are never modified.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

## Install

```bash
# Via plugin system
claude plugin marketplace add AlpacaLabsLLC/skills-for-architects
claude plugin install as@skills-for-architects
```

Requires [Pillow](https://pillow.readthedocs.io): `pip install Pillow`

## Usage

```
/as:resize-images
```

The skill asks which folder to use, then which outputs you need:

- **Web** — WebP at 1920px (hero), 1200px (standard), 400px (thumb)
- **Social** — center-cropped WebP: Instagram square (1080×1080), portrait (1080×1350), Twitter/X (1200×675), LinkedIn (1200×627)
- **Slides** — center-cropped JPEG: standard 4:3 (1024×768), widescreen 16:9 (1920×1080)
- **Print** — 300 DPI JPEG at ARCH A (9×12), ARCH B (12×18), ARCH C (18×24)

Output lands in `resized-web/`, `resized-social/`, `resized-slides/`, and `resized-print/` subfolders inside the source folder.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Workflow, Python resize script, size presets, edge case handling |

## License

MIT
