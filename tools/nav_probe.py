#!/usr/bin/env python3
"""Diagnostic harness, not part of the build: a port of scripts/sim/nav.gd's 0.25 m raster
(CS, RADIUS, blocked_disc, cell_of, cell_centre, _flood, _find_path, _smooth, line_ok) and
of Geom's clearance tests, so doorway geometry can be measured without Godot.

Used for the v1.2.1 doorway pass: with nav_probe.LEGACY = True it reproduces the smoothing
test that shipped in v1.2.0 (`_collect` the cell of each sample every 0.25 m); with it
False, the segment/obstacle test that replaced it.  It mirrors the game by hand and will
drift: treat it as a ruler, not a test.  tests/nav_door_test.gd is the gate.
"""
import heapq
import math

CS = 0.25
RADIUS = 0.30
LEGACY = False


class Geom:
    def __init__(self, w, h):
        self.width, self.height = w, h
        self.rects = []  # (x0, y0, x1, y1, move, name)

    def add(self, x0, y0, w, h, move=True, name=""):
        self.rects.append((x0, y0, x0 + w, y0 + h, move, name))

    def rect_dist(self, p, r):
        x0, y0, x1, y1 = r[0], r[1], r[2], r[3]
        qx = min(max(p[0], x0), x1)
        qy = min(max(p[1], y0), y1)
        return math.hypot(qx - p[0], qy - p[1])

    def seg_point_dist(self, a, b, p):
        abx, aby = b[0]-a[0], b[1]-a[1]
        l2 = abx*abx + aby*aby
        if l2 < 1e-12:
            return math.hypot(p[0]-a[0], p[1]-a[1])
        t = max(0.0, min(1.0, ((p[0]-a[0])*abx + (p[1]-a[1])*aby) / l2))
        return math.hypot(a[0]+abx*t-p[0], a[1]+aby*t-p[1])

    def seg_rect_dist(self, a, b, r):
        x0, y0, x1, y1 = r[0], r[1], r[2], r[3]
        dx, dy = b[0]-a[0], b[1]-a[1]
        t0, t1 = 0.0, 1.0
        hit = True
        for p0, dd, lo, hi in ((a[0], dx, x0, x1), (a[1], dy, y0, y1)):
            if abs(dd) < 1e-9:
                if p0 < lo or p0 > hi:
                    hit = False
                    break
            else:
                ta, tb = (lo-p0)/dd, (hi-p0)/dd
                if ta > tb:
                    ta, tb = tb, ta
                t0 = max(t0, ta); t1 = min(t1, tb)
                if t0 > t1:
                    hit = False
                    break
        if hit:
            return 0.0
        best = min(self.seg_point_dist(a, b, c) for c in
                   ((x0, y0), (x1, y0), (x1, y1), (x0, y1)))
        return min(best, self.rect_dist(a, r), self.rect_dist(b, r))

    def path_clear(self, a, b, rad=0.30):
        if rad <= 0.0:
            return True
        for r in self.rects:
            if not r[4]:
                continue
            if self.seg_rect_dist(a, b, r) < rad:
                return False
        return True

    def path_clear_leg(self, a, b, rad=0.30):
        if (a[0]-b[0])**2 + (a[1]-b[1])**2 < 0.0004:
            return True
        for r in self.rects:
            if not r[4]:
                continue
            lim = min(rad, self.rect_dist(a, r), self.rect_dist(b, r)) - 0.01
            if lim <= 0.01:
                continue
            if self.seg_rect_dist(a, b, r) < lim:
                return False
        return True

    def blocked_disc(self, px, py, rad):
        if px < rad or py < rad or px > self.width - rad or py > self.height - rad:
            return True
        for (x0, y0, x1, y1, move, _n) in self.rects:
            if not move:
                continue
            qx = min(max(px, x0), x1)
            qy = min(max(py, y0), y1)
            if (qx - px) ** 2 + (qy - py) ** 2 < rad * rad:
                return True
        return False


class Nav:
    def __init__(self, geom):
        self.geom = geom
        self.nx = int(math.ceil(geom.width / CS))
        self.ny = int(math.ceil(geom.height / CS))
        self.solid = bytearray(self.nx * self.ny)
        self.reach = bytearray(self.nx * self.ny)
        self.w_door = [0.0] * (self.nx * self.ny)
        self.build()

    def cell_of(self, px, py=None):
        if py is None:
            px, py = px.x, px.y
        return (min(max(int(px / CS), 0), self.nx - 1),
                min(max(int(py / CS), 0), self.ny - 1))

    def cell_centre(self, c):
        return ((c[0] + 0.5) * CS, (c[1] + 0.5) * CS)

    def build(self):
        for y in range(self.ny):
            for x in range(self.nx):
                p = self.cell_centre((x, y))
                self.solid[y * self.nx + x] = 1 if self.geom.blocked_disc(p[0], p[1], RADIUS) else 0
        self._flood()

    def _flood(self):
        n = self.nx * self.ny
        comp = [-1] * n
        best_id, best_size, cid = -1, 0, 0
        for start in range(n):
            if self.solid[start] == 1 or comp[start] != -1:
                continue
            stack = [start]
            comp[start] = cid
            size = 0
            while stack:
                i = stack.pop()
                size += 1
                x, y = i % self.nx, i // self.nx
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    xx, yy = x + dx, y + dy
                    if xx < 0 or yy < 0 or xx >= self.nx or yy >= self.ny:
                        continue
                    j = yy * self.nx + xx
                    if self.solid[j] == 0 and comp[j] == -1:
                        comp[j] = cid
                        stack.append(j)
            if size > best_size:
                best_size, best_id = size, cid
            cid += 1
        for i in range(n):
            self.reach[i] = 1 if comp[i] == best_id else 0

    def free(self, c):
        return self.solid[c[1] * self.nx + c[0]] == 0

    def in_reach(self, c):
        return self.reach[c[1] * self.nx + c[0]] == 1

    def nearest_free(self, p):
        """nav.gd nearest_free: nearest cell in the main region (rings to 3 m)."""
        p = (p.x, p.y) if hasattr(p, "x") else p
        c = self.cell_of(*p)
        if self.in_reach(c):
            return c
        for r in range(1, 12):
            best, bd = None, None
            for dy in range(-r, r + 1):
                for dx in range(-r, r + 1):
                    if abs(dx) != r and abs(dy) != r:
                        continue
                    q = (c[0] + dx, c[1] + dy)
                    if q[0] < 0 or q[1] < 0 or q[0] >= self.nx or q[1] >= self.ny:
                        continue
                    if self.in_reach(q):
                        cc = self.cell_centre(q)
                        d = (cc[0] - p[0]) ** 2 + (cc[1] - p[1]) ** 2
                        if bd is None or d < bd:
                            bd, best = d, q
            if best:
                return best
        return c

    def snap(self, p):
        p = (p.x, p.y) if hasattr(p, "x") else p
        c = self.cell_of(*p)
        if self.in_reach(c):
            return p
        return self.cell_centre(self.nearest_free(p))

    # --- nav.gd _find_path / _smooth / line_ok (profile 0) ------------------
    def find_path(self, a, b):
        a = (a.x, a.y) if hasattr(a, "x") else a
        b = (b.x, b.y) if hasattr(b, "x") else b
        ca, cb = self.nearest_free(a), self.nearest_free(b)
        ids = self.path(a, b)
        if not ids:
            return []
        pts = [a if self.self_free(a) else self.cell_centre(ca)]
        for _p, c in ids[1:-1]:
            pts.append(self.cell_centre(c))
        pts.append(b if self.self_free(b) else self.cell_centre(cb))
        return self.smooth(pts)

    def self_free(self, p):
        c = self.cell_of(*p)
        return self.solid[c[1] * self.nx + c[0]] == 0

    def line_ok(self, a, b):
        if LEGACY:
            steps = int(math.hypot(b[0] - a[0], b[1] - a[1]) / CS) + 1
            for k in range(1, steps + 1):
                f = k / steps
                c = self.cell_of(a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f)
                if not self.free(c):
                    return False
            return True
        if not self.geom.path_clear_leg(a, b, RADIUS):
            return False
        steps = int(math.hypot(b[0] - a[0], b[1] - a[1]) / (CS * 0.5)) + 1
        for k in range(1, steps + 1):
            f = k / steps
            px = a[0] + (b[0] - a[0]) * f
            py = a[1] + (b[1] - a[1]) * f
            c = self.cell_of(px, py)
            if not self.free(c):
                return False
        return True

    def smooth(self, pts):
        if len(pts) <= 2:
            return pts
        out = [pts[0]]
        i, n = 0, len(pts)
        while i < n - 1:
            j = min(n - 1, i + 12)
            while j > i + 1 and not self.line_ok(pts[i], pts[j]):
                j -= 1
            out.append(pts[j])
            i = j
        return out

    # --- AStarGrid2D with DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES -----------------
    def path(self, a, b):
        a = (a.x, a.y) if hasattr(a, "x") else a
        b = (b.x, b.y) if hasattr(b, "x") else b
        start = self.nearest_free(a)
        goal = self.nearest_free(b)
        openq = [(0.0, start)]
        came = {start: None}
        g = {start: 0.0}
        while openq:
            _f, cur = heapq.heappop(openq)
            if cur == goal:
                break
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
                nb = (cur[0] + dx, cur[1] + dy)
                if nb[0] < 0 or nb[1] < 0 or nb[0] >= self.nx or nb[1] >= self.ny:
                    continue
                if not self.free(nb):
                    continue
                if dx and dy:
                    if not self.free((cur[0] + dx, cur[1])) or not self.free((cur[0], cur[1] + dy)):
                        continue
                step = math.hypot(dx, dy)
                ng = g[cur] + step
                if nb not in g or ng < g[nb] - 1e-9:
                    g[nb] = ng
                    came[nb] = cur
                    cx, cy = self.cell_centre(nb)
                    h = math.hypot(goal[0] + 0.5 - cx / CS, goal[1] + 0.5 - cy / CS)
                    heapq.heappush(openq, (ng + h, nb))
        if goal not in came:
            return []
        out, cur = [], goal
        while cur is not None:
            out.append(cur)
            cur = came[cur]
        out.reverse()
        return [(self.cell_centre(c), c) for c in out]
