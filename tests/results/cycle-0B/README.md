# Cycle 0.B — playtest tooling in the tree (2026-10-28)

Engine: official Godot 4.7.2 (Linux; campaigns headless, the walk rendered with software GL under Xvfb at 1600×900).

**Exit test:** `tools/playtest.sh` with no arguments reproduces the 28 Oct campaign playtest
(`docs/PLAYTEST_2026-10-28_CAMPAIGN.md`): every figure in `report.md` matches that report, and the
week-by-week account lines of all three runs are identical to the 28 Oct logs. The walk took the same
path as the 28 Oct click-through, with 0 failures and 2 KNOWN problems (EA_TASKS P3.A1, P3.B1).

| File | What |
|---|---|
| `report.md`, `report.csv` | the table (`tools/campaign_report.py`) |
| `campaign-seed1001/2002/3003.json` and `.log` | `op_test.gd --json` output and console |
| `walk/` | 18 screenshots (converted to JPEG for the repository; the tool writes PNG), the side-panel text of each, `walk.json`, `walk.log` |
| `playtest-console.log` | what the command printed |
| `quick.log` | `tools/run_tests.sh --quick` with `ui_walk` in the tier: 17/17 |

New in the table compared with 28 Oct: weeks with fewer than 12 fit (8, 35, 33 of 40); weeks below $0 in
weeks 1–12 (8, 0, 5); the union lost in **week 10** in seeds 1001 and 2002, which the old log never
printed; and run scores **−2,207 / −829 / −1,202**. The minimal-effort run that lost every ally and left
80 calls unattended scores best, because the chief was kept: EA_TASKS P1.F2.
