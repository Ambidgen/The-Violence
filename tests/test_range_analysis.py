"""Checks the arithmetic and pairing used in the test-range study report."""
import json
import math
import tempfile
import unittest
from pathlib import Path

from tools.analyze_test_range_study import load_rows, paired, summarize, wilson
from tools.audit_test_range_coverage import audit, expected_plan


def row(seed, winner, a_down=0, b_down=0, case="baseline", **extra):
    out = {"group": "habits", "case": case, "map": 0, "seed": seed,
           "winner": winner, "timeout": False, "seconds": 10.0,
           "a": ["sof", "sof"], "b": ["sof", "sof"],
           "a_down": a_down, "b_down": b_down, "a_dead": 0, "b_dead": 0, "friendly_hits": 0}
    out.update(extra)
    return out


class StudyAnalysisTests(unittest.TestCase):
    def test_draws_remain_in_denominator(self):
        value = summarize([row(1, 0), row(2, 1), row(3, 2)])
        self.assertEqual((value["a"], value["b"], value["draw"], value["n"]), (1, 1, 1, 3))

    def test_owner_delta_and_losses_are_paired_by_map_seed(self):
        base = [row(1, 0, 0, 2), row(2, 1, 2, 0), row(3, 2, 1, 1)]
        variant = [row(3, 1, 1, 0, "change", bad_active_operators=2),
                   row(1, 1, 2, 0, "change", bad_active_operators=0),
                   row(2, 0, 0, 2, "change", bad_active_operators=1)]
        a = paired(variant, base, "A")
        b = paired(variant, base, "B")
        self.assertEqual((a["gained"], a["lost"], a["delta_pp"]), (1, 1, 0.0))
        self.assertEqual((b["gained"], b["lost"]), (2, 1))
        self.assertAlmostEqual(b["delta_pp"], 100.0 / 3)
        self.assertEqual(b["active_matches"], 2)
        self.assertEqual(b["active_operators"], 3)
        self.assertAlmostEqual(b["down_delta"], -1 / 3)

    def test_paired_deaths_and_invalid_death_counts(self):
        base = [row(1, 0, a_down=2, a_dead=1)]
        changed = [row(1, 1, a_down=2, a_dead=2, case="change")]
        self.assertEqual(paired(changed, base, "A")["dead_delta"], 1.0)
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "invalid.jsonl"
            path.write_text(json.dumps(row(1, 0, a_down=0, a_dead=1)) + "\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "death count"):
                load_rows([path])

    def test_missing_baseline_fails_closed(self):
        with self.assertRaises(ValueError):
            paired([row(5, 0, case="change")], [row(4, 0)], "A")

    def test_wilson_interval_is_finite_and_wide_for_six_matches(self):
        lo, hi = wilson(3, 6)
        self.assertTrue(math.isclose(lo, 0.1876, abs_tol=0.001))
        self.assertTrue(math.isclose(hi, 0.8124, abs_tol=0.001))

    def test_study_plans_are_complete_and_separate(self):
        screen, holdout = expected_plan("screen"), expected_plan("holdout")
        self.assertEqual(len(screen), 1441)
        self.assertEqual(len(holdout), 336)
        self.assertFalse(screen.keys() & holdout.keys())
        debug = expected_plan("debug")
        self.assertEqual(len(debug), 152)
        self.assertFalse(debug.keys() & screen.keys())
        self.assertFalse(debug.keys() & holdout.keys())
        with self.assertRaisesRegex(ValueError, "coverage mismatch"):
            audit([], "screen")
        synthetic = [{"group": g, "case": c, "map": m, "seed": seed, "a": a, "b": b, "change": change}
                     for (g, c, m, seed), (a, b, change) in holdout.items()]
        audit(synthetic, "holdout")
        synthetic[0] = {**synthetic[0], "a": ["militia"]}
        with self.assertRaisesRegex(ValueError, "scenario metadata"):
            audit(synthetic, "holdout")

    def test_duplicate_match_is_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "same.jsonl"
            text = json.dumps(row(3, 0)) + "\n"
            path.write_text(text + text, encoding="utf-8")
            with self.assertRaises(ValueError):
                load_rows([path])


if __name__ == "__main__":
    unittest.main()
