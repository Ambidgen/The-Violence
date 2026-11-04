#!/usr/bin/env python3
"""Generate the top-down character parts used by the animated rig.

The source shapes and the three textured/hand-wobbled PNG frames are original art,
rendered from the same primitives.  Nothing in this file is needed by the game at
runtime.  Figures face +x and use the existing 80 px/metre asset convention.

    python3 -m pip install Pillow==13.0.0
    python3 tools/make_character_assets.py
    python3 tools/make_character_assets.py --check
"""
from __future__ import annotations

import argparse
import hashlib
import io
import math
from pathlib import Path
import random
import sys
from xml.sax.saxutils import escape

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
INK = "#201d1a"
SKIN = "#d6a27f"
BOOT = "#171717"
GOLD = "#e5b853"
# key: (body, dark shade, highlight, head/hair, decoration)
LOOKS = {
    "patrol": ("#304d84", "#1a294a", "#7895b7", "#202f56", "badge"),
    "swat": ("#343e4b", "#1b222b", "#8a9daa", "#262e36", "webbing"),
    "riot": ("#2b4265", "#19283d", "#aac1ce", "#1f3049", "stripe"),
    "hood": ("#866047", "#4d392e", "#bf9672", "#372b25", "hood"),
    "leather": ("#694b42", "#392b29", "#b78065", "#211e1d", "zip"),
    "workcoat": ("#6d704e", "#393f2c", "#a7aa7b", "#514232", "pockets"),
    "track": ("#526963", "#30433f", "#c4b899", "#302823", "track"),
    "vestlook": ("#796f5d", "#393b37", "#b7a48c", "#272521", "vest"),
}
CUSTOM_KIT = ("riot_head",)


def stable_seed(name: str, variant: int) -> int:
    return int.from_bytes(hashlib.sha256(f"{name}:{variant}".encode()).digest()[:8], "big")


class Canvas:
    """Small vector canvas, rendered identically to SVG and to supersampled PNG."""

    def __init__(self, width: int, height: int, seed: int):
        self.width, self.height = width, height
        self.rng = random.Random(seed)
        self.items: list[tuple] = []

    def ellipse(self, pen, x, y, rx, ry, fill, stroke=INK, width=1.8, wobble=0.055):
        pts = []
        for i in range(24):
            a = math.tau * i / 24
            rad = 1 + self.rng.uniform(-wobble, wobble)
            pts.append(pen.point(x + math.cos(a) * rx * rad, y + math.sin(a) * ry * rad))
        self.items.append(("polygon", pts, fill, stroke, width))

    def polygon(self, pen, points, fill, stroke=INK, width=1.6):
        self.items.append(("polygon", [pen.point(*p) for p in points], fill, stroke, width))

    def line(self, pen, points, color, width=1.5):
        self.items.append(("line", [pen.point(*p) for p in points], "none", color, width))

    def svg(self) -> bytes:
        s = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.width}" height="{self.height}" viewBox="0 0 {self.width} {self.height}">']
        for kind, pts, fill, stroke, width in self.items:
            coords = " ".join(f"{x:.2f},{y:.2f}" for x, y in pts)
            tag = "polygon" if kind == "polygon" else "polyline"
            s.append(f'<{tag} points="{coords}" fill="{escape(fill)}" stroke="{escape(stroke)}" stroke-width="{width:.2f}" stroke-linejoin="round" stroke-linecap="round"/>')
        s.append("</svg>\n")
        return "".join(s).encode()

    def png(self, seed: int) -> bytes:
        # Four samples per dimension keep the existing sprite sizes and smooth edges.
        scale = 4
        im = Image.new("RGBA", (self.width * scale, self.height * scale))
        d = ImageDraw.Draw(im)
        for kind, pts, fill, stroke, width in self.items:
            p = [(round(x * scale), round(y * scale)) for x, y in pts]
            sw = max(1, round(width * scale))
            if kind == "polygon":
                d.polygon(p, fill=fill)
                if stroke != "none":
                    d.line(p + [p[0]], fill=stroke, width=sw, joint="curve")
            else:
                d.line(p, fill=stroke, width=sw, joint="curve")
                for x, y in (p[0], p[-1]):
                    r = sw / 2
                    d.ellipse((x-r, y-r, x+r, y+r), fill=stroke)
        im = im.resize((self.width, self.height), Image.Resampling.LANCZOS)
        # Fine, deterministic crayon grain: preserve transparency and dark ink.
        rng = random.Random(seed ^ 0xB047)
        pix = im.load()
        for y in range(self.height):
            for x in range(self.width):
                r, g, b, a = pix[x, y]
                if a < 32:
                    continue
                grain = rng.uniform(-0.095, 0.065) + 0.025 * math.sin(x * 1.05 - y * 0.8)
                if max(r, g, b) < 55:
                    grain *= 0.35
                pix[x, y] = tuple(max(0, min(255, round(c * (1 + grain)))) for c in (r, g, b)) + (a,)
        out = io.BytesIO()
        im.save(out, format="PNG", optimize=True)
        return out.getvalue()


class Pen:
    def __init__(self, canvas: Canvas, origin, angle=0.0):
        self.c, self.origin, self.angle = canvas, origin, angle

    def point(self, x, y):
        co, si = math.cos(self.angle), math.sin(self.angle)
        return (self.origin[0] + x * co - y * si, self.origin[1] + x * si + y * co)

    def child(self, x, y):
        return Pen(self.c, self.point(x, y), self.angle)

    def ellipse(self, x, y, rx, ry, fill, stroke=INK, width=1.8, wobble=0.055):
        self.c.ellipse(self, x, y, rx, ry, fill, stroke, width, wobble)

    def poly(self, points, fill, stroke=INK, width=1.6):
        self.c.polygon(self, points, fill, stroke, width)

    def line(self, points, color, width=1.5):
        self.c.line(self, points, color, width)


def star(p: Pen, x: float, y: float, radius=3.8):
    pts = []
    for i in range(10):
        r = radius if i % 2 == 0 else radius * .46
        a = math.tau * i / 10 - math.pi / 2
        pts.append((x + math.cos(a) * r, y + math.sin(a) * r))
    p.poly(pts, GOLD, "none", 0)


def torso(p: Pen, style: str, lying=False):
    body, shade, light, _, mark = LOOKS[style]
    rx, ry = (27, 16) if lying else (10.5, 21.5)
    p.ellipse(-4, 0, rx, ry, body, INK, 2.8)
    # Short pencil hatching stays inside the body, so silhouettes stay legible at zoom.
    if lying:
        for j in range(-2, 3):
            p.line([(-20, j * 5 - 4), (9, j * 5 + 4)], shade, 1.7)
        if mark in ("badge", "webbing", "stripe"):
            star(p, 7, -7, 3.0)
        elif mark == "track":
            p.line([(-20, -7), (9, -7)], light, 2.1)
        elif mark == "hood":
            p.ellipse(-23, 0, 5, 9, shade, INK, 1.2)
        elif mark == "zip":
            p.line([(-14, 0), (17, 0)], light, 1.5)
        elif mark == "pockets":
            p.poly([(-8, -10), (3, -10), (3, -4), (-8, -4)], shade, light, 1)
        elif mark == "vest":
            p.line([(-12, -9), (10, -9)], light, 2)
        return
    for y in (-14, -5, 4, 13):
        p.line([(-11, y - 3), (2, y + 3)], shade, 1.6)
    if mark == "badge":
        p.line([(-11, -16), (-11, 16)], light, 2.5)  # duty belt
        p.line([(-2, -18), (5, -14)], light, 2)      # epaulette
        p.line([(-2, 18), (5, 14)], light, 2)
        star(p, 2, -8)
    elif mark == "webbing":
        p.line([(-9, -16), (-9, 16)], light, 2.0)
        p.line([(-2, -13), (-2, 13)], shade, 3.0)
        for y in (-8, 0, 8):
            p.line([(-6, y), (3, y)], light, 1.7)
        p.poly([(1, -17), (7, -15), (7, -9), (1, -9)], "#c4ced0", INK, .7)
    elif mark == "stripe":
        p.line([(-10, -16), (-10, 16)], light, 3.5)
        p.line([(-1, -17), (5, -14)], "#e1e4d5", 2.4)
        p.line([(-1, 17), (5, 14)], "#e1e4d5", 2.4)
        star(p, 3, -7, 3.0)
    elif mark == "hood":
        p.ellipse(-12, 0, 5, 9, shade, INK, 1.5)
        p.line([(-7, -11), (0, -8), (3, -4)], light, 1.8)
    elif mark == "zip":
        p.line([(1, -15), (1, 15)], light, 1.6)
        p.line([(-4, -16), (3, -9), (5, -4)], shade, 2.0)
    elif mark == "pockets":
        p.poly([(-1, -14), (5, -14), (5, -7), (-1, -7)], shade, light, .8)
        p.poly([(-1, 7), (5, 7), (5, 14), (-1, 14)], shade, light, .8)
        p.line([(-9, -18), (-5, -12)], light, 1.5)
    elif mark == "track":
        p.line([(-9, -17), (-9, 17)], light, 2.1)
        p.line([(-4, -16), (-4, 16)], light, 1.5)
    elif mark == "vest":
        p.poly([(-7, -14), (4, -12), (5, 12), (-7, 14)], shade, INK, 1.0)
        p.line([(-1, -11), (-1, 11)], light, 1.4)
        p.line([(-7, -9), (-3, -9)], light, 1.6)
        p.line([(-7, 9), (-3, 9)], light, 1.6)


def head(p: Pen, style: str):
    body, shade, light, hair, mark = LOOKS[style]
    if style == "patrol":
        p.ellipse(0, 0, 11.4, 11.1, hair, INK, 2)
        p.line([(9, -9), (11, 0), (9, 9)], "#111924", 3.7)
        p.line([(-8, -5), (7, -5)], light, 1.2)
        star(p, 4, 0, 2.9)
    elif style == "riot":
        # Soft public-order cap, not a protective helmet. An equipped helmet/visor is a separate overlay.
        p.ellipse(0, 0, 11.4, 11.1, hair, INK, 2)
        p.line([(7, -9), (8, 0), (7, 9)], light, 2.4)
        p.line([(-8, -6), (4, -6)], body, 1.7)
        star(p, 3, 0, 2.7)
    elif style == "swat":
        # Knit cap, not ballistic protection; a real equipped helmet is shown separately.
        p.ellipse(1, 0, 10.6, 10.4, SKIN, INK, 2)
        p.ellipse(-3, 0, 9.8, 10.9, hair, INK, 1.7)
        p.line([(4, -9), (4, 9)], light, 1.8)
        p.line([(-8, -4), (1, -4)], shade, 1.5)
    else:
        p.ellipse(1, 0, 10.7, 10.5, SKIN, INK, 2)
        if style == "hood":
            p.ellipse(-3, 0, 10.2, 11, shade, INK, 1.8)
            p.line([(4, -8), (6, 0), (4, 8)], light, 1.6)
        elif style == "workcoat":
            p.ellipse(-3, 0, 10, 10.5, hair, INK, 1.5)
            p.line([(5, -8), (5, 8)], "#c3a67b", 2.0)
        else:
            p.ellipse(-4, 0, 8.8, 10.1, hair, INK, 1.4)
            for y in (-6, -2, 2, 6):
                p.line([(-9, y - 2), (-2, y + 1)], "#514237", 1.3)
        p.line([(10, -1), (12, 0)], INK, 1.5)  # nose points forward


def limbs(p: Pen, body: str, shade: str, pose: int):
    # Whole limbs and boots; no injury is painted. Octants vary the fall silhouette.
    side_bias = ((pose % 3) - 1) * 3.0
    for side in (-1, 1):
        hip = (-23, side * 7)
        knee = (-37, side * (10 + (pose % 2) * 2))
        foot = (-54 + side_bias, side * (15 + ((pose + 1) % 3) * 2))
        p.line([hip, knee, foot], shade, 8.5)
        p.ellipse(foot[0] - 5, foot[1], 7.8, 5.1, BOOT, INK, 1.3)
    for side in (-1, 1):
        shoulder = (9, side * 12)
        elbow = (13 + side_bias, side * 25)
        hand = (27 - side_bias, side * (36 - (pose % 2) * 4))
        p.line([shoulder, elbow, hand], body, 7.4)
        p.ellipse(*hand, 4.7, 4.7, SKIN, INK, 1.2)


def render_part(style: str, part: str, variant: int) -> Canvas:
    if part == "torso":
        size = (64, 64)
    elif part == "head":
        size = (32, 32)
    elif part == "stand":
        size = (96, 96)
    elif part == "down":
        size = (152, 96)
    else:
        size = (176, 176)
    canvas = Canvas(*size, stable_seed(style + "_" + part, variant))
    angle = (int(part[4:]) * math.tau / 8) if part.startswith("dead") else 0.0
    p = Pen(canvas, (size[0] / 2, size[1] / 2), angle)
    if part == "torso":
        torso(p, style)
    elif part == "head":
        head(p, style)
    elif part == "stand":
        # A useful static preview; the game animates torso, head and limbs independently.
        body, shade, *_ = LOOKS[style]
        p.line([(-11, -13), (-19, -25)], body, 7)
        p.line([(-11, 13), (-19, 25)], body, 7)
        p.ellipse(-21, -26, 4.7, 4.7, SKIN, INK, 1)
        p.ellipse(-21, 26, 4.7, 4.7, SKIN, INK, 1)
        p.line([(-17, -8), (-31, -11)], shade, 7)
        p.line([(-17, 8), (-31, 11)], shade, 7)
        p.ellipse(-33, -11, 6, 4, BOOT, INK, 1)
        p.ellipse(-33, 11, 6, 4, BOOT, INK, 1)
        torso(p, style)
        head(p.child(12, 0), style)
    else:
        body, shade, *_ = LOOKS[style]
        limbs(p, body, shade, int(part[4:]) if part.startswith("dead") else 0)
        torso(p, style, lying=True)
        head(p.child(31, 1), style)
    return canvas


def render_riot_helmet(variant: int) -> Canvas:
    c = Canvas(32, 32, stable_seed("riot_head", variant))
    p = Pen(c, (16, 16))
    p.ellipse(-1, 0, 12.4, 12.2, "#26374f", INK, 2.1)
    for y in (-6, -2, 2, 6):
        p.line([(-8, y - 2), (2, y + 2)], "#496278", 1.4)
    # Visor reads as a curved pale edge beyond the head, not a separate shield.
    p.line([(7, -10), (11, -8), (13, 0), (11, 8), (7, 10)], "#c4dde0", 2.3)
    p.line([(8, -6), (10, -3)], "#f0f2e6", 1.4)
    return c


def outputs():
    parts = ["torso", "head", "stand", "down"] + [f"dead{k}" for k in range(8)]
    for style in LOOKS:
        for part in parts:
            key = f"op/{style}_{part}"
            for v in range(3):
                art = render_part(style, part, v)
                if v == 0:
                    yield ROOT / f"assets/svg/{key}.svg", art.svg()
                yield ROOT / f"assets/crayon/{key}_{v}.png", art.png(stable_seed(key, v))
    for item in CUSTOM_KIT:
        key = f"kit/{item}"
        for v in range(3):
            art = render_riot_helmet(v)
            if v == 0:
                yield ROOT / f"assets/svg/{key}.svg", art.svg()
            yield ROOT / f"assets/crayon/{key}_{v}.png", art.png(stable_seed(key, v))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="compare instead of writing assets")
    args = parser.parse_args()
    count = 0
    mismatches = []
    for path, data in outputs():
        count += 1
        if args.check:
            if not path.is_file() or path.read_bytes() != data:
                mismatches.append(path.relative_to(ROOT))
        else:
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
    if mismatches:
        print("Character assets missing or different:", *mismatches, sep="\n  ", file=sys.stderr)
        return 1
    print(f"{'Checked' if args.check else 'Wrote'} {count} character asset files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
