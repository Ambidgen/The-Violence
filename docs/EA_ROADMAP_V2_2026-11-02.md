# The Violence — Early Access roadmap v2

Written 2026-11-02 from a scan of `The-Violence-01-Nov-26-main` (the newest tree) and the project docs. It replaces the **schedule and task list** of the 28 Oct roadmap and keeps that roadmap's bar, gates and risks. Every outstanding item is split into four or more smaller tasks: **93 outstanding items → 376 tasks** (88 items → 356 tasks for Early Access itself, plus a 5-item story track you have to approve).

---

## 1. Where the game is on 2 November

**Phase 0 is finished, Phase 1 is a third finished, and the thing blocking everything else moved.** The 28 Oct roadmap said the money, roster, ally and crowd curves all collapse over a forty-week run. The crowd curve is fixed. The roster levers now exist and work. The money cannot carry them, so money is the new critical path.

| Phase | State | Evidence in the tree |
|---|---|---|
| 0 — trustworthy build | **Done** (Gate 0 met 28 Oct) | Honest exit codes, CI on 4.7.2 and 4.4.1, duplicate-charge fix, version 1.3.0 "Early Access", `LICENSE`, `THIRD_PARTY_NOTICES`, fixed user dir |
| 1.A — balance harness | **Done** | `tests/policies.gd`, `rogue_balance_test.gd`, 20 seeds × 4 policies baseline, 0 broken runs |
| 1.B — crowd cliff | **Done, one decision open** | Quiet-event civilians struck at trauma 14: 413 → 1. Attackers now stopped 3–5 s later (P1.B6, your call) |
| 1.C — roster bleed | **Built, exit missed** | Cautious holds ≥ 12 fit in 53% of week-ends (target 90%); weeks in the red 5.1 → 29.5; chief kept 16 → 12 of 20 |
| 1.D–1.I — money, allies, election, pacing, planning, close | **Not started** | No task in these cycles has a status line |
| 2 — Steam | **Not started** | No `addons/`, no Steam code, no `[input]` actions, no `tr()` calls, settings have no resolution / UI scale / rebinding |
| 3 — first-hour screens | **Not started** | — |
| 4 — content and music | **Not started** | No `assets/music/`; the ten unplayed shorts are still open |
| 5 — store, demo, testers | **Not started** | — |

What I measured in the tree: about 34,700 lines of GDScript under `scripts/`, 57 test scripts in `tests/`, 12 maps (test range plus 11), `scripts/version.gd` = 1.3.0 / "Early Access", `.github/` present, `adaptive_speed` still defaults to `false`. The folder is a snapshot without `.git`, so I could not see branches, PR #8, or CI state; the status lines in `docs/EA_TASKS.md` are my source for those.

## 2. What changed since the 28 Oct roadmap

- **Money is now the critical path.** The 1.C matrix (CI 41409260807, 20 seeds × 4 policies) shows the roster levers working and the account unable to pay for them. EA_TASKS says the 1.C exit "depends on 1.D", so P1.D moves to the front and 1.C's exit is reopened as P1.CX.
- **The 2 Nov clearance investigation changed the simulation.** Three fixes to squad movement (check-room timeout, doorway oscillation, entry completion) landed after the 1.C matrix. The test-range fixture was refreshed on purpose. The campaign balance has not been re-run since, and the full quick tier ran 17/22 on an export-only engine with three UI suites unvalidated. Stage 0 exists for this.
- **A story and tutorial plan exists.** `Story Opening & Tutorial Plan` (30 Oct, updated 1 Nov) adds a tutorial mission, squad-selection changes and a training-program rework. It is explicitly "a plan, not code". It adds a 13th map, which the old roadmap told you not to do before the run is balanced. It is a separate track (S) so you can say yes or no.
- **Unchanged and still true:** Valve's Early Access rules, the review lead times, the June 2027 Next Fest dates, the list of things not to do before EA.

## 3. How the 4× split was done

| Source of outstanding items | Items |
|---|---|
| Task IDs in cycles of `EA_TASKS.md` that have no "done" status (1.D–1.I, Phases 2–5) | 78 |
| Reopened: P1.B6 (posture decision) and the 1.C exit (new ID P1.CX) | 2 |
| Open bugs B1–B4 | 4 |
| Follow-ups from the 2 Nov clearance diagnosis (CL1–CL4) | 4 |
| **Early Access items** | **88** |
| Story and tutorial track (S1–S5) | 5 |
| **All items** | **93** |

Each item became four tasks, or more where it was big (P1.D4 has six, P4.D1 has six). Result: **356 tasks for Early Access (4.05× the item count) and 376 with the story track (4.04×).** CL1–CL4, P1.CX, and the item IDs for bugs are mine; the others carry the IDs already in EA_TASKS so commits and the changelog can still cite them. Task IDs add a letter: `P1.D1.a`.

Sizes: **XS** ≤ 2 h · **S** ≤ half a day · **M** ≤ 1 day. **Who: you** means only you can do it (accounts, decisions, hands-on play, art and music); everything else I or the code pipeline can do. `+CPU` is machine time that is not counted as effort.

## 4. Calendar

Effort below is my sizing of each small task as hand-work, summed in the order shown, at five working days a week from 2 Nov. It is not measured velocity. Cycles 0.A–1.C were built in two days (28–29 Oct, status lines in EA_TASKS), with CI running their matrices over the following days, so code-heavy stages may go faster than this; the floor is the **84 owner-only tasks (about 33 days)**, the overnight balance runs, and Valve's review and waiting periods.

| Order | Stage | Tasks | Effort (days) | Starts | Ends |
|---|---|---|---|---|---|
| 1 | Stage 0 - trust the tree | 28 | 13.1 | 02 Nov 2026 | 20 Nov 2026 |
| 2 | Stage 1 - the forty-week run (Phase 1 remainder, incl. reopened 1.B/1.C) | 82 | 36.2 | 20 Nov 2026 | 10 Jan 2027 |
| 3 | Stage 3 - first-hour screens | 44 | 19.5 | 10 Jan 2027 | 06 Feb 2027 |
| 4 | Stage 2 - Windows and Steam plumbing | 76 | 33.6 | 06 Feb 2027 | 25 Mar 2027 |
| 5 | Stage 5a - store page, art, trailer | 20 | 9.2 | 25 Mar 2027 | 07 Apr 2027 |
| 6 | Stage 5b - demo | 12 | 6.7 | 07 Apr 2027 | 17 Apr 2027 |
| 7 | Stage 4 - content, music, finish | 38 | 23.1 | 17 Apr 2027 | 19 May 2027 |
| 8 | Stage 5c - testers, Next Fest, launch | 40 | 14.8 | 19 May 2027 | 08 Jun 2027 |
| ∥ | Steam account (P2.B), owner-only, start 2 Nov because of Valve's waiting period | 12 | 2.8 | 2 Nov 2026 | spread out |
| ∥ | Optional squad-movement work (CL4) | 4 | 2.8 | when Stage 1 waits on CPU | — |

Total 162 days for Early Access, 12 more for the story track.

**Fixed external dates** (Steamworks, from the 28 Oct roadmap): register for the June Next Fest by **25 Apr 2027**; demo and page for press preview by **10 May**; everything by **24 May**; festival **14–21 Jun**; submit the launch build at least 7 business days before launch. The demo must be public in April, so the demo is sequenced **before** the content stage.

What the table says:

- **Gate 1 lands in early-to-mid January at full time** (Stage 0 + 1 ends 10 Jan). At half time it moves to mid-March, which breaks the June plan.
- **At full time with no slack, the demo is ready around 17 Apr and Next Fest registration (25 Apr) is met.** Content and music finish after that (19 May), and the last stage's effort adds up to 08 Jun, about a week before the festival. That sum contains none of the waiting on Valve's page and build reviews, so there is no real slack.
- **If you are working evenings and weekends, treat June 2027 as unlikely** and use Option C from the old roadmap (public demo plus Steam Playtest, launch when Gate 3 passes). I did not check the dates of the festival after June.

**Cut list if Gate 1 slips past 31 Jan.** Defer, in this order: P4.D1–D2 (more events/offers/doctrines), P4.E1 (1.5 command layer), P2.G1 (localization scaffold), CL4 (movement tuning), and P2.E (pad/Deck; ship keyboard and mouse, say "controller support planned"). That is 38 tasks and about 24 days. Do not cut the money, ally or election cycles; they are Gate 1 itself.

---

## 5. Task lists

Cycles inside a stage are in the order to do them. Each stage ends in a gate you can check with a command or a number.

## Stage 0 - Trust the tree again

7 items → 28 tasks · about 13 days · owner-only tasks: 1

**Gate R0: the full quick tier is green on 4.7.2 and 4.4.1 from an imported official editor; every changed determinism case is tagged to a cause; a fresh 8-seed balance reference exists for the current tree.**

### 0.A — Verify the 2 Nov clearance work

*Quick tier ran 17/22 on an export-only engine; three suites could not validate UI/assets.*

| ID | Task | Size | Who |
|---|---|---|---|
| **CL1** | **Run the whole quick tier in an imported official editor** | | |
| CL1.a | Install/import the project in the official 4.7.2 editor (`godot --headless --editor --path . --quit`) and run `tools/run_tests.sh --quick` | S | you |
| CL1.b | Read the failures of `character_assets_test`, `ops_ui_test` and `ui_walk` that the export-only engine could not validate; classify each as real or environmental | S |  |
| CL1.c | Fix every real failure found, one commit per fix, task ID in the message | M |  |
| CL1.d | Repeat on 4.4.1 and commit both logs to `tests/results/clearance-2026-11-02/` | XS |  |
| **CL2** | **Progress-aware approach and entry timeouts** | | |
| CL2.a | Replace the fixed 45 s approach fallback with a timer that resets on route progress (remaining path length) | M |  |
| CL2.b | Replace the 9 s entry timeout the same way, still requiring an entrant inside the room | M |  |
| CL2.c | Add an explicit 'unchecked / unreachable' room outcome and word it in the debrief | S |  |
| CL2.d | Extend `group_movement_test` (long detour, real stall, closed door, casualty reassignment) and re-run `clearance_study` on three maps | S |  |
| **B4** | **Close the intermittent `ui_walk` exit error** | | |
| B4.a | Watch the next ten CI quick-tier runs for `resources still in use at exit`; log run IDs | XS |  |
| B4.b | If it recurs, read the resource the `--verbose` annotation names and release it in `_release_static_caches()` | S |  |
| B4.c | Give `ops_ui_test` and `character_assets_test` the same stop-audio + five-frame wait before freeing the game | S |  |
| B4.d | Mark B4 closed in EA_TASKS with the run IDs that stayed clean | XS |  |

### 0.B — Know what the movement fixes did to the campaign

*The 1.C matrix (ff89f12) predates the Duplex jam, check-room and entry fixes.*

| ID | Task | Size | Who |
|---|---|---|---|
| **CL3** | **Re-baseline after the clearance fixes** | | |
| CL3.a | Re-run determinism and the test-range fixtures; list every changed case | S |  |
| CL3.b | Tag each changed case to a cause (CL fix, B1-B3, other); an untagged case is a bug | S |  |
| CL3.c | Run the 8-seed x 4-policy balance on the current tree as the new reference (+CPU, ~4 h) | XS |  |
| CL3.d | Diff it against `cycle-1C/balance`; write the moved metrics into EA_TASKS and point `balance_bands.json` at the new reference | S |  |

### 0.C — Three simulation bugs from the first full tier

*B1-B3 have been open since 28 Oct; every sim change waits for P1.I1.*

| ID | Task | Size | Who |
|---|---|---|---|
| **B1** | **Wolf brain hides less when on** | | |
| B1.a | Reproduce with `brains_test --only=wolf --n=24 --v` and log hidden-time per state | S |  |
| B1.b | Trace the wolf branch in `brain.gd` to find why on < off (0.19 vs 0.28) | M |  |
| B1.c | Fix it so the gate passes without loosening the gate | S |  |
| B1.d | Re-run the brains suite; list any determinism cases it moves for P1.I1 | XS |  |
| **B2** | **Shield lets more rounds through** | | |
| B2.a | Reproduce the `equip_test` shield case; log rounds reaching the officer by angle and range | S |  |
| B2.b | Audit the shield block and `_notice_shield_stop` in `world.gd` for arc and facing errors | M |  |
| B2.c | Fix the cause (not the test threshold) | S |  |
| B2.d | Re-run `equip_test` and `raid_probe`; list moved determinism cases | XS |  |
| **B3** | **Beanbag slows the arrest** | | |
| B3.a | Reproduce 224 s vs 208 s and split the time into draw, fire, reassess and cuff | S |  |
| B3.b | Inspect the less-lethal-first order and beanbag switch/draw time | M |  |
| B3.c | Fix the cause | S |  |
| B3.d | Re-run `equip_test` and the order tests; list moved determinism cases | XS |  |

## Stage 1 - Make a forty-week run hold together (Phase 1 remainder)

21 items → 86 tasks · about 39 days · owner-only tasks: 6

**Gate 1 (unchanged in substance): cautious holds >= 12 fit in >= 90% of week-ends with no week below $0 in weeks 1-12 and <= 4 overall; >= 1 ally lost and won back in >= 5 of 20 runs; cautious beats minimal and military-first on score; determinism rebaselined; bands asserting.**

### 1.D — Money curve - now the critical path

*1.C proved the roster levers work and the money cannot carry them: weeks in the red 5.1 -> 29.5.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.D1** | **Hire, course and kit buttons show the forecast** | | |
| P1.D1.a | `forecast_after(action)` in `department.gd`: the four-week balance with one hire, course or kit added | S |  |
| P1.D1.b | Print 'week N goes to -$X' on every hire, course and kit button from it | S |  |
| P1.D1.c | Confirm dialog before any action that takes a forecast week below $0 | S |  |
| P1.D1.d | Test: `forecast_after` equals a real `next_week()` run over 12 weeks; `ops_ui_test` sees the line | S |  |
| **P1.D2** | **Council overdraft instead of a hard freeze** | | |
| P1.D2.a | Put the overdraft limit (-$25K), weekly interest and Duff standing cost in one tuning table | XS |  |
| P1.D2.b | Rework `frozen()` so the freeze applies only below the limit; hiring, training and kit stay open above it | M |  |
| P1.D2.c | Board and Ledger show overdraft state, interest accrued and the political cost | S |  |
| P1.D2.d | Test across four policies: no run sits in a permanent freeze; interest and standing cost accrue exactly | S |  |
| **P1.D3** | **Lawsuits settle in four instalments** | | |
| P1.D3.a | Give the lawsuit record a four-week instalment schedule | S |  |
| P1.D3.b | `politics._land()` posts a quarter per week-end; forecast and payroll include the tail | S |  |
| P1.D3.c | Save/load of in-flight instalments plus `from_data` migration for older saves | S |  |
| P1.D3.d | Test: instalments sum to the old single hit; forecast shows the tail | XS |  |
| **P1.D4** | **Late-game money sinks with real effects** | | |
| P1.D4.a | Armoured rescue vehicle: capital item, military tag; measure its effect on raid deaths with `raid_probe` | M |  |
| P1.D4.b | Training range: courses cheaper and faster; build cost and upkeep | M |  |
| P1.D4.c | Union contract: pay up, morale floor up; draft card and Ledger line | M |  |
| P1.D4.d | Tier-3 programs repriced and 'return surplus to council' for Duff standing | S |  |
| P1.D4.e | `rogue_test`: reproducibility and an effect assertion for each new item | S |  |
| P1.D4.f | 3-seed balance smoke; confirm `minimal` no longer ends with an unspent six-figure account | S |  |
| **P1.D5** | **Starting reserve** | | |
| P1.D5.a | Make the starting reserve a tuning constant in `department.found()` | XS |  |
| P1.D5.b | Run $25K vs $35K, 3 seeds x 4 policies (+CPU) | S |  |
| P1.D5.c | Run 20 seeds on the better candidate (+CPU overnight) | XS |  |
| P1.D5.d | Pick one, record the reason in EA_TASKS, update tests pinned to the old figure | XS |  |

### 1.C* — Reopen the 1.C exit

*Measured 2 Nov: cautious >= 12 fit in 53% of week-ends (target 90%).*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.CX** | **Make the roster exit pass** | | |
| P1.CX.a | Add emergency laterals and kit purchases to the standing order's forecast | S |  |
| P1.CX.b | Let the Entry-kit purchase run on overdraft once P1.D2 lands, not only when the account is in the black | S |  |
| P1.CX.c | Probe why the full Entry kit cuts deaths 41% when no part of it does (door-taking by ram?) with `raid_probe` variants | M |  |
| P1.CX.d | Re-run the 20-seed matrix after P1.D; check >= 12 fit in >= 90% of week-ends and <= 25 unattended (+CPU) | S |  |

### 1.B* — Reopen the 1.B posture decision

*Attackers are stopped a median 3-5 s later since relaxed posture; owner's call.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.B6** | **Posture at public events** | | |
| P1.B6.a | Probe the three candidates on the same attack seeds with `event_probe --attack` (60 seeds) | S |  |
| P1.B6.b | Prototype a low-ready alert state (weapon out, not aimed) in `brain.gd` / `civ_brain._unaware` | M |  |
| P1.B6.c | Prototype a per-event plan option 'visible presence / low profile' in `op.gd` and the plan UI | M |  |
| P1.B6.d | Run the crowd tier on each; you pick one; record the table and the choice in EA_TASKS and the changelog | S | you |

### 1.E — Allies that can come back

*Zero allies won back in every run measured so far.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.E1** | **Find out where the coalition goes** | | |
| P1.E1.a | Log every ally standing change with cause, week and delta into `weeks.csv` | S |  |
| P1.E1.b | Chart drift per policy (new `ally_report.py` or extend `roster_report.py`) | S |  |
| P1.E1.c | Identify what takes the coalition from 45 to under 25 by week 3-4 | S |  |
| P1.E1.d | Write the finding and numbers into EA_TASKS | XS |  |
| **P1.E2** | **Reconciliation offers** | | |
| P1.E2.a | Define the offer in `OFFERS`: big cost, standing +20, once per ally per run, at most one per four weeks | S |  |
| P1.E2.b | `_deal_offer()` deals it only from a lost ally, from its own RNG sub-stream | M |  |
| P1.E2.c | Desk card, Ledger line and a line of text per ally | S |  |
| P1.E2.d | `rogue_test`: reproducibility, cooldown, once-per-ally; smoke counts allies regained | S |  |
| **P1.E3** | **Tune ally drift** | | |
| P1.E3.a | Remove any drift caused only by being out of sight in `politics.week_end()` | S |  |
| P1.E3.b | Tune per-cause drift constants to the target (careful 0-1 lost, reckless 2-3) | M |  |
| P1.E3.c | 3-seed smoke after each tuning step | S |  |
| P1.E3.d | 20-seed run against the exit (>= 1 lost and won back in >= 5 of 20; cautious median lost <= 1) (+CPU) | S |  |

### 1.F — The election and the score

*Two wrecked departments kept their chief in the 28 Oct runs.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.F1** | **Polls respond to the record** | | |
| P1.F1.a | Document current harm, neglect and restraint weights as a table in code and test | S |  |
| P1.F1.b | Strengthen the weights in `on_operation()` and `week_end()` | M |  |
| P1.F1.c | Each Ledger week names its dominant cause | S |  |
| P1.F1.d | Test: restraint seeds and neglect seeds move the poll in opposite directions by a stated margin | S |  |
| **P1.F2** | **Kettering keeping a brutal chief** | | |
| P1.F2.a | Decide whether the outcome stays; write the decision down | XS | you |
| P1.F2.b | If it stays: make the +60 for keeping office conditional on the record in `run_score()` | S |  |
| P1.F2.c | If it goes: rebalance the weights instead | S |  |
| P1.F2.d | Assert in the balance report that cautious mean score beats minimal and military-first | XS |  |
| **P1.F3** | **Election night explains the score** | | |
| P1.F3.a | Return the score breakdown as data from `run_score()` | S |  |
| P1.F3.b | Render it beside the ending in `_election_night()` | S |  |
| P1.F3.c | Check it in `ui_walk` at 1280x720 and 1600x900 | XS |  |
| P1.F3.d | `ops_ui_test` asserts the breakdown sums to the score | XS |  |

### 1.G — Rally pacing

*Quiet rallies cost minutes of wall time at default speed.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.G1** | **Adaptive speed on by default** | | |
| P1.G1.a | Flip the `adaptive_speed` default to true | XS |  |
| P1.G1.b | Migrate existing `settings.cfg` only where the key was never set | S |  |
| P1.G1.c | Document what adaptive speed does for each situation type | S |  |
| P1.G1.d | Pin default and migration in `improvements_test` | XS |  |
| **P1.G2** | **Skip to the report** | | |
| P1.G2.a | Headless fast-forward stepping API in `world`/`main.gd` | M |  |
| P1.G2.b | 'Skip to the report' button after 60 s of quiet | S |  |
| P1.G2.c | Determinism check: skipped result equals watched result on 10 seeds | S |  |
| P1.G2.d | Debrief opens identically; replay slider covers the skipped span | S |  |
| **P1.G3** | **Measure wall time** | | |
| P1.G3.a | Add a timed full-run option to `tools/playtest.sh` | S |  |
| P1.G3.b | Run it on the slowest machine you own | S | you |
| P1.G3.c | Record wall time and CPU per quiet rally in the results folder | XS |  |
| P1.G3.d | If a quiet rally exceeds 60 s, file follow-up tasks | XS |  |

### 1.H — Planning has to matter

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.H1** | **Manual chief beats the one-click suggestion** | | |
| P1.H1.a | Run `op_test --chief=manual` vs `--chief=sensible` over 20 seeds (+CPU) | S |  |
| P1.H1.b | Compute the share of seeds where manual wins on run score (target >= 70%) | XS |  |
| P1.H1.c | If it misses, tune order costs and benefits in `orders.gd`, not the suggestion's knowledge | M |  |
| P1.H1.d | Re-run and record | S |  |

### 1.X — Squad movement quality (optional, parallel)

*Apartment Block: independent model 93 s, measured 848 s unopposed; 54% of ticks under 1 mm.*

| ID | Task | Size | Who |
|---|---|---|---|
| **CL4** | **Reduce idle time in large interiors** | | |
| CL4.a | Add per-phase time and person-metre columns to the clearance report for Apartment Block and Walled Compound | S |  |
| CL4.b | Test pair-split thresholds (members needed, no-recent-contact rule) | M |  |
| CL4.c | Test stack spacing and waiting policies against both serial and independent references | M |  |
| CL4.d | Keep a change only if both references improve and the collision and casualty regressions pass | S |  |

### 1.I — Close the phase

| ID | Task | Size | Who |
|---|---|---|---|
| **P1.I1** | **Rebaseline determinism** | | |
| P1.I1.a | Re-run determinism; list the changed cases | S |  |
| P1.I1.b | Map each changed case to a task ID; an unexplained case is a bug until proven otherwise | M |  |
| P1.I1.c | `--write` and say why in the changelog | XS |  |
| P1.I1.d | Move determinism back into the quick tier in `run_tests.sh` and the README | XS |  |
| **P1.I2** | **Bands start asserting** | | |
| P1.I2.a | Choose the final band thresholds | S | you |
| P1.I2.b | Flip `enforce` to true in `balance_bands.json` | XS |  |
| P1.I2.c | Weekly CI runs the balance and fails on a miss | S |  |
| P1.I2.d | Dry run: plant a deliberate miss and confirm CI goes red | XS |  |
| **P1.I3** | **A full human playtest** | | |
| P1.I3.a | Play all 40 weeks, screen-recorded | M | you |
| P1.I3.b | Write notes against the gate numbers (fit, red weeks, allies, civilians) | S | you |
| P1.I3.c | Triage the notes into tasks | S |  |
| P1.I3.d | Sign Gate 1 in EA_TASKS | XS |  |

## Stage 2 - Windows and Steam plumbing

22 items → 88 tasks · about 36 days · owner-only tasks: 23

**Gate 2: a build installed through Steam on a clean Windows machine completes a week; the save survives quit and reload; achievements fire; the cloud save round-trips; a pad completes week 1.**

### 2.B — The Steam app (your account - the waiting period runs on its own clock)

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.B1** | **Partner account** | | |
| P2.B1.a | Create the Steamworks partner account | XS | you |
| P2.B1.b | Pay the app fee | XS | you |
| P2.B1.c | Submit tax and bank details | S | you |
| P2.B1.d | Note the date Valve's waiting period ends in EA_TASKS | XS | you |
| **P2.B2** | **App, depot, branches** | | |
| P2.B2.a | Create the app ID and Windows depot | XS | you |
| P2.B2.b | Create `default` and `beta` branches | XS | you |
| P2.B2.c | Write `tools/steam/app_build.vdf` and the depot vdf | S |  |
| P2.B2.d | Write the steamcmd upload script, credentials from the environment | S |  |
| **P2.B3** | **First Steam install** | | |
| P2.B3.a | Upload a build to `beta` | XS | you |
| P2.B3.b | Install it through the Steam client on a clean machine | S | you |
| P2.B3.c | Launch from Steam and confirm it starts | XS | you |
| P2.B3.d | Record the result | XS |  |

### 2.A — First real Windows run

*The exe has never run on Windows.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.A1** | **Export and play on Windows** | | |
| P2.A1.a | Install official Godot 4.7.2 and export templates on your PC | XS | you |
| P2.A1.b | Export with the existing preset; walk the checklist (boot, run, week, save, quit, reload, alt-tab, resize, fullscreen, audio, opening, quit) | S | you |
| P2.A1.c | Record GPU, driver and any errors | XS | you |
| P2.A1.d | Repeat on a second, low-end or iGPU machine | S | you |
| **P2.A2** | **Cross-platform test comparison** | | |
| P2.A2.a | Run `run_tests.sh --quick` on Windows | S | you |
| P2.A2.b | Run `determinism_test` on Windows | XS | you |
| P2.A2.c | Diff the hashes against Linux | XS |  |
| P2.A2.d | Log any divergence as a bug | XS |  |
| **P2.A3** | **Release build script** | | |
| P2.A3.a | Write `tools/build_release.sh` using official templates | M |  |
| P2.A3.b | Update `tools/inspect_pck.py` for pack format 4 | S |  |
| P2.A3.c | Print SHA-256 and size at the end of the build | XS |  |
| P2.A3.d | Delete `build_windows_exe.sh`; update `RELEASE.md` | XS |  |

### 2.C — GodotSteam

*No Steam code exists in the tree.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.C1** | **Choose and pin the engine** | | |
| P2.C1.a | List GodotSteam releases that match 4.7.2 (prefer the GDExtension build) | S |  |
| P2.C1.b | Pin the engine version in `project.godot`, CI and `RELEASE.md` | S |  |
| P2.C1.c | Add `addons/godotsteam/` and its licence to `THIRD_PARTY_NOTICES` | S |  |
| P2.C1.d | Confirm official templates still export with it | S |  |
| **P2.C2** | **Platform wrapper** | | |
| P2.C2.a | `scripts/platform/steam.gd` interface | S |  |
| P2.C2.b | Null backend for headless, CI and non-Steam builds | S |  |
| P2.C2.c | Real backend: init and overlay | M |  |
| P2.C2.d | Test: every harness behaves identically on the null backend | XS |  |
| **P2.C3** | **Achievements** | | |
| P2.C3.a | Pick about 20 and write `scripts/data/achievements.gd` | S |  |
| P2.C3.b | Fire each from the campaign hooks (`campaign`, `rogue`, `politics`) | M |  |
| P2.C3.c | Fake-backend harness asserting each trigger | M |  |
| P2.C3.d | Create them in Steamworks with icons | S | you |
| **P2.C4** | **Steam Auto-Cloud** | | |
| P2.C4.a | Configure paths for `campaign.json(.bak)`, `legacy.json`, `settings.cfg` | S | you |
| P2.C4.b | Round-trip test: play on PC A, continue on PC B | S | you |
| P2.C4.c | Provoke a conflict and watch what happens | S | you |
| P2.C4.d | Write the player-facing behaviour into the manual | XS |  |
| **P2.C5** | **Rich presence** | | |
| P2.C5.a | Write the presence strings | XS |  |
| P2.C5.b | Update them on week start and operation start | S |  |
| P2.C5.c | Keep them as `tr()` keys | XS |  |
| P2.C5.d | Verify in the Steam client | XS | you |

### 2.D — Settings

*Settings offers fullscreen only; no resolution, UI scale or rebinding.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.D1** | **Window mode and resolution** | | |
| P2.D1.a | Resolution list applied in `ui/settings.gd` | S |  |
| P2.D1.b | Windowed / borderless / fullscreen | S |  |
| P2.D1.c | Persist and migrate | XS |  |
| P2.D1.d | `ui_walk` at each resolution | XS |  |
| **P2.D2** | **UI scale** | | |
| P2.D2.a | Expose the existing `--ui-scale` hook as a setting | S |  |
| P2.D2.b | Slider in the settings screen | S |  |
| P2.D2.c | Persist | XS |  |
| P2.D2.d | Overflow check in `ui_walk` at 75 / 100 / 125 / 150% | S |  |
| **P2.D3** | **Rebinding** | | |
| P2.D3.a | Inventory every hard-coded `KEY_*` check (16 tokens in `scripts/` today) | XS |  |
| P2.D3.b | Define InputMap actions in `project.godot` | M |  |
| P2.D3.c | Replace the checks with actions | M |  |
| P2.D3.d | Rebinding screen and persistence | M |  |
| **P2.D4** | **Accessibility options** | | |
| P2.D4.a | Reduced motion: boil off, no camera moves | S |  |
| P2.D4.b | Text-size option | S |  |
| P2.D4.c | Colourblind-safe alternative to red ink | M |  |
| P2.D4.d | Each option checked in `ui_walk` | XS |  |

### 2.E — Controller and Steam Deck

*No controller handling in `scripts/`.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.E1** | **Focus navigation** | | |
| P2.E1.a | Set focus neighbours in `_btn()` and the UI theme | M |  |
| P2.E1.b | Grab focus on the first actionable control of every dynamically built screen | M |  |
| P2.E1.c | Visible focus ring | S |  |
| P2.E1.d | `ui_walk --input=pad` pass over every screen | S |  |
| **P2.E2** | **Map cursor with a stick** | | |
| P2.E2.a | Cursor mode on the plan map driven by stick or trackpad | M |  |
| P2.E2.b | Place, face and set entry point with pad buttons | M |  |
| P2.E2.c | On-screen pad hints | S |  |
| P2.E2.d | Pad run in `ui_walk` | S |  |
| **P2.E3** | **Steam Input config** | | |
| P2.E3.a | Default configuration in Steamworks | S | you |
| P2.E3.b | Map to the InputMap actions | S |  |
| P2.E3.c | Test on a pad | S | you |
| P2.E3.d | Test on a Deck if you can borrow one | S | you |
| **P2.E4** | **Pad walk in the test harness** | | |
| P2.E4.a | Add `--resolution=1280x800 --input=pad` to `ui_walk` | S |  |
| P2.E4.b | Drive `ui_accept` / `ui_down` events instead of `pressed.emit()` | M |  |
| P2.E4.c | Assert every actionable control is reachable | S |  |
| P2.E4.d | Wire it into the quick tier or CI | XS |  |

### 2.F — Saves and bug reports

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.F1** | **Save migration** | | |
| P2.F1.a | Collect a save fixture from each shipped version | S |  |
| P2.F1.b | Loader migration test over all fixtures | S |  |
| P2.F1.c | 'This update cannot load your run' notice path | S |  |
| P2.F1.d | Corrupt-save fallback test through `.bak` | XS |  |
| **P2.F2** | **Report a problem** | | |
| P2.F2.a | Collect version, seed, week, last 200 log lines and settings | S |  |
| P2.F2.b | Copy to the clipboard | XS |  |
| P2.F2.c | Open the logs folder | XS |  |
| P2.F2.d | Button on title and pause screens, with a test | S |  |

### 2.G — Localization scaffold (optional for EA)

*0 `tr()` calls in `scripts/` today.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P2.G1** | **Strings out of code** | | |
| P2.G1.a | Script that extracts the ~1,500 inline strings into one CSV | M |  |
| P2.G1.b | Lint rule in `gd47_check` that new user-facing strings use `tr()` | S |  |
| P2.G1.c | Convert one screen as a pilot | S |  |
| P2.G1.d | English locale round-trip test from the CSV | S |  |

## Stage 3 - First-hour screens

11 items → 44 tasks · about 20 days · owner-only tasks: 4

**Gate 3: no stall over 60 s in the second new-player session; overflow check clean at four resolutions; the `ops_ui_test` backdrop assertion passes.**

### 3.A — The left side of every management screen

*Drafts, roster, budget, IA and City Hall still sit over the last operation's map.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P3.A1** | **City backdrop helper** | | |
| P3.A1.a | Write `_city_backdrop()` | S |  |
| P3.A1.b | Call it from the ten management screens | S |  |
| P3.A1.c | `_clear_views()` hides floor plan, decals, fog and stamps | S |  |
| P3.A1.d | Screenshot every screen | XS |  |
| **P3.A2** | **Left pane tells you who or where** | | |
| P3.A2.a | Ally portrait on offers | M |  |
| P3.A2.b | Officer's file on IA cases | M |  |
| P3.A2.c | Ward pins on the budget | S |  |
| P3.A2.d | Review against the screenshots | XS |  |
| **P3.A3** | **Backdrop assertion** | | |
| P3.A3.a | `ops_ui_test`: `city_map` visible and floor plan hidden on non-plan screens | S |  |
| P3.A3.b | Cover all ten screens | S |  |
| P3.A3.c | Break it on purpose and confirm the test fails | XS |  |
| P3.A3.d | Assert no stale 'FILED / NOT RESOLVED' stamps remain | XS |  |

### 3.B — Say why, visibly

| ID | Task | Size | Who |
|---|---|---|---|
| **P3.B1** | **Disabled-button reasons** | | |
| P3.B1.a | `_btn_reason()` helper | S |  |
| P3.B1.b | Apply it at the six disabled-button sites | S |  |
| P3.B1.c | Style the reason text | XS |  |
| P3.B1.d | `ops_ui_test`: every disabled button has visible reason text | S |  |
| **P3.B2** | **Week-1 desk guidance** | | |
| P3.B2.a | Detect the 'inheritance not chosen' state | XS |  |
| P3.B2.b | Scroll to and highlight the Desk card | S |  |
| P3.B2.c | Plain-text next-action line | XS |  |
| P3.B2.d | `ui_walk` check | XS |  |
| **P3.B3** | **End-week confirmation** | | |
| P3.B3.a | Count open calls at End week | XS |  |
| P3.B3.b | Confirm text naming the consequence | S |  |
| P3.B3.c | Consequence estimate from `politics` | S |  |
| P3.B3.d | Test | XS |  |

### 3.C — Legible text

*Management text is 10-12 px at 1600x900.*

| ID | Task | Size | Who |
|---|---|---|---|
| **P3.C1** | **Font sizes** | | |
| P3.C1.a | Centralise sizes in `UI.make_theme()` | S |  |
| P3.C1.b | Raise 10-12 px text to 13-14 px | M |  |
| P3.C1.c | Reflow the screens that now overflow | M |  |
| P3.C1.d | Run the overflow check from P0.B1 | S |  |
| **P3.C2** | **Four-resolution walk** | | |
| P3.C2.a | `ui_walk` at 1280x720, 1280x800, 1600x900, 1920x1080 | S |  |
| P3.C2.b | Read every screenshot and list defects | M |  |
| P3.C2.c | Fix the defects | M |  |
| P3.C2.d | Re-run | XS |  |
| **P3.C3** | **Debrief summary** | | |
| P3.C3.a | Design the three-line summary (result, people, what follows) | XS |  |
| P3.C3.b | Generate it from debrief data | S |  |
| P3.C3.c | Place it above the arithmetic | S |  |
| P3.C3.d | Test | XS |  |

### 3.D — New players

| ID | Task | Size | Who |
|---|---|---|---|
| **P3.D1** | **First session** | | |
| P3.D1.a | Recruit two people who have never played | S | you |
| P3.D1.b | Record title to end of week 2 with no help | S | you |
| P3.D1.c | Log every stall over 20 s and every misread | M | you |
| P3.D1.d | Write the findings into a results doc | S |  |
| **P3.D2** | **Second session** | | |
| P3.D2.a | Rank the top three stalls | XS |  |
| P3.D2.b | Fix them | M |  |
| P3.D2.c | Recruit two new people and record | M | you |
| P3.D2.d | Compare against the gate (no stall over 60 s) | S |  |

## Stage 4 - Content, music, finish

9 items → 38 tasks · about 23 days · owner-only tasks: 7

**Gate 4: music in all four screen families; no short half-wired; balance smoke still inside the bands after content batches.**

### 4.A — Music

*No music in the tree (`assets/` has crayon, cutscenes, sfx, svg).*

| ID | Task | Size | Who |
|---|---|---|---|
| **P4.A1** | **Four beds** | | |
| P4.A1.a | Title bed; record licence in `THIRD_PARTY_NOTICES` | M | you |
| P4.A1.b | Board / desk bed | M | you |
| P4.A1.c | Operation bed (tension, duckable under radio and gunfire) | M | you |
| P4.A1.d | Debrief / election-night bed | M | you |
| **P4.A2** | **Music bus** | | |
| P4.A2.a | Music bus and volume slider | S |  |
| P4.A2.b | Crossfade by screen family | S |  |
| P4.A2.c | Ducking on radio and gunfire | S |  |
| P4.A2.d | Silence music during 'nothing happened' fast-forward | S |  |
| **P4.A3** | **Mix check** | | |
| P4.A3.a | Loudness measuring script | S |  |
| P4.A3.b | Normalise the four beds | S |  |
| P4.A3.c | Compare against SFX levels | S |  |
| P4.A3.d | Record the figures in the release notes | XS |  |

### 4.B — The ten unplayed shorts

| ID | Task | Size | Who |
|---|---|---|---|
| **P4.B1** | **Wire or drop** | | |
| P4.B1.a | Map each of the ten to the beat `cinematics/SHORTS.md` names | S |  |
| P4.B1.b | Wire the first five through `play_consequence_short` / `claim_short` | M |  |
| P4.B1.c | Wire the other five, or exclude them in `export_presets.cfg` | M |  |
| P4.B1.d | Check the export size change | XS |  |
| **P4.B2** | **Shorts harness** | | |
| P4.B2.a | `tests/shorts_test.gd` that forces each trigger | M |  |
| P4.B2.b | Assert each key is claimed once per run | S |  |
| P4.B2.c | Cover all ten cases | S |  |
| P4.B2.d | Add it to the quick or full tier | XS |  |

### 4.C — Cutscene look

| ID | Task | Size | Who |
|---|---|---|---|
| **P4.C1** | **Ship as-is or re-render** | | |
| P4.C1.a | Decide; write it down | XS | you |
| P4.C1.b | If as-is: write the line for the EA notes | XS |  |
| P4.C1.c | If re-render: spike the tooling | M |  |
| P4.C1.d | Record the choice in the Q&A draft | XS |  |

### 4.D — Variety per run

| ID | Task | Size | Who |
|---|---|---|---|
| **P4.D1** | **More events and offers** | | |
| P4.D1.a | Events 20 -> 25, each with reproducibility and effect assertions in `rogue_test` | M |  |
| P4.D1.b | Events 25 -> 30, same checks | M |  |
| P4.D1.c | Events 30 -> 35, same checks | M |  |
| P4.D1.d | Offers 14 -> 19 | M |  |
| P4.D1.e | Offers 19 -> 24 | M |  |
| P4.D1.f | Balance smoke after every batch | S |  |
| **P4.D2** | **Second doctrine tier** | | |
| P4.D2.a | Design the tier-2 doctrines | M |  |
| P4.D2.b | Unlock them through the legacy file | M |  |
| P4.D2.c | Balance smoke for each | S |  |
| P4.D2.d | Tests | S |  |

### 4.E — The 1.5 command layer

| ID | Task | Size | Who |
|---|---|---|---|
| **P4.E1** | **Recover or defer** | | |
| P4.E1.a | Find the session copy with `deploy.gd`, `command_test.gd`, `strike.gd` and maps 12-15 | S | you |
| P4.E1.b | Decide: merge before EA or list as a plan | XS | you |
| P4.E1.c | If merging: integrate; `command_test` passes on all maps | M |  |
| P4.E1.d | Re-baseline the balance, or add the plan line to the Q&A | S |  |

## Stage 5 - Store page, demo, testers, launch

18 items → 72 tasks · about 31 days · owner-only tasks: 43

**Gate 5: demo public by April; Next Fest registered by 25 Apr; build review submitted at least 7 business days before launch.**

### 5.A — Store page

| ID | Task | Size | Who |
|---|---|---|---|
| **P5.A1** | **Art** | | |
| P5.A1.a | Capsule art at the current Steamworks sizes | M | you |
| P5.A1.b | Library art | M | you |
| P5.A1.c | Logo | M | you |
| P5.A1.d | Readability check at small-capsule size | S | you |
| **P5.A2** | **Screenshots** | | |
| P5.A2.a | Choose 6-10 scenes | S |  |
| P5.A2.b | Capture at 1920x1080 through `ui_walk` after Phase 3 | S |  |
| P5.A2.c | Check each is gameplay-only | XS |  |
| P5.A2.d | Upload | XS | you |
| **P5.A3** | **Trailer** | | |
| P5.A3.a | Script and storyboard 60-90 s | S |  |
| P5.A3.b | Capture footage with `tools/make_ads.py` | M |  |
| P5.A3.c | Mix with `mix_soundtrack.py` and your music | S |  |
| P5.A3.d | Cut and review | M |  |
| **P5.A4** | **Description and survey** | | |
| P5.A4.a | Description and tags | S | you |
| P5.A4.b | Content survey (violence, gore toggle, police-violence themes) | S | you |
| P5.A4.c | AI-content disclosure: decide which text and art it covers | S | you |
| P5.A4.d | Submit at least 7 business days before you want it live | XS | you |
| **P5.A5** | **Coming Soon** | | |
| P5.A5.a | Page approved | XS | you |
| P5.A5.b | Set Coming Soon live | XS | you |
| P5.A5.c | Track wishlists weekly | XS | you |
| P5.A5.d | Announce | XS | you |

### 5.B — Demo

| ID | Task | Size | Who |
|---|---|---|---|
| **P5.B1** | **Demo build** | | |
| P5.B1.a | `demo` export feature tag | S |  |
| P5.B1.b | Run ends after week 10 on a card ('the election is thirty weeks away') | M |  |
| P5.B1.c | Separate legacy file; no achievements | S |  |
| P5.B1.d | Balance smoke truncated to 10 weeks | S |  |
| **P5.B2** | **Demo app and page** | | |
| P5.B2.a | Create the demo app and depot | S | you |
| P5.B2.b | Demo store page | M | you |
| P5.B2.c | Upload the build | XS | you |
| P5.B2.d | Submit for review | XS | you |
| **P5.B3** | **Demo playtest** | | |
| P5.B3.a | Full playtest loop on the demo build | M |  |
| P5.B3.b | 10-week balance smoke | S |  |
| P5.B3.c | Fresh-player session | S | you |
| P5.B3.d | Fix what it finds | M |  |

### 5.C — Testers

| ID | Task | Size | Who |
|---|---|---|---|
| **P5.C1** | **Closed test** | | |
| P5.C1.a | Recruit 20-50 testers | S | you |
| P5.C1.b | Set up Steam Playtest | S | you |
| P5.C1.c | Push a build to `beta` | XS | you |
| P5.C1.d | Onboarding message with how to attach Report-a-problem text | XS | you |
| **P5.C2** | **Weekly loop** | | |
| P5.C2.a | Calendar: build Monday, play all week, triage Friday | XS | you |
| P5.C2.b | Triage template (crash, balance, confusion) | XS |  |
| P5.C2.c | Collect Report-a-problem text and run JSON | S |  |
| P5.C2.d | Fix the following week; changelog line per fix | S |  |
| **P5.C3** | **Read the data** | | |
| P5.C3.a | Compare tester runs with the four policies | S |  |
| P5.C3.b | Look for a dominant strategy | S |  |
| P5.C3.c | Find the week where people stop playing | S |  |
| P5.C3.d | File tasks from what it shows | XS |  |

### 5.D — Next Fest and launch (June 2027 option)

| ID | Task | Size | Who |
|---|---|---|---|
| **P5.D1** | **Demo public (April)** | | |
| P5.D1.a | Final demo build and smoke | S |  |
| P5.D1.b | Check the page links | XS | you |
| P5.D1.c | Publish | XS | you |
| P5.D1.d | Announce | XS | you |
| **P5.D2** | **Register by 25 Apr** | | |
| P5.D2.a | Confirm eligibility | XS | you |
| P5.D2.b | Register | XS | you |
| P5.D2.c | Fill the festival page | S | you |
| P5.D2.d | Verify the registration | XS | you |
| **P5.D3** | **Press preview by 10 May** | | |
| P5.D3.a | Submit demo and page | S | you |
| P5.D3.b | Check for review feedback | XS | you |
| P5.D3.c | Fix anything flagged | S |  |
| P5.D3.d | Resubmit if needed | XS | you |
| **P5.D4** | **Everything in by 24 May** | | |
| P5.D4.a | Final art and trailer check | S | you |
| P5.D4.b | Final demo build check | S |  |
| P5.D4.c | Submit | XS | you |
| P5.D4.d | Confirm acceptance | XS | you |
| **P5.D5** | **Next Fest 14-21 Jun** | | |
| P5.D5.a | Be online and answer players | M | you |
| P5.D5.b | Monitor Report-a-problem texts | S |  |
| P5.D5.c | Hotfix path ready | S |  |
| P5.D5.d | Wishlist report afterwards | XS | you |
| **P5.D6** | **Early Access Q&A and build review** | | |
| P5.D6.a | Draft the Q&A (no dated promises) | M | you |
| P5.D6.b | Set the price below the 1.0 price | S | you |
| P5.D6.c | List known issues and save-compatibility policy | S |  |
| P5.D6.d | Submit the build at least 7 business days before launch | XS | you |
| **P5.D7** | **Launch and first patches** | | |
| P5.D7.a | Run the launch checklist | S | you |
| P5.D7.b | Launch day: be online | M | you |
| P5.D7.c | First patch at 2-3 weeks | M |  |
| P5.D7.d | Second patch | M |  |

## Track S - Story opening and tutorial (needs your go/no-go)

5 items → 20 tasks · about 12 days · owner-only tasks: 1

**Decision D-S by 15 Jan: which of S2-S5 ship in Early Access. Effort is counted separately so you can see the plan with and without it.**

### S.A — Canon fixes

*The plan doc lists two open questions.*

| ID | Task | Size | Who |
|---|---|---|---|
| **S1** | **Timeline and title** | | |
| S1.a | Decide: election after the campaign's end, or reconcile the Fettick dates | XS | you |
| S1.b | Adjust campaign dates / Ledger text, or the diary dates, to match | S |  |
| S1.c | Make Grendel's title (Acting Chief vs Chief) consistent everywhere | S |  |
| S1.d | Update the canon doc | XS |  |

### S.B — Tutorial and structure (plan only today)

*Nothing below the cutscene prototypes is implemented.*

| ID | Task | Size | Who |
|---|---|---|---|
| **S2** | **Paisley Tower tutorial mission** | | |
| S2.a | Build the Paisley Tower top-floor map (a 13th map) | M |  |
| S2.b | Jeremy's 'Desperate' suspect state: sneak, hide, run until cornered | M |  |
| S2.c | Ten-officer SOS fixed force and the scripted moments from both sides | M |  |
| S2.d | Ending choice ('Arrest him' / 'He didn't drop it') and the first factional sentiment | M |  |
| **S3** | **Opening sequence flow** | | |
| S3.a | Wire opening, presser and Jeremy cutscenes into new-game start | M |  |
| S3.b | Gate the Fettick cutscene on >50% Carrick alignment | S |  |
| S3.c | Skip and replay controls | S |  |
| S3.d | Flow test from title to the tutorial's first order | S |  |
| **S4** | **Squad selection and archetypes** | | |
| S4.a | Leader-only selection UI; the rest auto-populate | M |  |
| S4.b | Auto-populate rule and test | S |  |
| S4.c | Archetype speccing screen past Sergeant | M |  |
| S4.d | Experience cap (85% of good habits, at most two bad) | S |  |
| **S5** | **Training programs rework** | | |
| S5.a | Offer a program only if fewer than half the officers would benefit | S |  |
| S5.b | Programs become universal on/off habit switches | M |  |
| S5.c | One-time effect on the current force only | S |  |
| S5.d | `rogue_test` coverage and balance smoke | S |  |

---

## 6. Decisions only you can make, with the date each one starts to cost you

| # | Decision | Needed by | Why then |
|---|---|---|---|
| 1 | P1.B6: posture at public events (accept 3–5 s, low-ready, or per-event option) | before Stage 1 tuning finishes (~mid-Dec) | It changes every crowd event, so every balance number after it |
| 2 | P1.F2: does Kettering keeping a brutal chief stay, and how does the score treat it | before P1.F1 | Sets what the election weights are for |
| 3 | P1.I2: the Gate 1 band thresholds | before Gate 1 (mid-Jan) | Bands start asserting |
| 4 | D-S: which of S2–S5 (tutorial mission, squad selection, training rework) ship in Early Access | **15 Jan** | S2 adds a 13th map and S4 changes the squad UI; both reopen balance and first-hour work |
| 5 | S1: how to reconcile the 1999 campaign with the Fettick diary's 2000 dates, and Grendel's title | December | Touches Ledger text, cutscene captions and the canon doc |
| 6 | P4.C1: ship the red-ink cutscenes as they are | February | Stage 4 |
| 7 | P4.E1: recover the 1.5 command layer or ship 12 maps | February | Stage 4 |
| 8 | P5.A4: which text and art the AI-content disclosure covers | before the store page is submitted | Valve's survey |
| 9 | EA price and the intended 1.0 price | before P5.D6 | Q&A |

## 7. Risks

| Risk | What to do |
|---|---|
| The money fix (P1.D) does not close the 1.C exit | Cut scope before moving dates: fewer allies or a simpler overdraft. P1.CX re-runs the 20-seed matrix right after P1.D to find out early |
| The clearance fixes moved the campaign numbers | CL3 re-baselines on day one of Stage 0, before any tuning is measured against stale numbers |
| Owner-only work bunches up in Stages 2 and 5 (66 of the 84 owner-only tasks) | Start P2.B1 this week; the app account, tax details and waiting period run on Valve's clock, not yours |
| Story track reopens balance | Treat D-S as a go/no-go; if S2 is in, run the balance smoke on the tutorial and re-check the first hour in P3.D |
| Windows has never run the game | P2.A1 is cheap and can move to week 2 of Stage 0 if you want the risk retired earlier |

## 8. What I could not check

- I did not run Godot. Everything about test results comes from the status lines in `docs/EA_TASKS.md`, the changelog, and `tests/results/`.
- The tree has no `.git`, so branch, PR and CI state are from the docs.
- Effort sizes are mine, not measured; the calendar is a sequence, not a forecast.
- The project's copy of `EA Task Plan` is older than `docs/EA_TASKS.md` in the repo (it has no 1.C status). The repo copy is the one I used.

*Sources: `docs/EA_TASKS.md`, `docs/EARLY_ACCESS_ROADMAP.md`, `docs/CLEARANCE_DIAGNOSIS_2026-11-02.md`, `tests/results/clearance-2026-11-02/README.md`, `CHANGELOG.md`, `RELEASE_READINESS.md`, the project's Story Opening & Tutorial Plan, and file counts taken from the tree on 2 Nov. Next Fest and Steam review dates are from the 28 Oct roadmap, which cites Steamworks; I did not re-check them today.*
