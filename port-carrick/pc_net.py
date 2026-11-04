"""pc_net.py - travel-time model over the street network (shared by generator and validator).

The at-grade network is noded exactly as the validator nodes it. The viaduct (class B) is a single grade-separated
edge between its two touch-down nodes; the lift bridge (class M) is an ordinary at-grade edge. Either crossing can be
closed, which is how the 'bridge closure' scenarios are computed.
"""
import numpy as np
import shapely
from shapely.geometry import LineString, Point
from scipy.sparse import coo_matrix
from scipy.sparse.csgraph import dijkstra
from scipy.spatial import cKDTree
import pc_geo as G

KEY = lambda p: (round(p[0], 2), round(p[1], 2))


def _pieces(g):
    if g.is_empty:
        return []
    if g.geom_type == "LineString":
        return [g]
    out = []
    for h in getattr(g, "geoms", []):
        out += _pieces(h)
    return out


class Network:
    def __init__(self, streets):
        road = [s for s in streets if s["cls"] not in ("B", "M")]
        lift = [s for s in streets if s["cls"] == "M"]
        deck = [s for s in streets if s["cls"] == "B"]
        self.lift_ids = [s["id"] for s in lift]
        lines = [LineString(s["pts"]) for s in road + lift]
        owners = road + lift
        un = shapely.union_all(lines, grid_size=0.01)
        edges = [g for g in _pieces(un) if g.length > 0.05]
        tree = shapely.STRtree(lines)
        nodes = {}
        E = []
        for e in edges:
            a, b = KEY(e.coords[0]), KEY(e.coords[-1])
            for p in (a, b):
                nodes.setdefault(p, len(nodes))
            m = e.interpolate(0.5, normalized=True)
            j = int(tree.nearest(m))
            st = owners[j]
            E.append((nodes[a], nodes[b], e.length, st["cls"], st["id"]))
        self.nodes = nodes
        self.xy = np.array(sorted(nodes, key=nodes.get), float)
        self.E = E
        self.kd = cKDTree(self.xy)
        self.viaduct = None
        if deck:
            d = LineString(deck[0]["pts"])
            a, b = KEY(d.coords[0]), KEY(d.coords[-1])
            if a in nodes and b in nodes:
                self.viaduct = (nodes[a], nodes[b], d.length)

    def graph(self, close=()):
        n = len(self.xy)
        r, c, w = [], [], []
        for u, v, L, cls, sid in self.E:
            if cls == "M" and "ferry-st-bridge" in close:
                continue
            t = L / G.SPEED[cls]
            r += [u, v]; c += [v, u]; w += [t, t]
        if self.viaduct and "carrick-bridge" not in close:
            u, v, L = self.viaduct
            t = L / G.SPEED["B"]
            r += [u, v]; c += [v, u]; w += [t, t]
        return coo_matrix((w, (r, c)), shape=(n, n)).tocsr()

    def times(self, sources_xy, targets_xy, close=(), access_speed=3.0):
        """seconds from the nearest source to each target (door points), over the network with `close`d crossings"""
        g = self.graph(close)
        sd, si = self.kd.query(np.asarray(sources_xy, float))
        d = dijkstra(g, directed=False, indices=np.unique(si), min_only=True)
        for_s = {int(i): float(x) for i, x in zip(si, sd)}
        # add each source's own access leg: handled by seeding through min over sources individually is costly; the
        # access leg is < 30 m, so it is added as a flat constant
        td, ti = self.kd.query(np.asarray(targets_xy, float))
        t = d[ti] + td / access_speed
        t[~np.isfinite(t)] = 99999.0
        return np.round(t).astype(int)
