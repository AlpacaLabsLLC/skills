#!/usr/bin/env python3
"""Resize supported images into Architecture Studio web/social/slide/print sets."""

from __future__ import annotations

import argparse
from pathlib import Path

try:
    from PIL import Image
except ModuleNotFoundError:
    Image = None  # type: ignore[assignment]

EXTENSIONS = {".jpg", ".jpeg", ".png", ".tif", ".tiff", ".webp"}
WEB_SIZES = (("hero", 1920), ("standard", 1200), ("thumb", 400))
SOCIAL_SIZES = (("social-square", (1080, 1080)), ("social-portrait", (1080, 1350)), ("social-landscape", (1200, 675)), ("social-linkedin", (1200, 627)))
SLIDE_SIZES = (("slides-standard", (1024, 768)), ("slides-wide", (1920, 1080)))
PRINT_SIZES = (("arch-a", (2700, 3600)), ("arch-b", (3600, 5400)), ("arch-c", (5400, 7200)))


def center_crop(image: Image.Image, width: int, height: int) -> Image.Image:
    scale = max(width / image.width, height / image.height)
    resized = image.resize((int(image.width * scale), int(image.height * scale)), Image.Resampling.LANCZOS)
    left = (resized.width - width) // 2
    top = (resized.height - height) // 2
    return resized.crop((left, top, left + width, top + height))


def save(image: Image.Image, path: Path, format_name: str, **kwargs: object) -> None:
    image.save(path, format_name, **kwargs)
    print(f"  {path.name} ({image.width}x{image.height}) {path.stat().st_size // 1024} KB")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("folder", type=Path)
    parser.add_argument("modes", nargs="+", choices=("web", "social", "slides", "print"))
    args = parser.parse_args()
    if Image is None:
        parser.error("Pillow is required; install it with: python3 -m pip install Pillow")
    folder = args.folder.expanduser().resolve()
    if not folder.is_dir():
        parser.error(f"not a directory: {folder}")
    images = sorted(path for path in folder.iterdir() if path.is_file() and path.suffix.lower() in EXTENSIONS)
    if not images:
        print(f"No supported images found in {folder}")
        return 1
    for mode in set(args.modes):
        (folder / f"resized-{mode}").mkdir(exist_ok=True)
    failures = 0
    for source in images:
        try:
            with Image.open(source) as opened:
                image = opened.convert("RGB") if opened.mode not in ("RGB", "L") else opened.copy()
            print(f"Processing: {source.name} ({image.width}x{image.height})")
            if "web" in args.modes:
                for label, max_width in WEB_SIZES:
                    output = image.copy()
                    if output.width > max_width:
                        output = output.resize((max_width, int(output.height * max_width / output.width)), Image.Resampling.LANCZOS)
                    save(output, folder / "resized-web" / f"{source.stem}-{label}.webp", "WEBP", quality=82)
            if "social" in args.modes:
                for label, size in SOCIAL_SIZES:
                    save(center_crop(image, *size), folder / "resized-social" / f"{source.stem}-{label}.webp", "WEBP", quality=85)
            if "slides" in args.modes:
                for label, size in SLIDE_SIZES:
                    save(center_crop(image, *size), folder / "resized-slides" / f"{source.stem}-{label}.jpg", "JPEG", quality=92)
            if "print" in args.modes:
                for label, size in PRINT_SIZES:
                    output = image.copy()
                    output.thumbnail(size, Image.Resampling.LANCZOS)
                    save(output, folder / "resized-print" / f"{source.stem}-{label}.jpg", "JPEG", quality=95, dpi=(300, 300))
        except Exception as exc:  # continue the batch while reporting each bad input
            failures += 1
            print(f"ERROR: {source.name} - {exc}")
    print(f"Done: {len(images) - failures} succeeded, {failures} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
