#!/usr/bin/env python3
"""Generate ORIGINAL placeholder SVG art for "The Violence" vertical slice.

Stdlib only, deterministic. Everything is drawn in plan view (top-down, 90 deg),
in the visual language of an architectural floor plan: thin ink lines, white or
grey fills. The only colour anywhere is blood red.

Scale: 80 px per metre (2x the in-game 40 px/m), so sprites stay crisp when the
camera zooms in. Sprites are placed at scale 0.5 by the game.
Facing: every figure and weapon faces +x (east), which is Godot's rotation 0.

    python3 tools/make_placeholders.py            # writes assets/svg/
    python3 tools/make_placeholders.py --list

Godot drops <text> in SVGs, so there is no text in any file.
"""
import argparse
import json
import math
import os
import random

PPM = 80  # pixels per metre in the SVG files
INK = "#1c1c1c"
LINE = "#3a3a3a"
FAINT = "#8a8a8a"
WHITE = "#ffffff"
PAPER = "#f4f4f4"
GREY_L = "#d9d9d9"
GREY_M = "#a6a6a6"
GREY_D = "#6b6b6b"
BLOOD = "#7d0a0a"
BLOOD_D = "#560505"
BLOOD_L = "#a01212"


def svg(w_m, h_m, body, defs=""):
    w, h = round(w_m * PPM), round(h_m * PPM)
    d = f"<defs>{defs}</defs>" if defs else ""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" '
            f'viewBox="0 0 {w} {h}">{d}{body}</svg>\n')


def st(color=LINE, w=2.0, dash=None):
    s = f' stroke="{color}" stroke-width="{w}" stroke-linejoin="round" stroke-linecap="round"'
    if dash:
        s += f' stroke-dasharray="{dash}"'
    return s


def rect(x, y, w, h, fill="none", rx=0, stroke=LINE, sw=2.0, extra=""):
    s = st(stroke, sw) if stroke else ""
    return f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" fill="{fill}"{s}{extra}/>'


def circle(cx, cy, r, fill="none", stroke=LINE, sw=2.0, extra=""):
    s = st(stroke, sw) if stroke else ""
    return f'<circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r:.1f}" fill="{fill}"{s}{extra}/>'


def ellipse(cx, cy, rx, ry, fill="none", stroke=LINE, sw=2.0, extra=""):
    s = st(stroke, sw) if stroke else ""
    return f'<ellipse cx="{cx:.1f}" cy="{cy:.1f}" rx="{rx:.1f}" ry="{ry:.1f}" fill="{fill}"{s}{extra}/>'


def line(x1, y1, x2, y2, color=LINE, w=2.0, dash=None):
    return f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}"{st(color, w, dash)}/>'


def path(d, fill="none", stroke=LINE, sw=2.0, extra=""):
    s = st(stroke, sw) if stroke else ""
    return f'<path d="{d}" fill="{fill}"{s}{extra}/>'


def blob_path(cx, cy, r, rng, lobes=9, jitter=0.35):
    """Irregular closed blob, used for blood."""
    pts = []
    n = lobes * 2
    for i in range(n):
        a = i / n * math.tau
        rr = r * (1 + rng.uniform(-jitter, jitter) * (0.6 if i % 2 else 1.0))
        pts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr))
    d = f"M{pts[0][0]:.1f},{pts[0][1]:.1f} "
    for i in range(n):
        p1 = pts[(i + 1) % n]
        p0 = pts[i]
        mx, my = (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2
        d += f"Q{p0[0]:.1f},{p0[1]:.1f} {mx:.1f},{my:.1f} "
    return d + "Z"


# ------------------------------------------------------------- operators
def operator(team, pose="stand"):
    """Plan-view figure, facing +x. 0.8 x 0.8 m canvas, centre = body centre."""
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    if team == "a":
        body, head, hatch = WHITE, WHITE, None
    else:
        body, head, hatch = GREY_M, GREY_L, True
    b = []
    # shoulders (wider across y because the figure faces +x)
    b.append(ellipse(cx - 2, cy, 11, 23, body, INK, 2.2))
    if hatch:
        for k in range(-3, 4):
            y = cy + k * 6
            b.append(line(cx - 9, y - 3, cx + 5, y + 3, GREY_D, 1.2))
        b.append(ellipse(cx - 2, cy, 11, 23, "none", INK, 2.2))
    # arms reaching forward to a weapon (both hands)
    b.append(path(f"M{cx - 2},{cy - 19} Q{cx + 12},{cy - 14} {cx + 22},{cy - 2}", "none", INK, 2.0))
    b.append(path(f"M{cx - 2},{cy + 19} Q{cx + 10},{cy + 12} {cx + 16},{cy + 2}", "none", INK, 2.0))
    # head
    b.append(circle(cx + 1, cy, 8.5, head, INK, 2.2))
    # nose tick showing facing
    b.append(line(cx + 9, cy, cx + 12, cy, INK, 2.0))
    return svg(0.8, 0.8, "".join(b))


def operator_down(team):
    """Figure lying on its back, long axis along x. 1.9 x 0.9 m."""
    w, h = 1.9 * PPM, 0.9 * PPM
    cy = h / 2
    fill = WHITE if team == "a" else GREY_M
    head = WHITE if team == "a" else GREY_L
    b = []
    # legs
    b.append(path(f"M{20},{cy - 9} L{62},{cy - 7} M{20},{cy + 9} L{62},{cy + 6}", "none", INK, 7))
    b.append(path(f"M{20},{cy - 9} L{62},{cy - 7} M{20},{cy + 9} L{62},{cy + 6}", "none", fill, 4))
    # torso
    b.append(rect(58, cy - 20, 54, 40, fill, 10, INK, 2.2))
    if team == "b":
        for k in range(0, 8):
            x = 62 + k * 6
            b.append(line(x, cy - 16, x + 6, cy + 16, GREY_D, 1.2))
        b.append(rect(58, cy - 20, 54, 40, "none", 10, INK, 2.2))
    # arms flung out
    b.append(path(f"M{100},{cy - 18} Q{112},{cy - 34} {96},{cy - 32}", "none", INK, 2.2))
    b.append(path(f"M{100},{cy + 18} Q{120},{cy + 30} {108},{cy + 34}", "none", INK, 2.2))
    # head
    b.append(circle(124, cy - 2, 10, head, INK, 2.2))
    return svg(1.9, 0.9, "".join(b))


def weapon(kind):
    """Weapon in plan, muzzle toward +x. Pivot (grip) is at the canvas left-centre."""
    if kind == "rifle":
        w_m, h_m = 0.95, 0.16
        w, h = w_m * PPM, h_m * PPM
        cy = h / 2
        b = [rect(2, cy - 3.5, 22, 7, GREY_D, 2, INK, 1.4),       # stock
             rect(22, cy - 4.5, 30, 9, "#4a4a4a", 2, INK, 1.4),    # receiver
             rect(30, cy - 2.5, 10, 5, "#2b2b2b", 1, None),         # optic
             rect(52, cy - 3, 14, 6, GREY_D, 2, INK, 1.2),         # handguard
             line(66, cy, 75, cy, INK, 2.6)]                        # barrel
        return svg(w_m, h_m, "".join(b))
    w_m, h_m = 0.42, 0.12
    w, h = w_m * PPM, h_m * PPM
    cy = h / 2
    b = [rect(14, cy - 4, 18, 8, "#3a3a3a", 2, INK, 1.4),
         line(32, cy, 33.5, cy, INK, 2)]
    return svg(w_m, h_m, "".join(b))


# ------------------------------------------------------------- furniture (plan symbols)
def bed(w_m=2.0, h_m=1.6):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 3),
         rect(4, 4, 18, h - 8, GREY_L, 2, LINE, 1.6),                       # headboard (left)
         rect(28, 10, 30, h / 2 - 16, PAPER, 6, LINE, 1.5),                # pillows
         rect(28, h / 2 + 6, 30, h / 2 - 16, PAPER, 6, LINE, 1.5),
         path(f"M{70},{4} L{70},{h - 4} M{70},{4} L{w - 4},{h * 0.55}", "none", FAINT, 1.4)]
    return svg(w_m, h_m, "".join(b))


def sofa(w_m=2.2, h_m=0.85):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 6),
         rect(2, 2, w - 4, 18, GREY_L, 6, LINE, 1.6),                        # back (top)
         rect(2, 2, 18, h - 4, GREY_L, 6, LINE, 1.6),                        # arms
         rect(w - 20, 2, 18, h - 4, GREY_L, 6, LINE, 1.6)]
    seat_w = (w - 44) / 3
    for i in range(3):
        b.append(rect(22 + i * seat_w, 22, seat_w - 2, h - 26, WHITE, 3, LINE, 1.2))
    return svg(w_m, h_m, "".join(b))


def armchair(s=0.85):
    w = s * PPM
    b = [rect(2, 2, w - 4, w - 4, WHITE, 6),
         rect(2, 2, w - 4, 16, GREY_L, 6, LINE, 1.5),
         rect(2, 2, 14, w - 4, GREY_L, 6, LINE, 1.5),
         rect(w - 16, 2, 14, w - 4, GREY_L, 6, LINE, 1.5)]
    return svg(s, s, "".join(b))


def coffee_table(w_m=1.2, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 3) + rect(8, 8, w - 16, h - 16, "none", 2, FAINT, 1.2))


def bookshelf(w_m=1.6, h_m=0.4):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 0)]
    for i in range(1, 8):
        x = i * (w / 8)
        b.append(line(x, 4, x, h - 4, FAINT, 1.2))
    b.append(line(2, 2, w - 2, h - 2, FAINT, 1.0))
    return svg(w_m, h_m, "".join(b))


def counter(w_m=1.6, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 0),
         rect(10, 8, 34, h - 18, PAPER, 6, LINE, 1.6),                       # sink
         circle(27, h / 2 - 4, 3, "none", LINE, 1.2)]
    for (dx, dy) in ((0, 0), (22, 0), (0, 20), (22, 20)):                     # stove burners
        b.append(circle(w - 52 + dx, 14 + dy, 7, "none", LINE, 1.4))
    b.append(line(2, h - 6, w - 2, h - 6, FAINT, 1.0))
    return svg(w_m, h_m, "".join(b))


def fridge(w_m=0.7, h_m=0.7):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 2) + line(2, 2, w - 2, h - 2, FAINT, 1.2)
               + line(w - 2, 2, 2, h - 2, FAINT, 1.2))


def dining(w_m=1.1, h_m=0.8):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(14, 12, w - 28, h - 24, WHITE, 3)]
    for x in (w * 0.3, w * 0.7):
        b.append(rect(x - 9, 1, 18, 10, WHITE, 2, LINE, 1.3))
        b.append(rect(x - 9, h - 11, 18, 10, WHITE, 2, LINE, 1.3))
    return svg(w_m, h_m, "".join(b))


def tub(w_m=1.6, h_m=0.72):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 6)
               + rect(10, 8, w - 20, h - 16, PAPER, 22, LINE, 1.5) + circle(w - 22, h / 2, 3, "none", LINE, 1.2))


def toilet(w_m=0.5, h_m=0.65):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(4, 2, w - 8, 14, WHITE, 2) + ellipse(w / 2, h * 0.58, w / 2 - 5, h * 0.36, WHITE))


def basin(w_m=0.55, h_m=0.42):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 3) + ellipse(w / 2, h / 2 + 2, w / 2 - 9, h / 2 - 8, PAPER, LINE, 1.4))


def dresser(w_m=1.2, h_m=0.5):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 1)]
    for i in (1, 2):
        b.append(line(i * w / 3, 4, i * w / 3, h - 4, FAINT, 1.2))
    return svg(w_m, h_m, "".join(b))


def wardrobe(w_m=1.2, h_m=0.5):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 1) + line(w / 2, 4, w / 2, h - 4, FAINT, 1.2)
               + line(8, h / 2, w - 8, h / 2, FAINT, 1.0, "4 4"))


# ------------------------------------------------------------- yard
def car(w_m=4.4, h_m=1.9):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(4, 4, w - 8, h - 8, WHITE, 34, INK, 2.2),
         rect(w * 0.30, 12, w * 0.40, h - 24, GREY_L, 16, LINE, 1.6),      # cabin / roof
         path(f"M{w * 0.30},{18} L{w * 0.22},{14} M{w * 0.30},{h - 18} L{w * 0.22},{h - 14}", "none", LINE, 1.4),
         path(f"M{w * 0.70},{18} L{w * 0.80},{14} M{w * 0.70},{h - 18} L{w * 0.80},{h - 14}", "none", LINE, 1.4),
         line(w * 0.12, 20, w * 0.12, h - 20, FAINT, 1.2),                  # bonnet line
         rect(w * 0.18, 0, 30, 6, GREY_D, 2, None), rect(w * 0.70, 0, 30, 6, GREY_D, 2, None),
         rect(w * 0.18, h - 6, 30, 6, GREY_D, 2, None), rect(w * 0.70, h - 6, 30, 6, GREY_D, 2, None)]
    return svg(w_m, h_m, "".join(b))


def tree(d_m=3.6):
    w = d_m * PPM
    c = w / 2
    rng = random.Random(7)
    b = [path(blob_path(c, c, c - 6, rng, 11, 0.12), "none", FAINT, 1.6, ' stroke-dasharray="6 5"'),
         circle(c, c, 0.25 * PPM, GREY_L, INK, 2)]
    for k in range(6):
        a = k / 6 * math.tau + 0.3
        b.append(line(c + math.cos(a) * 24, c + math.sin(a) * 24, c + math.cos(a) * (c * 0.7), c + math.sin(a) * (c * 0.7), FAINT, 1.0))
    return svg(d_m, d_m, "".join(b))


def hedge(w_m=0.8, h_m=3.6):
    w, h = w_m * PPM, h_m * PPM
    rng = random.Random(11)
    b = []
    y = 6
    while y < h - 6:
        r = rng.uniform(12, 18)
        b.append(circle(w / 2 + rng.uniform(-6, 6), y + r * 0.6, r, PAPER, LINE, 1.4))
        y += r * 0.9
    return svg(w_m, h_m, "".join(b))


def drum(d_m=0.6):
    w = d_m * PPM
    c = w / 2
    return svg(d_m, d_m, circle(c, c, c - 2, WHITE, INK, 2) + circle(c, c, c - 8, "none", FAINT, 1.2)
               + circle(c * 0.62, c * 0.62, 3, GREY_D, None))


def low_wall(w_m=3.0, h_m=0.4):
    w, h = w_m * PPM, h_m * PPM
    defs = f'<clipPath id="c"><rect x="1" y="1" width="{w - 2:.1f}" height="{h - 2:.1f}"/></clipPath>'
    hatch = []
    x = -h
    while x < w:
        hatch.append(line(x, h, x + h, 0, GREY_D, 1.0))
        x += 9
    b = [rect(1, 1, w - 2, h - 2, GREY_L, 0, None), f'<g clip-path="url(#c)">{"".join(hatch)}</g>',
         rect(1, 1, w - 2, h - 2, "none", 0, INK, 2)]
    return svg(w_m, h_m, "".join(b), defs)


def woodpile(w_m=2.0, h_m=0.8):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(1, 1, w - 2, h - 2, PAPER, 0, LINE, 1.2)]
    r = 7
    for row in range(int((h - 4) // (2 * r))):
        for col in range(int((w - 4) // (2 * r))):
            cx = 4 + r + col * 2 * r + (r if row % 2 else 0)
            if cx + r < w - 2:
                b.append(circle(cx, 4 + r + row * 2 * r, r - 1, WHITE, LINE, 1.2))
    return svg(w_m, h_m, "".join(b))


def picnic(w_m=1.8, h_m=1.6):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(4, 6, w - 8, 22, WHITE, 2, LINE, 1.6),
         rect(4, h - 28, w - 8, 22, WHITE, 2, LINE, 1.6),
         rect(10, 40, w - 20, h - 80, WHITE, 2, INK, 2)]
    for i in range(1, 5):
        b.append(line(10 + i * (w - 20) / 5, 42, 10 + i * (w - 20) / 5, h - 42, FAINT, 1.0))
    return svg(w_m, h_m, "".join(b))


def ac_unit(w_m=0.8, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 2, INK, 2) + circle(w / 2, h / 2, h / 2 - 7, "none", LINE, 1.5)
               + line(w / 2 - 12, h / 2, w / 2 + 12, h / 2, FAINT, 1.2) + line(w / 2, h / 2 - 12, w / 2, h / 2 + 12, FAINT, 1.2))


def bins(w_m=0.8, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(3, 3, w / 2 - 5, h - 6, PAPER, 4, LINE, 1.6) + rect(w / 2 + 2, 3, w / 2 - 5, h - 6, PAPER, 4, LINE, 1.6)
               + line(6, 10, w / 2 - 5, 10, FAINT, 1.0) + line(w / 2 + 5, 10, w - 6, 10, FAINT, 1.0))


def shed_roof(w_m=3.5, h_m=3.0):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(1, 1, w - 2, h - 2, GREY_L, 0, INK, 3),
         line(1, 1, w - 1, h - 1, GREY_D, 1.4), line(w - 1, 1, 1, h - 1, GREY_D, 1.4)]
    return svg(w_m, h_m, "".join(b))


# ------------------------------------------------------------- blood and residue
def splat(seed, size_m=1.4):
    rng = random.Random(seed)
    w = size_m * PPM
    c = w / 2
    b = [path(blob_path(c, c, w * 0.16, rng, 8, 0.45), BLOOD, None, 0, ' opacity="0.92"')]
    for _ in range(26):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(w * 0.14, w * 0.46)
        r = max(1.2, rng.gauss(4.5, 2.5) * (1.2 - d / w))
        b.append(circle(c + math.cos(a) * d, c + math.sin(a) * d, r, BLOOD if rng.random() < 0.7 else BLOOD_D, None, 0,
                        f' opacity="{rng.uniform(0.6, 0.95):.2f}"'))
    return svg(size_m, size_m, "".join(b))


def spray(seed, len_m=2.2, wid_m=0.9):
    """Directional exit spray; the impact point is at the left, the spray runs toward +x."""
    rng = random.Random(seed)
    w, h = len_m * PPM, wid_m * PPM
    cy = h / 2
    b = [path(blob_path(18, cy, 14, rng, 6, 0.4), BLOOD, None, 0, ' opacity="0.9"')]
    for _ in range(60):
        t = rng.random() ** 1.6
        x = 18 + t * (w - 30)
        spread = (0.08 + 0.42 * t) * h / 2
        y = cy + rng.gauss(0, spread * 0.6)
        if abs(y - cy) > h / 2 - 4:
            continue
        r = max(1.0, (6.5 - 5 * t) * rng.uniform(0.4, 1.1))
        if rng.random() < 0.35:   # elongated droplet pointing along the spray
            b.append(ellipse(x, y, r * 2.2, r * 0.8, BLOOD, None, 0, f' opacity="{rng.uniform(0.6, 0.95):.2f}"'))
        else:
            b.append(circle(x, y, r, BLOOD if rng.random() < 0.75 else BLOOD_L, None, 0, f' opacity="{rng.uniform(0.55, 0.95):.2f}"'))
    return svg(len_m, wid_m, "".join(b))


def wall_smear(seed, len_m=1.0, wid_m=0.24):
    rng = random.Random(seed)
    w, h = len_m * PPM, wid_m * PPM
    b = []
    x = 4
    while x < w - 6:
        r = rng.uniform(2, 7) * (1 - x / w * 0.6)
        b.append(ellipse(x, h / 2 + rng.uniform(-3, 3), r * 1.6, r, BLOOD, None, 0, f' opacity="{rng.uniform(0.6, 0.95):.2f}"'))
        x += rng.uniform(3, 9)
    return svg(len_m, wid_m, "".join(b))


def pool(seed, size_m=1.6):
    rng = random.Random(seed)
    w = size_m * PPM
    c = w / 2
    return svg(size_m, size_m, path(blob_path(c, c, w * 0.40, rng, 7, 0.22), BLOOD_D, None, 0, ' opacity="0.88"')
               + path(blob_path(c - 6, c - 4, w * 0.26, rng, 6, 0.25), BLOOD, None, 0, ' opacity="0.7"'))


def stain(seed, size_m=0.3):
    rng = random.Random(seed)
    w = size_m * PPM
    c = w / 2
    b = [path(blob_path(c, c, w * 0.26, rng, 6, 0.4), BLOOD, None, 0, ' opacity="0.92"')]
    for _ in range(5):
        a = rng.uniform(0, math.tau)
        b.append(circle(c + math.cos(a) * w * 0.36, c + math.sin(a) * w * 0.36, rng.uniform(1, 2.5), BLOOD_D, None))
    return svg(size_m, size_m, "".join(b))


def drip(seed):
    rng = random.Random(seed)
    w = 0.12 * PPM
    return svg(0.12, 0.12, circle(w / 2, w / 2, rng.uniform(1.6, 3.2), BLOOD, None, 0, ' opacity="0.85"'))


def chip():
    w = 0.14 * PPM
    c = w / 2
    pts = " ".join(f"{c + math.cos(a) * r:.1f},{c + math.sin(a) * r:.1f}"
                   for a, r in zip([i * math.tau / 7 for i in range(7)], [4.5, 2.2, 5, 2.6, 4, 2, 4.8]))
    return svg(0.14, 0.14, f'<polygon points="{pts}" fill="#2a2a2a" opacity="0.9"/>')


def casing():
    return svg(0.08, 0.04, rect(0.5, 0.5, 5.4, 2.2, "#9a9a9a", 1, "#555555", 0.8))


def plate_scuff():
    w = 0.16 * PPM
    return svg(0.16, 0.16, circle(w / 2, w / 2, 4, "#cfcfcf", "#5a5a5a", 1.2))


def flash():
    w = 0.5 * PPM
    c = w / 2
    pts = []
    for i in range(10):
        a = i / 10 * math.tau
        r = c - 2 if i % 2 == 0 else c * 0.35
        pts.append(f"{c + math.cos(a) * r:.1f},{c + math.sin(a) * r:.1f}")
    return svg(0.5, 0.5, f'<polygon points="{" ".join(pts)}" fill="#ffffff" stroke="#1c1c1c" stroke-width="1.4"/>')


def north_arrow():
    w, h = 0.9 * PPM, 1.3 * PPM
    c = w / 2
    return svg(0.9, 1.3, circle(c, h - c, c - 4, "none", INK, 1.6)
               + path(f"M{c},{6} L{c + 12},{h - c} L{c},{h - c - 10} Z", INK, INK, 1.2)
               + path(f"M{c},{6} L{c - 12},{h - c} L{c},{h - c - 10} Z", WHITE, INK, 1.2))


def icon_app():
    # 128 px app icon: a plan-view figure with one red stain on paper
    body = (rect(0, 0, 128, 128, PAPER, 0, None) + rect(6, 6, 116, 116, "none", 0, INK, 6)
            + ellipse(60, 64, 22, 40, WHITE, INK, 4) + circle(64, 64, 16, WHITE, INK, 4)
            + path(blob_path(84, 82, 12, random.Random(3), 7, 0.4), BLOOD, None))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">{body}</svg>\n'


# ------------------------------------------------------------- manifest
ASSETS = {
    "op/a_stand.svg": lambda: operator("a"),
    "op/b_stand.svg": lambda: operator("b"),
    "op/a_down.svg": lambda: operator_down("a"),
    "op/b_down.svg": lambda: operator_down("b"),
    "op/rifle.svg": lambda: weapon("rifle"),
    "op/pistol.svg": lambda: weapon("pistol"),
    "furn/bed.svg": bed, "furn/sofa.svg": sofa, "furn/armchair.svg": armchair,
    "furn/coffee_table.svg": coffee_table, "furn/bookshelf.svg": bookshelf, "furn/counter.svg": counter,
    "furn/fridge.svg": fridge, "furn/dining.svg": dining, "furn/tub.svg": tub, "furn/toilet.svg": toilet,
    "furn/basin.svg": basin, "furn/dresser.svg": dresser, "furn/wardrobe.svg": wardrobe,
    "yard/car.svg": car, "yard/tree.svg": tree, "yard/hedge.svg": hedge, "yard/drum.svg": drum,
    "yard/low_wall.svg": low_wall, "yard/woodpile.svg": woodpile, "yard/picnic.svg": picnic,
    "yard/ac_unit.svg": ac_unit, "yard/bins.svg": bins, "yard/shed.svg": shed_roof,
    "fx/chip.svg": chip, "fx/casing.svg": casing, "fx/scuff.svg": plate_scuff, "fx/flash.svg": flash,
    "fx/pool.svg": lambda: pool(5), "fx/pool2.svg": lambda: pool(9),
    "fx/drip1.svg": lambda: drip(1), "fx/drip2.svg": lambda: drip(2),
    "fx/stain1.svg": lambda: stain(21), "fx/stain2.svg": lambda: stain(22), "fx/stain3.svg": lambda: stain(23),
    "fx/smear1.svg": lambda: wall_smear(31), "fx/smear2.svg": lambda: wall_smear(32),
    "ui/north.svg": north_arrow,
}
for i in range(1, 5):
    ASSETS[f"fx/splat{i}.svg"] = (lambda i=i: splat(100 + i))
    ASSETS[f"fx/spray{i}.svg"] = (lambda i=i: spray(200 + i))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--out", default="assets/svg")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()
    for rel, fn in ASSETS.items():
        if a.list:
            print(rel)
            continue
        dst = os.path.join(a.out, rel)
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        with open(dst, "w", encoding="utf-8") as f:
            f.write(fn())
    if not a.list:
        with open("icon.svg", "w", encoding="utf-8") as f:
            f.write(icon_app())
        with open(os.path.join(a.out, "manifest.json"), "w", encoding="utf-8") as f:
            json.dump({"generator": "tools/make_placeholders.py", "license": "original, project-owned",
                       "px_per_metre": PPM, "files": list(ASSETS)}, f, indent=1)
        print(f"wrote {len(ASSETS)} files to {a.out}")


if __name__ == "__main__":
    main()
