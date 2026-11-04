#!/usr/bin/env python3
"""Summarize JSONL from tests/test_range_study.gd without third-party packages.

Example:
  python3 tools/analyze_test_range_study.py tests/results/test-range-2026-10-27/*.jsonl \
    --output docs/TEST_RANGE_PLAYTEST_DETAILS_2026-10-27.md

The on/off comparisons are paired by map and seed. A positive owner-win delta means
that the side whose configuration was changed won more often; draws are retained in
the denominator. This is a descriptive exploratory screen, not a significance test.
"""
from __future__ import annotations

import argparse
import json
import math
import re
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]
LEVELS = ("untrained", "militia", "patrol", "regular", "police", "sof")


def load_rows(paths: list[Path]) -> list[dict]:
    rows = []
    seen = set()
    for path in paths:
        with path.open(encoding="utf-8") as source:
            for number, line in enumerate(source, 1):
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                    key = (row["group"], row["case"], int(row["map"]), int(row["seed"]))
                    if key in seen:
                        raise ValueError(f"duplicate match {key}")
                    if row["winner"] not in (0, 1, 2):
                        raise ValueError(f"invalid winner {row['winner']}")
                    for side in ("a", "b"):
                        if not 0 <= row[f"{side}_down"] <= len(row[side]):
                            raise ValueError(f"invalid {side} casualty count")
                        if not 0 <= row[f"{side}_dead"] <= row[f"{side}_down"]:
                            raise ValueError(f"invalid {side} death count")
                    if not math.isfinite(row["seconds"]) or row["seconds"] < 0:
                        raise ValueError("invalid duration")
                except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
                    raise ValueError(f"{path}:{number}: {exc}") from exc
                seen.add(key)
                rows.append(row)
    if not rows:
        raise ValueError("no match records")
    return rows


def summarize(rows: list[dict]) -> dict:
    if not rows:
        raise ValueError("empty case")
    n = len(rows)
    counts = Counter(row["winner"] for row in rows)
    return {
        "n": n, "a": counts[0], "b": counts[1], "draw": counts[2],
        "timeouts": sum(bool(r["timeout"]) for r in rows),
        "seconds": mean(r["seconds"] for r in rows),
        "a_down": mean(r["a_down"] for r in rows),
        "b_down": mean(r["b_down"] for r in rows),
        "friendly_hits": sum(r["friendly_hits"] for r in rows),
    }


def wilson(wins: int, n: int, z: float = 1.96) -> tuple[float, float]:
    if not 0 <= wins <= n or n < 1:
        raise ValueError("invalid binomial data")
    p = wins / n
    den = 1 + z * z / n
    center = (p + z * z / (2 * n)) / den
    radius = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return max(0.0, center - radius), min(1.0, center + radius)


def paired(variant: list[dict], baseline: list[dict], side: str) -> dict:
    if side not in ("A", "B"):
        raise ValueError("invalid side")
    index = {(r["map"], r["seed"]): r for r in baseline}
    keys = [(r["map"], r["seed"]) for r in variant]
    if not variant or len(keys) != len(set(keys)) or any(k not in index for k in keys):
        raise ValueError("a variant is missing its corresponding baseline map/seed")
    target, down_field, dead_field = (0, "a_down", "a_dead") if side == "A" else (1, "b_down", "b_dead")
    diffs = [(int(r["winner"] == target) - int(index[k]["winner"] == target))
             for r, k in zip(variant, keys)]
    n = len(variant)
    return {
        "n": n,
        "base_wins": sum(index[k]["winner"] == target for k in keys),
        "wins": sum(r["winner"] == target for r in variant),
        "delta_pp": 100.0 * sum(diffs) / n,
        "gained": diffs.count(1), "lost": diffs.count(-1),
        "down_delta": mean(r[down_field] - index[k][down_field] for r, k in zip(variant, keys)),
        "dead_delta": mean(r[dead_field] - index[k][dead_field] for r, k in zip(variant, keys)),
        "active_matches": sum(r.get("bad_active_operators", 0) > 0 for r in variant),
        "active_operators": sum(r.get("bad_active_operators", 0) for r in variant),
    }


def habit_names() -> dict[str, str]:
    source = (ROOT / "scripts/data/habits.gd").read_text(encoding="utf-8")
    return dict(re.findall(r'\{"id": "((?:PF|GD|ED|WD|HD|BH)\d\d)", "name": "([^"]+)"', source))


def group_rows(rows: list[dict]) -> dict[tuple[str, str], list[dict]]:
    result: dict[tuple[str, str], list[dict]] = defaultdict(list)
    for row in rows:
        result[(row["group"], row["case"])].append(row)
    return result


def report(rows: list[dict], paths: list[Path]) -> str:
    grouped = group_rows(rows)
    names = habit_names()
    lines = [
        "# Test-range playtest — complete results", "",
        "Generated by `tools/analyze_test_range_study.py` from the per-match JSONL files "
        "listed below. The interpretive report is [TEST_RANGE_PLAYTEST_2026-10-27.md]"
        "(TEST_RANGE_PLAYTEST_2026-10-27.md).", "",
        "**Reading the tables:** A assaults; B holds. `A/B/D` gives counts of attacker "
        "wins, defender wins and draws, including timeouts. Casualties are operators down "
        "or dead, not deaths alone. Win-rate differences are **percentage points**, "
        "paired on map and seed, for the side whose configuration changed. "
        "G/L counts pairs in which that side gained/lost a win. Δ own down and dead are "
        "the paired changes in the changed side's average casualties/deaths per fight; deaths are included in down. "
        "These are tactical-match deaths; police-operation post-fight casualty settlement is not enabled. "
        "A zero difference does not prove a habit or item is inert. See the main report "
        "for sample-size, activation and multiple-comparison limitations.", "",
        "Input records: " + ", ".join(f"`{p.as_posix()}`" for p in paths) + ".", "",
        f"Total: **{len(rows)} matches** across {len(grouped)} case labels; "
        f"{sum(bool(r['timeout']) for r in rows)} reached the map's normal time limit.", "",
    ]
    # Matrix core excludes the separately sampled plaza: otherwise the denominators
    # differ between cells and the apparent cross-preset comparison is confounded.
    matrix = [r for r in rows if r["group"] == "matrix" and r["map"] != 11]
    by_matrix = group_rows(matrix)
    if matrix:
        lines += ["## Full preset matrix — attacker win share", "",
                  "Core maps only (00, 03, 04); each cell is attacker wins / matches. "
                  "All six presets include their real test-range equipment, experience and preset habits.", "",
                  "| Attacker \\ defender | " + " | ".join(LEVELS) + " |",
                  "| --- |" + " ---: |" * len(LEVELS)]
        for a in LEVELS:
            cells = []
            for b in LEVELS:
                cell = by_matrix.get(("matrix", f"{a}_vs_{b}"), [])
                if not cell:
                    cells.append("—")
                else:
                    s = summarize(cell)
                    cells.append(f"{100*s['a']/s['n']:.0f}% ({s['a']}/{s['n']})")
            lines.append(f"| {a} | " + " | ".join(cells) + " |")
        lines += ["", "### Matrix outcomes and casualties", ""]
        _case_table(lines, by_matrix, "matrix")
        plaza = [r for r in rows if r["group"] == "matrix" and r["map"] == 11]
        if plaza:
            lines += ["", "### Supplemental plaza cases", "",
                      "One seed per cell, listed separately from the core matrix.", ""]
            _case_table(lines, group_rows(plaza), "matrix")
    for group, heading in (("size", "Team sizes — regular versus regular"),
                           ("mixed", "Mixed preset compositions")):
        if any(g == group for g, _ in grouped):
            lines += ["", "## " + heading, ""]
            if group == "mixed":
                lines += ["The plus-separated lineup is in slot order, not a sorted count; "
                          "slots set starting positions, while the AI selects leaders and entry order dynamically. "
                          "The other side is five regulars.", ""]
            _case_table(lines, grouped, group)
    for group, heading in (("habits", "SOF versus SOF — individual habits"),
                           ("equipment", "SOF versus SOF — individual equipment changes")):
        base = grouped.get((group, "baseline"), [])
        if not base:
            continue
        s = summarize(base)
        lo, hi = wilson(s["a"], s["n"])
        lines += ["", "## " + heading, "",
                  f"Baseline: A/B/draw {s['a']}/{s['b']}/{s['draw']} "
                  f"across {s['n']} fights; attacker win {100*s['a']/s['n']:.1f}% "
                  f"(Wilson 95% interval {100*lo:.1f}–{100*hi:.1f}%). "
                  "Both sides have all 60 good habits, no bad habits and the SOF preset kit.", ""]
        lines += ["| Change | Side | n | Owner wins | Δ win pp | G/L | Δ own down | Δ own dead | Active fights / operators |",
                  "| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
        for (g, case), cell in grouped.items():
            if g != group or case == "baseline":
                continue
            change = cell[0]["change"]
            side = change["side"]
            p = paired(cell, base, side)
            hid = change.get("habit", "")
            label = case
            if hid in names:
                label += " — " + names[hid]
            active = (f"{p['active_matches']}/{p['n']} / {p['active_operators']}"
                      if change.get("mode") == "bad_on" else "—")
            lines.append(f"| {label} | {side} | {p['n']} | {p['wins']}/{p['n']} | "
                         f"{p['delta_pp']:+.1f} | {p['gained']}/{p['lost']} | "
                         f"{p['down_delta']:+.2f} | {p['dead_delta']:+.2f} | {active} |")
        if group == "equipment":
            lines += ["", "### Equipment exposure/usage in each variant", "",
                      "Consumables are counted when spent by the changed side, not merely carried; "
                      "plates and SOF helmets are counted as used when they actually stop a hit. "
                      "Shield stops are the entire match total. Medical kits are not consumed by treatment, "
                      "so consumption is not a measure of medical exposure; compare deaths instead.", "",
                      "| Change | Side | n | Flashbangs used | Plates used | SOF helmets spent | Shield stops |",
                      "| --- | --- | ---: | ---: | ---: | ---: | ---: |"]
            for (g, case), cell in grouped.items():
                if g != group:
                    continue
                side = cell[0]["change"].get("side", "A")
                field = side.lower()
                lines.append(f"| {case} | {side} | {len(cell)} | "
                             f"{sum(r[f'{field}_gear_used'].get('flashbang', 0) for r in cell)} | "
                             f"{sum(r[f'{field}_plates_used'] for r in cell)} | "
                             f"{sum(r[f'{field}_helmets_spent'] for r in cell)} | "
                             f"{sum(r['shield_stops'] for r in cell)} |")
    return "\n".join(lines) + "\n"


def _case_table(lines: list[str], grouped: dict, group: str) -> None:
    lines += ["| Case | n | A/B/D | Timeouts | A down | B down | Mean seconds | Friendly hits |",
              "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |"]
    for (g, case), cell in grouped.items():
        if g != group:
            continue
        s = summarize(cell)
        lines.append(f"| {case} | {s['n']} | {s['a']}/{s['b']}/{s['draw']} | {s['timeouts']} | "
                     f"{s['a_down']:.2f} | {s['b_down']:.2f} | {s['seconds']:.1f} | {s['friendly_hits']} |")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", type=Path, nargs="+")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    rows = load_rows(args.files)
    text = report(rows, args.files)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(text, encoding="utf-8")
    print(f"Wrote {args.output} from {len(rows)} matches")


if __name__ == "__main__":
    main()
