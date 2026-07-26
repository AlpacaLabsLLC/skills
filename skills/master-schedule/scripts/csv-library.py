#!/usr/bin/env python3
"""Validate and atomically mutate Architecture Studio CSV libraries."""

from __future__ import annotations

import argparse
import csv
import io
import json
import os
from pathlib import Path
import sys
import tempfile


PRODUCT_HEADER = (
    "Category", "Brand", "Vendor", "Thumbnail", "Product Name", "Designer",
    "Indoor/Outdoor", "Description", "SKU", "Link", "Collection", "W", "D",
    "H", "Seat H", "Unit", "Weight", "Materials", "Colors/Finishes",
    "Selected Color/Finish", "List Price", "Sale Price", "Currency", "Lead Time",
    "Warranty", "Certifications", "COM/COL", "Clipped At", "Image URL", "Tags",
    "Notes", "Status", "Source",
)
EPD_HEADER = (
    "EPD Link", "Manufacturer", "Product Name", "Description", "Declared Unit",
    "Functional Unit", "CSI Division", "Material Category", "EPD Registration No.",
    "Program Operator", "PCR Reference", "PCR Expiry", "Standard", "System Boundary",
    "Valid From", "Valid To", "GWP-total (A1-A3)", "GWP-fossil (A1-A3)",
    "GWP-biogenic (A1-A3)", "ODP (A1-A3)", "AP (A1-A3)", "EP (A1-A3)",
    "GWP (A4-A5)", "GWP (B1-B7)", "GWP (C1-C4)", "GWP (D)",
    "GWP-total (all stages)", "POCP (A1-A3)", "PERE (A1-A3)", "PENRE (A1-A3)",
    "Total Energy (A1-A3)", "FW (A1-A3)", "Recycled Content", "Waste (A1-A3)",
    "LEED Eligible", "EC3 ID", "Plant/Facility", "Country", "Parsed At", "Tags",
    "Notes", "Source",
)
SCHEMAS = {
    "product": ("product-library.csv", PRODUCT_HEADER),
    "epd": ("epd-library.csv", EPD_HEADER),
}
MISSING = object()
UNCHECKED = object()


class LibraryError(Exception):
    pass


def project_root(start: Path) -> Path:
    current = start.resolve()
    if current.is_file():
        current = current.parent
    for candidate in (current, *current.parents):
        if (candidate / "PROJECT.md").is_file():
            return candidate
    raise LibraryError("no project root found; run inside a directory governed by PROJECT.md")


def parse_bytes(data: bytes, header: tuple[str, ...], source: str) -> list[list[str]]:
    if data.startswith(b"\xef\xbb\xbf"):
        raise LibraryError(f"{source}: UTF-8 BOM is not allowed")
    try:
        text = data.decode("utf-8")
    except UnicodeDecodeError as exc:
        raise LibraryError(f"{source}: not valid UTF-8: {exc}") from exc
    try:
        rows = list(csv.reader(io.StringIO(text, newline=""), strict=True))
    except csv.Error as exc:
        raise LibraryError(f"{source}: invalid CSV: {exc}") from exc
    if not rows:
        raise LibraryError(f"{source}: file is empty")
    if rows[0] != list(header):
        duplicates = sorted({name for name in rows[0] if rows[0].count(name) > 1})
        detail = f"; duplicate columns: {', '.join(duplicates)}" if duplicates else ""
        raise LibraryError(f"{source}: header does not match the exact {len(header)}-column schema{detail}")
    for line, row in enumerate(rows[1:], 2):
        if len(row) != len(header):
            raise LibraryError(f"{source}: row {line} has {len(row)} fields; expected {len(header)}")
    return rows


def encode_rows(rows: list[list[str]], header: tuple[str, ...]) -> bytes:
    for line, row in enumerate(rows, 1):
        if len(row) != len(header):
            raise LibraryError(f"replacement row {line} has {len(row)} fields; expected {len(header)}")
    stream = io.StringIO(newline="")
    csv.writer(stream, lineterminator="\r\n", quoting=csv.QUOTE_MINIMAL).writerows(rows)
    data = stream.getvalue().encode("utf-8")
    parse_bytes(data, header, "replacement")
    return data


def atomic_write(target: Path, data: bytes, expected: bytes | object = UNCHECKED) -> None:
    temp_name: str | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="wb", prefix=".csv-library-", dir=target.parent, delete=False
        ) as handle:
            temp_name = handle.name
            handle.write(data)
            handle.flush()
            os.fsync(handle.fileno())
        if expected is MISSING:
            try:
                os.link(temp_name, target)
            except FileExistsError as exc:
                raise LibraryError(f"target appeared during validation; refusing to overwrite: {target}") from exc
            os.unlink(temp_name)
            temp_name = None
            return
        if expected is not UNCHECKED:
            try:
                current = target.read_bytes()
            except FileNotFoundError:
                current = MISSING
            if current != expected:
                raise LibraryError(f"target changed during validation; refusing to replace: {target}")
        os.replace(temp_name, target)
        temp_name = None
    finally:
        if temp_name is not None:
            try:
                os.unlink(temp_name)
            except FileNotFoundError:
                pass


def load_json(path: Path) -> object:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError) as exc:
        raise LibraryError(f"cannot read row JSON {path}: {exc}") from exc


def validate_row(value: object, header: tuple[str, ...], partial: bool = False) -> dict[str, str]:
    if not isinstance(value, dict) or not all(isinstance(k, str) and isinstance(v, str) for k, v in value.items()):
        raise LibraryError("row JSON must be an object whose keys and values are strings")
    unknown = sorted(set(value) - set(header))
    if unknown:
        raise LibraryError(f"row JSON has unknown columns: {', '.join(unknown)}")
    if not partial:
        return {name: value.get(name, "") for name in header}
    return value


def load_rows(path: Path, header: tuple[str, ...]) -> list[dict[str, str]]:
    value = load_json(path)
    values = value if isinstance(value, list) else [value]
    if not values:
        raise LibraryError("row JSON array must contain at least one row object")
    return [validate_row(row, header) for row in values]


def load_row(path: Path, header: tuple[str, ...], partial: bool = False) -> dict[str, str]:
    return validate_row(load_json(path), header, partial)


def legacy_names(root: Path) -> list[str]:
    return [name for name in ("master-schedule.json", "canoa.json") if (root / name).is_file()]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("init", "status", "validate", "import", "append", "update"))
    parser.add_argument("kind", choices=tuple(SCHEMAS))
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--source", type=Path)
    parser.add_argument("--row-json", type=Path)
    parser.add_argument("--match-column")
    parser.add_argument("--match-value")
    parser.add_argument(
        "--replace-existing",
        action="store_true",
        help="allow import to replace a populated, fully validated library",
    )
    args = parser.parse_args()

    if args.replace_existing and args.command != "import":
        raise LibraryError("--replace-existing is valid only with import")

    root = project_root(args.project)
    filename, header = SCHEMAS[args.kind]
    target = root / filename

    if args.command == "init":
        if target.exists() and target.stat().st_size:
            raise LibraryError(f"refusing to overwrite non-empty file: {target}")
        expected = target.read_bytes() if target.exists() else MISSING
        atomic_write(target, encode_rows([list(header)], header), expected)
        print(f"initialized {target}")
        return 0

    if args.command == "import":
        if args.source is None:
            raise LibraryError("import requires --source <user-exported.csv>")
        rows = parse_bytes(args.source.read_bytes(), header, str(args.source))
        target_before = target.read_bytes() if target.exists() else MISSING
        if target_before is not MISSING and target_before:
            current = parse_bytes(target_before, header, str(target))
            if len(current) > 1 and not args.replace_existing:
                raise LibraryError(f"refusing to overwrite populated library: {target}")
        atomic_write(target, encode_rows(rows, header), target_before)
        print(f"imported {len(rows) - 1} data rows into {target}")
        return 0

    if not target.is_file():
        legacy = legacy_names(root)
        if legacy:
            names = ", ".join(legacy)
            raise LibraryError(
                f"{filename} is missing; legacy configuration preserved ({names}). "
                "Export the former sheet as CSV, then import that user-exported CSV."
            )
        raise LibraryError(f"library does not exist: {target}; run init first")

    target_before = target.read_bytes()
    rows = parse_bytes(target_before, header, str(target))
    if args.command in ("status", "validate"):
        print(f"{target}: valid: {len(rows) - 1} data rows")
        legacy = legacy_names(root)
        if legacy:
            print(f"legacy configuration preserved: {', '.join(legacy)}")
        return 0

    if args.row_json is None:
        raise LibraryError(f"{args.command} requires --row-json <file>")
    if args.command == "append":
        values_list = load_rows(args.row_json, header)
        rows.extend([values[name] for name in header] for values in values_list)
        atomic_write(target, encode_rows(rows, header), target_before)
        noun = "row" if len(values_list) == 1 else "rows"
        print(f"appended {len(values_list)} {noun} to {target}")
        return 0

    if not args.match_column or args.match_value is None:
        raise LibraryError("update requires --match-column and --match-value")
    if args.match_column not in header:
        raise LibraryError(f"unknown match column: {args.match_column}")
    patch = load_row(args.row_json, header, partial=True)
    index = header.index(args.match_column)
    matches = [row for row in rows[1:] if row[index] == args.match_value]
    if len(matches) != 1:
        raise LibraryError(f"update match must identify exactly one row; found {len(matches)}")
    match = matches[0]
    for name, value in patch.items():
        match[header.index(name)] = value
    atomic_write(target, encode_rows(rows, header), target_before)
    print(f"updated 1 row in {target}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (LibraryError, OSError) as exc:
        print(f"csv-library: {exc}", file=sys.stderr)
        raise SystemExit(1)
