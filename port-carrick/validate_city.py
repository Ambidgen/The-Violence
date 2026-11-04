#!/usr/bin/env python3
"""validate_city.py - independent rule checker for city.json.
Rebuilds geometry only from the document plus pc_geo / pc_addr; shares no state with the generator."""
import sys, json, math, collections
import numpy as np
import shapely
from shapely.geometry import LineString, Point, Polygon, box
from shapely import STRtree
import pc_geo as G
import pc_addr as A
import pc_net as NET

MIN_EDGE = 8.0
DEAD_END_MAX = 0.08
RAIL_CLEAR = 14.0
SITE_RULES = {"WS": dict(status=(0,), cls="bldg"), "HT": dict(status=(0,), cls="bldg"),
              "GH": dict(status=(0, 1), cls="bldg"), "BS": dict(status=(0, 1), cls=None),
              "PE": dict(status=(0,), cls=None, kinds={"civic", "faith", "plaza", "park", "cemetery", "school", "political"})}


class UF:
    def __init__(self): self.p = {}
    def f(self, a):
        self.p.setdefault(a, a)
        while self.p[a] != a:
            self.p[a] = self.p[self.p[a]]; a = self.p[a]
        return a
    def u(self, a, b): self.p[self.f(a)] = self.f(b)


def rect(cx, cy, ang, w, d, shrink=0.0):
    c, s = math.cos(ang), math.sin(ang)
    hw, hd = w / 2 - shrink, d / 2 - shrink
    pts = [(cx + a * hw * c - b * hd * s, cy + a * hw * s + b * hd * c) for a, b in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    return Polygon(pts)


def validate(path):
    D = json.load(open(path))
    checks = []

    def chk(id_, group, title, ok, detail=""):
        checks.append(dict(id=id_, group=group, title=title, ok=bool(ok), detail=str(detail)))

    meta = D["meta"]; Bd = D["buildings"]; n = Bd["n"]
    wards_names = meta["wards"]; types = meta["types"]
    streets = D["streets"]
    S = [dict(s, width=s["w"]) for s in streets]
    geo = A.Geocoder(S)
    lines = [LineString(s["pts"]) for s in S]
    road_ids = [s["id"] for s in S if s["cls"] not in ("B", "M")]
    lift_ids = [s["id"] for s in S if s["cls"] == "M"]
    deck = next(s for s in S if s["cls"] == "B")
    X0, Y0, X1, Y1 = meta["frame"]["extent"]
    ext = box(X0, Y0, X1, Y1)

    # ============================================================ CS
    chk("CS1", "coordinates", "bridge centre is lat 0, lon 0", G.enu_to_geo(0, 0) == (0.0, 0.0) and
        next(l for l in D["landmarks"] if l["id"] == "carrick-bridge")["lat"] == 0.0 and
        next(l for l in D["landmarks"] if l["id"] == "carrick-bridge")["lon"] == 0.0 and
        abs(sum(p[0] for p in deck["pts"])) < 1e-6 and abs(sum(p[1] for p in deck["pts"])) < 1e-6)
    rng = np.random.default_rng(3)
    P0 = rng.uniform([X0, Y0], [X1, Y1], (2000, 2))
    err = max(math.hypot(*(np.array(G.geo_to_enu(*G.enu_to_geo(x, y))) - (x, y))) for x, y in P0)
    lerr = max(math.hypot(l["x"] - G.geo_to_enu(l["lat"], l["lon"])[0], l["y"] - G.geo_to_enu(l["lat"], l["lon"])[1])
               for l in D["landmarks"])
    chk("CS2", "coordinates", "lat/lon <-> metres round trip < 1 mm (random points and every landmark)", err < 1e-3 and lerr < 1e-3,
        f"max err {err:.2e} m, landmarks {lerr:.2e} m")
    allx = [p[0] for s in S for p in s["pts"]] + Bd["x"]; ally = [p[1] for s in S for p in s["pts"]] + Bd["y"]
    chk("CS3", "coordinates", "everything lies inside the declared extent", min(allx) >= X0 and max(allx) <= X1 and min(ally) >= Y0 and max(ally) <= Y1)
    slope0 = float(G.yc(5.0) - G.yc(-5.0)) / 10.0
    chk("CS4", "coordinates", "bridge axis is perpendicular to the river at the datum",
        abs(slope0) < 1e-6 and deck["pts"][0][0] == deck["pts"][-1][0] == 0.0, f"river slope at x=0: {slope0:.2e}")

    # ============================================================ GE
    river = shapely.union_all([Polygon(r) for r in D["water"]["river"]])
    xs = G.XS
    wid = G.width(xs)
    chk("GE1", "geography", "one river spans the full east-west extent", river.geom_type == "Polygon" and
        river.bounds[0] <= X0 + 1 and river.bounds[2] >= X1 - 1 and float(wid.min()) > 0,
        f"x range {river.bounds[0]:.0f}..{river.bounds[2]:.0f}")
    wc = float(G.width(0.0))
    xs_ = np.arange(0.0, X1 + 1, 25.0)
    ww = G.width(xs_)
    mono = bool(np.all(np.diff(ww) > 0)) and abs(float(G.width(-1234.0)) - float(G.width(1234.0))) < 1e-9
    peaks = [(x, float(G.width(x))) for x in (-G.BAY_X, G.BAY_X)]
    chk("GE2", "geography", "river is narrowest at the bridge and widens steadily east and west (>= 3x centre width by x = +-3,250; symmetric)",
        mono and ww[0] == wc and all(w >= 3 * wc for _, w in peaks), f"centre {wc:.0f} m; x=+-3250: {peaks[0][1]:.0f} m; edge: {ww[-1]:.0f} m")
    bas = D["water"]["basins"]
    quads = sorted(b["quad"] for b in bas.values())
    okb = quads == ["NE", "NW", "SE", "SW"]
    sigs = set()
    wide_bad = []
    for nm, b in bas.items():
        r_ = box(*b["rect"]); okb &= r_.buffer(1).intersects(river) and len(b["piers"]) >= 2
        sx = 1 if b["quad"][1] == "E" else -1; sy = 1 if b["quad"][0] == "N" else -1
        okb &= (r_.centroid.x * sx > 0) and (r_.centroid.y * sy > 0)
        sigs.add((round(r_.bounds[2] - r_.bounds[0]), round(r_.bounds[3] - r_.bounds[1]), len(b["piers"])))
        cxm = (r_.bounds[0] + r_.bounds[2]) / 2
        wd_ = float(G.width(cxm))
        ok_w = wd_ >= G.MIN_BASIN_RIVER_W and wd_ >= 1.8 * float(G.width(0.0)) and min(abs(r_.bounds[0]), abs(r_.bounds[2])) >= G.MIN_BASIN_X
        ok_p = all(box(*p).distance(river) >= 40.0 for p in b["piers"])
        if not (ok_w and ok_p): wide_bad.append((nm, round(wd_), round(min(abs(r_.bounds[0]), abs(r_.bounds[2])))))
    unequal = len(sigs) == 4
    chk("GE3", "geography", "four harbour basins, one per quadrant, each open to the river with >= 2 finger piers that stop >= 40 m short of the bank",
        okb and len(bas) == 4, f"{quads}")
    chk("GE3c", "geography", f"the harbour is in the wide reaches, not at the narrows: every basin is >= {G.MIN_BASIN_X:.0f} m from the bridge and sits where the river is >= {G.MIN_BASIN_RIVER_W:.0f} m wide (>= 1.8x its width at the bridge)",
        not wide_bad, wide_bad or {nm: round(float(G.width((b['rect'][0] + b['rect'][2]) / 2))) for nm, b in bas.items()})
    chk("GE3b", "geography", "the basins are not mirror images: four distinct size/pier signatures",
        unequal, sorted(sigs))
    water = shapely.union_all([river] + [box(*b["rect"]).difference(shapely.union_all([box(*p) for p in b["piers"]])) for b in bas.values()])
    shapely.prepare(water)
    cross = D["crossings"]
    major = [c for c in cross if c.get("major")]
    minor = [c for c in cross if not c.get("major") and c["kind"] != "ferry" and c["kind"] != "car-float"]
    water_cross_streets = sorted(s["id"] for s in S if (s["cls"] in ("B", "M")) and lines[s["id"]].intersects(river))
    other_cross = [s["id"] for s in S if s["cls"] not in ("B", "M") and lines[s["id"]].intersects(river)]
    rail_cross = [r_["name"] for r_ in D["rail"] if LineString(r_["pts"]).intersection(river).length > 0.5 and r_["kind"] == "rail"]
    lift_rail = [r_ for r_ in D["rail"] if r_["kind"] == "lift-rail"]
    in_service = [c for c in cross if c.get("closed") is None]
    ok_cross = (len(major) == 1 and major[0]["id"] == "carrick-bridge" and major[0]["width"] >= 60 and major[0]["lanes"] >= 6
                and all(c["river_width"] <= G.CROSSING_MAX_WIDTH for c in cross)
                and all(c["lanes"] + 0 <= 2 for c in minor)
                and major[0]["lanes"] >= 2.5 * sum(c["lanes"] for c in minor)
                and not other_cross and not rail_cross and len(lift_rail) == 1
                and water_cross_streets == sorted([deck["id"]] + lift_ids))
    chk("GE4", "geography", "exactly one MAJOR crossing (the 62 m viaduct, >= 2.5x the lanes of all minor spans combined); every crossing sits where the river is <= 400 m wide; nothing else crosses the water",
        ok_cross, f"major {[c['id'] for c in major]}, minor {[c['id'] for c in minor]}, widths {[c['river_width'] for c in cross]}, other {other_cross}, rail {rail_cross}")
    # graph (road network + lift bridge; the viaduct is grade separated and excluded from noding)
    net_ids = road_ids + lift_ids
    key = lambda p: (round(p[0], 2), round(p[1], 2))

    def graph_of(ids):
        un_ = shapely.union_all([lines[i] for i in ids], grid_size=0.01)
        es = [g for g in (un_.geoms if hasattr(un_, "geoms") else [un_]) if g.length > 0.05]
        uf_ = UF(); dg_ = collections.Counter(); ln_ = []
        for e in es:
            c = list(e.coords); a_, b_ = key(c[0]), key(c[-1])
            uf_.u(a_, b_); dg_[a_] += 1; dg_[b_] += 1; ln_.append(e.length)
        cl = collections.Counter()
        for e in es:
            cl[uf_.f(key(e.coords[0]))] += e.length
        return es, uf_, dg_, ln_, cl

    edges, uf, deg, elen, comp_len = graph_of(net_ids)
    edges_r, uf_r, deg_r, _, comp_len_r = graph_of(road_ids)
    tot = sum(comp_len.values())
    ycen = lambda x: float(G.yc(x))
    both_r = 0
    side_r = collections.defaultdict(set)
    for node in list(uf_r.p):
        side_r[uf_r.f(node)].add(node[1] > ycen(node[0]))
    both_r = [c for c, s_ in side_r.items() if len(s_) == 2]
    side_n = collections.defaultdict(set)
    for node in list(uf.p):
        side_n[uf.f(node)].add(node[1] > ycen(node[0]))
    joined = [c for c, s_ in side_n.items() if len(s_) == 2]
    # with the viaduct closed the lift bridge still joins the banks; with the lift closed the viaduct does
    net_ = NET.Network(S)
    def banks_connected(close):
        g = net_.graph(close)
        from scipy.sparse.csgraph import connected_components
        nc, lab = connected_components(g, directed=False)
        north = net_.xy[:, 1] > np.array([ycen(x) for x in net_.xy[:, 0]])
        # connected iff some component contains nodes of both banks and is dominant
        sizes = collections.Counter(lab)
        big = [c for c, k_ in sizes.items() if k_ > 0.4 * len(lab)]
        return any(north[lab == c].any() and (~north[lab == c]).any() for c in big)
    chk("GE5", "geography",
        "crossings are redundant but not free: closing both leaves two disconnected banks; closing either one alone leaves the banks joined",
        (not banks_connected(("carrick-bridge", "ferry-st-bridge"))) and banks_connected(("carrick-bridge",)) and banks_connected(("ferry-st-bridge",)) and not both_r,
        f"no-crossing components touching both banks: {len(both_r)}")
    wpolys = {w: shapely.union_all([Polygon(r) for r in rings]) for w, rings in D["wards"].items()}
    areasum = sum(p.area for p in wpolys.values())
    ov = sum(wpolys[a].intersection(wpolys[b]).area for a in wpolys for b in wpolys if a < b)
    chk("GE6", "geography", "six wards partition the extent (no gaps, no overlaps)", abs(areasum - ext.area) < 5.0 and ov < 5.0,
        f"area sum {areasum:.0f} vs extent {ext.area:.0f}; overlap {ov:.1f}")
    bad_w = 0
    for s in S:
        m = lines[s["id"]].interpolate(0.5, normalized=True)
        if s["ward"] is None or not wpolys[s["ward"]].buffer(0.75).contains(m): bad_w += 1
    chk("GE7", "geography", "every street's declared ward contains its midpoint", bad_w == 0, f"{bad_w} mismatches")
    lim = Polygon(D["limit"])
    chk("GE8", "geography", "the city limit lies inside the extent and contains the bridge", ext.buffer(0.1).contains(lim) and lim.contains(Point(0, 0)))

    # ============================================================ RD
    sp_poly = {i: lines[i].buffer(S[i]["width"] / 2, cap_style="flat") for i in road_ids}
    inw = [i for i in road_ids if sp_poly[i].intersection(water).area > 1.0]
    chk("RD1", "roads", "no street carriageway lies in water", not inw, [S[i]["name"] for i in inw[:5]])
    top1 = max(comp_len.values()); top2 = sorted(comp_len_r.values(), reverse=True)[:2]
    chk("RD2", "roads", "the street network (with the lift bridge) is one connected component (>= 99.5% of length); without the lift bridge it is exactly two, one per bank",
        top1 / tot >= 0.995 and sum(top2) / sum(comp_len_r.values()) >= 0.995 and len(both_r) == 0,
        f"{len(comp_len)} components; largest = {100*top1/tot:.2f}% of {tot/1000:.0f} km; per-bank pair = {100*sum(top2)/sum(comp_len_r.values()):.2f}%")
    short = [l for l in elen if l < MIN_EDGE]
    chk("RD3", "roads", f"no edge shorter than {MIN_EDGE:.0f} m", len(short) == 0, f"{len(short)} short edges of {len(edges)}")
    et = STRtree(edges)
    pi, ti = et.query(edges, predicate="crosses")
    chk("RD4", "roads", "network is planar (edges meet only at nodes)", len(pi) == 0, f"{len(pi)} proper crossings")
    grp = collections.defaultdict(list)
    for s in S: grp[s["name"]].append(s)
    bad_names = []
    for nm, g in grp.items():
        if len(g) == 1: continue
        k = 0 if g[0]["axis"] == "EW" else 1
        if len({x["axis"] for x in g}) > 1: bad_names.append(nm); continue
        rr = sorted((min(p[k] for p in x["pts"]), max(p[k] for p in x["pts"])) for x in g)
        if any(rr[i][1] > rr[i + 1][0] + 1e-6 for i in range(len(rr) - 1)): bad_names.append(nm)
    chk("RD5", "roads", "street names are unique (shared only by disjoint pieces of one line)", not bad_names, bad_names[:5])
    nonmono = []
    for s in S:
        k = 0 if s["axis"] == "EW" else 1
        v = [p[k] for p in s["pts"]]
        if any(v[i + 1] <= v[i] for i in range(len(v) - 1)): nonmono.append(s["name"])
    chk("RD6", "roads", "every street is strictly monotone along its numbering axis", not nonmono, nonmono[:5])
    arts = [s for s in S if s["cls"] == "A"]
    weak = []
    for a in arts:
        hits = {S[j]["id"] for j in road_ids if S[j]["cls"] in ("A", "C", "Q") and S[j]["id"] != a["id"] and lines[a["id"]].intersects(lines[j])}
        if len({S[h]["name"] for h in hits}) < 2: weak.append(a["name"])
    wmap = {c: S[next(s["id"] for s in S if s["cls"] == c)]["w"] for c in "ALCQSB"}
    chk("RD7", "roads", "hierarchy: arterials meet >= 2 other trunk streets; widths ordered by class", not weak and wmap["B"] > wmap["A"] > wmap["Q"] > wmap["C"] > wmap["S"] > wmap["L"], f"weak: {weak}")
    nodes = list(deg)
    lim_b = lim.exterior
    dead = [nd for nd in nodes if deg[nd] == 1 and lim_b.distance(Point(nd)) > 40.0]
    chk("RD8", "roads", f"dead ends (away from the city limit) <= {100*DEAD_END_MAX:.0f}% of nodes", len(dead) / len(nodes) <= DEAD_END_MAX, f"{len(dead)} of {len(nodes)} = {100*len(dead)/len(nodes):.1f}%")
    decks = [s for s in S if s["cls"] == "B"]
    ends = [decks[0]["pts"][0], decks[0]["pts"][-1]]
    brs = [s for s in S if s["name"] == "Bridge Street"]
    verts_ok = all(any(abs(p[0] - e[0]) < 1e-6 and abs(p[1] - e[1]) < 1e-6 for s in brs for p in s["pts"]) for e in ends)
    chk("RD9", "roads", "the viaduct touches down exactly at (0, +-1300), where Bridge Street has a vertex", len(decks) == 1 and ends == [[0.0, -1300.0], [0.0, 1300.0]] and verts_ok,
        f"deck ends {ends}")
    bad_cl = []
    dl = LineString(decks[0]["pts"])
    for i in road_ids:
        x_ = lines[i].intersection(dl.buffer(31))
        if x_.is_empty: continue
        for p in (x_.geoms if hasattr(x_, "geoms") else [x_]):
            for yy in np.linspace(p.bounds[1], p.bounds[3], 12):
                if abs(yy) >= 1286.0: continue     # the touch-down junction itself / beyond the deck end
                if G.deck_clearance(yy) < G.CLEAR_MIN - 0.01 and abs(yy) > 260:
                    bad_cl.append((S[i]["name"], round(float(yy))))
    chk("RD10", "roads", f"every street passing under the viaduct has >= {G.CLEAR_MIN} m of headroom", not bad_cl, bad_cl[:4])
    bad_rail_cl = []
    for r_ in D["rail"]:
        if r_["kind"] != "rail": continue
        x_ = LineString(r_["pts"]).intersection(dl.buffer(31))
        if x_.is_empty: continue
        for p in (x_.geoms if hasattr(x_, "geoms") else [x_]):
            for yy in np.linspace(p.bounds[1], p.bounds[3], 6):
                if G.deck_clearance(yy) < 6.0: bad_rail_cl.append((r_["name"], round(float(yy))))
    chk("RD11", "roads", "a railway that passes beneath the viaduct has >= 6.0 m of headroom", not bad_rail_cl, bad_rail_cl[:3])
    rail = [LineString(r_["pts"]) for r_ in D["rail"] if r_["kind"] == "rail"]
    rail_u = shapely.union_all(rail)

    # ============================================================ BD
    types_arr = np.array(types, dtype=object)
    polys = [rect(Bd["x"][i], Bd["y"][i], Bd["a"][i], Bd["w"][i], Bd["d"][i]) for i in range(n)]
    shr = [rect(Bd["x"][i], Bd["y"][i], Bd["a"][i], Bd["w"][i], Bd["d"][i], 0.25) for i in range(n)]
    tr = STRtree(shr)
    pi, ti = tr.query(shr, predicate="intersects")
    ov = int((pi != ti).sum() // 2)
    chk("BD1", "buildings", "no two building footprints overlap", ov == 0, f"{ov} overlapping pairs of {n}")
    parr = np.array(polys, dtype=object)
    wat_hit = int(shapely.intersects(parr.astype(object), water).sum())
    spoly_all = [lines[i].buffer(S[i]["width"] / 2 + 0.3, cap_style="flat") for i in road_ids]
    stree = STRtree(spoly_all)
    pi, si = stree.query(parr, predicate="intersects")
    in_street = 0
    for a, b in zip(pi, si):
        if road_ids[b] != Bd["st"][a]: in_street += 1
    chk("BD2", "buildings", "every footprint is on land and clear of every carriageway (own street included)", wat_hit == 0 and in_street == 0, f"{wat_hit} in water, {in_street} on other streets")
    own_clip = sum(1 for i in range(n) if polys[i].intersection(sp_poly[Bd["st"][i]]).area > 0.3)
    chk("BD2b", "buildings", "every footprint clears its own street's carriageway", own_clip == 0, f"{own_clip}")
    frac_bad = 0; cen_bad = 0
    for i in range(n):
        w = wpolys[wards_names[Bd["ward"][i]]]
        if not w.contains(Point(Bd["x"][i], Bd["y"][i])): cen_bad += 1
        elif polys[i].intersection(w).area < 0.85 * polys[i].area: frac_bad += 1
    chk("BD3", "buildings", "each building's declared ward contains its centre and >= 85% of its footprint", cen_bad == 0 and frac_bad == 0, f"{cen_bad} centre mismatches, {frac_bad} straddlers")
    bad_t = []
    for i in range(n):
        t = Bd["tiers"][i]
        ins = t[0::2]; lv = t[1::2]
        ok = len(t) >= 2 or Bd["lv"][i] == 0
        if t:
            ok &= all(lv[k + 1] > lv[k] for k in range(len(lv) - 1)) and all(ins[k + 1] >= ins[k] for k in range(len(ins) - 1))
            ok &= ins[0] == 0.0 and lv[0] >= 1 and max(ins) < min(Bd["w"][i], Bd["d"][i]) / 2 - 0.5
        if not ok: bad_t.append(i)
    chk("BD4", "buildings", "tier profiles are monotone (levels rise, setbacks never reverse, upper tier fits the footprint)", not bad_t, f"{len(bad_t)} bad")
    cap = meta["lv_cap"]; tower_h = G.DECK_ABOVE_WATER + G.TOWER_HEIGHT_ABOVE_DECK
    bad_h = []
    for i in range(n):
        lm = Bd["lm"][i] >= 0
        lim_lv = 30 if lm else cap[wards_names[Bd["ward"][i]]]
        if Bd["lv"][i] > lim_lv or Bd["lv"][i] * meta["level_m"] >= tower_h: bad_h.append(i)
    chk("BD5", "buildings", "height caps: ward cap for ordinary buildings, 30 levels for landmarks, nothing taller than the bridge towers", not bad_h, f"{len(bad_h)} violations")
    mism = []; sidebad = 0
    for i in range(n):
        ad = geo.address_at(Bd["st"][i], Bd["x"][i], Bd["y"][i])
        if ad["n"] != Bd["num"][i] or ad["prefix"] != "NSEW"[Bd["pre"][i]]: mism.append(i)
        st = S[Bd["st"][i]]
        expect_even = (ad["even"])
        if (Bd["num"][i] % 2 == 0) != expect_even: sidebad += 1
    chk("BD6", "buildings", "stored address == address recomputed from geometry (number, E/W/N/S prefix, parity side)", not mism and not sidebad, f"{len(mism)} mismatches, {sidebad} parity errors")
    keys = collections.Counter((S[Bd["st"][i]]["name"], Bd["num"][i], Bd["pre"][i]) for i in range(n))
    dup = [k for k, v in keys.items() if v > 1]
    chk("BD7", "buildings", "every street address is unique", not dup, dup[:3])
    grpb = collections.defaultdict(list)
    for i in range(n): grpb[(Bd["st"][i], Bd["side"][i])].append(i)
    nonm = 0
    for k, idx0 in grpb.items():
      for pre_ in range(4):
        idx = [i for i in idx0 if Bd["pre"][i] == pre_]
        idx.sort(key=lambda i: abs(Bd["qa"][i]))       # numbers rise with distance from the baseline
        nums = [Bd["num"][i] for i in idx]
        if any(nums[j + 1] <= nums[j] for j in range(len(nums) - 1)): nonm += 1
    chk("BD8", "buildings", "numbers rise monotonically along each side of every street piece", nonm == 0, f"{nonm} sides violate")
    gap = [i for i in range(n) if lines[Bd["st"][i]].distance(polys[i]) < S[Bd["st"][i]]["w"] / 2 + 0.5]
    chk("BD9", "buildings", "set-back >= half carriageway + 0.5 m from the street centreline", not gap, f"{len(gap)}")
    deck_foot = box(-31, -1300, 31, 1300)
    under = [i for i in range(n) if polys[i].intersects(deck_foot.buffer(10))]
    chk("BD10", "buildings", "no footprint lies under or within 10 m of the viaduct deck", not under, [(i, round(Bd["x"][i]), round(Bd["y"][i]), types[Bd["t"][i]]) for i in under[:3]])
    near_rail = [i for i in range(n) if polys[i].distance(rail_u) < RAIL_CLEAR - 0.1] if rail else []
    chk("BD11", "buildings", f"no building within {RAIL_CLEAR:.0f} m of a rail line", not near_rail, f"{len(near_rail)}")
    zlow = [i for i in range(n) if Bd["z"][i] < 215.0]
    chk("BD12", "buildings", "no building sits below river level", not zlow, f"{len(zlow)}")

    # ============================================================ AD
    LM = {l["id"]: l for l in D["landmarks"]}
    bad_l = []
    for l in D["landmarks"]:
        if l["bi"] < 0: continue
        i = l["bi"]
        txt = A.fmt_address(Bd["num"][i], "NSEW"[Bd["pre"][i]], S[Bd["st"][i]]["name"])
        r_ = geo.forward(l["num"], l["pre"], S[l["street"]]["name"])
        ok = txt == l["address"] and r_ is not None and l["num"] == Bd["num"][i] and l["pre"] == "NSEW"[Bd["pre"][i]] and l["street"] == Bd["st"][i]
        if ok:
            d = polys[i].distance(Point(r_["x"], r_["y"]))
            ok &= d < 8.0
            lat, lon = G.enu_to_geo(l["x"], l["y"])
            ok &= abs(lat - l["lat"]) < 1e-6 and abs(lon - l["lon"]) < 1e-6
            # the point we resolved must be nearer to this lot than to any other lot on that street side
            near = [j for j in grpb[(Bd["st"][i], Bd["side"][i])] if polys[j].distance(Point(r_["x"], r_["y"])) < d - 0.01]
            ok &= not near
        if not ok: bad_l.append(l["id"])
    chk("AD1", "addresses", "every landmark's address geocodes forward to its own lot and its lat/lon matches its door", not bad_l, bad_l[:5])
    sample = np.random.default_rng(9).choice(n, size=min(2500, n), replace=False)
    badr = 0
    for i in sample:
        r_ = geo.forward(Bd["num"][i], "NSEW"[Bd["pre"][i]], S[Bd["st"][i]]["name"])
        if r_ is None or polys[i].distance(Point(r_["x"], r_["y"])) > 9.0: badr += 1
    chk("AD2", "addresses", "forward geocode of 2,500 random addresses lands on the right lot", badr == 0, f"{badr} misses")
    tot_m = sum(m[3] + m[4] for m in D["matrix"])
    lm_in_m = collections.Counter(x for m in D["matrix"] for x in m[5].split(";") if x)
    chk("AD3", "addresses", "address matrix totals equal building count; each landmark is listed exactly once",
        tot_m == n and all(lm_in_m[l["id"]] == 1 for l in D["landmarks"] if l["bi"] >= 0), f"matrix {tot_m} vs {n}")
    names = {s["name"] for s in S if s["cls"] != "B"}
    bad_nm = []
    for obj in list(D["landmarks"]) + list(D["sites"]):
        for nm in names:
            if len(nm) > 8 and nm in obj["name"] and S[obj["street"]]["name"] != nm and nm not in ("Bridge Street",):
                bad_nm.append((obj["id"], nm))
        if "Bridge Street" in obj["name"] and S[obj["street"]]["name"] != "Bridge Street": bad_nm.append((obj["id"], "Bridge Street"))
    chk("AD4", "addresses", "anything named after a street is addressed on that street", not bad_nm, bad_nm[:5])
    bw = [l["id"] for l in D["landmarks"] if l["bi"] >= 0 and l["ward"] != wards_names[Bd["ward"][l["bi"]]]]
    chk("AD5", "addresses", "landmark ward == ward of its building", not bw, bw)

    # ============================================================ PD
    now = sum(Bd["now"]); peak = sum(Bd["peak"]); units = sum(Bd["units"])
    chk("PD1", "population", "population now is exactly 100,000", now == meta["population"]["now"] == 100000, f"{now:,}")
    chk("PD2", "population", "peak population is exactly 150,000", peak == 150000, f"{peak:,}")
    chk("PD3", "population", "peak household size 2.4 - 3.6", 2.4 <= peak / units <= 3.6, f"{peak/units:.2f} over {units:,} units")
    bad = [i for i in range(n) if (Bd["status"][i] != 0 and Bd["now"][i] != 0) or Bd["now"][i] > Bd["peak"][i] or (Bd["units"][i] == 0 and Bd["peak"][i] != 0)]
    chk("PD4", "population", "vacant (derelict/cleared) buildings hold nobody; now <= peak; non-residential holds nobody", not bad, f"{len(bad)}")
    perw = {w: [0, 0] for w in wards_names}
    for i in range(n):
        perw[wards_names[Bd["ward"][i]]][0] += Bd["now"][i]; perw[wards_names[Bd["ward"][i]]][1] += Bd["peak"][i]
    occ = {w: v[0] / max(1, v[1]) for w, v in perw.items()}
    chk("PD5", "population", "Northgate is the most intact ward and Ironworks the most emptied", max(occ, key=occ.get) in ("northgate", "kilbride") and min(occ, key=occ.get) == "ironworks" and occ["northgate"] > 0.9 and occ["ironworks"] < 0.3,
        "; ".join(f"{w} {100*o:.0f}%" for w, o in occ.items()))
    gh_ok = []
    for g in meta["ghosts"]:
        idx = [i for i in range(n) if math.hypot(Bd["x"][i] - g["x"], Bd["y"][i] - g["y"]) < g["r"]]
        v = sum(1 for i in idx if Bd["status"][i] != 0)
        gh_ok.append((g["name"], len(idx), round(v / max(1, len(idx)), 2)))
    chk("PD6", "population", ">= 3 ghost districts: >= 40 buildings each, >= 85% vacant", sum(1 for _, k, f in gh_ok if k >= 40 and f >= 0.85) >= 3, gh_ok)
    vac = sum(1 for s in Bd["status"] if s != 0) / n
    chk("PD7", "population", "at least 15% of buildings are derelict or cleared", vac >= 0.15, f"{100*vac:.1f}%")
    chk("PD8", "population", "cleared lots exist only where peak population is non-zero or the lot is non-residential and are never occupied", all(Bd["now"][i] == 0 for i in range(n) if Bd["status"][i] == 2))

    # ============================================================ ST
    sites = D["sites"]; bad_s = []
    for s in sites:
        r_ = SITE_RULES[s["type"]]
        if s["bi"] >= 0:
            i = s["bi"]
            kind = types[Bd["t"][i]]
            lmk = D["landmarks"][Bd["lm"][i]] if Bd["lm"][i] >= 0 else None
            ok = Bd["status"][i] in r_["status"] and WARD_OK(wards_names, Bd, i, s)
            if r_["cls"] == "bldg": ok &= not (lmk and lmk["cls"] == "open")
            if "kinds" in r_: ok &= (lmk is not None and (lmk["kind"] in r_["kinds"]))
            ok &= A.fmt_address(Bd["num"][i], "NSEW"[Bd["pre"][i]], S[Bd["st"][i]]["name"]) == s["address"]
        else:
            ok = s["type"] == "PE" and lines[s["street"]].distance(Point(s["x"], s["y"])) < 40
        if not ok: bad_s.append(s["id"])
    chk("ST1", "sites", "all situation sites resolve to an address and satisfy their type constraints", not bad_s and len(sites) >= 24, bad_s)
    chk("ST2", "sites", "site ids unique, each has lat/lon consistent with x/y", len({s["id"] for s in sites}) == len(sites) and all(abs(G.geo_to_enu(s["lat"], s["lon"])[0] - s["x"]) < 1e-3 for s in sites))

    import validate_layers as VL
    VL.run(D, S, lines, chk)

    passed = sum(1 for c in checks if c["ok"])
    stats = dict(buildings=n, streets=len(S), street_km=round(sum(lines[i].length for i in road_ids) / 1000, 1), edges=len(edges), nodes=len(nodes),
                 ward_pop={w: dict(now=v[0], peak=v[1]) for w, v in perw.items()})
    return dict(total=len(checks), passed=passed, failed=len(checks) - passed, checks=checks, stats=stats)


def WARD_OK(wards_names, Bd, i, s):
    return wards_names[Bd["ward"][i]] == s["ward"]


def print_report(rep):
    for c in rep["checks"]:
        print(("PASS " if c["ok"] else "FAIL ") + f"{c['id']:5s} {c['title']}" + ("" if c["ok"] else f"\n        -> {c['detail']}"))
    print(f"{rep['passed']}/{rep['total']} checks passed", rep["stats"])


if __name__ == "__main__":
    rep = validate(sys.argv[1] if len(sys.argv) > 1 else "city.json")
    print_report(rep)
    sys.exit(0 if rep["failed"] == 0 else 1)
