# Playtest — campaign, 2026-10-28

**Tree:** `The-Violence-27-Oct-26-main` (runtime and export metadata still say 1.2.1) · **Engine:** official Godot 4.7.2 Linux build · **Companion:** [`EARLY_ACCESS_ROADMAP.md`](EARLY_ACCESS_ROADMAP.md). This report adds to, and does not replace, `PLAYTEST_2026-10-28.md` (the Web-runtime pass of the same day).

## What was exercised, and what was not

**Done**
- **Three 40-week roguelike campaigns** headless (`tests/op_test.gd --weeks=40 --rogue --chief=sensible`): seed **1001** with `--hire --train`; seed **2002** with no hiring or training; seed **3003** with `--hire`. The harness answers the desk (drafts, offers, events) at random and runs every call with the suggested plan. Logs in `../tests/results/playtest-2026-10-28-campaign/logs/`.
- **A rendered click-through** at 1600×900 (Xvfb, software GL), seed **410255**, driving real buttons: title → *New run* → week-1 board → inheritance → procurement → *Brief and plan* → Force and Orders tabs → live operation (20×) → debrief → back to the board → end week → week-2 board with a training-program draft and an event → Roster, Budget, Internal Affairs, City Hall. Screenshots in `../tests/results/playtest-2026-10-28-campaign/screens/`; the driver is `../tests/results/playtest-2026-10-28-campaign/logs/ui_walk.gd`.
- **Probes:** quiet-rally crowd probe (`event_probe.gd`, 8 seeds at the roster's natural trauma and at trauma 14); a new 12-seed duplicate-procurement probe (`../tests/results/playtest-2026-10-28-campaign/logs/dup_probe.gd`); `rogue_test.gd` (0 failures); `determinism_test.gd --verbose`; `_check.gd` (125 scripts, 0 failed).

**Not done / limits.** No Windows run, no audio heard (dummy audio device), no gamepad, no human wall-clock timing (software GL, two shared cores). The 10 cutscene `.ogv` files were left out of my working copy, so cutscene playback was not exercised (the game skips a missing short without hanging). The harness chief is not a human: it always runs the suggested plan, never edits orders, and the desk is answered at random, so these are *warnings to investigate*, not a prediction of a careful player's run. Three seeds is a small sample.

## Campaign results (40 weeks)

| | Seed 1001, hire + train | Seed 2002, minimal | Seed 3003, hire |
|---|---|---|---|
| Election | **Okonjo-Vale 54% — chief fired** | Kettering 35% — chief kept | Kettering 41% — chief kept |
| Operations won / failed | 41 / 11 | 25 / 10 | 29 / 10 |
| Situations left unattended | 48 | **80** | 69 |
| Officers killed | **16** | 13 | 13 |
| Per operation: killed / down | 0.21 / 0.36 | 0.25 / 0.53 | 0.23 / 0.60 |
| Findings / lawsuits settled / stories | 156 / 10 / 13 | 65 / 7 / 8 | 106 / 5 / 8 |
| Fit officers (of 20) | 20 → 13 (wk 5) → 12 (wk 10) → 15 (wk 30) → **5** (wk 40) | 19 → 14 (wk 5) → **5** (wk 10), 4–8 thereafter | 20 → 19 (wk 5) → **7** (wk 10) → **2** at worst (wk 22) → 8 |
| Account | $23.9K → **−$7.9K by week 5**; −$95K wk 30; **−$491K** wk 40 | $15K–$67K to week 22, then climbs to **$369K** | $28.8K (wk 5) → **−$49.9K** (wk 10) → −$114K (wk 30) → $8K |
| Week-end snapshots below $0 | **24 of 40** | 0 | **24 of 40** |
| Ally-loss messages (week) | Duff (12), Mbeki-Shaw (18), Varga (25); all four marked lost by wk 27 | Mbeki-Shaw (4), Duff (5), Varga (13); all four marked lost by wk 40 | Mbeki-Shaw (3), Rourke (12), Varga (20); all four marked lost by wk 38 |
| Allies at 40 | **0 of 4** | **0 of 4** | **0 of 4** |

(The harness's own "deficit weeks" line reads 15 and 21 for the two hiring runs; the 24 above counts the printed week-end account lines below $0.)

**Reading.** Every run ends with a department of 2–8 fit officers, a dead pile of 13–16, and no allies. Hiring runs fall into debt by weeks 5–10 (the game then freezes hiring, training and kit — the very things that would recover it); the run that did not hire never goes negative but has nothing to spend $369K on and cannot field a team (80 calls unattended). Allies, once lost, are never won back (win-back threshold 40, never reached). And two of the three wrecked departments **kept their chief** under Kettering: the ending text is "Kettering keeps you. The equipment budget doubles." That is thematically sharp, but with a run score that adds +60 for keeping the office, it means ruin can out-score restraint. These are the same shapes the 27 Oct report recorded (unattended 55–62, killed 11–12, 5–7 fit, allies gone by week 20): the 27 Oct recommendations 1–4 and 8 are still open.

## Findings

### 1. Crowd cliff is still in the simulation (reproduced)

`event_probe.gd`, two officers on post at a quiet public event, morale 60, **no attack**, 8 seeds (5000, 5017 … 5119):

| Roster trauma | Events with civilian deaths | Civilians killed | Police rounds hitting civilians | Police shots | Misjudgments |
|---|---|---|---|---|---|
| natural (`--trauma=0`, not forced to zero) | **3 of 8** | 6 | 11 | 51 | 3 |
| floor of 14 | **8 of 8** | **52** (up to 14 in one event, seed 5119) | 90 | 224 | 46 |

`civ_hit_police` is a round count; `civ_killed` counts people. The 27 Oct mitigation (Suggest-a-plan keeps trauma 12+ off crowd duty) does not fix the sim, and the natural-trauma row shows the failure without any forcing (how fast a real roster's trauma climbs over a run was not measured here). Logs: `../tests/results/playtest-2026-10-28-campaign/logs/crowd-trauma-0.log`, `../tests/results/playtest-2026-10-28-campaign/logs/crowd-trauma-14.log`.

### 2. Duplicate procurement charge (reproduced, and common)

With a fresh legacy, `../tests/results/playtest-2026-10-28-campaign/logs/dup_probe.gd` dealt each of seeds 1–12 and tried every inheritance × contract pair. **Six of twelve seeds (1, 3, 5, 6, 11, 12) offer Plate carriers in both the inheritance and the procurement draft;** choosing *Plate carriers on day one* and then signing the plate contract charges **$6,000** and adds nothing to the armoury (`contracts` becomes `["plates","plates"]`). The seed used in the rendered walk (410255) dealt SMG instead, which is why the walk's account went $25,000 → $20,000 for a real purchase. Log: `../tests/results/playtest-2026-10-28-campaign/logs/procurement-duplicate-12-seeds.log`.

### 3. Stale tactical map behind every management screen except the board

The board draws the Port Carrick ward map with numbered call pins, and it is good. But the **inheritance and procurement drafts, Roster, Budget, Internal Affairs and City Hall** all sit over the *last operation's* tactical map: a Test Range house in week 1, the Corner Store after the first op (still showing its fog and red "FILED / NOT RESOLVED" stamps). See `../tests/results/playtest-2026-10-28-campaign/screens/desk-inheritance-stale-map.jpg`, `roster-stale-map.jpg`, `budget-stale-map.jpg`, `city-hall-stale-map.jpg`. It looks like a bug, and it wastes about 70% of the screen at the moments a new player is deciding what to do.

### 4. First-hour clarity: good bones, small text

Good: the first-operation guide ("1/4 Briefing … Next: Force"), the briefing separating *confirmed* from *estimate with confidence*, "readiness is a planning index, not a win chance", the debrief's itemised score arithmetic, the Ledger, and the fact that opening a briefing no longer spends money (account change **$0**; the $805 is overtime, "$0 to restock").

Needs work: at 1600×900 most management text is 10–12 px; the first thing a new player tries (*Brief and plan* on call 1) is disabled with its reason only in a hover tooltip; a rendered operation at the default 2× would take minutes (see 5).

### 5. Rally pacing

All 17–23 public events per run are **900 simulated seconds** ("Passed quietly 100 — nothing happened"). At the default speed of 2× that is **7.5 minutes** per rally; `adaptive_speed` (fast-forward on quiet) exists and defaults to off. In this sandbox one rally cost 28–52 s of CPU headless. Estimate (arithmetic, not measured): a full run with planning is several hours; rallies are a large share of it.

### 6. Determinism fixture is stale

`determinism_test.gd --verbose` on native Linux: **22 of 35 cases changed**, with divergent timings and hit counts (e.g. op1001 W1-1 barricade: t 170.0 → 323.8, shots 11 → 10). The 28 Oct Web-runtime report also saw 22 of 35, so this is a fixture that predates simulation changes, not platform noise. Do not rebaseline until the crowd and economy fixes land.

### 7. Things that work

`rogue_test.gd`: 0 failures (seeded desk reproducibility, save round-trip, armoury gating, programs teaching the whole force, four 40-week random-desk runs to the election). `_check.gd`: 125 scripts compile, exits non-zero on failure. The week-2 desk (a program draft and an event, both with costs and effects shown) behaved. The briefing, force and debrief screens are legible at 1600×900. The crayon art and title page are strong.

## Reproduce

```sh
GODOT=/path/to/godot-4.7.2
$GODOT --headless --path . --import
$GODOT --headless --path . -s res://tests/op_test.gd -- --weeks=40 --seed=1001 --chief=sensible --rogue --hire --train
$GODOT --headless --path . -s res://tests/op_test.gd -- --weeks=40 --seed=2002 --chief=sensible --rogue
$GODOT --headless --path . -s res://tests/op_test.gd -- --weeks=40 --seed=3003 --chief=sensible --rogue --hire
$GODOT --headless --path . -s res://tests/event_probe.gd -- --trauma=0  --n=8
$GODOT --headless --path . -s res://tests/event_probe.gd -- --trauma=14 --n=8
$GODOT --headless --path . -s res://tests/dup_probe.gd        # copy ../tests/results/playtest-2026-10-28-campaign/logs/dup_probe.gd into tests/
# rendered walk (Linux, needs a display):
xvfb-run -s "-screen 0 1600x900x24" $GODOT --path . --rendering-driver opengl3 --resolution 1600x900 -s res://ui_walk.gd -- --out=/tmp/shots --seed=410255
```

Use a separate `XDG_DATA_HOME` per concurrent run so they do not share `user://`. The port-carrick data file (`port-carrick/city.json`) must be in the project or call sites fall back with a warning.
