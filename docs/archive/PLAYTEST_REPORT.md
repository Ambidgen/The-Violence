# Playtest report — The Violence v1.2.1

Date: 2026-10-22 · Branch: `arena/d0e5e6df-theviolence-v1-2-1` · Build: commit `20163c5`

## Method and caveat

The sandbox has no Godot 4.4+ binary and the engine's release downloads are outside
this environment's network allow-list, so no live runs were possible. This is a
**static playtest** built from:

- all 30k lines of simulation, campaign and city code under `scripts/`;
- the developers' own headless harnesses in `tests/` (their gates, metrics and comments
  describe what the measured behaviour is and why);
- the checked-in determinism fixture `tests/fixtures/determinism.json` — 35 real,
  byte-stable fight outcomes;
- `CHANGELOG.md`, which records measured before/after numbers from past playtests.

Every finding below cites the file it comes from. Each question ends with the harness
that can confirm or refute it once an engine is available.

### Snapshot from the determinism fixture

- 35 seeded fights: 1,121 rounds fired, 291 hits — an overall **26% hit rate**.
- Median fight length 40.6 s; short room contacts end in 3-6 s, but the two **public
  event operations run 469.6 s and 590.6 s with only 13-17 shots and 3-5 hits** — long,
  nearly silent commitments.
- One warrant (m06, ranch) resolves in 182 s with **zero shots fired**; a 12v12
  SOF-vs-regular fight spends 214 rounds in 91 s. The simulation's dynamic range is
  wide; the question is whether the management layer rewards both ends of it.

---

## The ten questions

### 1. Stress only ever accumulates during contact — is that the intended difficulty curve?

**Finding.** `add_stress()` (`scripts/sim/world.gd:2661`) only raises stress. The sole
decay path is in `_passive()` (~`world.gd:3008`): `0.1/s`, and only after a full second
with *neither* a stress event nor an enemy sighting, never below the officer's `stress0`
floor (trauma × 0.015, up to 0.3, plus up to 0.05 from low morale — see
`department.gd:452`). During a room-to-room clear, near misses (0.15), hits (0.25),
friends down (0.10) and flashbangs (0.3) arrive more often than the one-second quiet
window opens, so stress habits, once switched on by `_update_bad()` (`world.gd:843`),
effectively stay on for the operation. The CHANGELOG already shows the downstream
effect: after the v0.9.1 friendly-fire fix, patrol overkill findings (BH03) rose from 7
to 39 across 40 operations because rookies now stay under fire longer.

**Question.** Should an element that has consolidated in a cleared, quiet room be
allowed to calm down, or is permanent combat arousal meant to be the pressure that
makes long raids unravel?

**Recommendation.** Add a *rally reset*: when an element holds a cleared room with no
contact and no stress event for ~10-15 s, decay toward `stress0` at ~0.25/s (cap the
relief, keep the trauma floor). This makes consolidation (`orders.gd`'s Consolidate
constraint) a genuine tactical tool instead of a 20-second speed bump. Surface per-
officer stress in the debrief timeline so the mechanic is legible.
**Measure:** `tests/lethality_test.gd` and `tests/habits_test.gd --strict` before/after;
the determinism fixture will need a one-time `--write` reset.

### 2. Hiring is a blind dice roll — where is the chief's judgement in building the roster?

**Finding.** `Department.hire()` (`department.gd:104`) rolls every attribute at once:
~40% of hires arrive with a personality bad habit, 6% with Tinnitus, 5% with Elephant
Ears, random judgment/temper/integrity, random habits. A lateral hire (`$6,500`) is just
as blind. The only levers after the fact are courses and dismissal, and firing costs
two weeks' severance plus −6 morale (`department.gd:253`). The player never chooses
between people.

**Question.** Should staffing be a decision (pick the best of a flawed pool) or a
random event you can only remediate later?

**Recommendation.** Generate a weekly **applicant pool of 2-4 records** (the existing
`hire()` already builds a complete record — just don't append until chosen), showing
echelon, judgment, temper, integrity, traits and expected pay. The chief picks one; the
rest walk. This also gives the currently invisible `integrity` and `judgment` stats a
pre-hire purpose and makes the academy-vs-lateral choice meaningful.
**Measure:** `tests/dept_test.gd` (extend it to exercise pool selection and saving).

### 3. `integrity` is a visible stat that does nothing — wire it up or take it off the screen

**Finding.** `op.gd:48` literally says `integrity` is "record only, for now". Across the
codebase it is read in exactly two places: the resignation tie-break sort
(`department.gd:673`) and UI strings (`ui.gd:1039`, `ops_ui.gd:542`). It does not affect
incident statements, IA cases, the 55%/25% leak roll in `politics.gd`, or anything the
player is told about. A displayed number that never bites teaches players to distrust
the numbers that do.

**Question.** Should integrity govern what the department's paper trail says, or should
it be hidden until it has a function?

**Recommendation.** Wire it to the information systems already in the game:
(1) low-integrity officers' post-op statements can disagree with bodycam/radio evidence
in `incident.gd`, strengthening or undermining an IA case; (2) scale the leak
probability of a cleared case (`politics.gd` on-decision) by the named officer's
integrity; (3) make testimony in a colleague's case a roster event. If none of that is
wanted before the next release, remove the field from the roster UI rather than leave a
dead dial.
**Measure:** `tests/politics_test.gd` and `tests/dept_test.gd` with a low-integrity
fixture officer.

### 4. "Suggest a plan" can play the whole game for you — what is the human planner's edge?

**Finding.** `autoplan.gd` builds squads, entries, objectives, constraints and paid kit,
and `tests/op_test.gd --chief=sensible` plays an entire 40-week campaign to an election
ending on suggestions alone. The suggestion already consumes some intel (e.g. the
hostage room, `autoplan.gd:132`). Planning is the player's only real expression in the
operational loop, so the risk is not that the autopilot is bad but that nothing
demonstrates when a human edit would have been better.

**Question.** Which pieces of information should the suggestion deliberately not use, so
that reading the briefing and canvassing still pay?

**Recommendation.** (a) Audit every `intel`/tip field in `situations.gd` against what
`autoplan.suggest()` reads, and reserve a defined subset — back doors, the lookout,
door-lock state, civilian estimates — for manual plans to exploit. (b) Add a debrief
diff: orders broken and objectives missed by the suggestion that the executed plan
avoided (the data already exists in `world.broken` and `outcome.gd`). (c) Add a
"veteran chief" difficulty that hides the button, leaving it available for onboarding.
**Measure:** run `op_test.gd --weeks=40` twice per seed — pure suggestion vs. a scripted
variant that edits entries from intel — and compare score, deaths and findings.

### 5. The balance gate covers one matchup on four houses while the game now ships twelve maps and six echelons

**Finding.** The only hard win-rate gate is equal regulars, 5v5, maps 00/04/05/06,
30-50% attacker wins (`tests/balance_test.gd`), and its own header comment says the
share "wobbles past 50%" at the documented sample size. `scale_playtest.gd` covers all
twelve maps at 10-20 a side but only prints a CSV — nothing asserts on it. The CHANGELOG
(v0.8) still leaves an open item: in SOF-vs-SOF fights the hold habits individually help
(HD16 is worth 11 points) "but together they cancel out; that interaction is the next
thing to tune" — still untuned in 1.2.1.

**Question.** Is 30-50% for equal regulars still the design target now that apartment
blocks, compounds and plazas exist, and should the other echelons have gates at all?

**Recommendation.** Turn `scale_playtest.gd`'s CSV into assertions: per-echelon-pair
bands (regular/police/SOF) split by map family (houses, commercial, multi-room, plaza),
pooled over n≥30 seeds with the same pooled-estimator approach the unreleased
equipment-gate fix already uses, and add a dedicated regression test for the SOF
hold-habit cancellation. Publish the expected-vs-actual table in the CHANGELOG each
release so drift is visible.
**Measure:** `balance_test.gd --gate`, `scale_playtest.gd`, `stall_test.gd`,
`fuzz_test.gd --n=60` in CI.

### 6. De-escalation is deeply simulated but thinly commanded — are non-shooting endings as supported as shootings?

**Finding.** The judgment model is rich: `misjudge_p()` (`world.gd:1239`) weighs stress,
night, distance, filming, running, hands-up, prior clearance; `_surrender_roll()`
(`world.gd:1334`) weighs wounds, empty weapons, blind/gas, mates nearby; challenges,
cuffing and the full less-lethal toolkit (OC, taser, baton, sting-ball, gas) exist. But
the player's command levers are thin: "Weapons tight" costs two scarce order points
(`orders.gd:23`), there is no *less-lethal-first* order, and even a correct stop can
become a late shot via `late_stop()` (`world.gd:1393`) — BH03 adds half a second of
firing after surrender. Arrest rates and misjudgements are recorded per officer but
never summarised back in the roster.

**Question.** Should a chief be able to mandate a de-escalation posture the way they can
mandate pistols-only or a pace?

**Recommendation.** Add a 1-point **Less-lethal first** constraint: inside 4 m, OC/taser
must be attempted unless the suspect is firing or pointing a weapon (the brain's
`_less_lethal()` path already exists to receive it). Add per-officer arrest and
misjudgement tallies to the roster file (the counters exist in `apply_result()`), and
put an expected-effect tooltip on the judgment course — the misjudge probability is
currently invisible to the player.
**Measure:** `tests/civ_test.gd --n=40` with the constraint on/off; compare arrests,
civilian hits, excessive-force findings.

### 7. Endless Battle runs a parallel ruleset the campaign never touches — what earns its upkeep?

**Finding.** The city director (`scripts/city/director.gd`) contains no judgment,
arrest or civilian logic at all (verified by grep): city QRF never judges, never cuffs,
and the city has no civilians. The README's known-limits list adds non-solid vehicles,
no firing from vehicles, on-foot-only movement and fenced-off back gardens. It is a pure
sandbox with no win state and no data flowing back to the 40-week campaign — and it was
the source of the 64,000-errors/minute pathfinding bug that survived from v0.7.

**Question.** Is Endless Battle a showcase, a testbed, or a future game mode — and which
gap closes first?

**Recommendation.** Reuse before building new: `civ_brain.gd`, `incident.gd` and the
police-rules path in `world.gd` already work in operations, so port **civilians first**
(pure simulation, no new UI), then judgment/arrest for the QRF, giving the city and the
campaign one rulebook. Then add a single feedback link — precinct monthly stats changing
the frequency or type of board situations — so the mode earns its maintenance cost.
Keep vehicles cosmetic until then rather than half-implementing them.
**Measure:** extend `tests/city_sim.gd --min=10` with civilian and arrest counts;
`city_test.gd` already proves every room is reachable.

### 8. The budget is a binary throttle, not a planning puzzle

**Finding.** Money has one real failure mode: a negative balance freezes hiring,
training and kit (`department.gd:224`) — it never ends the game, and the Pell ending
only counts deficit weeks (`politics.gd:512`). Income is nearly fixed: the allocation is
payroll +16% set at handover, moving only ±4%/−3% every eight weeks. Overtime is a flat
`$160 + $60 night` per officer per operation (`courses.gd`) no matter how long the
operation runs — and the fixture shows events tying up ten officers for ten sim-minutes.
Lawsuits ($10k hurt / $40k killed) land 6-10 weeks late with no forward warning in the
UI even though they already sit in `politics.pending`.

**Question.** Should the chief be able to foresee and manage a cash crunch, or is
surprise austerity the intended pressure?

**Recommendation.** (a) Add a four-week cash-flow forecast to the account screen using
the pending ledger (allocation, payroll, known lawsuits and severance are already
known). (b) Make overtime reflect the commitment — either time-on-target or a per-detail
callout minimum — so a ten-officer event vigil has a real price attached. (c) Add one
positive money decision, e.g. a grant application that requires an ally's standing, to
mirror the freeze mechanic. Keep the no-hard-game-over design; the election already
adjudicates the books.
**Measure:** `tests/dept_test.gd` budget assertions plus a 40-week `op_test.gd`
deficit-week distribution.

### 9. Training throughput vs. the 40-week clock: can a troubled roster actually be reformed?

**Finding.** Every course takes an officer off duty for 1-2 weeks, one course at a time,
with no queue; `enrol()` (`department.gd:302`) refuses anyone not `active`, so the
wounded can't even take classroom courses; a serious wound benches an officer 4-8 weeks;
coaching removes exactly one personality habit; and roughly four in ten hires arrive
with one. Nothing auto-enrolls the next course, so forty weeks of reform requires
constant manual attention across a roster of dozens.

**Question.** Is the training system meant to shape the whole department or only a few
heroes?

**Recommendation.** (a) Add a course queue per officer that auto-starts when status
returns to active. (b) Allow classroom courses (judgment, use-of-force review) while
injured. (c) Add a squad-cohort discount for CQB refreshers that also feeds the existing
pair-bond/cohesion system (`department.squad_cohesion()`). (d) Report in the debrief how
many course-weeks the roster has available, so the player can see the bottleneck.
**Measure:** `op_test.gd --weeks=40`: count mean courses completed per officer and mean
residual bad habits at week 40, before and after.

### 10. Public events are a mostly-quiet tax with a catastrophic tail and a noisy threat signal

**Finding.** An event attack happens only 8-17% of the time (`situations.gd:~194`), yet
every event runs the longest time limit in the game (900 s), the autoplan wants ten
officers (`autoplan.WANT`), each drawing full overtime, and the fixture's events run
470-590 s with 3-5 hits. When the tail lands it is the harshest consequence in the game
— visibility 5, council −10, coalition −6, Okonjo +3 per crowd death
(`politics.on_operation`). The true threat estimate is marked `never: true` and never
shown directly; the player gets only chatter tips, and 20% of those tip "raised" even
when no attack is coming (`situations.tip()`).

**Question.** Is the event bet priced and legible fairly, given the player mostly pays
for nothing and occasionally loses the election over it?

**Recommendation.** (a) Pay static post/patrol duty at half overtime, or cap billable
officers, so a quiet vigil isn't billed like a raid. (b) Let a six-officer detail
suffice when chatter is "lowered" and ten be the choice when it is "raised". (c) Surface
the chatter estimate in the briefing with its confidence, so sizing the detail is a
calculated bet rather than a default. Keep the catastrophic tail — it is the mode's
reason to exist.
**Measure:** `op_test.gd` with and without `--no-events`, comparing account, morale and
election outcomes across matched seeds.

---

## What already works well (don't break these)

- **Measurement culture.** Deterministic seeds, a 35-case fixture hashed to the decimal,
  pooled estimators replacing flaky per-run means (unreleased pass), and named gates in
  every harness — rare discipline for an indie sim.
- **The v0.9.1 friendly-fire fix is a model playtest loop:** measured (21/43 officer hits
  were blue-on-blue), root-caused to a habit nine-year veterans alone had, fixed with a
  universal lane instinct, re-measured (1.25 → 0.30 deaths per raid, 32 → 2 police-round
  hits on police).
- **The evidence chain** from muzzle flash to incident finding to IA case to delayed
  press story to lawsuit to election is mechanically connected end to end; nothing is
  purely cosmetic.
- **Safe saves** (temp-file, check, swap, `.bak` fallback) and the single-source design
  data (`habits.gd`, `equipment.gd`, `courses.gd`) make tuning cheap.
- **Fog of war, recorder and the all-grey proof (red ink off)** show accessibility and
  replayability were first-class concerns, not afterthoughts.

## Suggested headless re-measurement once a Godot 4.4+ binary is available

```
godot --headless --path . -s res://tests/determinism_test.gd          # fixture first
godot --headless --path . -s res://tests/balance_test.gd --gate --n=20 # Q5
godot --headless --path . -s res://tests/scale_playtest.gd -- --n=4    # Q5, all maps
godot --headless --path . -s res://tests/stall_test.gd                 # long-fight tails
godot --headless --path . -s res://tests/civ_test.gd -- --n=40         # Q6
godot --headless --path . -s res://tests/lethality_test.gd -- --n=20   # Q1, Q6
godot --headless --path . -s res://tests/op_test.gd -- --weeks=40 --chief=sensible  # Q4, Q8, Q9, Q10
godot --headless --path . -s res://tests/city_sim.gd -- --seed=3 --min=10            # Q7
godot --headless --path . -s res://tests/dept_test.gd                  # Q2, Q3, Q8
godot --headless --path . -s res://tests/politics_test.gd              # Q3, Q8, Q10
```

## Priority if only three can be done

1. **Q4 (autoplan edge)** — protects the core player fantasy.
2. **Q1 (stress reset)** — the single change with the widest effect on feel and on the
   excessive-force pipeline the press and election are built on.
3. **Q2/Q3 together (applicant pool + live integrity stat)** — one feature makes the
   dead stat meaningful and deepens the management half of the game.

---

## Survey results (2026-10-22)

| # | System | Decision |
|---|--------|----------|
| Q1 | Stress | **Implement the rally reset** (~0.25/s decay after 10-15 s quiet, trauma floor kept) |
| Q2 | Hiring | **Weekly applicant pool of 2-4**, full traits visible, pick one |
| Q3 | Integrity | **Full wire-up**: statement-vs-bodycam disagreements in IA cases and leak-probability scaling |
| Q4 | Autoplan | **All three**: reserve intel for manual plans, debrief diff, veteran difficulty hiding the button |
| Q5 | Balance | **Full matrix with assertions**: 12 maps x echelon pairs, pooled n>=30, CSV gates in CI |
| Q6 | De-escalation | **Both**: add 1-point Less-lethal-first constraint *and* cut Weapons tight from 2 to 1 point |
| Q7 | Endless Battle | **Campaign feedback link first** (precinct stats change board situations), not rule unification |
| Q8 | Budget | **All three**: 4-week cash-flow forecast, time/detail-based overtime, ally-gated grant decision |
| Q9 | Training | **All three**: per-officer course queues, classroom courses while injured, cohort discount with bond gains |
| Q10 | Public events | **All three**: half-rate static-duty overtime, 6-officer details on lowered chatter, confidence-rated briefing estimate |

No custom answers and no skips. Q7 was the only question where the maximal option was not
chosen.

### Implied build order

1. **Q1 rally reset + Q6 order changes** — small, isolated sim/orders changes behind
   existing headless gates (lethality, civ, orders, determinism fixture reset).
2. **Q2 applicant pool + Q3 integrity** — one department-screen feature plus the IA/leak
   plumbing; cover with dept_test and politics_test.
3. **Q5 balance matrix** — do this before Q4 and Q10 tuning so every later change is
   measured against asserted bands.
4. **Q4 autoplan reservation + diff, Q10 event pricing, Q8 budget, Q9 training** — UI
   and campaign-layer work, each with its named harness.
5. **Q7 city feedback link** — last, since it touches both director.gd and the campaign
   board generator and needs its own test.

### Implementation log

- **2026-10-22 — build step 1 shipped on this branch (Q1 + Q6).**
  - Q1 rally reset: `STRESS_DECAY`/`RALLY_QUIET`/`RALLY_DECAY` in `world.gd`; after 12 s
    with no stress event and no enemy sighting, stress decays at 0.25/s instead of
    0.1/s, never below the `stress0` floor.
  - Q6: new 1-point **Less-lethal first** constraint (`orders.gd` → `operation.gd` →
    `op.gd` → `world.engage()`), hard 4 m fire block against non-attacking,
    non-weapon-pointing recognized suspects, one-challenge threshold for less-lethal
    tools (`less_challenges_needed`), UI row in `ops_ui.gd`, text in the order summary,
    and a `less` gate in `tests/orders_test.gd` (n_min 16). **Weapons tight cut from
    2 points to 1.**
  - Validation: every changed file parses with `gdparse` (repo-wide parse-failure count
    unchanged at 3, all pre-existing gdtoolkit lambda limits). No engine binary is
    available in this environment, so the headless suites are not yet run; the
    determinism fixture will need `-- --write` once, per the CHANGELOG note.
  - Remaining: Q2/Q3, Q5, Q4, Q10, Q8, Q9, Q7 in the build order above.
- **2026-10-22 — doorway pathfinding pass (separate from the ten questions).** A bug hunt
  through the two systems that meet at a door: the 0.25 m navigation lattice
  (`scripts/sim/nav.gd`) and the shut-door leaves (`scripts/sim/geom.gd`). Three faults,
  one new gate, and a way to measure them without an engine.
  - **A. Smoothing cut corners the cell grid could not see.** `line_ok()` sampled one cell
    per 0.25 m of a leg, so a leg could cross the corner of a blocked cell between two
    samples. Because the walkable mask is already inflated by the 0.30 m body, that put the
    body *inside* a wall or a door jamb: up to 11 cm of it (p95 9 cm), and **59 of the 175
    door crossings on the twelve maps clipped geometry**. `line_ok()` now ends in
    `geom.path_clear_leg(a, b, RADIUS)` — the leg is tested against the obstacles
    themselves, each grown by the body's radius (`Geom.seg_rect_dist()` is the exact
    segment-to-rectangle distance). After: **0 / 175 clip**, worst overlap 1 cm, paths
    essentially unchanged (2 cm longer on average, a third of a waypoint more).
    `candidates()` grew a `halo` parameter because a 1 m bucket's edge is where an obstacle
    is filed, not where it is; the plain DDA walk alone missed three legs in 3,300.
  - **B. Officers stopped to open doors they were walking past.** `leaf_in_way()` grew each
    shut leaf by 0.25 m on *every* side — including out along the opening, past the jamb —
    and asked only whether that box lay ahead. Walking down a 2 m hall, or round a corner
    past a closed bathroom door, caught the body 0.10-0.28 m off the door's face and set it
    opening a door it was not going through: **152 of the 175 doors did it.** The test now
    requires the move to close on the leaf's thin-axis face or cross it. After: 0 / 175
    false stops; head-on approaches and bodies pressed on a leaf still stop and still work
    the door.
  - **C. A squad at a locked door re-searched the building every 1.5 s.** `move_to()` calls
    a path bad when its owner has not moved in 1.5 s, which is exactly what standing at a
    shut door looks like, so every officer in the stack ran A* again — and A* cannot help.
    New `world.door_ahead()` excuses the stuck test while a shut leaf is in the way.
  - **Gate:** `tests/nav_door_test.gd` (SceneTree, `-s` runnable, `--map=N` for one map).
    For every door it finds free floor on both sides (4.8 m in, scoring depth x lateral and
    checking the room), paths between them, and fails if any leg puts the body through
    geometry, if the crossing is implausibly long, or if a shut leaf both fails to stop a
    body going through it and stops one walking past.
  - **Measurement without an engine.** The numbers above come from `tools/nav_probe.py` and
    `tools/level_port.py`, hand ports of the nav raster and of the level/wall/door builder,
    run over the twelve shipped maps (12 maps, 175 doors, ~20 s). They are diagnostics, not
    the build: they will drift from the GDScript and are worth nothing against a real
    engine. Open risk: no Godot binary is reachable from this sandbox (release downloads
    redirect to a host outside the allow-list), so the GDScript has been checked only by
    `gdparse` (all four changed files parse; repo-wide parse-failure count still 3, the
    same pre-existing gdtoolkit lambda limits). The next runnable step is
    `godot --headless --path . -s res://tests/nav_door_test.gd`.
