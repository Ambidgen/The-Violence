#!/usr/bin/env python3
"""Aggregate the per-match JSON dumps from tests/playtest.gd --dump-json=<dir>.

Tier 0 #1 said: "then one small Python aggregator". This is it. It turns a dump
directory into the numbers the analysis needs to settle its hypotheses:

  * win rates and durations per cell                        (H2's raw material)
  * recognition times and recognition distances             (H1's dominant term)
  * acquisition ("on target after") times                   (attention boost, H1)
  * plate stops vs wounds vs downs                         (H2: plates vs habits)
  * friendly fire and stray shots                          (suppression behaviour)
  * stress and suppression left standing at the end         (does anything reset?)

Usage:
  python3 tools/aggregate_playtest.py /tmp/tv
  python3 tools/aggregate_playtest.py /tmp/tv --cell="atk 3"
  python3 tools/aggregate_playtest.py /tmp/tv --csv
"""

import argparse
import csv
import json
import re
import sys
from pathlib import Path

RE_REC = re.compile(r"recognizes [^:]+: ([0-9.]+) m, (-?[0-9]+) deg")
RE_ACQ = re.compile(r"on target [^ ]+ after ([0-9.]+) s")


def one_match(path: Path) -> dict:
    d = json.loads(path.read_text())
    recs, rec_d, acqs = [], [], []
    plates = wounds = downs = kills = strays = 0
    for line in d.get("log", []):
        text = line.get("text", "")
        m = RE_REC.search(text)
        if m:
            recs.append(line["t"])
            rec_d.append(float(m.group(1)))
        m = RE_ACQ.search(text)
        if m:
            acqs.append(float(m.group(1)))
        if "plate stops" in text:
            plates += 1
        elif "wounded (" in text:
            wounds += 1
        if "DOWN (" in text or "DOWN," in text:
            downs += 1
        if "KILLED (" in text or "KILLED," in text:
            downs += 1
            kills += 1
        if "stray shot" in text:
            strays += 1
    ops = d.get("ops", [])
    cleared = sum(len(tm.get("cleared", [])) for tm in d.get("teams", []))
    return {
        "cell": d.get("cell", path.stem),
        "t": d.get("t", 0.0),
        "winner": d.get("winner", -1),
        "stat": d.get("stat", {}),
        "n_ops": len(ops),
        "down_end": sum(1 for o in ops if o.get("state") != "alive"),
        "stress": sum(o.get("stress", 0.0) for o in ops) / max(1, len(ops)),
        "suppress": sum(o.get("suppress", 0.0) for o in ops) / max(1, len(ops)),
        "shots": sum(o.get("shots", 0) for o in ops),
        "hits": sum(o.get("hits", 0) for o in ops),
        "recs": recs,
        "rec_d": rec_d,
        "acqs": acqs,
        "plates": plates,
        "wounds": wounds,
        "downs": downs,
        "kills": kills,
        "strays": strays,
        "cleared": cleared,
    }


def mean(xs):
    return sum(xs) / len(xs) if xs else 0.0


def aggregate(rows: list) -> dict:
    n = len(rows)
    wins = [sum(1 for r in rows if r["winner"] == i) for i in range(3)]
    recs = [t for r in rows for t in r["recs"]]
    rec_d = [x for r in rows for x in r["rec_d"]]
    acqs = [x for r in rows for x in r["acqs"]]
    return {
        "matches": n,
        "a_win%": 100.0 * wins[0] / n,
        "b_win%": 100.0 * wins[1] / n,
        "draw%": 100.0 * wins[2] / n,
        "mean_s": mean([r["t"] for r in rows]),
        "first_rec_s": mean([min(r["recs"]) if r["recs"] else 0.0 for r in rows]),
        "recs": mean([len(r["recs"]) for r in rows]),
        "rec_m": mean(rec_d),
        "acq_s": mean(acqs),
        "shots": mean([r["shots"] for r in rows]),
        "hits": mean([r["hits"] for r in rows]),
        "hit%": 100.0 * sum(r["hits"] for r in rows) / max(1, sum(r["shots"] for r in rows)),
        "plates": mean([r["plates"] for r in rows]),
        "wounds": mean([r["wounds"] for r in rows]),
        "downs": mean([r["downs"] for r in rows]),
        "strays": mean([r["strays"] for r in rows]),
        "cleared": mean([r["cleared"] for r in rows]),
        "stress": mean([r["stress"] for r in rows]),
        "suppress": mean([r["suppress"] for r in rows]),
    }


COLUMNS = [
    "cell", "matches", "a_win%", "b_win%", "draw%", "mean_s", "first_rec_s",
    "recs", "rec_m", "acq_s", "shots", "hits", "hit%", "plates", "wounds",
    "downs", "strays", "cleared", "stress", "suppress",
]


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dir", help="directory written by playtest --dump-json=")
    ap.add_argument("--cell", default="", help="only cells whose name contains this")
    ap.add_argument("--csv", action="store_true", help="machine-readable output")
    args = ap.parse_args()

    files = sorted(Path(args.dir).glob("m_*.json"))
    if not files:
        print(f"no m_*.json in {args.dir}", file=sys.stderr)
        return 1
    rows = [one_match(f) for f in files]
    if args.cell:
        rows = [r for r in rows if args.cell in r["cell"]]
        if not rows:
            print(f"no cell matching {args.cell!r}", file=sys.stderr)
            return 1

    by_cell: dict = {}
    for r in rows:
        by_cell.setdefault(r["cell"], []).append(r)
    table = [(name, aggregate(rs)) for name, rs in sorted(by_cell.items())]

    if args.csv:
        w = csv.writer(sys.stdout)
        w.writerow(COLUMNS)
        for name, ag in table:
            w.writerow([name] + [ag[c] for c in COLUMNS[1:]])
        return 0

    for name, ag in table:
        print(f"\n== {name}")
        for c in COLUMNS[1:]:
            v = ag[c]
            print(f"   {c:>10}: {v:8.2f}" if isinstance(v, float) else f"   {c:>10}: {v}")
    if len(table) > 1:
        print(f"\n== ALL ({len(rows)} matches)")
        for c in COLUMNS[1:]:
            v = aggregate(rows)[c]
            print(f"   {c:>10}: {v:8.2f}" if isinstance(v, float) else f"   {c:>10}: {v}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
