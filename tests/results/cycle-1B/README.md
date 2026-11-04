# Cycle 1.B evidence — the crowd cliff

Every table here is the CI **crowd** tier (`Run workflow` → ci → tier=crowd): `tests/event_probe.gd`
over 60 seeds (5000 + 17k, k = 0…59) per condition, quiet and attacked events, trauma floors 0 / 14 / 20,
morale 60, two officers on post, joined by `tools/crowd_sweep.py --summarize`. Each folder has the
table (`table.md`) and one JSON line per event (`events.jsonl`).

| folder | code | what it is |
|---|---|---|
| `before/` | e257aa0 | the probe and the sweep, no simulation change: the baseline |
| `first-cut/` | 181005a | fixes A, B, C, C2 and the crowd cue: the quiet gate met, attacks answered later and the attacker hitting ~60% more people |
| `ci-<sha>/` | the cycle's head | adds *shooter first* and *to the shots*: the result reported in `docs/EA_TASKS.md` §1.B |

Numbers are deterministic for a given commit and engine (Godot 4.7.2), so a re-run of the same commit
reproduces its table exactly. Exit 3 is judged paired by seed (`events.jsonl`, keyed on trauma and seed).
