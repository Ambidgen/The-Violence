#!/usr/bin/env bash
# The Violence: one command that runs the headless suites.
#
# Why this exists: the README documents the harnesses one by one, and each one
# has to be retyped with its own arguments. That is fine for a developer
# checking one thing and useless for a release gate. This wraps them in tiers,
# keeps a log per suite, and exits non-zero if any suite fails.
#
#   tools/run_tests.sh --check          compile only (fastest possible signal)
#   tools/run_tests.sh --range          tactical test-range regressions, no campaign playtests
#   tools/run_tests.sh --quick          the gates a commit should pass (default)
#   tools/run_tests.sh --full           quick + the simulation/campaign suites
#   tools/run_tests.sh --soak           full + the asserted balance matrix
#   tools/run_tests.sh --list           print the plan and exit
#
#   GODOT=/path/to/godot tools/run_tests.sh --quick
#   JOBS=1              run suites one after another (default; the sim is not
#                       thread-safe across processes on a small box)
#   TIMEOUT_SCALE=2     multiply every per-suite timeout (default: 2 on a machine
#                       with two cores or fewer, 1 otherwise)
#
# Exit codes: 0 all green, 1 at least one suite failed, 2 the runner was misused
# (no Godot binary, unknown flag), 3 a suite timed out.
#
# Three things to know about the harnesses this calls:
#
#   1. Every harness sets its own exit code (P0.A1, 2026-10-28): gates exit 1 on
#      a failed gate; diagnostics and probes exit 1 when they broke an invariant
#      (a hung operation, a campaign that never reached its election) or measured
#      nothing. The runner trusts that code. It no longer scans logs for the word
#      FAIL.
#   2. It still fails a suite whose log shows a GDScript or engine error (SCRIPT
#      ERROR, Parse Error, ERROR:), because Godot keeps running a script after a
#      runtime error and can still quit(0). This applies to every suite.
#   3. rogue_balance_test runs twice in a life: --smoke in this tier (1 seed x 4
#      policies x 2 weeks, a shakedown of the policy harness and its child processes),
#      and the full Gate 1 matrix by hand or in the balance job of CI (EA_TASKS P1.A2:
#      `tests/rogue_balance_test.gd -- --seeds=20 --policy=all`). The smoke does not
#      assert balance: tests/balance_bands.json is report-only until P1.I.
#   4. A suite marked xfail is a KNOWN failure with a stated reason: it runs and is
#      reported, but does not fail the tier. If it starts passing it is reported as
#      XPASS and *does* fail the tier, so the mark cannot outlive the reason. A
#      failure only counts as KNOWN if the log shows the known signature
#      (known_signature below) and no engine error; a crash is still a FAIL.
#      determinism_test.gd is the one xfail today: its fixture predates the 1.3
#      simulation changes (22 of 35 cases differ on native Linux and on the Web).
#      Rebaseline it with --write in Phase 1 (EA_TASKS P1.I1), then remove the mark.
set -uo pipefail

cd "$(dirname "$0")/.." || exit 2
ROOT="$PWD"
LOGS="${TEST_LOG_DIR:-$ROOT/build/test-logs}"
GODOT="${GODOT:-godot}"
# A leading ~ in an environment value is not expanded by the shell (CI used to pass
# GODOT=~/godot/godot and every headless job stopped at "no Godot binary").
GODOT="${GODOT/#\~/$HOME}"
TIER="quick"
# P0.A2: a small runner gets twice the time, unless the caller says otherwise
if [ -z "${TIMEOUT_SCALE:-}" ]; then
	_cores=$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)
	if [ "$_cores" -le 2 ] 2>/dev/null; then TIMEOUT_SCALE=2; else TIMEOUT_SCALE=1; fi
fi
JOBS="${JOBS:-1}"

usage() {
	sed -n '2,32p' "$0" | sed 's/^# \{0,1\}//'
}

# Reject bad scaling/concurrency instead of silently turning a timeout into 0.
if ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || ! [[ "$TIMEOUT_SCALE" =~ ^[1-9][0-9]*$ ]]; then
	echo "run_tests: JOBS and TIMEOUT_SCALE must be positive integers" >&2
	exit 2
fi

case "${1:---quick}" in
	--check) TIER="check" ;;
	--range) TIER="range" ;;
	--quick) TIER="quick" ;;
	--full) TIER="full" ;;
	--soak) TIER="soak" ;;
	--list) TIER="list" ;;
	-h|--help) usage; exit 0 ;;
	*) echo "run_tests: unknown option '${1}' (try --help)" >&2; exit 2 ;;
esac

if [ "$TIER" != "list" ]; then
	if ! command -v "$GODOT" >/dev/null 2>&1; then
		echo "run_tests: no Godot binary named '$GODOT' on PATH." >&2
		echo "           Set GODOT=/absolute/path/to/godot and run again." >&2
		exit 2
	fi
	mkdir -p "$LOGS"
fi

# name|tier|timeout seconds|how failures are detected|arguments
#   exit  = the harness's exit code (plus the engine-error scan every suite gets)
#   xfail = a known failure (see note 3 above); the reason is in known_reason() below
PLAN=$(cat <<'EOF'
_check.gd|check|300|exit|
godot472_test.gd|quick|300|exit|
crayon_shorts_test.gd|quick|300|exit|
week_recap_test.gd|quick|300|exit|
city_integration_test.gd|quick|300|exit|
character_assets_test.gd|quick|300|exit|
group_movement_test.gd|quick|300|exit|
clearance_model_test.gd|quick|300|exit|
test_range_mechanics_test.gd|quick|300|exit|
test_range_regression_test.gd|quick|300|exit|
test_range_replays_test.gd|quick|600|exit|
test_range_determinism_test.gd|quick|900|exit|
improvements_test.gd|quick|600|exit|
ops_ui_test.gd|quick|600|exit|
dept_test.gd|quick|600|exit|
orders_test.gd|quick|900|exit|
save_test.gd|quick|600|exit|
story_test.gd|quick|300|exit|
politics_test.gd|quick|600|exit|
rogue_test.gd|quick|600|exit|
pacing_test.gd|quick|120|exit|
policies_test.gd|quick|300|exit|
kit_proposal_test.gd|quick|300|exit|
patrol_test.gd|quick|900|exit|
rogue_balance_test.gd|quick|1200|exit|-- --smoke
ui_walk.gd|quick|900|exit|--verbose
determinism_test.gd|full|1800|xfail|-- --verbose
habits_test.gd|full|1200|exit|-- --strict
brains_test.gd|full|1200|exit|-- --n=8
civ_test.gd|full|1800|exit|-- --n=40
equip_test.gd|full|1800|exit|-- --n=12
lethality_test.gd|full|1200|exit|-- --n=20
maps_test.gd|full|600|exit|
nav_door_test.gd|full|900|exit|
op_test.gd|full|1800|exit|-- --weeks=40 --chief=sensible
hold_test.gd|full|1800|exit|
stall_test.gd|full|1800|exit|
fuzz_test.gd|full|1800|exit|-- --n=60
balance_test.gd|soak|1800|exit|-- --gate --n=20
balance_matrix_test.gd|soak|5400|exit|-- --n=30
scale_playtest.gd|soak|5400|exit|-- --gate --n=30
sim_test.gd|soak|1800|exit|
perf.gd|soak|900|exit|-- --map=10 --na=20 --nb=20 --t=60
duel_probe.gd|soak|900|exit|
trace.gd|soak|900|exit|
playtest.gd|soak|1800|exit|
EOF
)

# Why each xfail suite is expected to fail. Remove the line together with the mark.
known_reason() {
	case "$1" in
		determinism_test.gd) echo "fixture predates the 1.3 simulation changes (22/35 differ); rebaseline in P1.I1" ;;
		*) echo "no reason recorded" ;;
	esac
}

# The log line an xfail suite must print for its failure to count as the known one.
# Any other failure (a crash, a script error, a missing fixture) is an ordinary FAIL,
# so the mark cannot hide a new fault behind an old one.
known_signature() {
	case "$1" in
		determinism_test.gd) echo '^FAIL: [0-9]+ case\(s\) changed' ;;
		*) echo '^$NEVER' ;;
	esac
}

want() {
	case "$TIER" in
		check) [ "$1" = "check" ] ;;
		quick) [ "$1" = "check" ] || [ "$1" = "quick" ] ;;
		full) [ "$1" = "check" ] || [ "$1" = "quick" ] || [ "$1" = "full" ] ;;
		soak|list) true ;;
	esac
}

# ---- which suites actually exist (the tree is the source of truth) ----------
selected=()
while IFS='|' read -r name tier budget detect args; do
	[ -z "$name" ] && continue
	[ -f "tests/$name" ] || { echo "run_tests: tests/$name is in the plan but not in the tree" >&2; exit 2; }
	if [ "$TIER" = "range" ]; then
		# Deliberately exclude campaign scenarios and campaign determinism cases.
		case "$name" in
			_check.gd|group_movement_test.gd|clearance_model_test.gd|test_range_mechanics_test.gd|test_range_regression_test.gd|test_range_replays_test.gd|test_range_determinism_test.gd|habits_test.gd|maps_test.gd|nav_door_test.gd)
				selected+=("$name|$tier|$budget|$detect|$args") ;;
		esac
	elif want "$tier"; then
		selected+=("$name|$tier|$budget|$detect|$args")
	fi
done <<< "$PLAN"

if [ "${#selected[@]}" -eq 0 ]; then
	echo "run_tests: nothing selected for tier '$TIER'" >&2
	exit 2
fi

if [ "$TIER" = "list" ]; then
	printf '%-28s %-6s %-7s %-5s\n' SUITE TIER TIMEOUT DETECT
	for row in "${selected[@]}"; do
		IFS='|' read -r name tier budget detect args <<< "$row"
		printf '%-28s %-6s %-7s %-5s\n' "$name" "$tier" "${budget}s" "$detect"
	done
	exit 0
fi

echo "the violence: tier '$TIER', ${#selected[@]} suites, engine: $("$GODOT" --version 2>/dev/null | head -1)"
echo "logs: $LOGS"
echo

if [ -t 1 ]; then
	C_PASS=$'\033[32m'; C_FAIL=$'\033[31m'; C_NOTE=$'\033[36m'; C_OFF=$'\033[0m'
else
	C_PASS=""; C_FAIL=""; C_NOTE=""; C_OFF=""
fi

pass=0; fail=0; timeout_n=0; noted=0
failed_names=()

run_one() {
	local row="$1"
	local name tier budget detect args
	IFS='|' read -r name tier budget detect args <<< "$row"
	local log="$LOGS/${name%.gd}.log"
	local status_file="$LOGS/${name%.gd}.status"
	local seconds=$(( budget * TIMEOUT_SCALE ))
	# shellcheck disable=SC2086
	local -a extra=()
	if [ -n "${args// /}" ]; then extra=(${args}); fi

	local start end rc
	start=$(date +%s)
	timeout --signal=TERM --kill-after=30 "$seconds" \
		"$GODOT" --headless --path . -s "res://tests/$name" "${extra[@]}" >"$log" 2>&1
	rc=$?
	end=$(date +%s)
	local took=$(( end - start ))

	local status="PASS"
	[ "$rc" -ne 0 ] && status="FAIL"
	# A harness may quit(0) after a script or engine/resource error.
	if [ "$status" = "PASS" ] && grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$log"; then status="FAIL"; fi
	if [ "$rc" -eq 124 ] || [ "$rc" -eq 137 ]; then status="TIMEOUT"; fi
	if [ "$detect" = "xfail" ]; then
		case "$status" in
			FAIL)
				# expected only if it failed the known way, and without an engine error
				if grep -qE "$(known_signature "$name")" "$log" && ! grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$log"; then
					status="KNOWN"     # reported, does not fail the tier
				fi ;;
			PASS) status="XPASS" ;;     # the reason is gone: remove the mark
		esac
	fi
	printf '%s\n' "$status" > "$status_file"

	case "$status" in
		PASS) pass=$((pass+1)); printf '  %sPASS%s    %-28s %4ss\n' "$C_PASS" "$C_OFF" "${name%.gd}" "$took" ;;
		KNOWN) noted=$((noted+1)); printf '  %sKNOWN%s   %-28s %4ss  %s\n' "$C_NOTE" "$C_OFF" "${name%.gd}" "$took" "$(known_reason "$name")" ;;
		XPASS) fail=$((fail+1)); failed_names+=("$name (xpass)"); printf '  %sXPASS%s   %-28s %4ss  expected to fail and passed: remove its xfail mark\n' "$C_FAIL" "$C_OFF" "${name%.gd}" "$took" ;;
		FAIL) fail=$((fail+1)); failed_names+=("$name"); printf '  %sFAIL%s    %-28s %4ss  %s\n' "$C_FAIL" "$C_OFF" "${name%.gd}" "$took" "$log" ;;
		TIMEOUT) timeout_n=$((timeout_n+1)); failed_names+=("$name (timeout)"); printf '  %sTIMEOUT%s %-28s %4ss  %s\n' "$C_FAIL" "$C_OFF" "${name%.gd}" "$took" "$log" ;;
	esac
	# keep the interesting part of a failure in front of the reader
	if [ "$status" = "FAIL" ]; then
		grep -nE '\bFAILED\b|\bFAIL\b|HUNG|failures?: *[1-9]|problems?: *[1-9]|stalls: *[1-9]|missing: \[.|SCRIPT ERROR|Parse Error|^ERROR:' "$log" | head -5 | sed 's/^/          /'
	fi
	# Under GitHub Actions a failed suite also becomes an annotation: it shows on the
	# commit and the pull request, and the API returns it even where the raw job log
	# cannot be fetched.
	if [ "${GITHUB_ACTIONS:-}" = "true" ] && { [ "$status" = "FAIL" ] || [ "$status" = "TIMEOUT" ] || [ "$status" = "XPASS" ]; }; then
		local detail
		# (with --verbose, Godot names each resource still in use at exit: EA_TASKS B4)
		detail=$(grep -E '\bFAILED\b|\bFAIL\b|HUNG|failures?: *[1-9]|problems?: *[1-9]|stalls: *[1-9]|missing: \[.|SCRIPT ERROR|Parse Error|^ERROR:|still in use|Leaked instance' "$log" | head -12)
		[ -z "$detail" ] && detail=$(tail -n 8 "$log")
		[ "$status" = "TIMEOUT" ] && detail="timed out after ${seconds}s"$'\n'"$(tail -n 5 "$log")"
		detail="${detail//'%'/'%25'}"; detail="${detail//$'\r'/}"; detail="${detail//$'\n'/'%0A'}"
		printf '::error title=%s %s (exit %s)::%s\n' "${name%.gd}" "$status" "$rc" "$detail"
	fi
}

export -f run_one known_reason known_signature 2>/dev/null || true
export GODOT LOGS TIMEOUT_SCALE C_PASS C_FAIL C_NOTE C_OFF

if [ "$JOBS" -gt 1 ]; then
	# Clear only selected status files: stale logs from an earlier tier must not
	# turn a crashed child into a pass. Each child records its own final status.
	for row in "${selected[@]}"; do
		IFS='|' read -r name tier budget detect args <<< "$row"
		rm -f "$LOGS/${name%.gd}.status"
	done
	printf '%s\n' "${selected[@]}" | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}
	pass=0; fail=0; timeout_n=0; noted=0; failed_names=()
	for row in "${selected[@]}"; do
		IFS='|' read -r name tier budget detect args <<< "$row"
		status_file="$LOGS/${name%.gd}.status"
		status=$(cat "$status_file" 2>/dev/null || printf 'FAIL')
		case "$status" in
			PASS) pass=$((pass+1)) ;;
			KNOWN) noted=$((noted+1)) ;;
			XPASS) fail=$((fail+1)); failed_names+=("$name (xpass)") ;;
			TIMEOUT) timeout_n=$((timeout_n+1)); failed_names+=("$name (timeout)") ;;
			*) fail=$((fail+1)); failed_names+=("$name") ;;
		esac
	done
else
	for row in "${selected[@]}"; do
		run_one "$row"
	done
fi

echo
echo "----------------------------------------------------------------"
printf 'suites: %d   pass: %d   fail: %d   timeout: %d   known failures: %d\n' \
	"${#selected[@]}" "$pass" "$fail" "$timeout_n" "$noted"
if [ "$fail" -ne 0 ] || [ "$timeout_n" -ne 0 ]; then
	echo "failed: ${failed_names[*]}"
	echo "logs are in $LOGS"
	if [ "$timeout_n" -ne 0 ]; then exit 3; fi
	exit 1
fi
echo "all selected suites passed"
exit 0
