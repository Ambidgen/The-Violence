# The Violence

**The Violence** is a Godot 4 police-command and close-quarters autobattler set in Port Carrick. You are the chief: choose which situations to answer, assign officers, write their orders, and watch the operation resolve hands-off. The campaign lasts forty weeks and ends with an election.

This checkout contains the game source, maps, campaign systems, cutscenes, and headless test harnesses. It is not a design document or a prose story.

## Run the game

1. Install **Godot 4.4 or newer**. The project declares 4.4 and 4.7 compatibility; 4.7.2 is the primary target and 4.4.1 the compatibility target. See the root README and test results for current verification, rather than assuming every version or platform has been tested.
2. Import `project.godot` in the Godot editor.
3. Press **F5** to run the project (`scenes/main.tscn`), or use `./play.sh` on Linux.

The project uses the compatibility renderer. The title screen offers three ways to play:

- **New run / Continue:** the forty-week story as a roguelike run. Each run has its own seed, inheritance, procurement contracts, training programs, offers and events; there is one ironman-style save slot, saved after operations, desk decisions and weeks, and finished runs are kept in a legacy file that unlocks starting doctrines.
- **Test range:** a configurable sandbox for two teams, officers, habits, equipment, and the twelve tactical maps.

The shipped Ogg Theora opening and short interstitials are optional. Shorts can be skipped with **Space**, **Enter**, **Escape**, a mouse click, or the on-screen **Skip** button. Missing video files do not block campaign flow.

## The campaign loop

Each week the operations board deals warrants, crew-house raids, barricaded suspects, hostage takings, and public events. Officers committed to one situation or to canvassing cannot be sent to another that week. Unanswered situations are recorded and can have consequences.

For a situation, work through:

1. **Briefing:** read confirmed facts, estimates, confidence, tips, time pressure, and the readiness range. The range is a planning index built from public intelligence and assigned force; it is **not a win probability**. Canvassing buys two tips but commits an officer for the week.
2. **Force:** form up to five squads of six, assign officers, and buy or return equipment within the budget and training restrictions. **Suggest a plan** is an editable starting point and does not buy kit on its own; Veteran chief mode removes it.
3. **Orders:** choose objectives and constraints. Order points depend on squad leadership and experience. The plan is a starting intention, not a script that guarantees compliance.
4. **Run:** watch the operation under fog of war. Officers judge, perceive, react, and fight using their training, habits, stress, and orders. You do not steer individual officers.
5. **Debrief:** read the itemized score arithmetic, officer and civilian outcomes, findings, and department consequences. Click any timeline event to seek the replay to that moment.

### Port Carrick on the board

The overview shows the official model's ward shapes, river, harbour basins and major streets. Numbers correspond to the week's calls; hover over a pin to see its canonical name and address. The six trust indicators use the same ward order as existing saves. The briefing names the official site and makes clear that the tactical layout is **schematic**. Fourteen compatible sites can be selected for recurring calls; other sites are not silently substituted. The generator itself is not needed to play.

Old saved boards retain their original locations and are marked unlocated when they have no canonical coordinates; the game does not retroactively invent them. A missing or invalid city resource produces a warning and an unlocated call without ward-specific political effects. New boards snapshot the canonical site metadata, so an already-saved call remains stable if the city is later regenerated. See [`../port-carrick/README.md`](../port-carrick/README.md) for the site-to-layout table and maintenance instructions.

### Character appearances

The animated top-down roster has patrol uniforms, SWAT-style tactical uniforms, public-order/riot uniforms, and five distinct criminal clothing models. Ordinary officers use patrol; police-tactical or quick-response units and officers with plates or a helmet use SWAT outside public events; event officers use the riot look. Criminal looks are stable for an operation and are selected without consuming gameplay randomness. The four city gangs each have a distinct clothing family, and civilians and medics retain their own looks.

These appearances are **cosmetic**: a soft cap or padded-looking uniform does not add protection. Actual armour, helmets, shields and other equipment come from the officer's kit; the riot visor appears only over an equipped helmet. The debrief replay retains the look and equipment, and a concealed attacker remains dressed as a civilian until the attack is revealed. These are 2D animated sprites, not 3D models.

The first operation includes an optional four-step guide covering Briefing, Force, Orders, and Debrief. It can be skipped and is controlled by the first-weeks tips setting.

After an operation, review **Internal affairs**. Cases are sorted by severity and evidence, with filters for grave cases, video, and cases approaching lapse. Every case still requires its own decision: clear, retrain, suspend, or dismiss. The weekly board includes a triage summary.

## Controls and playback

| Input | Action |
| --- | --- |
| Mouse wheel | Zoom |
| Middle- or right-drag | Pan |
| Home | Refit the view |
| Space | Pause/resume an operation; skip a short when one is playing |
| 1–7 | Select operation speed in the test range/run controls |
| F2 | Toggle red ink / monochrome presentation |
| F3 | Toggle gore; evidence markers remain |
| Escape | Open the menu or go back one front-end screen |

The operation speed buttons provide the available playback rates. The rewind slider is a viewing tool: it never rolls back the simulation. Replay is available from the debrief.

**Contact-aware fast-forward** is an optional Settings toggle. At speeds above 1×, contact, casualties, and important radio events temporarily return playback to 1× for a short readable interval, then resume the selected speed after quiet. This changes presentation timing only, not simulation decisions or deterministic results.

Other settings include fullscreen, volume buses, red ink, gore, first-weeks tips, opening/rare campaign shorts, and Veteran chief mode. Presentation settings do not alter the simulation.

## The desk (1.3: story mode as a roguelike)

Every story is a run. The **Desk** card on the board holds what the run asks of you:

- **Inheritance** (week 1): one of three starting doctrines; finished runs unlock more.
- **Procurement** (every four weeks): the armoury starts with patrol stock; sign one of
  three contracts (or pass for surplus cash). Locked items cannot be issued anywhere.
- **Training programs** (every six weeks): one habit taught to the whole force, then to
  every hire through the academy.
- **Offers** from candidates, allies, reporters and community leaders; they lapse at the
  end of the week.
- **Events** with two to four responses, answered before the week can end.

Election night prints a run score and records the run in `user://legacy.json`.
`docs/ROGUELIKE_PLAN.md` is the design; `scripts/campaign/rogue.gd` is the whole layer;
`tests/rogue_test.gd` is its gate. Endless Battle has been removed.

## Saves and version

Campaign and settings data live under Godot's `user://` directory, which is pinned to one fixed folder — `TheViolence`, from `application/config/custom_user_dir_name` — so the path never moves when the project is renamed (and is the path a cloud-save service would use). On launch, `Settings.migrate()` copies saves, settings and the legacy file forward from the folders earlier builds wrote (`The Violence`, and `The Violence - Vertical Slice` before that), never over a file that already exists. The campaign save is versioned and older compatible saves are accepted. A corrupt or semantically invalid primary save is checked against the `.bak` copy; when recovery succeeds, the first save preserves the good backup instead of replacing it with the corrupt primary. A save from a newer, unsupported version is not automatically downgraded or overwritten. The title screen warns if a save cannot be loaded and asks for confirmation before starting a new run over it. Keep independent backups, and do not run multiple game instances against the same save slot.

The canonical runtime version is `scripts/version.gd` (`Version.VALUE`, and `Version.CHANNEL` for the title's label). The line is 1.3.x for Early Access and 2.0 for the 1.0 release. After changing it, synchronize Godot's metadata with:

```sh
python3 tools/sync_version.py
```

Commit `scripts/version.gd`, `project.godot`, and `export_presets.cfg` together. The improvement regression suite checks that these values agree.

## Headless checks

One command runs them in tiers and keeps a log per suite:

```sh
tools/run_tests.sh --list      # see suites and timeouts without running Godot
tools/run_tests.sh --check     # load every script
tools/run_tests.sh --quick     # the gates a commit should pass (default)
tools/run_tests.sh --full      # + determinism, simulation, campaign and soak suites
tools/run_tests.sh --soak      # + the asserted balance matrix (long)
GODOT=/path/to/godot tools/run_tests.sh --full
```

The runner exits nonzero for a failure, script or engine error, or timeout and writes `build/test-logs/<suite>.log`. Use `JOBS=2` to run in parallel or `TIMEOUT_SCALE=2` to allow more time under load; both values must be positive integers (`TIMEOUT_SCALE` defaults to 2 on two cores or fewer). Every harness sets its own exit code; `determinism_test` is a known failure (`KNOWN`) until its fixture is rebaselined. CI lives in `.github/workflows/ci.yml`. Run the suites individually when debugging, otherwise prefer the runner. Its own Python regression tests run with `python3 -m unittest discover -s tests -p test_runner.py -v`.

Run from the repository root with a Godot executable on your PATH (or substitute its absolute path):

```sh
godot --headless --path . -s res://tests/_check.gd
godot --headless --path . -s res://tests/city_integration_test.gd
godot --headless --path . -s res://tests/improvements_test.gd
godot --headless --path . -s res://tests/rogue_test.gd
godot --headless --path . -s res://tests/ops_ui_test.gd
godot --headless --path . -s res://tests/dept_test.gd
godot --headless --path . -s res://tests/orders_test.gd
godot --headless --path . -s res://tests/determinism_test.gd -- --verbose
godot --headless --path . -s res://tests/op_test.gd -- --weeks=40 --chief=sensible --rogue
godot --headless --path . -s res://tests/godot472_test.gd
```

A determinism run fails for changed, missing **or new** fixture cases. The official city integration intentionally changes campaign scenarios: compare the case names, outcomes and diffs before regenerating with `godot --headless --path . -s res://tests/determinism_test.gd -- --write`. Never use `--write` merely to make an unexplained failure disappear.

`tests/godot472_test.gd` is the Godot 4.7.2 compatibility regression: it feeds
the save path deliberately malformed-but-parseable data, checks the navigator's
unbuilt fallback, and re-checks that the version metadata is in sync.

### Static checks without an engine

`tools/gd47_check.py` is the audit used for the 4.7.2 pass. It needs no Godot
binary, so it runs in CI or in a sandbox with no engine:

```sh
python3 tools/gd47_check.py            # scripts/, tests/, tools/
python3 tools/gd47_check.py scripts/   # or one subtree
python3 tools/gd_arity_check.py        # names and call arity; both checks, no engine
```

It checks bracket balance (with strings and comments stripped), duplicate class
members, tab-only indentation, `:=` inference from an untyped receiver — the
construct 4.7 rejects — the GDScript-breaking APIs from 4.4 to 4.7, and
statements that escaped into class scope. It is a linter, not a parser: confirm
anything it reports with `tests/_check.gd`.

`tools/gd_arity_check.py` checks the things a parser cannot: a call with more arguments
than the function takes (in this file, or on a `const X = preload("...")` alias), a
SCREAMING_CASE name used but never declared (in this file, its `extends` chain, a preload,
or Godot's globals), and a `+` between a string literal and a number. All three parse and
all three fail the moment the engine loads the script — which is how `politics.gd` came to
be unloadable for a whole cycle on 2026-11-02 while every static check was green.

Some harnesses accept additional options documented in their script headers. Headless execution validates logic and scene automation; it is not a substitute for visual or manual playtesting.

## Source map

- `scripts/main.gd`: application flow, operation playback, replay, and cutscene integration.
- `scripts/ui/ops_ui.gd`: board, planner, debrief, IA, and first-operation guide.
- `scripts/campaign/`: city adapter, situations, planning, public-intel readiness, outcomes, department, politics, and saves.
- `scripts/ui/city_map.gd`: city overview and canonical board pins.
- `scripts/sim/`: deterministic world, operators, navigation, combat, recorder, and pacing classifiers.
- `scripts/view/`: plan, actors, overlays, decals, replay, and presentation settings.
- `tests/`: engine-backed unit, regression, determinism, balance, and soak harnesses.

See `CHANGELOG.md` for historical release notes and the in-game **How to play** pages for the full mechanics reference.
