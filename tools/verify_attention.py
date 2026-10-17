#!/usr/bin/env python3
"""Verify the cone-of-attention boost against the numbers it was specified with.

Godot is not required to run this. It does two jobs:

  1. Parse the tuning constants out of scripts/data/habits.gd, so the spec is
     checked against the values the game actually uses rather than copies of
     them that can drift.
  2. Re-implement Memory.boost() (scripts/sim/memory.gd) and assert the
     properties the mechanic was specified to have.

The port in `_boost()` below is a hand transcription, so it could in principle
diverge from the GDScript. `_check_port_still_matches()` greps the source for
the expressions the port depends on and fails loudly if the formula changes
shape; if it fires, re-read memory.gd and update `_boost()` before trusting
anything else this file prints.

Run:  python3 tools/verify_attention.py            (exit 0 = pass)
      python3 tools/verify_attention.py --verbose  (print the whole curve)
"""

import math
import re
import sys

ROOT_HABITS = "scripts/data/habits.gd"
ROOT_MEMORY = "scripts/sim/memory.gd"

TAU = math.tau
PI = math.pi


# --------------------------------------------------------------- GDScript builtins

def angle_difference(a: float, b: float) -> float:
    """Godot's angle_difference(from, to): the signed delta, wrapped to [-PI, PI]."""
    d = (b - a) % TAU
    if d > PI:
        d -= TAU
    return d


def lerpf(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def clampf(x: float, lo: float, hi: float) -> float:
    return lo if x < lo else (hi if x > hi else x)


# --------------------------------------------------------------- the port

EDGE_EPS = 1e-9


def _boost(look_dir, vision_half, focus_dir, focus_half, bearing,
           boost_max, boost_min):
    """Transcription of Memory.boost() from scripts/sim/memory.gd.

    The mechanic: a target only gets the bonus if it lies inside BOTH the cone
    of vision and the cone of attention. How big the bonus is depends on how
    well the two cones are lined up with each other, not on where the target
    is -- so the worst case is the two cones just touching, and the best is
    their centre lines being identical.

    The gates are inclusive (see EDGE_EPS in memory.gd): a bearing exactly on a
    cone edge is inside it, otherwise the "cones just touching" case that
    ATT_BOOST_MIN is defined at would be a coin flip on rounding.
    """
    if abs(angle_difference(bearing, look_dir)) > vision_half + EDGE_EPS:
        return 0.0
    if abs(angle_difference(bearing, focus_dir)) > focus_half + EDGE_EPS:
        return 0.0
    span = vision_half + focus_half
    if span <= 1e-6:
        return 0.0
    u = clampf(abs(angle_difference(look_dir, focus_dir)) / span, 0.0, 1.0)
    return lerpf(boost_max, boost_min, u)


def _overlap_bearing(look_dir, vision_half, focus_dir, focus_half):
    """A bearing that lies inside both cones, or None if they do not overlap.

    Picks the middle of the intersection, which is the fairest single sample
    point for a given pair of cones.
    """
    left = max(look_dir - vision_half, focus_dir - focus_half)
    right = min(look_dir + vision_half, focus_dir + focus_half)
    if left > right:
        return None
    return (left + right) * 0.5


# --------------------------------------------------------------- source parsing

def parse_constants(path=ROOT_HABITS):
    """Pull the ATT_* constants out of habits.gd without importing GDScript."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    out = {}

    def scalar(name):
        m = re.search(r"^const\s+%s\s*:?=\s*([0-9.]+)" % name, src, re.M)
        if not m:
            return None
        return float(m.group(1))

    for name in ("ATT_BOOST_MAX", "ATT_BOOST_MIN", "ATT_REC_SHARE"):
        val = scalar(name)
        if val is None:
            sys.exit("verify_attention: could not find const %s in %s" % (name, path))
        out[name] = val

    m = re.search(r"^const\s+ATT_HALF_DEG\s*:?=\s*\{([^}]*)\}", src, re.M)
    if not m:
        sys.exit("verify_attention: could not find ATT_HALF_DEG in %s" % path)
    half = {}
    for kind, val in re.findall(r'"(\w+)"\s*:\s*([0-9.]+)', m.group(1)):
        half[kind] = float(val)
    out["ATT_HALF_DEG"] = half
    return out


def _check_port_still_matches(path=ROOT_MEMORY):
    """Fail loudly if memory.gd's boost() no longer has the shape we ported."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    needed = [
        ("vision gate", r"angle_difference\(bearing,\s*o\.look_dir\)\)\s*>\s*vhalf\s*\+\s*EDGE_EPS"),
        ("attention gate", r"angle_difference\(bearing,\s*f\[.dir.\]\)\)\s*>\s*ahalf\s*\+\s*EDGE_EPS"),
        ("span is the sum of both half-angles", r"var\s+span:\s*float\s*=\s*vhalf\s*\+\s*ahalf"),
        ("lerp between the two extremes", r"lerpf\(Habits\.ATT_BOOST_MAX,\s*Habits\.ATT_BOOST_MIN,\s*u\)"),
    ]
    missing = [label for label, pat in needed if not re.search(pat, src)]
    if missing:
        sys.exit(
            "verify_attention: Memory.boost() has changed shape; re-read %s and\n"
            "  update _boost() in this file before trusting these results.\n"
            "  No longer found: %s" % (path, ", ".join(missing))
        )


# --------------------------------------------------------------- the tests

class Report:
    def __init__(self):
        self.passed = 0
        self.failed = 0

    def check(self, label, ok, detail=""):
        if ok:
            self.passed += 1
            print("  PASS  %-52s %s" % (label, detail))
        else:
            self.failed += 1
            print("  FAIL  %-52s %s" % (label, detail))
        return ok

    def close(self, label, ok, detail=""):
        return self.check(label, ok, detail)

    def near(self, label, got, want, tol=1e-9):
        return self.check(label, abs(got - want) <= tol,
                          "got %.6f want %.6f" % (got, want))


def run(verbose=False):
    _check_port_still_matches()
    const = parse_constants()
    bmax = const["ATT_BOOST_MAX"]
    bmin = const["ATT_BOOST_MIN"]
    share = const["ATT_REC_SHARE"]
    half_deg = const["ATT_HALF_DEG"]

    r = Report()
    deg = math.radians

    print("cone of attention -- spec verification")
    print("  constants read from %s" % ROOT_HABITS)
    print("    ATT_BOOST_MAX  = %.4f   (centre lines aligned)" % bmax)
    print("    ATT_BOOST_MIN  = %.4f   (cones just touching)" % bmin)
    print("    ATT_REC_SHARE  = %.4f   (recognition gets this share)" % share)
    print("    ATT_HALF_DEG   = %s" % half_deg)
    print()

    # The two numbers the mechanic was specified with.
    print("specified endpoints")
    r.near("boost max is 35%", bmax, 0.35)
    r.near("boost min is 7.5%", bmin, 0.075)
    print()

    # Use a realistic cone of vision. op.gd's default vision_half is 1.0472 rad (60 deg).
    vision_half = deg(60.0)

    # ---------------------------------------------------------------- case 1
    # Centre lines identical. The operator is looking exactly where its
    # attention is already pointing, and the target is dead ahead.
    print("case 1 -- centre lines identical -> 35%")
    look_dir = 0.0
    focus_dir = 0.0
    focus_half = deg(half_deg["seen"])          # 25 deg, the tightest cone
    bearing = 0.0
    got = _boost(look_dir, vision_half, focus_dir, focus_half, bearing, bmax, bmin)
    r.near("target dead ahead, eyes on the focus", got, bmax)
    # It should hold for any target inside the overlap, not only dead ahead.
    worst = None
    for frac in (0.0, 0.25, 0.5, 0.75, 1.0):
        b = focus_dir - focus_half + 2.0 * focus_half * frac
        v = _boost(look_dir, vision_half, focus_dir, focus_half, b, bmax, bmin)
        if worst is None or abs(v - bmax) > abs(worst - bmax):
            worst = v
    r.near("holds anywhere inside the overlap", worst, bmax)
    print()

    # ---------------------------------------------------------------- case 2
    # The theoretical edge case: the target sits on the edge of peripheral
    # vision AND on the edge of the cone of attention, which is only possible
    # when the two cones are separated by exactly vision_half + focus_half.
    print("case 2 -- peripheral edge meets attention edge -> 7.5%")
    for kind, khalf_deg in sorted(half_deg.items(), key=lambda kv: kv[1]):
        focus_half = deg(khalf_deg)
        bearing = 0.0
        look_dir = bearing - vision_half          # target on the edge of vision
        focus_dir = bearing + focus_half          # and on the edge of attention
        # Sanity: the geometry really is the two cones just touching.
        sep = abs(angle_difference(look_dir, focus_dir))
        r.check("%-6s cones separated by vhalf+ahalf" % kind,
                abs(sep - (vision_half + focus_half)) < 1e-9,
                "sep=%.4f span=%.4f" % (sep, vision_half + focus_half))
        got = _boost(look_dir, vision_half, focus_dir, focus_half, bearing, bmax, bmin)
        r.near("%-6s boost at the touching point" % kind, got, bmin)
    print()

    # ---------------------------------------------------------------- case 3
    # Scaled gradually between the extremes: sweep the cones apart and check
    # the boost falls monotonically and linearly from MAX to MIN.
    print("case 3 -- gradual scaling between the extremes")
    focus_half = deg(half_deg["seen"])
    samples = 101
    prev = None
    curve = []
    monotone = True
    linear = True
    for i in range(samples):
        u = i / (samples - 1.0)
        focus_dir = 0.0
        look_dir = focus_dir + u * (vision_half + focus_half)
        bearing = _overlap_bearing(look_dir, vision_half, focus_dir, focus_half)
        if bearing is None:
            r.check("cones still overlap at u=%.2f" % u, False)
            break
        got = _boost(look_dir, vision_half, focus_dir, focus_half, bearing, bmax, bmin)
        curve.append((u, got))
        want = lerpf(bmax, bmin, u)
        if abs(got - want) > 1e-9:
            linear = False
        if prev is not None and got > prev + 1e-12:
            monotone = False
        prev = got
    else:
        r.check("monotonically decreasing as the cones separate", monotone)
        r.check("linear in the separation (no steps or knees)", linear)
        r.near("value at u=0.00", curve[0][1], bmax)
        r.near("value at u=1.00", curve[-1][1], bmin)
        r.near("value at u=0.50 (midpoint)", curve[samples // 2][1],
               lerpf(bmax, bmin, 0.5))
        # Every interior value must sit strictly between the extremes.
        r.check("all interior values strictly between min and max",
                all(bmin - 1e-12 < v < bmax + 1e-12 for _, v in curve))
    print()

    # ---------------------------------------------------------------- case 4
    # No overlap, no bonus. The boost must not leak outside either cone.
    print("case 4 -- gating")
    focus_half = deg(half_deg["seen"])
    focus_dir = 0.0
    look_dir = 0.0
    outside_vision = look_dir + vision_half + deg(1.0)
    got = _boost(look_dir, vision_half, focus_dir, focus_half, outside_vision, bmax, bmin)
    r.near("target outside the cone of vision", got, 0.0)

    # Outside the attention cone but inside vision: possible when the vision
    # cone is the wider of the two (attention kinds are all <= 40 deg).
    bearing = focus_dir + focus_half + deg(0.5)
    got = _boost(look_dir, vision_half, focus_dir, focus_half, bearing, bmax, bmin)
    r.near("target outside the cone of attention", got, 0.0)

    # Cones pointing opposite ways: no overlap at all.
    got = _boost(0.0, vision_half, PI, focus_half, 0.0, bmax, bmin)
    r.near("cones pointing apart", got, 0.0)
    print()

    # ---------------------------------------------------------------- case 5
    # What the boost means where it is actually spent: acquisition time and
    # recognition progress. Both are `x * (1 - boost)` in world.gd.
    print("case 5 -- application")
    base_time = 1.0
    aligned = base_time * (1.0 - bmax)
    edge = base_time * (1.0 - bmin)
    r.near("acquisition time at 35%% is 65%% of base", aligned, 0.65)
    r.near("acquisition time at 7.5%% is 92.5%% of base", edge, 0.925)
    r.check("35% really is the faster end", aligned < edge)
    r.near("recognition gets ATT_REC_SHARE of the boost (aligned)",
           1.0 - share * bmax, 1.0 - 0.5 * 0.35)
    print()

    if verbose:
        print("the curve (separation as a fraction of vhalf+ahalf)")
        for u, v in curve:
            bar = "#" * int(round(v * 120))
            print("  u=%.2f  boost=%.4f  time x%.4f  %s" % (u, v, 1.0 - v, bar))
        print()

    print("-" * 62)
    print("  %d passed, %d failed" % (r.passed, r.failed))
    return 1 if r.failed else 0


if __name__ == "__main__":
    verbose = "--verbose" in sys.argv or "-v" in sys.argv
    sys.exit(run(verbose=verbose))
