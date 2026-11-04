# Cycle 0.C — duplicate procurement charge (2026-10-28)

Cycle 0.C of [`docs/EA_TASKS.md`](../../../docs/EA_TASKS.md), from §2 of
[`docs/PLAYTEST_2026-10-28_CAMPAIGN.md`](../../../docs/PLAYTEST_2026-10-28_CAMPAIGN.md):
the week-1 procurement draft is dealt before the inheritance is chosen, so *Plate
carriers on day one* followed by the plate contract charged **$6,000** and added nothing.

## What changed

| Task | Where | What |
|---|---|---|
| P0.C1 | `rogue.gd` `contract_stocked()` / `_open_contracts()` | one predicate: a contract whose every item is stocked is never offered |
| P0.C2 | `rogue.gd` `_revalidate_drafts()` | after any stocking change, a redundant card is re-dealt from the same tier on **its own stream** (`draft_rng`); the card and an empty draft are dropped when nothing is left to offer |
| P0.C3 | `rogue.gd` `pick()` | a contract for stocked kit is refused: a line, no charge, draft still open; `from_data()` repairs restored drafts |
| P0.C4 | `tests/rogue_test.gd` | seeds 1–12 × every inheritance × every contract, the guard, the mid-week free military contract, the stream isolation; `dup_probe.gd` folded in |

## Verification

No Godot engine was available in the sandbox that made the change (the GitHub release
asset host is not reachable from it, so the 4.4.1/4.7.2 downloads fail with
`SSL_ERROR_SYSCALL`). The engine evidence is the CI run on PR #1 (§"Engine run" below).

| Check | Result |
|---|---|
| `python3 tools/gd47_check.py` | **clean**, 128 GDScript files |
| `python3 tools/sync_version.py --check` | in sync at the time (1.2.1 / Windows 1.2.1.0; 1.3.0 from cycle 0.D) |
| `gdparse` (gdtoolkit 4.5.0) on the three changed files | **parses** |

`gdparse` rejects two files this change did not touch — `scripts/ui/ui.gd` and
`tests/orders_test.gd` use a one-line lambda with a `for` statement that gdtoolkit 4.5.0's
grammar does not accept. That is a linter limit, not a finding: both compile in
`_check.gd` on the engines.


## Engine run

CI run **40785806997** on PR #1 (commit `b3ec8cb`), quick tier:

| Job | Result |
|---|---|
| static audit (`gd47_check`, runner tests, version check) | **success** |
| headless (4.7.2-stable) — quick tier, `rogue_test` included | **success** |
| headless (4.4.1-stable) — quick tier, `rogue_test` included | **success** |

`rogue_test` exits 1 when any of its checks fail, and the runner trusts that code, so a
green job means every new assertion held on both engines: 0 wasted purchases across
seeds 1–12 × every inheritance × every contract, the guard, the mid-week free military
contract, the replacement stream, and the ten-week "same seed, same desk" check.

The CI log blob host is not reachable from the sandbox that wrote this, so the per-case
`PASS` lines are not quoted here; the job conclusions are. To read them:

```sh
gh run view 40785806997 --job 123158573998 --log | grep -E "PASS|FAIL"
```

## Reproduce

```sh
GODOT=/path/to/godot-4.7.2
python3 tools/gd47_check.py
$GODOT --headless --path . -s res://tests/rogue_test.gd -- --matrix-seeds=12   # P0.C gate
$GODOT --headless --path . -s res://tests/rogue_test.gd                        # the whole gate
GODOT=$GODOT tools/run_tests.sh --quick
```

The 28 Oct probe is kept for comparison; it is folded into `rogue_test` but still runs
standalone if copied into `tests/`:

```sh
cp tests/results/playtest-2026-10-28-campaign/logs/dup_probe.gd tests/dup_probe.gd
$GODOT --headless --path . -s res://tests/dup_probe.gd
```
