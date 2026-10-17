# The Violence — systems & mechanics analysis (v0.4)

Read against commit `ae97783` ("v0.4: endless battle city, alert states, melee, variation, names, ledger").
~16k lines of GDScript: 75 functions in `sim/world.gd`, 87 in `sim/brain.gd`, 93 in `city/director.gd`.

**Method and confidence.** This is a code read, not a measurement. No Godot binary is
available in this workspace, so nothing below is a runtime number. Where I assert a
*behavioural* claim (habit X only fires in code path Y) it is from reading the call graph and
can be verified by grep. Where I assert a *balance* claim (armour is overtuned, Experience is
the dominant stat) it is a **hypothesis derived from the model's algebra** and is written in
§5 as a test with the exact command to run. Treat §5 as a list of things to falsify, not as
findings.

> **Status: Tiers 0–2 are implemented** (see `docs/tiers-0-2.md` for the change log).
> §3 and §4 below are still an accurate description of what the project *was*; the
> specific defects they name have been addressed where §7 called for it. §5.1's list
> of inert habits and §5.3's hypotheses H1–H5 are **not yet measured** — the
> harnesses to measure them now exist and are the immediate next step.

---

## 1. What this actually is

Strip the renderers away and the project is one thing:

> A **fixed-tick (30 Hz), seeded, stochastic resolver for small-unit close-quarters gunfights**,
> built around an explicit *cognitive pipeline* — perceive → track → recognize → acquire →
> settle → fire — with an *attention budget* (Experience) gating how many of those pipelines
> run at once, driven by a flat priority arbiter (P1–P8) sitting on top of a team tasking layer
> (elements, rooms, phases).

That is the valuable part, and it is genuinely unusual. Most games in this space model a
gunfight as "two hit-point pools with an accuracy roll". This one models the *reason the
accuracy roll is what it is*: where the eyes were, who was in the cone, how far off-axis the
target was, how long the traverse took, how much the sight picture had settled, how stressed
the shooter was, whether the target's head or only his shoulders showed over the sofa.

Two shells wrap it:

| Shell | Shape | What it tests |
|---|---|---|
| **Matches** | Closed, scored, 11 maps, 1–20 a side | The CQB model itself |
| **Endless Battle** | Open, systemic, ~250 lots, 4 gangs + 6 precincts + 3 hospitals | Whether the model sustains a world |

They have almost nothing in common at the player-facing level. That matters for §8.

---

## 2. Architecture map

| Layer | Files | Responsibility | Coupling risk |
|---|---|---|---|
| Design data | `data/habits.gd`, `data/names.gd` | 40 good habits, 20 bad, 5 echelons, 2 weapons, quirks, sound table | **Low** — the cleanest layer in the project |
| Geometry | `sim/geom.gd` | Obstacles, dual-height sight mask, bullet trace with pitch, low-cover rule | Low — genuinely self-contained |
| Map | `sim/level.gd`, `maps/m*.gd` | Walls from room rects, doors, room graph, openings, posts for 20 a side | Medium — `auto_walls` + hand-built maps is a lot of implicit contract |
| Navigation | `sim/nav.gd` | 4 `AStarGrid2D` profiles (0.25 m), cover spots, cached per map | Low |
| Operator state | `sim/op.gd` | 97 fields, 4 stances, zones, weapons, perception maps | **High** — see §4.1 |
| Simulation | `sim/world.gd` | Perception, tracking, recognition, aiming, firing, damage, stress, sound, alert | **High** — does scheduling *and* mechanics |
| Decisions | `sim/brain.gd` | P1–P8 arbiter, elements, assault/hold/hunt/support/transit, sectors, bounding | **High** — see §4.2, §4.3 |
| City | `city/*.gd` | Generator, templates, roads, vehicles, the director | **High** — 1962-line director, §6 |
| View | `view/*.gd` | Floor plan, blood/residue decals, actors, overlays, ledger, city layers | Low — reads only |
| UI | `ui/ui.gd`, `ui/city_ui.gd` | Setup and run panels | Low |
| Tests | `tests/*.gd` | 11 headless harnesses | Medium — the project's insurance policy, §7 T0 |

---

## 3. What is genuinely strong

**1. Height is analytic and shared between sight and ballistics.**
`geom.sight_mask()` and `geom.trace_shot()` both call the same `low_height()`. The question
"can I see over it" and "does the bullet stop here" are answered by *one* model. This is the
correct architecture and it is why the emergent behaviour reads well — half cover hides a
ducked body but a standing head shows, windows pass sight between sill and lintel, concealment
hides you but doesn't stop rounds.

**2. The low-cover near/full rule (`LOW_COVER_H 1.3`, `LOW_NEAR 0.4`, `LOW_FULL 3.0`) is the
best single mechanic in the project.** Cover height scales from 0 at 0.4 m to full at 3 m
*from the shooter's side*, while remaining full height against a distant shooter. One static
field produces: hugging cover, standing off to shoot over it (PF05), ducking to break contact,
and the "you can't see me but I can see you" asymmetry at range. That is a lot of behaviour
per line of code, and it's the thing to protect in any refactor.

**3. Recognition is continuous and parallel, not a binary flag.**
`rec` accumulates `DT / t_rec(...)` per tracked enemy; `t_rec` is a product of eccentricity,
head-only-visible, target motion, stress, callout cue, and alert state. Each tracked target
also gets its aim set up in parallel (`tracked[eid].ready_t`), so switching to an already
acquired target costs `switch + 4 ms/plate` instead of a full Fitts traverse. That is the
mechanism by which Experience becomes meaningful, and it is the right mechanism.

**4. Habits are control-flow overrides, not stat bonuses.**
`op.has(gid)` is false when an active bad habit suspends it, and bad habits switch on at a
stress threshold with a hysteresis band (`bad_lo`/`bad_hi` short-circuit `_update_bad`
entirely). So "Spray and pray" doesn't subtract accuracy — it deletes `WD07`'s settle
behaviour. Correct call. The 0.5%-per-good-habit `m_h` multiplier is a weak second lever but
it makes habit count legible as a number.

**5. Determinism is a first-class feature.** Seeded RNG, fixed tick, `rerun same seed`, and
per-operator `perc_phase` jitter that is itself seeded. For a project whose purpose is to
*prove a model*, this is more valuable than any feature.

**6. The element layer scales 5-person doctrine to 20 without a second code path.**
Contiguous balanced blocks (6 → 3+3, 11 → 4+4+3, 20 → 5×4), each with its own room claim,
stack, entry geometry, sectors, and bounding — sharing cleared/claimed/lkp at team level. The
fact that a 5-man team behaves identically to a 20-man team's element is a real design win.

**7. Observability is unusually good for a POC.** `o.dbg` short strings, an event stream
(`shot`, `blood`, `plate`, `drip`, `down`, `recognized`, `heard`, `alert`, `bad_on`), a ledger
of the dead with place and cause, log `kinds` filtering, a step-by-step trace harness, and a
profiling mode (`w.profiling`, `brain.fine`) that already breaks time down by element mode.

---

## 4. Structural risks

### 4.1 `op.gd` is a 97-field struct plus a 63-key untyped string bag

`ticker` is the real problem. It is a `Dictionary` with **63 distinct keys** in use
(`assessed_`, `callout_`, `confirm_`, `froze_`, `pf07_`, `tot_`, `ll_`, `ll_<key>`,
`form_key`, `support_key`, `prog`, `open`, `crouch`, `retreat`, `investigate`, …) with no
owner, no schema, no lifetime, and no cleanup. Several keys are *prefixed with an entity id*
(`confirm_<eid>`, `callout_<eid>`, `froze_<eid>`, `pf07_<eid>`, `tot_<eid>`, `assessed_<eid>`,
`ll_<pointkey>`), which means the bag grows unboundedly over a long city run and is cleaned up
by hand in `world.remove_op()`:

```gdscript
for pre in ["confirm_", "tot_", "froze_", "assessed_", "pf07_", "farcover_", "callout_"]:
    x.ticker.erase(pre + oid)
```

That list must be kept in sync with every future prefix. It won't be. This is the single
highest-risk item in the codebase because it is the thing that makes every other change
scarier than it should be.

**Fix shape (mechanical, no behaviour change):** split `ticker` into declared sub-structures —
`o.aim`, `o.move`, `o.eyes`, `o.cover`, `o.comms`, `o.task`, `o.badh` — each with one owning
system and a `clear_for(oid)`. Do it as a pure rename pass first, then migrate fields.

### 4.2 Habit logic is scattered, not centralized

There are ~55 `o.has("XX")` / `o.hb("XX")` call sites spread across `brain.gd` and `world.gd`.
**22 of the 40 good habits have exactly one call site.** There is no registry, so:

* adding habit 41 means hunting call sites;
* you cannot enumerate what a habit does;
* a habit can be implemented in one branch and silently inert in another (§5.1);
* ablation tests exist (`sim_test --ablation`, `playtest --set=ablation`) but are hand-written
  per habit.

There is no `HabitRegistry.effect(o, hook, default)`. Adding one is the highest-leverage
architectural change in the project (§7, T2 #10).

### 4.3 The "behaviour tree" is a flat priority ladder with early `return`

`brain._think()` is a hand-ordered sequence of `if … return` blocks: flinch → BH07 → BH09 →
P1 Rule 1 → retreat → P2 Rule 2 → P3 stoppage → BH05 → P4 engage far → fixation → P5 react →
P6 maintain → P7 task → P8 eyes.

This works, and at this size it is defensible. But it has three consequences worth naming:

1. **No interrupt/resume semantics.** "Keep clearing the room, but angle left because #2's
   sector is dark" is not expressible. The closest thing is `_task_look` + `look_hint`, which
   is a one-slot blackboard with a `start`/`until` window.
2. **Continuity is faked with ticker keys.** The brain re-decides from scratch 30×/s and
   relies on `far_dest`, `hold_pos_until`, `form_key`, `support_key`, `prog` to remember what
   it was doing. Every one of those is a hand-rolled miniature state machine.
3. **P1–P4 shadow P5–P7 entirely.** Anything an operator was doing as a *task* is abandoned
   the instant any visible enemy is within 45 m and recognized. There is no notion of
   "finishing the entry because the team depends on it".

Note this is *not* an argument for replacing it with a textbook BT. See §7 T2 #11 — the right
answer depends on the game direction, which is undetermined.

### 4.4 World and Brain are mutually entangled

`Brain` holds `w` and calls `w.stop(o)`, `w.move_to(...)`, `w.start_action(...)`,
`w.say(...)`, `w.raise_alert(...)`, `w.engage(...)` directly. There is no intent/command
boundary. Consequences: no replay files, no unit-testing a decision without constructing a
world, no headless parallel evaluation, and — most importantly — **no path for a player-issued
command**, which every plausible game shape needs (§8).

### 4.5 Two navigation systems, two map systems

`sim/nav.gd` (grid A*, 4 profiles) vs `city/city_nav.gd` (AStar2D corner graph + street lines);
`maps/m*.gd` vs `city/city_level.gd` + `city/tpl_*.gd`. The city adapts `level.gd` via
`skip_posts` and `xf`/`inv` transforms. Divergence is a matter of time, not chance.

### 4.6 The director is a bespoke 1962-line scheduler

`director.tick()` is a modulo schedule (`% 15`, `% 30`, `% 30 == 5`, `% 150`) over
captures / dominance / spawns / pushes / expansions / QRF / convoys / medics / hires /
body retirement, with gangs, police and paramedic logic interleaved. It works. Adding a fifth
gang or a new unit type means editing the schedule and `hostile()`/`potential()`.

---

## 5. Mechanical gaps and incoherences

### 5.1 Habits that are inert outside one branch (verified by call-graph)

These are the real examples; §7 T0 #2 will find the rest automatically.

| Habit | Only call site | Consequence |
|---|---|---|
| **PF07** Get off the X | `brain.gd:981`, inside `_rule1` only | Only fires at ≤10 m. In `_engage_far` — which handles everything from 10 m to 45 m — nobody sidesteps. The habit does nothing in the majority of engagements. |
| **WD01** Ammo count awareness | `brain.gd:1024`, the empty-click pause in `_transition` | Does not gate any proactive reload. Proactive reload is `WD02`-driven in `_maintain`. An operator with WD01 but not WD02 still only reloads when dry. |
| **GD10** Mutual support (8 m) | `brain.gd`, inside `_go`, and only when the goal is *behind* the mate (`dot < 0`) | Drifting sideways or forwards is unconstrained. |
| **GD03** Respect lines of fire | `brain.gd`, inside `_go` | Applies only while choosing to move. An operator already standing in a lane never backs out. Also uses a 7 m radius where the Bible says 6 m. |
| **ED09** Rear security | 3 sites, but `_is_rear` returns **true** for a lone operator (vacuous "no mate is behind me") | A single operator on the move periodically looks directly backwards at nothing. |
| **BH09** Jumpy trigger | `brain._jumpy`, gated on `w.visible(o, e)` being false and `rec >= 0.5` | Fine, but note it returns before P1, so a jumpy operator can *lock onto a half-recognized target and ignore a fully-recognized one 3 m away*. Probably intended; worth asserting. |

### 5.2 Systems with no feedback loop

* **Wounds are a latch.** `o.wounds > 0` multiplies sigma ×1.5 and speed ×0.7 and makes
  subsequent chest/abdomen hits more likely to down. There is no bleed, no progression, no
  pain behaviour, no self-aid. In a Match a wounded operator is permanently a bit worse.
  `arm_hit` (+0.2 s acquire) and `leg_hit` (20% chance of crouch, ×0.4 speed) are one-shot
  flags that are never revisited.
* **Stress is one number.** Rises from near misses (+0.15), hits (+0.25), a friend down
  (+0.10) and stray shots; decays at 0.1/s after 1 s of quiet; caps at 1.0; gates bad habits
  via `stress × (1 − resist)`. There is no acute/chronic split, no exhaustion, and no
  recovery faster than 60 s of nothing happening. For a 5-minute match that is fine; for the
  endless city it means a survivor in a hot neighbourhood is permanently at max stress.
* **Sound is one-way.** `emit_sound` is thorough (loudness table, wall halving, per-operator
  hearing traits, 8% positional error, alerts, look-hints). But:
  * `brain.on_heard` **returns immediately unless the element is in `hold` mode.** An assault
    team never reacts to a 45 m gunshot. Hunting teams get it only indirectly, via
    `tm["sound"]` polled in `_task_hunt`.
  * Nothing is *audible* — no operator knows they are making noise, so `creep` vs `sprint` is
    a speed choice with no cost. Stealth cannot exist as a strategy.
* **Melee is accidental.** `_melee()` is a reaction-time comparison (`_react` = `t_rec0 × m_h ×
  stress`, ×1.5 if unrecognized, ×1.3 if GREEN) between two operators who happened to end up
  within 0.8 m. There is no personal-space steering keeping hostiles apart, no positioning,
  no approach, no weapon-vs-weapon interaction. In practice it fires inside doorway jams
  (`ghost_until` exists precisely because bodies jam in doorways).
* **No suppression.** The single largest missing CQB behaviour. Near misses add stress (+0.15)
  but do not degrade aim, do not pin, do not interrupt. Covering fire is decorative, which
  means `GD05` (bounding overwatch), `WD07` (controlled pairs) and `GD08` (cover the reloader)
  are all *correct but purposeless* — there is nothing to suppress the enemy with.

### 5.3 Model hypotheses to falsify (with commands)

These are algebra-derived, not measured. Each has a command.

**H1 — Experience is by far the strongest stat, and nothing else is close.**
`t_rec` for an untrained operator at the cone edge works out around 0.50 × 1.3 (GREEN) × 3.5
(ecc 60°) × 1.5 (head only) × 1.5 (stress) ≈ 5 s, versus ~0.3 s of Fitts time-on-target. So
recognition dominates the engagement timeline. Experience sets how many recognitions run
*concurrently* (1 to 5). Tier 1 vs tier 4 is therefore not a 4× bonus on one term — it is
serial vs parallel processing of the dominant term. Every other stat is a 10–30% multiplier
on a sub-second quantity.
→ Test: `godot --headless --path . -s res://tests/sim_test.gd -- --n=40` plus a new sweep
holding all echelon stats constant and varying only `exp` 1→5. If the win-rate curve is
steeper than the echelon curve, the game is an Experience game with habits as decoration.

**H2 — Plates are stronger than any habit set.** Three plates absorb three chest hits outright
(`_hit`: `zone == "chest" and plates > 0 and front`). Only the 4th chest hit rolls the
20%-instant-kill / 65%-down / wound table. Meanwhile `abd` **bypasses armour entirely** (the
plate branch is `chest`-only) and `front` is a ±60° arc. So armour is enormous against a
centre-mass shooter and worthless against a low shot from the flank — which is interesting —
but at `sof = 3 plates` vs `untrained = 0`, the exchange ratio should be lopsided.
→ Test: `tests/playtest.gd -- --n=40 --cells=all`, compare the `3 police vs 5 militia` and
`3 SOF vs 5 militia` exchange columns against the `3 SOF-habits vs 5 SOF-no-habits` control.
If habit-delta < plate-delta, habits need to be worth more (raise `m_h` from 0.5% per habit,
or make more of them control-flow rather than timing).

**H3 — The 10 m line is a visible artefact.** `_close_threat` (P1, ≤10 m: stop, fire until
dry or eliminated, no movement) and `_far_target` (P4, >10 m: move to a fighting position,
crouch, re-engage from a new spot) are qualitatively different behaviours with a hard
boundary. Real doctrine has a gradient. Expect a discontinuity in movement-vs-distance plots
at exactly 10 m, and expect operators to oscillate across it.
→ Test: add a `time-moving vs distance-to-nearest-enemy` histogram to `tests/perf.gd` output.
A spike at 9–11 m confirms it.

**H4 — Aim-hold deadlock is reachable.** In `_aim_update`, `WD10` blocks fire while a friend is
within 0.5 m of the line; after 0.3 s it attempts a sidestep and resets `hold`. If
`nav.is_free` fails on both sides, `sidestep` is never set, `hold` is reset to 0 every 0.3 s,
and the operator stands aimed and silent forever. Same shape in `_rule2` when
`_cover_point` returns `null` and `threats` is non-empty (it stops and retries next tick).
→ Test: extend `tests/stall_test.gd` to flag any operator with `aim.on == true`,
`shots == 0`, and `t - last_shot_t > 10`.

**H5 — The city's territorial outcome is driven by constants, not by fighting.**
`PUSH_EVERY = 120 s`, `CAPTURE_TIME = 60 s`, gang strength `0.15 × Σ(dominance × buildings)/min`.
Gang echelon mix is fixed at 70/20/10 untrained/militia/regular, and "holding gangs don't
shoot at each other" (`hostile()`: `gang vs gang` requires `a.assault or b.assault`). So most
territory change is scheduled, not fought, and gang *quality* is nearly irrelevant to the map.
→ Test: `tests/city_sim.gd -- --seed=3 --min=30` twice, once with all gangs `sof` and once
with all gangs `untrained`. If the territorial outcome is similar, the city is a clock.

---

## 6. The Endless Battle is a different game wearing the same renderer

The city mode's interesting content lives in `director.gd`, not in the CQB model.

* **"Holding gangs don't shoot at each other" caps emergence.** It is a sensible anti-stalemate
  rule, but it means three of the four gang interaction types are inert until an *expansion*
  team forms (which needs the perimeter full or the cap nearly reached). The map is therefore
  static, punctuated by 2-minute pushes — a clock, not a war.
* **Police are the most complex and least legible subsystem.** QRF (vans, 3-building search,
  all-clear, return), patrols (random drive, dismount on hearing gunfire), ROE (flag on
  "seen targeting someone", 90 s), retreat checks, hires, hospital recovery, ambulances. The
  ROE means police frequently stand next to an armed gang member and do nothing — correct
  behaviour, terrible readability.
* **The city has no population.** 200 buildings, six schools, three hospitals, and zero
  civilians. The ROE system, the "seen targeting someone" flag, the retreat check, and
  paramedics all exist to make *non-lethal* interactions matter — and they currently only ever
  apply to gang members. The city is a stage set with no audience.
* **`World` threads `city` and `dormancy` booleans everywhere** — 12 occurrences of
  `if city` / `if dormancy` in `sim/` alone, plus `endless`, `o.gang`, `o.police`, `o.clearing`,
  `o.assault`, `o.mounted`. The sim knows a lot about the city.

So: the city is currently a *stress test and a demo* for the CQB sim, not a game. That is
exactly right for a POC. But it means the two shells have different design needs and should
not be assumed to converge.

---

## 7. Next steps for refinement

Ordered by *value under uncertainty*. Because the game direction is undetermined, the
principle is: **do the work that every candidate game needs, defer the work that commits you.**

### Tier 0 — Instrumentation, before any features (1–2 sessions)

The project's purpose is to prove the simulation is interesting. Right now it cannot prove
anything falsifiable. This tier converts opinion into data.

1. **A JSON dump harness.** `tests/scale_playtest.gd` already emits CSV. Add
   `playtest --dump-json=<dir>` emitting per-match: full event timeline, per-operator summary,
   per-room clear times, shot/hit/zone histograms, stress curves, time-to-first-recognition,
   time-to-first-shot, distance-at-engagement. Then one small Python aggregator. Every
   hypothesis in §5.3 becomes a query instead of an argument.
2. **A habit-coverage report.** `tests/habits_test.gd`: for each id in `Habits.good_ids()` +
   `bad_ids()`, grep `scripts/sim/` for call sites and report `{habit, n_sites, branches_touched}`.
   Flag any habit with 0 sites (unimplemented), 1 site (probably inert outside one branch — §5.1
   found 22), or sites in only one of P1–P8. Run it in CI. This is the cheapest, highest-value
   item on the list.
3. **Deadlock and stall watchdogs.** Extend `tests/stall_test.gd` with: aim-hold (H4),
   path-fail loops (`path_fail_until` retriggering > 20×), elements in `approach` past the
   45 s force-go, sweeps that never prune, operators with `moving == true` and `speed == 0`
   for > 5 s.
4. **Determinism regression.** Run N seeds, hash the terminal world state (positions, states,
   `stat`, `deaths`), store as a fixture. This is what makes Tiers 1–2 refactors survivable, and
   it costs an afternoon. Do it before touching `op.gd`.

### Tier 1 — Make the simulation honest about what it models

5. **Sound, both directions.** Route `on_heard` through one reaction policy for *all* postures
   (assault: element halts and covers the bearing, leader may re-task; hunt: investigate; hold:
   re-post — which already exists and is good). Add the missing half: an `audible` flag on the
   mover so that sprinting is *loud* and creeping is not, and so `PF06` (short rushes) and
   `PF02` (duck under window sills) become choices with costs. This turns noise from a
   perception widget into a resource.
6. **Suppression.** The highest value-per-line missing mechanic. `suppressed_until` set by near
   misses and impacts within N m; effects: stress, sigma penalty, a flinch that resets `settle`,
   and a `WD09`-exempt chance of a stray shot. Suddenly `GD05` bounding, `GD08` covering the
   reloader, and `WD07` controlled pairs all have a *purpose*, and covering fire becomes a
   tactic the player can understand.
7. **Wounds that progress.** Bleed rate by zone; a wounded operator can't sprint and aims worse;
   a downed operator is a timed problem rather than a 5-minute one in matches. Without this the
   damage model is a two-state latch and the excellent `arm_hit`/`leg_hit` flags are wasted.
8. **Doors as state** (open / closed / locked, plus a breach action). This is the biggest
   mechanical hole — "how do we get in" is *the* CQB decision, and `PF01`, `PF03`, `PF04`,
   `GD01`, `ED10`, `BH06` and `BH11` all presuppose it. It is also the biggest change, because
   `PF02`'s exposure layer and `nav`'s doorway cost layer are precomputed. **Do it on one map
   first** (`m01_lone_cabin.gd`, 30×20 m, one room, one door) as a vertical slice. If it reads
   well there, generalize.

### Tier 2 — Architecture that unlocks iteration

9. **Kill the `ticker` bag** (§4.1). Mechanical split first, behaviour change never.
10. **A habit effect registry** (§4.2). `Habits.EFFECTS[gid] = [{hook, fn}]` with hooks
    `{recognition, target_selection, movement_mode, entry_geometry, reload_policy, eyes,
    cover_choice, fire_cadence, team_task}`. `brain` calls
    `Hab.effect(o, "reload_policy", default_fn)`. Benefits compound: adding a habit becomes
    data; the coverage report (T0 #2) becomes automatic; ablation tests become a loop over ids
    instead of hand-written cells; the UI's "what does this habit do / what overrides it"
    becomes generated from the same table instead of hand-maintained prose.
11. **Decide what "AI behaviour tree" means here.** Two honest options:
    * **(a) Keep the ladder, add named interrupt classes + a real blackboard.** ~80% of the
      benefit of a BT for ~15% of the work. This is the right answer *unless* the game needs
      authored squad plans.
    * **(b) A real BT/HTN** with the element as planner and the operator as executor — tasks
      become resumable nodes with guards and memory instead of ticker keys.

    **Recommendation: (a) now.** (b) is a trap if the game turns out to be an autobattler or a
    city sim, and it is only clearly right if the game becomes a command game. Do (a), keep the
    ladder's ordering documented as data so (b) stays possible.
12. **An intent boundary** (§4.4). `brain` emits `{move, aim, fire, action, say, look}` into a
    per-tick intent; `world` applies it. Unlocks replay files, decision unit tests without a
    world, parallel headless evaluation (huge for T0), and — critically — the player-command
    path every game shape needs.

### Tier 3 — Fidelity, gated on game direction

| Item | Needed for | Do not do it if |
|---|---|---|
| 13. Civilians | A police game, a narrative game, the city as a game | The game is an autobattler |
| 14. Verticality / multiple floors | A building-clearing game | Anything else — it touches geom, nav, level, and all 4 city templates |
| 15. Grenades, breaching, less-lethal | A tactical game with loadouts | The CQB model stays the whole point |
| 16. Wall penetration + materials | A realism-autobattler | Cheap-ish: `trace_shot` already walks candidates; add a `material` with a penetration budget |

### Tier 4 — The city

17. **Extract a `FactionPolicy` interface** so `if city` disappears from `sim/`: hostility,
    dormancy, faction tags, and the director hooks become a strategy object the match mode
    satisfies with a trivial default.
18. **Replace "holding gangs don't shoot at each other" with a per-pair `disposition` matrix**
    and a heat value that escalates through incidents. Same calm most of the time, but feuds
    can now start, which is where the city's stories would come from.
19. **Give territory an economy** (income by buildings held, spending on recruits/echelon
    upgrades) so `PUSH_EVERY` stops being the only clock.

---

## 8. Three candidate games, and what each would need

The sim is good enough that the honest problem is choosing, not building.

**A. The resolver / autobattler.** *(closest to today — maybe 80% built)*
Configure, run, watch, attribute. Needs: outcome attribution ("you lost because B3 owned the
hall and your element had no PF04"), a ladder/campaign, and progression that maps onto habits
and quirks. The sim is already the content. **Missing piece: legibility of cause** — which is
exactly what T0 #1 delivers.

**B. The squad commander.** *(Door Kickers / Frozen Synapse shape)*
Needs: pause-and-plan, waypointing, the intent boundary (T2 #12), and undo/replan. Medium
risk. The CQB model here is already better than most shipped games in this genre — a
pausable, hatchable plan layer over it would be a genuinely strong product. This is the shape
that justifies T2 #11(b).

**C. The crime city.** *(Endless Battle as the whole game)*
Needs: an economy, civilians, a player role (gang boss? precinct commander? paramedic?), and
legibility at zoom levels where operators are 2 pixels. Highest ceiling, furthest from done.
Note that at city zoom the CQB detail — the project's entire differentiator — is invisible.
That is a real design tension, not just a rendering problem.

**Recommendation if you don't want to choose yet:** do Tiers 0–2. All three games need
instrumentation, suppression, sound, wound progression, a sane `Op`, a habit registry, and an
intent boundary. None of those commit you. Then let the T0 data tell you which fantasy the sim
actually delivers — specifically: if the habit-deltas are large and legible, that is game A; if
the *failure modes* are the interesting part (elements stalling in the fatal funnel, sectors
going dark after a casualty), that is game B; if neither is interesting at 20× speed but the
city churn is, that is game C.

---

## 9. Appendix — commands

```bash
# T0 #2 — the habit coverage report (does not exist yet; write it first)
godot --headless --path . -s res://tests/habits_test.gd

# H1 — Experience sensitivity
godot --headless --path . -s res://tests/sim_test.gd -- --n=40
godot --headless --path . -s res://tests/sim_test.gd -- --ablation

# H2 — plates vs habits
godot --headless --path . -s res://tests/playtest.gd -- --n=40 --cells=all

# H3 — the 10 m line
godot --headless --path . -s res://tests/perf.gd -- --map=4 --t=40

# H4 — aim-hold deadlock
godot --headless --path . -s res://tests/stall_test.gd

# H5 — is the city a clock?
godot --headless --path . -s res://tests/city_sim.gd -- --seed=3 --min=30

# per-tick, per-branch narrative for one operator
TR_STEP=1 godot --headless --path . -s res://tests/trace.gd -- --map=4 --a=sof --na=8 --b=militia --nb=8

# where the time goes
godot --headless --path . -s res://tests/perf.gd -- --map=10 --t=40
```

Full list in `README.md` §"Headless tests".
