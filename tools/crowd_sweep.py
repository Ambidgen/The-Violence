#!/usr/bin/env python3
"""The Violence: the crowd-escalation sweep for EA_TASKS cycle 1.B.

Runs tests/event_probe.gd over a grid of trauma floors, morale levels and quiet /
attacked events, in parallel chunks, and prints one table row per condition.

    GODOT=/path/to/godot python3 tools/crowd_sweep.py --n=20 --trauma=0,14,20 --morale=60 --attack=both
    python3 tools/crowd_sweep.py --n=20 --out=tests/results/cycle-1B/before   # writes events.jsonl + table.md
    python3 tools/crowd_sweep.py --summarize shards/*/crowd.txt --out=DIR        # CI: join shard outputs

Gate 1.B (EA_TASKS): in quiet events, at most 1 distinct civilian struck by police per
event at trauma 14 and 20; with --gate the script exits 1 if a quiet condition at a
trauma floor of 14 or more breaks that, or if any attacked event's attacker is never
stopped. The comparison with a baseline (attackers stopped no later, harm no worse)
is read from the two tables, not enforced here.
"""
import argparse
import json
import os
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def run_chunk(godot, trauma, morale, attack, first, n, officers, env):
    cmd = [godot, "--headless", "--path", str(ROOT), "-s", "res://tests/event_probe.gd", "--",
           f"--trauma={trauma}", f"--morale={morale}", f"--first={first}", f"--n={n}",
           f"--officers={officers}", "--json"] + (["--attack"] if attack else [])
    p = subprocess.run(cmd, capture_output=True, text=True, env=env)
    events, errors = [], []
    for line in (p.stdout + p.stderr).splitlines():
        if line.startswith("EVENT "):
            events.append(json.loads(line[6:]))
        elif "SCRIPT ERROR" in line or line.startswith("ERROR:"):
            errors.append(line)
    return {"trauma": trauma, "morale": morale, "attack": attack, "events": events,
            "rc": p.returncode, "errors": errors}


def summarise(evs):
    n = len(evs)
    s = lambda k: sum(e[k] for e in evs)
    row = {"events": n, "events_struck": sum(1 for e in evs if e["civ_struck"] > 0),
           "struck": s("civ_struck"), "max_struck": max((e["civ_struck"] for e in evs), default=0),
           "killed_by_police": s("civ_killed_police"), "misjudged": s("misjudged"),
           "police_shots": s("police_shots")}
    if evs and evs[0]["attack"]:
        stopped = [e for e in evs if e["stopped"]]
        row["stopped"] = len(stopped)
        row["stop_s_mean"] = round(sum(e["stop_s"] for e in stopped) / len(stopped), 1) if stopped else None
        row["stop_s_max"] = max((e["stop_s"] for e in stopped), default=None)
        row["struck_by_attacker"] = s("civ_struck_by_attacker")
    return row


def read_events(paths):
    """EVENT lines from probe output files (CI shards), as one list."""
    out = []
    for p in paths:
        for line in Path(p).read_text(errors="ignore").splitlines():
            if line.startswith("EVENT "):
                out.append(json.loads(line[6:]))
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--summarize", nargs="+", type=Path,
                    help="no runs: read EVENT lines from these files (CI shards) and print the table")
    ap.add_argument("--n", type=int, default=20)
    ap.add_argument("--trauma", default="0,14,20")
    ap.add_argument("--morale", default="60")
    ap.add_argument("--attack", choices=["no", "yes", "both"], default="both")
    ap.add_argument("--officers", type=int, default=2)
    ap.add_argument("--jobs", type=int, default=max(1, min(4, os.cpu_count() or 1)))
    ap.add_argument("--chunk", type=int, default=5, help="events per process")
    ap.add_argument("--out", type=Path)
    ap.add_argument("--gate", action="store_true")
    a = ap.parse_args()
    if a.summarize:
        evs = read_events(a.summarize)
        results = [{"trauma": e["trauma"], "morale": e["morale"], "attack": e["attack"], "events": [e],
                    "rc": 0, "errors": []} for e in evs]
        return report(results, a)
    godot = os.environ.get("GODOT", "godot")
    traumas = [float(x) for x in a.trauma.split(",")]
    morales = [int(x) for x in a.morale.split(",")]
    attacks = {"no": [False], "yes": [True], "both": [False, True]}[a.attack]
    tasks = []
    for t in traumas:
        for m in morales:
            for at in attacks:
                for first in range(0, a.n, a.chunk):
                    tasks.append((t, m, at, first, min(a.chunk, a.n - first)))
    env = dict(os.environ)
    results = []
    with ThreadPoolExecutor(max_workers=a.jobs) as ex:
        futs = []
        for i, (t, m, at, first, n) in enumerate(tasks):
            e = dict(env, XDG_DATA_HOME=str(Path(os.environ.get("TMPDIR", "/tmp")) / f"crowd_sweep_{os.getpid()}_{i}"))
            futs.append(ex.submit(run_chunk, godot, t, m, at, first, n, a.officers, e))
        for f in futs:
            results.append(f.result())
    return report(results, a)


def report(results, a):
    groups = {}
    problems = []
    for r in results:
        groups.setdefault((r["trauma"], r["morale"], r["attack"]), []).extend(r["events"])
        if r["rc"] != 0 or r["errors"]:
            problems.append(f"trauma {r['trauma']} morale {r['morale']} attack {r['attack']}: exit {r['rc']} {r['errors'][:2]}")
    lines = ["| trauma | morale | event | events | with a civilian struck | civilians struck (max in one) | killed by police | misjudged | police shots | attacker stopped | stop s mean / max | struck by attacker |",
             "|---|---|---|---|---|---|---|---|---|---|---|---|"]
    gate_fail = []
    for (t, m, at), evs in sorted(groups.items()):
        evs.sort(key=lambda e: e["seed"])
        r = summarise(evs)
        lines.append("| {:g} | {} | {} | {} | {} | {} ({}) | {} | {} | {} | {} | {} | {} |".format(
            t, m, "attacked" if at else "quiet", r["events"], r["events_struck"], r["struck"], r["max_struck"],
            r["killed_by_police"], r["misjudged"], r["police_shots"],
            f"{r['stopped']}/{r['events']}" if at else "—",
            f"{r['stop_s_mean']} / {r['stop_s_max']}" if at else "—",
            r["struck_by_attacker"] if at else "—"))
        if not at and t >= 14 and r["max_struck"] > 1:
            gate_fail.append(f"quiet, trauma {t:g}, morale {m}: up to {r['max_struck']} civilians struck in one event (gate: at most 1)")
        if at and r["stopped"] < r["events"]:
            gate_fail.append(f"attacked, trauma {t:g}, morale {m}: attacker not stopped in {r['events'] - r['stopped']} event(s)")
    table = "\n".join(lines)
    print(table)
    for p in problems:
        print("PROBLEM", p, file=sys.stderr)
    for g in gate_fail:
        print("GATE", g)
    if a.out:
        a.out.mkdir(parents=True, exist_ok=True)
        with (a.out / "events.jsonl").open("w") as f:
            for (t, m, at), evs in sorted(groups.items()):
                for e in evs:
                    f.write(json.dumps(e) + "\n")
        (a.out / "table.md").write_text(table + "\n" + "".join(f"\nGATE {g}" for g in gate_fail) + "\n")
    if problems:
        return 1
    return 1 if (a.gate and gate_fail) else 0


if __name__ == "__main__":
    sys.exit(main())
