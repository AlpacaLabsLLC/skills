---
name: resize-images
description: Batch-resize or convert a folder of images for web, social media, slides, or ARCH-size print output while preserving originals. Use for image resizing, format presets, or photo batches; not for product-image background removal.
allowed-tools:
  - Read
  - Bash
  - Glob
  - AskUserQuestion
---

# /as:resize-images — Image Resizer for Web, Social, and Print

Resize project photos and renders for web publishing, social media, and print layouts. Always asks the user for the source folder before doing anything. Outputs resized copies into clearly named subfolders — originals are never modified.

## Step 1: Ask for the source folder

Before doing anything else, ask:

> "Which folder contains the images you'd like to resize?"

Wait for the user's response. Accept any valid path — absolute, relative, or with `~`. Expand `~` to the user's home directory.

Then ask:

> "Which outputs do you need? (choose one or more)
> - **Web** — WebP at 1920px (hero), 1200px (standard), 400px (thumb)
> - **Social** — center-cropped WebP: Instagram square (1080×1080), Instagram portrait (1080×1350), Twitter/X (1200×675), LinkedIn (1200×627)
> - **Slides** — center-cropped JPEG: standard 4:3 (1024×768), widescreen 16:9 (1920×1080)
> - **Print** — 300 DPI JPEG at ARCH A (9×12), ARCH B (12×18), ARCH C (18×24)
> - **All**"

## Step 2: Scan the folder

List supported files non-recursively: `.jpg`, `.jpeg`, `.png`, `.tif`, `.tiff`, and `.webp`. Report the count: `"Found N image(s) in [folder]. Ready to resize."`

If the folder is empty or contains no supported images, tell the user and stop.

## Step 3: Check for Pillow

Confirm Pillow is available:

```bash
python3 -c "import PIL; print('ok')" 2>/dev/null || echo "missing"
```

If missing, tell the user:

> "Pillow isn't installed. Run `pip install Pillow` then try again."

Stop if Pillow is unavailable.

## Step 4: Resize images

Run the bundled processor once, passing the source folder and selected modes:

```bash
python3 "${CLAUDE_PLUGIN_ROOT}/skills/resize-images/scripts/resize_images.py" "<folder>" web social slides print
```

Include only selected modes. The script creates the matching `resized-<mode>/` folders, preserves originals, reports each output, continues past corrupt inputs, and exits nonzero if any input fails. Never recreate or modify the script inline.

## Step 6: Report results

After all files are processed, show a summary:

```
Resized N image(s) → [folder]/resized-web/, resized-social/, resized-print/

Web (resized-web/):
  project-photo-hero.webp          (1920×1385)   138 KB
  project-photo-standard.webp      (1200×866)     62 KB
  project-photo-thumb.webp         (400×288)      11 KB

Social (resized-social/):
  project-photo-social-square.webp    (1080×1080)   74 KB
  project-photo-social-portrait.webp  (1080×1350)   91 KB
  project-photo-social-landscape.webp (1200×675)    65 KB
  project-photo-social-linkedin.webp  (1200×627)    63 KB

Print (resized-print/):
  project-photo-arch-a.jpg         (2700×1949)   959 KB
  project-photo-arch-b.jpg         (3600×2599)  1698 KB
  project-photo-arch-c.jpg         (5019×3623)  3470 KB
```

If any files failed, list them with their error messages.

## Edge Cases

- **Social and slides crops** — center crop always; if a subject is off-center, the user should crop manually before running the skill
- **Portrait images (web/print)** — aspect ratio is always preserved; the image fits within the target dimensions, so a portrait image will be narrower than the target width
- **Images already smaller than the target** — web sizes: skip upscaling, save as-is with the size label; print sizes: save at original resolution with 300 DPI tag; social: upscale to fill (center crop still applies)
- **RGBA / PNG with transparency** — convert to RGB before saving (JPEG and most social WebP don't support alpha)
- **Duplicate filenames** — if two source files share a stem after stripping extension, the second will overwrite the first; warn the user if this happens
- **Read errors** — catch and report per-file, continue processing the rest
