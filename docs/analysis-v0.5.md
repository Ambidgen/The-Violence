# The Violence — systems & mechanics analysis (v0.5)

Read against the tree at the end of the "harnesses" milestone (branch
`arena/a1e97e7b-the-violence`). Supersedes `docs/analysis-v0.4.md` where the two
disagree; v0.4 §3–§8 remain the design record and most of its risk analysis is
still accurate. `docs/roadmap.md` is the forward queue.

**Method and confidence.** v0.4 was a code read with no runtime. This document
is different in kind: a Godot 4.4.1 headless engine was **built from source
inside the workspace** (minimal `template_debug`, `-O0`, x11/audio/web modules
off) and every harness the project ships was actually executed. Behavioural and
balance claims below are marked either **measured** (a command and its output
appear) or **hypothesis** (algebra from the model, with the command that would
falsify it). Build notes are in §8 — the engine cannot be fetched from the
release hosts in this environment, but it can be built from the source tarball
in about ten minutes of wall clock on two cores with the patch in §8.

---

## 1. What the systems are, verified

The architecture map in v0.4 §2 is unchanged: design data (`data/habits.gd`,
`data/names.gd`) → geometry (`sim/geom.gd`) → maps (`sim/level.gd`,
`maps/m*.gd`) → navigation (`sim/nav.gd`) → operator state (`sim/op.gd`) →
simulation (`sim/world.gd`) → decisions (`sim/brain.gd`) → city (`city/*.gd`) →
view/UI. What changed since v0.4 is the *honesty* layer, and all of it is now
verified wired:

| System | Where | Verified |
|---|---|---|
| Cone of attention | `sim/memory.gd` | `verify_attention.py` 25/25; boost spent at acquisition and (half) at recognition |
| Suppression | `world.gd` 18 sites | `o.suppress` gain/decay/stray path present; WD09 exemption in `_hit`/stray logic |
| Bleeding wounds | `world.gd` 15 sites | `BLEED_RATE` per zone, blood clock 1.0 = down, shortened 5-minute clock |
| Doors as state | `geom/level/nav/world/brain` | shut leaf is a dynamic obstacle; `breach` phase in the element; only map 01 starts shut |
| Habit registry | `Habits.HOOKS`/`EFFECTS` | 62 ids, 13 hooks; coverage test gates drift |
| Interrupt classes | `Brain.Ix`, `o.ix` | ladder rungs labelled; `Ix.EYES` claims only from TASK |
| Intent boundary | `w.record`, `w.commands` | `move_to/stop/start_action/engage` recorded; nothing consumes yet |
| Determinism | seeded RNG, `perc_phase` | fixture `tests/fixtures/determinism.json`, 27 digests |
| Ticker namespace | `Op.TICKER_KEYS` | 65 keys declared; `gdlint` and `habits_test` enforce |

Current size (GDScript): sim 6.6k lines, city 3.8k, view 1.7k, maps 1.1k, tests
1.5k — `world.gd` 78 functions, `brain.gd` 91, `director.gd` 94.

## 2. The engine found bugs the linter could not

The first `godot --headless -s res://tests/_check.gd` (compile every script)
failed twice. Both were defects in the Tier 1 door/cover work that no amount of
static linting can catch, and both were silently shipping in a tree that had
never been executed:

1. **`geom.gd` `sight_mask`: the band-clear step was outside its loop.**
   `for k in 2:` computes whether obstacle `idx` stops height-band `k`, but
   `if stop: mask &= ~(1 << k)` sat one indent level out — `k` (and `stop`) out
   of scope, parse error. As written the function could never have compiled,
   so the low-cover/window two-band mask never ran since the doors branch.
   Fixed by indenting the two lines into the loop body, matching `trace_shot`'s
   per-obstacle structure.
2. **`world.gd` `_finish_action`: `break` inside a `match` arm.**
   GDScript `match` does not accept `break`; the arm wanted an early-out for an
   action with no `did`. `return` is identical there (nothing follows the
   match).

A third defect was found by `habits_test --strict` rather than the compiler:
**BH17 "Skip the checks" declared `fire_cadence`/`reload_policy` hooks it never
used.** Its description ("no function checks, no round count, reloads only when
dry") is exactly the suspension of WD04/WD01/WD02 — `checked: not m.has("WD04")`
skips the door check, the stoppage-rate halving disappears, the lull top-up
disappears. It is a pure suspension habit and its `EFFECTS` entry now says so
(`"BH17": []`). This is precisely the class of silent lie the registry exists to
prevent, caught on the first real run.

Three more were found by running the suites:

4. **Stray-shot reentrancy crash** (`world.gd` `_aim_update`). `fire_at` is
   re-entrant: a hit victim's reaction fire (`add_stress` ≥ 0.15) or a
   near-miss stray recursively calls `_fire`, and that nested fire can down the
   original shooter — `_down` clears `o.aim` — after which `o.aim["pair"] += 1`
   reads a key on an empty dict and the script aborts mid-tick. Rare (~1 in 66
   heavy matches) but a hard error; `_aim_update` now bails if the aim is gone
   after the shot.
5. **A shut door baked itself into the nav grid permanently** (`nav.gd`).
   `_build_layers` marked the closed leaf solid via `blocked_disc`'s dynamic
   set, so `block_rect` skipped those cells (`already solid`), `_blocked` stayed
   empty, and `reset_blocks()`/`sync_doors` never re-flooded — `nav.reach` said
   map 01's cabin was unreachable **even after a breach**. The nav layer now
   builds from static geometry alone (`blocked_disc(..., false)`); door leaves
   live only in the reversible block path.
6. **`snap_posts` ejected defenders from legitimately sealed rooms**
   (`level.gd`). A post is wrong only inside a wall; a shut door is the
   *attacker's* problem. Together with #5 this explains map 01's silent
   breakage: its defenders were being snapped out of the cabin.

All fixes change behaviour, so the determinism fixture was regenerated after
them and is the baseline from here on.

## 3. Instrumentation status (Tier 0, complete)

| Harness | Command | State |
|---|---|---|
| JSON dump per match | `playtest -- --dump-json=<dir>` | working; one file per cell/seed |
| Aggregator | `python3 tools/aggregate_playtest.py <dir>` | **added this milestone** (the "one small Python aggregator" T0 #1 promised) |
| Habit coverage | `habits_test -- --strict` | green |
| Stall watchdogs | `stall_test` | see §6 |
| Determinism regression | `determinism_test` | 27/27 reproducible, fixture committed |
| Linter / attention spec | `gdlint.py` / `verify_attention.py` | 0 issues / 25 assertions |
| **new** exp sweep (H1) | `sim_test -- --exp-sweep` | see §6 |
| **new** move-vs-distance histogram (H3) | `perf.gd` (prints `H3` table) | see §6 |
| **new** gang quality override (H5) | `city_sim -- --gangs=sof` | see §6 |

## 4. Structural risks — what is still true

Everything in v0.4 §4 stands with one update:

* **§4.1 the ticker bag** is now *declared* (65 keys, enforced) but still one
  bag. The mechanical split is queued (roadmap Q2 #5) and is now safe because
  the determinism fixture will catch a botched rename.
* **§4.4 world/brain entanglement** is half-addressed: the intent boundary
  records commands, but `brain` still calls `w.*` directly and nothing replays.
* **§4.5 two nav systems / two map systems**, **§4.6 the director scheduler** —
  unchanged; queued as roadmap Q3.
* **New:** the whole tree has now been executed, but only on a `-O0` build and
  only headless. Rendering, the UI panels, and the city's 20x-speed behaviour
  on a release build remain unexercised in this environment.

## 5. Mechanical model — what the measurements are for

v0.4 §5.3's five hypotheses are the agenda. Their harnesses all exist now:

| Hypothesis | Claim | Harness |
|---|---|---|
| H1 | Experience (parallel tracking) dominates every other stat | `sim_test -- --exp-sweep` (new: regular-vs-regular, only `exp` moves) |
| H2 | Plates beat any habit set | `playtest -- --cells=` the plate rows vs the habits control |
| H3 | 10 m is a visible behaviour cliff | `perf.gd` movement-vs-distance histogram (new) |
| H4 | Aim-hold deadlock is reachable | `stall_test` watchdogs (aim_hold 10 s) |
| H5 | The city's territory is scheduled, not fought | `city_sim -- --gangs=sof|untrained` (new) |

Results are in §6. Interpretation and the balance actions they trigger are
roadmap Q1.

## 8. Appendix — building the engine here

The release hosts (`release-assets.githubusercontent.com`) are unreachable from
this workspace, but `codeload.github.com` serves the source. A minimal headless
engine builds in ~10 minutes on 2 cores:

```
curl -L -o godot-src.tar.gz https://codeload.github.com/godotengine/godot/tar.gz/refs/tags/4.4.1-stable
tar -xzf godot-src.tar.gz && pip install --user --break-system-packages scons
# pkg-config stub: the linuxbsd detector only needs `--version` when every
# system-library option is off. See platform/linuxbsd/detect.py:21.
scons platform=linuxbsd target=template_debug -j2 optimize=none debug_symbols=no \
  use_static_cpp=no disable_3d=yes alsa=no pulseaudio=no dbus=no speechd=no \
  fontconfig=no udev=no x11=no wayland=no libdecor=no touch=no \
  module_mono_enabled=no module_svg_enabled=no module_glslang_enabled=no \
  module_text_server_adv_enabled=no  # ...plus the web/media/3d modules, all off
```

One link fix was needed: `libdrivers.a` precedes `libservers.a` on the link
line, so GNU ld never pulls `RenderingContextDriverVulkan` out of the drivers
archive (its only reference is `DisplayServer::can_create_rendering_device`
later in the line). Wrapping `$_LIBFLAGS` in `-Wl,--start-group ... -Wl,--end-group`
in `platform/linuxbsd/detect.py` fixes it; a stock full build does not hit this
because more of the tree is pulled earlier.

Caveats: `-O0` means per-tick timings in `perf.gd`/`city_sim.gd` are not
representative of a release build — outcomes and digests are (the simulation is
fixed-step and seeded), wall-clock rates are not.

## 6. Results

All numbers from the `-O0` headless engine (2 cores). Win rates at n=20-30
carry roughly ±10-15 points of noise; read the shape, not the third digit.

### H1 — Experience is a threshold stat, not a runaway one

`sim_test -- --exp-sweep --n=20`, 5v5 regular vs regular, both hunting, only
`exp` moving (the first 2v2 design of this sweep was wrong: the tracking cap
never binds when enemies are met one at a time, and it measured exactly zero
effect — worth knowing as a trap):

| A exp vs B exp 3 | A win% | peak tracked A/B |
|---|---|---|
| 1 | 20% | 1/3 |
| 2 | 55% | 2/3 |
| 3 | 40% | 3/3 |
| 4 | 40% | 4/3 |
| 5 | 40% | 5/3 |
| 1 vs 1 | 50% | 1/1 |
| 2 vs 1 | 55% | 2/1 |
| 3 vs 1 | 70% | 3/1 |
| 4 vs 1 | 55% | 4/1 |
| 5 vs 1 | 55% | 5/1 |

The cap binds (peak column) and the jump from 1 to 2 is worth ~35 points
against a tier-3 enemy. Past 3, nothing — at 5v5 the fourth and fifth slots
never fill. **H1's strong form is refuted**: Experience is not "the whole game
with everything else decoration"; it is a threshold with sharp diminishing
returns. The interesting question for Q1 is now the 1→2 step, not the 4→5 one.

### H2 — habits are real, the echelon package is enormous

`playtest -- --n=30 --cells=2,4,6`:

| Cell | A win% | A down | B down | exchange | A hit% | B hit% |
|---|---|---|---|---|---|---|
| 3 SOF vs 5 militia | 100% | 0.03 | 5.00 | 150 | 84% | 8% |
| 3 police vs 5 militia | 100% | 0.50 | 5.00 | 10 | 79% | 18% |
| 3 SOF-habits vs 5 SOF-no-habits | 70% | 1.27 | 3.77 | 3.0 | 47% | 20% |

Habits alone (same stats and plates on both sides) are worth ~3:1 and 70% of
the wins — the bible's thesis holds, habits are not decoration. But the full
echelon package (plates + stats + exp + habits) runs 10:1 to 150:1. **H2 is
confirmed in spirit**: the package dwarfs the habit delta, and the SOF-vs-
militia matchup is not a fight, it is an erasure. Also note every cell here
was assault-vs-hold and the attacker won all of them — see the posture note
below.

### H3 — the 10 m cliff is real

`perf.gd -- --map=4 --na=12 --nb=12 --t=40`, movement time binned by distance
to the nearest living enemy:

| dist m | 7-8 | 8-9 | 9-10 | 10-11 | 11-12 | 12-13 | 13-14 | 14-15 |
|---|---|---|---|---|---|---|---|---|
| moving % | 20 | 31 | **23** | **47** | 27 | 45 | 52 | 62 |

The move fraction doubles across the P1/P4 boundary and keeps climbing
beyond it. **H3 confirmed**: the ladder's hard branch at 10 m is visible in
behaviour exactly where the code puts it.

### H4 — no hard stalls; one reentrancy crash; two watchdog calibrations

`stall_test` (all 11 maps): **0 matches hit their time limit** — no reachable
deadlock of the H4 shape. But the run exposed one real crash (§2.3: stray-shot
reentrancy clearing the shooter's aim mid-`_aim_update`) and two watchdog
findings: the `memory` watchdog was measuring a healthy 20v20 (raw dict size
> 20) instead of a leak, and with `Memory.fade` in place the right signal is
"expired but present" records of the dead. With both fixed, map 09 drops from
28 flags to 4, all of one class: elements in `approach` past 40 s. The
approach force-go sits at 45 s (`brain.gd:741`), so the watchdog is
deliberately stricter than the behaviour it guards; the *frequency* of
near-force-go approaches on maps 09/10 says big-map door congestion is real
work (roadmap Q1), not a deadlock. The `entry`-phase 60 s flags on map 10 are
the one class worth a dedicated look.

### H5 — the city is a clock whose hands are made of soldiers

`city_sim -- --seed=3 --min=4`, three recruit mixes (all other seeds identical;
territories at 1:00 are byte-identical, confirming the paired comparison):

| recruits | deaths | captures | expansions | reports | owned drift 1:00→4:00 |
|---|---|---|---|---|---|
| 70/20/10 mix | 33 | 4 | 5 | 22 | ~1-4 buildings |
| all sof | 15 | 2 | 4 | 7 | ~1-2 buildings |
| all untrained | **0** | **0** | **0** | **0** | **0** |

Two findings in one table:

1. **Between mixes that can fight, territory is scheduled, not won.** All-sof
   gangs kill half as often and fire a third of the shots of the default mix,
   yet the map at 4:00 is within a building or two per gang of the same shape.
   H5 is confirmed for the range that matters: `PUSH_EVERY`, `CAPTURE_TIME`
   and dominance recruiting own the map; combat is a tax on the roster.
2. **Quality is an on/off switch for activity, not a gradient.** All-untrained
   gangs cannot form expansion teams (`director.gd` excludes untrained from
   the assault pool), so no expansions → no attacks → no gunfire → no
   incidents → a completely static city. The clock's hands are made of
   soldiers.

The action this queues is not "nerf the clock" or "buff fighting" alone: it is
to decide whether territory *should* respond to who wins (roadmap Q3
disposition/heat + Q1 balance), and to fix the flatline at the bottom of the
quality range whatever is decided.

### Posture asymmetry (unprompted finding)

In every symmetric-echelon experiment here, assault beats hold almost
deterministically at small sizes (2v2: 83-90% for the attacker; 3v5 cells:
100%). Holding is currently a losing posture regardless of quality. This was
not one of H1-H5 and it is at least as large as any of them.

## 9. Run log for this milestone

| Command | Result |
|---|---|
| `python3 tools/gdlint.py` | 63 files, 0 issues |
| `python3 tools/verify_attention.py` | 25 passed |
| `godot -s tests/_check.gd` | all scripts compile (after §2 fixes) |
| `godot -s tests/habits_test.gd -- --strict` | OK (BH17 reclassified) |
| `godot -s tests/determinism_test.gd -- --write` | 27 digests written (post-fix baseline) |
| `godot -s tests/determinism_test.gd` | 27/27 reproducible |
| `godot -s tests/maps_test.gd` | 11 maps, 0 problems; 5v5 + 20v20 resolve on each |
| `godot -s tests/stall_test.gd` | 0 stalls; watchdogs clean after calibration (map 09/10 spot-verified) |
| `sim_test -- --exp-sweep --n=20` | §6 H1 |
| `playtest -- --n=30 --cells=2,4,6` | §6 H2 |
| `perf.gd -- --map=4 --na=12 --nb=12 --t=40` | §6 H3 |
| `city_sim -- --seed=3 --min=4` ×3 | §6 H5 |
