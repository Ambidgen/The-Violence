#!/usr/bin/env python3
"""Diagnostic harness, not part of the build: a port of the parts of scripts/sim/level.gd
that decide where walls, doors, windows and move-blocking props are (the `_room` / `_door`
/ `_wall` helpers, `_auto_walls`, `_line_walls`, `_side_room`, `_make_leaves`), plus
room_at and is_exterior, so the shipped maps can be rasterised through tools/nav_probe.py
without Godot.

The map scripts' _build() bodies are exec'd with those helpers stubbed, after a light
GDScript-to-Python pass (var :=, for i in N, lambdas), which is enough for all twelve.  It
mirrors the game by hand and will drift: treat it as a ruler, not a test.

    python3 tools/nav_probe.py        # nothing to run on its own
    python3 -c "import tools.level_port as l; print(len(l.load_map('scripts/maps/m04_center_hall.gd').doors))"
"""
import math
import re
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])
from nav_probe import Geom, Nav, CS

WALL, COVER, CONCEAL, WINDOW, LOW = 0, 1, 2, 3, 4
EXT_T = 0.22
INT_T = 0.12


class V2:
    __slots__ = ("x", "y")

    def __init__(self, x=0.0, y=0.0):
        self.x, self.y = float(x), float(y)

    def __add__(self, o):
        return V2(self.x + o.x, self.y + o.y)

    def __sub__(self, o):
        return V2(self.x - o.x, self.y - o.y)

    def __mul__(self, s):
        return V2(self.x * s, self.y * s)

    __rmul__ = __mul__

    def __truediv__(self, s):
        return V2(self.x / s, self.y / s)

    def __neg__(self):
        return V2(-self.x, -self.y)

    def __repr__(self):
        return f"V2({self.x:.3f},{self.y:.3f})"

    def distance_to(self, o):
        return math.hypot(self.x - o.x, self.y - o.y)


class R2:
    __slots__ = ("x", "y", "w", "h")

    def __init__(self, x=0.0, y=0.0, w=0.0, h=0.0):
        if isinstance(x, V2) and isinstance(y, V2):   # Rect2(position, size)
            x, y, w, h = x.x, x.y, y.x, y.y
        self.x, self.y, self.w, self.h = float(x), float(y), float(w), float(h)

    @property
    def position(self):
        return V2(self.x, self.y)

    @property
    def end(self):
        return V2(self.x1, self.y1)

    @property
    def size(self):
        return V2(self.w, self.h)

    @property
    def x1(self):
        return self.x + self.w

    @property
    def y1(self):
        return self.y + self.h

    def area(self):
        return self.w * self.h

    def grow(self, g):
        return R2(self.x - g, self.y - g, self.w + 2 * g, self.h + 2 * g)

    def has_point(self, p):
        return self.x <= p.x <= self.x1 and self.y <= p.y <= self.y1

    def __repr__(self):
        return f"R2({self.x:.2f},{self.y:.2f},{self.w:.2f},{self.h:.2f})"


class GeomStub:
    WALL, COVER, CONCEAL, WINDOW, LOW = WALL, COVER, CONCEAL, WINDOW, LOW


class Level:
    def __init__(self):
        self.id = "base"
        self.W, self.H = 36.0, 24.0
        self.fenced = True
        self.geom = None
        self.rooms = {}
        self.doors = {}
        self.windows = []
        self.decor = []
        self._door_defs = []
        self._win_defs = []
        self._stub_ns = None

    # ---- helpers the map scripts call -------------------------------------
    def _room(self, name, title, rects, opts=None):
        opts = opts or {}
        area = sum(r.area() for r in rects)
        big = max(rects, key=lambda r: r.area())
        self.rooms[name] = {
            "rects": list(rects),
            "label": opts.get("label", V2(big.x + big.w / 2, big.y + big.h / 2)),
            "title": title,
            "exterior": bool(opts.get("deck", False)),
            "deck": bool(opts.get("deck", False)),
            "area": area,
            "nowalls": bool(opts.get("nowalls", False)) or bool(opts.get("deck", False)),
            "hall": bool(opts.get("hall", False)),
        }

    def _door(self, x, y, w=0.9, opts=None):
        opts = opts or {}
        w = max(w, 0.9)
        self._door_defs.append({"c": V2(x, y), "w": w, "id": opts.get("id", ""),
                                "arch": bool(opts.get("arch", False)), "hinge": opts.get("hinge", 1)})

    def _window(self, x, y, w=1.2):
        self._win_defs.append({"c": V2(x, y), "w": w})

    def _wall(self, r, name="wall"):
        self.geom.add(r.x, r.y, r.w, r.h, True, name)

    def _hwall(self, x0, x1, y, t, gaps, name="wall"):
        x = x0
        for g in gaps:
            if g[0] > x:
                self._wall(R2(x, y - t / 2, g[0] - x, t), name)
            if g[2] == "window":
                self.geom.add(g[0], y - t / 2, g[1] - g[0], t, True, "window")
                self.windows.append({"axis": "h"})
            x = g[1]
        if x1 > x:
            self._wall(R2(x, y - t / 2, x1 - x, t), name)

    def _vwall(self, y0, y1, x, t, gaps, name="wall"):
        y = y0
        for g in gaps:
            if g[0] > y:
                self._wall(R2(x - t / 2, y, t, g[0] - y), name)
            if g[2] == "window":
                self.geom.add(x - t / 2, g[0], t, g[1] - g[0], True, "window")
                self.windows.append({"axis": "v"})
            y = g[1]
        if y1 > y:
            self._wall(R2(x - t / 2, y, t, y1 - y), name)

    def _prop(self, key, r, kind, h, rot=0.0, name=""):
        if kind >= 0:
            self.geom.add(r.x, r.y, r.w, r.h, True, name if name else key)

    def _p(self, key, x, y, w, h, kind, height, rot=0.0, name=""):
        self._prop(key, R2(x, y, w, h), kind, height, rot, name)

    def _trunk(self, c, canopy=3.6):
        self.geom.add(c.x - 0.22, c.y - 0.22, 0.44, 0.44, True, "tree trunk")

    def _decor(self, type_, data):
        pass

    def _pool(self, r):
        self.geom.add(r.x, r.y, r.w, r.h, True, "pool")

    def _fence(self):
        t = 0.12
        self._wall(R2(0, 0, self.W, t), "fence")
        self._wall(R2(0, self.H - t, self.W, t), "fence")
        self._wall(R2(0, 0, t, self.H), "fence")
        self._wall(R2(self.W - t, 0, t, self.H), "fence")

    # ---- room queries ------------------------------------------------------
    def room_at(self, p):
        for name, rm in self.rooms.items():
            for r in rm["rects"]:
                g = r.grow(0.01)
                if g.has_point(p):
                    return name
        return "OUT"

    def is_exterior(self, rm):
        if rm == "OUT":
            return True
        r = self.rooms.get(rm)
        return r is None or r["exterior"]

    def _side_room(self, p):
        rm = self.room_at(p)
        return "OUT" if self.is_exterior(rm) else rm

    # ---- door leaves (level.gd _make_leaves) -------------------------------
    def make_leaves(self):
        for did, D in self.doors.items():
            if D.get("arch", False):
                continue
            c, t, n, half = D["c"], D["t"], D["n"], D["half"]
            xs = [c.x + t.x*half + n.x*0.04, c.x - t.x*half - n.x*0.04]
            ys = [c.y + t.y*half + n.y*0.04, c.y - t.y*half - n.y*0.04]
            D["leaf_rect"] = (min(xs), min(ys), max(xs), max(ys))
            D["n"] = n

    # ---- _auto_walls (level.gd:264-445) ------------------------------------
    @staticmethod
    def _k(v):
        return int(round(v * 100.0))

    def _auto_walls(self):
        hl, vl, hy, vx = {}, {}, {}, {}
        for nm, rm in self.rooms.items():
            if rm["nowalls"]:
                continue
            for r in rm["rects"]:
                for y in (r.y, r.y1):
                    ky = self._k(y)
                    hy[ky] = y
                    hl.setdefault(ky, []).append([r.x, r.x1])
                for x in (r.x, r.x1):
                    kx = self._k(x)
                    vx[kx] = x
                    vl.setdefault(kx, []).append([r.y, r.y1])
        gaps_h, gaps_v, pending = {}, {}, []
        for d in self._door_defs:
            pending.append({"c": d["c"], "w": d["w"], "kind": "door", "def": d})
        for wd in self._win_defs:
            pending.append({"c": wd["c"], "w": wd["w"], "kind": "window", "def": wd})
        for g in pending:
            c, half = g["c"], g["w"] / 2.0
            placed = False
            ky2 = self._k(c.y)
            if ky2 in hl:
                for iv in hl[ky2]:
                    if c.x - half >= iv[0] - 0.01 and c.x + half <= iv[1] + 0.01:
                        gaps_h.setdefault(ky2, []).append([c.x - half, c.x + half, g["kind"]])
                        g["axis"] = "h"
                        placed = True
                        break
            if not placed:
                kx2 = self._k(c.x)
                if kx2 in vl:
                    for iv in vl[kx2]:
                        if c.y - half >= iv[0] - 0.01 and c.y + half <= iv[1] + 0.01:
                            gaps_v.setdefault(kx2, []).append([c.y - half, c.y + half, g["kind"]])
                            g["axis"] = "v"
                            placed = True
                            break
            if not placed:
                g["axis"] = "?"
                print(f"    ! opening at {c} is not on any wall")
        for ky3 in hl:
            self._line_walls(True, hy[ky3], hl[ky3], gaps_h.get(ky3, []))
        for kx3 in vl:
            self._line_walls(False, vx[kx3], vl[kx3], gaps_v.get(kx3, []))
        n_auto = 0
        for g in pending:
            if g["kind"] != "door" or g["axis"] == "?":
                continue
            d = g["def"]
            n = V2(0, 1) if g["axis"] == "h" else V2(1, 0)
            did = d["id"]
            if did == "":
                n_auto += 1
                did = "D%d" % n_auto
                while did in self.doors:
                    n_auto += 1
                    did = "D%d" % n_auto
            self._add_door(did, d["c"], n, d["w"] / 2.0, d["arch"], d["hinge"])

    def _add_door(self, did, c, n, half, arch=False, hinge=1):
        a = self._side_room(V2(c.x - n.x * 0.35, c.y - n.y * 0.35))
        b = self._side_room(V2(c.x + n.x * 0.35, c.y + n.y * 0.35))
        self.doors[did] = {"id": did, "c": c, "n": n, "t": V2(-n.y, n.x), "half": half,
                           "a": a, "b": b, "hinge": hinge, "arch": arch}

    def _line_walls(self, horiz, v, ivs, gaps):
        cuts = {}
        for iv in ivs:
            cuts[self._k(iv[0])] = iv[0]
            cuts[self._k(iv[1])] = iv[1]
        for g in gaps:
            cuts[self._k(g[0])] = g[0]
            cuts[self._k(g[1])] = g[1]
        keys = sorted(cuts)
        pts = [cuts[k] for k in keys]
        pieces = []
        for i in range(len(pts) - 1):
            a, b = pts[i], pts[i + 1]
            if b - a < 0.005:
                continue
            m = (a + b) / 2.0
            if not any(m > iv[0] and m < iv[1] for iv in ivs):
                continue
            p1 = V2(m, v - 0.06) if horiz else V2(v - 0.06, m)
            p2 = V2(m, v + 0.06) if horiz else V2(v + 0.06, m)
            r1, r2 = self.room_at(p1), self.room_at(p2)
            if r1 == r2 and not self.is_exterior(r1):
                continue
            t = EXT_T if (self.is_exterior(r1) or self.is_exterior(r2)) else INT_T
            kind = "wall"
            for g in gaps:
                if m > g[0] and m < g[1]:
                    kind = g[2]
            pieces.append([a, b, kind, t])
        runs = []
        for pc in pieces:
            if pc[2] != "wall":
                runs.append(list(pc))
                continue
            if runs:
                last = runs[-1]
                if last[2] == "wall" and abs(last[1] - pc[0]) < 0.005 and abs(last[3] - pc[3]) < 0.001:
                    last[1] = pc[1]
                    continue
            runs.append(list(pc))
        for i, rn in enumerate(runs):
            a2, b2, t2 = rn[0], rn[1], rn[3]
            if rn[2] == "door":
                continue
            if rn[2] == "window":
                r = R2(a2, v - t2 / 2, b2 - a2, t2) if horiz else R2(v - t2 / 2, a2, t2, b2 - a2)
                self.geom.add(r.x, r.y, r.w, r.h, True, "window")
                self.windows.append({"axis": "h" if horiz else "v"})
                continue
            prev_gap = i > 0 and runs[i - 1][2] != "wall" and abs(runs[i - 1][1] - a2) < 0.005
            next_gap = i < len(runs) - 1 and runs[i + 1][2] != "wall" and abs(runs[i + 1][0] - b2) < 0.005
            ext = EXT_T / 2.0
            if not prev_gap:
                a2 -= ext
            if not next_gap:
                b2 += ext
            r = R2(a2, v - t2 / 2, b2 - a2, t2) if horiz else R2(v - t2 / 2, a2, t2, b2 - a2)
            self._wall(r, "wall")


TRUE_FALSE = (("true", "True"), ("false", "False"))


def load_map(path):
    """Run a map script's _init (W/H only) and _build (calls) in a stub namespace."""
    src = open(path).read()
    lv = Level()
    ns = {
        "Vector2": V2, "Rect2": R2, "Geom": GeomStub, "PI": math.pi,
        "float": float, "int": int, "abs": abs, "max": max, "min": min,
        "range": range, "hash": hash, "round": round,
    }
    for name in ("_room", "_door", "_window", "_wall", "_hwall", "_vwall", "_prop", "_p",
                 "_trunk", "_decor", "_pool", "_fence", "_auto_walls"):
        ns[name] = getattr(lv, name)
    # class attributes assigned at the top of the script (id, W, H, fenced, ...)
    head = src.split("func ")[0]
    for m in re.finditer(r"^(?:var|const)\s+(\w+)(?::\s*\w+)?\s*:?=\s*(.+?)(?:\s*#.*)?$", head, re.M):
        name, expr = m.group(1), m.group(2).strip()
        for a, b in TRUE_FALSE:
            expr = expr.replace(a, b)
        try:
            val = eval(expr, dict(ns))
        except Exception:
            continue
        if hasattr(lv, name):
            setattr(lv, name, val)
    # helper functions in a map script read instance state by bare name (rooms, geom...)
    ns["rooms"] = lv.rooms
    ns["doors"] = lv.doors
    ns["geom"] = lv.geom
    ns["windows"] = lv.windows
    ns["decor"] = lv.decor
    helpers = _funcs(src)
    for hname, (argl, hbody) in helpers.items():
        if hname in ("_init", "_build"):
            continue
        code = f"def {hname}({argl}):\n" + "\n".join("    " + ln if ln.strip() else "" for ln in _py_body(hbody).split("\n"))
        try:
            exec(code, ns)
        except Exception as e:
            print(f"    ! helper {hname} failed in {path}: {e}")
    ns["_add_door"] = lv._add_door
    consts = {}
    for m in re.finditer(r"^const\s+(\w+)\s*(?::\s*\w+)?\s*:=\s*(.+?)(?:\s*#.*)?$", src, re.M):
        expr = m.group(2).strip()
        for a, b in TRUE_FALSE:
            expr = expr.replace(a, b)
        try:
            ns[m.group(1)] = eval(expr, dict(ns))
        except Exception:
            pass
    body = _py_body(_func_body(src, "_init") or "")
    if body:
        try:
            exec(body, ns)
        except Exception as e:
            print(f"    ! _init failed for {path}: {e}")
    for k in ("id", "W", "H", "fenced", "time_limit", "map_name"):
        if k in ns:
            setattr(lv, k, ns[k])
    lv.geom = Geom(lv.W, lv.H)
    if lv.fenced:
        lv._fence()
    body = _py_body(_func_body(src, "_build") or "")
    try:
        exec(body, ns)
    except Exception as e:
        print(f"    ! _build failed for {path}: {type(e).__name__}: {e}")
        return None
    return lv


def _py_body(body):
    """GDScript -> Python for the subset the map scripts use."""
    out = []
    for line in body.split("\n"):
        line = re.sub(r"\btrue\b", "True", line)
        line = re.sub(r"\bfalse\b", "False", line)
        line = re.sub(r"^(\s*)var\s+(\w+)\s*(?::\s*\w+)?\s*:=\s*", r"\1\2 = ", line)
        line = re.sub(r"^(\s*)var\s+(\w+)\s*:\s*\w+\s*=\s*", r"\1\2 = ", line)
        line = re.sub(r"^(\s*)const\s+(\w+)\s*(?::\s*\w+)?\s*:=\s*", r"\1\2 = ", line)
        line = re.sub(r"\bfor\s+(\w+)\s+in\s+(\d+)\s*:", r"for \1 in range(\2):", line)
        line = re.sub(r"\bfor\s+(\w+)\s+in\s+(\w+)\.size\(\)\s*:", r"for \1 in range(len(\2)):", line)
        line = re.sub(r"\.call\(", "(", line)
        m = re.match(r"^(\s*)(\w+)\s*=\s*func\s*\((.*?)\)\s*(?:->\s*[\w\.]+)?\s*:\s*return\s+(.+)$", line)
        if m:
            args = ", ".join(a.split(":")[0].strip() for a in m.group(3).split(",") if a.strip())
            line = f"{m.group(1)}{m.group(2)} = lambda {args}: {m.group(4)}"
        out.append(line)
    return "\n".join(out)


def _funcs(src):
    """{name: (args, body)} for every top-level func."""
    out = {}
    lines = src.split("\n")
    i = 0
    while i < len(lines):
        m = re.match(r"^func\s+(\w+)\s*\((.*?)\)", lines[i])
        if not m:
            i += 1
            continue
        name, args = m.group(1), m.group(2)
        body = []
        i += 1
        while i < len(lines) and (lines[i].startswith("\t") or lines[i].strip() == ""):
            body.append(lines[i][1:] if lines[i].startswith("\t") else "")
            i += 1
        argl = ", ".join(a.split(":")[0].split("=")[0].strip() for a in args.split(",") if a.strip())
        out[name] = (argl, "\n".join(body))
    return out


def _func_body(src, name):
    lines = src.split("\n")
    out, inside = [], False
    for line in lines:
        if not inside:
            if re.match(r"^func\s+" + re.escape(name) + r"\s*\(", line):
                inside = True
            continue
        if line.strip() == "":
            out.append("")
            continue
        if line.startswith("\t"):
            out.append(line[1:])
        else:
            break
    return "\n".join(out)
