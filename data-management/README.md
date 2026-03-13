# Data Management

Product data management skills for Claude Code — FF&E product research, spec extraction, cleanup, PDF parsing, and image processing.

## Skills

| Skill | Description |
|-------|-------------|
| [product-research](skills/product-research/) | Product research companion — captures and organizes products into a persistent library as you browse |
| [product-spec-bulk-fetch](skills/product-spec-bulk-fetch/) | Bulk FF&E product spec extractor — fetches names, dimensions, materials, pricing from product URLs |
| [product-spec-bulk-cleanup](skills/product-spec-bulk-cleanup/) | Normalizes, translates, deduplicates, and standardizes fetched product spec data |
| [product-spec-pdf-parser](skills/product-spec-pdf-parser/) | Extracts product specifications from manufacturer PDF cut sheets |
| [product-image-processor](skills/product-image-processor/) | Downloads, crops, and standardizes product images from spec sheets |

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
