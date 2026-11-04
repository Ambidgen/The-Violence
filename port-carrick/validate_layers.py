"""validate_layers.py - the v4 rules: history (HS), flood (FL), utilities (UT), services (SV).
Called from validate_city.validate(); reads only the city document and pc_geo / pc_net."""
import math, collections
import numpy as np
from shapely.geometry import LineString, Point
import pc_geo as G
import pc_net as NET

LAND = G.LANDING


def _spearman(a, b):
    ra = np.argsort(np.argsort(a)); rb = np.argsort(np.argsort(b))
    return float(np.corrcoef(ra, rb)[0, 1])


def run(D, S, lines, chk):
    Bd = D["buildings"]; n = Bd["n"]; meta = D["meta"]; types = meta["types"]
    x = np.array(Bd["x"]); y = np.array(Bd["y"]); z = np.array(Bd["z"])
    peak = np.array(Bd["peak"]); now = np.array(Bd["now"]); status = np.array(Bd["status"])
    yr = np.array(Bd["yr"]); abn = np.array(Bd["abn"]); fl = np.array(Bd["fl"])
    LM = {l["id"]: l for l in D["landmarks"]}
    W = D["wall"]; U = D["utilities"]; H = D["history"]; SV = D["services"]
    river = G.RIVER

    # ================================================================ HS  history
    cs = D["crossings"]
    ids = [c["id"] for c in cs]
    by = {c["id"]: c for c in cs}
    order_ok = [c["year"] for c in cs] == sorted(c["year"] for c in cs) and len({c["year"] for c in cs}) == len(cs)
    ferry_ok = by["ferry"]["closed"] == by["ferry-st-bridge"]["year"] and by["ferry"]["x"] == by["ferry-st-bridge"]["x"]
    major = [c for c in cs if c.get("major")]
    last_ok = len(major) == 1 and major[0]["year"] == max(c["year"] for c in cs) and major[0]["year"] > by["rail-lift"]["year"] > by["ferry-st-bridge"]["year"]
    rail_first = by["rail-lift"]["year"] < major[0]["year"] and by["rail-lift"]["tracks"] == 2
    chk("HS1", "history", "crossings accrete in order: ferry, swing/lift bridge (replacing it at the same place), rail lift bridge, and only then the viaduct, which is the newest and the only major one",
        order_ok and ferry_ok and last_ok and rail_first, [(c["id"], c["year"]) for c in cs])
    # every road is older than what stands on it; residential stock is all built by the peak year
    era = np.array([S[s].get("era", 9999) for s in Bd["st"]])
    bad_age = np.where(yr <= era)[0]
    res = np.array(Bd["units"]) > 0
    late_res = np.where(res & (yr > H["year_peak"]))[0]
    chk("HS2", "history", "every building post-dates its street; every dwelling was built by the peak year; nothing post-dates today",
        len(bad_age) == 0 and len(late_res) == 0 and yr.max() <= H["year_now"], f"{len(bad_age)} older than their street, {len(late_res)} late dwellings")
    # the grid is accretive: streets get younger with distance from the landing, and the oldest street is Ferry Street at the landing
    lat = [s for s in S if s["kind"] in ("lattice",) and s["cls"] != "B" and "era" in s]
    mids = [lines[s["id"]].interpolate(0.5, normalized=True) for s in lat]
    dist = [math.hypot(m.x - LAND[0], m.y - LAND[1]) for m in mids]
    rho = _spearman([s["era"] for s in lat], dist)
    noera = [s for s in S if "era" not in s]
    oldest = min(S, key=lambda s: (s.get("era", 9999), lines[s["id"]].distance(Point(*LAND))))
    tav = LM.get("landing-tavern")
    chk("HS3", "history", "the street grid is accretive: era rises with distance from the ferry landing (rho >= 0.4) and the oldest street starts at the landing",
        not noera and rho >= 0.4 and oldest.get("era") == H["year_founded"] and lines[oldest["id"]].distance(Point(*LAND)) < 45.0 and tav is not None and tav["yr"] == 1796,
        f"rho {rho:.2f}; oldest {oldest['name']} {oldest['era']}")
    # basins: dug at different dates, the original first; the fill post-dates the basin it fills
    bs = D["water"]["basins"]
    yrs = {k: v["year"] for k, v in bs.items()}
    fill = D["water"]["fill"]
    fill_streets = [s for s in S if s.get("fill")]
    fill_b = [i for i in range(n) if S[Bd["st"][i]].get("fill")]
    allowed = {"warehouse", "factory", "shed", "industry", "utility"}
    bad_fill = [i for i in fill_b if types[Bd["t"][i]] in ("rowhouse", "house", "tenement", "apartment", "shop")]
    chk("HS4", "history", "harbour chronology: four different dig years, the Packet Basin oldest; the Fish Basin fill post-dates its basin and carries only light industry",
        len(set(yrs.values())) == 4 and min(yrs, key=yrs.get) == "Packet Basin" and fill["year"] > yrs["Fish Basin"] and not bad_fill and
        all(s["era"] == fill["year"] for s in fill_streets) and all(yr[i] > fill["year"] for i in fill_b),
        f"{yrs}; {len(fill_b)} buildings on the fill")
    # the population curve is rebuilt from the building years
    cur = H["pop"]
    mono_up = all(cur[i + 1][1] >= cur[i][1] for i in range(len(cur) - 1) if cur[i + 1][0] <= H["year_peak"])
    mono_dn = all(cur[i + 1][1] <= cur[i][1] for i in range(len(cur) - 1) if cur[i][0] >= H["year_peak"])
    ok_pts = True
    for Y, P in cur:
        if Y <= H["year_peak"]:
            v = int(peak[yr <= Y].sum())
        else:
            v = int(np.where(abn <= Y, now, peak)[yr <= Y].sum())
        ok_pts &= (v == P)
    byy = dict(map(tuple, cur))
    chk("HS5", "history", "population curve rebuilds from building years: rises to exactly 150,000 at the peak year, falls to exactly 100,000 now",
        ok_pts and mono_up and mono_dn and byy[H["year_peak"]] == 150000 and byy[H["year_now"]] == 100000, f"peak {byy.get(H['year_peak'])}, now {byy.get(H['year_now'])}")
    # decline is causal: later abandonment dates belong to weaker causes; nobody is abandoned before the peak
    dec = (now < peak) | (status != 0)
    chk("HS6", "history", "decline starts after the peak year and ends before today; every declined building has a date and no other building does",
        bool(np.all(abn[dec] > H["year_peak"])) and bool(np.all(abn[dec] <= H["year_now"])) and bool(np.all(abn[~dec] == 9999)), f"{int(dec.sum())} declined")

    # ================================================================ FL  flood
    gates = W["gates"]; segs = W["segments"]
    bad_wall = []
    for bank in "NS":
        runs = sorted((s["pts"][0][0], s["pts"][-1][0]) for s in segs if s["bank"] == bank)
        gs = sorted((g["x0"], g["x1"]) for g in gates if g["bank"] == bank)
        edges = [W["x"][0]]
        for a, b in gs: edges += [a, b]
        edges.append(W["x"][1])
        want = [(edges[i], edges[i + 1]) for i in range(0, len(edges), 2) if edges[i + 1] - edges[i] >= 20]
        if [(round(a, 1), round(b, 1)) for a, b in runs] != [(round(a, 1), round(b, 1)) for a, b in want]: bad_wall.append(bank)
    chk("FL1", "flood", "the floodwall's crest clears the flood line by >= 3 m, and its runs plus its gates cover the protected reach with no other gap",
        W["crest"] >= G.FLOOD_LINE + 3 and not bad_wall and W["x"] == list(G.WALL_X) and W["year"] > W["flood_year"], f"{bad_wall}")
    bad_g = []
    for g in gates:
        xm = (g["x0"] + g["x1"]) / 2
        if g["kind"] == "basin":
            q = g["id"][-2:]
            r = bs[[k for k, v in bs.items() if v["quad"] == q][0]]["rect"]
            ok = g["x0"] <= r[0] - G.RING_PAD and g["x1"] >= r[2] + G.RING_PAD and g["year"] >= r_year(bs, q)
        elif g["kind"] == "road":
            ok = any(s["name"].startswith("Ferry Street") and lines[s["id"]].distance(Point(xm, float(G.bank_n(xm)) + 8.0 if g["bank"] == "N" else float(G.bank_s(xm)) - 8.0)) < 4 for s in S)
        else:
            ok = any(r_["kind"] in ("rail", "lift-rail") and LineString(r_["pts"]).distance(Point(xm, float(G.bank_n(xm)) + 8.0 if g["bank"] == "N" else float(G.bank_s(xm)) - 8.0)) < 4 for r_ in D["rail"])
        if not ok: bad_g.append(g["id"])
    in_reach = [k for k, v in bs.items() if abs(v["rect"][0]) < G.WALL_X[1]]
    chk("FL2", "flood", "every opening in the wall is a real thing passing through it: each in-reach basin, Ferry Street and the rail spur get a gate; no gate is built before what it serves",
        not bad_g and sum(1 for g in gates if g["kind"] == "basin") == len(in_reach), f"{bad_g}")
    off_bad = []
    for s in segs:
        for px, py in s["pts"]:
            d = Point(px, py).distance(river)
            if abs(d - W["off"]) > 0.7: off_bad.append((round(px), round(d, 1)))
    chk("FL3", "flood", "the wall stands 8 m back from the water's edge, between the water and the quay road", not off_bad, off_bad[:3])
    pump = [LM[p] for p in U["pumps"]]
    bad_p = []
    for bank in "NS":
        xs = sorted(p["x"] for p in pump if p["bank"] == bank)
        pts = [W["x"][0]] + xs + [W["x"][1]]
        gaps = [pts[i + 1] - pts[i] for i in range(len(pts) - 1)]
        if len(xs) < 3 or max(gaps) > 1700.0 or any(p["x"] < W["x"][0] or p["x"] > W["x"][1] for p in pump if p["bank"] == bank): bad_p.append((bank, len(xs), round(max(gaps))))
    land = all(Point(p["x"], p["y"]).distance(river) > W["off"] for p in pump)
    chk("FL4", "flood", "pump stations stand behind the wall (landward of it), >= 3 per bank, no unpumped stretch of wall longer than 1,700 m", not bad_p and land, bad_p)
    fl_re = np.where(z >= G.FLOOD_LINE, 0, np.where(np.abs(x) <= G.WALL_X[1], 1, 2))
    chk("FL5", "flood", "every building's stored flood class (0 above the line, 1 behind the wall, 2 on the unprotected flats) matches its ground and position", bool(np.all(fl_re == fl)), f"{int((fl_re != fl).sum())} mismatches")
    resv = res & (peak > 0)
    mv = lambda m: float((status[m] != 0).mean()) if m.any() else 0.0
    v0 = mv(resv & (fl == 0)); v1 = mv(resv & (fl == 1)); v2 = mv(resv & (fl == 2))
    n2 = int((resv & (fl == 2)).sum())
    chk("FL6", "flood", "abandonment follows exposure: any homes on the unprotected flats are >= 90% vacant, and behind-the-wall lowland is >= 10 points emptier than high ground",
        (n2 == 0 or v2 >= 0.90) and v1 > v0 + 0.10, f"above line {100*v0:.0f}%, behind wall {100*v1:.0f}%, flats: {n2} homes" + (f" {100*v2:.0f}% vacant" if n2 else " (the far bays were never built on)"))

    # ================================================================ UT  utilities
    fac = {f["zone"]: f for f in U["facilities"]}
    zone = []
    for i in range(n):
        zone.append(G.zone_of(G.bank_is_north(x[i], y[i]), z[i]))
    head = np.array([fac[zz]["twl"] - z[i] for i, zz in enumerate(zone)])
    chk("UT1", "utilities", f"every building has {G.HEAD_MIN:.0f}-{G.HEAD_MAX:.0f} m of gravity head from its pressure zone's storage",
        set(fac) == {"NL", "NH", "SL", "SH"} and head.min() >= G.HEAD_MIN and head.max() <= G.HEAD_MAX, f"{head.min():.1f}..{head.max():.1f} m")
    bad_f = []
    for f in fac.values():
        gz = float(G.terrain(f["x"], f["y"]))
        h = 45.0 if "standpipe" in f["id"] else 10.0
        if abs(gz - f["ground"]) > 0.25 or abs(f["twl"] - (gz + h)) > 0.3 or G.bank_is_north(f["x"], f["y"]) != (f["zone"][0] == "N"): bad_f.append(f["id"])
        if f["zone"][1] == "H" and f["ground"] < G.ZONE_SPLIT: bad_f.append(f["id"] + ":low")
    chk("UT2", "utilities", "storage sits on the right bank at its stated ground elevation; high-zone storage stands above the zone split", not bad_f, bad_f)
    pumps_by_bank = collections.defaultdict(list)
    for p in pump: pumps_by_bank[p["bank"]].append(p["x"])
    bad_l = []
    for l in U["laterals"]:
        xm = (l["up"][0] + l["down"][0]) / 2
        # recompute the fall from the ground itself
        zu = float(G.terrain(*l["up"])); zd = float(G.terrain(*l["down"]))
        riv_up = abs(l["up"][1] - float(G.yc(l["up"][0]))); riv_dn = abs(l["down"][1] - float(G.yc(l["down"][0])))
        ok = abs((zu - zd) / l["len"] - l["fall"]) < 2e-4 and riv_dn < riv_up
        if l["fall"] < G.SEWER_MIN_FALL:
            pumped = abs(xm) <= G.WALL_X[1] and pumps_by_bank[l["bank"]] and min(abs(xm - px) for px in pumps_by_bank[l["bank"]]) <= 700.0
            flats = abs(xm) > G.WALL_X[1]
            ok &= bool(pumped or flats)
        if not ok: bad_l.append((l["st"], S[l["st"]]["name"], l["fall"]))
    chk("UT3", "utilities", "every sewer lateral drains toward the river: >= 0.3% fall, or it is flat behind the wall and lifted by a pump station within 700 m, or it lies in the unprotected flats",
        not bad_l and len(U["laterals"]) >= 30, bad_l[:4])
    oxs = {b: [o["x"] for o in U["outfalls"] if o["bank"] == b] for b in "NS"}
    ic = U["interceptors"]
    ic_ok = all(i["flow"] == "east" and all(i["pts"][k + 1][0] > i["pts"][k][0] for k in range(len(i["pts"]) - 1)) for i in ic)
    plants = {p: LM[p] for p in U["plants"]}
    plant_ok = all(plants[i["to"]]["x"] > max(oxs[i["bank"]]) and plants[i["to"]]["bank"] == i["bank"] for i in ic)
    intake = LM[U["intake"]]
    intake_ok = intake["x"] < min(min(v) for v in oxs.values()) - 600.0
    od = [Point(o["x"], o["y"]).distance(river) for o in U["outfalls"]]
    chk("UT4", "utilities", "the river flows west to east: the water intake is upstream (west) of every outfall by >= 600 m, each treatment plant is downstream (east) of every outfall on its bank, and interceptors run east",
        ic_ok and plant_ok and intake_ok and max(od) < 1.0 and len(U["outfalls"]) >= 12, f"intake x {intake['x']:.0f}; plants {[round(p['x']) for p in plants.values()]}")
    basin_cso = {o["id"].split("-")[1][:2] for o in U["outfalls"] if len(o["id"].split("-")[1]) > 2 and o["id"].split("-")[1][:2] in ("NE", "NW", "SW", "SE")}
    chk("UT5", "utilities", "combined sewers overflow into the harbour: each of the four basins has its own CSO outfall", basin_cso == {"NE", "NW", "SW", "SE"}, sorted(basin_cso))

    # ================================================================ SV  emergency services (dual-bank redundancy)
    bank_of = lambda l: "N" if G.bank_is_north(l["x"], l["y"]) else "S"
    svc = {k: [l for l in D["landmarks"] if l["kind"] == k] for k in ("fire", "police", "health")}
    per_bank = {k: collections.Counter(bank_of(l) for l in v) for k, v in svc.items()}
    ok_bank = (per_bank["fire"]["N"] >= 2 and per_bank["fire"]["S"] >= 2 and per_bank["police"]["N"] >= 1 and per_bank["police"]["S"] >= 1
               and per_bank["health"]["N"] >= 1 and per_bank["health"]["S"] >= 1 and all(l["bank"] == bank_of(l) for v in svc.values() for l in v))
    chk("SV1", "services", "no service depends on the bridges: >= 2 fire stations, >= 1 police station and >= 1 hospital on each bank", ok_bank, {k: dict(v) for k, v in per_bank.items()})
    tf, tv, tc = np.array(Bd["tf"]), np.array(Bd["tv"]), np.array(Bd["tc"])
    pop = now.astype(float)
    cov = lambda t, lim: float(pop[t <= lim].sum() / pop.sum())
    chk("SV2", "services", f"fire response: >= 95% of residents within {G.FIRE_LIMIT_S/60:.0f} min with every crossing open; >= 90% within 8 min with the viaduct and the lift bridge both closed; nobody unreachable",
        cov(tf, G.FIRE_LIMIT_S) >= 0.95 and cov(tc, 480) >= 0.90 and int((tc >= 99999).sum()) == 0 and bool(np.all(tf <= tv)) and bool(np.all(tv <= tc)),
        f"open {100*cov(tf, G.FIRE_LIMIT_S):.1f}% in 5 min; both closed {100*cov(tc, 480):.1f}% in 8 min")
    net = NET.Network(S)
    def door_xy(j):
        return Bd["x"][j], Bd["y"][j]
    samp = np.arange(0, n, 53)
    srcs = [(l["x"], l["y"]) for l in svc["fire"]]
    tg = [door_xy(j) for j in samp]
    mism = 0
    for scen, arr in (((), tf), (("carrick-bridge",), tv), (("carrick-bridge", "ferry-st-bridge"), tc)):
        t_ = net.times(srcs, tg, close=scen)
        mism += int((np.abs(t_ - arr[samp]) > 45).sum())      # door points differ by a few metres from building centres
    spurs(D, S, chk)
    chk("SV3", "services", "stored response times match an independent recomputation over the street network (sampled, all three scenarios)", mism <= 0.02 * 3 * len(samp), f"{mism} of {3*len(samp)} off by > 45 s")


def spurs(D, S, chk):
    bs = D["water"]["basins"]
    ok = True; det = []
    for nm, sp in (("Packet Basin", "Packet Spur"), ("Coal Basin", "Coal Spur")):
        ring = next(s for s in S if s["name"] == nm.replace(" Basin", " Basin Road"))
        spur = [r for r in D["rail"] if r["name"] == sp]
        d = min((LineString(r["pts"]).distance(LineString(ring["pts"])) for r in spur), default=1e9)
        ok &= bool(spur) and d < 3.0 and all(r["era"] >= bs[nm]["year"] for r in spur)
        det.append((sp, round(d, 1)))
    chk("RD12", "roads", "each big basin (Packet, Coal) is served by a rail spur that ends on its ring road and post-dates the basin", ok, det)


def r_year(bs, q):
    return [v["year"] for v in bs.values() if v["quad"] == q][0]
