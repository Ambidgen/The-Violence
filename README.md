# The Violence - vertical slice (v0.4)

A test range for the NPC CQB Bible, in two modes:

- **Matches:** eleven maps, from a one-room cabin to an apartment block. Two teams of one to twenty operators each carry a rifle and a pistol (the untrained carry only a pistol). You place everyone, set every operator's habits and traits, and press RUN. The fight resolves itself at up to 20x speed.
- **Endless Battle:** Port Carrick, a 1 km city of about 250 lots. Four gangs fight over its buildings, six police precincts answer the gunfire, and three hospitals send out ambulances. It never ends.

Every plan is drawn as an architectural floor plan in greyscale. Operators start as clean plan symbols. Red appears only where the shooting has been: sprays, smears on walls, drip trails, pools under the fallen, stains on the figures.

## Run it

**Standalone:** double-click `TheViolence.exe`. It is the whole game in one file (Godot 4.7.2 runtime with the game data embedded), so no Godot install is needed. The first launch may show a Windows SmartScreen warning because the file is unsigned: choose "More info", then "Run anyway".

**From source:**
1. Install Godot 4.4 or newer (tested on 4.4.1 and 4.7.2, standard build, no addons).
2. Open `project.godot` in the Godot project manager (Import, select the folder).
3. Press F5. The first open imports the SVGs (a few seconds).

**Rebuild the standalone exe:**
1. In Godot 4.7.2, install the export templates (Editor > Manage Export Templates).
2. Choose Project > Export > "Windows Desktop" > Export Project. The preset embeds the game data in the exe and writes `build/TheViolence.exe`.

From a terminal: `godot --headless --path . --export-release "Windows Desktop" build/TheViolence.exe`.

## The maps

Maps climb in complexity. Pick one from the Map list at the top of the setup panel.

| # | Map | Size | What it tests |
|---|-----|------|---------------|
| 00 | Test Range 01 - Shotgun House | 36 x 24 m | the original slice: four rooms on one line, porch, yard |
| 01 | Lone Cabin | 30 x 20 m | one room, one door |
| 02 | Bunkhouse | 36 x 22 m | two rooms, three doors: the first choice of way in |
| 03 | Corner Store | 40 x 26 m | a shop floor too big to clear from the door, glass shopfront, back alley |
| 04 | Center-Hall Bungalow | 40 x 28 m | a hall with rooms off both sides, small rooms to check, four entries |
| 05 | Duplex | 44 x 30 m | two mirrored units joined by one party-wall door |
| 06 | L-Shaped Ranch | 48 x 34 m | garage, open great room, kitchen core, bedroom wing, patio doors, pool |
| 07 | Roadside Motel | 56 x 34 m | six rooms off one walkway, office, open parking lot |
| 08 | Warehouse & Offices | 64 x 44 m | a racked 32 x 24 m warehouse next to a tight office block |
| 09 | Walled Compound | 64 x 50 m | perimeter wall and gates, big main house, guard house, garage |
| 10 | Apartment Block | 60 x 36 m | 43 rooms: eight flats off one 44 m corridor, two stair halls |

## Controls

**Setup**
- Pick a map. Set each team's size (1-20 operators) and posture:
  - Assault: clear the building room by room.
  - Hold: defend.
  - Hunt: go after contacts and sounds.
- Pick an operator (A1-A20, B1-B20), then left-click the plan to place them. Right-click sets facing. Every map has default posts for all forty.
- The Echelon dropdown plus `Apply preset` loads the bible's base stats, typical habits, plates and Experience. `Plates` sets 0-4 chest plate segments.
- The habit tabs toggle all 40 good habits and 20 bad habits. Hover any habit to see what it does and what overrides it.
- The Traits tab sets Experience (tier 1-5) and the hearing traits, Tinnitus and Elephant Ears.
- `Copy to team` gives every teammate the selected operator's echelon, habits, traits and plates.
- `Seed` makes a fight repeatable. The same seed and configuration always replay the same fight.

- Each team's alert option sets how it starts: Yellow (weapons drawn) or Green (relaxed, for an ambush).
- `ENDLESS BATTLE` opens the city. It uses the seed above it. `Gang cap` and `Police cap` set the most members a gang can have and the police headcount at which hiring stops.

**Run**
- Speed buttons run from 0.25x to 20x, or use keys 1-7. Space pauses, Esc returns to setup. Big fights may run slower than the target; the panel shows the real rate.
- Overlay toggles:
  - vision cones;
  - recognition bars: one per target, showing the enemy closest to recognizing it;
  - aim traverse arcs;
  - planned paths.
- Small arcs flash beside an operator who has just heard an enemy.
- Mouse wheel zooms; middle-drag or right-drag pans; Home refits the view.
- `Rerun same seed` replays the fight exactly; `Rerun new seed` rolls a new one.
- The ledger of the dead runs down the left side: when, who, how, by whom and where.
- The small dot beside each figure is their alert state: green, yellow or red.

## What is simulated

Everything follows the NPC CQB Bible.

- **Plan plus height:** 2D geometry with analytic height.
  - Half cover hides a ducked body, but a standing head shows over it.
  - Windows pass sight between 0.9 and 2.1 m.
  - Concealment hides you but doesn't stop rounds: sofas, beds, hedges, shelving, plastic bins, railings.
  - Cover hides you and stops rounds: walls, cars, counters, racks, drums, sandbags.
- **Low cover (up to 1.3 m):** someone right beside it sees and shoots over it with no penalty. Its effect grows with their distance from it, reaching its full height at 3 m. Cover close to the target still protects fully against a distant shooter. A ducked operator stays behind it.
- **Recognition:** slows with eccentricity in a 120 degree cone. It is followed by Fitts-law time on target, with separate precision and accuracy.
- **Experience (a trait, tiers 1-5):** how many enemies an operator tracks at once.
  - Only tracked enemies are recognized. They are the closest ones in the cone with a line of sight.
  - Every tracked enemy is recognized, and the aim set up, in parallel.
  - Switching to an enemy already acquired takes 0.06 s on the pistol and 0.08 s on the rifle, plus 4 ms per plate.
  - Tier 1 takes one enemy at a time, from scratch.
  - Presets: untrained 1, militia 1, regular 2, police 3, special operations 4.
- **Sound (a mechanic; nothing is played yet):** each sound has a fixed loudness:
  - rifle 45 m, pistol 35 m;
  - footsteps: sprint 8 m, run 5 m, walk 3 m, room-clearing pace 2 m; creeping is silent;
  - reloads and stoppage clearing: 4 m.

  Walls halve it. Hearing is the same for everyone unless a trait changes it: Tinnitus x0.5, Elephant Ears x1.5. Hearing gives a rough position.

  With ED07, an operator turns their eyes to any sound within 0.3 s; without it, only to gunfire, after 1 s. Aggressive operators go after what they hear: a hunting team, or anyone with the Aggression personality. A holding squad covers the door or window of its room closest to the sound.
- **Damage:** a head hit kills from any weapon, and plates break one segment per hit.
  - A chest hit that no plate stops kills outright one time in five. Otherwise it downs (65%) or wounds, as before.
  - Someone downed has five minutes to get aboard an ambulance, or dies of wounds. In a match, that only matters in long fights.
- **Alert states:** every operator is green, yellow or red.
  - Green: relaxed.
    - A rifle is carried low and takes 0.45 s to bring up.
    - A holstered pistol takes 0.9 s to draw (1.2 s for the untrained).
    - Recognition is 30% slower.
  - Yellow: weapon drawn and ready.
  - Red: engaging (aiming at or firing on someone).
  - Hearing an enemy, seeing one, a callout or incoming fire raises an operator to yellow.
  - Red relaxes to yellow after 5 s without engaging. Yellow relaxes to green after a quiet minute, never below the starting state or a tasking's floor (assaults and hunts stay at least yellow).
- **Melee:** two enemies in body contact (0.8 m). The quicker reaction kills; it comes from the echelon, habits and stress. It is half again slower against someone not yet recognized, and 30% slower in green.
- **Every operator is an individual.** Each match rolls:
  - a form within about 6% of their echelon, moving every time-based stat;
  - a little jitter on each stat;
  - one or two named strengths and one or two named weaknesses of 15-25% each (Quick eyes, Fast hands, Steady aim, Snap shooter, Cool head, Recoil master, Quick to settle; Slow eyes, Fumbles reloads, Shaky aim, Slow on target, Jittery, Flincher, Slow to settle).

  The roster shows them: hover an operator's name in a match, or select anyone in the city.
- **Names:** every operator gets a name from a bank of 18 cultures (hundreds of thousands of combinations). Team B and each gang draw about four in five from one culture; police, paramedics and team A draw from all of them.
- **Stress:** near misses, hits and casualties raise it. It widens dispersion, narrows the cone and switches on stress-triggered bad habits.
- **Rules 1 and 2:**
  - Rule 1: the closest visible enemy within 10 m overrides everything; fire until dry or the threat is eliminated.
  - Rule 2: a dry primary means switch to the pistol; when both are dry, break line of sight with cover before reloading.
- **Habits:** every good habit changes behaviour and gives the 0.5% speed bonus. Bad habits override the good habits they contradict, never Rules 1 and 2.

Bad habits present on an operator:
- Stress habits switch on when stress x (1 - resistance) passes their threshold.
- Personality habits are always on.

## Attention, suppression, wounds and doors

**The cone of attention (short-term memory).** An operator carries a handful of
*attention entries*: things that have recently demanded their attention and whose
position is only approximate.

| Learned by | Cone | Lasts |
|---|---|---|
| a figure that was recognized, lost, and never watched die | 25 deg | 20 s |
| a team-mate's contact callout | 30 deg | 25 s |
| a sound (gunfire, footsteps, a breach) | 35 deg | 18 s |
| incoming fire: a near miss or a round into cover beside you | 40 deg | 12 s |

The strongest entry still live is the operator's *focus*, and they attend to it
through a second cone that is independent of where the eyes are pointing. Where
the cone of vision and the cone of attention overlap, acquisition is faster:

- eyes dead on the focus: **35% off the time on target**
- the two cones just touching at one edge: **7.5%**
- no overlap, or the target outside the intersection: nothing

scaled linearly in between. A 35% boost removes 35% of the time. Recognition gets
the same boost at half strength (`ATT_REC_SHARE`), because spotting a figure and
swinging onto it are two halves of the same effect.

So the mechanic is a reward for acting on awareness: an operator who keeps looking
back at the corner the man disappeared behind gets on target a third faster when he
comes back. One who lets their attention go, or whose eyes are somewhere else, gets
almost nothing. Memories fade, faster in green, slower with ED02/ED07/ED08, slower
still with Tinnitus or a fixed scan pattern (BH20). Anyone who *watches* a figure
die drops the memory at once; the rest keep covering a man who is already dead.

With nothing else asking for the eyes, they come back to the remembered bearing for
about 0.6 s in every 1.2-2.2 s. That is enough to be looking the right way when it
matters, without ever locking the eyes up.

**Suppression.** Incoming fire you are not answering degrades everything at once.
A round passing within a metre, or striking cover within 2 m, raises `suppress`; it
fades at 0.55/s. Suppression widens the group (x1.6 at full), slows recognition
(x1.35), costs 15% of movement speed, knocks the sights off every time a burst
lands so the group has to be rebuilt, and past 0.55 an unsteady hand fires a stray
shot without being told to (WD09 stops that). Only the echelon's composure blunts
it. This is what makes covering fire worth anything: GD05 bounding overwatch, GD08
covering a reloader and WD07 controlled pairs all had no purpose before, because
there was nothing to suppress the enemy *with*.

**Wounds bleed.** Every round that gets through starts or adds to a bleed, by zone.
Blood lost is a clock of its own (at 1.0 the operator goes down) and pain gathers
stress. A wounded operator cannot sprint, and a downed one with blood already gone
has less than the five minutes.

**Doors are state.** Open, closed or locked. A shut leaf is a real obstacle: it
blocks sight, bullets and movement at the same time, and it has to be opened before
anyone goes through it. Opening takes 1.2 s; forcing a locked one takes 2.6 s with
an 85% + 0.15 x composure chance on the first attempt, and both are loud (6 m and
30 m). An element halted at a shut door works it with the number one man while the
rest cover it. Every map except **01 Lone Cabin** starts with every door open, so
the rest of the game is unchanged; map 01's single door starts shut, which is the
whole problem of that map.

## Teams of up to twenty

A team of more than five splits into elements (fire teams) of up to five, as balanced contiguous blocks of slots: 6 = 3+3, 7 = 4+3, 11 = 4+4+3, 20 = 5x4.

**Elements on the attack:**
- Each element picks its own room: the nearest uncleared room reachable through a door from outside or from a cleared room, by path length. No other element may have claimed it.
- A small room off the room just cleared goes first.
- Small rooms (10.5 m2 or less, not halls) are checks. Someone with PF10 looks in; if nobody on the team has PF10, they are skipped.
- An element with no room open to it waits a few metres behind the nearest element working a door.
- Once an element is clearing a corridor or stair hall, others can peel off it into the rooms along it.
- Rooms of 60 m2 or more, or big L-shaped rooms, are swept: a lattice of points about 5 m apart must each be seen from within 12 m.
- Entry runs are capped at 4.5 m. Rooms of 40 m2 or more seat five entrants.
- An element cut down to one joins the nearest element that still has people. An element wiped out releases its room.

**Inside each element**, the five-person rules from bible section 7.1 hold:
- Sectors: 110 degrees each for two or three, 360/N for four or five.
- Stacks: run along the wall, split across the door when the wall runs out, then form a second row.
- Rooms: each seats two to four entrants by floor area. Anyone else holds rear security at the stack.
- Bounding: odd and even slots bound as two halves.
- Hunting: followers take wedge slots.
- Callouts only turn the eyes of teammates within 25 m of the contact whose sector covers the bearing.
- Reload cover: only the nearest free teammate covers a reloader.

**Defence (Hold):** each squad consolidates in one room, one squad per room. It takes the room where most of its members already are, if that room is big enough. Members already inside keep their posts; the rest move to posts covering the room's doors (outside doors first) and windows. Default defender posts follow the same rule: B1-B5 in one room, B6-B10 in another, and so on, picking big, deep rooms with few windows.

## Endless Battle: Port Carrick

**The city.** A grid of 30 blocks between 18 m streets, about 1,026 x 608 m.
- Each block holds two rows of lots, back to back.
- Every lot is a full floor plan:
  - the eleven maps, turned to face their street;
  - a police station, a hospital and a school;
  - pocket parks and car parks.
- Lots are fenced at the sides and back and open on the sidewalk.
- Streets have sidewalks, parking lanes with parked cars (cover) and two traffic lanes.
- The blocks form twelve neighbourhoods and six police precincts.
- There are about 200 buildings: six police stations, three hospitals, six schools and the rest homes, shops, motels, warehouses, compounds and apartment blocks.

**The gangs.** Kilbride Crew (dots), Corvino Family (bands), Los Halcones (diagonal hatch) and Zarya Bratva (cross-hatch). The pattern on a member's shoulders is the pattern that hatches the gang's buildings on the map.
- Recruits are 70% untrained, 20% militia and 10% regulars ("soldiers").
- Each gang starts with a home neighbourhood holding a school, plus one next to it. The rest of the city is unclaimed.
- Squads of up to five hold one room each: one room in a house, up to three in the biggest buildings.
- **Capture:** a building changes hands after a minute of domination, meaning only one gang has living members inside. Police inside, or a rival, stop the clock. Only a gang member can take a building; police clearing a building does not change its owner. Police stations can't be taken.
- **Recruiting:**
  - The gang holding the most buildings in a neighbourhood dominates it by its share of them.
  - A gang recruits 0.15 x the sum of (its dominance x the number of buildings) for each neighbourhood it dominates, per minute.
  - Recruits appear at the hospitals and schools it holds; these spawn points can be captured.
  - A gang stops recruiting at its cap.
- **Pushes:** every two minutes, each gang sends everyone at its spawn points, beyond five kept there, out to the buildings on the edge of its territory, five to a room.
- **Expansions:** when the edge is full (or the gang is near its cap), its soldiers and militia form an assault team. The best ten are taken, and the garrisons they leave are refilled by the untrained.
  - The team attacks the nearest building it doesn't hold, unclaimed ones first.
  - It clears the building room by room, holds it through the minute's domination, and becomes its garrison.
- **Holding gangs don't shoot at each other.** Gang against gang only happens when one side is an assault team.

**The police.** Each precinct station holds:
- a QRF of ten special-operations officers with two vans;
- two patrol convoys, each two cars with two officers per car;
- a police ambulance with two police paramedics.

All vehicles drive on rails: the right-hand lane of every street, turning at intersections.
- **Reports:** gang gunfire is called in.
  - A report within 500 m of an original report from the last five minutes is a duplicate of that incident.
  - Anything else opens a new incident.
  - Incidents are answered in the order they came in, each by the nearest QRF at its station.
- **The QRF:**
  - boards its vans and drives to the scene;
  - searches the three buildings nearest the report point, nearest first (chosen when the report came in);
  - reports all clear, walks back to the vans and drives home.
- **Patrol convoys** drive their precinct at random. A convoy within earshot of gang gunfire stops, gets out and hunts the shooter. After a quiet spell it goes back to the cars.
- **Rules of engagement.** Police may fire on a gang member only:
  - once police have seen him targeting someone (the sighting goes out over the radio and lasts 90 s), or
  - while their QRF is clearing its search buildings.

  Holding gang members fire on police only once police have engaged their squad, and then for 45 s. Assault teams and anyone out hunting fire on police at will.
- **Retreat:** a gang member in combat who sees tactical police or the QRF makes a stress check and may break and run for the nearest building his gang holds. The check happens once per officer every 15 s. Rule 1 (the closest visible enemy within 10 m) still comes first.
- **Replacements:** every officer killed is replaced by a new hire at their station two minutes later. An officer who reaches the hospital alive is back on duty two minutes after that. Nobody is hired while on duty + recovering + hires due reaches the police cap (108 is full strength).

**Paramedics.**
- Every faction treats paramedics as friendly: nobody targets them, but bullets still hit them.
- Police paramedics drive out at once for any downed officer.
- The hospitals' ambulances (two each, two paramedics apiece) go in only after a QRF reports all clear. They collect every casualty within 120 m of the incident's report points, the living first.
- Two paramedics carry each casualty on a stretcher, up to two per ambulance, to the nearest hospital.
- The living are saved. The dead go to the morgue.
- Bodies nobody collects are cleared after 15 minutes.

**Watching it.**
- The camera:
  - Mouse wheel zooms from the whole city down to a single room.
  - Right- or middle-drag pans.
  - `Home` fits the city.
  - `Follow the fighting` (or `F`) keeps the camera on the busiest gunfight of the last 20 seconds.
- Left-click anyone to see their card in the panel. It shows:
  - name and rank;
  - echelon, form, strengths and weaknesses;
  - alert state and ammunition;
  - what they are doing and where.
- The panel shows:
  - each gang's strength, buildings, neighbourhoods, recruiting rate and current attack;
  - each QRF's state and its incident;
  - the patrols and the ambulances;
  - the feed of captures, pushes, assaults, reports and hires.
- What the map shows:
  - Far out, neighbourhoods show their dominant gang and its share.
  - Capture bars show who is taking a building.
  - Incidents pulse at the report point, and their search buildings are outlined.
- Speeds run 0.25x to 20x. A big city fight runs at roughly 2-3x real time on a typical desktop, and the panel shows the real rate.
- `Esc` returns to setup.

## Simplifications in this slice

- **The original house:** it is the 14 x 32 ft sketch scaled up to 5 x 13 m and turned on its side so two-person teams fit through it.
- **Doors:** every door opening is at least 0.9 m, the narrowest gap a body fits on the 0.25 m navigation grid. Doors default to open; only map 01 starts with one shut. Roll-up, dock and garage doors are open arches. A shut leaf blocks everything at once -- nothing passes part-way through a door.
- **Path exposure (PF02):** counts doors and windows only. It is precomputed per map (on a 1 m lattice for the big maps), not updated live.
- **Perception:** pairs more than 15 m apart re-trace sight every 0.2 s, and pairs more than 30 m apart every 0.4 s.
- **Stoppages:** rates are raised (4 per 1,000 rounds for the rifle, 3 for the pistol) so stoppage drills show up in a short test.
- **Ducked stance:** an extra stance, "ducked", is fully behind half cover, with the eye at 0.8 m. The bible's crouched head (1.00-1.25 m) would otherwise show over 0.9-1.1 m cover.
- **City:**
  - The city's lots are walkable only from their street front: fenced back gardens are scenery.
  - Vehicles are drawn but don't block anyone or stop bullets.
  - Nobody fires from a vehicle.
  - Gang members go everywhere on foot.
  - Away from any possible enemy, people skip perception and think every third tick; standing posts sleep until something comes near.
- **Out of scope:**
  - wall penetration;
  - grenades;
  - multiple floors (the apartment stairs are scenery);
  - civilians.

## Files

```
scripts/data/habits.gd    habits, traits, Experience, sound, echelons, weapons, individual variation,
                          the effect registry and all tuning constants
scripts/data/names.gd     the name bank (18 cultures)
scripts/sim/memory.gd     short-term memory and the cone of attention
scripts/city/*.gd         the city: generator, templates (police, hospital, school, parks), navigation, roads and vehicles, the director
scripts/city_main.gd      the Endless Battle scene
scripts/sim/geom.gd       obstacles, sight lines (with the low-cover rule), bullet traces with height
scripts/sim/level.gd      map base: walls from room rectangles, doors, room graph, posts for 20 a side
scripts/maps/*.gd         the eleven maps and the registry
scripts/sim/nav.gd        AStarGrid2D x4 (PF01/PF02 cost layers), cover spots, cached per map
scripts/sim/op.gd         operator state, stances and body zones
scripts/sim/world.gd      perception, tracking, hearing, aiming, shooting, wounds, stress, bad habits
scripts/sim/brain.gd      priorities P1-P8, elements, assault/hold/hunt, consolidation, habit hooks
scripts/view/*            floor plan, blood and residue, operators, overlays, the ledger, the city's layers
scripts/ui/ui.gd          setup and run panels
assets/svg/               all sprites, generated by tools/make_placeholders.py
tests/                    headless tests and an art gallery
```

## Headless tests

```
godot --headless --path . -s res://tests/maps_test.gd -- --run=1           # validate every map, then 5v5 and 20v20 on each
godot --headless --path . -s res://tests/stall_test.gd                     # six matchups per map; time-limit stalls and frozen-state watchdogs
godot --headless --path . -s res://tests/determinism_test.gd               # 27 seeded matches against the stored digests
godot --headless --path . -s res://tests/determinism_test.gd -- --write    # regenerate tests/fixtures/determinism.json
godot --headless --path . -s res://tests/habits_test.gd -- --strict        # habit coverage: registry vs call sites
godot --headless --path . -s res://tests/habits_test.gd -- --csv           # the same report, machine-readable
godot --headless --path . -s res://tests/playtest.gd -- --n=1 --cells=all --dump-json=/tmp/tv  # per-match JSON
godot --headless --path . -s res://tests/scale_playtest.gd -- --n=4        # Playtest 02: big fights on every map, CSV
godot --headless --path . -s res://tests/perf.gd -- --map=10 --t=40        # where the time goes in a 20v20 fight
godot --headless --path . -s res://tests/fuzz_test.gd -- --n=60            # random maps, sizes, habits, traits, postures
godot --headless --path . -s res://tests/sim_test.gd -- --n=12             # matchups by echelon (map 00, 2v2)
godot --headless --path . -s res://tests/sim_test.gd -- --ablation         # 40 habits vs none, same reflexes
godot --headless --path . -s res://tests/playtest.gd -- --n=40 --cells=all # Playtest 01 matrix (map 00), CSV rows
godot --headless --path . -s res://tests/city_test.gd -- --seed=3          # build the city, check every room is reachable
godot --headless --path . -s res://tests/city_sim.gd -- --seed=3 --min=10  # the endless battle headless, with timings
TR_STEP=1 godot --headless --path . -s res://tests/trace.gd -- --map=4 --a=sof --na=8 --b=militia --nb=8   # step-by-step trace
```

Every test takes `--map=N`. Playtest 01 results and recommended system improvements are in the second tab of the NPC CQB Bible.

Regenerate the art with `python3 tools/make_placeholders.py`. All art is original and project-owned.

Two checks run without Godot at all:

```
python3 tools/gdlint.py              # lint: indentation, bracket balance, ticker keys, habit coverage
python3 tools/verify_attention.py    # the cone of attention, checked against its spec
```

`gdlint.py` checks indentation, bracket balance, that every `ticker` key used is
declared in `op.gd`, that every habit id referenced exists, and that every declared
habit has a call site.

`verify_attention.py` re-implements `Memory.boost()` and asserts the properties the
mechanic was specified with: 35% with the two centre lines aligned, 7.5% where the
cones just touch, linear and monotonic between them, and zero outside either cone.
It reads the tuning constants out of `habits.gd` rather than hard-coding them, and it
greps `memory.gd` for the shape it ported — so if the formula is edited, the script
stops and says so instead of quietly testing a stale copy. Pass `--verbose` for the
curve.
