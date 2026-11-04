"""pc_geo.py - Port Carrick geography.

One module owns every geometric fact about the city so the generator and the
validator cannot disagree: the local coordinate frame, the river and its two bays,
the four harbour basins, the Carrick Bridge, the terrain and the six wards.

Frame: local ENU in metres, origin (0, 0) = centre of the Carrick Bridge.
x grows east, y grows north. The same point is expressed as local geodetic
(lat, lon) in degrees relative to that origin:  lat = y / 111320,
lon = x / (111320 * cos 40.5 deg).  So the bridge is exactly lat 0, lon 0.
"""
import math
import numpy as np
from shapely.geometry import Polygon, box, LineString
from shapely.ops import unary_union

# ------------------------------------------------------------------ frame
M_PER_DEG_LAT = 111320.0
LAT_NOMINAL = 40.5          # only sets the longitude scale
M_PER_DEG_LON = M_PER_DEG_LAT * math.cos(math.radians(LAT_NOMINAL))

X0, X1, Y0, Y1 = -4000.0, 4000.0, -2400.0, 2400.0


def enu_to_geo(x, y):
    return (y / M_PER_DEG_LAT, x / M_PER_DEG_LON)


def geo_to_enu(lat, lon):
    return (lon * M_PER_DEG_LON, lat * M_PER_DEG_LAT)


# ------------------------------------------------------------------ river
W0 = 330.0                   # river width at the bridge
FLARE_EXTRA, FLARE_POW = 1100.0, 2.2     # river widens monotonically with distance from the bridge
BAY_X = 3250.0                           # reference point where the flare is checked (>= 3x centre width)


def yc(x):
    """River centreline (y as a function of x). Slope is exactly 0 at the bridge."""
    x = np.asarray(x, float)
    return 55.0 * (1 - np.cos(x / 1250.0)) + 3.2 * (x / 1000.0) ** 3


def width(x):
    x = np.asarray(x, float)
    return W0 + FLARE_EXTRA * (np.abs(x) / X1) ** FLARE_POW


def bank_n(x):
    return yc(x) + width(x) / 2


def bank_s(x):
    return yc(x) - width(x) / 2


QUAY_OFFSET = 24.0


def quay_n(x):
    return bank_n(x) + QUAY_OFFSET


def quay_s(x):
    return bank_s(x) - QUAY_OFFSET


XS = np.arange(X0, X1 + 1, 25.0)


def _poly_between(f_lo, f_hi, xs=XS):
    lo = [(float(x), float(f_lo(x))) for x in xs]
    hi = [(float(x), float(f_hi(x))) for x in xs[::-1]]
    return Polygon(lo + hi)


RIVER = _poly_between(bank_s, bank_n)

# ------------------------------------------------------------------ harbour
# The four basins are dug into the banks of the WIDE reaches of the river (the east and west bays), where the water
# is 600-800 m across and slow, never at the narrows, where it is 330 m wide and fast. Each is a rectangle with finger
# piers cut into a sloping bank, so its landward depth differs end to end. Dug by different owners in different decades.
#   bank : N or S bank        x : absolute x range of the basin        piers : absolute x centres of the finger piers
PIER_W = 40.0
RING_PAD = 22.0
BASIN_DEPTH = 190.0          # cut beyond the higher end of the bank
PIER_STANDOFF = 70.0         # a pier stops this far short of the bank line
MIN_BASIN_RIVER_W = 600.0    # a basin is only dug where the river is at least this wide
MIN_BASIN_X = 1800.0         # ... and at least this far from the bridge
BASINS = {
    "NE": dict(name="Packet Basin", year=1838, bank="N", x=(2150.0, 2700.0), piers=[2250.0, 2425.0, 2600.0],
               note="the original harbour: lake packet boats and canal trade, dug 1838 where the east bay is 600 m wide"),
    "NW": dict(name="Fish Basin", year=1871, bank="N", x=(-2600.0, -2250.0), piers=[-2500.0, -2350.0],
               note="dug 1871; its outer half was silted and filled in 1971, and the fill is the Fish Flats"),
    "SW": dict(name="Coal Basin", year=1889, bank="S", x=(-2750.0, -2250.0), piers=[-2650.0, -2550.0, -2450.0, -2350.0],
               note="dug 1889 beside the Ironworks for the coal trade; the deepest basin"),
    "SE": dict(name="Grain Basin", year=1912, bank="S", x=(2250.0, 2700.0), piers=[2400.0, 2570.0],
               note="the last basin, 1912, with the grain elevator"),
}
BASIN_NAMES = {q: b["name"] for q, b in BASINS.items()}
FILL_YEAR = 1971
FILL_W = 137.0


def _sg(q):
    """(sign of x, sign of y) of the quadrant"""
    return (1 if q[1] == "E" else -1), (1 if BASINS[q]["bank"] == "N" else -1)


def _basin_extent(q):
    b = BASINS[q]
    x0, x1 = b["x"]
    xs = np.linspace(x0, x1, 41)
    if b["bank"] == "N":
        bk = bank_n(xs)
        return x0, float(bk.min()) - 40.0, x1, float(bk.max()) + BASIN_DEPTH
    bk = bank_s(xs)
    return x0, float(bk.min()) - BASIN_DEPTH, x1, float(bk.max()) + 40.0


def _basin_rect(q):
    return box(*_basin_extent(q))


def pier_rects(q):
    b = BASINS[q]
    x0, ylo, x1, yhi = _basin_extent(q)
    out = []
    for cx in b["piers"]:
        xx = np.linspace(cx - PIER_W / 2, cx + PIER_W / 2, 5)
        if b["bank"] == "N":
            tip = float(bank_n(xx).max()) + PIER_STANDOFF
            out.append(box(cx - PIER_W / 2, tip, cx + PIER_W / 2, yhi))
        else:
            tip = float(bank_s(xx).min()) - PIER_STANDOFF
            out.append(box(cx - PIER_W / 2, ylo, cx + PIER_W / 2, tip))
    return out


def basin_wall(q):
    """signed y of the ring road along the landward wall"""
    x0, ylo, x1, yhi = _basin_extent(q)
    return yhi + RING_PAD if BASINS[q]["bank"] == "N" else ylo - RING_PAD


BASIN_RECTS = {q: _basin_rect(q) for q in BASINS}
PIERS = {q: pier_rects(q) for q in BASINS}
BASIN_WATER = {q: BASIN_RECTS[q].difference(unary_union(PIERS[q])) for q in BASINS}
WATER = unary_union([RIVER] + list(BASIN_WATER.values()))
# the Fish Basin's outer end was silted and filled in 1971; the fill abuts the outer causeway
_xa = BASINS["NW"]["x"][0] - RING_PAD
_fx = np.linspace(_xa - FILL_W, _xa, 11)
FILL_NW = box(_xa - FILL_W, float(bank_n(_fx).max()) + 4.0, _xa, _basin_extent("NW")[3])
FILL_NORTH = FILL_NW
# lattice exclusion zone = basin rectangle plus the ring road around it, from the river to above the wall
HARBOUR_ZONE = {}
for _q in BASINS:
    _x0, _, _x1, _ = _basin_extent(_q)
    _w = basin_wall(_q)
    HARBOUR_ZONE[_q] = box(_x0 - RING_PAD, 0, _x1 + RING_PAD, _w) if BASINS[_q]["bank"] == "N" else box(_x0 - RING_PAD, _w, _x1 + RING_PAD, 0)
HARBOUR_ZONE["fill"] = box(FILL_NW.bounds[0], 0, FILL_NW.bounds[2] + 1.0, FILL_NW.bounds[3] + 4.0)

# ------------------------------------------------------------------ bridge
BRIDGE_HALF_W = 31.0                # deck is 62 m wide
BRIDGE_FOOT = 1300.0                # ramps touch down at y = +-1300
DECK_ABOVE_WATER = 62.0
TOWER_Y = 100.0
TOWER_X = 38.0
TOWER_LEG = (12.0, 14.0)            # footprint of one tower leg (w, d)
TOWER_HEIGHT_ABOVE_DECK = 128.0     # tower top = deck + 128 m


DECK_THICK = 2.5                    # structure depth below the road surface
CLEAR_MIN = 4.5                     # minimum headroom for anything passing underneath
LEVEL_TO = 260.0                    # deck is level over the river to |y| = 260


def deck_z(y):
    """Road-surface elevation (m) of the viaduct. Level over the water, then a constant grade that
    meets the natural ground exactly at the touch-down nodes (0, +-1300)."""
    y = float(y)
    s = 1.0 if y >= 0 else -1.0
    a = abs(y)
    z_level = 215.0 + DECK_ABOVE_WATER
    if a <= LEVEL_TO:
        return z_level
    z_foot = float(terrain(0.0, s * BRIDGE_FOOT))
    t = min(1.0, (a - LEVEL_TO) / (BRIDGE_FOOT - LEVEL_TO))
    return z_level + (z_foot - z_level) * t


def deck_clearance(y):
    """headroom between ground and the underside of the deck at northing y (x = 0)"""
    return deck_z(y) - DECK_THICK - float(terrain(0.0, y))


def under_limit(sign):
    """largest |y| at which something can still pass beneath the deck with CLEAR_MIN headroom"""
    y = BRIDGE_FOOT
    while deck_clearance(sign * y) < CLEAR_MIN and y > 0:
        y -= 1.0
    return y


# ------------------------------------------------------------------ wards
def N1(x):
    """Top of the north lowland (Highland Avenue)."""
    x = np.asarray(x, float)
    return yc(x) + 1300.0 + 90.0 * np.sin(x / 650.0)


def _vstrip(x0, x1):
    return box(x0, Y0, x1, Y1)


_EXT = box(X0, Y0, X1, Y1)
_NORTH_LOW = _poly_between(yc, N1)
_SOUTH = _poly_between(lambda x: Y0, yc)
EXT, NORTH_LOW, SOUTH = _EXT, _NORTH_LOW, _SOUTH
_NORTHGATE = _EXT.difference(_NORTH_LOW).difference(_SOUTH)

WARD_X = {"riverside": (X0, -650.0), "oldtown": (-650.0, 700.0), "eastport_n": (700.0, X1),
          "ironworks": (X0, 0.0), "kilbride": (0.0, 2100.0), "eastport_s": (2100.0, X1)}
FERRY_X, DOCK_X, PORT_X = -650.0, 700.0, 2100.0


def _clean(g):
    return g.buffer(0)


WARDS = {
    "riverside": _clean(_NORTH_LOW.intersection(_vstrip(*WARD_X["riverside"]))),
    "oldtown": _clean(_NORTH_LOW.intersection(_vstrip(*WARD_X["oldtown"]))),
    "eastport": _clean(unary_union([_NORTH_LOW.intersection(_vstrip(*WARD_X["eastport_n"])),
                                    _SOUTH.intersection(_vstrip(*WARD_X["eastport_s"]))])),
    "ironworks": _clean(_SOUTH.intersection(_vstrip(*WARD_X["ironworks"]))),
    "kilbride": _clean(_SOUTH.intersection(_vstrip(*WARD_X["kilbride"]))),
    "northgate": _clean(_NORTHGATE),
}

# ------------------------------------------------------------------ terrain
def _smooth(t):
    t = np.clip(t, 0, 1)
    return t * t * (3 - 2 * t)


def in_water_np(x, y):
    x = np.asarray(x, float); y = np.asarray(y, float)
    return np.abs(y - yc(x)) <= width(x) / 2


def terrain(x, y):
    """Ground elevation in metres above the datum. River surface = 215."""
    x = np.asarray(x, float); y = np.asarray(y, float)
    dy = y - yc(x)
    n = np.maximum(dy, 0.0)
    s = np.maximum(-dy, 0.0)
    z = 215.0 + np.where(dy >= 0,
                         8.0 * (1 - np.exp(-n / 300.0)) + 92.0 * _smooth((n - 1100.0) / 1250.0) ** 1.3,
                         6.0 * (1 - np.exp(-s / 300.0)) + 66.0 * _smooth((s - 650.0) / 1450.0) ** 1.2)
    z += 34.0 * np.exp(-(((x + 2400.0) ** 2 + (y + 900.0) ** 2) / (2 * 260.0 ** 2)))   # the Slag
    z += 11.0 * np.exp(-(((x - 1500.0) ** 2 + (y + 1150.0) ** 2) / (2 * 340.0 ** 2)))  # Kilbride knoll
    k = np.minimum(1.0, np.abs(dy) / 600.0)
    z += k * (4.0 * np.sin(x / 410.0 + 1.3) * np.sin(y / 530.0 + 0.4) + 2.5 * np.sin(x / 170.0 + y / 230.0))
    return np.where(in_water_np(x, y), 215.0, z)


def slope(x, y, h=20.0):
    gx = (terrain(x + h, y) - terrain(x - h, y)) / (2 * h)
    gy = (terrain(x, y + h) - terrain(x, y - h)) / (2 * h)
    return np.hypot(gx, gy)


FLOOD_LINE = 222.0           # ground below this is the river's floodplain


def dem_grid(step=50.0):
    xs = np.arange(X0, X1 + 1, step)
    ys = np.arange(Y0, Y1 + 1, step)
    gx, gy = np.meshgrid(xs, ys)
    return xs, ys, terrain(gx, gy)


def river_tangent_angle(x):
    h = 5.0
    return math.atan2(float(yc(x + h) - yc(x - h)), 2 * h)


# ====================================================================== v4: history, crossings, flood, utilities
# Canon (see the project doc): the lake lies to the EAST. The Carrick flows west -> east through the narrows
# (a bedrock sill at x = 0). The city began as a ferry landing at the west end of the narrows and grew east.
YEAR_FOUNDED = 1794
YEAR_PEAK = 1962            # population peak (150,000)
YEAR_NOW = 2026
FLOOD_YEAR = 1936           # the great flood
WALL_YEAR = 1938            # floodwall completed
WALL_X = (-3000.0, 3000.0)  # protected reach: covers all four basins; the far ends of the bays are the unprotected flats
WALL_OFF = 8.0              # wall centreline offset from the water's edge (between the water and the quay road)
WALL_CREST = 226.0          # crest elevation (flood line is 222)
LANDING = (-650.0, 190.0)   # the original ferry landing, north bank (north end of Ferry Street)

FERRY_X = -650.0
RAIL_X = -710.0
RAIL_JUNCTION_Y = -1420.0   # where the Ferry Spur leaves the South Line
RAIL_STUB_X = -60.0         # South Line terminates at Union Station, west of the viaduct's south touch-down

# Crossings of the river. Exactly one is MAJOR (the viaduct). All the others are movable spans at the narrows.
CROSSINGS = [
    dict(id="ferry", name="Carrick's Ferry", kind="ferry", x=FERRY_X, year=YEAR_FOUNDED, closed=1861, lanes=0, width=8.0,
         note="cable ferry at the landing; replaced by the swing bridge"),
    dict(id="ferry-st-bridge", name="Ferry Street Lift Bridge", kind="lift", x=FERRY_X, year=1861, rebuilt=1927, lanes=2, width=16.0,
         deck_above=9.0, note="swing bridge 1861, rebuilt as a vertical lift 1927; opens for barge tows"),
    dict(id="rail-lift", name="Carrick Rail Lift Bridge", kind="rail-lift", x=RAIL_X, year=1893, lanes=0, tracks=2, width=12.0,
         deck_above=9.0, note="the only rail crossing; double-track vertical lift"),
    dict(id="carrick-bridge", name="Carrick Bridge", kind="viaduct", x=0.0, year=1958, lanes=6, width=62.0,
         deck_above=DECK_ABOVE_WATER, major=True, note="high-level fixed viaduct built to carry traffic past the lift bridges, which stopped for every ship bound for the western basins"),
]
MAJOR_CROSSING = "carrick-bridge"
CROSSING_MAX_WIDTH = 400.0   # every crossing sits where the river is narrow

# Flood-wall gates: windows in the wall where something passes through it
def _gate_windows():
    g = []
    for q, b in BASINS.items():
        x0, x1 = b["x"]
        g.append(dict(id=f"gate-{q}", name=f"{b['name']} storm gate", bank=b["bank"], x0=x0 - RING_PAD - 4, x1=x1 + RING_PAD + 4, kind="basin", year=max(WALL_YEAR, b["year"])))
    for bank in "NS":
        g.append(dict(id=f"gate-ferry-{bank}", name="Ferry Street floodgate", bank=bank, x0=FERRY_X - 14, x1=FERRY_X + 14, kind="road", year=WALL_YEAR))
        g.append(dict(id=f"gate-rail-{bank}", name="Rail spur floodgate", bank=bank, x0=RAIL_X - 12, x1=RAIL_X + 12, kind="rail", year=WALL_YEAR))
    return g


WALL_GATES = _gate_windows()


def wall_segments():
    """floodwall polylines (one list per continuous run) for each bank, with the gate windows removed"""
    out = []
    for bank in "NS":
        gates = sorted([(g["x0"], g["x1"]) for g in WALL_GATES if g["bank"] == bank])
        xs = [x for x in np.arange(WALL_X[0], WALL_X[1] + 1, 25.0)]
        cuts = [WALL_X[0]]
        for a, b in gates:
            cuts += [a, b]
        cuts.append(WALL_X[1])
        for i in range(0, len(cuts), 2):
            lo, hi = cuts[i], cuts[i + 1]
            if hi - lo < 20:
                continue
            xx = sorted({float(lo), float(hi)} | {float(x) for x in xs if lo < x < hi})
            f = (lambda x: float(bank_n(x)) + WALL_OFF) if bank == "N" else (lambda x: float(bank_s(x)) - WALL_OFF)
            out.append(dict(bank=bank, pts=[(x, f(x)) for x in xx]))
    return out


# Water supply: two gravity pressure zones per bank, split by ground elevation. Storage facilities set the
# hydraulic grade (top water level); every building must have 14-100 m of head.
ZONE_SPLIT = 250.0
HEAD_MIN, HEAD_MAX = 14.0, 100.0
SEWER_MIN_FALL = 0.003       # trunk laterals must fall at least 0.3 % toward the river
RESERVOIR_DEPTH, STANDPIPE_HEIGHT = 10.0, 45.0


def zone_of(bank_north, z):
    return ("N" if bank_north else "S") + ("H" if z >= ZONE_SPLIT else "L")


def bank_is_north(x, y):
    return bool(y > float(yc(x)))


# Response-time model for emergency services (metres per second on each road class, closed-bridge scenarios)
SPEED = {"A": 9.0, "C": 7.0, "L": 5.5, "Q": 7.0, "S": 4.0, "M": 4.0, "B": 14.0}
FIRE_LIMIT_S = 300.0         # 5 minutes of travel time
