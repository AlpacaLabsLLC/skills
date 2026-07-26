# /as:product-image-processor

Batch product image processor for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Read the named `Image URL` and `Product Name` fields from `product-library.csv`, download at full resolution, normalize sizing, and remove backgrounds.

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../../LICENSE)

### Dependencies

Requires Python 3.9+ with:

- **Pillow** — image resizing and format conversion
- **rembg + onnxruntime** — AI background removal (u2net model)

The skill auto-installs missing packages on first run. The u2net model (~170MB) downloads once and is cached.

## Usage

```
/as:product-image-processor
```

Run it inside a project containing `PROJECT.md` and `product-library.csv`.

### Output

Three folders, one per processing stage:

```
product-images-YYYY-MM-DD/
├── originals/    # Raw downloads (any format)
├── resized/      # Max 2000px longest edge, PNG
└── nobg/         # Background removed, transparent PNG
```

## How it fits

This is a **utility** that processes images from any source:

| Context | How it's used |
|---------|--------------|
| Standalone | Process named image URLs from the project product library |
| After `/as:product-spec-bulk-fetch` | Process images from fetched products |
| After `/as:product-research` | Process images from research results |
| On the project library | Process all product images in the library |

## Processing Pipeline

| Stage | What happens | Tool |
|-------|-------------|------|
| Download | `curl -L` each URL, preserve original format | curl |
| Resize | Scale to max 2000px longest edge, convert to PNG, skip upscaling | Pillow |
| BG Remove | AI background removal via u2net, output transparent PNG | rembg |

## Error Handling

Never stops a batch on a single failure:

- **Download failures** (404, timeouts) — logged and skipped
- **Resize failures** (corrupt files) — logged and skipped
- **rembg failures** (vectors, icons) — logged, original kept

After every batch: success/failure counts per stage.

## Works with

| Skill | Relationship |
|-------|-------------|
| `/as:product-research` | Processes images from research results |
| `/as:product-spec-bulk-fetch` | Processes images from fetched products |
| `/as:product-data-cleanup` | Run cleanup first, then process images |

## License

MIT
