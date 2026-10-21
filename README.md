# The Violence (v1.2.0)

You are the new chief of police in Port Carrick, a rust-belt city on the edge of collapse. You have forty weeks, an inherited department, a budget that does not cover it, and a contested election at the end.

Each week the board shows two or three situations: warrants, barricades, hostages, gang houses, public events. Pick one. Read the briefing, which is always confident and never complete. Choose who goes, split them into squads, give each squad its orders and its constraints, and press RUN. Then watch. Nothing you do during the operation changes what your officers do, except calling it off. They see, hear, recognise, judge, hesitate and shoot by their training, their habits and their nerve, and the debrief tells you what actually happened in the room.

Between operations you run the department: pay, hiring and firing, kit, training courses, wounds and recovery, and the cases that excessive force and civilian harm leave behind. The city keeps score. Each ward's trust moves with what you do in it; the press prints what it can prove; four allies (the chair of the council's budget committee, the police union, the community coalition and the district attorney) stand by you or walk away. Three candidates run for mayor, and on election night whoever wins decides what happens to you.

Every building is drawn as an architectural floor plan in greyscale. Red is the only colour, and it marks only where the plan touched a real room.

Two more ways to play sit on the title screen:
- **Test range:** eleven maps and two teams of one to thirty operators each. Set every operator's echelon, habits, traits and kit, place them, and watch the fight resolve itself at up to 20x.
- **Endless battle:** Port Carrick itself, a 1 km city of about 250 lots. Four gangs fight over its buildings, six police precincts answer the gunfire, and three hospitals send out ambulances. It never ends.

## Run it

**Windows:** unpack `TheViolence-v1.2.0-windows.7z` and double-click `TheViolence.exe`. It is the whole game in one file; nothing else is needed. The exe is unsigned, so the first launch may show a SmartScreen warning: choose "More info", then "Run anyway".

**Linux:** unpack `TheViolence-v1.2.0-linux.7z` and run `./TheViolence.x86_64`.

**From source:** install Godot 4.4 or newer (tested on 4.7.2), open `project.godot` and press F5. `Play.bat` / `play.sh` run the project with a Godot found beside it or on the PATH.

**Rebuild:** with the Godot 4.7.2 export templates installed, `godot --headless --path . --export-release "Windows Desktop" build/TheViolence.exe` (or `"Linux"` to `build/TheViolence.x86_64`).

Saves, the department and settings live in Godot's user folder (`%APPDATA%\Godot\app_userdata\The Violence` on Windows, `~/.local/share/godot/app_userdata/The Violence` on Linux). Each save keeps the previous one beside it as `.bak`.

## Your first campaign

1. **New campaign** on the title screen. The opening plays first (four short scenes; Space skips one, Esc skips them all; Prologue on the title plays them again). The outgoing chief leaves a note on the board for the first two weeks.
2. Pick a situation and read the briefing. The tips under it are what your people believe, not what is true.
3. Press **Suggest a plan** to see a reasonable one, then change what you disagree with: who goes, the squads, each squad's entry, objective and limits.
4. **RUN.** Watch at any speed, pause, rewind to look again. **Abort** is the only order you can give.
5. Read the debrief. The fog lifts and the replay shows what every officer saw. Then deal with the department: the wounded, the cases, the account.
6. **End the week.** The city, the press and the allies answer.

**How to play** on the title screen (or in the pause menu) covers all of it in eight short pages.

## Settings and sound

Settings (title screen or pause menu) are kept between sessions: fullscreen, master, effects and ambience volume, red ink (F2), gore (F3), the speed an operation starts at, and the first-weeks tips. Red ink off is the monochrome proof: everything still reads in grey. Gore off removes the stains and keeps the evidence markers. Neither changes the simulation.

All sound is synthesised. Shots are placed where they were fired; a shot nobody on your side can see plays muffled, as if through walls.

## The figures

Everyone on the plan is still a flat ink figure seen from directly above, but since 1.1 the figure moves: feet step as they walk and run, free arms swing, and the head turns to where they are looking before the body does. Aiming puts both hands on the weapon and follows its traverse; every round kicks it back into the shoulder with a paper-white flash at the muzzle. A reload cants the rifle in while the support hand fetches a fresh magazine; a stoppage gets its tap and rack; doors are opened, rammed or kicked; bangs are thrown; cuffs go on; dressings are worked. A hit staggers the figure; a fall plays out before it lies still, and the wounded on the floor still breathe. The injury is never drawn. The replay animates the same way.

## The maps (test range and operations)

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
| 11 | Civic Plaza | 64 x 46 m | an open square with a stage, a crowd and the buildings around it (public events) |

## Controls

**Everywhere**
- Esc steps back: out of a menu, or into the pause menu (Resume, How to play, Settings, Abort the operation or Main menu). In the test range it returns to setup.
- F2 red ink, F3 gore.

**Test range: setup**

- Pick a map. Set each team's size (1-20 operators) and posture:
  - Assault: clear the building room by room.
  - Hold: defend.
  - Hunt: go after contacts and sounds.
- Pick an operator (A1-A20, B1-B20), then left-click the plan to place them. Right-click sets facing. Every map has default posts for all forty.
- The Echelon dropdown plus `Apply preset` loads the bible's base stats, typical habits, plates and Experience. `Plates` sets 0-4 chest plate segments.
- The habit tabs toggle all 40 good habits and 20 bad habits. Hover any habit to see what it does and what overrides it.
- The Traits tab sets Experience (tier 1-5) and the hearing traits, Tinnitus and Elephant Ears.
- The Kit tab (new in v0.7.5) sets what the selected operator carries: primary, sidearm, sight, armour, helmet and tools. `Apply preset` also loads the echelon's kit.
- `Copy to team` gives every teammate the selected operator's echelon, habits, traits, plates and kit.
- `Seed` makes a fight repeatable. The same seed and configuration always replay the same fight.

- Each team's alert option sets how it starts: Yellow (weapons drawn) or Green (relaxed, for an ambush).
- `ENDLESS BATTLE` opens the city. It uses the seed above it. `Gang cap` and `Police cap` set the most members a gang can have and the police headcount at which hiring stops.

**Operation (section 3, new in v0.6)**
- `Civilians` (0-40) places that many civilians from the seed, about two in three indoors. They appear on the plan before you run.
- `Police rules` puts team A under police rules: every recognized person is judged before an officer may fire, suspects can give up, and officers cuff them.
- `Night` slows recognition and judgment and makes misjudgments more likely.
- `Team A: department` replaces team A with the officers you picked in the department (always under police rules). Team B becomes a gang house of four relaxed suspects, which you can change.
- `Body cameras` equips the department: what officers see is recorded as evidence.
- The doors list (new in v0.7.5) sets how the building is shut: Doors open, Inner doors shut, Outer doors locked, or Shut and locked. Team B (the occupants) holds the keys.
- `Department ...` opens the roster (see "The department" below).
- When the run ends, the panel shows the **incident record**: suspects, officers and civilians, rounds fired and rounds through walls, misjudgments, excessive force, and every finding with its evidence.

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
- The small pip beside each figure is their alert state, told apart by shape: a hollow ring (GREEN), a grey disc (YELLOW) or a red disc in a heavy ring (RED).
- F2 switches red ink off (the monochrome proof) and F3 switches gore off. The buttons sit at the bottom right of the plan. Neither changes the fight.

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
  - Presets: untrained 1, militia 1, Patrol 1, regular 2, police 3, special operations 4.
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
- **Every operator is an individual.** Each match rolls (a department officer was rolled once, at hire, instead):
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

## Teams of up to thirty

A team forms squads by the rules of v0.7.9 (see that section): 6 = 3+3, 7 = 4+3, 11 = 4+4+3, 20 = 4x5, 30 = 6x5. In the code a squad is an "element".

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
- Squads (formed by the same rules as everyone) hold one room each, layering into the rooms behind a small one: one room in a house, up to three in the biggest buildings.
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

## Known limits, and what comes after 1.0

- **The original house:** it is the 14 x 32 ft sketch scaled up to 5 x 13 m and turned on its side so two-person teams fit through it.
- **Doors:** every door opening is at least 0.9 m, the narrowest gap a body fits on the 0.25 m navigation grid. A door is open, shut or locked; nobody closes a door behind them or locks one during a fight. Roll-up, dock and garage doors are open arches.
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
- **The city campaign map (v0.10, after 1.0):** operations still happen in the eleven hand-built buildings, not on the city's lots. The Endless Battle has no civilians yet, and its police do not judge or arrest. All three come with the campaign map, which is the next planned update.
- **Not planned:**
  - fragmentation grenades;
  - multiple floors (the apartment stairs are scenery).

## Files

```
scripts/data/habits.gd    habits, traits, Experience, sound, echelons, weapons, individual variation
scripts/data/names.gd     the name bank (18 cultures)
scripts/data/equipment.gd the equipment database: weapons, sights, armour, the helmet, tools, kits, who may carry what
scripts/data/squads.gd    squad formation rules, cohesion and the Lion's lag
scripts/data/courses.gd   pay, costs, morale constants and the training courses (v0.8.5)
scripts/city/*.gd         the city: generator, templates (police, hospital, school, parks), navigation, roads and vehicles, the director
scripts/city_main.gd      the Endless Battle scene
scripts/sim/geom.gd       obstacles, sight lines (with the low-cover rule), bullet traces with height, door leaves
scripts/sim/level.gd      map base: walls from room rectangles, doors and their states, room graph, posts for 30 a side
scripts/maps/*.gd         the eleven maps and the registry
scripts/sim/nav.gd        AStarGrid2D x4 (PF01/PF02 cost layers), cover spots, cached per map
scripts/sim/op.gd         operator state, stances and body zones
scripts/sim/world.gd      perception, tracking, hearing, aiming, shooting, wounds, stress, bad habits
scripts/sim/brain.gd      priorities P1-P8, elements, assault/hold/hunt, consolidation, habit hooks, arrests
scripts/sim/civ_brain.gd  civilians: alarm, flee, hide, freeze, comply, film
scripts/sim/incident.gd   the incident record: every round, findings and their evidence
scripts/campaign/department.gd  persistent officers: the inherited roster, hiring, years of service, experience, wounds, files
scripts/campaign/campaign.gd    the 40-week campaign: the board, commitments, canvassing, the week's end, saving
scripts/campaign/situations.gd  wards, situation types, what is really inside, the briefing and its tips
scripts/campaign/orders.gd      objectives, constraints, order points by the leader's experience
scripts/campaign/operation.gd   civilians' placement; team A from the department; a planned operation built into a world
scripts/campaign/autoplan.gd    "Suggest a plan"
scripts/campaign/outcome.gd     the result, its score and each squad's objectives
scripts/campaign/politics.gd    wards' trust, the four allies, the candidates, delayed consequences, the press, the election (v0.9)
scripts/sim/recorder.gd   snapshots twice a second for rewind and the replay
scripts/view/*            floor plan, blood and residue, operators, overlays, the ledger, the city's layers,
                          the fog of war (fog.gd), the replay (replay_view.gd), the plan on the map (plan_marks.gd),
                          door states (doors_view.gd), the red-ink palette and toggles (ink.gd), the walls
                          layer above the blood (plan_walls.gd), the squads' actual routes (actual_route.gd)
scripts/ui/ui.gd          setup, run, debrief and department panels
scripts/ui/ops_ui.gd      operations: the board, roster, briefing, force, orders, the run and the debrief
scripts/ui/front.gd       the title screen, pause menu, settings, manual and credits (1.0)
scripts/ui/settings.gd    the player's settings, saved in user://settings.cfg (1.0)
scripts/view/sound.gd     sound: effects from the simulation's events, the interface, ambience (1.0)
scripts/ui/cutscene.gd    the opening's player (1.2)
cinematics/               the opening cutscenes' Remotion project (see cinematics/README.md); assets/cutscenes holds the videos
scripts/view/rig.gd       the animated figure: gait, hands, actions, recoil, hits and falls (1.1)
scripts/campaign/save_file.gd  safe saves: temporary file, check, swap, .bak fallback (1.0)
assets/sfx/               all sounds, synthesised by tools/make_sounds.py (1.0)
assets/svg/               all sprites, generated by tools/make_placeholders.py
tests/                    headless tests and an art gallery
```

## Headless tests

```
godot --headless --path . -s res://tests/maps_test.gd -- --run=1           # validate every map, then 5v5 and 20v20 on each
godot --headless --path . -s res://tests/stall_test.gd                     # six matchups per map; flags time-limit stalls
godot --headless --path . -s res://tests/determinism_test.gd               # 35 seeded cases against the fixture (--write to reset)
godot --headless --path . -s res://tests/habits_test.gd -- --strict        # every habit read somewhere, or a declared suspension
godot --headless --path . -s res://tests/brains_test.gd -- --n=8           # the four brains, squads, pairs, dispersal, cohesion: each on and off
godot --headless --path . -s res://tests/scale_playtest.gd -- --n=4        # Playtest 02: big fights on every map, CSV
godot --headless --path . -s res://tests/perf.gd -- --map=10 --t=40        # where the time goes in a 20v20 fight
godot --headless --path . -s res://tests/fuzz_test.gd -- --n=60            # random maps, sizes, habits, traits, postures
godot --headless --path . -s res://tests/sim_test.gd -- --n=12             # matchups by echelon (map 00, 2v2)
godot --headless --path . -s res://tests/sim_test.gd -- --ablation         # 40 habits vs none, same reflexes
godot --headless --path . -s res://tests/playtest.gd -- --n=40 --cells=all # Playtest 01 matrix (map 00), CSV rows
godot --headless --path . -s res://tests/city_test.gd -- --seed=3          # build the city, check every room is reachable
godot --headless --path . -s res://tests/city_sim.gd -- --seed=3 --min=10  # the endless battle headless, with timings
godot --headless --path . -s res://tests/civ_test.gd -- --n=40             # v0.6 gate: operations with civilians, Patrol vs police tactical
godot --headless --path . -s res://tests/dept_test.gd                      # v0.5 gate: save, load, carry-over, replay; v0.8.5 budget, courses, cases
xvfb-run godot --path . -s res://tests/rig_gallery.gd -- --out=g.png  # 1.1: every pose of the figure (--anim records it moving)
godot --headless --path . -s res://tests/save_test.gd                      # 1.0: safe saves and the .bak fallback
godot --headless --path . -s res://tests/politics_test.gd                  # v0.9 gate: stories, allies, the DA, the election, saves
godot --headless --path . -s res://tests/balance_test.gd -- --gate --n=20   # v0.8.5: equal regulars' assault on a held house, 30-50% attacker wins
godot --headless --path . -s res://tests/lethality_test.gd -- --type=gang  # v0.9.1 diagnostic: how officers fall in planned operations
godot --headless --path . -s res://tests/duel_probe.gd                     # v0.9.1 diagnostic: how each side falls in an assault
godot --headless --path . -s res://tests/orders_test.gd -- --n=8           # v0.7 gate: every order, with and without it
godot --headless --path . -s res://tests/equip_test.gd -- --n=16           # v0.7.5 gate: every item, with and without it
godot --headless --path . -s res://tests/op_test.gd                        # a campaign played by "Suggest a plan", week by week
godot --headless --path . -s res://tests/hold_test.gd -- --n=30            # the hold-mode habits on and off, by matchup
godot --headless --path . -s res://tests/hold_test.gd -- --ablate=drop --n=30   # all hold habits but one, one at a time
TR_STEP=1 godot --headless --path . -s res://tests/trace.gd -- --map=4 --a=sof --na=8 --b=militia --nb=8   # step-by-step trace
```

Every test takes `--map=N`. Playtest 01 results and recommended system improvements are in the second tab of the NPC CQB Bible.

Rebuild the trailers with `python3 tools/make_ads.py OUT_DIR` (xvfb-run, Godot and ffmpeg; set AD_CAMPAIGN to a campaign saved by `tests/op_test.gd -- --save` for a played election night).

Regenerate the art with `python3 tools/make_placeholders.py` and the sounds with `python3 tools/make_sounds.py` (numpy and scipy). All art and sound is original and project-owned.

## Credits

Design, code, art and sound: Ambidgen, with Claude (Anthropic).
Built with Godot Engine 4.7 (MIT licence, godotengine.org).
All art is generated by tools/make_placeholders.py and all sound by tools/make_sounds.py: no third-party assets.
The version history is in CHANGELOG.md.
