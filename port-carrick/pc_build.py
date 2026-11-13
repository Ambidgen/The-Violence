"""pc_build.py - lots, buildings, landmarks, abandonment and exact population calibration."""
import math
import numpy as np
import shapely
from shapely.geometry import LineString, Point, box
from shapely import STRtree
import pc_geo as G
import pc_addr as A
import pc_streets as P
import pc_landmarks as LM

WARD_ORDER = ["oldtown", "riverside", "ironworks", "eastport", "kilbride", "northgate"]
WARD_IDX = {w: i for i, w in enumerate(WARD_ORDER)}
LEVEL_M = 3.0                     # one storey = one contour interval = 3 m
BATTER_M = 0.30                   # plan inset per level when drawing storey contours
TARGET_NOW, TARGET_PEAK = 100_000, 150_000
HH_PEAK = 2.9

# type: (wmin,wmax,dmin,dmax,lvmin,lvmax, residential, extra_yard)
TYPES = ["rowhouse", "house", "tenement", "shop", "apartment", "warehouse", "factory", "shed"]
TT = {
    "rowhouse": (5.0, 6.8, 11.0, 14.5, 2, 3, "res", 0.0),
    "house": (10.0, 15.0, 10.0, 13.0, 2, 3, "res", 5.0),
    "tenement": (11.0, 17.0, 15.0, 20.0, 3, 5, "res", 0.0),
    "shop": (5.5, 9.0, 13.0, 18.0, 2, 4, "mixed", 0.0),
    "apartment": (20.0, 32.0, 18.0, 26.0, 4, 9, "res", 0.0),
    "warehouse": (22.0, 48.0, 20.0, 34.0, 1, 3, "non", 0.0),
    "factory": (36.0, 80.0, 28.0, 50.0, 2, 4, "non", 0.0),
    "shed": (3.4, 5.0, 4.0, 6.0, 1, 1, "non", 0.0),
}
PROFILE = {   # rowhouse house tenement shop apartment warehouse factory shed
    "oldtown":   [.22, .03, .20, .30, .12, .07, .04, .00],
    "riverside": [.40, .05, .25, .12, .05, .08, .05, .00],
    "eastport":  [.28, .04, .12, .12, .04, .20, .20, .00],
    "ironworks": [.24, .01, .08, .07, .02, .22, .36, .00],
    "kilbride":  [.50, .12, .12, .12, .02, .05, .07, .00],
    "northgate": [.05, .62, .03, .06, .10, .02, .02, .00],
}
LV_CAP = {"oldtown": 14, "riverside": 9, "eastport": 9, "ironworks": 10, "kilbride": 6, "northgate": 6}
SPECIAL_LV_CAP = 30
LV_CAP_FACTORY = 4
KEY_OFFSET = {"oldtown": -0.10, "riverside": 0.0, "eastport": 0.0, "ironworks": -0.05, "kilbride": 0.08, "northgate": -0.10}
M2_PER_UNIT = 92.0
DECK_FOOT = box(-42, -1312, 42, 1312)


def rect_polys(cx, cy, ang, w, d, shrink=0.0):
    c, s = np.cos(ang), np.sin(ang)
    hw, hd = w / 2 - shrink, d / 2 - shrink
    ux, uy = c, s
    vx, vy = -s, c
    corners = []
    for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1), (-1, -1)):
        corners.append(np.stack([cx + a * hw * ux + b * hd * vx, cy + a * hw * uy + b * hd * vy], axis=-1))
    return shapely.polygons(np.stack(corners, axis=1))


def tiers_for(tp, w, d, lv, rng):
    if tp == "apartment" and lv >= 6:
        return [[0.0, 3], [2.0, int(lv)]]
    if tp == "factory" and w > 50 and lv >= 2 and lv < LV_CAP_FACTORY:
        return [[0.0, int(lv)], [round(min(w, d) * 0.22, 1), int(lv) + 1]]
    return [[0.0, int(lv)]]


def units_for(tp, w, d, lv):
    kind = TT[tp][6]
    if kind == "non":
        return 0
    if tp == "house":
        return 1 if lv <= 2 else 2
    floors = lv if kind == "res" else max(0, lv - 1)
    return int(max(1 if kind == "res" else 0, round(w * d * floors * 0.82 / M2_PER_UNIT)))


class Env:
    def __init__(self, streets, rail):
        self.streets = streets
        self.lines = [LineString(s["pts"]) for s in streets]
        self.road_ids = [i for i, s in enumerate(streets) if s["cls"] not in ("B", "M")]
        self.spolys = [self.lines[i].buffer(streets[i]["width"] / 2 + 0.5, cap_style="round") for i in self.road_ids]
        self.stree = STRtree(self.spolys)
        self.rail_buf = shapely.union_all([LineString(r["pts"]).buffer(14.0) for r in rail if r["kind"] == "rail"])
        self.wall_buf = shapely.union_all([LineString(p["pts"]).buffer(2.5) for p in G.wall_segments()])
        self.limit_in = P.LIMIT.buffer(-12)
        shapely.prepare(G.WATER); shapely.prepare(self.wall_buf); shapely.prepare(self.rail_buf); shapely.prepare(self.limit_in); shapely.prepare(DECK_FOOT)

    def valid(self, polys, own):
        ok = ~shapely.intersects(polys, G.WATER)
        ok &= shapely.within(polys, self.limit_in)
        ok &= ~shapely.intersects(polys, DECK_FOOT)
        ok &= ~shapely.intersects(polys, self.rail_buf)
        ok &= ~shapely.intersects(polys, self.wall_buf)
        ci, si = self.stree.query(polys, predicate="intersects")
        ok[ci] = False          # any carriageway (own street included) plus a 0.5 m verge
        return ok


def smooth_noise(x, y, seed=0):
    p = seed * 1.7
    return (0.5 * np.sin(x / 530.0 + 1.3 + p) * np.sin(y / 470.0 + 0.4 - p)
            + 0.3 * np.sin(x / 190.0 + y / 240.0 + 2.1 * p) + 0.2 * np.sin(x / 90.0 - y / 130.0 + 0.7))


# ---------------------------------------------------------------------------- specials
def place_specials(env, streets):
    placed = []
    placed_polys = []
    out = []
    names = {}
    for i, s in enumerate(streets):
        if s["cls"] not in ("B", "M"):
            names.setdefault(s["name"], []).append(i)
    for sp0 in LM.L:
      sp = dict(sp0)
      for attempt in range(6):
        ward = sp["ward"]
        elig = [i for i in env.road_ids if streets[i]["ward"] == ward]
        if sp["street"]:
            elig = [i for i in names[sp["street"]]]
        elines = [env.lines[i] for i in elig]
        ax, ay = sp["anchor"]
        if sp["street"]:
            u = shapely.union_all(elines)
            q = u.interpolate(u.project(Point(ax, ay)))
            ax, ay = q.x, q.y
        etree = STRtree(elines)
        R = 330.0 if sp["cls"] == "open" else 260.0
        step = 3.0
        gx, gy = np.meshgrid(np.arange(ax - R, ax + R + 1, step), np.arange(ay - R, ay + R + 1, step))
        gx, gy = gx.ravel(), gy.ravel()
        m = (gx - ax) ** 2 + (gy - ay) ** 2 <= R * R
        gx, gy = gx[m], gy[m]
        pts = shapely.points(gx, gy)
        idx, dist = etree.query_nearest(pts, return_distance=True, all_matches=False)
        pi, ei = idx[0], idx[1]
        gx, gy, dist = gx[pi], gy[pi], dist
        eid = np.array(elig)[ei]
        wd = np.array([streets[i]["width"] for i in eid])
        yd = np.array([streets[i]["yard"] for i in eid])
        target = wd / 2 + yd + sp["d"] / 2
        sel = np.abs(dist - target) <= 2.1
        gx, gy, eid, dist = gx[sel], gy[sel], eid[sel], dist[sel]
        wardpoly = G.WARDS[ward]
        shapely.prepare(wardpoly)
        sel = shapely.contains(wardpoly, shapely.points(gx, gy))
        gx, gy, eid = gx[sel], gy[sel], eid[sel]
        # orientation from the street tangent at the projection
        ang = np.zeros(len(gx))
        qx = np.zeros(len(gx)); qy = np.zeros(len(gx))
        for k in range(len(gx)):
            ln = env.lines[eid[k]]
            s = ln.project(Point(gx[k], gy[k]))
            a = ln.interpolate(max(0, s - 0.75)); b = ln.interpolate(min(ln.length, s + 0.75))
            ang[k] = math.atan2(b.y - a.y, b.x - a.x)
            qx[k], qy[k] = ln.interpolate(s).x, ln.interpolate(s).y
        polys = rect_polys(gx, gy, ang, sp["w"], sp["d"])
        ok = env.valid(polys, eid)
        for pp in placed_polys:
            ok &= ~shapely.intersects(polys, pp.buffer(2.0))
        cand = np.where(ok)[0]
        if len(cand) == 0:
            if attempt == 5:
                raise RuntimeError(f"cannot place {sp['id']}")
            sp["w"] = round(sp["w"] * 0.85, 1); sp["d"] = round(sp["d"] * 0.88, 1)   # shrink to fit the block
            continue
        k = cand[np.argmin((gx[cand] - ax) ** 2 + (gy[cand] - ay) ** 2)]
        placed_polys.append(polys[k])
        out.append(dict(spec=sp, cx=float(gx[k]), cy=float(gy[k]), ang=float(ang[k]), street=int(eid[k]),
                        qx=float(qx[k]), qy=float(qy[k])))
        break
    return out


# ---------------------------------------------------------------------------- regular lots
def _profile(ward, st):
    w = np.array(PROFILE[ward], float)
    cls, kind = st["cls"], st["kind"]
    if st.get("fill"):
        return np.array([0, 0, 0, 0, 0, .60, .20, .20])      # the Fish Flats were filled in 1971: light industry only
    if kind in ("pier",):
        w = np.array([0, 0, 0, 0, 0, .70, .0, .30])
    elif kind in ("quay", "ring"):
        w = w * np.array([.3, .1, .3, .7, .2, 3.0, 2.0, 0]) + np.array([0, 0, 0, 0, 0, 0, 0, .05 * w.sum()])
    elif cls in ("A", "C"):
        w = w * np.array([.6, .5, 1.0, 2.5, 1.5, .8, .6, 0])
    return w / w.sum()


def gen_lots(env, streets, rng):
    recs = []
    for i in env.road_ids:
        st = streets[i]
        ln = env.lines[i]
        L = ln.length
        ward = st["ward"]
        if ward is None:
            continue
        prof = _profile(ward, st)
        for side in (1, -1):
            s = rng.uniform(1.5, 6.0)
            prev = None
            while True:
                tp = prev if (prev is not None and rng.random() < 0.72) else int(rng.choice(8, p=prof))
                prev = tp
                name = TYPES[tp]
                wmin, wmax, dmin, dmax, lmin, lmax, kind, xyard = TT[name]
                w = rng.uniform(wmin, wmax)
                d = rng.uniform(dmin, dmax)
                if st["kind"] == "pier":
                    w = min(w, 26.0); d = min(d, 11.0)
                lv = int(rng.integers(lmin, lmax + 1))
                lv = min(lv, LV_CAP[ward])
                if s + w > L - 1.5:
                    break
                recs.append((i, side, s + w / 2, tp, w, d, lv, xyard))
                s += w + rng.uniform(0.0, 0.8)
    R = np.array(recs, float)
    sid = R[:, 0].astype(int); side = R[:, 1].astype(int); sc = R[:, 2]
    n = len(R)
    cx = np.zeros(n); cy = np.zeros(n); ang = np.zeros(n); qx = np.zeros(n); qy = np.zeros(n)
    for i in np.unique(sid):
        m = np.where(sid == i)[0]
        ln = env.lines[i]
        s = sc[m]
        a = shapely.line_interpolate_point(ln, np.clip(s - 0.75, 0, ln.length))
        b = shapely.line_interpolate_point(ln, np.clip(s + 0.75, 0, ln.length))
        q = shapely.line_interpolate_point(ln, s)
        ax_, ay_ = shapely.get_x(a), shapely.get_y(a)
        bx_, by_ = shapely.get_x(b), shapely.get_y(b)
        t = np.arctan2(by_ - ay_, bx_ - ax_)
        qx[m], qy[m], ang[m] = shapely.get_x(q), shapely.get_y(q), t
    wd = np.array([streets[i]["width"] for i in sid]); yd = np.array([streets[i]["yard"] for i in sid])
    off = wd / 2 + yd + R[:, 7] + R[:, 5] / 2
    cx = qx - np.sin(ang) * side * off
    cy = qy + np.cos(ang) * side * off
    return dict(street=sid, side=side, s=sc, tp=R[:, 3].astype(int), w=R[:, 4], d=R[:, 5], lv=R[:, 6].astype(int),
                cx=cx, cy=cy, ang=ang, qx=qx, qy=qy)


def address_fields(streets, sid, side, qx, qy):
    """vectorised address assignment per the scheme in pc_addr"""
    n = len(sid)
    num = np.zeros(n, int); pre = np.empty(n, "U1"); even = np.zeros(n, bool)
    for k in range(n):
        st = streets[sid[k]]
        ew = st["axis"] == "EW"
        a = qx[k] if ew else qy[k]
        ev = (side[k] > 0) if ew else (side[k] < 0)
        num[k] = A.make_number(a, ev)
        pre[k] = A.prefix_for(st["axis"], a)
        even[k] = ev
    return num, pre, even


def build_buildings(streets, rail, rng):
    env = Env(streets, rail)
    sp = place_specials(env, streets)
    lots = gen_lots(env, streets, rng)
    # assemble arrays: specials first
    ns = len(sp)
    cols = {}
    sx = np.array([p["cx"] for p in sp]); sy = np.array([p["cy"] for p in sp]); sa = np.array([p["ang"] for p in sp])
    sw = np.array([p["spec"]["w"] for p in sp], float); sd = np.array([p["spec"]["d"] for p in sp], float)
    ssid = np.array([p["street"] for p in sp]); sqx = np.array([p["qx"] for p in sp]); sqy = np.array([p["qy"] for p in sp])
    tx, ty = np.cos(sa), np.sin(sa)
    sside = np.where(tx * (sy - sqy) - ty * (sx - sqx) > 0, 1, -1)
    allc = dict(
        cx=np.r_[sx, lots["cx"]], cy=np.r_[sy, lots["cy"]], ang=np.r_[sa, lots["ang"]],
        w=np.r_[sw, lots["w"]], d=np.r_[sd, lots["d"]],
        street=np.r_[ssid, lots["street"]], side=np.r_[sside, lots["side"]],
        qx=np.r_[sqx, lots["qx"]], qy=np.r_[sqy, lots["qy"]],
        tp=np.r_[np.full(ns, -1), lots["tp"]], lv=np.r_[[p["spec"]["lv"] for p in sp], lots["lv"]],
    )
    N = len(allc["cx"])
    polys = rect_polys(allc["cx"], allc["cy"], allc["ang"], allc["w"], allc["d"])
    cpolys = rect_polys(allc["cx"], allc["cy"], allc["ang"], allc["w"], allc["d"], shrink=0.1)
    valid = env.valid(polys, allc["street"])
    valid[:ns] = True
    # ward of each building = ward containing its centre
    ward = np.full(N, -1)
    pts = shapely.points(allc["cx"], allc["cy"])
    for k, wn in enumerate(WARD_ORDER):
        poly = G.WARDS[wn]
        shapely.prepare(poly)
        m = (ward < 0) & shapely.contains(poly, pts)
        ward[m] = k
    valid &= ward >= 0
    # a lot's height cap follows the ward its centre lies in, not the ward of the street it fronts
    wcap = np.array([LV_CAP[WARD_ORDER[w]] if w >= 0 else 0 for w in ward])
    allc["lv"] = np.r_[allc["lv"][:ns], np.minimum(allc["lv"][ns:], wcap[ns:])]
    # density key
    rad = np.sqrt((allc["cx"] / 3850.0) ** 2 + (allc["cy"] / 2300.0) ** 2)
    off = np.array([KEY_OFFSET[WARD_ORDER[w]] if w >= 0 else 9 for w in ward])
    key = rad + off + 0.10 * smooth_noise(allc["cx"], allc["cy"], 3) + rng.normal(0, 0.025, N)
    key[:ns] = -1.0
    # greedy collision-free selection in key order
    tree = STRtree(cpolys)
    ci, ti = tree.query(cpolys, predicate="intersects")
    m = ci != ti
    ci, ti = ci[m], ti[m]
    o = np.argsort(ci, kind="stable")
    ci, ti = ci[o], ti[o]
    indptr = np.searchsorted(ci, np.arange(N + 1))
    acc = np.zeros(N, bool)
    order = np.argsort(key, kind="stable")
    for i in order:
        if not valid[i]:
            continue
        nb = ti[indptr[i]:indptr[i + 1]]
        if nb.size and acc[nb].any():
            continue
        acc[i] = True
    return dict(env=env, specials=sp, cols=allc, key=key, accepted=acc, ward=ward, ns=ns, polys=polys)


if __name__ == "__main__" and False:
    import time
    t0 = time.time()
    rng = np.random.default_rng(1995)
    S = P.build_streets(); R = P.build_rail(); P.apply_named(S, R, LM.NAMED_STREETS)
    r = build_buildings(S, R, rng)
    print("time", time.time() - t0)
    acc = r["accepted"]; c = r["cols"]
    print("candidates", len(acc), "accepted", acc.sum())
    # capacity in units
    tpn = c["tp"]; units = np.zeros(len(acc), int)
    for k in np.where(acc)[0]:
        if tpn[k] >= 0:
            units[k] = units_for(TYPES[tpn[k]], c["w"][k], c["d"][k], c["lv"][k])
    print("total units if everything accepted", units.sum())
    for k, wn in enumerate(WARD_ORDER):
        m = acc & (r["ward"] == k)
        print(wn, m.sum(), units[m].sum())
