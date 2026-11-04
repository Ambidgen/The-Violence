#!/usr/bin/env python3
"""Verify the exact planned test-range study coverage and scenario metadata.

Screen and holdout are separate statistical datasets, even where case labels match:
  python3 tools/audit_test_range_coverage.py screen tests/results/test-range-2026-10-27/screen-*.jsonl
  python3 tools/audit_test_range_coverage.py holdout tests/results/test-range-2026-10-27/holdout-*.jsonl
  python3 tools/audit_test_range_coverage.py debug tests/results/test-range-debug-2026-10-27/*.jsonl
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

# Also works when launched as `python3 tools/audit_test_range_coverage.py`.
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tools.analyze_test_range_study import LEVELS, habit_names, load_rows  # noqa: E402

MIXES = (
    ("sof", "militia", "militia", "militia", "militia"),
    ("militia", "sof", "sof", "sof", "sof"),
    ("sof", "sof", "militia", "militia", "militia"),
    ("police", "police", "patrol", "patrol", "patrol"),
    ("regular", "regular", "regular", "regular", "regular"),
)
SIZES = ((1, 1), (2, 2), (3, 3), (5, 5), (8, 8), (10, 10),
         (2, 5), (5, 2), (3, 5), (5, 3), (5, 8), (8, 5), (5, 10), (10, 5))
GEAR = ("no_plates", "vest", "no_helmet", "no_flashbang", "no_medkit", "no_gear",
        "carbine", "smg", "shotgun", "battle_rifle", "irons", "magnified", "shield_point")
PLAZA = ("untrained_vs_untrained", "militia_vs_sof", "regular_vs_regular", "regular_vs_police",
         "police_vs_regular", "sof_vs_militia", "sof_vs_sof")
HOLDOUT_HABITS = ("baseline", "no_good:A", "no_good:B", "good_off:PF04:A", "good_off:GD02:A",
                  "good_off:HD07:B", "bad_on:BH11:A", "bad_on:BH27:B", "bad_on:BH06:A")
HOLDOUT_GEAR = ("baseline", "kit:no_plates:A", "kit:no_helmet:A", "kit:no_flashbang:A", "kit:shield_point:A")
DEBUG_CASES = {
    "matrix": ("untrained_vs_regular", "militia_vs_patrol", "patrol_vs_militia", "regular_vs_untrained",
               "regular_vs_regular", "police_vs_sof", "sof_vs_police", "sof_vs_sof"),
    "size": ("1v1", "3v3", "5v5", "10v10", "2v5", "5v2"),
    "mixed": ("A_sof+militia+militia+militia+militia", "B_sof+militia+militia+militia+militia"),
    "habits": ("baseline", "good_off:PF04:A", "good_off:GD02:A", "bad_on:BH06:A", "bad_on:BH11:A", "bad_on:BH26:B"),
    "equipment": ("baseline", "kit:no_plates:A", "kit:battle_rifle:A", "kit:shield_point:A", "kit:shield_point:B"),
}


def cases() -> dict[tuple[str, str], tuple[list[str], list[str], dict]]:
    result = {}

    def add(group: str, case: str, a: list[str], b: list[str], change: dict | None = None) -> None:
        result[(group, case)] = (a, b, change or {})

    for a in LEVELS:
        for b in LEVELS:
            add("matrix", f"{a}_vs_{b}", [a] * 5, [b] * 5)
    for a, b in SIZES:
        add("size", f"{a}v{b}", ["regular"] * a, ["regular"] * b)
    for mix in MIXES:
        name = "+".join(mix)
        add("mixed", "A_" + name, list(mix), ["regular"] * 5)
        add("mixed", "B_" + name, ["regular"] * 5, list(mix))

    names = habit_names()
    good = [hid for hid in names if not hid.startswith("BH")]
    bad = [hid for hid in names if hid.startswith("BH")]
    if len(good) != 60 or len(bad) != 27:
        raise ValueError("The recorded study plan assumes 60 good and 27 bad habits")
    for group in ("habits", "equipment"):
        add(group, "baseline", ["sof"] * 3, ["sof"] * 3, {"mode": "baseline"})
    for side in ("A", "B"):
        for mode in ("no_good", "all_bad"):
            add("habits", f"{mode}:{side}", ["sof"] * 3, ["sof"] * 3, {"side": side, "mode": mode})
        for hid in good:
            if side == "A" and hid.startswith("HD"):
                continue
            add("habits", f"good_off:{hid}:{side}", ["sof"] * 3, ["sof"] * 3,
                {"side": side, "mode": "good_off", "habit": hid})
        for hid in bad:
            if side == "A" and hid in {f"BH{i:02d}" for i in range(21, 28)}:
                continue
            add("habits", f"bad_on:{hid}:{side}", ["sof"] * 3, ["sof"] * 3,
                {"side": side, "mode": "bad_on", "habit": hid})
        for variant in GEAR:
            add("equipment", f"kit:{variant}:{side}", ["sof"] * 3, ["sof"] * 3,
                {"side": side, "mode": "kit", "variant": variant})
    return result


def expected_plan(plan: str) -> dict[tuple[str, str, int, int], tuple[list[str], list[str], dict]]:
    result = {}
    for (group, case), metadata in cases().items():
        if plan == "screen":
            maps = (0, 3, 4) if group in ("matrix", "size", "mixed") else (0, 3, 11)
            repetitions = range(2)
            if group == "matrix" and case in PLAZA:
                key = (group, case, 11, 710001 + 1000 * 11)
                result[key] = metadata
        elif plan == "holdout":
            if group == "habits" and case not in HOLDOUT_HABITS:
                continue
            if group == "equipment" and case not in HOLDOUT_GEAR:
                continue
            if group not in ("habits", "equipment"):
                continue
            maps = (0, 3, 11)
            repetitions = range(100, 108)
        elif plan == "debug":
            if case not in DEBUG_CASES.get(group, ()):
                continue
            maps = (0, 3, 4, 11)
            repetitions = range(200, 202 if group in ("habits", "equipment") else 201)
        else:
            raise ValueError(f"unknown plan: {plan}")
        for mi in maps:
            for rep in repetitions:
                result[(group, case, mi, 710001 + 1000 * mi + 7919 * rep)] = metadata
    return result


def audit(rows: list[dict], plan: str) -> None:
    expected = expected_plan(plan)
    actual = {(r["group"], r["case"], int(r["map"]), int(r["seed"])): r for r in rows}
    if len(actual) != len(rows):
        raise ValueError("duplicate match keys")
    missing = expected.keys() - actual.keys()
    extra = actual.keys() - expected.keys()
    if missing or extra:
        raise ValueError(f"coverage mismatch: {len(missing)} missing, {len(extra)} unexpected; "
                         f"examples missing={sorted(missing)[:3]} extra={sorted(extra)[:3]}")
    for key, (a, b, change) in expected.items():
        r = actual[key]
        if r["a"] != a or r["b"] != b or r["change"] != change:
            raise ValueError(f"incorrect scenario metadata for {key}")
        side = change.get("side", "A").lower()
        if not 0 <= r.get("bad_active_operators", 0) <= len(r[side]):
            raise ValueError(f"invalid active operator count for {key}")
        if plan == "debug" and (r.get("stress_model") != "resistance_adjusted_event_accumulator_v1"
                                or r.get("decision_telemetry", {}).get("dropped") != 0):
            raise ValueError(f"missing post-change stress model or dropped diagnostics for {key}")
    if plan == "debug":
        moves = sum(r["decision_telemetry"]["total_events"].get("pf04_entry_move", 0) for r in rows)
        if moves == 0:
            raise ValueError("no room-entry execution events in the debug sample")
        # The two groups intentionally replay the same all-good/no-bad baseline.
        # Require exact outcomes and telemetry; these repeated controls are not
        # additional independent matches for statistical comparisons.
        fields = ("winner", "timeout", "seconds", "a_down", "b_down", "a_dead", "b_dead",
                  "a_shots", "b_shots", "a_hits", "b_hits", "decision_telemetry")
        for mi in (0, 3, 4, 11):
            for rep in (200, 201):
                seed = 710001 + 1000 * mi + 7919 * rep
                h = actual[("habits", "baseline", mi, seed)]
                e = actual[("equipment", "baseline", mi, seed)]
                if any(h[f] != e[f] for f in fields):
                    raise ValueError(f"repeated SOF baseline differs on map {mi} seed {seed}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("plan", choices=("screen", "holdout", "debug"))
    parser.add_argument("files", nargs="+", type=Path)
    args = parser.parse_args()
    rows = load_rows(args.files)
    audit(rows, args.plan)
    print(f"PASS {args.plan}: {len(rows)} unique expected matches and all lineup/change metadata")


if __name__ == "__main__":
    main()
