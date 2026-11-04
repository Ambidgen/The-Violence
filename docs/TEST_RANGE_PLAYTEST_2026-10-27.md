# Test-range playtest — 27 October 2026

**Historical pre-fix baseline.** This study exercises the **test range/tactical suite only**, not campaign missions. It compares preset compositions, assault versus hold, team size, individual SOF habits, and SOF equipment. At the time of these runs, the simulation had not been modified to fix the issues below. For the subsequent changes and post-fix results, see [Test-range fixes and debug](TEST_RANGE_DEBUG_2026-10-27.md).

- [Full screening tables](TEST_RANGE_PLAYTEST_DETAILS_2026-10-27.md) — every matrix, size, composition, habit and equipment case.
- [Fresh-seed follow-up tables](TEST_RANGE_CONFIRMATION_2026-10-27.md) — paired results for selected habit/equipment changes.
- [Per-match data, diagnostic logs and source hashes](../tests/results/test-range-2026-10-27/).

## Main findings

1. **Two genuine tactical stalls were reproduced.** A blocked friendly-fire lane can hold both sides in place until timeout; separately, operators can stop just short of cover and never reload despite having spare magazines. Both are described with exact repros below.
2. **Full preset strength mattered, but the map and role mattered too.** In the 216-fight core 5v5 matrix, SOF attackers beat militia and patrol in 6/6 each and regulars and police in 5/6 each; SOF defenders beat each weaker preset in 6/6. Those are small samples and include gear, experience and habits, not just training.
3. **Some nominally good SOF habits warrant review.** On 24 fresh-seed pairs, turning off PF04 for the attacking team changed its win count from 14/24 to 18/24; turning off GD02 changed it to 21/24. The latter result was concentrated on the plaza, and neither screen is sufficient to declare those habits globally harmful. Removing *all* good habits reduced each changed side's win count by 6/24 in its respective comparison.
4. **A shielded first-slot attacker was strong in the follow-up:** 23/24 wins versus 14/24 for the all-good SOF baseline, with 82 shield stops in 13 fights. This is a shield **plus a pistol instead of the SBR** and added weight, not a shield-only intervention. It is a balance question rather than proof of a defect.
5. **Many stress-triggered bad habits were not exposed in normal SOF fights.** A zero observed effect is not proof the behavior is implemented incorrectly or has no effect under other conditions. A separate threshold probe explains why activation is unlikely at typical SOF resistance.

## Scope and design

**1,777 completed tactical simulation runs:** 1,441 screening runs and 336 fresh-seed follow-up runs. Coverage was checked against the exact planned case/map/seed keys and lineup/change metadata. The count is runs, not independent observations: SOF baseline fights were rerun in both the habit and equipment groups (six screen and 24 follow-up repeats), and the six regular 5v5 controls were rerun in the size and two mixed-composition labels (18 repeats). Those controls are not pooled to inflate per-case sample sizes.

The initial habit worker was intentionally stopped and split into two isolated processes. Its 65 completed cases were retained; four partial records from the interrupted next case were excluded from the screen and the case was rerun. All four rerun records matched the discarded partial records exactly. The coverage audit found no missing, extra or duplicate case/map/seed keys.

| Group | Configuration | Maps / seeds |
| --- | --- | --- |
| Preset matrix | All 36 ordered 5v5 pairs of untrained, militia, patrol, regular, police and SOF; real UI preset kits, experience and preset habits | Maps 00, 03, 04; two seeds each: 216 matches |
| Extra plaza matrix | Seven specifically selected 5v5 pairs, **not** mixed into the equally sampled core matrix | Map 11; one seed each: 7 matches |
| Team size | Regular versus regular: 1v1, 2v2, 3v3, 5v5, 8v8, 10v10 and four reversed unequal sizes | Maps 00, 03, 04; two seeds: 84 matches |
| Mixed teams | Five ordered lineups, each tried on A and B against five regulars | Maps 00, 03, 04; two seeds: 60 matches |
| SOF habit screen | 3v3; baseline plus team-wide one-habit removals/additions, no-good and all-bad comparisons | Maps 00, 03, 11; two seeds per map: 912 matches |
| SOF equipment screen | 3v3; baseline and 13 changes on either team | Maps 00, 03, 11; two seeds per map: 162 matches |
| Fresh-seed follow-up | Nine selected habit cases and five equipment cases, including their repeated baselines | Maps 00, 03, 11; eight new seeds per map: 336 matches |

Map 00 is the Shotgun House, 03 the Corner Store, 04 the Center-Hall Bungalow, and 11 the Civic Plaza. A assaults and B holds; spawn points and geometry are not mirror images. These are daylight tactical matches, alerts 1/1, normal open doors, no civilians, no police rules or campaign state, at the normal 30 Hz simulation rate. The police *preset* therefore does not imply police rules of engagement. Normal map time limits are retained: 300 s on map 00, 360 s on 03/04 and 900 s on 11.

The matrix uses the entire UI preset: stats, experience, good habits, stress bad habits and actual equipment. The legacy `tests/teams.gd` helper, unless given a kit, instead supplies generic fallback equipment; this study explicitly supplies `Equipment.preset`. The SOF-only baseline deliberately differs from the standard SOF preset: **both teams have all 60 good habits and no bad habits**, including PF08, ED09 and HD07, which the regular SOF preset excludes. Baseline SOF equipment is an SBR, pistol, red dot, three plates, SOF helmet, light, medkit and two flashbangs. A single habit change applies to **all three operators on one side**. Hold-only habits are tested on B; they sleep outside hold mode. The 152 habit cases comprise the baseline, 100 individual-good-off cases, 47 individual-bad-on cases, and two each for all-good-off and all-bad-on.

Cases use common seeds `710001 + 1000*map + 7919*rep`, with rep 0–1 for the screen and 100–107 for the follow-up. Reversing sides changes roles rather than mirroring geometry; changing team size can change the initial random draws. Even for the same seed, behavior changes may make later RNG streams diverge, so these are paired simulation comparisons rather than identical histories.

## Reproduced mechanics defects

### 1. Friendly-fire-lane deadlock — high impact

On map 00, 5 patrol attackers versus 5 regular defenders, seed `717920`, the match draws at 300 s. At 60, 120, 180, 240 and 300 s the shot total remains **28**, with unchanged survivor positions and squad tasks. At 120 s, A3 and B5 are mutually targeting, on target and requesting fire, with unjammed magazines of 26 and 30 rounds, respectively; `friend_in_lane=true` and `sidestep={}` for both. Four attackers and two defenders survive.

`World` correctly prevents firing through a teammate, but the observed shooters lack WD10: the no-WD10 guard holds fire without the WD10 sidestep, and the nearby blockers stay put. A safe hold is preferable to friendly fire, but an indefinite stand-off is a failure to recover. Review the friendly-lane guard around `scripts/sim/world.gd`'s `friend_in_line` and provide a bounded, safe reposition/replanning path; add a regression that asserts progress without firing through teammates.

```sh
godot --headless --path . -s res://tests/test_range_trace.gd -- \
  --map=0 --a=patrol --b=regular --na=5 --nb=5 --seed=717920 --interval=60
```

Evidence: [full trace](../tests/results/test-range-2026-10-27/logs/friendly-lane-full.log), [120 s detail](../tests/results/test-range-2026-10-27/logs/friendly-lane-detail.log).

### 2. Reload/cover deadlock — high impact

On plaza map 11, 5 untrained attackers versus 5 untrained defenders, seed `721001`, all ten are still up when the fight draws at 900.033 s; there were 141 shots and two hits. By both 120 and 240 s, operators A3, A5 and B4 have zero rounds in their current magazines and 2–3 spare magazines, with `RULE 2 > cover`, no action, `hidden=false`, `goal_hidden=true` and goal distances of 0.255–0.296 m. They have stopped within the 0.3 m arrival tolerance without reaching the point that actually blocks sight, so `_rule2` will not reload and `_seek_cover` will not advance them. A4 also remains in the same state, though its current goal is not hidden. A2 is concurrently held by a friendly lane. No additional shots are recorded after 120 s.

Review `scripts/sim/brain.gd`'s `_rule2`, `_seek_cover` and cover-point arrival: verify actual concealment at the operator's position and replan/recover when a nominally reached point is not safe. Avoid simply forcing a reload in the open without a design decision.

```sh
godot --headless --path . -s res://tests/test_range_trace.gd -- \
  --map=11 --a=untrained --b=untrained --na=5 --nb=5 --seed=721001 --interval=120 --stop=240
```

Evidence: [120/240 s reload and lane detail](../tests/results/test-range-2026-10-27/logs/plaza-reload-detail.log), plus the full 900 s outcome in `screen-plaza.jsonl`.

## Presets, roles and team size

The core preset matrix below shows **attacker wins / six fights**; defender wins, the one draw, casualties and durations are in the [full table](TEST_RANGE_PLAYTEST_DETAILS_2026-10-27.md). These are whole-preset comparisons, not isolated skill effects.

| A attackers \\ B defenders | Untrained | Militia | Patrol | Regular | Police | SOF |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Untrained | 3/6 | 0/6 | 0/6 | 0/6 | 0/6 | 0/6 |
| Militia | 4/6 | 3/6 | 2/6 | 0/6 | 0/6 | 0/6 |
| Patrol | 6/6 | 4/6 | 4/6 | 1/6 | 2/6 | 0/6 |
| Regular | 6/6 | 4/6 | 1/6 | 4/6 | 1/6 | 0/6 |
| Police | 6/6 | 6/6 | 4/6 | 3/6 | 2/6 | 0/6 |
| SOF | 6/6 | 6/6 | 6/6 | 5/6 | 5/6 | 5/6 |

Across the same 36 ordered pairings, A won **46/72** fights on map 00, **31/72** on map 03 and **22/72** on map 04. This describes these scenarios, not an unbiased estimate of a general attacker/defender advantage. The 5-patrol-versus-5-regular cell includes the reproduced draw.

**Team size — regular attackers versus regular defenders** (mean down includes dead):

| A vs B | A/B/draw | Mean A down | Mean B down |
| --- | ---: | ---: | ---: |
| 1v1 | 4/2/0 | 0.33 | 0.67 |
| 2v2 | 4/2/0 | 1.00 | 1.67 |
| 3v3 | 2/4/0 | 2.50 | 1.67 |
| 5v5 | 4/2/0 | 3.17 | 4.67 |
| 8v8 | 5/1/0 | 4.33 | 6.83 |
| 10v10 | 5/1/0 | 4.50 | 9.33 |
| 2v5 / 5v2 | 2/4/0 / 6/0/0 | 1.50 / 2.33 | 1.83 / 2.00 |
| 3v5 / 5v3 | 3/3/0 / 5/1/0 | 2.50 / 1.83 | 3.50 / 2.83 |
| 5v8 / 8v5 | 3/3/0 / 6/0/0 | 3.83 / 3.33 | 6.50 / 5.00 |
| 5v10 / 10v5 | 2/4/0 / 5/1/0 | 4.00 / 5.00 | 7.00 / 4.83 |

Numbers are descriptive, not a monotonic scaling law: each cell has only six fights, and larger teams change spawn and random-draw ordering. In the mixed-composition screen, a lineup with an SOF operator in slot 1 and four militia won 5/6 as A against regulars but 3/6 as B; a lineup with one militia in slot 1 and four SOF won 6/6 as B against regulars. Slot order determines spawn and can affect assignments; the AI selects leader and entry order dynamically, so these are not controlled tests of leadership or one soldier's contribution.

## SOF habits: paired fresh-seed results

All rows below compare the changed side against the same-map, same-seed 3v3 all-good/no-bad baseline. There are 24 pairs per row. The baseline is A/B/draw **14/10/0**; its attacker win share is 58.3%, with a nominal Wilson 95% interval of 38.8–75.5%. `G/L` counts paired fights in which the changed side gained/lost a win; draws would remain in the denominator. `Δ down` is change in that side's mean down-or-dead operators per fight.

| One team-wide change | Changed side | Baseline wins → changed wins | Δ win pp | G/L | Δ down |
| --- | --- | ---: | ---: | ---: | ---: |
| All good habits off | A | 14/24 → 8/24 | -25.0 | 4/10 | +0.71 |
| PF04 Points of domination off | A | 14/24 → 18/24 | +16.7 | 5/1 | -0.33 |
| GD02 Sector ownership off | A | 14/24 → 21/24 | +29.2 | 9/2 | -0.50 |
| BH06 Doorway stall on | A | 14/24 → 14/24 | 0.0 | 0/0 | 0.00 |
| BH11 Rush the room on | A | 14/24 → 13/24 | -4.2 | 4/5 | +0.33 |
| All good habits off | B | 10/24 → 4/24 | -25.0 | 0/6 | +0.33 |
| HD07 Canalize the entry off | B | 10/24 → 8/24 | -8.3 | 0/2 | +0.08 |
| BH27 Unprepared position on | B | 10/24 → 13/24 | +12.5 | 6/3 | -0.54 |

The GD02 difference is especially map-dependent: paired net changes were +1/8 on map 00, 0/8 on map 03 and +6/8 on map 11. The PF04 changes were 0/8, +2/8 and +2/8, respectively. They are leads for investigation, not a universal ranking. Removing a non-hold good habit also changes the general good-habit-count reaction multiplier (`m_h`), in addition to removing that habit's specific behavior.

The small screen is volatile: BH11 on A appeared to improve attacker wins by **50 percentage points** in the six-fight screen but changed them by **-4.2 points** in the fresh-seed follow-up. Across the one-bad-habit-at-a-time screen, none of the **138 stress-habit fights** sampled activation, while all **144 trait-habit fights** sampled activation for all three changed-side operators. BH11 and BH27 were sampled active in all 24 follow-up fights for all 72 changed-side operators; BH06 was sampled active in none, and its recorded outcomes and telemetry matched the control. Activation is sampled once every five simulation ticks, so extremely brief activations can be missed. Activation does not guarantee that the relevant opportunity (entry, cover, target, etc.) occurred. Good-habit opportunities were not separately instrumented.

### SOF stress threshold concern

Effective stress is `stress * (1 - resistance)`, and stress is capped at 1.0. In a separate seeded probe of 10,000 independently varied SOF operators, resistance was min/median/max **0.558/0.802/0.950**. With each stress bad habit present alone, the maximum-stress threshold was theoretically reachable for 2.96% for BH06/BH07, 0.07% for BH21, and 0% for the other ten. Enabling anxiety habits lowers several thresholds; see the [probe output](../tests/results/test-range-2026-10-27/logs/sof-stress-probe.log). These are maximum-stress upper bounds, not measured fight activation or a claim that the threshold is impossible for every operator. The 24 BH06 follow-up fights sampled no activation; their largest sampled A-side effective stress was 0.377 versus BH06's 0.38 threshold. Direct mechanics tests confirm BH06 can trigger and suspend PF01/PF04 at lower resistance. Decide whether very rare stress-bad activation for elite operators is intended, and use deliberately stressed scenarios to measure the behaviors when exposed.

## SOF equipment: paired fresh-seed results

Each change below is on the attacking side of the same 24 baseline pairs; all other habits/kit remain as described above. Gear changes also change weight, and may affect behavior and subsequent RNG.

| Attacker equipment change | Baseline wins → changed wins | Δ win pp | G/L | Δ own down |
| --- | ---: | ---: | ---: | ---: |
| Remove plates | 14/24 → 10/24 | -16.7 | 5/9 | +0.67 |
| Remove SOF helmet | 14/24 → 13/24 | -4.2 | 3/4 | +0.12 |
| Remove flashbangs | 14/24 → 17/24 | +12.5 | 6/3 | -0.21 |
| Shield on first-slot attacker; primary removed | 14/24 → 23/24 | +37.5 | 9/0 | -0.79 |

The baseline attackers consumed 77 plate segments, spent 16 SOF helmets and threw only three flashbangs across 24 fights. The shielded variant registered 82 shield stops across 13 fights, with a maximum of 21 in one fight; 6 of its 9 gained wins were on the plaza. In the separate six-fight defender shield screen, B won 6/6 versus 4/6 in the paired baseline, and 89 shield stops were recorded, including **67 in one fight** (map 00, seed 710001). The implemented shield does not wear out, and SBR body shots in the covered frontal arc are blocked, so investigate that interaction before treating the point estimate as a general-purpose shield advantage. In the six-fight screen removing plates appeared to improve attacker wins by 16.7 points, while the follow-up moved the other way; this illustrates sampling uncertainty, not evidence that plates are useless.

The full equipment screen also includes vest instead of plates, no medkit, no gear, carbine, SMG, shotgun, battle rifle, iron sights, magnified optic and shield on each side. Flashbangs are counted when spent, plates/helmets when they stop hits. Medkits are not consumed by treatment; the tally cannot establish treatment exposure. During-match treatment is possible, but police-operation post-fight casualty settlement is disabled in these test-range matches. Night-only light effects, heavy-rifle fire against shields, locked doors and other equipment combinations were not isolated in the follow-up.

## Safety metrics and verification

Across the 1,777 recorded runs, **2 timed out**, both the reproduced matrix cases above. There were **45 friendly-fire hit events in 37 runs**: 44 hits in the screen and one in the fresh-seed follow-up. A hit event includes a hit stopped by protection; it is not necessarily a casualty. The simulation recorded 193 stress-induced stray shots, not necessarily friendly hits. These totals count repeated control runs and should not be treated as independent incident rates. No civilians were present.

The direct tactical mechanics fixture passed **16 assertions** on Godot 4.7 stable and 4.4 stable: baseline configuration and SOF kit, hold gating, stress and trait bad-habit overrides, shield, plate and SOF helmet behavior. The strict habit audit passed, all 12 maps built, and door-navigation diagnostics reported zero problems. Six baseline fights also matched across 4.7 and 4.4 on winner, time, casualty counts, shots, hits, friendly hits and timeout; this is a small cross-engine check, not full compatibility certification. Logs are in the results directory.

## Reproduce

Run in a development checkout with a Godot 4 executable; outputs below go to `/tmp` so the recorded evidence is not overwritten. The study runs can take many minutes. Groups may be partitioned by `--shard=i/n` or explicit `--cases`; use separate project copies when running Godot processes concurrently to avoid shared import/cache races. See the source hash manifest for the measured working-tree state; the checkout contained prior uncommitted work. The study used **Godot 4.7 stable**, not the exact 4.7.2 editor/export, which was unavailable in this environment.

```sh
mkdir -p /tmp/violence-range
GODOT=godot
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=matrix --maps=0,3,4 --n=2 --out=/tmp/violence-range/screen-matrix.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=matrix --maps=11 --n=1 --cases=untrained_vs_untrained,militia_vs_sof,regular_vs_regular,regular_vs_police,police_vs_regular,sof_vs_militia,sof_vs_sof --out=/tmp/violence-range/screen-plaza.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=size --maps=0,3,4 --n=2 --out=/tmp/violence-range/screen-size.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=mixed --maps=0,3,4 --n=2 --out=/tmp/violence-range/screen-mixed.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=habits --maps=0,3,11 --n=2 --out=/tmp/violence-range/screen-habits.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=equipment --maps=0,3,11 --n=2 --out=/tmp/violence-range/screen-equipment.jsonl

$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=habits --maps=0,3,11 --n=8 --offset=100 --cases=baseline,no_good:A,no_good:B,good_off:PF04:A,good_off:GD02:A,good_off:HD07:B,bad_on:BH11:A,bad_on:BH27:B,bad_on:BH06:A --out=/tmp/violence-range/holdout-habits.jsonl
$GODOT --headless --path . -s res://tests/test_range_study.gd -- --group=equipment --maps=0,3,11 --n=8 --offset=100 --cases=baseline,kit:no_plates:A,kit:no_helmet:A,kit:no_flashbang:A,kit:shield_point:A --out=/tmp/violence-range/holdout-equipment.jsonl

python3 tools/audit_test_range_coverage.py screen /tmp/violence-range/screen-*.jsonl
python3 tools/audit_test_range_coverage.py holdout /tmp/violence-range/holdout-*.jsonl
python3 tools/analyze_test_range_study.py /tmp/violence-range/screen-*.jsonl --output /tmp/violence-range/screen-tables.md
python3 tools/analyze_test_range_study.py /tmp/violence-range/holdout-*.jsonl --output /tmp/violence-range/holdout-tables.md
$GODOT --headless --path . -s res://tests/test_range_mechanics_test.gd
$GODOT --headless --path . -s res://tests/sof_stress_probe.gd -- --n=10000 --seed=8675309
python3 -m unittest tests/test_range_analysis.py -v
```

## Interpretation limits

Six fights per screen cell are not enough for precise balance estimates: even 6/6 wins has a nominal Wilson 95% lower bound of about 61%, assuming independent Bernoulli observations. The preset matrix reuses the same seed set across cells, and its fixed maps are not a random sample of all maps. The 24-pair follow-up uses fresh seeds on the same three maps and selected cases; it was chosen during exploratory testing, not preregistered, and many comparisons were examined. Estimates and nominal intervals are descriptive, not corrected for multiple comparisons. Other team sizes, maps, door modes, nighttime, actual players and visual/export behavior remain untested. Timeouts and the two deadlocks can themselves distort win-rate and duration comparisons.
