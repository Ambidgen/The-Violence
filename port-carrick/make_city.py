#!/usr/bin/env python3
"""make_city.py - Port Carrick generator. python3 make_city.py [out.json]
Deterministic (seed 1995). Exits non-zero if validate_city reports any failure."""
import sys, json, time
import numpy as np
import pc_streets as P, pc_landmarks as LM, pc_build as PB, pc_finalize as F, pc_export as X

OUT = sys.argv[1] if len(sys.argv) > 1 else "city.json"
SEED = 1995
t0 = time.time()
rng = np.random.default_rng(SEED)
S = P.build_streets(SEED)
R = P.build_rail()
P.apply_named(S, R, LM.NAMED_STREETS)
r = PB.build_buildings(S, R, rng)
F.DEV_RETUNE = False
B = F.finalize(r, S, R, np.random.default_rng(SEED + 1))
B["ghosts"] = F.GHOSTS
doc = X.export(S, R, B, r, OUT, meta_extra=dict(seed=SEED))
print(f"generated {OUT}: {B['cx'].size} buildings, {len(S)} streets in {time.time()-t0:.0f}s")
import validate_city as V
rep = V.validate(OUT)
doc["validation"] = rep
json.dump(doc, open(OUT, "w"), separators=(",", ":"))
V.print_report(rep)
sys.exit(0 if rep["failed"] == 0 else 1)
