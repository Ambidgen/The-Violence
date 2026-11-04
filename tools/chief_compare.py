#!/usr/bin/env python3
"""The Violence: does reading the briefing beat the one-click suggestion? (EA_TASKS P1.H1)

`tests/op_test.gd --chief=manual` plays the same board as `--chief=sensible`, with the
suggestion edited from what the briefing says (the hostage room cleared first, the far
door taken round the lookout, less-lethal on an entry with civilians in it). This runs both
chiefs on matched seeds, in parallel, and reports the pair.

    GODOT=/path/to/godot python3 tools/chief_compare.py --seeds=20 --jobs=4
    python3 tools/chief_compare.py --seeds=5 --first=20020 --out=tests/results/cycle-1H/shard-2
    python3 tools/chief_compare.py --merge tests/results/cycle-1H/shard-* --out=tests/results/cycle-1H

Exit (the gate the roadmap proposes, and the one the changelog cites): the manual chief is
ahead on the run score in at least `--threshold` (default 0.70) of the seeds played, and no
run failed. A seed the two chiefs tie on is not a win.

Cost: a 40-week op_test run is 10-15 minutes on two cores, so the 20-seed pair is about
7-10 hours in one go. Dispatch it as shards of five seeds (CI: `Run workflow` -> tier=chief,
first=1001/6006/11011/16016) and merge them, the same shape the balance matrix uses.
"""
import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CHIEFS = ["sensible", "manual"]


def run_one(godot, seed, chief, weeks, out_dir):
    """One 40-week run; returns its JSON (or a record saying why it failed)."""
    tmp = Path(tempfile.mkdtemp(prefix=f"chief-{seed}-{chief}-"))
    env = dict(os.environ)
    env["XDG_DATA_HOME"] = str(tmp / "data")   # no run may see another's save or legacy file
    js = tmp / f"run-{seed}-{chief}.json"
    cmd = [godot, "--headless", "--path", str(ROOT), "-s", "res://tests/op_test.gd", "--",
           f"--seed={seed}", f"--weeks={weeks}", f"--chief={chief}", f"--json={js}"]
    p = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=4 * 3600)
    errors = [ln for ln in (p.stdout + p.stderr).splitlines()
              if "SCRIPT ERROR" in ln or ln.startswith("ERROR:")]
    data = None
    if js.exists():
        try:
            data = json.loads(js.read_text())
        except json.JSONDecodeError:
            data = None
    if data is not None:
        data["_chief"] = chief
        (Path(out_dir) / f"run-{seed}-{chief}.json").write_text(json.dumps(data, indent=1))
    shutil.rmtree(tmp, ignore_errors=True)
    return {"seed": seed, "chief": chief, "run": data, "rc": p.returncode, "errors": errors[:4],
            "tail": (p.stdout or "").strip().splitlines()[-3:]}


def row(r):
    """The comparable numbers from one run."""
    d, out = r["run"], {"seed": r["seed"], "chief": r["chief"], "rc": r["rc"], "ran": False}
    if d is None:
        out["error"] = "no JSON written" + ((": " + r["errors"][0]) if r["errors"] else "")
        return out
    rec = d.get("record") or {}
    sc = (d.get("run_score") or {}).get("total")
    out.update({
        "ran": True,
        "run_score": int(sc) if sc is not None else int(d.get("mean_op_score", 0)),
        "mean_op_score": int(d.get("mean_op_score", 0)),
        "ops": int(d.get("ops", 0)),
        "kept": bool(((d.get("election") or {}).get("kept")) or False),
        "election": (d.get("election") or {}).get("winner"),
        "officers_killed": int(rec.get("officers_killed", 0)),
        "civilians_killed": int(rec.get("civ_killed", 0)) + int(rec.get("crowd_killed", 0)),
        "civilians_hit": int(rec.get("civ_hit", 0)),
        "findings": int(d.get("findings", 0)),
        "deficit_weeks": int(d.get("deficit_weeks", 0)),
        "hung": int(d.get("hung", 0)),
        "wall_s": round(int(d.get("wall_ms", 0)) / 1000.0, 1),
    })
    return out


def seeds_for(first, n):
    """op_test / rogue_balance seed numbering: 1001, 2002, 3003, ..."""
    return [first + i * 1001 for i in range(n)]


def write_report(rows, out_dir, weeks, threshold):
    pairs = {}
    for r in rows:
        pairs.setdefault(r["seed"], {})[r["chief"]] = r
    lines = ["# The planning test (EA_TASKS P1.H1)", "",
             f"`op_test --weeks={weeks}` on matched seeds: the one-click suggestion (`sensible`) "
             f"against the same schedule edited from the briefing (`manual`). "
             f"Gate: the manual chief is ahead on the run score in at least {int(threshold * 100)}% "
             "of the seeds played.", "",
             "| seed | score (manual) | score (sensible) | gap | ops | officers killed | "
             "civilians killed | findings | kept | wall s |",
             "|---|---|---|---|---|---|---|---|---|---|"]
    wins = ties = losses = 0
    bad = []
    gaps = []
    for sd in sorted(pairs):
        pair = pairs[sd]
        a, b = pair.get("manual"), pair.get("sensible")
        if not a or not b or not a["ran"] or not b["ran"] or a["rc"] or b["rc"]:
            bad.append(sd)
            lines.append(f"| {sd} | — | — | — | — | — | — | — | — | BROKEN |")
            continue
        gap = a["run_score"] - b["run_score"]
        gaps.append(gap)
        if gap > 0:
            wins += 1
        elif gap == 0:
            ties += 1
        else:
            losses += 1
        lines.append(f"| {sd} | {a['run_score']} | {b['run_score']} | {gap:+d} | {a['ops']} / {b['ops']} | "
                     f"{a['officers_killed']} / {b['officers_killed']} | "
                     f"{a['civilians_killed']} / {b['civilians_killed']} | "
                     f"{a['findings']} / {b['findings']} | "
                     f"{'y' if a['kept'] else 'n'} / {'y' if b['kept'] else 'n'} | "
                     f"{a['wall_s']} / {b['wall_s']} |")
    played = wins + ties + losses
    share = wins / played if played else 0.0
    mean_gap = sum(gaps) / len(gaps) if gaps else 0.0
    lines += ["", f"**Seeds played:** {played}" + (f" ({len(bad)} broken: {bad})" if bad else ""),
              f"**Manual ahead:** {wins} of {played} ({share * 100:.0f}%), ties {ties}, behind {losses}",
              f"**Mean gap:** {mean_gap:+.1f} run score",
              f"**Gate ({int(threshold * 100)}%):** " + ("MET" if played and not bad and share >= threshold else "MISSED")]
    Path(out_dir, "report.md").write_text("\n".join(lines) + "\n")
    summary = {"weeks": weeks, "threshold": threshold, "seeds": sorted(pairs), "played": played,
               "wins": wins, "ties": ties, "losses": losses, "share": round(share, 3),
               "mean_gap": round(mean_gap, 1), "broken": bad, "rows": rows,
               "gate": bool(played and not bad and share >= threshold)}
    Path(out_dir, "summary.json").write_text(json.dumps(summary, indent=1))
    return summary, "\n".join(lines)


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--seeds", type=int, default=20, help="seeds per chief (default 20)")
    ap.add_argument("--first", type=int, default=1001, help="first seed (1001, 6006, ... for a shard)")
    ap.add_argument("--weeks", type=int, default=40)
    ap.add_argument("--jobs", type=int, default=4)
    ap.add_argument("--threshold", type=float, default=0.70)
    ap.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    ap.add_argument("--out", default="", help="write report.md, summary.json and each run's JSON here")
    ap.add_argument("--merge", nargs="*", default=None,
                    help="join shard folders (each with run-<seed>-<chief>.json) instead of playing")
    args = ap.parse_args(argv)

    out_dir = Path(args.out or "build/chief").resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.merge is not None:
        rows = []
        for d in args.merge:
            for f in sorted(Path(d).glob("run-*-*.json")):
                try:
                    rows.append(row({"seed": int(f.stem.split("-")[1]), "chief": f.stem.split("-")[2],
                                     "run": json.loads(f.read_text()), "rc": 0, "errors": [], "tail": []}))
                except (ValueError, json.JSONDecodeError):
                    continue
        if not rows:
            print("chief_compare: no run-<seed>-<chief>.json in the shard folders", file=sys.stderr)
            return 2
        summary, text = write_report(rows, out_dir, args.weeks, args.threshold)
        print(text)
        return 0 if summary["gate"] else 1

    seeds = seeds_for(args.first, args.seeds)
    jobs = [(sd, ch) for sd in seeds for ch in CHIEFS]
    print(f"chief_compare: {len(jobs)} runs ({len(seeds)} seeds x {len(CHIEFS)} chiefs), "
          f"{args.jobs} at a time, {args.weeks} weeks each", flush=True)
    results = []
    with ThreadPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        futs = {pool.submit(run_one, args.godot, sd, ch, args.weeks, out_dir): (sd, ch) for sd, ch in jobs}
        for f in futs:
            r = f.result()
            results.append(r)
            wait = "ran" if r["run"] is not None else "BROKEN"
            print(f"  seed {r['seed']} {r['chief']:<8} {wait}", flush=True)
    rows = [row(r) for r in results]
    summary, text = write_report(rows, out_dir, args.weeks, args.threshold)
    print()
    print(text)
    return 0 if summary["gate"] else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
