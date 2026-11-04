#!/usr/bin/env python3
"""The Violence: where the roster bleeds (EA_TASKS P1.C1).

Reads the balance matrix's ops.csv (one line per operation) and, when it is there,
weeks.csv (one line per run-week), and prints a markdown report:

  - officer deaths per operation, by policy
  - by situation type and by map: operations, deaths, deaths per operation, share of all
    deaths, and how they died (a suspect, a colleague, or bled out with nobody named)
  - the type x map pairs that produce most of the deaths
  - from weeks.csv: week-end snapshots with at least 12 fit (the 1.C exit), injury-weeks
    and academy-weeks per run, by policy

    python3 tools/roster_report.py tests/results/cycle-1B/balance            # a results folder
    python3 tools/roster_report.py DIR --policy=cautious --out=DIR/roster.md
"""
import argparse
import csv
import sys
from collections import defaultdict
from pathlib import Path

FIT_FLOOR = 12


def load(path):
    with open(path, newline="") as f:
        return list(csv.DictReader(f))


def num(row, k):
    v = row.get(k, "0") or "0"
    return float(v) if "." in v else int(v)


def table(head, rows):
    out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
    out += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows]
    return "\n".join(out)


def by(ops, key, total_killed):
    g = defaultdict(lambda: {"ops": 0, "sent": 0, "killed": 0, "down": 0, "sus": 0, "fr": 0, "bled": 0})
    for o in ops:
        k = key(o)
        d = g[k]
        d["ops"] += 1
        d["sent"] += num(o, "officers")
        d["killed"] += num(o, "killed")
        d["down"] += num(o, "down")
        d["sus"] += num(o, "killed_by_suspect")
        d["fr"] += num(o, "killed_by_friendly")
        d["bled"] += num(o, "bled_out")
    rows = []
    for k, d in sorted(g.items(), key=lambda kv: -kv[1]["killed"]):
        share = 100.0 * d["killed"] / total_killed if total_killed else 0.0
        rows.append([k, d["ops"], d["killed"], f'{d["killed"] / d["ops"]:.2f}', f"{share:.0f}%",
                     f'{d["sent"] / d["ops"]:.1f}', f'{d["down"] / d["ops"]:.2f}', d["sus"], d["fr"], d["bled"]])
    return rows


def report(folder, policy=None):
    folder = Path(folder)
    ops = load(folder / "ops.csv")
    if policy:
        ops = [o for o in ops if o["policy"] == policy]
    if not ops:
        return f"# Roster bleed\n\nNo operations in {folder}/ops.csv" + (f" for {policy}" if policy else "") + ".\n"
    total_killed = sum(num(o, "killed") for o in ops)
    runs = {(o["seed"], o["policy"]) for o in ops}
    lines = [f"# Roster bleed — {folder}" + (f" ({policy})" if policy else ""), "",
             f"{len(ops)} operations in {len(runs)} runs; {total_killed} officers killed, "
             f"**{total_killed / len(ops):.2f} per operation**.", ""]
    pol = defaultdict(lambda: [0, 0])
    for o in ops:
        pol[o["policy"]][0] += 1
        pol[o["policy"]][1] += num(o, "killed")
    lines += ["## By policy", "", table(["policy", "operations", "killed", "per operation"],
              [[p, n, k, f"{k / n:.2f}"] for p, (n, k) in sorted(pol.items())]), ""]
    head = ["", "operations", "killed", "per op", "share", "officers sent", "down per op (incl. killed)",
            "by a suspect", "by a colleague", "bled out"]
    lines += ["## By situation type", "", table(["type"] + head[1:], by(ops, lambda o: o["type"], total_killed)), ""]
    lines += ["## By map", "", table(["map"] + head[1:], by(ops, lambda o: o["map_name"], total_killed)), ""]
    pairs = by(ops, lambda o: f'{o["type"]} · {o["map_name"]}', total_killed)
    top, acc = [], 0.0
    for r in pairs:
        if acc >= 60.0 and len(top) >= 3:
            break
        top.append(r)
        acc += float(r[4].rstrip("%"))
    lines += [f"## The pairs that make most of the deaths ({acc:.0f}% in {len(top)})", "",
              table(["type · map"] + head[1:], top), ""]
    wpath = folder / "weeks.csv"
    if wpath.exists():
        weeks = load(wpath)
        if policy:
            weeks = [w for w in weeks if w["policy"] == policy]
        g = defaultdict(lambda: {"snaps": 0, "ok": 0, "inj": 0, "acad": 0, "runs": set()})
        for w in weeks:
            d = g[w["policy"]]
            d["snaps"] += 1
            d["ok"] += 1 if num(w, "fit") >= FIT_FLOOR else 0
            d["inj"] += num(w, "injured")
            d["acad"] += num(w, "academy")
            d["runs"].add(w["seed"])
        rows = [[p, f'{100.0 * d["ok"] / d["snaps"]:.0f}%', f'{d["inj"] / len(d["runs"]):.1f}',
                 f'{d["acad"] / len(d["runs"]):.1f}'] for p, d in sorted(g.items())]
        lines += ["## The roster week by week", "",
                  f"Week-end snapshots with at least {FIT_FLOOR} fit (the 1.C exit wants 90% for cautious), "
                  "and officer-weeks spent injured and at the academy, per run.", "",
                  table(["policy", f"weeks >= {FIT_FLOOR} fit", "injury-weeks per run", "academy-weeks per run"], rows), ""]
    else:
        lines += ["*(no weeks.csv in this folder: a matrix from before 1.C)*", ""]
    apath = folder / "allies.csv"
    if apath.exists():
        allies = load(apath)
        if policy:
            allies = [a for a in allies if a["policy"] == policy]
        # last row per (run, ally) = the week-40 standing; ever-lost vs end-lost gives
        # the won-back count (P1.E2) — per policy
        last = {}
        ever_lost = defaultdict(set)
        for a in allies:
            k = (a["seed"], a["policy"], a["ally"])
            if k not in last or int(a["week"]) > int(last[k]["week"]):
                last[k] = a
            if a["lost"] == "1":
                ever_lost[(a["seed"], a["policy"])].add(a["ally"])
        pol = defaultdict(lambda: {"runs": set(), "lost_end": 0, "regained": 0})
        for (seed, pol_name, ally), row in last.items():
            pol[pol_name]["runs"].add(seed)
            if row["lost"] == "1":
                pol[pol_name]["lost_end"] += 1
        for key, lost_set in ever_lost.items():
            end_lost = {a for (s, p, a), row in last.items() if (s, p) == key and row["lost"] == "1"}
            pol[key[1]]["regained"] += len(lost_set - end_lost)
        rows = [[p, len(d["runs"]), f'{100.0 * d["lost_end"] / (4 * len(d["runs"])):.0f}%',
                 d["regained"]] for p, d in sorted(pol.items())]
        lines += ["## Allies (P1.E1/E2/E3)", "",
                  "From allies.csv: allies lost at week 40, and allies ever lost but not lost at the end "
                  "(won back — the P1.E2 exit wants at least one in 5 of 20 runs).", "",
                  table(["policy", "runs", "ally-losses at week 40", "won back"], rows), ""]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("folder", type=Path)
    ap.add_argument("--policy")
    ap.add_argument("--out", type=Path)
    a = ap.parse_args()
    if not (a.folder / "ops.csv").exists():
        print(f"no ops.csv in {a.folder}", file=sys.stderr)
        return 2
    text = report(a.folder, a.policy)
    print(text)
    if a.out:
        a.out.write_text(text + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
