# /product-image-processor

Batch product image processor for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Read image URLs from a Google Sheet, download at full resolution, normalize sizing, and remove backgrounds — saving output at each stage.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
ln -s "$(pwd)/skills/product-image-processor" ~/.claude/skills/product-image-processor
```

### Dependencies

Requires Python 3.9+ with:

- **Pillow** — image resizing and format conversion
- **rembg + onnxruntime** — AI background removal (u2net model)

The skill auto-installs missing packages on first run. The u2net model (~170MB) downloads once and is cached at `~/.u2net/`.

## Usage

```
/product-image-processor
```

Then provide a Google Sheet ID and tell it which column has image URLs. Optionally specify a name column for file naming and a custom output path.

```
/product-image-processor

Sheet: 1FMScYW9guezOWc_m4ClTQxxFIpS6TNRr373R-MJGzgE
Image URL column: AC
Name column: C (Product Name)
Output: ~/Documents/Work-Docs/product-images-2026-03-04/
```

### Input

- **Google Sheet** — spreadsheet ID + column letter or header name containing image URLs
- **Name column** (optional) — adjacent column with product names for file naming; otherwise names are derived from the URL

### Output

Three folders, one per processing stage:

```
product-images-YYYY-MM-DD/
├── originals/    # Raw downloads (any format)
├── resized/      # Max 2000px longest edge, PNG
└── nobg/         # Background removed, transparent PNG
```

## Demo: 14-Product Batch

Real output from a Norma Jean FF&E schedule with 14 product URLs across IKEA, Herman Miller, RH, and local Uruguayan vendors:

```
## Product Image Processing Complete

Output: ~/Documents/Work-Docs/product-images-2026-03-04/

| Stage       | Success | Failed |
|-------------|---------|--------|
| Downloaded  | 14      | 0      |
| Resized     | 14      | 0      |
| BG Removed  | 14      | 0      |

Files:
  001-vardagen-vaso.png          250x250
  002-kvot.png                   250x250
  003-soria-teak-lounge.png      1200x985
  004-ateco-icing-spatula.png    800x800
  005-eames-lcw-red-stain.png    750x1000
  006-eames-lcw-natural.png      862x1000
  ...
  012-silla-plona-verde.png      2000x1583  (scaled from 3118px)
  014-pedrali-osaka-armchair.png 1000x1000
```

## Processing Pipeline

| Stage | What happens | Tool |
|-------|-------------|------|
| Download | `curl -L` each URL, preserve original format | curl |
| Resize | Scale to max 2000px longest edge, convert to PNG, skip upscaling | Pillow |
| BG Remove | AI background removal via u2net, output transparent PNG | rembg |

## Error Handling

The skill never stops a batch on a single failure:

- **Download failures** (404, timeouts) — logged and skipped, batch continues
- **Resize failures** (corrupt files) — logged and skipped in subsequent stages
- **rembg failures** (vectors, icons) — logged, original kept in `resized/`
- **Sheet read errors** — stops and asks user to verify spreadsheet ID and column

After every batch: success/failure counts per stage with reasons for any failures.

## What's Included

| File | Purpose |
|------|---------|
| `SKILL.md` | Download, resize, and bg-removal workflow with Python scripts |

## Pairs With

Use [`/product-spec-bulk-fetch`](../product-spec-bulk-fetch) to extract product specs and image URLs from vendor pages into a Google Sheet, then run `/product-image-processor` on that sheet to download and process all images. **Fetch specs → process images → spec-ready assets.**

## License

MIT
