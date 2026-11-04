"""pc_streets.py - programmatic road system for Port Carrick.

Everything is derived from pc_geo (river, basins, wards, bridge). No hand-placed road
coordinates exist; the only inputs are per-ward lattice parameters.
"""
import math
import numpy as np
import shapely
from shapely import affinity
from shapely.geometry import LineString, Point, Polygon, box, MultiLineString
from shapely.ops import unary_union
import pc_geo as G

STEP = 25.0
X0, X1, Y0, Y1 = G.X0, G.X1, G.Y0, G.Y1

LIMIT = affinity.scale(Point(0, 0).buffer(1.0, 96), 3850.0, 2300.0).intersection(G._EXT)
ZONES = shapely.union_all(list(G.HARBOUR_ZONE.values()))
DECK_CORRIDOR = box(-45, -1300, 45, 1300)
_UL = {1: G.under_limit(1), -1: G.under_limit(-1)}
DECK_NOPASS = shapely.union_all([box(-45, _UL[1], 45, 1300), box(-45, -1300, 45, -_UL[-1])])   # no headroom: streets stop

PN = G._poly_between(G.quay_n, G.N1)
PS = G._poly_between(lambda x: Y0, G.quay_s)
NG = G._poly_between(G.N1, lambda x: Y1)

WIDTH = {"A": 24.0, "C": 16.0, "L": 10.0, "Q": 18.0, "S": 12.0, "B": 62.0, "M": 16.0}
YARD = {"A": 3.0, "C": 3.0, "L": 3.0, "Q": 3.0, "S": 2.0, "B": 0.0, "M": 0.0}

STEMS = """Market Front Court Chapel Canal Mill Church Pearl Union Washington Jefferson Adams Monroe Madison Franklin
Hamilton Liberty Commerce Exchange Lantern Cooper Tanner Salt Brewer Printer Chandler Cutler Draper Fulton Hanover Orange
Lime Cherry Walnut Chestnut Spruce Locust Poplar Sycamore Hemlock Cedar Birch Maple Elm Linden Alder Willow Beech Hickory
Larch Juniper Aspen Magnolia Sumac Laurel Holly Ivy Rowan Hazel Quince Plum Pear Apple Peach Mulberry Dogwood Tamarack
Kosciuszko Pulaski Dvorak Novak Kowalski Nowak Sokol Petrov Volkov Ivanov Brodsky Zelenka Hruska Kovac Horvat Babic
Murphy Kelly Sullivan Doyle Brennan Gallagher Flanagan Keane Quinn Rooney Callahan Donovan Mahoney Riordan Tierney Walsh
Rossi Bianchi Romano Ricci Greco Marino Gallo Conti Esposito Bruno Moretti Ferrara DeLuca Santoro Caruso Lombardi
Schultz Kessler Brandt Hoffman Weiss Krause Vogel Baumann Reinhardt Albrecht Zimmer Hartmann Lindner Steiner Koenig
Hughes Evans Powell Pryce Rhys Morgan Griffith Llewellyn Owen Bevan Cadwal Vaughan Tudor
Okafor Baptiste Freeman Douglass Tubman Truth Garvey Bethune Carver Johnson Whitfield Lyle Pruitt Greer Banks Thornton
Carnegie Frick Mellon Westinghouse Heinz Bessemer Kelvin Watt Stephenson Fairbanks Siemens Otis Armstrong Corliss Jessop
Anvil Forge Bellows Crucible Ingot Slag Coke Furnace Rivet Girder Flange Billet Puddler Roller Smelter Tuyere Sinter
Ferry Packet Drover Teamster Stevedore Wharfinger Lighterman Cooperage Rigger Caulker Dredge Mooring Bollard Hawser Capstan
Harlan Kettering Pell Okonjo Hale Brannigan Delacroix Fenwick Garrity Halloran Ironside Jarrett Kincaid Lockhart Maddox
Sterling Prescott Ashford Beaumont Carlisle Devereux Eastwick Fairchild Grafton Hollis Irving Kensington Langley Montrose
Northcote Oakley Pemberton Quimby Radcliffe Sutton Thackeray Underhill Vandermeer Winslow Yarrow Zeller
Allegheny Monongahela Youghiogheny Conemaugh Juniata Susquehanna Lehigh Schuylkill Tioga Mahoning Shenango Kiskiminetas
Bethlehem Altoona Johnstown Latrobe Erie Reading Scranton Hazleton Pottsville Lancaster Carlisle2 Greensburg Uniontown
Brownsville Monessen Aliquippa Ambridge Beaver Butler Kittanning Indiana Punxsutawney Ridgway Warren Titusville Meadville
Saint-Brendan Saint-Anne Saint-Casimir Saint-Stanislaus Saint-Clair Saint-Jude Saint-Cyril Saint-Michael Holy-Cross Calvary
Prospect Summit Vista Overlook Highview Ridgeline Bluff Crest Heights Hillcrest Skyline Panorama Belvedere Eyrie Aerie
Orchard Meadow Fairview Greenfield Brookside Glenwood Lakeview Parkside Woodland Pinecrest Stonegate Westmont Eastmont
Foundry Pattern Tannery Brickyard Lumber Cinder Ash Soot Ember Clinker Scrap Salvage Junction Siding Spur Roundhouse
Depot Switchyard Cabbage Onion Dairy Cattle Orchard2 Hopyard Maltster Granary Silo Hayloft Plowshare Harrow Sickle""".split()
STEMS = [s.replace("-", " ").replace("2", "") for s in STEMS]
_seen = set(); _u = []
for s in STEMS:
    if s not in _seen:
        _seen.add(s); _u.append(s)
STEMS = _u


class Names:
    def __init__(self, seed=7):
        rng = np.random.default_rng(seed)
        self.pool = list(STEMS)
        rng.shuffle(self.pool)
        self.i = 0
        self.used = set()
        self.rng = rng

    def take(self, axis, cls):
        while True:
            s = self.pool[self.i % len(self.pool)]
            self.i += 1
            if self.i > len(self.pool):
                s = s + " " + ["North", "South", "Upper", "Lower", "Old", "New"][self.i % 6]
            suf = {"A": ["Avenue", "Road"], "C": ["Avenue", "Boulevard"], "L": ["Street", "Street", "Place"]}[cls]
            name = f"{s} {suf[self.i % len(suf)]}"
            if name not in self.used:
                self.used.add(name)
                return name

    def reserve(self, name):
        assert name not in self.used, name
        self.used.add(name)


def _axis_of(pts):
    p = np.asarray(pts)
    return "EW" if abs(p[-1, 0] - p[0, 0]) >= abs(p[-1, 1] - p[0, 1]) else "NS"


def _orient(pts, axis):
    k = 0 if axis == "EW" else 1
    if pts[0][k] > pts[-1][k]:
        pts = pts[::-1]
    return pts


def _pieces(geom):
    if geom.is_empty:
        return []
    if geom.geom_type == "LineString":
        return [geom]
    out = []
    for g in getattr(geom, "geoms", []):
        out += _pieces(g)
    return out


def _ensure_vertex(pts, axis_k, val):
    """insert an exact vertex at axis coordinate `val` if missing (pts monotone in axis k)"""
    for i in range(len(pts) - 1):
        a, b = pts[i][axis_k], pts[i + 1][axis_k]
        if abs(a - val) < 1e-9 or abs(b - val) < 1e-9:
            return pts
        if min(a, b) < val < max(a, b):
            t = (val - a) / (b - a)
            p = (pts[i][0] + t * (pts[i + 1][0] - pts[i][0]), pts[i][1] + t * (pts[i + 1][1] - pts[i][1]))
            return pts[:i + 1] + [p] + pts[i + 1:]
    return pts


# ---------------------------------------------------------------------------- history of the street pattern
BRIDGE_CLASSES = ("B", "M")        # decks: not part of the carriageway lot system


def era_of(s):
    """Year the street was laid out. Explicit eras (basins, arterials, crossings) are set at creation; lattice
    streets take the year their district was platted, which grows outward from the 1794 landing."""
    if s.get("era"):
        return s["era"]
    m = LineString(s["pts"]).interpolate(0.5, normalized=True)
    x, y = m.x, m.y
    if G.FILL_NW.contains(m) or G.FILL_NW.buffer(1).contains(m):
        return G.FILL_YEAR
    w, kind = s["ward"], s["kind"]
    if kind == "quay":
        return 1861 if abs(x) < 1500 else 1895
    if w == "oldtown":
        if x < -120.0 and y < float(G.quay_n(x)) + 650.0:
            return 1794
        if y < float(G.quay_n(x)) + 900.0:
            return 1838
        return 1851
    if w == "riverside":
        return 1858 if x > -1650.0 else 1879
    if w == "ironworks":
        return 1866 if x > -1500.0 else 1887
    if w == "eastport":
        if y > float(G.yc(x)):
            return 1884 if x < 1500.0 else 1903
        return 1893
    if w == "kilbride":
        return 1904 if x < 1000.0 else 1921
    if w == "northgate":
        return 1936
    return 1900


def _warp(pts, amp, lam, ph):
    if not amp:
        return pts
    return [(x + amp * math.sin(y / lam + ph), y + amp * math.sin(x / (lam * 1.3) + 1.7 * ph)) for x, y in pts]


DIAGONALS = [   # radial roads that grew out of the original crossings: (name, start on an existing street, bearing deg, length, era)
    dict(name="Turnpike Avenue", start=(G.FERRY_X, 560.0), bearing=150.0, length=1900.0, reg="N", era=1802),
    dict(name="Eastport Pike", start=(G.DOCK_X, 520.0), bearing=35.0, length=1800.0, reg="N", era=1869),
    dict(name="Mill Road", start=(G.FERRY_X, -700.0), bearing=225.0, length=2200.0, reg="S", era=1866),
    dict(name="Kilbride Pike", start=(0.0, -700.0), bearing=-35.0, length=2200.0, reg="S", era=1904),
]


def build_streets(seed=1995):
    rng = np.random.default_rng(seed)
    names = Names()
    streets = []

    def add(pts, cls, kind, name, ward=None, group=None, axis=None, era=None, **extra):
        pts = [(round(float(x), 3), round(float(y), 3)) for x, y in pts]
        axis = axis or _axis_of(pts)
        pts = _orient(pts, axis)
        d = dict(id=len(streets), name=name, cls=cls, kind=kind, axis=axis, pts=pts,
                 width=WIDTH[cls], yard=YARD[cls], group=group or name, era=era)
        d.update(extra)
        streets.append(d)
        return d

    water = G.WATER
    base_clip = LIMIT.difference(water).difference(ZONES)

    def emit(line_pts, region, cls, kind, name, minlen=40.0, ward=None, era=None):
        ln = LineString(line_pts).intersection(region.intersection(base_clip))
        for p in _pieces(ln):
            if p.length >= minlen:
                add(list(p.coords), cls, kind, name, ward=ward, era=era)

    # ---------------------------------------------------------------- arterials
    for nm in ["Bridge Street", "Highland Avenue", "Ferry Street", "Dock Road", "Port Road",
               "North Quay", "South Quay", "Carrick Bridge", "Ferry Street Lift Bridge",
               "Turnpike Avenue", "Eastport Pike", "Mill Road", "Kilbride Pike"]:
        names.reserve(nm)
    xs = list(G.XS)
    emit([(x, float(G.quay_n(x))) for x in xs], G._EXT, "Q", "quay", "North Quay")
    emit([(x, float(G.quay_s(x))) for x in xs], G._EXT, "Q", "quay", "South Quay")
    emit([(x, float(G.N1(x))) for x in xs], G._EXT, "A", "arterial", "Highland Avenue", era=1858)
    # Bridge Street: at grade beneath the viaduct while there is headroom, then again from the touch-down
    # node outward. One street, disjoint pieces on each side, vertex forced at y = +-1300.
    for sgn in (1, -1):
        y_start = float(G.quay_n(0)) if sgn > 0 else float(G.quay_s(0))
        ys = list(np.arange(abs(y_start), _UL[sgn] + 1e-9, STEP)) + [_UL[sgn]]
        add([(0.0, sgn * y) for y in sorted(set(ys))], "A", "arterial", "Bridge Street", era=1838 if sgn > 0 else 1866)
        ys = list(np.arange(1300.0, 2300.0 + 1, STEP))
        add([(0.0, sgn * y) for y in ys], "A", "arterial", "Bridge Street", era=G.CROSSINGS[-1]["year"])
    # Ferry Street runs from the old landing north to Highland Avenue and, since 1861, south from the south landing
    x = G.FERRY_X
    ya, yb = float(G.quay_n(x)), float(G.N1(x))
    add([(x, y) for y in np.linspace(ya, yb, int((yb - ya) // STEP) + 2)], "A", "arterial", "Ferry Street", era=1794)
    emit([(x, y) for y in np.arange(float(G.quay_s(x)), -2250.0, -STEP)], G._EXT, "A", "arterial", "Ferry Street", era=1861)
    # Dock Road and Port Road
    x = G.DOCK_X
    ya, yb = float(G.quay_n(x)), float(G.N1(x))
    add([(x, y) for y in np.linspace(ya, yb, int((yb - ya) // STEP) + 2)], "A", "arterial", "Dock Road", era=1838)
    ya, yb = float(G.quay_s(G.PORT_X)), -2200.0
    emit([(G.PORT_X, y) for y in np.arange(ya, yb, -STEP)], G._EXT, "A", "arterial", "Port Road", era=1884)

    # the viaduct itself (grade separated, class B) and the lift bridge deck (class M, joins the quays at grade)
    add([(0.0, y) for y in np.arange(-1300.0, 1300.1, 100.0)], "B", "deck", "Carrick Bridge", era=G.CROSSINGS[-1]["year"])
    x = G.FERRY_X
    add([(x, float(G.quay_s(x))), (x, float(G.bank_s(x))), (x, float(G.bank_n(x))), (x, float(G.quay_n(x)))],
        "M", "lift", "Ferry Street Lift Bridge", era=1861)

    # ---------------------------------------------------------------- harbour (four unequal basins in the wide reaches)
    for q, spec in G.BASINS.items():
        bn = spec["name"].replace(" Basin", "")
        xa, xb = spec["x"]
        yr = spec["year"]
        wall = G.basin_wall(q)
        quay = G.quay_n if spec["bank"] == "N" else G.quay_s
        xlo, xhi = xa - G.RING_PAD, xb + G.RING_PAD
        for leg, nm in ((xlo if xlo * xb > 0 and abs(xlo) < abs(xhi) else xhi, f"{bn} Causeway"), (xhi if abs(xlo) < abs(xhi) else xlo, f"{bn} Wharf")):
            y0 = float(quay(leg))
            pts = [(leg, y) for y in np.linspace(y0, wall, int(abs(wall - y0) // STEP) + 2)]
            names.reserve(nm)
            outer_filled = (q == "NW" and abs(leg - xlo) < 1e-6)      # the Fish Basin's outer causeway was laid after the 1971 fill
            add(pts, "Q", "ring", nm, era=G.FILL_YEAR if outer_filled else yr, fill=outer_filled)
        names.reserve(f"{bn} Basin Road")
        add([(x, wall) for x in np.linspace(xlo, xhi, int((xhi - xlo) // STEP) + 2)], "Q", "ring", f"{bn} Basin Road", era=yr)
        for i, p in enumerate(G.PIERS[q]):
            bx0, by0, bx1, by1 = p.bounds
            xx = (bx0 + bx1) / 2
            if spec["bank"] == "N":
                y_tip, y_w = by0 + 8, wall
            else:
                y_tip, y_w = by1 - 8, wall
            nm = f"{bn} Pier {i + 1}"
            names.reserve(nm)
            add([(xx, y) for y in np.linspace(y_tip, y_w, int(abs(y_w - y_tip) // STEP) + 2)], "S", "pier", nm, era=yr)
    # the quay road across the 1971 fill (the fill itself is cut out of the lattice and the old quay)
    fx0, fy0, fx1, fy1 = G.FILL_NW.bounds
    add([(x, float(G.quay_n(x))) for x in np.linspace(fx0, fx1, 6)], "Q", "quay", "North Quay", era=G.FILL_YEAR, fill=True)

    # ---------------------------------------------------------------- lattices (one per district, by era)
    def strip(a, b):
        return box(a, Y0, b, Y1)

    SEAM_X = -120.0       # seam between the 1794 landing town and the 1838 Packet Basin district
    LAT = [
        dict(ward="oldtown", reg=PN, xr=(-650.0, SEAM_X), mode="north", K=15, jit=0.22, sN=66.0, jitN=0.26, tilt=-0.05, yref=300.0,
             warp=(15.0, 120.0, 1.1), skip=0.12),
        dict(ward="oldtown", reg=PN, xr=(SEAM_X, 700.0), mode="north", K=11, jit=0.04, sN=84.0, jitN=0.05, tilt=0.0, yref=0.0,
             warp=(5.0, 300.0, 0.3), skip=0.0),
        dict(ward="riverside", reg=PN, xr=(X0, -650.0), mode="north", K=9, jit=0.10, sN=100.0, jitN=0.08, tilt=0.10, yref=500.0,
             warp=(10.0, 260.0, 2.0), skip=0.0),
        dict(ward="eastport", reg=PN, xr=(700.0, X1), mode="north", K=9, jit=0.06, sN=118.0, jitN=0.06, tilt=-0.06, yref=500.0,
             warp=(8.0, 320.0, 0.7), skip=0.0),
        dict(ward="northgate", reg=NG, xr=(X0, X1), mode="gate", sE=150.0, sN=135.0, jitN=0.10, tilt=-0.09, yref=1800.0,
             warp=(34.0, 380.0, 2.7), skip=0.0),
        dict(ward="ironworks", reg=PS, xr=(X0, 0.0), mode="south", sE=160.0, sN=190.0, jitN=0.0, tilt=0.0, yref=-800.0,
             warp=(4.0, 500.0, 0.2), skip=0.0),
        dict(ward="kilbride", reg=PS, xr=(0.0, G.PORT_X), mode="south", sE=108.0, sN=96.0, jitN=0.05, tilt=0.07, yref=-800.0,
             warp=(6.0, 260.0, 1.4), skip=0.0),
        dict(ward="eastport", reg=PS, xr=(G.PORT_X, X1), mode="south", sE=135.0, sN=125.0, jitN=0.05, tilt=0.0, yref=-800.0,
             warp=(7.0, 300.0, 0.9), skip=0.0),
    ]
    for sp in LAT:
        a, b = sp["xr"]
        region = sp["reg"].intersection(strip(a, b)).difference(DECK_NOPASS)
        region_ns = region.difference(DECK_CORRIDOR)
        ward = sp["ward"]
        amp, lam, ph = sp["warp"]
        lines = []
        if sp["mode"] == "north":
            K = sp["K"]
            prev_skip = False
            for k in range(1, K):
                if sp["skip"] and not prev_skip and rng.random() < sp["skip"]:
                    prev_skip = True
                    continue
                prev_skip = False
                t = (k + rng.uniform(-sp["jit"], sp["jit"])) / K
                lines.append([(x, float(G.quay_n(x) + (G.N1(x) - G.quay_n(x)) * t)) for x in xs if a - 1 <= x <= b + 1])
        elif sp["mode"] == "south":
            k = 1
            while True:
                off = k * sp["sE"]
                if float(G.quay_s(0)) - off < -2300:
                    break
                lines.append([(x, float(G.quay_s(x) - off)) for x in xs if a - 1 <= x <= b + 1])
                k += 1
        else:
            k = 1
            while float(G.N1(0)) + k * sp["sE"] < 2300 + 200:
                lines.append([(x, float(G.N1(x) + k * sp["sE"])) for x in xs if a - 1 <= x <= b + 1])
                k += 1
        for i, pts in enumerate(lines):
            cls = "C" if i % 4 == 2 else "L"
            nm = names.take("EW", cls)
            emit(_warp(pts, amp, lam, ph), region, cls, "lattice", nm, ward=ward)
        ya, yb = region.bounds[1] - 50, region.bounds[3] + 50
        yy = np.arange(math.floor(ya / STEP) * STEP, yb + STEP, STEP)
        x = a + sp["sN"] * 0.55
        j = 0
        while x < b - sp["sN"] * 0.3:
            xj = x + rng.uniform(-sp["jitN"], sp["jitN"]) * sp["sN"]
            if (abs(xj) > 70 and abs(xj - G.FERRY_X) > 30 and abs(xj - G.DOCK_X) > 30 and abs(xj - G.PORT_X) > 30
                    and abs(xj - SEAM_X) > 30 and abs(xj - G.RAIL_X) > 25):
                cls = "C" if j % 4 == 0 else "L"
                nm = names.take("NS", cls)
                emit(_warp([(xj + sp["tilt"] * (y - sp["yref"]), float(y)) for y in yy], amp, lam, ph), region_ns, cls, "lattice", nm, ward=ward)
            x += sp["sN"]
            j += 1
    # the seam street between the landing town and the harbour district: a collector with ragged T-junctions either side
    emit([(SEAM_X, float(y)) for y in np.arange(150.0, 1400.0, STEP)], PN, "C", "lattice", names.take("NS", "C"), ward="oldtown")

    # radial roads that grew out of the original crossings
    for dg in DIAGONALS:
        th = math.radians(dg["bearing"])
        x0, y0 = dg["start"]
        ln = [(x0 + t * math.cos(th), y0 + t * math.sin(th)) for t in np.arange(0.0, dg["length"] + 1, 25.0)]
        emit(ln, PN if dg["reg"] == "N" else PS, "C", "pike", dg["name"], minlen=60.0, era=dg["era"])

    # ---------------------------------------------------------------- tag wards, eras, fill
    order = ["northgate", "oldtown", "riverside", "eastport", "kilbride", "ironworks"]
    for s in streets:
        ln = LineString(s["pts"])
        m = ln.interpolate(0.5, normalized=True)
        w = None
        for k in order:
            if G.WARDS[k].buffer(0.75).contains(m):
                w = k
                break
        s["ward"] = w
    prune_short_edges(streets)
    for s in streets:
        s["era"] = era_of(s)
        m = LineString(s["pts"]).interpolate(0.5, normalized=True)
        s["fill"] = bool(s.get("fill") or (s["kind"] == "lattice" and G.FILL_NW.buffer(1).contains(m)))
    return streets


MIN_EDGE = 8.0
_RANK = {"L": 0, "S": 1, "C": 2, "Q": 3, "M": 4, "A": 4, "B": 5}


def prune_short_edges(streets, rounds=8):
    """Remove the weakest lattice street that creates a sub-12 m edge (near-coincident junctions)."""
    for _ in range(rounds):
        road = [s for s in streets if s["cls"] != "B"]
        lines = [LineString(s["pts"]) for s in road]
        un = shapely.union_all(lines, grid_size=0.01)
        edges = [g for g in _pieces(un) if 0.05 <= g.length < MIN_EDGE]
        if not edges:
            break
        tree = shapely.STRtree(lines)
        kill = set()
        for e in edges:
            m = e.interpolate(0.5, normalized=True)
            on_edge = [i for i in tree.query(m.buffer(0.3)) if lines[i].distance(m) < 0.05]
            ends = [Point(e.coords[0]), Point(e.coords[-1])]
            cand = set()
            for p in ends:
                for i in tree.query(p.buffer(0.2)):
                    if lines[i].distance(p) < 0.05 and i not in on_edge:
                        cand.add(i)
            pool = {i for i in set(cand) | set(on_edge) if road[i]["kind"] == "lattice"}
            if not pool:
                continue
            kill.add(min(pool, key=lambda i: (_RANK[road[i]["cls"]], lines[i].length)))
        if not kill:
            break
        keep = [s for k, s in enumerate(road) if k not in kill] + [s for s in streets if s["cls"] == "B"]
        keep.sort(key=lambda s: s["id"])
        for i, s in enumerate(keep):
            s["id"] = i
        streets[:] = keep
    return streets


def node_graph(streets):
    """noded edge list of the at-grade network. Deck (class B) is excluded: grade separated."""
    lines = [LineString(s["pts"]) for s in streets if s["cls"] != "B"]
    ids = [s["id"] for s in streets if s["cls"] != "B"]
    un = shapely.union_all(lines, grid_size=0.01)
    edges = [g for g in _pieces(un)]
    return edges


if __name__ == "__main__":
    S = build_streets()
    from collections import Counter
    print(len(S), Counter(s["cls"] for s in S), Counter(s["ward"] for s in S))
    print("total km", sum(LineString(s["pts"]).length for s in S) / 1000)
    E = node_graph(S)
    print("edges", len(E))


# ====================================================================== rail + named streets
def _smooth(t):
    t = min(1.0, max(0.0, t))
    return t * t * (3 - 2 * t)


RAIL_NORTH_OFFSET = 150.0


def rail_north_y(x):
    return float(G.N1(x)) - RAIL_NORTH_OFFSET


def _bezier(p0, p1, p2, p3, n=24):
    out = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        out.append((u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
                    u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1]))
    return out


def build_rail():
    """Rail follows the river's history: the South Line reached the south bank in 1861 (cars crossed on a float);
    the 1893 lift bridge carries the Ferry Spur over the narrows to the North Line, which runs east behind the city."""
    RX = G.RAIL_X
    south = [(float(x), -1300.0 - 120.0 * _smooth(-x / 250.0)) for x in np.arange(-4000.0, G.RAIL_STUB_X + 1, 25.0)]
    spur_s = [(RX, G.RAIL_JUNCTION_Y), (RX, float(G.bank_s(RX)))]
    spur_n = [(RX, float(G.bank_n(RX)))]
    yb = rail_north_y(-420.0)
    p0 = (RX, rail_north_y(RX) - 330.0)
    curve = _bezier(p0, (RX, p0[1] + 180.0), (RX + 120.0, yb - 20.0), (-420.0, yb), 20)
    spur_n += [(RX, y) for y in np.arange(float(G.bank_n(RX)) + 25.0, p0[1] - 1, 100.0)] + curve
    north = [(-420.0, yb)] + [(float(x), rail_north_y(x)) for x in np.arange(-395.0, X1 + 1, 25.0)]
    # port spurs: each of the two big basins has a rail spur ending on its ring road
    xs_p = (G.BASINS["NE"]["piers"][1] + G.BASINS["NE"]["piers"][2]) / 2
    xs_c = (G.BASINS["SW"]["piers"][1] + G.BASINS["SW"]["piers"][2]) / 2
    packet = [(xs_p, rail_north_y(xs_p)), (xs_p, G.basin_wall("NE"))]
    coal = [(xs_c, -1300.0 - 120.0 * _smooth(-xs_c / 250.0)), (xs_c, G.basin_wall("SW"))]
    out = []
    for nm, pts, era in (("South Line", south, 1861), ("Ferry Spur", spur_s, 1861), ("Ferry Spur", spur_n, 1893), ("North Line", north, 1893),
                         ("Packet Spur", packet, 1894), ("Coal Spur", coal, 1890)):
        for p in _pieces(LineString(pts).intersection(LIMIT)):
            out.append(dict(name=nm, kind="rail", pts=[(round(x, 3), round(y, 3)) for x, y in p.coords], era=era))
    out.append(dict(name="Rail Lift Bridge", kind="lift-rail", pts=[(RX, float(G.bank_s(RX))), (RX, float(G.bank_n(RX)))], era=1893))
    return out


def apply_named(streets, rail, names_spec):
    """Give selected lattice streets the names the design documents refer to."""
    rail_ln = shapely.union_all([LineString(r["pts"]) for r in rail if r["kind"] == "rail"])
    by_name = {}
    for s in streets:
        by_name.setdefault(s["name"], []).append(s)
    used = {s["name"] for s in streets}
    for new, sp in names_spec.items():
        assert new not in used, new
        cands = []
        for nm, group in by_name.items():
            g0 = group[0]
            if g0["kind"] != "lattice" or g0["ward"] != sp["ward"] or g0["axis"] != sp["axis"] or g0["cls"] != sp["cls"]:
                continue
            total = sum(LineString(s["pts"]).length for s in group)
            if total < 450:
                continue
            allpts = np.array([p for s in group for p in s["pts"]])
            cands.append((nm, group, total, allpts.mean(0)))
        if not cands:
            raise RuntimeError(f"no candidate for {new}")
        r = sp["rule"]
        wc = np.array(G.WARDS[sp["ward"]].centroid.coords[0])
        if r == "central":
            key = lambda c: np.linalg.norm(c[3] - wc)
        elif r == "near":
            q = np.array(sp["pt"])
            key = lambda c: min(np.linalg.norm(np.array(p) - q) for s_ in c[1] for p in s_["pts"])
        elif r in ("southmost",):
            key = lambda c: c[3][1]
        elif r in ("nearest_quay", "nearest_quay_n"):
            sel = [c for c in cands if c[3][1] > 0] or cands
            cands = sel
            key = lambda c: c[3][1]
        elif r == "nearest_rail":
            sel = [c for c in cands if c[3][1] > 0] or cands
            cands = sel
            key = lambda c: min(LineString(s["pts"]).distance(rail_ln) for s in c[1])
        best = min(cands, key=key)
        for s in best[1]:
            s["name"] = new
            s["group"] = new
        del by_name[best[0]]
        by_name.setdefault(new, []).extend(best[1])
        used.add(new)
    return streets
