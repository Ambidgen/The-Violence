# Port Carrick, PA — the city model

The definitive map of the game's city, **generated rather than drawn**: one deterministic Python pipeline writes
`city.json`; an independent validator re-checks it from the JSON alone; a single-file viewer draws it. Everything
level-design touches downstream (streets, addresses, landmarks, situation sites, wards) is meant to read from
`city.json` and never contradict it.

The model has its own version (**v0.4**). The Godot game reads the generated JSON for new campaign locations, ward trust, visibility and the weekly board overview. Tactical layouts are still schematic proxies; the model and the game's release/version numbers are separate.

## Run it

Run from this directory (`cd port-carrick` from the repository root):

```sh
python3 -m pip install -r requirements.txt          # numpy, scipy, shapely>=2, scikit-image
python3 make_city.py city.json           # ~1 minute; seed 1995; exits non-zero if any validator rule fails
python3 validate_city.py city.json       # validate the existing output without regenerating it
python3 build_viewer.py city.json        # writes port-carrick-map.html (open in a browser)
python3 mutate.py && python3 mutate2.py  # 36 mutation tests: each injected contradiction must be caught
```

Checked 2026-10-27: 74/74 validator rules passed, regeneration matched the committed JSON byte for byte, and all 36 mutation tests (10 + 26) were caught.

Validation checks the generated data independently of the report embedded in the JSON. To avoid overwriting the committed file during a reproducibility check, use `python3 make_city.py /tmp/port-carrick-city.json` and compare that file with `city.json`. Both mutation scripts return nonzero if an injected contradiction is missed; the second also checks the expected rule IDs. Regeneration can depend on Python dependency versions: review any output diff rather than accepting it blindly.

## Using the model in the game

`../scripts/campaign/city.gd` validates the consumed data, caches a compact subset and maps the following official site IDs to existing playable layouts. IDs, type codes, names, addresses, ward and visibility come from `city.json`; the map number is a deliberately hand-authored **proxy**, not a claim that the drawn floorplan is the actual building. The site list in `sites_src.json` remains the generator input.

| Campaign type | Canonical site IDs | Tactical proxy |
| --- | --- | --- |
| Warrant | `front-st-flat`, `foundry-row-warrant` | 05 Duplex |
| Warrant | `heights-villa` | 06 Ranch |
| Crew house | `mill-squat`, `warehouse-row-7` | 08 Warehouse |
| Crew house | `riverside-homes-block` | 10 Apartments |
| Barricade | `brass-rail` | 03 Corner Store |
| Barricade | `floodwall-shed` | 01 Lone Cabin |
| Barricade | `bluff-rd-bungalow`, `harlan-ave-bungalow` | 04 Center Hall |
| Hostage | `yard-office` | 08 Warehouse |
| Hostage | `kilbride-corner-store` | 03 Corner Store |
| Hostage | `wharf-st-flat` | 05 Duplex |
| Public event | `civic-plaza-rally` | 11 Civic Plaza |

Other authored sites are retained in the model but are not placed on a recurring board until a suitable layout and simulation exist. The Bridge Street eviction is a historical event, not a repeating call. The board overview draws ward/water geometry, selected major roads and numbered situation pins; it is not a full building-level navigator. Wards map to the game's existing save order: Northgate, Riverside, Old Town, Ironworks, Eastport, Kilbride.

New situations snapshot their site metadata; existing saved boards keep their original values and appear unlocated if they have no canonical position. If the resource or its mapped-site contract is invalid, the adapter warns and falls back to explicitly unlocated calls with no invented ward. The JSON is included by the project/export presets; Python and the full validator are not needed at runtime.

When changing the city, regenerate and independently validate it, update the explicit mapping only for compatible layouts, and run `tests/city_integration_test.gd` plus the game regression suites. Renaming or deleting a mapped ID intentionally trips the adapter instead of silently relocating calls. Changes to city choices also alter campaign determinism cases; review those diffs before regenerating the fixture. A generator change does not update already-saved boards.

## Files

| File | Role |
| --- | --- |
| `make_city.py` | Entry point: streets → landmarks → lots/buildings → finalize → export → validate |
| `pc_geo.py` | Single owner of every geometric fact: frame, river, terrain, harbour basins, bridge, floodwall, crossings |
| `pc_streets.py` | Programmatic road system derived from `pc_geo` (no hand-placed road coordinates): organic Ferry Street kernel, accretive grids, rail |
| `pc_net.py` | Travel-time model over the noded street network, shared by generator and validator (service response times, bridge-closure scenarios) |
| `pc_landmarks.py`, `pc_build.py`, `pc_finalize.py` | Landmarks, lots and buildings, history/abandonment/flood exposure, exact population calibration |
| `pc_addr.py`, `pc_export.py` | Chicago-style address geocoder; sites, address matrix, contours and the `city.json` document |
| `sites_src.json` | The 25 hand-authored situation sites (name, ward, type, archetype, visibility, notes) read by `pc_export.py` |
| `validate_city.py`, `validate_layers.py` | Independent rule checker: GE, RD, BD, AD, PD, ST + the v4 layers HS history, FL flood, UT utilities, SV services |
| `mutate.py`, `mutate2.py` | Mutation tests for the validator |
| `viewer_template.html`, `build_viewer.py` | Crayon-styled map viewer; the JSON is inlined into one HTML file |
| `city.json` | The model (1.9 MB): 275 streets, 12,666 buildings, 80 landmarks, 25 situation sites, 6 wards |
| `docs/MAP_SPEC.md` | The spec (v0.4) |
| `docs/CANON_AND_CRITIQUE.md` | Locked topography, proposed geology, the infrastructure critique v0.4 implements |

## Where it stands

**Done (v0.4):** locked topography (river funnel, 215 m datum, 222 m flood line, Slag, Kilbride knoll, south bluff);
growth by era (Ferry Street 1794 → peak 150,000 in 1962 → 100,000 now); four unequal harbour basins relocated to the wide
reaches; ferry, swing/lift, rail lift and the 1958 viaduct as the last crossing; floodwall, gates and 12 pump stations;
utilities with validated fall lines; dual-bank services with three bridge-closure scenarios; causal abandonment for five
ghost districts. All nine items of the Canon critique's change list are implemented.

**Next:**
1. The author's edit pass: the model was built to be edited by hand and then locked as the definitive map.
2. Replace the tactical proxies with site-appropriate layouts. The 1.5 level list (see `../docs/design/LEVEL_DESIGN_CONSTRAINTS.md`) names four new maps in Tannery Flats, Ironworks, Riverside and Cinder Hollow; those maps and the command layer are not in this checkout.
3. Decide whether the bridge-closure scenarios become a campaign mechanic (the critique called it "a gameplay gift").

## Invented assumptions (veto freely)

Geology and flow direction, port founding years, pump and plant positions, unbuilt far bays. Street and landmark names
beyond the original project docs are placeholders.

## Filing notes (2026-10-27)

- `pc_export.py` used to read the situation sites from a hard-coded scratch path in an earlier working session, so the
  pipeline could not run anywhere else. The sites are now bundled as `sites_src.json` (extracted from the committed
  `city.json`) and the path is relative. Regenerated output is byte-identical to the previous `city.json`.
- Three superseded snapshots (`pc_geo_v4a.py`, `pc_streets_v4a.py`, `pc_landmarks_v4a.py`, which put the harbour basins
  at the narrows) and a duplicate root-level `city.json` were removed.
