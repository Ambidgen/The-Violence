"""pc_finalize.py - from accepted lots to the final building set, history, flood exposure, causal abandonment,
exact population calibration, sites and address book."""
import math, json
import numpy as np
import shapely
from scipy.spatial import cKDTree
from shapely.geometry import LineString, Point
import pc_geo as G, pc_addr as A, pc_streets as P, pc_landmarks as LM
from pc_build import *

# Names of the ghost districts and the windows in which each one can emerge. Their centres are NOT drawn by hand:
# they are found afterwards where the causal vacancy field is highest inside the window.
GHOST_WINDOWS = [
    ("The Slag", (-3000.0, -1800.0, -1900.0, -300.0)),            # below the slag heap: brownfield, bluff, rail yards
    ("Cinder Hollow", (-3500.0, -2000.0, 250.0, 1200.0)),        # the west-bay port district: Fish Basin and its flats
    ("Hale Yards", (2000.0, 3300.0, 350.0, 1150.0)),             # the east-bay port district: Packet Basin
    ("Tannery Flats", (2200.0, 3400.0, -1100.0, -150.0)),        # the east-bay port district: Grain Basin
    ("Foundry Bottoms", (-2000.0, -400.0, -1800.0, -600.0)),     # south-bank mill district
]
GHOST_R = 380.0
WEIGHTS = dict(expo=1.2, brown=0.30, sever=0.30, iso=0.60, age=0.55, serv=0.35)
GHOSTS = []          # filled by finalize()

DEV_RETUNE = False
UNPROTECTED_X = G.WALL_X[1]


def largest_remainder(weights, total):
    w = np.asarray(weights, float)
    q = w / w.sum() * total
    base = np.floor(q).astype(int)
    rem = total - base.sum()
    order = np.argsort(-(q - base), kind="stable")
    base[order[:rem]] += 1
    return base


def flood_class(z, x):
    """0 = above the flood line; 1 = below it but behind the floodwall; 2 = below it and outside the wall (the flats)"""
    z = np.asarray(z, float); x = np.asarray(x, float)
    low = z < G.FLOOD_LINE
    inside = np.abs(x) <= UNPROTECTED_X
    return np.where(~low, 0, np.where(inside, 1, 2))


def drivers(B, streets, rail, specials, spec_idx):
    """The causes of abandonment, one array per driver, each scaled 0..1."""
    x, y, z = B["cx"], B["cy"], B["z"]
    n = len(x)
    typ = np.array(B["type"], dtype=object)
    # --- flood: below the flood line, and outside the 1938 wall is far worse than behind it
    fl = flood_class(z, x)
    depth = np.clip((G.FLOOD_LINE - z) / 6.0, 0, 1)
    expo = np.where(fl == 2, 0.70 + 0.30 * depth, np.where(fl == 1, 0.12 + 0.18 * depth, 0.0))
    # --- brownfield: heavy industry nearby, and the slag heap itself
    ind = np.isin(typ, ["warehouse", "factory", "industry"])
    pts = np.c_[x, y]
    t_all = cKDTree(pts)
    t_ind = cKDTree(pts[ind]) if ind.any() else None
    cnt_all = np.array([len(v) for v in t_all.query_ball_point(pts, 300.0)])
    cnt_ind = np.array([len(v) for v in t_ind.query_ball_point(pts, 300.0)]) if t_ind else np.zeros(n)
    slag = np.exp(-np.hypot(x + 2400.0, y + 900.0) / 450.0)
    brown = np.clip(1.8 * cnt_ind / np.maximum(cnt_all, 1) + 0.8 * slag, 0, 1)
    # --- severance: the rail corridors, and the 1958 viaduct's ramps
    rs = []
    for r in rail:
        if r["kind"] != "rail":
            continue
        ln = LineString(r["pts"])
        rs += [(ln.interpolate(d).x, ln.interpolate(d).y) for d in np.arange(0, ln.length, 20.0)]
    d_r = cKDTree(np.array(rs)).query(pts)[0]
    t_rail = np.exp(-d_r / 90.0)
    ramp = np.where(np.abs(y) <= 1300.0, np.exp(-np.maximum(np.abs(x) - 31.0, 0) / 80.0), 0.0) * 0.8
    sever = np.maximum(t_rail, ramp)
    # --- isolation from the two crossings
    iso = np.clip(np.minimum(np.hypot(x, y), np.hypot(x - G.FERRY_X, y)) / 4200.0, 0, 1)
    # --- age of the street pattern
    era = np.array([streets[s]["era"] for s in B["street"]], float)
    age = np.clip((1936.0 - era) / 142.0, 0, 1)
    # --- services close by (schools, hospitals, fire, police, civic)
    sv = [(B["cx"][j], B["cy"][j]) for j in np.where(B["is_special"])[0]
          if specials[B["special_idx"][j]]["spec"]["kind"] in ("school", "health", "fire", "police", "civic")]
    d_s = cKDTree(np.array(sv)).query(pts)[0]
    serv = np.exp(-d_s / 450.0)
    return dict(fl=fl, expo=expo, brown=brown, sever=sever, iso=iso, age=age, serv=serv)


def finalize(r, streets, rail, rng):
    c = r["cols"]; acc = r["accepted"]; ns = r["ns"]; key = r["key"].copy(); ward = r["ward"]
    sel = np.where(acc)[0]
    sel = sel[np.argsort(key[sel], kind="stable")]
    units = np.zeros(len(acc), int)
    tiers = [None] * len(acc)
    ttype = [None] * len(acc)
    for k in sel:
        if k < ns:
            spc = r["specials"][k]["spec"]
            ttype[k] = spc["kind"]
            lv = spc["lv"]
            tiers[k] = [list(t) for t in spc["tiers"]] if spc["tiers"] else ([[0.0, lv]] if lv else [])
            if spc["units"] is not None:
                units[k] = spc["units"]
            elif spc["kind"] == "housing":
                units[k] = max(1, int(round(spc["w"] * spc["d"] * lv * 0.82 / M2_PER_UNIT)))
        else:
            tp = TYPES[c["tp"][k]]
            ttype[k] = tp
            tiers[k] = tiers_for(tp, c["w"][k], c["d"][k], c["lv"][k], rng)
            units[k] = units_for(tp, c["w"][k], c["d"][k], c["lv"][k])
    cum = np.cumsum(units[sel])
    target_units = TARGET_PEAK / HH_PEAK
    kcut = int(np.argmin(np.abs(cum - target_units)))
    keep = sel[: kcut + 1]
    keep = np.unique(np.r_[keep, np.arange(ns)[acc[:ns]]])
    keep = keep[np.argsort(key[keep], kind="stable")]
    n = len(keep)
    B = {k: np.asarray(v)[keep] for k, v in c.items()}
    for k_, nd in (("cx", 1), ("cy", 1), ("w", 1), ("d", 1), ("ang", 4)):
        B[k_] = np.round(B[k_], nd)
    B["ward"] = ward[keep]
    B["key"] = key[keep]
    B["is_special"] = keep < ns
    B["special_idx"] = np.where(keep < ns, keep, -1)
    B["units"] = units[keep]
    B["tiers"] = [tiers[k] for k in keep]
    B["type"] = [ttype[k] for k in keep]
    B["z"] = np.round(G.terrain(B["cx"], B["cy"]), 1)
    res = B["units"] > 0
    peak = np.zeros(n, int)
    peak[res] = largest_remainder(B["units"][res], TARGET_PEAK)
    B["peak"] = peak

    # ----- when each building was built: after its street, in the decades that district filled
    era = np.array([streets[s]["era"] for s in B["street"]], int)
    yr = np.zeros(n, int)
    for j in range(n):
        e = era[j]
        if B["is_special"][j]:
            yr[j] = max(int(r["specials"][B["special_idx"][j]]["spec"]["yr"]), e + 1)
            continue
        wn = WARD_ORDER[B["ward"][j]]
        nonres = B["units"][j] == 0
        if wn == "northgate":
            lo, hi = 1946, 1962
        elif nonres:
            lo, hi = e + 1, min(1990, e + 60)
        else:
            lo, hi = e + 2, min(1962, e + 38)
        if hi <= lo:
            lo = min(lo, 1962 if not nonres else lo); hi = lo + 1
        yr[j] = int(rng.integers(lo, hi + 1))
        if not nonres:
            yr[j] = min(yr[j], 1962)
        yr[j] = max(yr[j], e + 1)
    B["yr"] = yr

    # ----- causal vacancy
    D = drivers(B, streets, rail, r["specials"], B["special_idx"])
    B["fl"] = D["fl"]
    B["drv"] = D
    W = WEIGHTS
    pv = (W["expo"] * D["expo"] + W["brown"] * D["brown"] + W["sever"] * D["sever"] + W["iso"] * D["iso"] + W["age"] * D["age"]
          - W["serv"] * D["serv"] + 0.10 * smooth_noise(B["cx"], B["cy"], 11) + rng.normal(0, 0.04, n))
    pv[B["is_special"]] = -9.0
    for j in np.where(B["is_special"])[0]:
        if r["specials"][B["special_idx"][j]]["spec"]["status"] == "derelict":
            pv[j] = 9.0 - 1.0
    generic = {}

    def pick(street_name, types, lvmin=0):
        sids = {s["id"] for s in streets if s["name"] == street_name}
        cand = [j for j in range(n) if B["street"][j] in sids and B["type"][j] in types and not B["is_special"][j]
                and B["lv"][j] >= lvmin and B["units"][j] > 0]
        if not cand:
            raise RuntimeError("no host on " + street_name)
        mx, my = np.mean([B["cx"][j] for j in cand]), np.mean([B["cy"][j] for j in cand])
        return min(cand, key=lambda j: (B["cx"][j] - mx) ** 2 + (B["cy"][j] - my) ** 2)
    generic["front-st-flat"] = int(pick("Front Street", {"shop"}, 3))
    generic["foundry-row-warrant"] = int(pick("Foundry Road", {"rowhouse"}))
    for j in generic.values():
        pv[j] = -9.0
    B["generic"] = generic
    B["pv"] = pv
    q50 = float(np.median(pv[res & (pv > -5)]))
    frac = np.clip(1 - 0.55 * np.maximum(0, pv - q50), 0.45, 1.0)
    CLEAR_GAP = 0.30

    def now_total(cut):
        occ = pv < cut
        return int(np.round(peak * frac)[occ & res].sum())

    lo, hi = -1.0, 4.0
    for _ in range(60):
        mid = (lo + hi) / 2
        if now_total(mid) < TARGET_NOW:
            lo = mid
        else:
            hi = mid
    cut = hi
    occ = pv < cut
    status = np.where(occ, 0, np.where(pv < cut + CLEAR_GAP, 1, 2))
    for j in np.where(B["is_special"])[0]:
        if pv[j] == 8.0:
            status[j] = 1
        elif pv[j] < -5:
            status[j] = 0
    now = np.where((status == 0) & res, np.round(peak * frac).astype(int), 0)
    now = np.minimum(now, peak)
    diff = TARGET_NOW - int(now.sum())
    idx = np.where((status == 0) & res)[0]
    guard = 0
    while diff != 0 and guard < 100000:
        j = idx[guard % len(idx)]
        if diff > 0 and now[j] < peak[j]:
            now[j] += 1; diff -= 1
        elif diff < 0 and now[j] > 1:
            now[j] -= 1; diff += 1
        guard += 1
    B["status"] = status
    B["now"] = now
    B["cut"] = float(cut)

    # ----- when decline reached each building (earlier where the causes are stronger)
    abn = np.full(n, 9999, int)
    dec = (now < peak) | (status != 0)
    idxd = np.where(dec)[0]
    if idxd.size:
        pr = pv[idxd]
        rank = (np.argsort(np.argsort(-pr)) + 0.5) / idxd.size        # 0 = most severe
        a_ = 1963 + np.round(58.0 * rank + rng.normal(0, 2.5, idxd.size)).astype(int)
        abn[idxd] = np.clip(a_, 1963, 2022)
    B["abn"] = abn

    # ----- ghost districts: found where vacancy is highest inside each window
    vac = (status != 0).astype(float)
    pts = np.c_[B["cx"], B["cy"]]
    tree = cKDTree(pts)
    GHOSTS.clear()
    for name, (xa, xb, ya, yb) in GHOST_WINDOWS:
        best = None
        for gx in np.arange(xa, xb + 1, 100.0):
            for gy in np.arange(ya, yb + 1, 100.0):
                if any(math.hypot(gx - g_[2], gy - g_[3]) < 1.7 * GHOST_R for g_ in GHOSTS):
                    continue
                ids = tree.query_ball_point([gx, gy], GHOST_R)
                if len(ids) < 40:
                    continue
                f = vac[ids].mean()
                sc = (f, len(ids))
                if best is None or sc > best[0]:
                    best = (sc, gx, gy)
        if best is None:
            continue
        (_, gx, gy) = best
        wn = next((w for w in WARD_ORDER if G.WARDS[w].contains(Point(gx, gy))), "eastport")
        GHOSTS.append((name, wn, float(gx), float(gy), GHOST_R))

    # ----- addresses
    geo = A.Geocoder([dict(s, width=s["width"]) for s in streets])
    num = np.zeros(n, int); pre = np.empty(n, "U1"); even = np.zeros(n, bool); qa = np.zeros(n)
    for j in range(n):
        ad = geo.address_at(int(B["street"][j]), float(B["cx"][j]), float(B["cy"][j]))
        num[j], pre[j], even[j], qa[j] = ad["n"], ad["prefix"], ad["even"], ad["axis_coord"]
        B["side"][j] = 1 if (ad["even"] == (streets[B["street"][j]]["axis"] == "EW")) else -1
    B["num"], B["pre"], B["even"], B["qa"] = num, pre, even, qa
    return B
