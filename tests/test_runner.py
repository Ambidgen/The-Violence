#!/usr/bin/env python3
"""Regression tests for run_tests.sh without needing a Godot installation.

    python3 -m unittest discover -s tests -p 'test_runner.py'
"""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUNNER = ROOT / "tools" / "run_tests.sh"


class RunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.engine = self.directory / "godot"
        self.engine.write_text(
            "#!/bin/sh\n"
            "if [ \"$1\" = --version ]; then echo fake-engine; exit 0; fi\n"
            "case \"$*\" in\n"
            "  *\"$TEST_SUITE\"*)\n"
            "    case \"$TEST_RESULT\" in\n"
            "      exit) exit 7 ;;\n"
            "      timeout) exit 124 ;;\n"
            "      script_error) echo 'SCRIPT ERROR: simulated failure'; exit 0 ;;\n"
            "      engine_error) echo 'ERROR: failed loading resource'; exit 0 ;;\n"
            "      fail_text) echo 'GATE something -> FAIL'; exit 0 ;;\n"
            "      stale_fixture) echo 'FAIL: 22 case(s) changed. If intended, re-run with --write and read the diff.'; exit 1 ;;\n"
            "      abort) runner=$(ps -o ppid= -p \"$PPID\" | tr -d ' '); kill -KILL \"$runner\"; exit 0 ;;\n"
            "    esac ;;\n"
            "esac\n"
            "echo ok\n"
        )
        self.engine.chmod(0o755)

    def run_tier(self, jobs, result="pass", suite="city_integration_test.gd", tier="--quick"):
        env = dict(os.environ, GODOT=str(self.engine), JOBS=str(jobs),
                   TEST_LOG_DIR=str(self.directory / "logs"),
                   TEST_SUITE=suite, TEST_RESULT=result)
        # these runs are "outside GitHub Actions" even when the tests run in CI
        env.pop("GITHUB_ACTIONS", None)
        return subprocess.run([str(RUNNER), tier], cwd=ROOT, env=env,
                              text=True, capture_output=True, timeout=30)

    def test_list_does_not_require_godot(self):
        env = dict(os.environ, GODOT="missing-engine")
        proc = subprocess.run([str(RUNNER), "--list"], cwd=ROOT, env=env,
                              text=True, capture_output=True, timeout=10)
        self.assertEqual(proc.returncode, 0, proc.stderr)
        self.assertIn("city_integration_test.gd", proc.stdout)
        self.assertIn("balance_matrix_test.gd", proc.stdout)

    def test_range_tier_excludes_campaign_scenarios(self):
        proc = self.run_tier(1, tier="--range")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("test_range_regression_test", proc.stdout)
        self.assertIn("test_range_replays_test", proc.stdout)
        self.assertIn("test_range_determinism_test", proc.stdout)
        self.assertIn("group_movement_test", proc.stdout)
        self.assertIn("clearance_model_test", proc.stdout)
        self.assertIn("habits_test", proc.stdout)
        self.assertNotRegex(proc.stdout, r"(?m)^\s*PASS\s+determinism_test\s")
        self.assertNotIn("orders_test", proc.stdout)

    def test_serial_and_parallel_pass(self):
        for jobs in (1, 2):
            with self.subTest(jobs=jobs):
                proc = self.run_tier(jobs)
                self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
                self.assertIn("fail: 0", proc.stdout)

    def test_nonzero_exit_is_not_lost_in_parallel(self):
        for jobs in (1, 2):
            with self.subTest(jobs=jobs):
                proc = self.run_tier(jobs, "exit")
                self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
                self.assertIn("city_integration_test.gd", proc.stdout)
                self.assertIn("fail: 1", proc.stdout)

    def test_script_errors_and_timeouts_fail(self):
        for jobs in (1, 2):
            with self.subTest(jobs=jobs, failure="script_error"):
                proc = self.run_tier(jobs, "script_error")
                self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
            with self.subTest(jobs=jobs, failure="engine_error"):
                proc = self.run_tier(jobs, "engine_error")
                self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
            with self.subTest(jobs=jobs, failure="timeout"):
                proc = self.run_tier(jobs, "timeout")
                self.assertEqual(proc.returncode, 3, proc.stdout + proc.stderr)
                self.assertIn("timeout: 1", proc.stdout)

    # P0.A1 (2026-10-28): the runner trusts exit codes, not log text.
    def test_exit_code_is_trusted_over_log_text(self):
        # Every harness now sets its own exit code, so a log line containing FAIL
        # with exit 0 is a passing suite (e.g. a probe printing a measurement).
        proc = self.run_tier(1, "fail_text", suite="civ_test.gd", tier="--full")
        self.assertRegex(proc.stdout, r"(?m)^\s*PASS\s+civ_test\s")

    def test_former_note_suites_now_fail_on_exit_code(self):
        # stall_test used to be "note": it could never fail the tier.
        proc = self.run_tier(1, "exit", suite="stall_test.gd", tier="--full")
        self.assertRegex(proc.stdout, r"(?m)^\s*FAIL\s+stall_test\s")
        self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)

    def test_former_note_suites_now_fail_on_script_error(self):
        proc = self.run_tier(1, "script_error", suite="perf.gd", tier="--soak")
        self.assertRegex(proc.stdout, r"(?m)^\s*FAIL\s+perf\s")

    def test_xfail_is_known_and_does_not_fail_the_tier(self):
        # tests/determinism_test.gd only, not test_range_determinism_test.gd
        proc = self.run_tier(1, "stale_fixture", suite="tests/determinism_test.gd", tier="--full")
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertRegex(proc.stdout, r"(?m)^\s*KNOWN\s+determinism_test\s.*rebaseline")
        self.assertIn("known failures: 1", proc.stdout)

    def test_xfail_crash_is_not_the_known_failure(self):
        # a failure without the stale-fixture line (a crash, a missing fixture) or
        # with a script error must fail the tier, serial and parallel
        for result in ("exit", "script_error"):
            for jobs in (1, 2):
                with self.subTest(result=result, jobs=jobs):
                    proc = self.run_tier(jobs, result, suite="tests/determinism_test.gd", tier="--full")
                    self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
                    self.assertIn("determinism_test.gd", proc.stdout.split("failed:")[-1])

    def test_xpass_fails_the_tier(self):
        # every suite passes, including the xfail one: its mark must be removed
        for jobs in (1, 2):
            with self.subTest(jobs=jobs):
                proc = self.run_tier(jobs, "pass", tier="--full")
                self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
                self.assertIn("determinism_test.gd (xpass)", proc.stdout)

    def test_failed_suite_becomes_a_github_annotation(self):
        env = dict(os.environ, GODOT=str(self.engine), JOBS="1", GITHUB_ACTIONS="true",
                   TEST_LOG_DIR=str(self.directory / "logs"),
                   TEST_SUITE="city_integration_test.gd", TEST_RESULT="script_error")
        proc = subprocess.run([str(RUNNER), "--quick"], cwd=ROOT, env=env,
                              text=True, capture_output=True, timeout=30)
        self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
        self.assertRegex(proc.stdout, r"(?m)^::error title=city_integration_test FAIL \(exit 0\)::.*SCRIPT ERROR")
        # and not outside GitHub Actions
        proc = self.run_tier(1, "script_error")
        self.assertNotIn("::error", proc.stdout)

    def test_tilde_in_godot_path_is_expanded(self):
        env = dict(os.environ, HOME=str(self.directory), GODOT="~/godot", JOBS="1",
                   TEST_LOG_DIR=str(self.directory / "logs"),
                   TEST_SUITE="none", TEST_RESULT="pass")
        proc = subprocess.run([str(RUNNER), "--check"], cwd=ROOT, env=env,
                              text=True, capture_output=True, timeout=30)
        self.assertEqual(proc.returncode, 0, proc.stdout + proc.stderr)
        self.assertIn("fake-engine", proc.stdout)

    def test_stale_status_files_cannot_mask_failed_children(self):
        self.run_tier(2)
        proc = self.run_tier(2, "abort")
        self.assertEqual(proc.returncode, 1, proc.stdout + proc.stderr)
        self.assertNotIn("all selected suites passed", proc.stdout)


if __name__ == "__main__":
    unittest.main()
