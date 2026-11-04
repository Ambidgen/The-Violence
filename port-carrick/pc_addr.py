"""pc_addr.py - the Port Carrick address scheme and geocoder (shared by generator and validator).

Scheme (Chicago-style, baselines through the bridge at 0,0):
  * Streets running mostly east-west are numbered by easting x and prefixed E or W.
  * Streets running mostly north-south are numbered by northing y and prefixed N or S.
  * One address number per metre of distance from the baseline: number = floor(|axis coord|).
  * Even numbers on the north side (E-W streets) / east side (N-S streets); odd on the other side.
  * Every street polyline is stored in increasing axis order, so numbers rise away from the origin.
"""
import math
from shapely.geometry import LineString, Point
from shapely import STRtree


def even_side(axis, cross):
    return cross > 0 if axis == "EW" else cross < 0


def make_number(a, even):
    n = int(math.floor(abs(a)))
    tgt = 0 if even else 1
    if n % 2 != tgt:
        n -= 1
    if n < 1:
        n = 2 if even else 1
    return n


def prefix_for(axis, a):
    if axis == "EW":
        return "E" if a >= 0 else "W"
    return "N" if a >= 0 else "S"


def fmt_address(n, pre, name):
    return f"{n} {pre} {name}"


class Geocoder:
    def __init__(self, streets):
        self.streets = streets
        self.lines = [LineString(s["pts"]) for s in streets]
        self.by_name = {}
        for i, s in enumerate(streets):
            self.by_name.setdefault(s["name"], []).append(i)
        self.roads = [i for i, s in enumerate(streets) if s["cls"] not in ("B", "M")]
        self._tree = STRtree([self.lines[i] for i in self.roads])

    def locate(self, sid, x, y):
        ln = self.lines[sid]
        p = Point(x, y)
        s = ln.project(p)
        q = ln.interpolate(s)
        a = ln.interpolate(max(0.0, s - 1.0))
        b = ln.interpolate(min(ln.length, s + 1.0))
        dx, dy = b.x - a.x, b.y - a.y
        L = math.hypot(dx, dy) or 1.0
        dx, dy = dx / L, dy / L
        cross = dx * (y - q.y) - dy * (x - q.x)
        return dict(s=s, qx=q.x, qy=q.y, dist=p.distance(q), dx=dx, dy=dy, cross=cross)

    def address_at(self, sid, x, y):
        st = self.streets[sid]
        loc = self.locate(sid, x, y)
        a = loc["qx"] if st["axis"] == "EW" else loc["qy"]
        even = even_side(st["axis"], loc["cross"])
        n = make_number(a, even)
        return dict(street=sid, n=n, prefix=prefix_for(st["axis"], a), even=even, axis_coord=a, dist=loc["dist"])

    def reverse(self, x, y):
        i = int(self._tree.nearest(Point(x, y)))
        sid = self.roads[i]
        r = self.address_at(sid, x, y)
        r["text"] = fmt_address(r["n"], r["prefix"], self.streets[sid]["name"])
        return r

    def forward(self, n, pre, name):
        """Address -> (x, y) of the frontage (door) point, or None."""
        sign = 1 if pre in ("E", "N") else -1
        target = sign * n
        for sid in self.by_name.get(name, []):
            st = self.streets[sid]
            if prefix_for(st["axis"], target) != pre or st["axis"] != ("EW" if pre in ("E", "W") else "NS"):
                continue
            pts = st["pts"]
            k = 0 if st["axis"] == "EW" else 1
            for i in range(len(pts) - 1):
                a0, a1 = pts[i][k], pts[i + 1][k]
                lo, hi = min(a0, a1), max(a0, a1)
                if lo <= target <= hi and hi > lo:
                    t = (target - a0) / (a1 - a0)
                    x = pts[i][0] + t * (pts[i + 1][0] - pts[i][0])
                    y = pts[i][1] + t * (pts[i + 1][1] - pts[i][1])
                    dx, dy = pts[i + 1][0] - pts[i][0], pts[i + 1][1] - pts[i][1]
                    L = math.hypot(dx, dy)
                    dx, dy = dx / L, dy / L
                    even = (n % 2 == 0)
                    # left normal = (-dy, dx); EW even=north=left, NS even=east=right
                    left = even if st["axis"] == "EW" else (not even)
                    nx, ny = (-dy, dx) if left else (dy, -dx)
                    off = st["width"] / 2 + st["yard"]
                    return dict(sid=sid, x=x + nx * off, y=y + ny * off, cx=x, cy=y)
        return None
