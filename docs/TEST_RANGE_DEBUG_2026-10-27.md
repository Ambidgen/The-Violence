# Test-range fixes and debug — 27 October 2026

This follow-up implements the five recommendations from the [historical pre-fix study](TEST_RANGE_PLAYTEST_2026-10-27.md), in order, and checks them using the **test range and tactical suite only**. It does not play campaign missions. The old results remain unchanged in [`tests/results/test-range-2026-10-27/`](../tests/results/test-range-2026-10-27/); the post-change matches, logs and source hashes are in [`tests/results/test-range-debug-2026-10-27/`](../tests/results/test-range-debug-2026-10-27/).

## Changes

1. **Friendly-lane recovery.** An operator who cannot safely fire attempts a bounded reposition after a delay; WD10 retains its earlier, wider-lane response. Candidate sidesteps check geometry, doors, nearby bodies and friendly firing lanes. An idle blocker can step clear; otherwise the shooter may prefer a visible, clear alternative in the same threat-distance class or try a short route. Routes are checked for nearby teammates and firing lanes and rechecked as they are followed. If there is no safe choice, the operator continues to hold fire. The existing intentional BH26 exception, police beyond-target check and HD11 lift delay remain.
2. **Cover and reload recovery.** Being close to a cover point is no longer treated as concealment. Failed, exposed, unreachable or unproductive candidates are temporarily blacklisted and retried. After three failures or 14 seconds of a continuous search, a dry operator who cannot reach concealment performs an explicitly logged, crouched emergency reload; optional top-ups instead defer. A stoppage can also be cleared exposed after a failed cover search. None of these fallbacks is reported as concealed.
3. **Regressions, diagnostics and real kits.** Decision telemetry is opt-in, separate from UI events and capped at 50,000 records per world, with total and dropped counts retained. It records lane, cover/reload, habit, shield and PF04/GD02 decisions. The new test helper can explicitly use the actual preset kit while its default preserves the legacy generic kit and habit defaults. The `--range` suite adds focused behavior tests, full historical-seed replays and an eight-case range-only determinism fixture.
4. **Shield observation and cautious response.** Shield-stop events identify the shooter, bearer, weapon/penetration class, hit zone and circumstances. Two observed, directly visible intended stops against the same shield within six seconds can prompt a clear visible alternative or a short, checked flank; otherwise the operator retains normal behavior. This is a prototype, not a shield nerf: penetration, frontal coverage and durability rules are unchanged. Unseen impacts, strays and shots through walls do not grant the shooter omniscient knowledge.
5. **Stress/habit reachability.** Stress-triggered bad habits now use a separate accumulator. Each stress input adds `amount * (1 - 0.75 * resistance)` up to 1, including inputs after raw stress has saturated; the accumulator decays and retains the existing habit thresholds, anxiety adjustment and hysteresis. Initial conditions, gas and civilian alarms are included. Raw stress and its other perception, judgment and accuracy formulas remain unchanged. **This is a gameplay balance change**, including in campaign simulations even though campaign playtests were not run.

## Regression and general-debug results

| Check | Result |
| --- | --- |
| Historical friendly-lane seed: map 00, 5 patrol A vs 5 regular B, seed `717920` | Previously a 300 s draw with shots stuck at 28. Now A wins at **63.20 s**, with **60 shots**. |
| Historical cover/reload seed: map 11, 5 untrained per side, seed `721001` | Previously a 900 s draw. Now A wins at **183.07 s**, with **258 shots**. |
| Range suite | **8/8 suites pass** on Godot 4.7 stable and 4.4 stable: script loading, mechanics, focused regressions, the two full replays, eight range determinism cases, strict habit audit, 12-map build and door navigation. The eight tactical fixture digests match on both engines. |
| Diagnostic equivalence | For one complete map 03 replay, telemetry on/off produced identical terminal operator state, match statistics and RNG state. Both historical-seed replays had zero dropped diagnostic events. |
| Focused edge cases | Pass: lane protection and no-route fallback, teammate crossing and interruption cleanup, concealed arrival, emergency reload and deferred top-up, shield arc/penetration and response, stress inputs/decay, PF04 execution, GD02 opportunities, and 50,000-event buffer overflow accounting. |
| Randomized tactical fuzz | **16/16 matches completed**, zero timeouts and no reported script errors; teams up to 8 per side, varied maps, postures, habits, civilians and police rules. All 27 bad habits activated somewhere in this mixed sample; activation does not prove that every associated behavior had an opportunity to execute. |
| Other checks | `gd47_check.py` scanned 125 GDScript files cleanly; six runner tests, seven analysis tests, version metadata, shell syntax and `git diff --check` passed. |

The debug run found and corrected an indentation error introduced while instrumenting PF04: planned room entries had been incorrectly marked arrived without issuing movement. The final direct test now asserts the movement order and only marks arrival at the target; a full replay also requires an execution event. The discarded intermediate results are **not** included in the final dataset.

The two replays demonstrate progress on those particular stalls, not proof that all maps and situations are deadlock-free. Their changed times and winners are expected after behavior changes and diverging RNG histories.

## Fresh post-change matches

The debug sample contains **152 runs** on maps 00, 03, 04 and 11: 32 selected 5v5 preset matchups, 24 team-size runs, eight mixed-lineup runs, 48 SOF habit runs and 40 SOF equipment runs. A assaults and B holds; map geometry and spawns are asymmetric. Preset cases use the whole preset including stats, experience, habits and real equipment. The SOF baseline deliberately gives both 3-person teams **all good habits and no bad habits**, not the standard SOF habit list. Every case has one seed per map for preset/size/mixed or two per map for SOF cases. Habit/equipment baselines are repeated controls, as are regular 5v5 matrix/size cases; they are not extra independent observations.

All 152 runs ended before their map time limit; **three friendly hits** occurred. The lane checks do not eliminate all friendly-fire possibilities, including ballistics and intentional habit exceptions. These small, selected samples are a debugging screen, not a reliable estimate of balance or a head-to-head comparison with the earlier, differently seeded study.

### Presets and team sizes

Each row below has four runs, one per map; `A/B/D` is attacker wins, defender wins and draws.

| 5v5 preset A vs B | A/B/D | Regular team size | A/B/D |
| --- | ---: | --- | ---: |
| untrained vs regular | 0/4/0 | 1v1 | 3/1/0 |
| militia vs patrol | 0/4/0 | 3v3 | 3/1/0 |
| patrol vs militia | 1/3/0 | 5v5 | 2/2/0 |
| regular vs untrained | 3/1/0 | 10v10 | 2/2/0 |
| regular vs regular | 2/2/0 | 2v5 | 2/2/0 |
| police vs SOF | 0/4/0 | 5v2 | 3/1/0 |
| SOF vs police | 3/1/0 | — | — |
| SOF vs SOF | 3/1/0 | — | — |

A first-slot SOF plus four militia against five regulars produced A/B **3/1** when the mixed lineup attacked and **1/3** when it defended. Slot order influences spawns/assignment; leaders and entry order are selected dynamically. Four fights per row are far too few to rank presets or team sizes.

### SOF-only habits and equipment

The all-good/no-bad SOF baseline was A/B **6/2** in eight paired map/seed cases. A change applies to the named team, not a single operator.

| Variant | A/B | Additional observation |
| --- | ---: | --- |
| PF04 off on A | 7/1 | Entry plans and actual movement starts are separately instrumented. |
| GD02 off on A | 4/4 | Sector assignment and scans are instrumented. |
| BH06 on A | 6/2 | Activated in 4/8 fights, across six operator-fight instances. |
| BH11 on A | 6/2 | Activated in 8/8 fights, across 24 operator-fight instances. |
| BH26 on B | 6/2 | Activated in 7/8 fights, across eight operator-fight instances. |
| No plates on A | 1/7 | Equipment effects are not isolated from subsequent RNG divergence. |
| Battle rifles on A | 1/7 | Eight cases do not establish a weapon ranking. |
| Shield on A's first slot | 8/0 | 121 shield stops across these eight fights. |
| Shield on B's first slot | 3/5 | 33 shield stops across these eight fights. |

A shield carrier also has the validated shield kit, including a pistol instead of a primary and additional weight. The results therefore are not a shield-only causal estimate. Eight pairs, repeated controls and many examined variants make all comparisons exploratory.

### Event visibility

Across the 152 runs, telemetry recorded 498 lane-hold starts and 100 recovery attempts (including 68 with no safe route), 26 cover searches, 19 blocked reload episodes, 1,199 PF04 entry plans and 869 entry-movement starts, 5,082 GD02 sector-plan events and 22,339 scans. Plans, scans and retries are events, **not independent operators or completed room entries**. There were 154 shield stops (125 rifle-class, 29 pistol-class) and 33 response attempts: six flanks, five retargets and 22 with no safe option. No diagnostic events were dropped. These totals include repeated controls.

The no-decay theoretical probe of 10,000 varied SOF operators found median resistance **0.802**. For an isolated BH01 threshold, the new accumulator required a median of **13** repeated 0.15 inputs; BH06/BH07 required **7**. These are theoretical input counts without decay, not measured activation rates or a guarantee of activation during combat. In actual play, input timing, decay, anxiety, other habits and behavior opportunities matter.

## Reproduce

Install a Godot 4 executable and run from the repository root. The match outputs below are examples; change the output paths if desired. Reproducing the historical pre-fix results requires the historical source snapshot identified by its original hashes, not the current simulation.

```sh
GODOT=/path/to/godot
GODOT="$GODOT" tools/run_tests.sh --range
python3 -m unittest discover -s tests -p 'test_runner.py' -v
python3 -m unittest discover -s tests -p 'test_range_analysis.py' -v
python3 tools/gd47_check.py
python3 tools/audit_test_range_coverage.py debug tests/results/test-range-debug-2026-10-27/*.jsonl
sha256sum -c tests/results/test-range-debug-2026-10-27/source-sha256.txt

"$GODOT" --headless --path . -s res://tests/sof_stress_probe.gd -- --n=10000 --seed=8675309
"$GODOT" --headless --path . -s res://tests/fuzz_test.gd -- --n=16 --max=8 --seed=261027

"$GODOT" --headless --path . -s res://tests/test_range_study.gd -- \
  --group=matrix --cases=untrained_vs_regular,militia_vs_patrol,patrol_vs_militia,regular_vs_untrained,regular_vs_regular,police_vs_sof,sof_vs_police,sof_vs_sof \
  --maps=0,3,4,11 --n=1 --offset=200 --out=/tmp/range-matrix.jsonl
"$GODOT" --headless --path . -s res://tests/test_range_study.gd -- \
  --group=size --cases=1v1,3v3,5v5,10v10,2v5,5v2 \
  --maps=0,3,4,11 --n=1 --offset=200 --out=/tmp/range-size.jsonl
"$GODOT" --headless --path . -s res://tests/test_range_study.gd -- \
  --group=mixed --cases=A_sof+militia+militia+militia+militia,B_sof+militia+militia+militia+militia \
  --maps=0,3,4,11 --n=1 --offset=200 --out=/tmp/range-mixed.jsonl
"$GODOT" --headless --path . -s res://tests/test_range_study.gd -- \
  --group=habits --cases=baseline,good_off:PF04:A,good_off:GD02:A,bad_on:BH06:A,bad_on:BH11:A,bad_on:BH26:B \
  --maps=0,3,4,11 --n=2 --offset=200 --out=/tmp/range-habits.jsonl
"$GODOT" --headless --path . -s res://tests/test_range_study.gd -- \
  --group=equipment --cases=baseline,kit:no_plates:A,kit:battle_rifle:A,kit:shield_point:A,kit:shield_point:B \
  --maps=0,3,4,11 --n=2 --offset=200 --out=/tmp/range-equipment.jsonl
```

The seed formula is `710001 + 1000 * map + 7919 * rep`, with rep 200 for the first three groups and 200–201 for SOF cases. The debug audit checks exact case/map/seed keys, lineup/change metadata, the stress-model identifier, zero dropped events, actual PF04 movement events and equality of the repeated SOF controls.

## Limits and follow-up

- The range fixture is intentionally separate from the older full-suite fixture, which includes campaign cases and predates these simulation changes. It has **not** been silently regenerated; review campaign determinism and balance separately before updating it.
- These checks used isolated headless **Godot 4.7 stable** and **4.4 stable** runtimes. The project's exact 4.7.2/4.4.1 editor and export targets were unavailable; visual gameplay, native imports and exported builds were not verified.
- The shield response and stress model warrant broader balance evaluation; the sample does not justify a nerf or establish universal habit effects. More maps, door states, loadouts, human play and longer seeded runs remain useful. Randomized fuzz results include civilians and policing rules but no campaign playthrough.
