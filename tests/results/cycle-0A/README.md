# Cycle 0.A — harnesses that fail honestly (2026-10-28)

Engine: official Godot 4.7.2 (Linux, headless, 2 cores, `TIMEOUT_SCALE` defaulted to 2).

| Check | Result | Log |
|---|---|---|
| Runner self-tests (`tests/test_runner.py`) | 13/13 pass; the new xfail-crash test fails (4 subtests) with the signature check removed | `runner_unittests.log` |
| Break-one-assertion sweep, 14 changed harnesses | **14/14 exit 1 when broken** (`mutate.py`; original runs at small args are shown alongside) | `mutation.log` |
| `tools/run_tests.sh --quick` | **16/16 pass** | `quick.log` |
| `tools/run_tests.sh --full` | 25 pass, 1 KNOWN (`determinism_test`, stale fixture), **2 FAIL** | `full.log` |

The two full-tier failures are **pre-existing simulation findings, not regressions**: `brains_test`
was already exit-code-gated and `equip_test` was already failed by the old runner's log scan.
They are logged as EA_TASKS B1–B3:

- **B1 `brains_test` wolf:** a lone fighter in an unseen fight spends *less* of it hidden with the
  wolf brain on (0.19) than off (0.28); the gate wants more.
- **B2 `equip_test` shield:** rounds reaching an officer facing three rifles at 10 m: 1.02 with the
  shield, 0.69 without; the gate wants fewer.
- **B3 `equip_test` beanbag:** seconds until a non-compliant unarmed man is cuffed: 224 with beanbags,
  208 without; the gate wants less.

`equip_test` at `--n=2` (the sweep) fails 9 of 27 items; that is sample size, not a finding. At its plan
setting (`--n=12`) only B2 and B3 fail.
