"""pc_export.py - sites, landmarks, address matrix, contours and the city.json document."""
import json, math, collections, os
import numpy as np
import shapely
from shapely.geometry import LineString, Point, Polygon
from skimage import measure
import pc_geo as G, pc_addr as A, pc_streets as P, pc_landmarks as LM, pc_net as NET
from pc_build import WARD_ORDER, TYPES, LEVEL_M, BATTER_M, TARGET_NOW, TARGET_PEAK, LV_CAP

SITE_SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sites_src.json")
SITE_TO_LM = {
    "bridge-st-eviction": "bridge-st-apts", "civic-plaza-rally": "civic-plaza", "city-hall-steps": "city-hall",
    "mill-squat": "mill-3", "brass-rail": "brass-rail", "yard-office": "yard-office",
    "riverside-homes-block": "riverside-homes", "floodwall-shed": "floodwall-shed", "ebenezer-hall": "ebenezer",
    "bluff-rd-bungalow": "bluff-rd-bungalow", "st-brendan-hall": "st-brendan", "holy-cross-funeral": "holy-cross",
    "kilbride-corner-store": "kilbride-corner-store", "warehouse-row-7": "warehouse-row-7",
    "hale-records": "hale-records", "container-stack": "container-stack", "grain-elevator-hostage": "grain-elevator",
    "wharf-st-flat": "wharf-st-flat", "heights-villa": "heights-villa", "harlan-park-concert": "harlan-park",
    "ch6-occupation": "ch6", "harlan-ave-bungalow": "harlan-ave-bungalow",
}
# site-type constraints (validated again by validate_city.py)
SITE_RULES = {
    "WS": dict(status=(0,), cls="bldg"),
    "HT": dict(status=(0,), cls="bldg"),
    "GH": dict(status=(0, 1), cls="bldg"),
    "BS": dict(status=(0, 1), cls=None),
    "PE": dict(status=(0,), cls=None, kinds={"civic", "faith", "plaza", "park", "cemetery", "school", "political"}),
}


def r1(a, nd=1):
    return [round(float(v), nd) for v in a]


def door_of(B, j):
    s = B["side"][j]
    a = B["ang"][j]
    d = B["d"][j]
    return (B["cx"][j] + math.sin(a) * s * d / 2, B["cy"][j] - math.cos(a) * s * d / 2)


def addr_text(B, streets, j):
    return A.fmt_address(int(B["num"][j]), str(B["pre"][j]), streets[B["street"][j]]["name"])


def export(S, R, B, r, path, report=None, meta_extra=None):
    n = len(B["cx"])
    sp = r["specials"]
    # ---- building index by landmark id
    lm_bi = {}
    for j in np.where(B["is_special"])[0]:
        lm_bi[sp[B["special_idx"][j]]["spec"]["id"]] = int(j)
    # ---- generic site picks
    generic = B["generic"]
    # ---- types
    type_names = list(TYPES) + sorted({x for x in B["type"] if x not in TYPES})
    tix = {t: i for i, t in enumerate(type_names)}
    lm_of_b = np.full(n, -1)
    # ---- landmarks list
    landmarks = []
    for spc in LM.L:
        j = lm_bi[spc["id"]]
        dx, dy = door_of(B, j)
        dx, dy = round(dx, 3), round(dy, 3)
        lat, lon = G.enu_to_geo(dx, dy)
        lm_of_b[j] = len(landmarks)
        landmarks.append(dict(id=spc["id"], name=spc["name"], kind=spc["kind"], cls=spc["cls"], ward=WARD_ORDER[B["ward"][j]],
                              bi=j, address=addr_text(B, S, j), street=int(B["street"][j]), num=int(B["num"][j]),
                              pre=str(B["pre"][j]), x=dx, y=dy, lat=round(lat, 9), lon=round(lon, 9),
                              status=int(B["status"][j]), note=spc["note"], yr=int(B["yr"][j]), sub=spc.get("sub"),
                              h=spc.get("h"), bank="N" if G.bank_is_north(dx, dy) else "S"))
    landmarks.append(dict(id="carrick-bridge", name="Carrick Bridge (datum)", kind="bridge", cls="structure", ward="oldtown",
                          bi=-1, address="0 Carrick Bridge", street=[s["id"] for s in S if s["cls"] == "B"][0], num=0, pre="N",
                          x=0.0, y=0.0, lat=0.0, lon=0.0, status=0, note="origin of the local lat/lon frame", yr=1958, sub=None, h=None, bank="N"))
    # ---- sites
    src = json.load(open(SITE_SRC))["sites"]
    sites = []
    for s0 in src:
        sid_ = s0["id"]
        rec = dict(id=sid_, name=s0["name"], ward=s0["ward"], type=s0["type"], archetype=s0["archetype"],
                   visibility=s0["visibility"], notes=s0["notes"])
        if sid_ in SITE_TO_LM:
            lmr = next(l for l in landmarks if l["id"] == SITE_TO_LM[sid_])
            rec.update(bi=lmr["bi"], landmark=lmr["id"])
        elif sid_ in generic:
            j = generic[sid_]
            rec.update(bi=int(j), landmark=None)
        elif sid_ == "veterans-bridge-march":
            bs = next(s for s in S if s["name"] == "Bridge Street" and s["pts"][0][1] >= 1300)
            ad = A.Geocoder(S).address_at(bs["id"], 40.0, 1340.0)
            lat, lon = G.enu_to_geo(0.0, 1340.0)
            rec.update(bi=-1, landmark=None, street=bs["id"], num=ad["n"], pre=ad["prefix"], x=0.0, y=1340.0)
        else:
            raise RuntimeError("unhandled site " + sid_)
        if rec["bi"] >= 0:
            j = rec["bi"]
            dx, dy = door_of(B, j)
            rec.update(street=int(B["street"][j]), num=int(B["num"][j]), pre=str(B["pre"][j]), x=round(dx, 3), y=round(dy, 3))
            rec["ward"] = WARD_ORDER[B["ward"][j]]       # the map is authoritative for ward
            if sid_ in generic:
                lm_name = rec["name"]
        rec["address"] = A.fmt_address(rec["num"], rec["pre"], S[rec["street"]]["name"])
        rec["lat"], rec["lon"] = [round(v, 9) for v in G.enu_to_geo(rec["x"], rec["y"])]
        sites.append(rec)
    # ---- address matrix
    mat = collections.defaultdict(lambda: [0, 0, []])
    for j in range(n):
        a = B["qx"][j] if S[B["street"][j]]["axis"] == "EW" else B["qy"][j]
        blk = int(math.floor(abs(a) / 100.0) * 100)
        e = mat[(int(B["street"][j]), str(B["pre"][j]), blk)]
        e[0 if B["even"][j] else 1] += 1
        if lm_of_b[j] >= 0:
            e[2].append(landmarks[lm_of_b[j]]["id"])
    matrix = [[k[0], k[1], k[2], v[0], v[1], ";".join(v[2])] for k, v in sorted(mat.items())]
    # ---- contours
    step = 40.0
    xs = np.arange(G.X0, G.X1 + 1, step); ys = np.arange(G.Y0, G.Y1 + 1, step)
    gx, gy = np.meshgrid(xs, ys)
    Z = G.terrain(gx, gy)
    contours = []
    for lev in range(220, 321, 10):
        for c in measure.find_contours(Z, lev):
            if len(c) < 6:
                continue
            pts = [(G.X0 + p[1] * step, G.Y0 + p[0] * step) for p in c]
            ls = LineString(pts).simplify(5.0)
            contours.append(dict(z=lev, idx=(lev % 50 == 0), pts=[[round(x, 1), round(y, 1)] for x, y in ls.coords]))
    # ---- geometry export
    def ring(p):
        return [[round(x, 1), round(y, 1)] for x, y in p.exterior.coords]

    def polys_of(g):
        return [ring(p) for p in (g.geoms if hasattr(g, "geoms") else [g])]

    streets_out = [dict(id=s["id"], name=s["name"], cls=s["cls"], kind=s["kind"], axis=s["axis"], ward=s["ward"],
                        w=s["width"], yard=s["yard"], era=int(s["era"]), fill=bool(s.get("fill", False)),
                        pts=[[round(x, 3), round(y, 3)] for x, y in s["pts"]]) for s in S]
    bridge = dict(deck=[[0.0, -1300.0], [0.0, 1300.0]], half_w=G.BRIDGE_HALF_W, above_water=G.DECK_ABOVE_WATER,
                  tower_top_above_deck=G.TOWER_HEIGHT_ABOVE_DECK, level_to=G.LEVEL_TO, foot=1300.0,
                  towers=[dict(x=sx * G.TOWER_X, y=sy * G.TOWER_Y, w=G.TOWER_LEG[0], d=G.TOWER_LEG[1])
                          for sx in (-1, 1) for sy in (-1, 1)])
    basins = {}
    for q, spec in G.BASINS.items():
        basins[spec["name"]] = dict(quad=q, rect=list(G.BASIN_RECTS[q].bounds), piers=[list(p.bounds) for p in G.PIERS[q]],
                                    year=spec["year"], note=spec["note"], wall=G.basin_wall(q))
    water = dict(river=polys_of(G.RIVER), basins=basins, fill=dict(rect=list(G.FILL_NW.bounds), year=G.FILL_YEAR, name="Fish Flats"))
    wards = {w: polys_of(G.WARDS[w]) for w in WARD_ORDER}
    # ---------------------------------------------------------------- crossings, flood, utilities, services, history
    crossings = []
    for c in G.CROSSINGS:
        d = dict(c)
        x = c["x"]
        d.update(y0=round(float(G.bank_s(x)), 2), y1=round(float(G.bank_n(x)), 2), river_width=round(float(G.width(x)), 1),
                 lat=round(G.enu_to_geo(x, float(G.yc(x)))[0], 9), lon=round(G.enu_to_geo(x, float(G.yc(x)))[1], 9))
        crossings.append(d)
    wall = dict(year=G.WALL_YEAR, crest=G.WALL_CREST, x=list(G.WALL_X), off=G.WALL_OFF, flood_year=G.FLOOD_YEAR,
                segments=[dict(bank=s_["bank"], pts=[[round(x, 2), round(y, 2)] for x, y in s_["pts"]]) for s_ in G.wall_segments()],
                gates=[dict(g, x=round((g["x0"] + g["x1"]) / 2, 2),
                            y=round(float(G.bank_n((g["x0"] + g["x1"]) / 2)) + G.WALL_OFF if g["bank"] == "N" else float(G.bank_s((g["x0"] + g["x1"]) / 2)) - G.WALL_OFF, 2))
                       for g in G.WALL_GATES])
    step_f = 25.0
    fxs = np.arange(G.X0, G.X1 + 1, step_f); fys = np.arange(G.Y0, G.Y1 + 1, step_f)
    fgx, fgy = np.meshgrid(fxs, fys)
    fz = G.terrain(fgx, fgy)
    fw = G.in_water_np(fgx, fgy)
    rows = []
    for j in range(len(fys)):
        rows.append("".join("w" if fw[j, i] else str(int(min(9, max(0, round(G.FLOOD_LINE - fz[j, i]))))) for i in range(len(fxs))))
    flood = dict(step=step_f, x0=G.X0, y0=G.Y0, nx=len(fxs), ny=len(fys), line=G.FLOOD_LINE, rows=rows)

    spec_by_id = {sp_["id"]: sp_ for sp_ in LM.L}
    def lmrec(lid):
        return next(l for l in landmarks if l["id"] == lid)
    facilities = []
    for lid, zone in (("carrick-reservoir", "NL"), ("highland-standpipe", "NH"), ("kilbride-reservoir", "SL"), ("bluff-standpipe", "SH")):
        j = lm_bi[lid]; z = float(B["z"][j]); h = float(spec_by_id[lid]["h"])
        facilities.append(dict(id=lid, zone=zone, bi=int(j), x=float(B["cx"][j]), y=float(B["cy"][j]), ground=round(z, 1), h=h, twl=round(z + h, 1)))
    outfalls = []
    k_ = 0
    for bank in "NS":
        for x in list(range(-2400, 2401, 600)):
            if any(abs(x - g_x) < 100 for g_x in (G.FERRY_X, G.RAIL_X)):
                continue
            yb = float(G.bank_n(x)) if bank == "N" else float(G.bank_s(x))
            if any(g["x0"] - 30 <= x <= g["x1"] + 30 and g["bank"] == bank and g["kind"] == "basin" for g in G.WALL_GATES):
                continue
            k_ += 1
            outfalls.append(dict(id=f"cso-{bank}{k_}", bank=bank, x=float(x), y=round(yb, 2), kind="cso"))
    for q, spec in G.BASINS.items():
        xm = (spec["x"][0] + spec["x"][1]) / 2
        k_ += 1
        outfalls.append(dict(id=f"cso-{q}{k_}", bank=spec["bank"], x=float(xm), y=round(float(G.bank_n(xm)) if spec["bank"] == "N" else float(G.bank_s(xm)), 2), kind="cso"))
    interceptors = []
    for bank, plant in (("N", "wwtp-north"), ("S", "wwtp-south")):
        px = lmrec(plant)["x"]
        f = (lambda x: float(G.quay_n(x))) if bank == "N" else (lambda x: float(G.quay_s(x)))
        interceptors.append(dict(bank=bank, to=plant, flow="east", pts=[[float(x), round(f(x), 2)] for x in np.arange(-3600.0, min(px, 3600.0) + 1, 100.0)]))
    laterals = []
    for s_ in S:
        if s_["axis"] != "NS" or s_["cls"] not in ("A", "C") or s_["kind"] not in ("lattice", "arterial", "pike"):
            continue
        ln_ = LineString(s_["pts"])
        if ln_.length < 500:
            continue
        p0, p1 = s_["pts"][0], s_["pts"][-1]
        north = G.bank_is_north((p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2)
        up, dn = (p1, p0) if north else (p0, p1)          # north bank drains south, south bank drains north
        zu, zd = float(G.terrain(up[0], up[1])), float(G.terrain(dn[0], dn[1]))
        laterals.append(dict(st=s_["id"], bank="N" if north else "S", up=list(up), down=list(dn), z_up=round(zu, 1), z_down=round(zd, 1),
                             fall=round((zu - zd) / ln_.length, 5), len=round(ln_.length, 1)))
    utilities = dict(zone_split=G.ZONE_SPLIT, head_min=G.HEAD_MIN, head_max=G.HEAD_MAX, sewer_min_fall=G.SEWER_MIN_FALL,
                     facilities=facilities, intake=lmrec("waterworks")["id"], plants=["wwtp-north", "wwtp-south"],
                     pumps=[l["id"] for l in landmarks if l.get("sub") == "pump"], outfalls=outfalls, interceptors=interceptors,
                     laterals=laterals)
    # ---- emergency response over the network (all crossings open / viaduct closed / both crossings closed)
    net = NET.Network(S)
    dx_ = np.array([door_of(B, j)[0] for j in range(n)]); dy_ = np.array([door_of(B, j)[1] for j in range(n)])
    doors = np.c_[dx_, dy_]
    st_fire = [(l["x"], l["y"]) for l in landmarks if l["kind"] == "fire"]
    tf_open = net.times(st_fire, doors, close=())
    tf_via = net.times(st_fire, doors, close=("carrick-bridge",))
    tf_both = net.times(st_fire, doors, close=("carrick-bridge", "ferry-st-bridge"))
    services = dict(fire_limit=G.FIRE_LIMIT_S, speed=G.SPEED,
                    stations={k_: [l["id"] for l in landmarks if l["kind"] == k_] for k_ in ("fire", "police", "health")})
    # ---- history: events and the population curve (built from each building's year and its decline year)
    events = [
        (1794, "Carrick's Ferry and the landing: Ferry Street, the Landing Tavern (1796)", "founding"),
        (1802, "Turnpike Avenue cut toward the north-west", "road"),
        (1838, "Packet Basin dug in the east bay, where the river is 700 m wide and slow; Dock Road leads to it; the Old Town grid grows east of the landing", "harbour"),
        (1858, "Highland Avenue turnpike; Riverside platted", "road"),
        (1861, "Swing bridge replaces the ferry; South Line reaches the south bank (rail car float)", "crossing"),
        (1866, "Ironworks mills and the company grid", "industry"),
        (1871, "Fish Basin dug in the west bay", "harbour"),
        (1889, "Coal Basin dug in the west bay, beside the Ironworks; Coal Spur", "harbour"),
        (1893, "Rail Lift Bridge and the North Line; Packet Spur follows in 1894", "crossing"),
        (1912, "Grain Basin dug in the east bay", "harbour"),
        (1927, "Ferry Street swing bridge rebuilt as a lift", "crossing"),
        (G.FLOOD_YEAR, "The great flood: the river reaches 222 m", "flood"),
        (G.WALL_YEAR, "Floodwall and pump stations built (protects x = -3,000..+3,000 m, all four basins); the far ends of the bays are left to the river", "flood"),
        (1946, "Northgate built out on the platted heights", "growth"),
        (1958, "Carrick Bridge opens: a high-level viaduct carrying traffic past the lift bridges, which stop for every ship bound for the west bay", "crossing"),
        (G.YEAR_PEAK, "Population peaks at 150,000", "peak"),
        (G.FILL_YEAR, "The outer end of Fish Basin silted and filled: the Fish Flats", "harbour"),
        (G.YEAR_NOW, "Today: 100,000 residents", "now"),
    ]
    yrs = sorted(set(range(G.YEAR_FOUNDED, G.YEAR_NOW + 1, 4)) | {e[0] for e in events} | {G.YEAR_PEAK, G.YEAR_NOW})
    pk = np.array(B["peak"]); nw = np.array(B["now"]); by = np.array(B["yr"]); ab = np.array(B["abn"])
    curve = []
    for Y in yrs:
        if Y <= G.YEAR_PEAK:
            curve.append([Y, int(pk[by <= Y].sum())])
        else:
            curve.append([Y, int(np.where(ab <= Y, nw, pk)[by <= Y].sum())])
    history = dict(events=[dict(year=y_, text=t_, kind=k2) for y_, t_, k2 in events], pop=curve, year_peak=G.YEAR_PEAK, year_now=G.YEAR_NOW,
                   year_founded=G.YEAR_FOUNDED, landing=list(G.LANDING))
    bld = dict(
        n=n, x=r1(B["cx"]), y=r1(B["cy"]), w=r1(B["w"]), d=r1(B["d"]), a=[round(float(v), 4) for v in B["ang"]],
        t=[tix[t] for t in B["type"]], lv=[int(max([t[1] for t in tt]) if tt else 0) for tt in B["tiers"]],
        tiers=[[v for t in tt for v in (round(t[0], 1), int(t[1]))] for tt in B["tiers"]],
        st=[int(v) for v in B["street"]], side=[int(v) for v in B["side"]], num=[int(v) for v in B["num"]],
        pre=["NSEW".index(str(v)) for v in B["pre"]], ward=[int(v) for v in B["ward"]],
        status=[int(v) for v in B["status"]], peak=[int(v) for v in B["peak"]], now=[int(v) for v in B["now"]],
        units=[int(v) for v in B["units"]], z=[float(v) for v in B["z"]], lm=[int(v) for v in lm_of_b],
        qa=[round(float(v), 3) for v in B["qa"]],
        yr=[int(v) for v in B["yr"]], abn=[int(v) for v in B["abn"]], fl=[int(v) for v in B["fl"]],
        tf=[int(v) for v in tf_open], tv=[int(v) for v in tf_via], tc=[int(v) for v in tf_both],
    )
    doc = dict(
        meta=dict(name="Port Carrick, PA", version="0.4", frame=dict(
            origin="Carrick Bridge centre span", m_per_deg_lat=G.M_PER_DEG_LAT, m_per_deg_lon=G.M_PER_DEG_LON,
            lat_nominal=G.LAT_NOMINAL, extent=[G.X0, G.Y0, G.X1, G.Y1]),
            population=dict(now=TARGET_NOW, peak=TARGET_PEAK), level_m=LEVEL_M, batter_m=BATTER_M,
            flood_line=G.FLOOD_LINE, river_surface=215.0, lv_cap=LV_CAP, year_peak=G.YEAR_PEAK, year_now=G.YEAR_NOW,
            ghosts=[dict(name=g[0], ward=g[1], x=g[2], y=g[3], r=g[4]) for g in B.get("ghosts", [])],
            wards=WARD_ORDER, types=type_names, **(meta_extra or {})),
        wards=wards, water=water, limit=ring(P.LIMIT), streets=streets_out,
        rail=[dict(name=x["name"], kind=x["kind"], era=int(x["era"]), pts=[[round(a, 2), round(b, 2)] for a, b in x["pts"]]) for x in R],
        bridge=bridge, crossings=crossings, wall=wall, flood=flood, utilities=utilities, services=services, history=history,
        buildings=bld, landmarks=landmarks, sites=sites, matrix=matrix, contours=contours,
        validation=report or {})
    with open(path, "w") as f:
        json.dump(doc, f, separators=(",", ":"))
    return doc
