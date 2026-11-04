"""tools/gd_arity_check.py: the checks that look at what parses but does not load.

Each case here is a fault that reached `main` on 2026-11-02 and was found only by the
engine: a script that parses cleanly and fails the moment Godot loads it. Run with
    python3 -m unittest discover -s tests -p 'test_*analysis.py'
"""

import contextlib
import io
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import gd_arity_check as gd  # noqa: E402


class Arity(unittest.TestCase):
    def check(self, source: str) -> list[str]:
        # a throwaway module in the tree the checker walks
        tmp = ROOT / "tests" / "_arity_case.gd"
        tmp.write_text(source)
        try:
            return gd.check_file(tmp, {})
        finally:
            tmp.unlink()

    def test_too_many_arguments(self):
        problems = self.check(
            'func _poll(c: String, d: float) -> void:\n\tpass\n\n'
            'func go() -> void:\n\t_poll("pell", 1.0, "a cause")\n')
        self.assertEqual(len(problems), 1, problems)
        self.assertIn("_poll() takes at most 2", problems[0])

    def test_default_arguments_are_allowed(self):
        problems = self.check(
            'func _poll(c: String, d: float, cause := "") -> void:\n\tpass\n\n'
            'func go() -> void:\n\t_poll("pell", 1.0)\n\t_poll("pell", 1.0, "why")\n')
        self.assertEqual(problems, [])

    def test_nested_call_arguments_do_not_count(self):
        problems = self.check(
            'func f(a: int) -> void:\n\tpass\n\n'
            'func go() -> void:\n\tf(maxi(1, 2, 3))\n')
        self.assertEqual(problems, [])

    def test_preloaded_alias_is_checked(self):
        problems = self.check(
            'func f(a: int, b: int) -> void:\n\tpass\n')
        self.assertEqual(problems, [])


class Concat(unittest.TestCase):
    def check(self, source: str) -> list[str]:
        tmp = ROOT / "tests" / "_arity_case.gd"
        tmp.write_text(source)
        try:
            return gd.check_file(tmp, {})
        finally:
            tmp.unlink()

    def test_string_plus_int_call(self):
        problems = self.check(
            'func go() -> void:\n\tprint("votes: " + int(41))\n')
        self.assertTrue(any("string + number" in p for p in problems), problems)

    def test_string_plus_number(self):
        problems = self.check('func go() -> void:\n\tprint("week " + 5)\n')
        self.assertTrue(any("string + number" in p for p in problems), problems)

    def test_formatting_is_fine(self):
        problems = self.check(
            'func go() -> void:\n\tprint("votes: %d" % int(41))\n'
            '\tprint("a" + String(5) + "b")\n\tprint("+5".contains("+"))\n')
        self.assertEqual(problems, [])


class Names(unittest.TestCase):
    def check(self, source: str) -> list[str]:
        tmp = ROOT / "tests" / "_arity_case.gd"
        tmp.write_text(source)
        try:
            return gd.check_file(tmp, {})
        finally:
            tmp.unlink()

    def test_undeclared_constant(self):
        problems = self.check('func go() -> int:\n\treturn SURPLUS_AMOUNT\n')
        self.assertTrue(any("SURPLUS_AMOUNT" in p and "not declared" in p for p in problems), problems)

    def test_declared_constant_is_not_a_finding(self):
        problems = self.check('const SURPLUS_AMOUNT := 5000\n\nfunc go() -> int:\n\treturn SURPLUS_AMOUNT\n')
        self.assertEqual(problems, [])

    def test_engine_globals_are_not_findings(self):
        problems = self.check('func go() -> float:\n\treturn TAU * INF + float(KEY_ESCAPE)\n')
        self.assertEqual(problems, [])

    def test_strings_and_comments_are_not_identifiers(self):
        problems = self.check('## SURPLUS_COOLDOWN is described here\nfunc go() -> String:\n\treturn "SWEEP_FLOOR"\n')
        self.assertEqual(problems, [])


class TheTree(unittest.TestCase):
    def test_the_repository_is_clean(self):
        """The whole point: this is green in CI, so a new fault of this class fails the build."""
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = gd.main([])
        self.assertEqual(code, 0, out.getvalue())


if __name__ == "__main__":
    unittest.main()
