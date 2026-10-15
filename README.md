[README.md](https://github.com/user-attachments/files/33493454/README.md)
# The Violence - vertical slice

A test range for the NPC CQB Bible. One shotgun house in a fenced yard, two teams of one to five operators, one rifle and one pistol each. You place everyone, set every operator's good and bad habits, and press RUN; the fight resolves itself at up to 20x speed.

The plan is drawn as an architectural floor plan in greyscale. Operators start as clean plan symbols. Red appears only where the shooting has been: sprays, smears on walls, drip trails, pools under the fallen, stains on the figures.

## Run it

**Standalone:** double-click `TheViolence.exe`. It is the whole game in one file (Godot 4.7.2 runtime with the game data embedded); no Godot install needed. The first launch may show a Windows SmartScreen warning because the file is unsigned: choose "More info", then "Run anyway".

**From source:**
1. Install Godot 4.4 or newer (tested on 4.4.1 and 4.7.2, standard build, no addons).
2. Open `project.godot` in the Godot project manager (Import, select the folder).
3. Press F5. The first open imports the SVGs (a few seconds).

**Rebuild the standalone exe:** in Godot 4.7.2, install export templates (Editor > Manage Export Templates), then Project > Export > "Windows Desktop" > Export Project. The preset embeds the game data in the exe and writes `build/TheViolence.exe`. From a terminal: `godot --headless --path . --export-release "Windows Desktop" build/TheViolence.exe`.

## Controls

**Setup**
- Set each team's size (1-5 operators). The default is three special operations attacking five militia.
- Pick an operator (A1-A5, B1-B5), then left-click the plan to place them. Right-click sets facing.
- `Copy to team` gives every teammate the selected operator's echelon, habits and plates.
- Team posture: Assault (clear the house room by room), Hold (stay put), Hunt (go after contacts).
- Echelon dropdown plus `Apply preset` loads the bible's base stats, typical habits and plates. `Plates` sets 0-4 chest plate segments.
- Habit tabs toggle all 40 good habits and 20 bad habits. Hover any habit for what it does and what overrides it.
- `Seed` makes a fight repeatable. The same seed and configuration always replay the same fight.

**Run**
- Speed buttons 0.25x to 20x, or keys 1-7. Space pauses, Esc returns to setup.
- Overlay toggles: vision cones (shaded by eccentricity), recognition bars, aim traverse arcs with milliseconds left, planned paths.
- Mouse wheel zooms; middle-drag or right-drag pans; Home refits the view.
- `Rerun same seed` replays the fight exactly; `Rerun new seed` rolls a new one.

## What is simulated

Everything follows the NPC CQB Bible:

- **Plan plus height:** 2D geometry with analytic height. Half cover hides a ducked body, but a standing head shows over it. Windows pass sight between 0.9 and 2.1 m. Concealment (sofa, bed, hedges, plastic bins, porch rails, bookshelf) hides you but doesn't stop rounds. Cover (walls, car, counters, drums, woodpile, fridge, tub) does both.
- **Recognition:** slows with eccentricity in a 120 degree cone, then Fitts-law time on target, with separate precision and accuracy.
- **Damage:** a head hit kills from any weapon, and plates break one segment per hit.
- **Stress:** near misses, hits and casualties raise it. It widens dispersion, narrows the cone and switches on stress-triggered bad habits.
- **Rules 1 and 2:**
  - Rule 1: the closest visible enemy within 10 m overrides everything; fire until dry or the threat is eliminated.
  - Rule 2: a dry primary means switch to the pistol; when both are dry, break line of sight with cover before reloading.
- **Habits:** every good habit changes behaviour and gives the 0.5% speed bonus. Bad habits override the good habits they contradict, and never Rules 1 and 2.

Bad habits present on an operator:
- Stress habits switch on when stress x (1 - resistance) passes their threshold.
- Personality habits are always on.

## Teams of up to five

Group habits scale with team size (bible section 7.1):

- **Sectors:** 110 degrees each for two or three, 360/N for four or five. Holders own the arc they were placed facing.
- **Stacks:** run along the wall, split across the door when the wall runs out, then form a second row.
- **Rooms:** each seats two to four entrants by floor area. Anyone else holds rear security at the stack.
- **Bounding:** odd and even slots bound as two elements.
- **Hunting:** followers take wedge slots.
- **Callouts:** only turn eyes whose sector covers the bearing.
- **Reload cover:** only the nearest free teammate covers a reloader.

## Simplifications in this slice

- The house is the 14 x 32 ft sketch scaled up to 5 x 13 m and turned on its side so two-person teams fit through it.
- Path exposure (PF02) counts doors and windows only; it is precomputed, not updated live.
- Stoppage rates are raised (4 per 1,000 rounds for the rifle, 3 for the pistol) so stoppage drills show up in a short test.
- Wall penetration, grenades, doors that close, multiple floors and civilians are out of scope.
- An extra stance, "ducked", is fully behind half cover, with the eye at 0.8 m. The bible's crouched head (1.00-1.25 m) would otherwise show over 0.9-1.1 m cover.

## Files

```
scripts/data/habits.gd   habits, echelons, weapons (bible sections 2, 3, 5)
scripts/sim/geom.gd      obstacles, sight lines, bullet traces with height
scripts/sim/level.gd     the house, yard, doors, rooms, assault plans
scripts/sim/nav.gd       AStarGrid2D x4 (PF01/PF02 cost layers), cover spots
scripts/sim/op.gd        operator state, stances and body zones
scripts/sim/world.gd     perception, aiming, shooting, wounds, stress, bad habits
scripts/sim/brain.gd     priorities P1-P8, team assault/hold/hunt, habit hooks
scripts/view/*           floor plan, blood and residue, operators, overlays
scripts/ui/ui.gd         setup and run panels
assets/svg/              all sprites, generated by tools/make_placeholders.py
tests/                   headless tests and an art gallery
```

## Headless tests

```
godot --headless --path . -s res://tests/sim_test.gd -- --n=12        # matchups by echelon
godot --headless --path . -s res://tests/sim_test.gd -- --ablation    # 40 habits vs none, same reflexes
godot --headless --path . -s res://tests/fuzz_test.gd -- --n=120      # random habits, placements, postures
godot --headless --path . -s res://tests/sim_test.gd -- --verbose     # one match, full event log
godot --headless --path . -s res://tests/playtest.gd -- --n=40 --cells=all          # 38-cell playtest matrix, CSV rows
godot --headless --path . -s res://tests/playtest.gd -- --set=ablate --n=40         # which entry habit decides the kitchen
TR_STEP=1 godot --headless --path . -s res://tests/trace.gd -- --a=sof --na=3 --b=militia --nb=5   # step-by-step trace
```

Playtest 01 results and recommended system improvements are in the second tab of the NPC CQB Bible.

Regenerate the art with `python3 tools/make_placeholders.py`. All art is original and project-owned.
