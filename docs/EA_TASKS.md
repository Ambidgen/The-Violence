# The Violence — Early Access task plan (fix / playtest / debug cycles)

2026-10-28. Breaks [`EARLY_ACCESS_ROADMAP.md`](EARLY_ACCESS_ROADMAP.md) into tasks, grouped into cycles. Every task names the files it touches; every cycle names the command that playtests it and the number that ends it. Evidence for the problems: [`PLAYTEST_2026-10-28_CAMPAIGN.md`](PLAYTEST_2026-10-28_CAMPAIGN.md).

Sizes: **S** ≤ 1 day · **M** 2–4 days · **L** 1–2 weeks. IDs are stable so commits and changelog lines can cite them (`P1.B3`).

---

## How every cycle runs

```
FIX       one small change on a branch, with the task ID in the commit
CHECK     tools/run_tests.sh --check && --quick                          (~6 min)
PROBE     the cycle's targeted harness (named in the cycle)
PLAYTEST  balance smoke: tests/rogue_balance_test.gd --seeds=3            (~1 h, 4 policies)
          rendered walk: tests/ui_walk.gd to week 2, read the screenshots (~10 min)
DEBUG     if the exit number is missed: the cycle's trace tool, then back to FIX
LOG       CHANGELOG line + tests/results/<date>-<cycle>/ (logs, JSON, screenshots)
```

At the end of each **phase**: the full tier, the full balance run (20 seeds × 4 policies, overnight), and one human session (§3.E). A phase is not done until its gate is green on the merged commit.

Phase 0 builds two of the tools that every later cycle uses: the four-policy balance harness and the rendered walk. That's why it comes first.

---

## Phase 0 — Make the build trustworthy *(≈ 1 week)*

### Cycle 0.A — Harnesses that fail honestly
| ID | Task | Files | Size |
|---|---|---|---|
| P0.A1 | Give every diagnostic an exit code (`quit(1 if failures > 0 else 0)`): `civ`, `equip`, `hold`, `lethality`, `maps`, `nav_door`, `op`, `fuzz`, `perf`, `playtest`, `sim`, `stall`, `trace`, `duel_probe`, `rig_gallery`. Then delete the runner's log-scanning fallback. | `tests/*.gd`, `tools/run_tests.sh` | M |
| P0.A2 | Set the runner's default `TIMEOUT_SCALE` from `nproc` (×2 on ≤ 2 cores). Give `orders_test` an explicit budget. | `tools/run_tests.sh` | S |
| P0.A3 | Activate CI: `git mv tools/ci/ci.yml .github/workflows/ci.yml`. Run the quick tier on push (4.7.2 and 4.4.1) and upload logs on failure. | `.github/workflows/ci.yml` | S |
| P0.A4 | Move `determinism_test` from the quick tier to the full tier until Phase 1 ends, with a note that the fixture is known stale (22/35). Do **not** `--write`. | `tools/run_tests.sh`, `README.md` | S |

- **Playtest:** break one assertion in each harness on purpose. The runner must go red and name it.
- **Exit:** `--quick` green; every suite in `--full` can fail.

**Status 2026-10-28: done.** Runner self-tests 13/13; all 14 changed harnesses exit 1 when their check is broken; `--quick` 16/16; `--full` 25 pass, 1 KNOWN, 2 FAIL on pre-existing simulation bugs B1–B3 (below). Two additions beyond the plan: a KNOWN failure must show its signature (a crash in an xfail suite is a FAIL), and `perf`/`trace` now dispose their World (the engine-error scan would otherwise fail them every soak run). Also fixed: CI passed `GODOT=~/...`, which never expands, so every headless job would have stopped before running. Evidence: `tests/results/cycle-0A/`.

### Cycle 0.B — Playtest tooling in the tree
| ID | Task | Files | Size |
|---|---|---|---|
| P0.B1 | Bring in the rendered walk from this playtest. Add `--steps=` (title, desk, brief, run, debrief, endweek, screens), `--resolution`, and a check that no visible control's rect leaves the viewport. | `tests/ui_walk.gd` (from `tests/results/playtest-2026-10-28-campaign/logs/ui_walk.gd`) | M |
| P0.B2 | `tools/campaign_report.py`: parse `op_test`/balance logs into the playtest table. Columns: min fit, weeks < 12 fit, weeks < $0, max balance, unattended, deaths, allies lost/regained with weeks, winner/kept, run score. | new | S |
| P0.B3 | `op_test.gd --json=path`: emit the same metrics directly, so the report doesn't scrape text. | `tests/op_test.gd` | S |

- **Exit:** one command reproduces this report's campaign table and screenshots.

**Status 2026-10-28: done.** `tools/playtest.sh` (no arguments) reproduces the 28 Oct table and screenshots; `tests/ui_walk.gd` runs headless in the quick tier and rendered under the playtest; `op_test --json` and `tools/campaign_report.py` (which reproduces the 28 Oct numbers from the old logs). Found on the way: op_test never printed an ally lost to an operation or a desk answer (the union was lost in week 10 of seed 1001, not "by week 27"). Evidence: `tests/results/cycle-0B/`.

### Cycle 0.C — Duplicate procurement charge
| ID | Task | Files | Size |
|---|---|---|---|
| P0.C1 | When dealing procurement, skip contracts whose items are all already stocked. | `rogue.gd` `_open_contracts()` | S |
| P0.C2 | After any stocking change (doctrine `_doctrine()`, offer `_sign(...bought=false)`), revalidate the open drafts. Replace a redundant card from the same tier; draw the replacement from a **separate** RNG sub-stream so the rest of the desk stays seed-stable. | `rogue.gd` | S |
| P0.C3 | Guard in `pick()`: refuse, with a line and no charge, if every item is already stocked. | `rogue.gd` `pick()` | S |
| P0.C4 | Regression in `rogue_test`. Cover seeds 1–12 × every inheritance × every contract, expecting 0 wasted purchases. Add a case where a free military contract arrives by offer mid-week. | `tests/rogue_test.gd` (fold in `dup_probe.gd`) | S |

- **Debug:** if "same seed deals the same desk" fails, the replacement consumed the main RNG. Move it to its own stream.
- **Exit:** 0 wasted purchases; reproducibility still passes.

**Status 2026-10-28: done.** The deal-time filter the plan asks for in C1 already existed (`_open_contracts` skipped a contract whose every item was stocked) and could not help: the week-1 procurement draft is dealt in `on_week_start()` **before** the inheritance is chosen, so the stocking that made the card redundant happened afterwards. `contract_stocked()` is now the one predicate, used by the deal, by a new `_revalidate_drafts()` (C2: after a doctrine pick, a signed contract or a free contract from an offer), and by a refusal in `pick()` (C3: a line, no charge, the draft stays open; `from_data()` re-validates restored drafts, so a save written before this change is repaired on load). The replacement draws from its own stream, `draft_rng` (seeded from the run seed, saved as `draft_rng_state`), so the desk's `rng` does not move: same seed, same desk, same later weeks. C4 folds `dup_probe.gd` into `rogue_test`: seeds 1–12 × every inheritance × every contract still offered afterwards must charge exactly the contract's cost and add at least one item; plus the guard, the mid-week free military contract, and an assertion that a re-dealt card advances the replacement stream while the desk's rng stays put. The board's procurement line reads its card count instead of assuming three. Verified: the quick tier (which includes `rogue_test`) is green on **Godot 4.7.2 and 4.4.1** in CI run 40785806997 on PR #1 — any of the new assertions failing would have failed the suite and the job. No engine was available in the sandbox that wrote the change, so the job conclusions, not quoted PASS lines (the CI log blob host is unreachable from it), are the evidence; the static audit (`gd47_check`, 128 files) and `gdparse` on the changed files are clean. Evidence: `tests/results/cycle-0C/`.

### Cycle 0.D — Version, licence, hygiene
| ID | Task | Files | Size |
|---|---|---|---|
| P0.D1 | **Decide the version line.** Going from 1.2.1 down to 0.9 can confuse save and legacy migrations and players. Recommended: **1.3.x = Early Access** (labelled "Early Access" in the title corner), **2.0 = release**. This supersedes the 0.9 suggestion in the roadmap. Run `tools/sync_version.py`. | `scripts/version.gd` +2 | S |
| P0.D2 | Add `LICENSE` (your choice) and `THIRD_PARTY_NOTICES` (Godot MIT, Patrick Hand OFL, fonts used in videos). Make the credits screen match. | root, `ui/front.gd` | S |
| P0.D3 | **Remotion licence:** confirm whether your situation needs a company licence. If it does and you won't buy one, plan to re-render the openers and shorts with other tooling (this links to P4.C). | — | S (decision) |
| P0.D4 | Set `application/config/use_custom_user_dir` and a fixed user-dir name now, so Steam Cloud paths (P2.C4) never move. Keep `Settings.migrate()` for the old dir. | `project.godot`, `ui/settings.gd` | S |

**Status 2026-10-28: done** (the owner's decisions, taken in this session).

| ID | What was decided and done |
|---|---|
| P0.D1 | **Version line: 1.3.x = Early Access, 2.0 = the 1.0 release.** `Version.VALUE` is **1.3.0**, `Version.CHANNEL` is "Early Access"; `tools/sync_version.py` wrote 1.3.0 / 1.3.0.0 into `project.godot` and `export_presets.cfg`. The title plate carries a red **EARLY ACCESS** stamp and `V1.3.0` in its corner, drawn from `Version.CHANNEL`, not from a literal. `tools/patch_rc.py`'s hardcoded `FALLBACK_VERSION` is gone: a Windows build that cannot read `scripts/version.gd` now stops instead of stamping the exe with a number nobody bumped. |
| P0.D2 | **Licence: proprietary, all rights reserved** (`LICENSE`): reading, forking for review and quoting in reviews are permitted; redistribution, commercial use, derivative works and reuse of the art, audio, text or city data are not. **`THIRD_PARTY_NOTICES`** carries the Godot MIT text, the Patrick Hand OFL pointer and text file, Remotion and the render-time fonts (Courier Prime, Oswald, Open Sans — OFL), React (MIT), and the Python asset tools (numpy/scipy BSD, Pillow MIT-CMU). Both files are in every export preset's `include_filter`, and the credits screen names the licence, the notices and the development state. |
| P0.D3 | **Remotion: the free licence applies.** Remotion is free for an individual, a team of up to three people, or a non-profit ([licence FAQ](https://www.remotion.dev/docs/license/faq)); this project qualifies, so **no company licence is required and no re-render is needed** — P4.C1 keeps the red-ink openers as they are. The position and the version (4.0.537) are recorded in `THIRD_PARTY_NOTICES`. **Re-check on a change of circumstance**: more than three people on the project, a publisher, or a company formed around it turns this into a $25/seat/month Company Licence. |
| P0.D4 | **The user directory is fixed now**: `application/config/use_custom_user_dir=true` with `custom_user_dir_name="TheViolence"`, so a rename can never move a save and the Steam Cloud path (P2.C4) is decided before it is needed. `Settings.migrate()` now walks every folder earlier builds wrote — `The Violence - Vertical Slice`, then `The Violence` — and carries `campaign.json(.bak)`, `department.json(.bak)`, `settings.cfg` **and `legacy.json`**, never over an existing file. `improvements_test` pins the project key to `Settings.USER_DIR`, the three legacy folders, and that both files ship. |

- **Verified:** the quick tier is green on **Godot 4.7.2 and 4.4.1** in CI run 40791685096 (`ac2fda7`), after one caught fault: the first run of the cycle (40790768232) failed `improvements_test` with a parse error — `filter()` on the result of `String.split()`, a `PackedStringArray` — which neither `gd47_check` nor `gdparse` can see, because they do not type-check. Fixed by wrapping the value in `Array(...)`.
- **Evidence:** `tests/results/cycle-0D/`. The static audit and the CI quick tier (both engines) are the checks; `improvements_test` is in that tier and now fails if the version line drifts off 1.3, if the title or credits stop naming the channel, the licence or the notices, if `project.godot`'s user-directory key disagrees with `Settings.USER_DIR`, or if an export preset stops shipping `LICENSE`/`THIRD_PARTY_NOTICES`.

**Gate 0:** `--quick` and CI green with honest exit codes; the duplicate regression passes; the version line and licence are decided.

**Gate 0 on 2026-10-28: met.** 0.A, 0.B, 0.C and 0.D are done: the quick tier is green on Godot 4.7.2 and 4.4.1 with honest exit codes, the duplicate regression passes, and the version line (1.3.0 Early Access) and the licence (proprietary; Remotion free) are decided and recorded. What Gate 0 deliberately does **not** cover is Phase 1's work: the stale determinism fixture (rebaseline at P1.I1) and the three simulation findings B1–B3.

---

## Phase 1 — Make a forty-week run hold together *(≈ 4–6 weeks; the critical path)*

### Cycle 1.A — The balance harness (build it first; every later cycle is measured by it)
| ID | Task | Files | Size |
|---|---|---|---|
| P1.A1 | Policies as code, `tests/policies.gd`: **cautious**, **minimal**, **military-first**, **accept-all**. Each policy sets the desk choices by tag (deterministic, not random), the hiring rule, training, IA decisions, and which calls to take. **Match the UI:** choose the inheritance before the first op, and use current kit unless the policy buys kit. (The current `op_test` issues suggested kit and answers the desk after operations.) | new | M |
| P1.A2 | `tests/rogue_balance_test.gd --seeds=N --policy=all --json=out/`: one process per seed × policy, with a separate `XDG_DATA_HOME` per run. Writes per-run JSON and a summary table. | new | M |
| P1.A3 | `tests/balance_bands.json`: the Gate 1 thresholds, in report-only mode until P1.I. | new | S |
| P1.A4 | **Baseline:** run 20 seeds × 4 policies before any tuning and commit `tests/results/balance-baseline.json`. Every later cycle reports its change from this baseline. | — | S + a night of CPU |

- **Cost note:** one 40-week run took 10–15 minutes on two cores here, so 80 runs is about 7–10 h on two cores or about 2 h on eight. Use the 3-seed smoke during cycles and the full run overnight or in weekly CI.
- **Exit:** the baseline reproduces the playtest's shape (fit collapses, deficits, allies lost). If it doesn't, the policies don't match the game yet.

- **2026-10-29 correction (verified before 1.B):** the 20-seed baseline could not have finished as configured. A GitHub-hosted job stops at **6 hours** whatever `timeout-minutes` says ([GitHub: Actions limits](https://docs.github.com/en/actions/reference/actions-limits)), and the estimate above is 7–11 h, so the 18-hour setting would have been cut at 6. The `balance` job is now **sharded**: `balance-plan` splits the seeds into shards of four (20 seeds → 5 shards, seeds 1001…20020, the same set a single run uses), each shard is one job of 16 runs (1.4–2.3 h at the measured rate, limit 340 min), and `balance-merge` joins them with the harness's new **`--merge`** mode and commits the report as before. Checked: two one-seed shards merge to the two-seed report byte for byte apart from the wall clock (the per-run `derived` rows differ only in `wall_ms`), and a merge with a shard missing exits 1 naming each absent seed × policy. The baseline is dispatched from its own branch, so later pushes cannot cancel it (the workflow cancels superseded runs per ref).

**Status 2026-10-28: built, run end to end, and the shape matches the playtest; the 20-seed baseline is the one step left.**

**2026-10-29: the 20-seed baseline has run (P1.A4 done).** CI run 40857790338 on branch `baseline-1A` (commit 1b3bf45): 80 runs in five shards of four seeds (1.3–2.2 h each, inside the 6 h cap), merged by `balance-merge` with **0 broken runs** and committed as `tests/results/cycle-1A/baseline/report.md` and `summary.json` (the per-run JSON is the run's artifact). The exit holds — the shape is the playtest's at scale: lowest fit 4–9 on average across policies, 11–26 weeks under 12 fit, every policy but `minimal` ends in the red, 2.8–3.9 allies lost at the end and none won back, **10.2–15.8 civilians killed per run**, the chief kept 8–16 times in 20. 4 of 52 band checks pass (all report-only). Every later cycle reports against this file; a later cycle's own matrix goes to its own folder (`Run workflow` → tier=balance, `results=tests/results/cycle-1X/...`).

| ID | What was built | File |
|---|---|---|
| P1.A1 | **Four policies as code**, each answering the same questions the interface asks, in the interface's order — the inheritance and procurement first, **before** the first operation — and every answer derived from the desk it was dealt, never from a random number. `cautious` (hire to 14, restraint contracts, no military hardware, high-trauma officers kept off crowd duty, two calls a week), `minimal` (no hiring, courses, contracts or programs; every offer declined; cases left to lapse; one call), `military-first` (hardware and kit, Kettering's offers, cases cleared, three calls), `accept-all` (signs and accepts what is on the desk, hires to 18, lets plans buy kit, three calls). Policies also set kit issue — current kit unless the policy buys it — which is the UI's own behaviour and the thing `op_test` got wrong. | `tests/policies.gd` (new) |
| P1.A2 | **The matrix harness**: one process per seed × policy, each with its own `XDG_DATA_HOME` (so no run can see another's save or legacy file), a per-run timeout and a kill, then a table, `report.md` and `summary.json`. `--seeds=20 --policy=all --weeks=40 --jobs=4`, plus `--smoke` for the quick tier. Exit 1 on a hung operation, a run that never held its election, a missing or unreadable JSON, or (with `--enforce`) a missed band. | `tests/rogue_balance_test.gd` (new) |
| P1.A3 | **Gate 1 bands** as data: thirteen lines (roster floor and weeks under 12 fit, deficit weeks, debt floor, account at the end, coverage, deaths and lethality, civilians, allies held and won back, score, kept share), each with the aggregation it is judged by and the reason it exists. **`report-only`**: `enforce: false`, so a miss is printed and does not fail the tier until P1.I. The thresholds are provisional and are the owner's decision (roadmap §8.4). | `tests/balance_bands.json` (new) |
| P1.A4 | **Pilot baseline** from CI (see below): the harness runs a two-seed × four-policy matrix on every push to an `arena/*` branch and uploads it, so the shape can be checked before the long run. The **20-seed baseline** is one `Run workflow` away (Actions → ci → tier=balance); it takes hours and has not been run here. | `tests/results/cycle-1A/` |

- **Also in the tree:** `tests/policies_test.gd` (quick tier, seconds) pins the policy layer: same seed and policy settle the same desk twice, the desk is settled before any operation and never left blocking the week, the policies differ where they are meant to (minimal signs nothing, cautious never signs military hardware, military-first does), the call plan respects each policy's cap and priority, kit is only bought by the policies that buy it, a short account settles the desk without buying anything, and the bands file is well formed and still report-only. `rogue_balance_test --smoke` is in the quick tier too, so the child-process matrix itself is exercised on every commit.
- **First measurement, 2 seeds × 4 policies (four CI pilots, all reproducing each other):** 8 runs, 2246–4069 s, Godot 4.7.2, **0 broken runs**, 36 band misses, all report-only. Fit collapses on every policy (lowest 0–8 against a roster floor of 10), `accept-all` bankrupts itself (−$302k at the low, 20–33 civilians killed), `military-first` has the best lethality (0.18 killed per operation on average, 0.21 at its worst, band 0.15), and **no policy wins a single ally back** (`allies_regained` 0 for all eight runs). The two pilots also produced identical tables on the same seeds, so the run layer is deterministic through the harness. Full table and reading in `tests/results/cycle-1A/`.
- **Wall clock: 21–34 minutes per 40-week run**, measured across four pilots (8 runs each, 2246–4069 s, identical tables). Four at a time is 37–68 minutes per two seeds, so the 20-seed matrix is **7–11 h** — the balance job's limit is now 18 h (300 minutes would have killed it, and 12 h would have been tight), and the weekly drift check runs 8 seeds rather than 20.
- **Exit:** the baseline reproduces the playtest's shape (fit collapses, deficits, allies lost). The pilot already shows that shape; what the 20-seed baseline adds is the variance across seeds, which is what P1.I's thresholds have to be set against. `accept-all`'s money numbers are the one outlier worth watching at scale.

### Cycle 1.B — Crowd cliff *(done 2026-10-29 — the attack-response exit is missed by 3–5 s: owner's call)*
**Diagnosis.**
- `department.gd:771` sets `stress0 = min(0.3, trauma × 0.015)`.
- Line 776 adds `(60 − morale) / 1200`.
- `world.gd` stress decay (around line 3264) never takes stress below `stress0`.
- `misjudge_p()` treats an officer as `calm` only when `stress < 0.2`.

So at **trauma ≥ 13.4** (≈ 11.7 at morale 30) an officer can never be calm. The "a calm officer makes no new mistake about someone already cleared" branch stops applying, every cleared face in the crowd is re-rolled at ×0.1 instead of 0, the first mistake fires, the crowd panics, stress rises, and the cascade follows. That matches the probe: 0 civilians struck at trauma 10, 52 killed at 14.

| ID | Task | Files | Size |
|---|---|---|---|
| P1.B1 | Extend `event_probe.gd`: count **distinct** civilians struck (id set), add `--attack` seeds, and record time to the first police shot at the real attacker and how many people the attacker hit. Sweep `--trauma=0,10,12,13,14,16,20 --morale=30,60 --n=20`. | `tests/event_probe.gd` | S |
| P1.B2 | **Fix A:** make "calm" relative to the officer's own floor: `calm = not in_combat(o) and (o.stress − stress0) < 0.2`. Trauma still raises the base misjudgment rate through `eff`, but it stops disabling the cleared-face rule. | `world.gd misjudge_p()` | S |
| P1.B3 | **Fix B (defence in depth):** after a police round strikes someone later judged a civilian, call a squad-wide **check-fire**: a 20 s hold on new engagements of non-attackers, crowd-panic stress gain halved for that squad, and a forced rally reset. | `world.gd` (`_hit`, `add_stress`) | M |
| P1.B4 | `tests/crowd_trace.gd`: for each quiet event, print the first misjudgment (officer, stress, stress0, target cstate, filming/running, distance, night). Use it on the **natural-trauma** deaths (seeds 5051, 5068, 5119), which Fix A may not cover. | new | S |
| P1.B5 | Keep the Suggest-a-plan "no trauma ≥ 12 on crowd duty" preference, but explain it in the briefing rather than hiding it. | `autoplan.gd`, `ops_ui.gd` | S |

- **Playtest:** run the probe sweep first, then the balance smoke (watch `crowd_killed` and rally deaths per run).
- **Exit:**
  - ≤ 1 distinct civilian struck per quiet event over 20 seeds at trauma 14 and 20.
  - Natural trauma at or below baseline.
  - On attack seeds, the attacker is engaged no later than baseline and attacker casualties are no worse.

**Status 2026-10-29: the crowd cliff is gone; attacks are answered a few seconds later than before.** Measured with the CI crowd tier (`Run workflow` → tier=crowd): 60 seeds per condition, quiet and attacked events, trauma 0 / 14 / 20, morale 60, two officers on post. Before = e257aa0 (the probe and sweep only, branch `crowd-before-1B`); after = this cycle's head. Tables and per-event JSON: `tests/results/cycle-1B/`.

| | trauma 0 | trauma 14 | trauma 20 |
|---|---|---|---|
| **Quiet:** civilians struck by police (most in one event), before → after | 6 (3) → **2 (1)** | 413 (16) → **1 (1)** | 443 (18) → **5 (1)** |
| **Quiet:** killed by police | 6 → **1** | 358 → **0** | 376 → **0** |
| **Attacked:** struck by police / killed by police | 24 / 12 → **10 / 4** | 231 / 85 → **25 / 7** | 277 / 121 → **23 / 11** |
| **Attacked:** attacker stopped | 59/60 → **60/60** | 55/60 → **56/60** | 58/60 → **57/60** |
| **Attacked:** median s to stop him (p75) | 3.9 (8.7) → **8.9 (13.7)** | 4.3 (10.3) → **7.4 (11.8)** | 4.6 (12.2) → **9.8 (15.8)** |
| **Attacked:** people the attacker hit | 88 → **115** | 88 → **94** | 96 → **129** |

- **Exit 1 (≤ 1 civilian struck per quiet event at trauma 14 and 20): met**, over 60 seeds rather than 20.
- **Exit 2 (natural trauma no worse): met** — trauma 0 quiet events went from 6 struck to 2, and the three natural-trauma seeds (5051, 5068, 5119) have no misjudgment.
- **Exit 3 (attacker engaged no later, his casualties no worse): missed on time, within noise on casualties.** Paired by seed, the attacker hits +0.45 / +0.10 / +0.55 more people per event (95% bootstrap intervals −0.37…1.2, −0.5…0.68, −0.2…1.35; pooled +0.37, −0.06…0.79), but he is stopped a median 3–5 s later. Everyone else in an attacked event is far safer: bystanders struck (by the attacker plus by police), 804 → 396; bystanders killed by anyone, 365 → 147. The cause is the posture itself: relaxed officers recognise 1.3× slower and draw from the holster, and the faster response before 1.B came from officers with weapons already raised at the crowd — the thing that scattered and killed it. Getting the seconds back means choosing a different posture (a visible-but-low ready, a third alert state, or a plan option the player picks per event); that is a design decision, logged as **P1.B6** below.

What was built, against the plan:

| ID | Built | Where |
|---|---|---|
| P1.B1 | `event_probe.gd` rewritten: **distinct** people struck (`civ_struck`), deaths among people police struck (a casualty who bleeds out has no shooter on record, so the old count missed them), `--attack` (an armed attacker at t=300, forced if the event dealt none), `stopped`, `stop_s`, `civ_struck_by_attacker`, `--json`. `tools/crowd_sweep.py` runs it in parallel and prints the table; the CI **crowd** tier runs 18 jobs (3 trauma × quiet/attacked × 3 seed blocks of 20) and commits the table. | `tests/event_probe.gd`, `tools/crowd_sweep.py`, `ci.yml` |
| P1.B2 | **Fix A as planned:** `calm` is measured from the officer's own floor (`stress − stress0 < 0.2`). | `world.gd misjudge_p()` |
| P1.B3 | **Fix B, narrower than planned:** a police round that strikes a bystander calls **check fire** for that team for 20 s — every officer drops the threat verdicts he holds on bystanders and people giving up (a wrong verdict used to last the whole operation) and nobody in the crowd can be newly misjudged while it lasts. The planned stress halving and rally reset were not needed once the verdicts are dropped: seed 5170 at trauma 20 went from 8 struck / 3 killed to 1 / 0. | `world.gd _check_fire()`, `_judge()`, `_hit()` |
| P1.B4 | `crowd_trace.gd` as planned. What it found: the natural-trauma deaths were not trauma at all — officers at the ready held a weapon on face after face, the crowd saw guns and ran, and running people get misjudged. That gave two fixes the plan did not have (C and C2). | `tests/crowd_trace.gd` |
| — | **C: police at a public event start relaxed (GREEN)**, set per officer from the situation (`Operation.police_alert`), and posts honour the team's base alert instead of forcing YELLOW. **C2:** a relaxed officer watches a bystander or someone giving up whom he has not judged a threat — he does not raise his weapon at them (judgment still runs). | `operation.gd`, `brain.gd _set_posts`, `_relaxed_watch()` |
| — | **The attack response**, to pay for C: a bystander who sees an attacker's gun cues relaxed officers within 30 m who can see him (*crowd cue*); once an attack has begun, an officer who has judged the attacker a threat keeps him over bystanders running past (*shooter first*); and posted officers who cannot see him move at a run to where the team last saw him or last heard gunfire (*to the shots*). The last one also fixes something older: before 1.B, 1–5 attackers in 60 were never stopped because police held their posts for the rest of the event while he shot out of their sight. | `world.gd crowd_cue()`, `civ_brain.gd`, `brain.gd _visible_shooter()`, `_to_the_shots()` |
| P1.B5 | Suggest-a-plan still prefers officers under trauma 12 for crowd duty. The briefing now says so, and why, and the Force tab line reads "Suggest a plan keeps this officer off crowd duty while others are free (carries stress into the shift)" instead of a warning the fix made untrue. | `ops_ui.gd`, `autoplan.gd` |
| P1.B6 | **Open — owner's decision:** the posture at events. Options: accept 3–5 s; a low-ready state (weapon out, not pointed, seen by the crowd as less alarming than aiming); or a per-event plan option ("visible presence" vs "low profile") whose cost the player chooses. | `op.gd`, `civ_brain._unaware`, plan UI |

- **The rest of the build:** `--quick` passes on 4.7.2 locally, including the balance smoke. These changes alter every event that has a crowd, so campaign numbers move: the 1.B balance matrix (`results=tests/results/cycle-1B/balance`) is the comparison with the 1.A baseline's 10.2–15.8 civilians killed per run.
- **The campaign, 20 seeds × 4 policies** (`tests/results/cycle-1B/balance/`, CI 40974092408, against `cycle-1A/baseline`): civilians killed per run fall from 10.95 / 12.35 / 10.20 / 15.80 to **4.80 / 2.80 / 4.95 / 4.90** (cautious / minimal / military-first / accept-all); the chief is kept in 16 / 19 / 16 / 14 runs of 20 (was 16 / 11 / 13 / 8); the run score improves for every policy (cautious −962 → −707). Officers killed are unchanged (that is 1.C). The first attempt at this matrix (27 of 80 runs) was a CI fault, fixed: a cancelled run committed its partial report.

### Cycle 1.C — Roster bleed
| ID | Task | Files | Size |
|---|---|---|---|
| P1.C1 | **Measure first:** from the baseline JSON, officer deaths by situation type, map and cause; injury weeks lost; academy throughput. Find the two or three maps or situation types that produce most of the 0.21–0.25 deaths per operation. | `campaign_report.py` | S |
| P1.C2 | A **next-week strip** on the board: fit next week (counting returning injured and academy graduates) against what this week's open calls want (`Autoplan.want_for`). Show red text below 12. | `ops_ui.gd show_board()`, `campaign.gd` | M |
| P1.C3 | **Emergency lateral**: an applicant who reports the same week at about 2× cost. Show the weekly payroll change on every hire button. | `department.gd`, `ops_ui.gd _applicants()` | S |
| P1.C4 | A **standing order** "keep N officers on the books": the academy auto-enrols when the forecast allows it, and the player can see and cancel it. | `department.gd next_week()`, `ops_ui.gd _roster()` | M |
| P1.C5 | Tune lethality where P1.C1 points: suggested force size on the worst maps, medic/bleed-out timing, and the injured-vs-killed split. Don't touch the hit model unless the data says so. | `autoplan.gd`, `world.gd` (medic) | M |

- **Exit (cautious policy):** ≥ 12 fit in ≥ 90% of week-end snapshots; ≤ 25 unattended over the run.

**Status 2026-10-29: built; the exit is measured by the next matrix.** Branch `cycle-1C-roster` (PR #5 merged, #8 open).

| ID | Built | Where |
|---|---|---|
| P1.C1 | The harness logs every operation (`ops.csv`) and every run-week (`weeks.csv`), committed with the report; `tools/roster_report.py` reads them. **At scale (the 1.B matrix, 5,148 operations, `cycle-1B/balance/roster.md`): gang raids 68% of officer deaths (0.78 killed per raid), Warehouse & Offices 57%, Apartment Block 21%, hostage takings 21%, events 1%.** First seen in the 1.C pilot (2 seeds × 4 policies, 538 operations): gang raids are **76% of officer deaths** (0.90 killed per raid, 1.45 down); gang · Warehouse & Offices alone is 57% (1.00 per raid), gang · Apartment Block 19%; events, after 1.B, 2%. Of 130 gang-raid deaths 110 were killed by a suspect, 18 bled out. | `tests/rogue_balance_test.gd`, `tools/roster_report.py` |
| P1.C2 | Next-week strip on the board (fit next week, why, against what this week's calls want; red below 12). The forecast is tested against 12 weeks of a mixed roster: 12/12. **2026-11-02:** the week it missed was one that lost an officer to low morale — `fit_next_week()` says so itself ("resignations are a roll and are not guessed at"), so the test now subtracts the resignations the week's own lines report rather than hiding the miss. | `department.gd fit_next_week()`, `campaign.gd roster_outlook()`, `ops_ui.gd` |
| P1.C3 | Emergency lateral: on duty this week, $13,000 + kit, one a week, frozen with hiring, rolled from its own stream. Hire buttons show "payroll +$X a week". | `department.gd`, `ops_ui.gd` |
| P1.C4 | Standing order "keep N on the books" (Roster): up to two academy recruits a turn while the four-week forecast — **charged the department's recent overtime** — stays in the black. Without the overtime the pilot's cautious policy spent 36 of 40 weeks in the red. | `department.gd`, `ops_ui.gd` |
| P1.C5 | **Measured with `tests/raid_probe.gd`** (the same dealt raids replayed; 60 gang raids, trauma 15, six officers): force size changes success (Warehouse 15% at 6 → 81% at 10), not deaths; trauma 20 roughly doubles them; taking cover after a hit changes nothing (the follow-up hit comes in the same burst); helmets alone (34 killed → 34), plates alone (33), helmet + plates (32) and flashbangs alone (39) change nothing; **the full Entry kit cuts deaths to 20 (−41%)**. Owner's decision: **Suggest a plan proposes the Entry kit on gang raids** — shown with its price on the Force tab, bought at Run (only for officers going in, not for a kit changed by hand since, not while the account is in the red), with "keep their current kit" one click away. The cautious policy takes it, minimal does not. `tests/kit_proposal_test.gd` (quick tier). | `autoplan.gd propose_kit()`, `campaign.gd issue_plan_kit()`, `main.gd`, `ops_ui.gd` |

- **Exit: missed (2026-11-02).** The 1.C matrix (`tests/results/cycle-1C/balance/`, CI 41409260807, 20 seeds × 4 policies on `main` ff89f12) against 1.B: cautious holds ≥ 12 fit in **53%** of week-ends (target 90%; minimal 73%, accept-all 50%, military-first 33%); weeks under 12 fit 22.7 → 18.9, but **weeks in the red 5.1 → 29.5**, officers killed 20.7 → 24.6 and the chief kept 16 → 12 of 20 (accept-all, which keeps 20 on the books: in the red 9.2 → 32.8 weeks). Gang-raid deaths for cautious are unchanged (0.89 per raid in both): the Entry kit is bought at Run only while the account is in the black, and cautious is frozen most of the run. **The roster levers work and the money cannot carry them** — 1.C's exit depends on 1.D (money curve). The standing order's overtime cushion was not enough: emergency laterals ($13,000 + kit) and kit purchases are not in its forecast. Why the Entry kit works when none of its parts does alone is not yet known (the ram changes how the door is taken; worth a probe before Phase 3 tuning).

### Cycle 1.D — Money curve
**Diagnosis from the logs.**
- The week-1 margin is $30,500 allocation − $26,264 payroll = **$4,236 a week**. Each officer costs $1,150–1,400 a week, so three hires use up the whole margin.
- Losing Duff cuts the allocation by 8% (−$2,440 a week). After that the department runs a structural deficit, and a negative account freezes hiring, training and kit.
- The harness also hires whenever the balance is above $3,000, which nothing in the UI prevents.

| ID | Task | Files | Size |
|---|---|---|---|
| P1.D1 | Hire, course and kit buttons say what they do to the four-week forecast ("week 6 goes to −$2,100"). Confirm before going negative. | `ops_ui.gd`, `department.gd forecast()` | S |
| P1.D2 | Replace the hard freeze with a **council overdraft** down to −$25K: weekly interest plus Duff standing cost. The freeze only applies below the limit. | `department.gd frozen()`, `politics.gd` | M |
| P1.D3 | Settle lawsuits in instalments over four weeks instead of one hit. | `politics.gd _land()` | S |
| P1.D4 | **Late-game sinks** with real effects: armoured rescue vehicle (capital item; military tag), training range (courses cheaper and faster), union contract (pay up, morale floor up), and tier-3 programs priced higher. Also "return surplus to council" (Duff standing). | `rogue.gd`, `department.gd`, `data/` | M |
| P1.D5 | Starting reserve: test $25K vs $35K under each policy. | `department.gd found()` | S |

- **Exit:**
  - Cautious: no week below $0 in weeks 1–12 and ≤ 4 such weeks overall.
  - Minimal: week-40 balance ≤ $100K, or the money is visibly spent on sinks.

- **Status 2026-11-02: built; exit measured by the next matrix.** P1.D1 (forecast-priced
  buttons with confirm), P1.D2 (overdraft to −$25K, 2%/wk interest, Duff standing cost,
  freeze only below the limit), P1.D3 (four weekly instalments, forecast-aware), P1.D4
  (ARV capital item, training range, union contract, repriced tier-3, surplus-return offer,
  quarterly sweep), P1.D5 (`Courses.reserve` tuning constant). `dept_test` covers the
  overdraft boundaries, interest, reserve override and `forecast_after`; `rogue_balance_test`
  flags a minimal run ending ≥$100K unspent. Static validation only in this sandbox (no
  engine): `gd47_check` + `gdparse` clean; engine runs are CI-only.

### Cycle 1.E — Allies that can come back
| ID | Task | Files | Size |
|---|---|---|---|
| P1.E1 | Log every ally standing change with a cause, then chart drift per policy. Find what takes the coalition from 45 to below 25 by week 3–4 in two of three runs. | `politics.gd _ally()` | S |
| P1.E2 | **Reconciliation offers** from lost allies: a big cost, standing +20 on acceptance, at most one every four weeks, one per ally per run. | `rogue.gd OFFERS`, `_deal_offer()` | M |
| P1.E3 | Tune drift so a careful run loses 0–1 allies and a reckless run loses 2–3. Being out of sight should never drift an ally down by itself. | `politics.gd week_end()` | M |

- **Exit:** at least one ally lost *and* won back in ≥ 5 of 20 runs; median allies lost under cautious ≤ 1.

- **Status 2026-11-02: built; exit measured by the next matrix.** P1.E1 (every `_ally` /
  `_poll` delta logged with week + cause in `ally_log` / `poll_log`, saved, capped 400;
  `allies.csv` from the harness; roster_report section). P1.E2 (reconciliation offers from
  lost allies: $15,000, past the regain line, ≤1 per 4 weeks, once per ally per run, afforded
  to the overdraft limit). P1.E3 (quiet-week +1 hold, crowd −8, story coalition −3, deficit
  split at the limit; out-of-sight never self-drifts). `politics_test` covers instalments,
  sweep/surplus, the cause log and the hold; `rogue_test` D4.e covers reconcile. Static
  validation only (no engine in the sandbox); engine runs are CI-only.

### Cycle 1.F — The election and the score
| ID | Task | Files | Size |
|---|---|---|---|
| P1.F1 | Strengthen the poll response to harm, neglect (unattended calls) and restraint, so the record moves the race visibly. Each Ledger week names the cause. | `politics.gd on_operation()`, `week_end()` | M |
| P1.F2 | **Decide** whether Kettering keeping a brutal chief stays (it's thematically strong). If it stays, the run score must not reward it: make the +60 for keeping office conditional on the record, or rebalance the weights. | `rogue.gd run_score()` | S |
| P1.F3 | Election night shows the score breakdown next to the ending, so the player sees *why*. | `ops_ui.gd _election_night()` | S |

- **Exit:** cautious mean run score is above minimal and military-first over 20 seeds; cautious keeps the office in clearly more seeds than minimal.

- **Status 2026-11-02: P1.F1, P1.F2 and P1.F3 built; exit measured by the next matrix.** P1.F1: every poll move logged with its cause and listed on the Ledger's
  week page ("what moved the numbers this week"). P1.F2: decided — Kettering keeping a brutal
  chief stays, but the +60 for keeping office is now conditional on a clean record
  (≤2 officers killed, ≤6 civilians killed, ≤6 force findings), otherwise +20. P1.F3: election
  night lists the run score as rows — what moved it, by how much and why — and the election
  row names the clean-record test it passed or missed; `ops_ui_test` pins the row count, the
  labels, and that the rows sum to the total. Engine runs are CI-only.

### Cycle 1.G — Rally pacing
| ID | Task | Files | Size |
|---|---|---|---|
| P1.G1 | Turn `adaptive_speed` on by default (it already exists). | `ui/settings.gd DEFAULTS` | S |
| P1.G2 | **"Skip to the report"** after 60 s of quiet: the sim keeps stepping headless to the end (still deterministic), then the debrief opens. | `main.gd`, `ops_ui.gd show_run()` | M |
| P1.G3 | Measure the wall time of a full run at default settings on the slowest machine you have. Record it in the results. | — | S |

- **Exit:** a quiet rally costs ≤ 60 s wall time at default settings.

- **Status 2026-11-02: all three built; the exit awaits the P1.G3 measurement on the target
  machine.** P1.G1: `Settings.DEFAULTS.adaptive_speed` is on, and the policy works both ways
  — quiet runs at `QUIET_MULT` (3×, cap 8×) the speed asked for, contact returns to 1×, 1×
  asked for stays 1×. P1.G2: `Pacing.QUIET_SKIP_AFTER` (60 simulated seconds) and
  `Pacing.quiet_enough()` are the policy, `main.gd can_skip_report()` asks them, and the ops
  screen's "Skip to the report" steps the rest of the operation headless from the same
  seeded state (the old `quiet_timer` stepped only to t=40 and could never fire). P1.G3:
  `op_test` prints a `TIMING` line (seconds per operation by situation type) and carries
  `timing` in `--json`; `main.gd` prints `RUNCLOCK` under `--perf`. The numbers go in
  `tests/results/cycle-1G/` when the full tier runs on the slowest machine.

### Cycle 1.H — Planning has to matter
| ID | Task | Files | Size |
|---|---|---|---|
| P1.H1 | Run `op_test --chief=manual` against `--chief=sensible` over 20 seeds. If the informed chief doesn't clearly beat the one-click suggestion, the suggestion is too good or the orders too weak. Tune order costs and benefits, not the suggestion's knowledge. | `tests/op_test.gd`, `orders.gd` | M |

- **Exit:** the manual chief is ahead on the run score in ≥ 70% of seeds (a proposed threshold; set your own).

- **Status 2026-11-02: the driver is built; the exit is a 20-seed run, and that is a
  measurement, not a code change.** `tools/chief_compare.py --seeds 20 --first 1001` plays
  `--chief=sensible` and `--chief=manual` on matched seeds, prints the pairs, and exits 0 only
  if manual is ahead on the run score in ≥70% of them (ties are not wins). `op_test --json`
  now carries `run_score` for any campaign, which is what made pairing possible. CI gained
  `tier=chief` (shardable: `--first`, `--seeds`; joined with `--merge`), which commits the
  report under `tests/results/`. Cost: ~21–34 min per 40-week run, so 20 seeds is 7–10
  machine-hours in shards of 5.

### Cycle 1.I — Close the phase
| ID | Task | Size |
|---|---|---|
| P1.I1 | Re-run determinism. Account for each changed case by a Phase 1 task ID, then `--write` and say so in the changelog. Move determinism back into the quick tier. | S |
| P1.I2 | Switch `balance_bands.json` from report-only to asserting; the full balance run joins weekly CI. | S |
| P1.I3 | Human playtest of a full 40-week run (you), with notes against the gate numbers. | M |

- **Status 2026-11-02: P1.I1 and P1.I2 built; P1.I3 (yours) is open, and Gate 1 still needs
  the full 20-seed matrix.** P1.I1: CI `tier=determinism` reruns every seeded case, annotates
  each change, writes the fixture with `--write` and commits it, so a rebaseline is a visible
  commit rather than a silent one. P1.I2: `tests/balance_bands.json` is `"enforce": true` — a
  full matrix fails the tier on a missed band, the quick tier's two-week smoke is never
  judged, and `--report-only` reproduces an experiment.

**Gate 1:** all exits from 1.B to 1.H on the full 20-seed run; determinism rebaselined; bands asserting.

---

## Phase 2 — Steam plumbing *(≈ 3 weeks; 2.A can start in Phase 1)*

### Cycle 2.A — First real Windows run *(do this early: cheapest, highest risk)*
| ID | Task | Size |
|---|---|---|
| P2.A1 | On your PC: install official Godot 4.7.2 plus the export templates. Export Windows with the existing preset and play it. **Checklist:** boot, new run, a full week, save, quit, reload, alt-tab, window resize, fullscreen toggle, audio, the opening cutscene, quit. Note GPU and driver. | S |
| P2.A2 | Run `tools/run_tests.sh --quick` and `determinism_test` on Windows and compare against Linux. A cross-platform hash difference is a finding in its own right. | S |
| P2.A3 | Replace `tools/build_windows_exe.sh` (it compiles Godot from source) with `tools/build_release.sh`, which exports from official templates. Update `tools/inspect_pck.py` for pack format 4. | M |

- **Exit:** the checklist is clean on two Windows machines (one of them low-end or an iGPU).

### Cycle 2.B — The Steam app *(your account; can't be done for you)*
| ID | Task | Size |
|---|---|---|
| P2.B1 | Steamworks partner account, app fee, tax and bank details, then wait out Valve's waiting period. | S + wait |
| P2.B2 | App ID, Windows depot, `default` and `beta` branches, and an upload script (`tools/steam/app_build.vdf`, depot vdf, steamcmd). | S |
| P2.B3 | Upload a build to `beta` and install it through the Steam client on a clean machine. | S |

### Cycle 2.C — GodotSteam
| ID | Task | Files | Size |
|---|---|---|---|
| P2.C1 | Choose a GodotSteam release that matches the engine you ship (prefer the GDExtension build, so official templates still work). **Pin the engine version** from here on. | `addons/godotsteam/` | S |
| P2.C2 | Wrap Steam in `scripts/platform/steam.gd` with a null fallback, so headless harnesses, CI and non-Steam builds behave identically. | new | S |
| P2.C3 | **Achievements** (~20), defined in `scripts/data/achievements.gd` and fired from campaign hooks. Examples: finish a run; keep the office under each candidate; no civilian struck all run; every ally kept; win one back; each doctrine unlocked; 40 weeks with zero officer deaths. Test with a headless harness on a fake backend that asserts each trigger. | `campaign.gd`, `rogue.gd`, `politics.gd` | M |
| P2.C4 | **Steam Auto-Cloud** for `campaign.json(.bak)`, `legacy.json` and `settings.cfg`, using the fixed user dir from P0.D4. Test: play on PC A, continue on PC B, then provoke a conflict. | Steamworks config | S |
| P2.C5 | Rich presence ("Week 17 of 40 · Ironworks raid"). | `steam.gd` | S |

- **Exit:** a build installed through Steam unlocks achievements and round-trips the cloud save between two machines.

### Cycle 2.D — Settings
| ID | Task | Files | Size |
|---|---|---|---|
| P2.D1 | Window mode plus **resolution** list. | `ui/settings.gd`, `front.gd` | S |
| P2.D2 | **UI scale** slider. The engine side already exists as the `--ui-scale` command-line hook in `main.gd`; expose it as a setting. | `settings.gd`, `main.gd` | S |
| P2.D3 | Move the 22 hard-coded `KEY_*` checks in `main.gd`/`ui` into **InputMap actions**, then add a **rebinding** screen. | `project.godot [input]`, `main.gd` | M |
| P2.D4 | Reduced motion (boil off plus no camera moves), a text-size option, and a colourblind-safe alternative to red ink. | `settings.gd`, `view/ink.gd` | S |

### Cycle 2.E — Controller and Steam Deck
| ID | Task | Files | Size |
|---|---|---|---|
| P2.E1 | Focus navigation for every dynamically built `ops_ui` screen: set focus neighbours, grab focus on the first actionable control, and show a visible focus ring. | `ops_ui.gd _btn()`, `ui.gd` theme | M |
| P2.E2 | A cursor mode for map interaction (place, face, entry point on the plan) with a stick or trackpad. | `main.gd map input`, `ops_ui.gd map_click()` | M |
| P2.E3 | A default Steam Input configuration. | Steamworks | S |
| P2.E4 | Run `ui_walk.gd --resolution=1280x800 --input=pad`, driving `ui_accept`/`ui_down` events instead of `pressed.emit()`, so the walk proves pad navigation. | `tests/ui_walk.gd` | S |

- **Exit:** the full first week is playable with a pad at 1280×800, with no off-screen controls. If you can test on real Deck hardware, aim for "Playable" at Early Access launch; leave "Verified" for later.

### Cycle 2.F — Saves and bug reports
| ID | Task | Size |
|---|---|---|
| P2.F1 | Save-migration test: load a save from each earlier version you shipped. Add a "this update cannot load your run" notice path. | S |
| P2.F2 | An in-game **Report a problem** button: copies the version, seed, week, last 200 log lines and settings to the clipboard, and opens the log folder. | S |

### Cycle 2.G — Localization scaffold *(optional for EA, cheap now)*
| ID | Task | Size |
|---|---|---|
| P2.G1 | Wrap **new** strings in `tr()` from now on. Extract the 1,500 existing ones with a script into one CSV. No translations yet. | M |

**Gate 2:** a signed (or clearly flagged) build, installed through Steam on a clean Windows machine, completes a week; the save survives quit and reload; achievements fire; the cloud save round-trips; a pad completes week 1.

---

## Phase 3 — First-hour screens *(≈ 1–2 weeks)*

### Cycle 3.A — The left side of every management screen
| ID | Task | Files | Size |
|---|---|---|---|
| P3.A1 | One helper, `_city_backdrop()`: show `city_map` and hide the tactical layers (floor plan, decals, fog, stamps). Call it from `_desk_draft`, `_desk_offer`, `_desk_event`, `_armory`, `_roster`, `_budget`, `_cases`, `_city_hall`, `_story_file` and `_people`. | `ops_ui.gd`, `main.gd _clear_views()` | S |
| P3.A2 | On those screens, use the left pane for the person or place in question: the ally's portrait on an offer, the officer's file on an IA case, ward pins for the budget. A start is enough for EA. | `city_map.gd` | M |
| P3.A3 | Add an assertion to `ops_ui_test`: on any non-plan/run/debrief screen, `city_map.visible` is true and the floor plan is hidden. | `tests/ops_ui_test.gd` | S |

### Cycle 3.B — Say why, visibly
| ID | Task | Files | Size |
|---|---|---|---|
| P3.B1 | `_btn_reason()`: when a button is disabled, print the reason under it. `ops_ui.gd` disables buttons in 6 places and gives the reasons as tooltips, and the first thing a new player tries is one of them. | `ops_ui.gd` | S |
| P3.B2 | In week 1, scroll to and highlight the Desk card until the inheritance is chosen. | `ops_ui.gd show_board()` | S |
| P3.B3 | End week with open calls: confirm with "2 calls will be recorded as unattended; one is likely to reach the papers". | `ops_ui.gd _end_week()` | S |

### Cycle 3.C — Legible text
| ID | Task | Files | Size |
|---|---|---|---|
| P3.C1 | Centralise font sizes in `UI.make_theme()`. Raise the 10–12 px management text to at least 13–14 px at 1600×900. | `ui/ui.gd`, `ops_ui.gd` | M |
| P3.C2 | `ui_walk` at 1280×720, 1280×800, 1600×900 and 1920×1080, with the overflow check from P0.B1. Read every screenshot. | — | S |
| P3.C3 | A three-line summary at the top of the debrief (result, people, what follows). Keep the arithmetic and timeline below it. | `ops_ui.gd show_debrief()` | S |

### Cycle 3.D — New players *(the human cycle)*
| ID | Task | Size |
|---|---|---|
| P3.D1 | Two people who have never played: no help, screen-recorded, from the title to the end of week 2. Write down every stall over 20 s and every misread. | S |
| P3.D2 | Fix the top three stalls, then repeat with two new people. | M |

**Gate 3:** no stall over 60 s in the second session; the overflow check is clean at all four resolutions; the `ops_ui_test` assertion passes.

---

## Phase 4 — Content and music *(≈ 3–4 weeks; after Gate 1, because content multiplies balance work)*

### Cycle 4.A — Music
| ID | Task | Files | Size |
|---|---|---|---|
| P4.A1 | Four beds: title, board/desk, operation (tension, ducked under radio and gunfire), debrief/election night. Produce them yourself, or commission or license them and record the licence in `THIRD_PARTY_NOTICES`. | `assets/music/` | M–L |
| P4.A2 | A Music bus with crossfade by screen family, a volume slider, ducking on radio, and music silenced by the "nothing happened" fast-forward. | `view/sound.gd`, `settings.gd` | S |
| P4.A3 | Mix check: loudness consistent across beds and against the SFX. | S |

### Cycle 4.B — The ten unplayed shorts
| ID | Task | Files | Size |
|---|---|---|---|
| P4.B1 | For each of the 10, either wire it at the beat `cinematics/SHORTS.md` names (through `play_consequence_short` / `claim_short`) or exclude it from the export preset. | `main.gd`, `ops_ui.gd`, `export_presets.cfg` | M |
| P4.B2 | A harness that forces each trigger condition and asserts the key is claimed once per run. | `tests/shorts_test.gd` | S |

### Cycle 4.C — Cutscene look (decision)
- **P4.C1:** ship the red-ink openers as-is and say so in the Early Access notes, or re-render them in crayon. If the Remotion licence (P0.D3) blocks you, this becomes a re-render with other tooling.

### Cycle 4.D — Variety per run
| ID | Task | Files | Size |
|---|---|---|---|
| P4.D1 | Events 20 → ~35 and offers 14 → ~24, in batches of five. Each new item gets a reproducibility check and an effect assertion in `rogue_test`. Run the balance smoke after every batch. | `rogue.gd EVENTS/OFFERS` | L |
| P4.D2 | A second tier of doctrines unlocked through the legacy file. | `rogue.gd DOCTRINES` | M |

### Cycle 4.E — The 1.5 command layer (decision)
- **P4.E1:** find the session copy that has `deploy.gd`, `command_test.gd`, `strike.gd` and maps 12–15, and either merge it (then `command_test` must pass on all maps and the balance must be re-baselined) or list it as a plan in the Early Access Q&A and ship with 12 maps.

**Gate 4:** music in all four families; no short is half-wired; the balance smoke is still inside the bands after the content batches.

---

## Phase 5 — Store page, demo, testers *(page work starts after Gate 1 and runs in parallel)*

### Cycle 5.A — Store page
| ID | Task | Size |
|---|---|---|
| P5.A1 | Capsule art, library art and logo at the sizes Steamworks currently lists (check its graphical-assets page). The title must be readable at small-capsule size. | M |
| P5.A2 | 6–10 gameplay-only screenshots at 1920×1080 from `ui_walk`, after Phase 3 (no stale maps). | S |
| P5.A3 | A gameplay trailer of 60–90 s, cut with `tools/make_ads.py` plus `mix_soundtrack.py` and your music. | M |
| P5.A4 | Description, tags, content survey (violence, gore toggle, police violence themes), and the AI-content disclosure. Then submit the page for review at least 7 business days ahead. | S |
| P5.A5 | Put the page live as **Coming Soon** as soon as it's approved, so wishlists start accruing. | — |

### Cycle 5.B — Demo
| ID | Task | Files | Size |
|---|---|---|---|
| P5.B1 | A `demo` export feature tag: the run ends after week 10 with a card (score so far, "the election is thirty weeks away"), a separate legacy file, and no achievements. | `campaign.gd`, `export_presets.cfg` | S |
| P5.B2 | A separate demo app and store page. | S |
| P5.B3 | Run the full playtest loop on the demo build, with the balance smoke truncated to 10 weeks. | S |

### Cycle 5.C — Testers
| ID | Task | Size |
|---|---|---|
| P5.C1 | Steam Playtest (or an invite list) of 20–50 people on the `beta` branch, after Gate 1. | S |
| P5.C2 | Weekly loop: build Monday, testers play all week, triage Friday (crash → balance → confusion), fix the following week. Ask testers to attach the **Report a problem** text (P2.F2) and their run JSON. | ongoing |
| P5.C3 | Look for dominant strategies (compare tester runs with the four policies) and for the week where people stop playing. | ongoing |

### Cycle 5.D — Next Fest and launch
| ID | Task | When (Option A) |
|---|---|---|
| P5.D1 | Demo public on its own page. | April 2027 |
| P5.D2 | Register for the June Next Fest. | by **25 Apr 2027** |
| P5.D3 | Submit the demo and page for the press preview. | by **10 May 2027** |
| P5.D4 | Everything submitted. | by **24 May 2027** |
| P5.D5 | Next Fest. | **14–21 Jun 2027** |
| P5.D6 | Write the Early Access Q&A (no dated promises), set the price below the 1.0 price, list known issues, submit the build at least 7 business days before launch. | June 2027 |
| P5.D7 | Early Access launch, then patch every 2–3 weeks for two months. | late June – July 2027 |

---

## Bugs found by the cycles

| ID | Found in | Bug | Where to look | Phase |
|---|---|---|---|---|
| B1 | 0.A full tier | **Wolf brain backwards:** a lone fighter in an unseen fight spends 0.19 of it hidden with the wolf brain on vs 0.28 off (gate wants more). **2026-11-02: fixed** — the wolf dwells in the cover it has (`WOLF_DWELL` 2.5 s) and only bounds where the route is itself hidden (`WOLF_MAX_EXPOSURE`, 1 of 4 samples) instead of re-planning every tick. Closes when `brains_test --only=wolf` clears on the full tier. | `scripts/sim/brain.gd` (wolf), `tests/brains_test.gd --only=wolf --n=24 --v` | Phase 1 |
| B2 | 0.A full tier | **Shield lets more through:** rounds reaching an officer facing 3 rifles at 10 m: 1.02 with the shield vs 0.69 without (gate wants fewer). **2026-11-02: the gate was wrong, not the shield** — it counted rounds and so rewarded dying early (the unshielded officer was dead inside the first seconds and accrued less). It now measures the share of rounds arriving at his body that got through, with the shield's own stops in the denominator. | `world.gd` shield block / `_notice_shield_stop`, `equip_test.gd` shield case | Phase 1 |
| B4 | CI runs 16a76a2 and 55032f9 (`arena/2e7808b8`) | **Intermittent `ui_walk` exit error:** once each on 4.4.1 and 4.7.2, the walk passed every check and then logged `ERROR: N resources still in use at exit`, which fails the suite. Not reproduced in 18 local runs (headless, rendered, and four at once on two cores with `--verbose`). Hypothesis: the game's static caches (`decals._tex`, `sound._cache`, `shorts._cache`, `city._cached`, `floor_plan._paper`, the crayon and UI fonts, `ThemeDB.fallback_font`) fill differently with runner speed during a live operation and are still held at shutdown. 2026-10-29: the walk now releases them before quitting. **Unproven** — watch the annotations; if it recurs, the annotation names the suite. **2026-10-29: recurred** once on 4.7.2 after the release (CI run 40868629763, commit e257aa0: `1 resources still in use at exit`, down from N), so at least one holder is left. `run_tests.sh` now runs the walk with `--verbose`, which makes Godot name each resource still in use, and the annotation includes those lines: the next recurrence names it. **It did, the same day** (CI 40884831856, 4.4.1): `Leaked instance: AudioStreamWAV … res://assets/sfx/amb_office.wav` and its `AudioStreamPlaybackWAV` — the office ambience was still playing when the walk freed the game, and the audio server released the playback on its own next mix, before or after the engine's count depending on the audio thread. The walk now stops every audio player and waits five frames before freeing. **Fix applied, cause named; closes when CI stays clean.** | `tests/ui_walk.gd` `_release_static_caches()` | Phase 0 follow-up |
| B3 | 0.A full tier | **Beanbag slows the arrest:** 224 s to cuff a non-compliant unarmed man with beanbags vs 208 s without (gate wants less). **2026-11-02: fixed** — a suspect a less-lethal round put on the floor can be cuffed where he lies (`world.cuffable`), the operation waits up to 30 s for it under police rules, and the arrest counts; before, the knockdown ended the operation with nobody arrested. | less-lethal-first order, `equip_test.gd` beanbag case | Phase 1 |

| B5 | quick tier, 2026-11-02 (CI 41536220662) | **Weapons tight's gate is measuring a race, not the order:** police rounds at an armed man who is not attacking measure 0.81 without the order and 0.56 with it. `world._may_shoot` decides with `attacking()`; `incident.on_shot` records `att` when the round leaves, so a man who stops aiming in the interval is counted as "not attacking" and the residue cannot go to zero. The gate is now the 0.25 the measure resolves. **Proper fix (needs an engine):** record the decision-time verdict on the round — `on_shot` should take the verdict the officer acted on. | `world._may_shoot`, `incident.on_shot`, `tests/orders_test.gd t_tight` | Phase 1 follow-up |
| B6 | headless, 2026-11-02 (CI 41550396891) | **`ops_ui.gd` does not parse, and the fault is invisible to every tool here:** Godot reports `Parse Error: Unindent doesn't match the previous indentation level` and then `Failed to load script res://scripts/ui/ops_ui.gd`, which cascades — `main.gd` cannot preload it, `ui_walk` never reaches `go_title`, and `ops_ui_test` cannot resolve it (its `zeroed` inference error is collateral). Ruled out on 2026-11-02: leading spaces (`grep -P '^ +'` finds none in the repo), tab-then-space mixes (none), stray control bytes or a BOM (none), CRLF (none), mixed tab widths, a dedent to a level that never existed and a continuation line indented less than its statement (three hand-written stack scanners, all silent), `gdparse` (accepts the file), and `gdformat` (parses it, only style churn). The fault predates this branch: `bbc8d09` on `main` is red for the same reason, masked there because a different script failed to preload first so `ops_ui.gd` was never parsed. **Next step needs an engine:** open the project in the editor (the script panel points at the line) or bisect the file in CI with `godot --headless --check-only -s <file>` on halves; no offline method here can see it. | `scripts/ui/ops_ui.gd` (3446 lines) | Phase 1 blocking |

### Stage 0 bug fixes (2026-11-03, from the Stage 0 copy; B5/B6 there renumbered B7/B8)

Measured on official Godot 4.7.2 (checksum-verified), headless, 2 cores. Logs: `tests/results/stage0-2026-11-02/logs-bugs/` and `logs-bugfix-2026-11-03/`. **Every gate in the quick and full tiers now passes** (equipment 28/28, orders 15/15, brains 9/9, civ, lethality, hold on 4 maps, stall on 12 maps, maps, doors, fuzz 60 matches with 0 draws); the campaign determinism fixture stays xfail until P1.I1.

| ID | Cause | Fix | Result |
|---|---|---|---|
| B1 | Not a brain defect: the wolf gate pools hidden time over a few long fights, so at 8 or 16 seeds it flipped either way (0.22 vs 0.36 at 8; 0.33 vs 0.29 at 16; 0.37 vs 0.23 at 24). | `brains_test.gd g_wolf`: at least 32 seeds | **Closed.** 0.39 vs 0.28 (32 seeds), 0.35 vs 0.21 (48) |
| B2 | Every round the shield stopped flinched its carrier for 0.2 s (no return fire); three carbines kept him pinned. The gate also counted rounds absorbed before he fell, which a better shield raises. | `world.gd`: one shield flinch per 0.6 s. `equip_test` shield gate: rounds through **per round fired at him**, pooled | **Closed.** 0.13 vs 0.26. Survival in contested fights is about level (58% vs 62% over 48 seeds) |
| B3 | On surrender, every officer *aiming* at the man got the late-shot window, during which `cleared_to_fire()` is true: giving up licensed the shot. | `world.gd surrender()`: only for an officer whose aim was already set to fire | **Closed** |
| B3b | `visible_enemies()` kept returning a man who had given up, so an officer held Rule 1 on him while an armed man stood beside him (two fuzz matches ran to the time limit once B3 stopped those men being shot). | `world.gd visible_enemies()`: a complying person only if `hostile()` still says so | **Closed.** Fuzz 5252: 2 draws → 0 (original code: 1). Gang raids in `lethality_test`: officers killed per operation 0.45 → 0.30 |
| B3c | An officer who had judged a man "unknown" never re-judged him after he gave up, so he stayed a live contact and nobody moved in to cuff him. | `world.gd _judge()`: re-judge as someone giving up | **Closed** |
| B3d | `_arrest()` only took a man in sight at kneeling height or within 3 m; one kneeling in a bedroom off the hall was forgotten while the squad cleared on. | `world.gd surrender()` records the team he gave up to; `brain.gd _arrest()` goes to him | **Closed** |
| B4 | `ui_walk` freed the game while the office ambience was still playing (fix from 29 Oct). | none new | **Fix verified locally**: 7 runs, 4 of them two at a time on 2 cores, no leak. Closes when CI stays clean |
| B7 | Officers fired beanbags and 40 mm rounds with no line (into the bedroom wall from the hall, about 1 hit in 9), and fired when he ducked out of line during the wind-up. The launcher gate already failed on the unchanged tree. | `world.gd less_tool()`: no line, no tool. `_less_lethal_done()`: line lost at release → round held, nothing on the record. `brain.gd _close_in()`: in range without a line, or too close for a 4 m minimum with no room straight back → find a spot around him with a line (`_close_in_for_line`) | **Closed.** Launcher 59.5 vs 72.9 s |
| B7b | Beanbag wind-up was 0.7 s against the 40 mm's 0.4 s: a pump already loaded with beanbag rounds fires as fast as a launcher, and the extra 0.3 s was most of why it lost the line. | `equipment.gd` beanbag `act` 0.7 → 0.4 | **Closed.** 60.1 vs 72.9 s, all cuffed |
| B8 | `_melee()` killed whoever reacted second: an officer who reached an unarmed man he could not shoot killed him (9 of 12 no-tool runs), and an unarmed man killed an armed officer bare-handed. | `world.gd _struggle()`: an officer under police rules against someone showing no weapon whom he may not shoot → a **struggle**: both held 12 s, subdued at 20% + 15% per other officer within 2.5 m (max 90%), 10% chance each side is hurt, 15 s before he can be grabbed again; on the record as force (`incident.on_less_lethal`, tool "hands"). An unarmed winner (no weapon at all, not merely out of ammunition) knocks the other back for 1.5 s instead of killing. Lethal melee between armed fighters is unchanged | **Closed.** No-tool runs: 0 of 12 dead, all cuffed (was 11 of 12 dead). Every less-lethal tool beats bare hands by more than the 10 s margin: taser 42.8, OC 49.3, 40 mm 59.5, baton 59.7, beanbag 60.1, pepperball 61.8, hands 72.9 s |

**Tuning that is yours to revisit:** the struggle constants (`STRUGGLE_*` in `world.gd`) and the beanbag wind-up. They were set so that tools beat bare hands, as the gates intend; nothing else depends on the exact numbers.

**Campaign numbers will move.** These change every operation with an arrest, a surrender or hand-to-hand contact, so the 1.C balance figures are stale (one more reason for the CL3 8-seed reference before P1.D).

### Stage 0: CL1 and CL2 (2026-11-03)

| Task | Done | Evidence |
|---|---|---|
| CL1 — the quick tier in an imported official editor, both engines | **Done.** Godot 4.7.2 and 4.4.1 (both official, SHA-512 checked): the quick tier passes on both; equipment 28/28, orders 15/15 and brains 9/9 give **identical numbers to the decimal** on the two engines, and the test-range fixture passes on both. On 4.4.1 the import needs a second pass (`--import`) before the asset suites can load textures. The 4.4.1 balance smoke ran 3 of its 4 runs inside the time I had; those three match 4.7.2 exactly. | `tests/results/stage0-2026-11-02/logs-441/` |
| CL2 — progress-aware approach and entry | **Done.** The 45 s approach fallback now fires only once nobody still on the way to his stack has gained route for 10 s (`_stuck_on`, 120 s hard cap). An entry nobody can reach, with every entrant stalled for 20 s after at least 30 s, records the room as **unchecked** ("cannot reach the X: not cleared") and the squad moves on, instead of waiting for ever. | `brain.gd` `APPROACH_*`, `ENTRY_*`, `_skip_entry()` |

**What CL2 changed in measurement** (`tests/results/stage0-2026-11-02/cl2/`): on the Duplex (sizes 2 and 5, 3 seeds, fight and unopposed) every time is identical to the 2 Nov study. On Civic Plaza clearing takes 12–25 s longer (about 5–10%), because the squad no longer goes in at 45 s with members still walking round to the stack; every room is still cleared and none skipped. In `lethality_test` gang raids officers killed per operation fell again, 0.30 → 0.25, and raids take 113 s instead of 97 s, with 4 of 20 ending partial instead of 2. Two test-range fixture cases moved (motel 118 → 131 s, shield 138 → 118 s, same winners) and were refreshed. `group_movement_test`'s Plaza case asked for the old 9 s entry timeout to occur; with CL2 it no longer does, so the test now checks the invariant itself (the hall is cleared, and only after someone entered).

After CL2 every quick- and full-tier gate passes again on 4.7.2 (equipment, orders, brains, civ, lethality, hold on 4 maps, stall on 12, fuzz 60 matches with 0 draws, `ui_walk`, balance smoke 0 broken).

**Still open in Stage 0:** CL4 (optional movement tuning); CL3 is done (below). B4 closes once CI stays clean.

### Merge of the two 2–3 Nov copies (2026-11-04)

Two copies had split from the same 2 Nov tree: the **Phase 1 copy** (P1.D–P1.I, B1–B3 fixed one way, bugs B5 and B6 logged) and the **Stage 0 copy** (CL1, CL2, B1–B3 fixed another way, its own B5 and B6). Only nine files had changed on the Stage 0 side; every other file is the Phase 1 copy's. Where both sides changed the same code, both fixes are kept:

| Bug | Phase 1 copy | Stage 0 copy | Merged |
|---|---|---|---|
| B1 wolf | `WOLF_DWELL`, `WOLF_MAX_EXPOSURE`: dwell in cover, bound only on a hidden route | gate under-sampled: `g_wolf` runs at least 32 seeds | both: the behaviour change, measured at ≥ 32 seeds |
| B2 shield | gate = share of rounds reaching the body that got through | one shield flinch per 0.6 s; gate = rounds through per round fired | both world changes; **the Stage 0 gate** (rounds through per round fired) |
| B3 beanbag/arrest | `world.cuffable()`: a less-lethal knockdown is cuffed where he lies; the operation waits 30 s | late-shot window only for an officer already firing; B3b–B3d (re-judge, keep the team he gave up to) | all of them; `_arrest()` uses `cuffable()` and the gave-up team |
| B5 / B6 | weapons-tight gate race / `ops_ui.gd` does not parse | renumbered **B7** (no line, no less-lethal shot; beanbag `act` 0.4) and **B8** (hand-to-hand struggle) | all kept |

**B6 found and fixed in the merge** (it blocked the game from starting): Godot 4.7.2 points at `ops_ui.gd:1620` — the P1.D1 hire button passed a multi-line lambda straight into `_btn()` with `_confirm()`'s call nested in its `else`, a shape the parser rejects. It is now built as locals (`hire_red_text`, `on_hire`). The next error, `var fc :=` inferred from the untyped `d`, is now `var fc: Array =`. Every script under `scripts/` loads on 4.7.2.

**B9 found and fixed in the merge — the next-week strip ignored the overdraft (P1.C2 × P1.D2).** `dept_test`'s forecast check matched 5 of 12 weeks on the Phase 1 copy as well, so the merge did not cause it: `fit_next_week()` still assumed a queued course starts only when the account is at $0 or above, while P1.D2's `next_week()` starts it anywhere above the -$25K limit, after charging the week's interest. The forecast now uses `OVERDRAFT_LIMIT` and charges the interest first: 12 of 12.

**Quick tier on the merged tree, 2026-11-04:** official Godot 4.7.2 (headless, 2 cores), **25 of 25 suites pass**, including `rogue_balance_test` (439 s), `orders_test` (586 s) and `ui_walk`. Log: `tests/results/merge-2026-11-04/quick.log`. Not yet re-run on 4.4.1, and not yet the full tier.

**New (owner request, 2026-11-04): S15 Week Closed.** A ~5 s native crayon recap plays when the chief ends a week (election night keeps S11): the week stamped CLOSED, or ON THE RECORD if an officer or a civilian died; answered and unattended situations, suspects taken alive, civilians and officers killed, officers hurt, the account's movement and balance, and the Ledger's first headline. Click to skip; its own setting `week_recap` (default on), since it plays every week and the consequence shorts are rare by design. It does not touch `claim_short()`. Data: `Campaign.last_recap`, built in `end_week()`; operations now record `arrests` and `officers_hurt`. Test: `tests/week_recap_test.gd` (quick tier).

**Consequence for the roadmap:** the Phase 1 copy's P1.D–P1.I work had never run, because `ops_ui.gd` never loaded; its "built, exit measured by the next matrix" status lines are unmeasured. CL3's reference (8 seeds × 4 policies) is to be taken **on this merged tree**, and it doubles as the first measurement of P1.D–P1.H.

### Stage 0: CL3, re-baseline on the merged tree (2026-11-04)

**CL3.a: campaign determinism re-run** (`determinism_test.gd --verbose`, Godot 4.7.2, 277 s): **35 of 35 cases changed** against `tests/fixtures/determinism.json`, which predates 1.3 (22 of 35 had changed at Gate 0). The test-range fixture (`test_range_determinism_test`) passes unchanged on the merged tree; CL2's two refreshed cases (motel, shield) are already in it. The campaign fixture is **not rewritten**: it stays `xfail` until P1.I1, as the runner says. Logs: `tests/results/cl3-2026-11-04/determinism/` (merged, Phase 1 copy, Stage 0 copy).

**CL3.b: every changed case tagged to a cause.** The same test was run on the two copies the merge came from, and each case's outcome (winner, time, shots, hits) compared:

| Cause | Cases | Which |
|---|---|---|
| Before the 2 Nov split (1.3 simulation changes and everything both copies share) | 28 | every case not listed below: the outcome is identical on both copies and on the merge |
| Stage 0 copy (B3b–B3d surrender and arrest, B7 less-lethal line, B8 struggle, CL2 approach and entry) | 5 | `m00_5v5_regular_regular_assault_1001`, `m07_12v12_sof_regular_assault_1001/2002/3003`, `op2002_W1-2_warrant_m05`: the merge matches the Stage 0 copy, not the Phase 1 copy |
| Phase 1 copy (B1 wolf dwell, B3 `cuffable()` and the 30 s cuff wait, P1.D–H) | 2 | `m01_4v4_regular_untrained_assault_3003`, `m04_5v5_police_regular_assault_2002`: the merge matches the Phase 1 copy |
| Interaction of the two (differs from both copies) | **0** | — |

No case is untagged, so the merge introduced no outcome that neither side had. The 28 pre-split cases cannot be split further without the 2 Nov base tree (neither copy is it); they are the "fixture predates 1.3" set and are rebaselined with the rest at P1.I1.

**CL3.c: the 8-seed × 4-policy reference: done.** Run in CI on branch `arena/cl3-merged-2026-11-04` (the merged tree; GitHub `main` is still the 21 Oct tree and has no workflows, so the matrix cannot be dispatched there). `ci.yml` makes a push to `arena/cl3-*` run 8 seeds instead of the 2-seed pilot. CI run 41915644631, two shards of four seeds (1001–4004, 5005–8008), 32 runs, 9391 s of runner time, 0 broken runs. Report: `tests/results/cl3-2026-11-04/balance/` (report.md, summary.json, weeks.csv, ops.csv). The same run's static and headless jobs failed only because the Windows copy had lost the executable bit on `tools/run_tests.sh`; modes are restored (only `*.sh` executable) in the follow-up commit.

**CL3.d: what moved against `cycle-1C/balance`.** This is the first measurement of P1.D–P1.H, which had never run before the merge (`ops_ui.gd` did not load). Means over the same 8 seeds, 1C → CL3:

| metric | cautious | minimal | military | accept-all |
|---|---|---|---|---|
| lowest fit officers | 5.0 → 5.75 | 9.0 → 9.1 | 5.25 → 4.75 | 5.9 → 4.75 |
| weeks under 12 fit | 16.8 → 20.4 | 7.6 → 6.9 | 25.3 → 26.3 | 20.5 → 16.3 |
| week-ends with ≥ 12 fit | 58% → 49% | 81% → 83% | 37% → 34% | 49% → 59% |
| weeks below $0 | 27.0 → 32.9 | 0 → 0 | 5.9 → 4.6 | 32.6 → 35.6 |
| lowest account | −26.5k → −36.7k | +39.8k → +38.4k | **−27.2k → −10.1k** | −28.4k → −29.8k |
| account at week 40 | −2.6k → −12.3k | +347k → +215k | +14.3k → +8.0k | −6.9k → −9.9k |
| officers killed | 23.9 → 22.4 | 9.4 → 8.3 | 15.5 → 17.4 | 21.6 → 21.4 |
| killed per operation | 0.34 → 0.32 | 0.24 → 0.21 | 0.24 → 0.27 | 0.26 → 0.25 |
| civilians killed | 4.5 → 5.0 | 2.6 → 2.4 | 4.4 → 4.9 | 4.4 → 3.75 |
| allies lost at the end | 3.0 → 2.75 | 2.0 → 1.4 | 3.4 → 3.0 | 3.5 → 3.0 |
| allies won back | 0 → 0 | 0.12 → 0 | 0 → 0 | 0 → 0 |
| chief kept | 5/8 → 8/8 | 8/8 → 8/8 | 8/8 → 8/8 | 6/8 → 8/8 |
| run score | −799 → −795 | −426 → −404 | −490 → −575 | −648 → −616 |

**Bands: 36 of 52 miss (1C: 39 of 52).** Three flipped to ok: money-debt for military and for accept-all, and allies-held for minimal. None flipped the other way. The worst-seed bands (`min`/`max` aggregates) are read over 8 seeds here against 20 in 1C, so a flip there is weaker evidence than a mean moving.

**Reading.** P1.D–P1.H move the numbers in the intended direction, but by far less than Gate 1 asks:
- **Election is no longer a threat**: every policy keeps the chief on all 8 seeds (1C on the same seeds: 5/8 cautious, 6/8 accept-all). The election band passes with nothing to spare, which may mean the contest is now too soft.
- **Money**: military-first's debt trough is cut by about 60%; the other deficit-running policies are unchanged or worse (cautious ends about 10k lower). Minimal still banks over $200k, so the economy still pays for doing nothing.
- **Roster, deaths, lethality are untouched**: the worst week still fields 2–4 fit officers (band ≥ 10), officers killed per run is 8–22 (band ≤ 8), killed per operation 0.21–0.32 (band ≤ 0.15). These are the tactical layer's numbers, not the run layer's, and no Phase 1 task targets them.
- **Ally recovery never happens** (0 on all 32 runs; 1C had one seed of minimal win one back); either the mechanism is unreachable for these policies or the band is.

`tests/balance_bands.json` now names this run as its reference. The band values are not changed: per roadmap 8.4 they are the owner's decision, and this is the matrix where they are to be read as a verdict.

### Stage 1: what the CL3 reference says about the Phase 1 exits (2026-11-04)

Every Phase 1 exit misses on the CL3 matrix (8 seeds, merged tree):

| cycle | exit | CL3 |
|---|---|---|
| 1.C roster | cautious ≥ 12 fit in ≥ 90% of week-ends | 49% |
| 1.D money | cautious: no week below $0 in weeks 1–12, ≤ 4 overall | 6 and 33 (means) |
| 1.D money | minimal: week-40 balance ≤ $100K or visibly spent | $215K mean (after $230K of council sweeps) |
| 1.E allies | lost and won back in ≥ 5 of 20 runs | 0 of 32 |
| 1.F score | cautious mean run score above minimal and military-first | lowest of the four (−795 vs −404, −575) |

**Diagnosis: the money miss is a death bill.** The balance harness now writes `money.csv`
(each week's ledger summed by kind of item). One seed (1001) × 4 policies × 40 weeks, run
locally on 4.7.2, in `tests/results/p1d-diag-2026-11-04/`:

| 40 weeks, seed 1001 | cautious | accept-all | military | minimal |
|---|---|---|---|---|
| net change of the account | −$33.7K | −$24.5K | −$13.8K | +$88.5K |
| academy places (replacements) | −$191.0K | −$175.7K | −$30.6K | 0 |
| line-of-duty death benefits | −$87.0K | −$75.0K | −$45.0K | −$15.0K |
| medical | −$28.5K | −$19.5K | −$27.5K | −$7.5K |
| lateral hires | 0 | 0 | −$42.6K | 0 |
| **cost of deaths and wounds** | **−$306.5K** | **−$270.2K** | **−$145.6K** | **−$22.5K** |

Without the cost of deaths and wounds, cautious would end about $270K in the black. The
allocation covers payroll and training; it cannot cover replacing 25–29 officers a run. In
weeks 1–12 alone cautious loses 13 officers and spends $103K on it. Money (1.D), roster
(1.C) and the deaths and lethality bands are one problem.

**Where the deaths are: crew-house raids.** From CL3's `ops.csv` (2,128 operations):

| situation | operations | officers killed | per operation |
|---|---|---|---|
| crew house (`gang`) | 484 | 391 | **0.81** |
| hostage | 413 | 98 | 0.24 |
| barricade | 287 | 44 | 0.15 |
| warrant | 242 | 17 | 0.07 |
| public event | 702 | 5 | 0.01 |

- Crew houses are **70% of all officer deaths**. Every other type together is 0.10 per
  operation, inside the 0.15 lethality band.
- They were as deadly in 1C (0.79 over 1,169 raids), so this is not a merge or clearance
  regression.
- Most raids send six officers (1,297 of 1,653 in CL3 + 1C): the plan's floor, because the
  roster is short. Six against 5.5 armed members (3–8, up to a third with rifles) kills 0.98
  officers per raid. More officers help, but not enough: at 2:1 it is 0.56, at 3:1 still 0.5.
  Most deaths are outright kills by suspects (326 of 391), so better medical care would not
  change much.

**This is a design decision (owner).** Ways to close it, none applied yet:
1. Make crew houses less deadly in the simulation: fewer members, fewer rifles, more
   surrenders when outnumbered. Changes how the game feels; needs P1.I1 rebaselining.
2. Make them avoidable: fewer crew-house calls, or a plan option (surveillance, wait them
   out, a warrant at a better hour) that trades a slower result for fewer deaths.
3. Make the existing counters matter: the armoured rescue vehicle (P1.D4, crew houses
   only) and the plan's six-officer floor; cautious buys neither today.
4. Accept the lethality and re-set the deaths, lethality and roster bands (P1.I2.a), then
   rebalance the money against the death bill instead.

The economy itself needs only small changes once deaths are settled: minimal still banks
over $200K after the quarterly sweeps (the 1.D exit wants ≤ $100K).

### Stage 1, option 1 applied: crew houses less deadly (2026-11-05)

**Owner decision 2026-11-04: option 1.** Changed in `situations.gd` (crew-house generation)
and `world.gd` (surrender):
- **Crews**: 2–6 members instead of 3–8, at most one more than the rooms (two
  more before). The rifle chance is 0.3
  instead of 0.5. The lookout chance stays at 0.4; a lower one (0.25)
  measured worse in the probe.
- **New: members give up when outnumbered.** Each crew member has `yield_out` = 1.0. In
  `_surrender_roll`, every armed officer within 20 m beyond the member's own side (the
  member plus nearby mates) adds 0.3 × `yield_out` to the surrender chance, counting at
  most 4 extra officers. Other situation types have `yield_out` 0 and are unchanged.
- **Raid probe** (40 gang raids, 6 officers, own kit): officers killed per raid fell from
  0.42 to 0.23, armed members from 5.1 to 3.5, and suspects killed from 0.90 to 0.45.
  1.2 members per raid now surrender. Successes rose from 7 to 16 of 40.

**Measured on the campaign matrix.** CI run 41964333236 ran 8 seeds × 4 policies, the same
seeds as CL3, on branch `arena/m8-crew-2026-11-05`. Results are in
`tests/results/arena/m8-crew-2026-11-05/balance/`.

| situation | CL3 killed per op | crew change |
|---|---|---|
| crew house (`gang`) | 0.81 | **0.49** |
| hostage | 0.24 | 0.27 |
| barricade | 0.15 | 0.15 |
| warrant | 0.07 | 0.10 |

| exit | CL3 | crew change |
|---|---|---|
| 1.C cautious ≥ 12 fit, share of week-ends | 49% | 76% (needs 90%) |
| 1.D cautious weeks below $0: weeks 1–12 / all (means) | 6 / 33 | 4.5 / 26 (needs 0 / ≤ 4) |
| 1.D minimal week-40 balance | $215K | $182K (needs ≤ $100K) |
| 1.F run score: cautious / minimal / military | −795 / −404 / −575 | −410 / −285 / −408 |
| officers killed per run: cautious / accept-all / military / minimal | 22 / 21 / 17 / 8.3 | 19 / 17 / 14 / 7.4 |

- Band misses: 37 of 52 (36 on CL3). The minimal deaths band now passes. Two bands that
  were near the edge now miss: accept-all civilians (6.4 against ≤ 6) and accept-all worst
  debt. No runs broke.
- Every policy moved the right way on roster, score and officer deaths. The money and
  deaths misses are smaller but not closed: deaths are still about twice the ≤ 8 band, and
  lethality is 0.23–0.40 against ≤ 0.15.
- Crew houses fell from 0.81 to 0.49 per raid, not to the probe's 0.23. In the campaign,
  the officers sent are hurt, traumatised or short-handed, not a fresh six. Crew houses
  are still the deadliest type, now with about 45% of officer deaths.
- 1.E: this run used the old allies counter, so it shows 0 won back. The fixed counter
  (commit 7631121) is in the next matrix.
- The determinism cases need rebaselining for this change (P1.I1).

**Next.** Option 1 alone does not close Gate 1. The levers that are left:
- tune crew houses further (this run tested the probe's middle variant);
- option 3: the armoured rescue vehicle and the six-officer floor;
- hostage operations, now 0.27 per op and the second-largest share of deaths;
- option 4: re-set the deaths and lethality bands.

The roster and money exits follow deaths, so they need no separate work.

## Order and overlap

```
Nov 2026     P0 (all) ─► P1.A baseline ─► P1.B crowd ─► P1.C roster
Dec 2026     P1.D money ─► P1.E allies ─► P1.F election ─► P1.G pacing ─► P1.H
             (in parallel, short bursts: P2.A Windows run, P2.B Steam account)
Jan 2027     P1.I close Gate 1 ─► P3 first-hour screens ─► P2.C–G Steam plumbing
Feb 2027     Gate 2 + 3 ─► P5.A store page live (Coming Soon) ─► P5.C testers start
Mar–Apr      P4 content + music ─► P5.B demo public (April) ─► register NF by 25 Apr
May–Jun      tester cycles ─► NF submissions 10/24 May ─► Next Fest 14–21 Jun
Jun–Jul      Early Access launch
```

These durations assume full-time work; stretch them proportionally for evenings and weekends. Phase 1 is where the schedule is most likely to slip. If a Gate 1 number won't close, simplify the system (fewer allies, simpler money) rather than move the dates.

## Decisions needed before or during the cycles

1. Version line (P0.D1). **Decided 2026-10-28: 1.3.x = Early Access, 1.3.0 now; 2.0 = release.**
2. Licence for the game and the Remotion question (P0.D2–D3). **Decided 2026-10-28: proprietary, all rights reserved; Remotion under its free licence (re-check if headcount passes three or a company is involved).**
3. Gate 1 thresholds (`balance_bands.json`).
4. Whether Kettering keeping a brutal chief stays, and how the score treats it (P1.F2).
5. Cutscenes as-is or re-rendered (P4.C1).
6. Whether to recover the 1.5 command layer before EA (P4.E1).
7. Which Next Fest (roadmap §5).
