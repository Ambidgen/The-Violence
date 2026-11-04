# Cycle 1.A — the balance harness

**Date:** 2026-10-28
**Task:** EA_TASKS P1.A1–P1.A3 (P1.A4, the 20-seed baseline, is still open)
**Branch:** `arena/17cdd2d5-the-violence-28-oct-26`

## What this cycle had to prove

The four policies run a full 40-week campaign end to end and produce per-run JSON plus a
summary, and every later Phase 1 number is measured through this harness. The bands file
exists and is **report-only**.

## What was built

| File | What it is |
|---|---|
| `tests/policies.gd` | The four policies as code: inheritance, contracts and programs by tag, offers, events, hiring, courses, internal affairs, kit, and which calls to take. Deterministic — every answer is derived from the desk, never from a random number. |
| `tests/rogue_balance_test.gd` | The matrix runner: one child process per seed × policy, its own `XDG_DATA_HOME`, a per-run timeout and kill, then `report.md` + `summary.json` + `run-<seed>-<policy>.json`. |
| `tests/balance_bands.json` | Thirteen Gate 1 bands with aggregation and rationale; `"status": "report-only"`, `"enforce": false`. |
| `tests/policies_test.gd` | Quick-tier gates on the policy layer alone. |

## Evidence in this directory

| File | Status |
|---|---|
| `README.md` (this file) | written |
| `pilot/report.md`, `pilot/summary.json` | the **last** pilot run — regenerated on every push to this branch, so the wall clock in it is that run's. 2 seeds × 4 policies × 40 weeks, 8 runs, 2246–4069 s, Godot 4.7.2, **0 broken runs**, 36 band misses. Every pilot so far produced an **identical table**; the numbers below are from them |
| the smoke | **green** — `rogue_balance_test --smoke` is in the quick tier and passed on 4.7.2 and 4.4.1 in the same runs as `policies_test.gd` (run 40800062910 onward) |
| `baseline/` (20 seeds × 4 policies) | **not run** — P1.A4, one `Run workflow` away (tier=balance); the job commits it here |

This directory is deliberately honest about what has and has not run. The code in this
cycle was written in a sandbox with **no Godot engine**, so it was checked with static
tools only:

- `gdparse` (gdtoolkit 4.5.0) — all three new scripts parse.
- `tools/gd47_check.py` — clean over 131 files (4.7 API, no 4.4-only calls).
- `bash -n tools/run_tests.sh` — clean; `--list` shows the two new suites.
- `.github/workflows/ci.yml` — parsed as YAML; jobs `static`, `headless`, `balance`,
  `full`; events `push`, `pull_request`, `workflow_dispatch`, `schedule`.

What static tools **cannot** confirm is runtime behaviour: child-process spawning, the
per-run data directory actually isolating saves, the 40-week loop terminating in the step
guard, and the derived metrics landing in sane ranges. That is what the first CI run is
for, and this file is updated with its output rather than pre-empting it.

## The pilot, read

The two-seed pilot is not the baseline, but it is the first time the run layer has been
measured through the harness at all, and the shape is the playtest's:

| | cautious | minimal | military-first | accept-all |
|---|---|---|---|---|
| lowest fit | 6.5 | 8 | 6.5 | **2** |
| weeks below $0 | 3 | 0 | 4.5 | **13** |
| lowest account | −$12,748 | $40,386 | −$19,395 | **−$156,073** |
| civilians killed | 3.5 | 4 | 3.5 | **20.5** |
| killed per operation (mean) | 0.33 | 0.25 | **0.18** | 0.33 |
| allies lost at the end | 3 | 2 | 3.5 | 4 |
| allies won back | 0 | 0 | 0 | 0 |
| chief kept | 2/2 | 1/2 | 2/2 | 1/2 |

- **Every pilot produced an identical table** — every metric, to the decimal, on the
  same seeds, including a run on a runner loaded enough to take twice as long. The run layer is deterministic through the harness, which is what makes a
  later cycle's change measurable at all.
- **The policies separate**, which is the first thing this had to show: `minimal` never
  spends and ends with $414k; `military-first` has the best lethality (0.18 mean, 0.21 at
  its worst) and still runs out of money; `accept-all` bankrupts itself (−$302k at the low), kills 20–33
  civilians and is the only policy whose roster reaches zero fit officers.
- **Fit collapses on every policy** (lowest 0–8 against a roster floor of 10), and the
  weeks-under-12 counters are 7.5–28.5 of 40. That is finding B1/B2 territory, now with
  numbers and a reproducible command.
- **Nobody wins allies back.** `allies_regained` is 0 for all eight runs, against a band
  that asks for 0.25. Either the recovery path (standing back above 40) is unreachable
  under these policies, or nothing in the run loop pushes standing back up. Worth a
  look in 1.B/1.C; it is not a harness bug — the line the harness counts is the line
  `politics.gd` prints.
- **Lethality is 0.18–0.38 officers killed per operation** (means; 0.21–0.38 at each
  policy's worst) against a band of 0.15, on every policy including the careful one. That
  is the Gate 1 gap in one number.
- **36 of 52 band checks miss, and none of them is enforced.** The bands are the
  playtest's own figures turned into thresholds; the pilot says the playtest's shape is
  the whole 40-week run, not an edge case. P1.I decides whether the thresholds move or
  the game does.
- **Wall clock: 21–34 minutes per 40-week run**, depending on how loaded the runner is
  (four pilots, eight runs each: 2246, 2352, 2537 and 4069 s). Four at a time is 37–68
  minutes per two seeds, so twenty seeds is **7–11 hours**: the balance job's limit is 18
  hours, and the weekly schedule runs eight seeds rather than twenty.

## How to reproduce

```
GODOT=/path/to/godot tests/rogue_balance_test.gd --smoke
GODOT=/path/to/godot tests/rogue_balance_test.gd --seeds=20 --policy=all --weeks=40 --jobs=4 --json=build/balance
```

`--smoke` is the two-seed shakedown and is part of the quick tier. The second command is
the baseline and takes hours; in CI it is the `balance` job (dispatch with `tier=balance`,
weekly on a schedule, and a two-seed pilot on every `arena/*` push).

## What was checked when the first report landed

1. **No broken runs.** ✓ `broken: []` for all eight runs, both pilots. The harness exits 1
   when a run is broken, so a green job is itself the check.
2. **The shape matches the 28 Oct playtest:** ✓ fit collapses, deficits persist, allies are
   lost. No policy ends comfortably — even `minimal`, which spends nothing, has 5–11 bad
   weeks on the roster.
3. **The policies are actually different:** ✓ and in the expected directions — `minimal`
   signs nothing and banks $414k, `military-first` buys hardware and halves the civilian
   toll, `accept-all` goes broke and kills twenty. Identical rows would have meant an
   answer was being ignored.
4. **The bands' provisional thresholds** against those numbers: **open, for the owner.**
   36 of 52 checks miss, which says the playtest's shape is the whole run rather than an
   edge case. P1.I decides whether the thresholds move or the game does; nothing is
   enforced until then.
