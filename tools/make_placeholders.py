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
import re
import os
import random

PPM = 80  # pixels per metre in the SVG files
# The red-ink tokens (v0.8): ink, stepped greys, paper. Every grey written below is
# quantised to these on output; red is never painted into base art (blood is drawn by
# the game as red ink, through one accent, so the monochrome proof is one switch).
INK = "#121212"
LINE = "#2b2b2b"
FAINT = "#737370"
WHITE = "#edede8"
PAPER = "#edede8"
GREY_L = "#d4d4cf"
GREY_M = "#bfbfba"
GREY_D = "#737370"
SHADOW = "#2b2b2b"
BLOOD = "#b31f26"
TOKENS = [(232, "#edede8"), (208, "#d4d4cf"), (152, "#bfbfba"), (80, "#737370"), (34, "#2b2b2b"), (0, "#121212")]


def quantise(text):
    """Snap every grey in an SVG to the nearest step of the token ramp; red stays red."""
    def rep(m):
        hx = m.group(1)
        if len(hx) == 3:
            hx = "".join(c * 2 for c in hx)
        r, g, b = int(hx[0:2], 16), int(hx[2:4], 16), int(hx[4:6], 16)
        if max(r, g, b) - min(r, g, b) > 10:
            return m.group(0)
        lum = (r + g + b) // 3
        for lo, tok in TOKENS:
            if lum >= lo:
                return tok
    return re.sub(r"#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b", rep, text)


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


# ------------------------------------------------------------- operators (v0.8: flat ink)
# Officers, suspects and civilians are flat ink silhouettes from directly above: head
# circle, body block, limb strokes, an offset soft shadow (Dark at 0.2) and one pale
# equipment mark. No faces, no gear detail. Roles differ by mark, never by hue. A downed
# figure is the same silhouette on its side; the injury is never drawn.

def _shadow(parts, dx=3, dy=3):
    return f'<g transform="translate({dx},{dy})" opacity="0.2">' + "".join(parts).replace(INK, SHADOW) + "</g>"


def _figure(mark_fn=None, body=INK, outline=None, limb=5.0):
    """Standing silhouette facing +x on a 0.8 m canvas; mark_fn(cx, cy) adds the mark."""
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    shape = [path(f"M{cx - 2},{cy - 18} Q{cx + 12},{cy - 14} {cx + 22},{cy - 2}", "none", INK, limb),
             path(f"M{cx - 2},{cy + 18} Q{cx + 10},{cy + 12} {cx + 16},{cy + 2}", "none", INK, limb),
             rect(cx - 13, cy - 22, 17, 44, body, 8, outline or "none", 2.6 if outline else 0)]
    head = circle(cx + 5, cy, 8.0, body, PAPER if not outline else INK, 2.0 if not outline else 2.6)
    b = [_shadow(shape + [circle(cx + 5, cy, 8.0, INK, None)])] + shape
    if mark_fn:
        b += mark_fn(cx - 3, cy)
    b.append(head)   # the head over the shoulders, cut out by a paper hairline
    b.append(line(cx + 13, cy, cx + 16, cy, INK, 2.4))
    return svg(0.8, 0.8, "".join(b))


def _figure_down(mark_fn=None, body=INK, outline=None, limb=6.0):
    """The same silhouette on its side: long axis along x, 1.9 x 0.9 m."""
    w, h = 1.9 * PPM, 0.9 * PPM
    cy = h / 2
    shape = [path(f"M{22},{cy - 7} L{62},{cy - 6} M{22},{cy + 7} L{62},{cy + 6}", "none", INK, limb + 1),
             path(f"M{70},{cy - 21} L{104},{cy - 24} M{70},{cy + 21} L{104},{cy + 24}", "none", INK, limb - 1),
             rect(58, cy - 20, 54, 40, body, 10, outline or "none", 2.6 if outline else 0),
             circle(124, cy - 2, 10, body, outline or "none", 2.6 if outline else 0)]
    b = [_shadow(shape)] + shape
    if mark_fn:
        b += mark_fn(85, cy)
    return svg(1.9, 0.9, "".join(b))


def _bar(cx, cy):          # police: a pale bar across the shoulders
    return [rect(cx - 6, cy - 17, 5, 34, GREY_M, 2, None)]


def _bar_down(cx, cy):
    return [rect(cx - 17, cy - 3, 34, 6, GREY_M, 2, None)]


def _hatch3(cx, cy):       # the other side: three pale diagonals
    return [line(cx - 8, cy + k * 11 - 4, cx + 1, cy + k * 11 + 4, GREY_M, 2.0) for k in (-1, 0, 1)]


def _hatch3_down(cx, cy):
    return [line(cx + k * 12 - 4, cy - 12, cx + k * 12 + 4, cy + 12, GREY_M, 2.0) for k in (-1, 0, 1)]


def operator(team, pose="stand"):
    """Plan-view figure, facing +x. 0.8 x 0.8 m canvas, centre = body centre."""
    return _figure(_bar if team == "a" else _hatch3)


def operator_down(team):
    """Figure on its side, long axis along x. 1.9 x 0.9 m."""
    return _figure_down(_bar_down if team == "a" else _hatch3_down)


def civilian(pose="stand"):
    """Civilian: the hollow silhouette, an ink outline on paper, no mark (people who were
    not dressed for this). 0.8 x 0.8 m canvas."""
    return _figure(None, PAPER, INK, 3.0)


def civilian_down():
    return _figure_down(None, PAPER, INK, 3.6)


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


# ------------------------------------------------------------- the weapon roster (v0.7.5)
# Plan view, muzzle toward +x, the canvas's left edge at the shooter's shoulder. Each
# class has its own silhouette at a glance: length, width of the receiver, what sits on
# top (red dot, scope, nothing), a pump or a tube under a shotgun barrel.
DARK = "#2b2b2b"
MID = "#4a4a4a"


def long_gun(stock, recv, guard, barrel, rw=9.0, optic="dot", brake=False, folded=False, tube=False,
             pump=False, scope=False, mag=False):
    """Lengths in metres. rw: receiver width in px (at 80 px/m)."""
    L = stock + recv + guard + barrel
    w_m, h_m = L + 0.03, 0.18
    w, h = w_m * PPM, h_m * PPM
    cy = h / 2
    b = []
    x = 2.0
    sw = stock * PPM
    if folded:
        # a folding stock lies along the receiver: two thin rails
        b.append(line(x, cy - rw / 2 + 1, x + sw, cy - rw / 2 + 1, INK, 1.4))
        b.append(line(x, cy + rw / 2 - 1, x + sw, cy + rw / 2 - 1, INK, 1.4))
        b.append(line(x, cy - rw / 2 + 1, x, cy + rw / 2 - 1, INK, 1.6))
    elif sw > 0:
        b.append(path(f"M{x},{cy - rw / 2 + 0.5} L{x + sw},{cy - rw / 2 + 1.5} L{x + sw},{cy + rw / 2 - 1.5} L{x},{cy + rw / 2 - 0.5} Z",
                      GREY_D, INK, 1.3))
    x += sw
    rl = recv * PPM
    b.append(rect(x, cy - rw / 2, rl, rw, MID, 2, INK, 1.4))
    if mag:
        # a magazine seen edge-on from above: a short tab out to the side
        b.append(rect(x + rl * 0.55, cy + rw / 2 - 0.5, 5, 3.5, DARK, 1, INK, 0.8))
    if optic == "dot":
        b.append(rect(x + rl * 0.35, cy - 2.6, rl * 0.28, 5.2, DARK, 1.5, None))
        b.append(circle(x + rl * 0.35 + rl * 0.28 - 1.5, cy, 1.2, "#8a8a8a", None))
    if scope:
        b.append(rect(x + rl * 0.15, cy - 3.6, rl * 0.85, 7.2, DARK, 3.6, INK, 1.0))
        b.append(rect(x + rl * 0.15 + rl * 0.85 - 4, cy - 4.6, 4, 9.2, DARK, 1.5, INK, 0.8))
    x += rl
    gl = guard * PPM
    if gl > 0:
        if pump:
            b.append(rect(x, cy - rw / 2 + 1, gl * 0.35, rw - 2, GREY_D, 1, INK, 1.2))
            for k in range(1, 4):
                b.append(line(x + gl * 0.35 * k / 4, cy - rw / 2 + 2, x + gl * 0.35 * k / 4, cy + rw / 2 - 2, INK, 0.8))
            b.append(line(x + gl * 0.35, cy, x + gl, cy, INK, 2.2))
        else:
            b.append(rect(x, cy - rw / 2 + 1.5, gl, rw - 3, GREY_D, 2, INK, 1.2))
            b.append(line(x + 2, cy, x + gl - 2, cy, "#7a7a7a", 0.8))
    x += gl
    bl = barrel * PPM
    if tube:
        b.append(line(x - gl * 0.65, cy + 2.6, x + bl * 0.75, cy + 2.6, INK, 1.8))
        b.append(line(x - gl * 0.65, cy - 1.2, x + bl, cy - 1.2, INK, 2.4))
    else:
        b.append(line(x, cy, x + bl, cy, INK, 2.6))
    if brake:
        b.append(rect(x + bl - 4, cy - 2.4, 5, 4.8, DARK, 1, INK, 0.8))
    return svg(w_m, h_m, "".join(b))


def handgun(slide_m, w_px=8.0, heavy=False):
    w_m, h_m = slide_m + 0.22, 0.13
    w, h = w_m * PPM, h_m * PPM
    cy = h / 2
    x0 = 14.0
    sl = slide_m * PPM
    b = [rect(x0 - 3, cy - w_px / 2 - 0.5, 7, w_px + 1, GREY_D, 2, INK, 1.0),            # grip and hands
         rect(x0, cy - w_px / 2, sl, w_px, "#3a3a3a", 2.5, INK, 1.4),                    # slide
         line(x0 + 2, cy - w_px / 2 + 1.8, x0 + sl - 3, cy - w_px / 2 + 1.8, "#7a7a7a", 0.8)]
    if heavy:
        b.append(line(x0 + sl * 0.15, cy + w_px / 2 - 1.8, x0 + sl - 3, cy + w_px / 2 - 1.8, "#7a7a7a", 0.8))
    b.append(line(x0 + sl, cy, x0 + sl + 2, cy, INK, 2.0))
    return svg(w_m, h_m, "".join(b))


WEAPON_ART = {
    "carbine": lambda: long_gun(0.24, 0.36, 0.18, 0.12, optic="dot"),
    "sbr": lambda: long_gun(0.17, 0.34, 0.12, 0.06, optic="dot", brake=True),
    "assault_rifle": lambda: long_gun(0.24, 0.36, 0.18, 0.12, rw=9.5, optic="none", brake=True, mag=True),
    "battle_rifle": lambda: long_gun(0.26, 0.44, 0.22, 0.16, rw=10.5, optic="dot", brake=True),
    "marksman": lambda: long_gun(0.26, 0.46, 0.22, 0.20, rw=10.0, optic="none", scope=True),
    "smg": lambda: long_gun(0.18, 0.26, 0.06, 0.05, rw=8.5, optic="dot", folded=True, mag=True),
    "shotgun": lambda: long_gun(0.26, 0.24, 0.30, 0.22, rw=8.0, optic="none", tube=True, pump=True),
    "service_pistol": lambda: handgun(0.19),
    "compact_pistol": lambda: handgun(0.16, 7.5),
    "heavy_pistol": lambda: handgun(0.21, 9.0, True),
}


# ------------------------------------------------------------- kit seen from above (v0.7.5)
# Overlays drawn on the 0.8 x 0.8 m figure canvas (same centre and facing).
def kit_vest():
    """v0.8: armour is a pale outline inside the ink torso, not a drawing of a vest."""
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    return svg(0.8, 0.8, rect(cx - 11, cy - 18, 13, 36, "none", 5, GREY_M, 1.2))


def kit_plates():
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    return svg(0.8, 0.8, rect(cx - 11, cy - 18, 13, 36, "none", 5, GREY_M, 2.2))


def kit_helmet():
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    return svg(0.8, 0.8, circle(cx + 5, cy, 9.5, INK, PAPER, 1.6) + circle(cx + 5, cy, 6.0, "none", GREY_M, 1.4))


def kit_gas_mask():
    """A gas mask seen from above (v0.8): head straps round the back, the face piece and a
    filter canister forward (+x)."""
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    b = [path(f"M{cx - 8},{cy - 7} A10 10 0 0 0 {cx - 8},{cy + 7}", "none", DARK, 1.6),   # strap
         rect(cx + 3, cy - 8, 6, 16, "#3a3a3a", 3, INK, 1.2),                              # face piece
         circle(cx + 12, cy, 4.2, "#5a5a5a", INK, 1.2),                                  # filter
         line(cx + 10, cy - 2.5, cx + 14, cy - 2.5, "#8a8a8a", 0.8),
         line(cx + 10, cy + 2.5, cx + 14, cy + 2.5, "#8a8a8a", 0.8)]
    return svg(0.8, 0.8, "".join(b))


def shield_art():
    """A ballistic shield carried in front, seen edge-on from above: a curved slab."""
    w_m, h_m = 0.22, 0.74
    w, h = w_m * PPM, h_m * PPM
    b = [path(f"M{4},{4} Q{w - 2},{h / 2} {4},{h - 4} L{9},{h - 4} Q{w + 3},{h / 2} {9},{4} Z", "#2e2e2e", INK, 1.6),
         line(7.5, h / 2 - 5, 9.5, h / 2 + 5, "#9a9a9a", 1.6)]    # the viewport, edge-on
    return svg(w_m, h_m, "".join(b))


def ram_art():
    w_m, h_m = 0.70, 0.16
    w, h = w_m * PPM, h_m * PPM
    cy = h / 2
    b = [rect(4, cy - 4.5, w - 10, 9, "#4a4a4a", 4, INK, 1.4),
         rect(w - 9, cy - 5.5, 6, 11, DARK, 2, INK, 1.2),             # striking face
         path(f"M{14},{cy - 4.5} Q{18},{cy - 10} {22},{cy - 4.5}", "none", INK, 1.6),
         path(f"M{30},{cy + 4.5} Q{34},{cy + 10} {38},{cy + 4.5}", "none", INK, 1.6)]
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


# ------------------------------------------------------------- furniture added for the ten maps
def bunk(w_m=2.0, h_m=0.9):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 2), rect(8, 8, w - 16, h - 16, "none", 2, FAINT, 1.2),
         rect(4, 4, 16, h - 8, GREY_L, 2, LINE, 1.4), rect(26, 12, 26, h - 24, PAPER, 5, LINE, 1.3),
         line(w - 6, 2, w - 6, h - 2, INK, 2.4), line(6, 2, 6, h - 2, INK, 2.4)]
    return svg(w_m, h_m, "".join(b))


def desk(w_m=1.4, h_m=0.7):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h * 0.62, WHITE, 1), rect(w - 34, 6, 26, h * 0.62 - 10, "none", 1, FAINT, 1.2),
         rect(w * 0.18, 10, w * 0.34, 8, PAPER, 1, LINE, 1.2),
         path(f"M{w * 0.32},{h * 0.66} A{h * 0.3},{h * 0.3} 0 0 0 {w * 0.62},{h * 0.66}", "none", LINE, 1.5),
         rect(w * 0.36, h * 0.66, w * 0.22, h * 0.26, PAPER, 6, LINE, 1.4)]
    return svg(w_m, h_m, "".join(b))


def chair(s=0.5):
    w = s * PPM
    return svg(s, s, rect(4, 4, w - 8, w - 8, WHITE, 6, LINE, 1.6) + rect(4, 4, w - 8, 9, GREY_L, 4, LINE, 1.4))


def table(w_m=2.4, h_m=1.0):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 3) + rect(10, 10, w - 20, h - 20, "none", 2, FAINT, 1.0))


def shelving(w_m=4.0, h_m=1.0):
    """Store gondola: double-sided shelving seen from above."""
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 1, INK, 2), line(2, h / 2, w - 2, h / 2, LINE, 1.6)]
    x = 2
    while x < w - 4:
        b.append(rect(x + 3, 6, 14, h / 2 - 10, PAPER, 1, FAINT, 1.0))
        b.append(rect(x + 3, h / 2 + 4, 14, h / 2 - 10, PAPER, 1, FAINT, 1.0))
        x += 20
    return svg(w_m, h_m, "".join(b))


def rack(w_m=6.0, h_m=1.1):
    """Pallet racking bay run: uprights, beams and loaded pallets with the X of an overhead."""
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, GREY_L, 0, INK, 2.2)]
    bay = 2.7 * PPM / 1.0 * (w_m / max(1, round(w_m / 2.7))) / w_m
    nb = max(1, round(w_m / 2.7))
    bw = (w - 4) / nb
    for i in range(nb):
        x0 = 2 + i * bw
        b.append(rect(x0 + 6, 8, bw - 12, h - 16, WHITE, 1, LINE, 1.4))
        b.append(line(x0 + 6, 8, x0 + bw - 6, h - 8, FAINT, 1.0))
        b.append(line(x0 + bw - 6, 8, x0 + 6, h - 8, FAINT, 1.0))
        b.append(rect(x0 - 2, 2, 5, h - 4, INK, 0, None))
    b.append(rect(w - 6, 2, 5, h - 4, INK, 0, None))
    return svg(w_m, h_m, "".join(b))


def crate(s=1.2):
    w = s * PPM
    return svg(s, s, rect(3, 3, w - 6, w - 6, PAPER, 0, INK, 2) + rect(10, 10, w - 20, w - 20, "none", 0, LINE, 1.2)
               + line(10, 10, w - 10, w - 10, LINE, 1.2) + line(w - 10, 10, 10, w - 10, LINE, 1.2))


def pallet(w_m=1.2, h_m=1.0):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, "none", 0, LINE, 1.6)]
    for i in range(5):
        y = 4 + i * (h - 8) / 5
        b.append(rect(4, y + 1, w - 8, (h - 8) / 5 - 4, PAPER, 0, FAINT, 1.0))
    return svg(w_m, h_m, "".join(b))


def cabinet(w_m=0.5, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 1, INK, 1.8)]
    for i in range(1, 4):
        b.append(line(5, i * h / 4, w - 5, i * h / 4, FAINT, 1.1))
    return svg(w_m, h_m, "".join(b))


def stove(w_m=0.7, h_m=0.65):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 2, INK, 1.8)]
    for (fx, fy) in ((0.3, 0.32), (0.7, 0.32), (0.3, 0.72), (0.7, 0.72)):
        b.append(circle(w * fx, h * fy, 8, "none", LINE, 1.4))
    return svg(w_m, h_m, "".join(b))


def washer(s=0.65):
    w = s * PPM
    return svg(s, s, rect(2, 2, w - 4, w - 4, WHITE, 3, INK, 1.8) + circle(w / 2, w / 2 + 3, w * 0.3, PAPER, LINE, 1.5)
               + line(6, 9, w - 6, 9, FAINT, 1.1))


def stairs(w_m=1.2, h_m=3.0):
    """Stair run in plan: treads, a break line and the up arrow (runs toward +y)."""
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 0, INK, 2)]
    n = int(h_m / 0.28)
    for i in range(1, n):
        y = 2 + i * (h - 4) / n
        b.append(line(2, y, w - 2, y, LINE, 1.2))
    b.append(line(w / 2, h - 10, w / 2, 16, INK, 1.6))
    b.append(path(f"M{w / 2 - 7},{28} L{w / 2},{14} L{w / 2 + 7},{28}", "none", INK, 1.6))
    b.append(line(2, h * 0.55, w - 2, h * 0.45, INK, 1.4))
    return svg(w_m, h_m, "".join(b))


def lockers(w_m=2.4, h_m=0.5):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 0, INK, 1.8)]
    n = int(w_m / 0.4)
    for i in range(1, n):
        b.append(line(2 + i * (w - 4) / n, 4, 2 + i * (w - 4) / n, h - 4, LINE, 1.1))
    return svg(w_m, h_m, "".join(b))


def checkout(w_m=2.0, h_m=0.8):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, WHITE, 2, INK, 2) + rect(w - 46, 8, 34, 26, PAPER, 2, LINE, 1.4)
               + line(10, h - 12, w - 60, h - 12, FAINT, 1.1, "6 4"))


def cooler(w_m=3.0, h_m=0.8):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, WHITE, 1, INK, 2), line(2, h - 14, w - 2, h - 14, LINE, 1.2)]
    n = int(w_m / 0.75)
    for i in range(1, n):
        b.append(line(2 + i * (w - 4) / n, 4, 2 + i * (w - 4) / n, h - 4, FAINT, 1.1))
    return svg(w_m, h_m, "".join(b))


def dumpster(w_m=1.9, h_m=1.1):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(3, 3, w - 6, h - 6, GREY_L, 3, INK, 2.2) + line(w / 2, 4, w / 2, h - 4, LINE, 1.4)
               + rect(-1, h * 0.3, 6, h * 0.4, GREY_D, 1, None) + rect(w - 5, h * 0.3, 6, h * 0.4, GREY_D, 1, None))


def van(w_m=5.0, h_m=2.0):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(4, 4, w - 8, h - 8, WHITE, 22, INK, 2.2), rect(w * 0.06, 12, w * 0.16, h - 24, GREY_L, 10, LINE, 1.5),
         rect(w * 0.26, 10, w * 0.68, h - 20, "none", 4, FAINT, 1.2), line(w * 0.6, 10, w * 0.6, h - 10, FAINT, 1.0),
         rect(w * 0.14, 0, 30, 6, GREY_D, 2, None), rect(w * 0.76, 0, 30, 6, GREY_D, 2, None),
         rect(w * 0.14, h - 6, 30, 6, GREY_D, 2, None), rect(w * 0.76, h - 6, 30, 6, GREY_D, 2, None)]
    return svg(w_m, h_m, "".join(b))


def truck(w_m=7.5, h_m=2.5):
    w, h = w_m * PPM, h_m * PPM
    cab = w * 0.24
    b = [rect(4, 6, cab - 8, h - 12, WHITE, 16, INK, 2.2), rect(16, 14, cab * 0.4, h - 28, GREY_L, 8, LINE, 1.4),
         rect(cab, 2, w - cab - 4, h - 4, PAPER, 2, INK, 2.4)]
    for i in range(1, 9):
        x = cab + i * (w - cab - 4) / 9
        b.append(line(x, 6, x, h - 6, FAINT, 1.0))
    return svg(w_m, h_m, "".join(b))


def container(w_m=6.1, h_m=2.44):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(2, 2, w - 4, h - 4, GREY_L, 0, INK, 2.4)]
    x = 10
    while x < w - 10:
        b.append(line(x, 6, x, h - 6, GREY_D, 1.0))
        x += 10
    b.append(rect(w - 14, 4, 10, h - 8, WHITE, 0, LINE, 1.2))
    return svg(w_m, h_m, "".join(b))


def sandbags(w_m=2.4, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    b = []
    rw = 0.55 * PPM
    for row in range(2):
        x = 2 + (rw / 2 if row else 0)
        while x + rw <= w - 2 + 1:
            b.append(rect(x, 2 + row * (h - 4) / 2, rw - 2, (h - 4) / 2 - 1, PAPER, 9, LINE, 1.4))
            x += rw
    return svg(w_m, h_m, "".join(b))


def tank(d_m=2.2):
    w = d_m * PPM
    c = w / 2
    return svg(d_m, d_m, circle(c, c, c - 3, WHITE, INK, 2.4) + circle(c, c, c * 0.62, "none", FAINT, 1.2)
               + circle(c, c, 6, GREY_D, None))


def generator(w_m=1.6, h_m=0.9):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(3, 3, w - 6, h - 6, WHITE, 3, INK, 2), rect(10, 10, w * 0.3, h - 20, PAPER, 2, LINE, 1.2)]
    for i in range(5):
        b.append(line(w * 0.5 + i * 9, 10, w * 0.5 + i * 9, h - 10, FAINT, 1.1))
    return svg(w_m, h_m, "".join(b))


def bench(w_m=1.6, h_m=0.5):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 4, w - 4, h - 8, WHITE, 2, LINE, 1.6) + line(6, h / 2, w - 6, h / 2, FAINT, 1.0))


def planter(s=1.2):
    w = s * PPM
    rng = random.Random(13)
    return svg(s, s, rect(3, 3, w - 6, w - 6, PAPER, 2, INK, 2) + path(blob_path(w / 2, w / 2, w * 0.3, rng, 7, 0.2), "none", FAINT, 1.4))


def barrier(w_m=3.0, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(2, 2, w - 4, h - 4, GREY_L, 4, INK, 2) + rect(10, h / 2 - 5, w - 20, 10, WHITE, 3, LINE, 1.2))


def forklift(w_m=2.6, h_m=1.2):
    w, h = w_m * PPM, h_m * PPM
    b = [rect(w * 0.3, 4, w * 0.68, h - 8, WHITE, 8, INK, 2.2), rect(w * 0.42, 14, w * 0.3, h - 28, GREY_L, 4, LINE, 1.4),
         rect(2, h * 0.2, w * 0.3, 7, GREY_D, 1, None), rect(2, h * 0.8 - 7, w * 0.3, 7, GREY_D, 1, None),
         rect(w * 0.28, 4, 6, h - 8, INK, 0, None)]
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
    # 128 px app icon (v0.7.5): a doorway in plan, the leaf swung open on its arc, a
    # figure in the opening, and one red stain on the floor beyond
    body = (rect(0, 0, 128, 128, PAPER, 0, None)
            + rect(10, 54, 36, 20, INK, 0, None) + rect(82, 54, 36, 20, INK, 0, None)     # the wall, the gap
            + line(82, 54, 82, 18, INK, 5)                                                # the leaf, open
            + path("M46,54 A36,36 0 0 1 82,18", "none", FAINT, 2.5)                       # its swing
            + path(blob_path(90, 100, 12, random.Random(3), 7, 0.4), BLOOD, None)
            + ellipse(62, 66, 10, 20, WHITE, INK, 3.5) + circle(64, 66, 8, WHITE, INK, 3.5)
            + line(72, 66, 77, 66, INK, 3.5)
            + rect(4, 4, 120, 120, "none", 0, INK, 4))
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 128 128">{body}</svg>\n'


# ------------------------------------------------------------- manifest
ASSETS = {
    "op/a_stand.svg": lambda: operator("a"),
    "op/b_stand.svg": lambda: operator("b"),
    "op/a_down.svg": lambda: operator_down("a"),
    "op/b_down.svg": lambda: operator_down("b"),
    "op/c_stand.svg": lambda: civilian(),
    "op/c_down.svg": civilian_down,
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
    "ui/north.svg": north_arrow,
    "furn/bunk.svg": bunk, "furn/desk.svg": desk, "furn/chair.svg": chair, "furn/table.svg": table,
    "furn/shelving.svg": shelving, "furn/rack.svg": rack, "furn/crate.svg": crate, "furn/pallet.svg": pallet,
    "furn/cabinet.svg": cabinet, "furn/stove.svg": stove, "furn/washer.svg": washer, "furn/stairs.svg": stairs,
    "furn/lockers.svg": lockers, "furn/checkout.svg": checkout, "furn/cooler.svg": cooler,
    "yard/dumpster.svg": dumpster, "yard/van.svg": van, "yard/truck.svg": truck, "yard/container.svg": container,
    "yard/sandbags.svg": sandbags, "yard/tank.svg": tank, "yard/generator.svg": generator, "yard/bench.svg": bench,
    "yard/planter.svg": planter, "yard/barrier.svg": barrier, "yard/forklift.svg": forklift,
}


# ------------------------------------------------------------- city factions and vehicles
# Greyscale like everything else: factions differ by tone and by the mark on the
# shoulders (the same mark hatches their territory on the city plan).
FACTION_LOOK = {
    # body fill, head fill, mark
    "pd": ("#5c5c5c", WHITE, "cap"),
    "qrf": ("#2a2a2a", "#6a6a6a", "helmet"),
    "g1": ("#ececec", WHITE, "dots"),
    "g2": ("#c4c4c4", WHITE, "bands"),
    "g3": ("#a3a3a3", WHITE, "hatch"),
    "g4": ("#d6d6d6", WHITE, "check"),
    "med": (WHITE, WHITE, "cross"),
    "pmed": (GREY_L, WHITE, "cross"),
}


def _marks(mark, cx, cy):
    b = []
    if mark == "dots":
        for k in range(-2, 3):
            b.append(circle(cx - 3, cy + k * 8, 2.0, INK, None))
    elif mark == "bands":
        for k in (-12, 0, 12):
            b.append(line(cx - 11, cy + k, cx + 7, cy + k, INK, 2.0))
    elif mark == "hatch":
        for k in range(-3, 4):
            b.append(line(cx - 9, cy + k * 6 - 3, cx + 5, cy + k * 6 + 3, INK, 1.2))
    elif mark == "check":
        for k in range(-3, 4):
            b.append(line(cx - 9, cy + k * 6 - 3, cx + 5, cy + k * 6 + 3, INK, 1.0))
            b.append(line(cx - 9, cy + k * 6 + 3, cx + 5, cy + k * 6 - 3, INK, 1.0))
    elif mark == "cross":
        b.append(rect(cx - 10, cy - 3, 14, 6, INK, 0, None))
        b.append(rect(cx - 6, cy - 10, 6, 20, INK, 0, None))
    return b


def _fmark(mark, down=False):
    """A faction's one pale mark on the silhouette (the pattern that hatches its territory)."""
    def f(cx, cy):
        b = []
        if mark in ("cap", "helmet"):
            b += (_bar_down if down else _bar)(cx, cy)
        elif mark == "dots":
            for k in range(-2, 3):
                b.append(circle(cx + (k * 8 if down else -3), cy + (0 if down else k * 8), 2.2, GREY_M, None))
        elif mark == "bands":
            for k in (-12, 0, 12):
                b.append(line(cx + k, cy - 16, cx + k, cy + 16, GREY_M, 2.2) if down else line(cx - 10, cy + k, cx + 6, cy + k, GREY_M, 2.2))
        elif mark in ("hatch", "check"):
            b += (_hatch3_down if down else _hatch3)(cx, cy)
            if mark == "check":
                if down:
                    b += [line(cx + k * 12 + 4, cy - 12, cx + k * 12 - 4, cy + 12, GREY_M, 2.0) for k in (-1, 0, 1)]
                else:
                    b += [line(cx - 9, cy + k * 9 + 4, cx + 3, cy + k * 9 - 4, GREY_M, 2.0) for k in (-1, 0, 1)]
        elif mark == "cross":
            col = INK if MED_HOLLOW else GREY_M
            if down:
                b += [rect(cx - 9, cy - 4, 18, 8, col, 0, None), rect(cx - 4, cy - 10, 8, 20, col, 0, None)]
            else:
                b += [rect(cx - 10, cy - 3, 14, 6, col, 0, None), rect(cx - 6, cy - 10, 6, 20, col, 0, None)]
        return b
    return f


MED_HOLLOW = False


def operator_f(key):
    """Faction figure, facing +x. 0.8 x 0.8 m canvas."""
    global MED_HOLLOW
    _body, _head, mark = FACTION_LOOK[key]
    MED_HOLLOW = key == "med"
    if key == "med":     # city paramedics: hollow, like the people they come for, with a cross
        out = _figure(_fmark(mark), PAPER, INK, 3.0)
    else:
        out = _figure(_fmark(mark))
    if mark == "helmet":  # the QRF: a helmet ring around the head
        out = out.replace("</svg>", circle(0.4 * PPM + 5, 0.4 * PPM, 11.0, "none", GREY_M, 2.0) + "</svg>")
    return out


def operator_f_down(key):
    global MED_HOLLOW
    _body, _head, mark = FACTION_LOOK[key]
    MED_HOLLOW = key == "med"
    if key == "med":
        return _figure_down(_fmark(mark, True), PAPER, INK, 3.6)
    return _figure_down(_fmark(mark, True))


def _wheels(w, h, f1, f2):
    return [rect(w * f1, 0, 30, 6, GREY_D, 2, None), rect(w * f2, 0, 30, 6, GREY_D, 2, None),
            rect(w * f1, h - 6, 30, 6, GREY_D, 2, None), rect(w * f2, h - 6, 30, 6, GREY_D, 2, None)]


def police_car(w_m=4.6, h_m=1.9):
    """Patrol car in plan, nose toward +x: white body, dark doors and roof bar."""
    w, h = w_m * PPM, h_m * PPM
    b = [rect(4, 4, w - 8, h - 8, WHITE, 34, INK, 2.2),
         rect(w * 0.30, 6, w * 0.34, h - 12, "#3a3a3a", 6, None),
         rect(w * 0.33, 14, w * 0.30, h - 28, GREY_L, 14, LINE, 1.6),
         rect(w * 0.45, 12, 12, h - 24, INK, 3, None),
         line(w * 0.12, 20, w * 0.12, h - 20, FAINT, 1.2),
         rect(w * 0.70, 18, w * 0.12, h - 36, "none", 8, LINE, 1.4)] + _wheels(w, h, 0.18, 0.70)
    return svg(w_m, h_m, "".join(b))


def police_van(w_m=5.6, h_m=2.1):
    """Tactical van: dark grey box, cab forward."""
    w, h = w_m * PPM, h_m * PPM
    b = [rect(4, 4, w - 8, h - 8, "#3e3e3e", 20, INK, 2.2), rect(w * 0.72, 12, w * 0.13, h - 24, GREY_L, 10, LINE, 1.5),
         rect(w * 0.06, 10, w * 0.6, h - 20, "none", 4, GREY_M, 1.2), rect(w * 0.64, 10, 12, h - 20, INK, 3, None),
         line(w * 0.10, h / 2, w * 0.58, h / 2, GREY_M, 1.2)] + _wheels(w, h, 0.14, 0.76)
    return svg(w_m, h_m, "".join(b))


def ambulance(police=False, w_m=6.0, h_m=2.2):
    w, h = w_m * PPM, h_m * PPM
    band = "#3e3e3e" if police else GREY_M
    b = [rect(4, 4, w - 8, h - 8, WHITE, 18, INK, 2.2), rect(w * 0.76, 12, w * 0.12, h - 24, GREY_L, 10, LINE, 1.5),
         rect(8, h * 0.5 - 5, w * 0.66, 10, band, 0, None),
         rect(w * 0.30 - 24, h * 0.5 - 8, 48, 16, INK, 0, None), rect(w * 0.30 - 8, h * 0.5 - 24, 16, 48, INK, 0, None),
         rect(w * 0.70, 10, 12, h - 20, INK, 3, None)] + _wheels(w, h, 0.14, 0.78)
    return svg(w_m, h_m, "".join(b))


def stretcher(w_m=2.0, h_m=0.6):
    w, h = w_m * PPM, h_m * PPM
    return svg(w_m, h_m, rect(6, 4, w - 12, h - 8, WHITE, 4, INK, 1.8) + line(0, 6, w, 6, INK, 2.4)
               + line(0, h - 6, w, h - 6, INK, 2.4))


# ------------------------------------------------------------------ rig parts (1.1)
# The animated figure is drawn from parts: the torso with its mark, and the head, which
# turns on its own. Arms, feet and the shadow are drawn in code (scripts/view/rig.gd).
# Same 0.8 m canvas as the standing figure, so offsets line up.
def _torso(mark_fn=None, body=INK, outline=None):
    w = h = 0.8 * PPM
    cx, cy = w / 2, h / 2
    b = [rect(cx - 13, cy - 22, 17, 44, body, 8, outline or "none", 2.6 if outline else 0)]
    if mark_fn:
        b += mark_fn(cx - 3, cy)
    return svg(0.8, 0.8, "".join(b))


def _head(body=INK, outline=None, ring=False):
    """The head alone, centred on a 0.3 m canvas, nose toward +x."""
    w = h = 0.3 * PPM
    cx, cy = w / 2, h / 2
    b = [circle(cx, cy, 8.0, body, PAPER if not outline else INK, 2.0 if not outline else 2.6),
         line(cx + 8, cy, cx + 11, cy, INK, 2.4)]
    if ring:
        b.append(circle(cx, cy, 11.0, "none", GREY_M, 2.0))
    return svg(0.3, 0.3, "".join(b))


def _rig_parts(key):
    if key in ("a", "b"):
        return _torso(_bar if key == "a" else _hatch3), _head()
    if key == "c":
        return _torso(None, PAPER, INK), _head(PAPER, INK)
    global MED_HOLLOW
    _body, _hd, mark = FACTION_LOOK[key]
    MED_HOLLOW = key == "med"
    if key == "med":
        return _torso(_fmark(mark), PAPER, INK), _head(PAPER, INK)
    return _torso(_fmark(mark)), _head(ring=mark == "helmet")


for _k in ["a", "b", "c"] + list(FACTION_LOOK):
    ASSETS[f"op/{_k}_torso.svg"] = (lambda k=_k: _rig_parts(k)[0])
    ASSETS[f"op/{_k}_head.svg"] = (lambda k=_k: _rig_parts(k)[1])


for _k in FACTION_LOOK:
    ASSETS[f"op/{_k}_stand.svg"] = (lambda k=_k: operator_f(k))
    ASSETS[f"op/{_k}_down.svg"] = (lambda k=_k: operator_f_down(k))
ASSETS["veh/police_car.svg"] = police_car
ASSETS["veh/police_van.svg"] = police_van
ASSETS["veh/ambulance.svg"] = lambda: ambulance(False)
ASSETS["veh/police_ambulance.svg"] = lambda: ambulance(True, 5.6, 2.1)
ASSETS["fx/stretcher.svg"] = stretcher
for _w in WEAPON_ART:
    ASSETS[f"w/{_w}.svg"] = WEAPON_ART[_w]
ASSETS["kit/vest.svg"] = kit_vest
ASSETS["kit/plates.svg"] = kit_plates
ASSETS["kit/helmet.svg"] = kit_helmet
ASSETS["kit/shield.svg"] = shield_art
ASSETS["kit/ram.svg"] = ram_art
ASSETS["kit/gas_mask.svg"] = kit_gas_mask


def kit_helmet_head():
    c = 0.15 * PPM
    return svg(0.3, 0.3, circle(c, c, 9.5, INK, PAPER, 1.6) + circle(c, c, 6.0, "none", GREY_M, 1.4))


def kit_gas_mask_head():
    c = 0.15 * PPM
    cx, cy = c - 5, c
    b = [path(f"M{cx - 8},{cy - 7} A10 10 0 0 0 {cx - 8},{cy + 7}", "none", DARK, 1.6),
         rect(cx + 3, cy - 8, 6, 16, "#3a3a3a", 3, INK, 1.2),
         circle(cx + 12, cy, 4.2, "#5a5a5a", INK, 1.2),
         line(cx + 10, cy - 2.5, cx + 14, cy - 2.5, "#8a8a8a", 0.8),
         line(cx + 10, cy + 2.5, cx + 14, cy + 2.5, "#8a8a8a", 0.8)]
    return svg(0.3, 0.3, "".join(b))


ASSETS["kit/helmet_head.svg"] = kit_helmet_head
ASSETS["kit/gas_mask_head.svg"] = kit_gas_mask_head


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
            f.write(quantise(fn()))
    if not a.list:
        with open("icon.svg", "w", encoding="utf-8") as f:
            f.write(quantise(icon_app()))
        with open(os.path.join(a.out, "manifest.json"), "w", encoding="utf-8") as f:
            json.dump({"generator": "tools/make_placeholders.py", "license": "original, project-owned",
                       "px_per_metre": PPM, "files": list(ASSETS)}, f, indent=1)
        print(f"wrote {len(ASSETS)} files to {a.out}")


if __name__ == "__main__":
    main()
