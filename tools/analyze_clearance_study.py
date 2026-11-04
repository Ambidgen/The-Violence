#!/usr/bin/env python3
"""Audit and report the SOF-vs-infantry clearance study (standard library only).

Each fight is paired with a movement-only control by map, size and seed. Incomplete
clearances are censored, not converted to the timeout or included in time averages.
"""
from __future__ import annotations

import argparse
import json
import math
from collections import Counter, defaultdict
from pathlib import Path
from statistics import mean

ROOT = Path(__file__).resolve().parents[1]


def _number(value, *, minimum=0.0):
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < minimum:
        raise ValueError(f"invalid nonnegative number: {value!r}")
    return float(value)


def validate(row: dict) -> None:
    if row["schema"] != 2 or row["condition"] not in ("fight", "unopposed"):
        raise ValueError("invalid schema or condition")
    if row["map"] not in range(12) or row["size"] not in range(1, 6):
        raise ValueError("invalid map or squad size")
    rooms = row["rooms"]
    if not rooms or len(rooms) != len(set(rooms)) or row["room_count"] != len(rooms):
        raise ValueError("invalid room set")
    missing, skipped = set(row["missing_rooms"]), set(row["skipped_rooms"])
    if not skipped <= missing <= set(rooms):
        raise ValueError("invalid missing or skipped rooms")
    events = row["room_events"]
    event_names = [e["room"] for e in events]
    if len(event_names) != len(set(event_names)) or set(event_names) != set(rooms) - missing:
        raise ValueError("room events disagree with remaining rooms")
    end = _number(row["observation_seconds"])
    if row["stop_reason"] not in ("rooms_complete", "fight_end", "room_skipped", "room_limit", "no_attackers"):
        raise ValueError("unknown observation stop reason")
    if row["stop_reason"] == "room_skipped" and not skipped:
        raise ValueError("skip stop without a skipped room")
    if row["stop_reason"] == "rooms_complete" and row["room_seconds"] is None:
        raise ValueError("completion stop without a completed room milestone")
    if end > _number(row["room_limit_s"], minimum=1.0) + 0.04:
        raise ValueError("observation exceeded room limit")
    for event in events:
        if _number(event["seconds"]) > end + 0.002:
            raise ValueError("room event after observation")
        if event["method"] not in ("checked", "clear") or not isinstance(event["entered_by_assigned_element"], bool):
            raise ValueError("room completion has an unknown method or entry evidence")
        if event["method"] == "clear" and not event["entered_by_assigned_element"]:
            raise ValueError("room marked clear without evidence of an assigned entrant")
    if row["room_seconds"] is None:
        if not missing or row["room_movement"] is not None:
            raise ValueError("incomplete clearance recorded as complete")
    else:
        elapsed = _number(row["room_seconds"])
        if missing or elapsed > end + 0.002 or row["room_movement"] is None:
            raise ValueError("invalid completed clearance")
        if events and abs(elapsed - max(e["seconds"] for e in events)) > 0.002:
            raise ValueError("clearance time is not the last room event")
    for name in ("expected_rooms", "expected_defender_posts"):
        model = row[name]
        if not model["ok"] or len(model["paths"]) != row["size"]:
            raise ValueError("invalid route estimate")
        _number(model["speed_mps"], minimum=0.0001)
        times = [_number(p["seconds"]) for p in model["paths"]]
        metres = [_number(p["metres"]) for p in model["paths"]]
        if abs(max(times) - _number(model["seconds"])) > 0.003 or abs(sum(metres) - _number(model["metres"])) > 0.003 * len(metres):
            raise ValueError("route estimate does not match agent paths")
        targets = [target for path in model["paths"] for target in path["targets"]]
        if len(targets) != len(set(targets)):
            raise ValueError("a route target was assigned twice")
        if name == "expected_rooms" and set(targets) != set(rooms):
            raise ValueError("route estimate does not visit every room sample")
        if name == "expected_defender_posts" and set(targets) != {f"B{i}" for i in range(1, row["size"] + 1)}:
            raise ValueError("route estimate does not visit every defender post")
    fight = row["fight"]
    if row["condition"] == "unopposed":
        if fight is not None or row["continued_after_win"] or row["stop_reason"] == "fight_end":
            raise ValueError("unopposed control has a fight outcome")
    else:
        if not isinstance(fight, dict) or fight["winner"] not in (0, 1, 2):
            raise ValueError("fight missing a valid terminal outcome")
        if _number(fight["seconds"]) > _number(row["fight_limit_s"]) + 0.04 or fight["seconds"] > end + 0.002:
            raise ValueError("fight ended after its limit or observation")
        if not (0 <= fight["a_fighting"] <= row["size"] and 0 <= fight["b_fighting"] <= row["size"]):
            raise ValueError("invalid survivor count")
        if row["continued_after_win"] and not (fight["winner"] == 0 and fight["a_fighting"] > 0 and fight["b_fighting"] == 0):
            raise ValueError("post-fight continuation without a neutralized defence")
        if row["room_seconds"] is not None and row["room_seconds"] > fight["seconds"] + 0.002 and not row["continued_after_win"]:
            raise ValueError("room completion after fight without continuation")
        cleared_at_fight = {e["room"] for e in events if e["seconds"] <= fight["seconds"] + 0.002}
        if set(fight["cleared_rooms"]) != cleared_at_fight:
            raise ValueError("fight snapshot disagrees with room events")
    _number(row["room_limit_s"], minimum=1.0)
    for shot in (row["movement_at_stop"], row["room_movement"], None if fight is None else fight["movement"]):
        if shot is not None:
            _number(shot["total_metres"])
            _number(shot["moving_operator_s"])
            _number(shot["stationary_operator_s"])
            _number(shot["requested_no_motion_operator_s"])


def load_rows(paths: list[Path]) -> list[dict]:
    records = []
    seen = set()
    for path in paths:
        with path.open(encoding="utf-8") as source:
            for line_no, line in enumerate(source, 1):
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                    validate(row)
                    key = (row["map"], row["size"], row["seed"], row["condition"])
                    if key in seen:
                        raise ValueError(f"duplicate record {key}")
                    seen.add(key)
                    records.append(row)
                except (KeyError, TypeError, ValueError, json.JSONDecodeError) as exc:
                    raise ValueError(f"{path}:{line_no}: {exc}") from exc
    if not records:
        raise ValueError("no records")
    return records


def audit_coverage(rows: list[dict], maps: list[int], sizes: list[int], n: int, seed: int) -> None:
    expected = {(m, s, seed + 1000 * m + 7919 * rep, cond)
                for m in maps for s in sizes for rep in range(n) for cond in ("fight", "unopposed")}
    actual = {(r["map"], r["size"], r["seed"], r["condition"]) for r in rows}
    if actual != expected:
        raise ValueError(f"coverage mismatch: missing {len(expected - actual)}, unexpected {len(actual - expected)}")
    pairs = {(r["map"], r["size"], r["seed"]): r for r in rows if r["condition"] == "unopposed"}
    for fight in (r for r in rows if r["condition"] == "fight"):
        control = pairs[(fight["map"], fight["size"], fight["seed"])]
        for field in ("map_name", "rooms", "expected_rooms", "expected_defender_posts", "fight_limit_s", "room_limit_s"):
            if fight[field] != control[field]:
                raise ValueError(f"fight/control mismatch in {field}")


def summarize(rows: list[dict]) -> dict:
    if not rows:
        raise ValueError("empty sample")
    condition = rows[0]["condition"]
    if any(r["condition"] != condition for r in rows):
        raise ValueError("mixed conditions")
    complete = [r for r in rows if r["room_seconds"] is not None]
    result = {"n": len(rows), "complete": len(complete),
              "room_mean": mean(r["room_seconds"] for r in complete) if complete else None,
              "room_metres_mean": mean(r["room_movement"]["total_metres"] for r in complete) if complete else None,
              "skipped": sum(bool(r["skipped_rooms"]) for r in rows),
              "limited": sum(r["stop_reason"] == "room_limit" for r in rows)}
    if condition == "fight":
        outcomes = Counter(r["fight"]["winner"] for r in rows)
        wins = [r for r in rows if r["fight"]["winner"] == 0]
        neutralized = [r for r in wins if r["fight"]["b_fighting"] == 0]
        result.update({"a": outcomes[0], "b": outcomes[1], "draw": outcomes[2],
                       "timeouts": sum(r["fight"]["timeout"] for r in rows),
                       "win_mean": mean(r["fight"]["seconds"] for r in wins) if wins else None,
                       "neutralized": len(neutralized),
                       "neutralized_mean": mean(r["fight"]["seconds"] for r in neutralized) if neutralized else None,
                       "ammo_wins": len(wins) - len(neutralized)})
    return result


def _time(value) -> str:
    return "—" if value is None else f"{value:.1f}"


def report(rows: list[dict], paths: list[Path], n: int, seed: int) -> str:
    groups = defaultdict(list)
    for row in rows:
        groups[(row["map"], row["size"], row["condition"])].append(row)
    fights = [r for r in rows if r["condition"] == "fight"]
    controls = [r for r in rows if r["condition"] == "unopposed"]
    fs, us = summarize(fights), summarize(controls)
    maps = sorted({r["map"] for r in rows})
    sizes = sorted({r["size"] for r in rows})
    caps = {r["room_limit_s"] for r in rows}
    speeds = {r["expected_rooms"]["speed_mps"] for r in rows}
    if len(caps) != 1 or len(speeds) != 1:
        raise ValueError("mixed room limits or SOF walking speeds")
    cap = caps.pop()
    speed = speeds.pop()
    inputs = []
    for path in paths:
        try:
            inputs.append(f"[`{path.name}`](../{path.relative_to(ROOT).as_posix()})")
        except ValueError:
            inputs.append(f"`{path}`")
    lines = [
        "# SOF assault clearance timing — 2 November 2026", "",
        "This is a deterministic tactical-simulation study, not a real-world clearance-time prediction or a visual playtest. "
        "A single Special Operations squad assaults a single equal-sized Regular Infantry squad. "
        f"Each map/size uses {n} seed(s), plus a matched movement-only control with no defenders.", "",
        "## Key totals", "",
        f"- Fights: **{len(fights)}**; attacker/defender/draw outcomes **{fs['a']}/{fs['b']}/{fs['draw']}** "
        f"({fs['timeouts']} fight timeouts). Game wins with defenders still fighting due to ammunition exhaustion: {fs['ammo_wins']}.",
        f"- Entire-room completion in the contested runs: **{fs['complete']}/{fs['n']}** "
        f"({fs['skipped']} had a skipped room; {fs['limited']} hit the separate room-observation cap).",
        f"- Entire-room completion in movement-only controls: **{us['complete']}/{us['n']}** "
        f"({us['skipped']} had a skipped room; {us['limited']} hit the separate room-observation cap).",
        "- See [movement findings and fixes](CLEARANCE_DIAGNOSIS_2026-11-02.md) for the reproduced defects, "
        "before/after evidence, and interpretation of the slower cases.", "",
        "## How to read the comparisons", "",
        "- **Expected room travel** is an intentionally simplified reference: choose one reachable 0.25 m grid point "
        "nearest each interior room's label, assign the next point to the independent attacker that would arrive first, "
        "and sum profile-0 open-door navigation distances along each agent's route. Divide each by that agent's equipped "
        "walking speed; the largest individual travel time is the group estimate. "
        f"The SOF preset walks at **{speed:.4f} m/s** after its armour and kit penalties. The route's total metres and assigned "
        "points are in the JSONL. It assumes perfect independent parallel movement and ignores squad cohesion, entry, "
        "checking, combat, wounds, exposure avoidance and delays. A check room may be checked from its doorway rather than "
        "visited at the sampled interior point. **It is neither an optimal route nor a strict lower bound**, and it is not a "
        "prediction of combat duration. `Model m` is the sum of the independently assigned routes; `Actual m` is the "
        "sum of all attackers' measured movement until completion. These are person-metres, not wall-clock distances. "
        "`Serial s` repeats the one-operator route for the same map as an alternative non-splitting-squad reference; "
        "it still excludes every entry, check and delay and does not model the extra members' movement.",
        "- **Room actual** is the first tick when the game's team bookkeeping marks every interior room as cleared or "
        "checked. A skipped room is not clear. Every ordinary clear was audited for an assigned member entering the room; "
        "a PF10 `checked` room can instead be inspected from the doorway. This is an engine-defined milestone, not proof "
        "that every square metre was physically searched. Normal fights end on an outcome; after a win with no defending fighters remaining, "
        "we continue the same surviving attackers and state with only the automatic match-end check disabled. The "
        f"unopposed control disables that check from the start. Room-clearance observation is capped at {cap:,.0f} simulated "
        "seconds, including fight time. These extended times are **not normal in-game match durations**.",
        f"- The room table reports the mean of **completed** runs only, with the completion count / {n} alongside it. "
        "A loss, draw, unchecked room or capped run that has not already reached the room milestone is censored; "
        "an em dash means no run completed. A room milestone reached before a fight was subsequently lost is still recorded.",
        "- **Defender-post travel** is a separate counterfactual: the same assignment model to all defenders' initial "
        "positions. It is **not** an expected time to kill, or a lower bound: soldiers can fire from range and defenders "
        "can move. The combat table reports normal in-game A/B/draw outcomes and the mean time only for A wins in which "
        "no defending fighters remain. A win by enemy ammunition exhaustion is counted as an A win, not as a neutralized defence.", "",
        "## Room-clear timing by map and squad size", "",
        "`Model` is the idealized independent route reference; `Serial s` is the same map's one-operator route. "
        "The unopposed and contested columns give actual mean total attacker movement and elapsed seconds for "
        f"completed runs only. Counts are out of {n}.", "",
        "| Map | Size | Rooms | Model m | Model s | Serial s | Unopposed m | Unopposed s (done) | Contested m | Contested s (done) |",
        "| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |",
    ]
    for m in maps:
        for size in sizes:
            f = groups[(m, size, "fight")]
            u = groups[(m, size, "unopposed")]
            if not f or not u:
                continue
            fsum, usum = summarize(f), summarize(u)
            name = f"{m:02d} {f[0]['map_name']}"
            serial = groups.get((m, 1, "fight"), [])
            serial_s = serial[0]["expected_rooms"]["seconds"] if serial else None
            lines.append(f"| {name} | {size}v{size} | {f[0]['room_count']} | "
                         f"{f[0]['expected_rooms']['metres']:.1f} | {f[0]['expected_rooms']['seconds']:.1f} | {_time(serial_s)} | "
                         f"{_time(usum['room_metres_mean'])} | {_time(usum['room_mean'])} ({usum['complete']}/{usum['n']}) | "
                         f"{_time(fsum['room_metres_mean'])} | {_time(fsum['room_mean'])} ({fsum['complete']}/{fsum['n']}) |")
    lines += ["", "## Fight timing by map and squad size", "",
              "`Post route` is travel to the defenders' starting posts, not an estimate of the shooting time. "
              f"`Defeated actual` is conditional on an A win with zero defending fighters and gives its count / {n}.", "",
              "| Map | Size | Post route m | Post route s | A/B/draw | Defeated actual s (done) |",
              "| --- | ---: | ---: | ---: | ---: | ---: |"]
    for m in maps:
        for size in sizes:
            f = groups[(m, size, "fight")]
            if not f:
                continue
            s = summarize(f)
            lines.append(f"| {m:02d} {f[0]['map_name']} | {size}v{size} | {f[0]['expected_defender_posts']['metres']:.1f} | "
                         f"{f[0]['expected_defender_posts']['seconds']:.1f} | {s['a']}/{s['b']}/{s['draw']} | "
                         f"{_time(s['neutralized_mean'])} ({s['neutralized']}/{s['n']}) |")
    lines += ["", "## Reproducibility and limits", "",
              f"- Maps {', '.join(f'{m:02d}' for m in maps)}; squad sizes {', '.join(f'{s}v{s}' for s in sizes)}. "
              "These are the natural one-squad sizes. Initial A and B positions are the map's normal test-range spawns; "
              "B starts in hold and is prevented "
              "from automatically switching to hunt after 60 quiet seconds. Both sides use their full UI preset kits, "
              "experience and habits, including stress bad habits. No civilians, campaign state, police rules, "
              "night, or closed doors. Defenders can still react to contact and move defensively.",
              f"- Seeds are `{seed} + 1000 * map_index + 7919 * repetition`, repetition 0–{n - 1}. "
              f"Seed pairing fixes the labels and setup, not the later random stream or behavior. {n} fight(s) per cell "
              "are an exploratory sample; mean completion times are conditional on success, not estimates of a "
              f"population or causal effects. The {cap:,.0f}-second room cap differs from normal fight limits (240–900 s).",
              "- These records do not embed executable provenance. See the study's accompanying README for the "
              "engine used; an official-editor run and visual playtesting remain advisable.",
              "- Raw records: " + ", ".join(inputs) + ".",
              f"- Reproduce with `godot --headless --path . -s res://tests/clearance_study.gd -- "
              f"--maps={','.join(map(str, maps))} --sizes={','.join(map(str, sizes))} --n={n} "
              f"--seed={seed} --max-room-seconds={cap:.0f} --out=res://build/clearance.jsonl`, then run "
              f"`python3 tools/analyze_clearance_study.py build/clearance.jsonl --maps={','.join(map(str, maps))} "
              f"--sizes={','.join(map(str, sizes))} --n={n} --seed={seed} --output build/clearance-report.md`.", ""]
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--maps", default="0,1,2,3,4,5,6,7,8,9,10,11")
    parser.add_argument("--sizes", default="1,2,3,4,5")
    parser.add_argument("--n", type=int, default=3)
    parser.add_argument("--seed", type=int, default=811001)
    args = parser.parse_args()
    try:
        paths = [p.resolve() for p in args.paths]
        rows = load_rows(paths)
        maps = [int(x) for x in args.maps.split(",")]
        sizes = [int(x) for x in args.sizes.split(",")]
        if args.n < 1 or not maps or not sizes or len(set(maps)) != len(maps) or len(set(sizes)) != len(sizes):
            raise ValueError("invalid coverage plan")
        audit_coverage(rows, maps, sizes, args.n, args.seed)
        text = report(rows, paths, args.n, args.seed)
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(text, encoding="utf-8")
        else:
            print(text)
    except (OSError, ValueError, KeyError, TypeError) as exc:
        parser.error(str(exc))


if __name__ == "__main__":
    main()
