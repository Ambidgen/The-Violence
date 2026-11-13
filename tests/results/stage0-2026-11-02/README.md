# Stage 0 verification — 2 November 2026

Roadmap tasks CL1 (quick tier in an imported official editor) and the first step of CL3 (determinism).

**Engine:** official Godot 4.7.2.stable (`ed1daf0bf`) from godotengine/godot-builds, SHA-512 checked against the release's SHA512-SUMS.txt. Linux x86_64, 2 cores. The project was copied to a scratch folder and imported there (`--headless --editor --quit`), so this folder was not modified except for this results directory.

## Quick tier: 22 of 22 suites pass

The first 13 (`_check` through `dept_test`) ran under `tools/run_tests.sh --quick`. That run was cut off when the shell session ended, so the other nine were run one at a time with the same arguments the runner uses (logs in `logs/`). `orders_test` was run one order at a time (`--only=`), 15 of 15 PASS. `ui_walk --verbose`: 0 failures, 2 known (P3.A1, P3.B1), no resource-leak or script errors in the log. `rogue_balance_test --smoke`: 4 runs, 0 broken, 13 band misses (report-only).

| Suite group | Result |
|---|---|
| `_check`, `godot472`, `city_integration`, `character_assets`, `group_movement`, `clearance_model` | PASS |
| `test_range_mechanics / regression / replays / determinism` | PASS |
| `improvements`, `ops_ui`, `dept`, `save`, `story`, `politics`, `rogue`, `policies`, `kit_proposal` | PASS |
| `orders_test` (15 orders) | PASS |
| `rogue_balance_test --smoke` | PASS, 0 broken |
| `ui_walk` | PASS, 2 known |

The runner itself was not allowed to finish, so its own engine-error log scan was not applied to the nine suites run by hand; I checked the logs of the five fast ones for `SCRIPT ERROR` / `Parse Error` (none) and `ui_walk` for leaks (none).

CL1.a and CL1.b are done: the three suites that could not be validated on 2 Nov (`character_assets_test`, `ops_ui_test`, `ui_walk`) pass, so there were no real failures to fix. Not done: the same run on 4.4.1 (CL1.d).

## Campaign determinism: 35 of 35 cases changed

`determinism_test` (xfail in the runner): **35 cases, 35 changed** (100 s). On 28 Oct the note in `run_tests.sh` says 22 of 35 changed. The fixture is stale as expected; the extra 13 are consistent with the 1.B/1.C and 2 Nov clearance changes but this tree has no git history, so I could not attribute any case to a cause (CL3.b). Do not `--write` yet; that waits for P1.I1.

## Not done here

The 8-seed x 4-policy balance reference (CL3.c) takes 21-34 minutes per run, about 32 runs: hours on this machine, and a shell session here ends after three minutes. Run it in CI: Actions > ci > Run workflow, tier=balance, seeds=8, results=tests/results/stage0-2026-11-02/balance.

## B1–B3 (3 November)

See `docs/EA_TASKS.md`, "Stage 0 findings", and `logs-bugs/`. Two changes to `scripts/sim/world.gd` (surrender late-shot window, shield flinch rate) and the shield entry of `tests/fixtures/test_range_determinism.json`. After them: quick tier green on 4.7.2, the range fixture passes, 15/15 order gates, brains as before (wolf seed-count issue), equipment gates: shield, beanbag and launcher fail (launcher was already failing), the rest pass.

## All bugs fixed (3 November, later)

Every gate in the quick and full tiers passes on 4.7.2: equipment 28/28, orders 15/15, brains 9/9, civ, lethality, hold (maps 0, 4, 5, 6), stall (all 12 maps), maps, doors, fuzz (seeds 4242 and 5252, 60 matches, 0 draws), quick tier 22/22, balance smoke 0 broken, `ui_walk` 7 clean runs. Changes: `scripts/sim/world.gd`, `scripts/sim/brain.gd`, `scripts/data/equipment.gd` (beanbag wind-up), `tests/equip_test.gd` (shield measure), `tests/brains_test.gd` (wolf seeds). Logs in `logs-bugfix-2026-11-03/`. Full account: `docs/EA_TASKS.md`, "Stage 0 bug fixes".
