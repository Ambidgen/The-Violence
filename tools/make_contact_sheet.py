#!/usr/bin/env python3
"""Build a labelled contact sheet from captured stills.

The crayon cutscene loop's review surface: one PNG a human (or a vision model)
can judge in a pull request — every still captioned with its capture time on
paper stock, in the spirit of cinematics/scripts/sheet.mjs but dependency-light
and driven by tests/cutscene_capture.gd's output instead of Remotion.

    python3 tools/make_contact_sheet.py build/cutscene-captures/cutscene
    python3 tools/make_contact_sheet.py DIR --out sheet.png --cols 3 --width 640

Reads still_*.png / frame_*.jpg / *.png|*.jpg in DIR (sorted), writes
DIR/contact-sheet.png by default. Exits 2 when there is nothing to sheet.
Requires Pillow (pinned in tools/requirements.txt).
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:  # pragma: no cover - exercised only without Pillow
    sys.exit("make_contact_sheet: Pillow is required (pip install -r tools/requirements.txt)")

PAPER = (0xED, 0xED, 0xE8)
INK = (0x12, 0x12, 0x12)
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg"}


def find_images(directory: Path) -> list[Path]:
    images = [
        p for p in directory.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_SUFFIXES and p.name != "contact-sheet.png"
    ]
    # stills first (they carry times), then frames, then anything else; stable by name
    def key(p: Path):
        rank = 0 if p.stem.startswith("still_") else (1 if p.stem.startswith("frame_") else 2)
        return (rank, p.name)

    return sorted(images, key=key)


def label_for(path: Path) -> str:
    m = re.match(r"still_(\d+(?:\.\d+)?)s$", path.stem)
    if m:
        return f"t = {float(m.group(1)):g}s"
    m = re.match(r"frame_(\d+)$", path.stem)
    if m:
        return f"frame {int(m.group(1))}"
    return path.stem


def load_font(size: int):
    # A bundled monospace is not guaranteed; Pillow's bitmap font always is,
    # but try DejaVu first (present on Ubuntu runners) for legibility.
    for name in ("DejaVuSansMono.ttf", "DejaVuSans.ttf"):
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("directory", type=Path, help="folder of captured stills (tests/cutscene_capture.gd --out)")
    ap.add_argument("--out", type=Path, default=None, help="output PNG (default: <directory>/contact-sheet.png)")
    ap.add_argument("--cols", type=int, default=3, help="tiles across (default 3)")
    ap.add_argument("--width", type=int, default=640, help="tile width in px (default 640)")
    ap.add_argument("--title", default=None, help="title line (default: capture.json summary or folder name)")
    args = ap.parse_args()

    if not args.directory.is_dir():
        print(f"make_contact_sheet: no such directory: {args.directory}", file=sys.stderr)
        return 2
    images = find_images(args.directory)
    if not images:
        print(f"make_contact_sheet: no stills/frames in {args.directory}", file=sys.stderr)
        return 2

    title = args.title
    if title is None:
        manifest = args.directory / "capture.json"
        if manifest.exists():
            try:
                meta = json.loads(manifest.read_text())
                title = f"{args.directory.name} — {meta.get('secs', '?')}s, {meta.get('viewport', '?')}, {len(images)} image(s)"
            except (ValueError, OSError):
                title = args.directory.name
        else:
            title = args.directory.name

    cols = max(1, args.cols)
    tile_w = max(64, args.width)
    label_h, pad, title_h = 26, 12, 44

    tiles: list[tuple[Image.Image, str]] = []
    for path in images:
        img = Image.open(path).convert("RGB")
        tile_h = round(img.height * tile_w / img.width)
        tiles.append((img.resize((tile_w, tile_h)), label_for(path)))

    tile_h = max(t.height for t, _ in tiles)
    rows = (len(tiles) + cols - 1) // cols
    sheet_w = cols * tile_w + (cols + 1) * pad
    sheet_h = title_h + rows * (tile_h + label_h) + (rows + 1) * pad
    sheet = Image.new("RGB", (sheet_w, sheet_h), PAPER)
    draw = ImageDraw.Draw(sheet)
    draw.text((pad, 12), title, fill=INK, font=load_font(18))

    for i, (tile, label) in enumerate(tiles):
        r, c = divmod(i, cols)
        x = pad + c * (tile_w + pad)
        y = title_h + pad + r * (tile_h + label_h + pad)
        sheet.paste(tile, (x, y))
        draw.rectangle([x, y, x + tile_w - 1, y + tile_h - 1], outline=INK, width=2)
        draw.text((x + 4, y + tile_h + 5), label, fill=INK, font=load_font(15))

    out = args.out or (args.directory / "contact-sheet.png")
    sheet.save(out)
    print(f"make_contact_sheet: {len(tiles)} tile(s), {cols}x{rows} -> {out} ({sheet_w}x{sheet_h})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
