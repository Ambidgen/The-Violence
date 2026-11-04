#!/usr/bin/env bash
# The Violence: one command for a campaign playtest (EA_TASKS P0.B).
#
#   tools/playtest.sh                          the 28 Oct playtest: three 40-week runs + the rendered walk
#   tools/playtest.sh --weeks=10               a quicker pass (the same runs, ten weeks)
#   tools/playtest.sh --runs="1001:--hire 4004:"   your own seeds and op_test options
#   tools/playtest.sh --no-walk                campaigns and report only
#   tools/playtest.sh --resolution=1280x720    walk at another size
#
#   GODOT=/path/to/godot   JOBS=2 (campaigns run in parallel; default: cores, max 4)
#   OUT=tests/results/<date>-playtest (default)
#
# Writes OUT/campaign-seed<N>.json and .log for each run, OUT/walk/ (screenshots, the
# side-panel text, walk.json), OUT/report.md (the table, from tools/campaign_report.py)
# and OUT/report.csv. Exits 1 if any run or the walk failed, 2 on misuse.
# Every run is a roguelike run with --chief=sensible; the options after the seed are
# passed to tests/op_test.gd as they are.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2

GODOT="${GODOT:-godot}"
GODOT="${GODOT/#\~/$HOME}"
WEEKS=40
RUNS="1001:--hire --train|2002:|3003:--hire"
WALK=1
RES="1600x900"
OUT="${OUT:-tests/results/$(date +%Y-%m-%d)-playtest}"
_cores=$(nproc 2>/dev/null || echo 1)
JOBS="${JOBS:-$(( _cores > 4 ? 4 : _cores ))}"

for a in "$@"; do
	case "$a" in
		--weeks=*) WEEKS="${a#--weeks=}" ;;
		--runs=*) RUNS="$(printf '%s' "${a#--runs=}" | sed 's/ \([0-9][0-9]*:\)/|\1/g')" ;;
		--no-walk) WALK=0 ;;
		--resolution=*) RES="${a#--resolution=}" ;;
		--out=*) OUT="${a#--out=}" ;;
		-h|--help) sed -n '2,19p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*) echo "playtest: unknown option '$a' (try --help)" >&2; exit 2 ;;
	esac
done
if ! [[ "$WEEKS" =~ ^[1-9][0-9]*$ ]] || ! [[ "$JOBS" =~ ^[1-9][0-9]*$ ]] || ! [[ "$RES" =~ ^[0-9]+x[0-9]+$ ]]; then
	echo "playtest: --weeks, JOBS and --resolution must look like 40, 2 and 1600x900" >&2; exit 2
fi
if ! command -v "$GODOT" >/dev/null 2>&1; then
	echo "playtest: no Godot binary named '$GODOT'. Set GODOT=/absolute/path/to/godot." >&2; exit 2
fi
mkdir -p "$OUT"
OUT="$(cd "$OUT" && pwd)"
STATE="$OUT/.user"          # every run gets its own user:// (saves, legacy, settings)
echo "the violence playtest: $(echo "$RUNS" | tr '|' '\n' | grep -c .) run(s) x $WEEKS weeks, jobs $JOBS, walk $([ $WALK = 1 ] && echo "$RES" || echo off)"
echo "engine: $("$GODOT" --version 2>/dev/null | head -1)   out: $OUT"

# ---- the campaigns ------------------------------------------------------------
run_campaign() {
	local spec="$1" seed opts name
	seed="${spec%%:*}"; opts="${spec#*:}"
	name="campaign-seed${seed}"
	local -a extra=()
	# shellcheck disable=SC2206
	[ -n "${opts// /}" ] && extra=($opts)
	mkdir -p "$STATE/$name"
	local t0=$(date +%s)
	XDG_DATA_HOME="$STATE/$name" "$GODOT" --headless --path . -s res://tests/op_test.gd -- \
		--weeks="$WEEKS" --seed="$seed" --chief=sensible --rogue "${extra[@]}" --json="$OUT/$name.json" \
		>"$OUT/$name.log" 2>&1
	local rc=$?
	if [ $rc -eq 0 ] && grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$OUT/$name.log"; then rc=1; fi
	printf '  %-6s %-22s %-20s %5ss\n' "$([ $rc -eq 0 ] && echo PASS || echo FAIL)" "$name" "${opts:-(minimal)}" "$(( $(date +%s) - t0 ))"
	echo "$rc" > "$OUT/$name.rc"
}
export -f run_campaign
export GODOT WEEKS OUT STATE
echo "$RUNS" | tr '|' '\n' | grep . | xargs -P "$JOBS" -I{} bash -c 'run_campaign "$@"' _ {}

fail=0
for rcf in "$OUT"/campaign-seed*.rc; do
	[ "$(cat "$rcf")" = "0" ] || fail=1
	rm -f "$rcf"
done

# ---- the rendered walk ---------------------------------------------------------
if [ "$WALK" = 1 ]; then
	w="${RES%x*}"; h="${RES#*x}"
	mkdir -p "$STATE/walk"
	cmd=("$GODOT" --path . --rendering-driver opengl3 --audio-driver Dummy --resolution "$RES" -s res://tests/ui_walk.gd -- --out="$OUT/walk")
	if [ -z "${DISPLAY:-}" ] && [ "$(uname)" = "Linux" ]; then
		if command -v xvfb-run >/dev/null 2>&1; then
			cmd=(xvfb-run -a -s "-screen 0 ${w}x${h}x24" "${cmd[@]}")
		else
			echo "  (no display and no xvfb-run: the walk runs headless, without screenshots)"
			cmd=("$GODOT" --headless --path . -s res://tests/ui_walk.gd -- --out="$OUT/walk")
		fi
	fi
	t0=$(date +%s)
	XDG_DATA_HOME="$STATE/walk" LIBGL_ALWAYS_SOFTWARE="${LIBGL_ALWAYS_SOFTWARE:-1}" "${cmd[@]}" >"$OUT/walk.log" 2>&1
	rc=$?
	if [ $rc -eq 0 ] && grep -qE 'SCRIPT ERROR|Parse Error|^ERROR:' "$OUT/walk.log"; then rc=1; fi
	printf '  %-6s %-22s %-20s %5ss  %s\n' "$([ $rc -eq 0 ] && echo PASS || echo FAIL)" "walk" "$RES" "$(( $(date +%s) - t0 ))" \
		"$(grep -E '^ui_walk:' "$OUT/walk.log" | head -1)"
	grep -E '^WALK (FAIL|KNOWN)' "$OUT/walk.log" | sed 's/^WALK /         /'
	[ $rc -eq 0 ] || fail=1
fi
rm -rf "$STATE"

# ---- the table -------------------------------------------------------------------
shopt -s nullglob
jsons=("$OUT"/campaign-seed*.json)
if [ ${#jsons[@]} -gt 0 ]; then
	{
		echo "# Campaign playtest, $(date +%Y-%m-%d)"
		echo
		echo "Engine: $("$GODOT" --version 2>/dev/null | head -1). $WEEKS weeks per run, roguelike runs, \`--chief=sensible\`, desk answered at random by the harness."
		echo
		python3 tools/campaign_report.py "${jsons[@]}" --csv "$OUT/report.csv" --check || fail=1
		if [ -f "$OUT/walk/walk.json" ]; then
			echo
			echo "Walk ($RES): $(grep -E '^ui_walk:' "$OUT/walk.log" | head -1 | sed "s#$OUT/##")"
			grep -E '^WALK (FAIL|KNOWN)' "$OUT/walk.log" | sed 's/^WALK /- /'
		fi
	} > "$OUT/report.md"
	echo
	cat "$OUT/report.md"
else
	echo "playtest: no run wrote JSON" >&2
	fail=1
fi
exit $fail
