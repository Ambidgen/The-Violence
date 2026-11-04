# Port Carrick: canonical topography and geology, plus infrastructure critique

> **Status note (added when this was filed in the repo).** Sections 1 (locked topography) and 2 (proposed geology) stand.
> Section 3's critique and Section 5's change list were **implemented in generator v0.4** — see [`MAP_SPEC.md`](MAP_SPEC.md).
> Where the two disagree, the Map Spec wins: in particular the harbour bullet in Section 1 ("four basins at the narrows") is
> **superseded** — the four basins now sit in the wide reaches of the river. The original text follows unchanged.

Status (original): topography is LOCKED (2026-10-27). The geological explanation is a new authored layer (marked "proposed"). The infrastructure critique is advice; nothing in the generator has been changed.
Source of truth for numbers: `pc_geo.py` (v3). The validator already enforces most of this.

## 1. Locked canon: topography

Frame: local metres, bridge centre = (0,0) = lat 0, lon 0. x east, y north. Extent x -4000..4000, y -2400..2400.

- **Datum.** River surface 215 m. Flood line 222 m (7 m above water). Terrain spans 215-321 m.
- **The Carrick River.** Runs east-west. Centreline yc(x) = 55(1-cos(x/1250)) + 3.2(x/1000)^3, so it is level at the bridge and bends gently. Width(x) = 330 + 1100*(|x|/4000)^2.2: 330 m at the bridge, about 1,030 m at x = +/-3250, about 1,430 m at the map edges. Symmetric and strictly monotone. The narrow midpoint is the only sensible crossing; this is the in-world reason there is one bridge.
- **North bank.** A long slope rising to about 307 m. Old Town, Riverside, Eastport (north) sit on the lower slope. Northgate sits on the upper slope above Highland Avenue.
- **South bank.** A steep bluff (+66 m, smoothed) close to the river. Ironworks and Kilbride sit on it.
- **The Slag.** Artificial heap, +34 m, centred (-2400,-900), sigma 260 m.
- **Kilbride knoll.** Natural rise, +11 m, centred (1500,-1150).
- **Harbour.** *(Superseded by Map Spec v0.4.)* Four basins at the narrows: NE Packet, NW Fish, SW Coal, SE Grain. NE basin spans x 80-540, y 150-410; the others are mirrored. Three finger piers each, 40 m wide, 190 m long.
- **Carrick Bridge.** Deck 62 m above water (277 m), 62 m wide, level to |y| = 260, then a constant grade meeting ground at (0, +/-1300). Towers top out at deck + 128 m. The only river crossing.
- **Contours.** 10 m interval, index every 50 m. Buildings: 1 storey = 3 m, so building contours align with terrain contours.

## 2. Proposed canon: geology (invented; veto freely)

This is the explanation that makes the locked numbers make sense. It is consistent with Pennsylvania and the Great Lakes basin.

- **The river is a connecting channel, not a normal river.** A river that widens in BOTH directions from a midpoint is two drowned valleys (backwater bays) joined by a narrows. Think Detroit River or Niagara, not the Allegheny. Canon: east and west reaches are drowned river-mouth bays, held high by a lake seiche or backwater; the middle is a rock-cut narrows.
- **The narrows is a bedrock sill.** A resistant sandstone ledge crosses the valley at x = 0. It is why the channel is only 330 m wide there, why the bridge piers can be founded on rock, and why nothing else can be bridged for kilometres either side (the wide reaches are deep, soft-bottomed, and 1 km across).
- **Flow.** Suggested canon: flows west to east (the sill drops water into the east bay). This matters for where sewage outfalls, slag and industry sit.
- **North slope** is a dissected glacial till plateau edge. Good drainage, gravity water supply.
- **South bluff** is the cut face of the sill's escarpment. Steep, bedrock close to the surface, poor for rail and housing.
- **Kilbride knoll** is a glacial kame (sand and gravel). Natural high ground, flood-safe.
- **The Slag** is anthropogenic: 150 years of furnace dumping. Unstable, contaminated, unbuildable.
- **Wide reaches** are soft alluvium. Floodplain. Subsidence, high water table, the ground that should have been left empty.

## 3. Infrastructure critique

### What is plausible
- One crossing at the narrows is the right place and the right reason.
- A river-hugging quay road, a bank-parallel rail line, a steep south bluff with less housing, and a high-density core near the crossing all behave like real cities.
- Industry on the south bluff plus the Slag is plausible.

### What is not
1. **Symmetric four-basin harbour at the narrows.** Real ports go in wide, sheltered, slow water, not at the fastest, narrowest point. Four mirrored basins with identical piers read as planned in one stroke. A real harbour accretes: one original landing, then basins added by different owners in different decades, unequal in size, with disused ones silted or filled.
2. **A 62 m-high, 62 m-wide viaduct as the original crossing.** No town of this size builds that first. It is a capital project that arrives late, probably 1920s-60s, replacing a ferry, a low truss or swing bridge, and a rail bridge. Keep the monument, but make it the last of several crossings.
3. **Rail dead-ends at the bridge.** Rail must cross the river or it is two disconnected networks. Railways were the FIRST fixed crossing in most such cities. Needs a rail bridge or lift span at or near the narrows, a car-float yard, or a tunnel.
4. **Single point of failure for services.** One bridge means police, fire and EMS must be duplicated on both banks, with a hospital on each. This is a gameplay gift: a bridge closure splits the city and forces the player's budget decisions. It should be an explicit mechanic, not an accident.
5. **No flood logic.** 7 m of freeboard and housing right at the quays. Real cities have levees, floodwalls, pumping stations, and a flood-prone class of land that depopulates first.
6. **Street pattern is lattices with perturbation.** The old core should be organic and follow the original landing, ferry road and fords; grids come later as annexed additions, each meeting the last at a ragged seam. Ward boundaries should be those seams.
7. **No utilities.** Water towers and reservoirs belong on the north slope; sewers fall to the river; treatment works sit downstream (east); combined sewer overflows discharge at the harbour. None of this exists in the data.
8. **Abandonment is statistical.** Ward bias plus noise plus five ghost circles. Real abandonment has causes, and causes make better level design.
9. **Cleared lots only appear at Peak.** Demolition is the main thing that distinguishes a declining city from an old one.

## 4. How the city would really have evolved

| Era | What happens | Map consequence |
| --- | --- | --- |
| 1790s-1820s | Ferry and ford at the narrows; a tavern and landing on the north bank | Organic Old Town kernel, ferry road becomes Ferry Street |
| 1830s-50s | Canal or packet trade; first small basin (NE Packet); wooden bridge | One basin, not four; first quay |
| 1860s-90s | Rail arrives; iron and coal move to the south bluff; rail bridge at the narrows | Ironworks, Slag begins, Coal and Grain basins added later and unequal |
| 1900-30 | Peak boom to 150,000; tenement rings; annexed grids; streetcars across the new truss | Lattice wards appear as additions; Riverside and Eastport fill the floodplain |
| 1930-60 | Flood(s); levee and floodwall; the great viaduct replaces the truss | The monument bridge is a late civic gesture |
| 1960-90 | Steel collapses; highway bypasses; white flight to Northgate and Kilbride | Ironworks, Eastport, Riverside lose population first |
| 1990-now | Demolition, vacancy, ghost districts, 100,000 residents | Cleared lots, derelicts, selective survival near services |

## 5. Recommended generator changes (originally "not done; ask to proceed" — all done in v0.4)

1. Growth model: generate by eras (kernel, annexations, additions) so street pattern, building age and lot size follow from history.
2. Harbour: one original basin; others differ in size, with one silted or filled.
3. Second and third crossings: a rail bridge at the narrows, a lift or swing span, or ferry slips. Add a validator rule: every ward reachable by rail and by road.
4. Flood layer: a 222 m floodplain polygon, a levee line, a pumping station; vacancy weighted by flood exposure.
5. Causal abandonment: score = flood exposure + brownfield + distance from remaining jobs + highway severance + age of stock.
6. Utilities: reservoirs on the north slope, sewer fall lines, outfalls, a treatment plant downstream. Validate that every sewer falls to the river.
7. Dual-bank services: fire, police and hospital per bank, with a bridge-closure scenario.
