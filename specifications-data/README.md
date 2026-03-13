# Specifications & Data

FF&E specifications and product data skills for Claude Code — bulk extraction, cleanup, image processing, PDF parsing, spec writing, and redline review.

## Skills

| Skill | Description |
|-------|-------------|
| [product-spec-bulk-fetch](skills/product-spec-bulk-fetch/) | Bulk FF&E product spec extractor — fetches names, dimensions, materials, pricing from product URLs |
| [product-spec-bulk-cleanup](skills/product-spec-bulk-cleanup/) | Normalizes, translates, deduplicates, and standardizes fetched product spec data |
| [product-spec-pdf-parser](skills/product-spec-pdf-parser/) | Extracts product specifications from manufacturer PDF cut sheets |
| [product-image-processor](skills/product-image-processor/) | Downloads, crops, and standardizes product images from spec sheets |
| [spec-writer](skills/spec-writer/) | CSI outline specification writer — maps materials to MasterFormat 2020 divisions with three-part specs |
| [redline-punch-list](skills/redline-punch-list/) | Generates punch lists and redline reviews from construction documents |

## Commands

| Command | Description |
|---------|-------------|
| [spec-package](commands/spec-package.md) | Full FF&E pipeline — bulk fetch, cleanup, and image processing in sequence |

## Install

```bash
git clone https://github.com/AlpacaLabsLLC/skills.git
# Then symlink individual skills or install the full plugin
```

## License

MIT
