# The Violence — Port Carrick Map Spec (v0.4)

Port Carrick, PA is generated, not drawn. `make_city.py` builds `city.json`; `validate_city.py` + `validate_layers.py` re-check it independently from the JSON alone (74 rules, all passing; 36 mutation tests prove contradictions are caught). Level design reads from `city.json` and never contradicts it. v0.4 implements the critique in [`CANON_AND_CRITIQUE.md`](CANON_AND_CRITIQUE.md) and relocates the ports into the wide river reaches.

## Frame
- Local metres, origin = centre of the Carrick Bridge = lat 0, lon 0. lat = y / 111,320; lon = x / (111,320 cos 40.5 deg). x east, y north. Extent 8,000 x 4,800 m.

## Geography (locked canon, unchanged)
- River widens symmetrically: width = 330 + 1,100 (|x|/4000)^2.2. Surface 215 m, flood line 222 m. Flows west to east (proposed geology: connecting channel between two drowned bays, bedrock sill at the narrows).
- Terrain 215-321 m, 10 m contours. Slag heap, Kilbride knoll, south bluff as before.

## Harbour (changed in v0.4: ports sit in the wide reaches)
- Four basins, each cut into a bank at a wide reach (river 690-720 m wide there, never nearer than 1,800 m to the bridge): NE Packet (1838), NW Fish (1871, outer end filled 1971), SW Coal (1889), SE Grain (1912). Unequal, built by different owners in different decades.
- Rail spurs: Packet Spur (1894) and Coal Spur (1890) end on their basin ring roads.

## Growth by era
- Every street has an era; every building a build year and an abandonment year. Oldest street is Ferry Street at the landing (1794); grid ages rise with distance from the landing. Population curve is rebuilt from building years: 150,000 at 1962, 100,000 now. The viewer has a year slider.

## Crossings (chronological)
- Ferry 1794; swing/lift bridge 1861 (lift 1927); rail lift bridge 1893; Carrick Bridge viaduct 1958, the only major crossing and the last. With the viaduct closed, the lift bridges still link the banks at reduced speed.

## Flood layer
- Floodwall x -3000..3000, crest 226 m, gates at the four basins, Ferry Street and the rail spur; 12 pump stations (6 per bank). Classes: 0 above flood line, 1 low ground behind wall, 2 unprotected flats. Only 4 buildings (none residential) lie beyond |x| 3000; the far ends of the bays are unbuilt flats.

## Utilities
- Four gravity pressure zones fed from north-slope reservoirs; sewer laterals fall to interceptors flowing east to two treatment plants; water intake upstream (west) of every outfall; CSO outfalls including one per basin.

## Services
- Fire/police/EMS stations on both banks; response times stored for three scenarios (open, viaduct closed, all crossings closed). Each bank has its own stations, so fire response is nearly identical across scenarios; the closure mechanic bites on hospitals, jurisdictional reach and supply, not fire.

## Roads, addresses, population
- ~350 km, 275 streets, noded and planar. Chicago-style addresses from the bridge baselines; every address unique. 12,666 buildings. Now exactly 100,000; peak 150,000. Five ghost districts (The Slag, Cinder Hollow, Hale Yards, Tannery Flats, Foundry Bottoms) now have causes (flood, brownfield, severance, job distance, age of stock).

## Validator groups
- GE, RD (incl. RD12 spur check), BD, AD, PD, ST (original 50) plus HS history, FL flood, UT utilities, SV services (layers). 74/74.

## Invented assumptions (veto freely)
- Geology and flow direction, port founding years, pump and plant positions, unbuilt far bays. Street and landmark names beyond the original docs are placeholders.

## Critique status (supersedes the Canon doc's status line and harbour bullet)
Section 5 of the Canon doc is done in the generator (see this spec, v0.4). Per item: (1) era-based growth with year slider; (2) one original basin, others later and unequal, one partly filled; (3) rail lift bridge 1893 plus swing/lift and ferry; viaduct is last (1958); (4) dual-bank services with closure scenarios; (5) floodwall, pumps, flood classes; (6) organic Ferry Street kernel with accretive grids; (7) utilities with validated fall lines; (8) causal abandonment; (9) cleared lots shown by era.

Port relocation (user challenge: by this logic ports belong in the wide reaches): all four basins moved out of the narrows into the wide bays (x about +/-1800 to 2900, river 690-720 m wide), floodwall extended to +/-3000 to cover them, rail spurs added, and the viaduct's rationale is now purely the narrow crossing, not the harbour. The Canon doc's harbour bullet ("four basins at the narrows") is superseded.
