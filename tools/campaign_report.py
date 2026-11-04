#!/usr/bin/env python3
"""The Violence: the campaign playtest table from op_test runs (EA_TASKS P0.B2).

Reads `op_test.gd --json=...` files (preferred) or plain op_test logs (the text the
harness prints; used for older runs) and prints one column per run:

    python3 tools/campaign_report.py runs/*.json            # markdown to stdout
    python3 tools/campaign_report.py a.log b.log --csv out.csv
    python3 tools/campaign_report.py runs/*.json --check     # exit 1 if any run is broken

Week snapshots are the line op_test prints before the week ends (account before
payroll), so "weeks below $0" counts those lines - the same figure the 28 Oct playtest
reports. --check fails a run that hung an operation or never reached its election.
"""
import argparse
import csv
import json
import re
import sys
from pathlib import Path

ALLIES = ["council", "union", "coalition", "da"]
ALLY_CODES = {"CL": "council", "UN": "union", "CC": "coalition", "DA": "da"}
ALLY_NAMES = {"council": "Duff", "union": "Rourke", "coalition": "Mbeki-Shaw", "da": "Varga"}
LOST_NAMES = {"Marguerite Duff": "council", "Tommy Rourke": "union", "Rev. Alma Mbeki-Shaw": "coalition", "Paul Varga": "da"}
CANDIDATES = {"kettering": "Kettering", "okonjo": "Okonjo-Vale", "pell": "Pell"}
MARK_WEEKS = [1, 5, 10, 20, 30, 40]

WEEK_RE = re.compile(r"^  week (\d+): account \$(-?\d+), morale (\d+), (\d+) open cases, (\d+) fit\s+\|\s+trust (\d+)\s+allies (.*?)\s+polls K (\d+) O (\d+) P (\d+)")
ALLY_RE = re.compile(r"(CL|UN|CC|DA)(\d+)(x?)")
ELECTION_RE = re.compile(r"^ELECTION: (.+?)\s+\(K (\d+)%, O (\d+)%, P (\d+)%\)\s+kept: (true|false)")
FORTY_RE = re.compile(r"(\d+) operations succeeded, (\d+) failed, (\d+) situations went unattended\. (\d+) officers killed")
PEROP_RE = re.compile(r"^officers per operation: ([\d.]+) killed, ([\d.]+) down \((\d+) operations\)")
TOTALS_RE = re.compile(r"^TOTALS chief=(\S+) train=(\S+): mean score (-?\d+), (\d+) findings, deficit weeks (\d+)")
SEED_RE = re.compile(r"seed[=_-]?(\d+)", re.I)


def from_json(path: Path) -> dict:
    d = json.loads(path.read_text())
    weeks = []
    for w in d.get("weeks", []):
        weeks.append({"week": w["week"], "balance": w["balance"], "fit": w["fit"], "morale": w["morale"],
                      "allies": {a: (w["allies"][a]["standing"], bool(w["allies"][a]["lost"])) for a in ALLIES},
                      "lines": w.get("lines", [])})
    rec = d.get("record", {})
    el = d.get("election") or {}
    return {
        "name": path.stem, "seed": d.get("seed"), "policy": _policy(d.get("chief"), d.get("hire"), d.get("train"), d.get("rogue")),
        "weeks": weeks, "won": rec.get("successes"), "failed": rec.get("failures"), "unattended": rec.get("unattended"),
        "killed": rec.get("officers_killed"), "civ_killed": rec.get("civ_killed"), "crowd_killed": rec.get("crowd_killed"),
        "killed_per_op": d.get("officers_killed_per_op"), "down_per_op": d.get("officers_down_per_op"), "ops": d.get("ops"),
        "findings": d.get("findings"), "lawsuits": rec.get("settled"), "stories": rec.get("stories"),
        "winner": CANDIDATES.get(el.get("winner", ""), el.get("winner")), "kept": el.get("kept"),
        "votes": el.get("votes"), "run_score": (d.get("run_score") or {}).get("total"),
        "hung": d.get("hung", 0), "weeks_asked": d.get("weeks_asked"),
    }


def from_log(path: Path) -> dict:
    r = {"name": path.stem, "seed": None, "policy": "?", "weeks": [], "hung": 0, "weeks_asked": None,
         "won": None, "failed": None, "unattended": None, "killed": None, "civ_killed": None, "crowd_killed": None,
         "killed_per_op": None, "down_per_op": None, "ops": None, "findings": None, "lawsuits": None, "stories": None,
         "winner": None, "kept": None, "votes": None, "run_score": None}
    m = SEED_RE.search(path.name)
    if m:
        r["seed"] = int(m.group(1))
    for raw in path.read_text(errors="ignore").splitlines():
        line = re.sub(r"\x1b\[[0-9;]*m", "", raw)
        m = WEEK_RE.match(line)
        if m:
            allies = {}
            for code, standing, lost in ALLY_RE.findall(m.group(7)):
                allies[ALLY_CODES[code]] = (int(standing), lost == "x")
            r["weeks"].append({"week": int(m.group(1)), "balance": int(m.group(2)), "morale": int(m.group(3)),
                               "fit": int(m.group(5)), "allies": allies, "lines": []})
            continue
        if line.startswith("  week: ") and r["weeks"]:
            r["weeks"][-1]["lines"].append(line[len("  week: "):])
            continue
        if line.startswith("HUNG:"):
            r["hung"] += 1
        m = ELECTION_RE.match(line)
        if m:
            r["winner"] = {"Royce Kettering": "Kettering", "Dana Okonjo-Vale": "Okonjo-Vale", "Gordon Pell": "Pell"}.get(m.group(1), m.group(1))
            r["kept"] = m.group(5) == "true"
            r["votes"] = {"kettering": int(m.group(2)), "okonjo": int(m.group(3)), "pell": int(m.group(4))}
        m = FORTY_RE.search(line)
        if m:
            r["won"], r["failed"], r["unattended"], r["killed"] = (int(x) for x in m.groups())
            m2 = re.search(r"(\d+) stories reached the papers; (\d+) lawsuits settled", line)
            if m2:
                r["stories"], r["lawsuits"] = int(m2.group(1)), int(m2.group(2))
        m = PEROP_RE.match(line)
        if m:
            r["killed_per_op"], r["down_per_op"], r["ops"] = float(m.group(1)), float(m.group(2)), int(m.group(3))
        m = TOTALS_RE.match(line)
        if m:
            r["findings"] = int(m.group(4))
            r["policy"] = f"chief={m.group(1)} train={m.group(2)}"
    return r


def _policy(chief, hire, train, rogue) -> str:
    bits = [str(chief or "all")]
    if hire:
        bits.append("hire")
    if train:
        bits.append("train")
    if rogue:
        bits.append("run")
    return "+".join(bits)


def derive(r: dict) -> dict:
    """The comparable numbers: roster, money and allies over the run."""
    w = r["weeks"]
    out = {}
    if not w:
        return out
    fits = [x["fit"] for x in w]
    out["min_fit"] = min(fits)
    out["min_fit_week"] = next(x["week"] for x in w if x["fit"] == out["min_fit"])
    out["weeks_fit_below_12"] = sum(1 for f in fits if f < 12)
    out["fit_marks"] = {x["week"]: x["fit"] for x in w if x["week"] in MARK_WEEKS}
    bal = [x["balance"] for x in w]
    out["weeks_below_zero"] = sum(1 for b in bal if b < 0)
    out["weeks_below_zero_1_12"] = sum(1 for x in w if x["week"] <= 12 and x["balance"] < 0)
    out["first_week_below_zero"] = next((x["week"] for x in w if x["balance"] < 0), None)
    out["balance_min"], out["balance_max"], out["balance_end"] = min(bal), max(bal), bal[-1]
    out["acct_marks"] = {x["week"]: x["balance"] for x in w if x["week"] in MARK_WEEKS}
    first_lost, regained = {}, 0
    for x in w:
        for ln in x["lines"]:
            if ln.startswith("LOST:"):
                for nm, a in LOST_NAMES.items():
                    if nm in ln and a not in first_lost:
                        first_lost[a] = x["week"]
            if ln.startswith("Won back"):
                regained += 1
    # an ally can also cross the line without the message (marked x in the snapshot)
    for x in w:
        for a, (_, lost) in x["allies"].items():
            if lost and a not in first_lost:
                first_lost[a] = x["week"]
    out["allies_first_lost"] = first_lost
    end = w[-1]["allies"]
    out["allies_lost_end"] = sum(1 for a in ALLIES if end.get(a, (0, False))[1])
    out["allies_regained"] = regained
    return out


def _money(n) -> str:
    if n is None:
        return "—"
    s = f"${abs(n) / 1000:.1f}K" if abs(n) >= 1000 else f"${abs(n)}"
    return ("−" if n < 0 else "") + s


def table(runs: list) -> str:
    cols = []
    for r in runs:
        d = derive(r)
        r["_d"] = d
        cols.append(r)
    head = "| | " + " | ".join(f"{r['name']}" for r in cols) + " |"
    sep = "|---|" + "---|" * len(cols)
    rows = []

    def row(label, f):
        rows.append(f"| {label} | " + " | ".join(f(r) for r in cols) + " |")

    row("Seed / policy", lambda r: f"{r['seed']} · {r['policy']}")
    row("Election", lambda r: "—" if r["winner"] is None else f"{r['winner']} {max((r['votes'] or {'x': 0}).values()):.0f}% — chief {'kept' if r['kept'] else 'fired'}")
    row("Operations won / failed", lambda r: f"{r['won']} / {r['failed']}")
    row("Situations left unattended", lambda r: str(r["unattended"]))
    row("Officers killed", lambda r: str(r["killed"]))
    row("Per operation: killed / down", lambda r: "—" if r["killed_per_op"] is None else f"{r['killed_per_op']:.2f} / {r['down_per_op']:.2f}")
    row("Findings / lawsuits / stories", lambda r: f"{r['findings']} / {r['lawsuits']} / {r['stories']}")
    row("Fit officers (wk " + ", ".join(map(str, MARK_WEEKS)) + ")", lambda r: " → ".join(str(r["_d"]["fit_marks"].get(k, "·")) for k in MARK_WEEKS))
    row("Lowest fit (week)", lambda r: f"{r['_d']['min_fit']} (wk {r['_d']['min_fit_week']})")
    row("Weeks with fewer than 12 fit", lambda r: f"{r['_d']['weeks_fit_below_12']} of {len(r['weeks'])}")
    row("Account (wk " + ", ".join(map(str, MARK_WEEKS)) + ")", lambda r: " → ".join(_money(r["_d"]["acct_marks"].get(k)) for k in MARK_WEEKS))
    row("Weeks below $0 (wk 1–12)", lambda r: f"{r['_d']['weeks_below_zero']} of {len(r['weeks'])} ({r['_d']['weeks_below_zero_1_12']})")
    row("Allies lost at the end / first losses", lambda r: f"{r['_d']['allies_lost_end']} of 4 · " + (", ".join(f"{ALLY_NAMES[a]} {wk}" for a, wk in sorted(r['_d']['allies_first_lost'].items(), key=lambda kv: kv[1])) or "none"))
    row("Allies won back", lambda r: str(r["_d"]["allies_regained"]))
    row("Run score", lambda r: "—" if r["run_score"] is None else str(r["run_score"]))
    return "\n".join([head, sep] + rows)


def broken(r: dict) -> list:
    why = []
    if r.get("hung"):
        why.append(f"{r['hung']} operation(s) hung")
    asked = r.get("weeks_asked")
    if asked and asked >= 40 and r.get("winner") is None:
        why.append("never reached the election")
    if not r["weeks"]:
        why.append("no week snapshots")
    return why


def main(argv=None) -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("runs", nargs="+", type=Path)
    ap.add_argument("--csv", type=Path, help="also write one row per run")
    ap.add_argument("--check", action="store_true", help="exit 1 if a run hung or never held its election")
    a = ap.parse_args(argv)
    runs = [from_json(p) if p.suffix == ".json" else from_log(p) for p in a.runs]
    print(table(runs))
    if a.csv:
        with a.csv.open("w", newline="") as f:
            wr = csv.writer(f, lineterminator="\n")
            keys = ["name", "seed", "policy", "winner", "kept", "won", "failed", "unattended", "killed", "killed_per_op",
                    "down_per_op", "findings", "lawsuits", "stories", "run_score"]
            dkeys = ["min_fit", "min_fit_week", "weeks_fit_below_12", "weeks_below_zero", "weeks_below_zero_1_12",
                     "first_week_below_zero", "balance_min", "balance_max", "balance_end", "allies_lost_end", "allies_regained"]
            wr.writerow(keys + dkeys)
            for r in runs:
                d = r.get("_d") or derive(r)
                wr.writerow([r.get(k) for k in keys] + [d.get(k) for k in dkeys])
    bad = [(r["name"], broken(r)) for r in runs if broken(r)]
    for name, why in bad:
        print(f"\nBROKEN {name}: {'; '.join(why)}", file=sys.stderr)
    return 1 if (a.check and bad) else 0


if __name__ == "__main__":
    sys.exit(main())
