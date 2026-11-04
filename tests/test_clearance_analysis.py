"""Audit and censoring tests for the clearance-timing report."""
import copy
import json
import tempfile
import unittest
from pathlib import Path

from tools.analyze_clearance_study import audit_coverage, load_rows, report, summarize, validate


def record(condition="fight", seed=811001):
    motion = {"total_metres": 5.0, "moving_operator_s": 4.0, "stationary_operator_s": 6.0,
              "requested_no_motion_operator_s": 0.5, "operators": []}
    model = {"ok": True, "metres": 10.0, "seconds": 5.0, "speed_mps": 2.0,
             "paths": [{"id": "A1", "metres": 10.0, "seconds": 5.0, "targets": ["ROOM"]}]}
    posts = copy.deepcopy(model)
    posts["paths"][0]["targets"] = ["B1"]
    fight = {"seconds": 8.0, "winner": 0, "timeout": False, "a_fighting": 1, "b_fighting": 0,
             "shots": 3, "hits": 1, "cleared_rooms": [], "skipped_rooms": [], "movement": motion}
    return {"schema": 2, "condition": condition, "map": 0, "map_id": "m00", "map_name": "Test",
            "size": 1, "seed": seed, "room_count": 1, "rooms": ["ROOM"], "fight_limit_s": 300,
            "room_limit_s": 1200, "expected_rooms": model, "expected_defender_posts": posts,
            "room_seconds": 10.0, "room_movement": motion, "fight": fight if condition == "fight" else None,
            "continued_after_win": condition == "fight", "observation_seconds": 10.0,
            "stop_reason": "rooms_complete", "missing_rooms": [], "skipped_rooms": [],
            "room_events": [{"room": "ROOM", "seconds": 10.0, "method": "clear",
                             "entered_by_assigned_element": True}], "movement_at_stop": motion}


def failure(seed=818920):
    row = record(seed=seed)
    row.update(room_seconds=None, room_movement=None, continued_after_win=False, observation_seconds=100,
               stop_reason="fight_end", missing_rooms=["ROOM"], room_events=[])
    row["fight"] = {**row["fight"], "seconds": 100.0, "winner": 1, "a_fighting": 0, "b_fighting": 1}
    return row


class ClearanceAnalysisTests(unittest.TestCase):
    def test_incomplete_runs_are_not_treated_as_completed_times(self):
        won, lost = record(), failure()
        validate(won)
        validate(lost)
        result = summarize([won, lost])
        self.assertEqual((result["n"], result["complete"], result["a"], result["b"]), (2, 1, 1, 1))
        self.assertEqual(result["room_mean"], 10.0)
        self.assertEqual(result["neutralized_mean"], 8.0)

    def test_ammunition_win_not_mislabelled_as_all_defenders_down(self):
        row = record()
        row["continued_after_win"] = False
        row["fight"]["b_fighting"] = 1
        row["room_seconds"] = 7.0
        row["room_events"][0]["seconds"] = 7.0
        row["fight"]["cleared_rooms"] = ["ROOM"]
        validate(row)
        result = summarize([row])
        self.assertEqual((result["a"], result["neutralized"], result["ammo_wins"]), (1, 0, 1))
        self.assertIsNone(result["neutralized_mean"])

    def test_room_events_and_skips_must_match(self):
        row = record()
        row["skipped_rooms"] = ["ROOM"]
        with self.assertRaisesRegex(ValueError, "missing or skipped"):
            validate(row)
        row = record()
        row["room_events"][0]["seconds"] = 9.0
        with self.assertRaisesRegex(ValueError, "last room event"):
            validate(row)
        row = failure()
        row["missing_rooms"] = []
        with self.assertRaises(ValueError):
            validate(row)

    def test_entry_completions_require_occupancy_evidence_but_door_checks_do_not(self):
        row = record()
        row["room_events"][0]["entered_by_assigned_element"] = False
        with self.assertRaisesRegex(ValueError, "without evidence"):
            validate(row)
        row["room_events"][0]["method"] = "checked"
        validate(row)
        row["room_events"][0]["method"] = "unknown"
        with self.assertRaisesRegex(ValueError, "unknown method"):
            validate(row)

    def test_route_must_cover_targets_and_add_up(self):
        row = record()
        row["expected_rooms"]["paths"][0]["targets"] = []
        with self.assertRaisesRegex(ValueError, "every room"):
            validate(row)
        row = record()
        row["expected_rooms"]["seconds"] = 999.0
        with self.assertRaisesRegex(ValueError, "agent paths"):
            validate(row)

    def test_continuation_and_times_fail_closed(self):
        row = record()
        row["fight"]["b_fighting"] = 1
        with self.assertRaisesRegex(ValueError, "continuation"):
            validate(row)
        row = record()
        row["room_seconds"] = float("nan")
        with self.assertRaisesRegex(ValueError, "invalid nonnegative number"):
            validate(row)
        row = record()
        row["continued_after_win"] = False
        with self.assertRaisesRegex(ValueError, "after fight without continuation"):
            validate(row)
        row = record()
        row["fight"]["cleared_rooms"] = ["ROOM"]
        with self.assertRaisesRegex(ValueError, "snapshot disagrees"):
            validate(row)

    def test_pair_and_coverage_audit(self):
        rows = [record("fight"), record("unopposed")]
        audit_coverage(rows, [0], [1], 1, 811001)
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            audit_coverage(rows[:1], [0], [1], 1, 811001)
        rows[1]["expected_rooms"]["seconds"] = 6
        with self.assertRaisesRegex(ValueError, "fight/control mismatch"):
            audit_coverage(rows, [0], [1], 1, 811001)

    def test_jsonl_duplicate_rejected_and_report_uses_denominators(self):
        rows = [record("fight"), record("unopposed")]
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "study.jsonl"
            path.write_text("\n".join(json.dumps(r) for r in rows + rows[:1]) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "duplicate"):
                load_rows([path])
            path.write_text("\n".join(json.dumps(r) for r in rows) + "\n", encoding="utf-8")
            loaded = load_rows([path])
            text = report(loaded, [path], 1, 811001)
            self.assertIn("10.0 (1/1)", text)
            self.assertIn("Serial s", text)
            self.assertIn("2.0000 m/s", text)
            self.assertIn("not a real-world clearance-time prediction", text)


if __name__ == "__main__":
    unittest.main()
