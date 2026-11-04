extends SceneTree
## The run-layer balance harness (EA_TASKS P1.A2). One policy plays one full campaign
## per process; every run gets its own `user://`, so runs cannot see each other's
## legacy file or save. Prints a table and writes the runs out as JSON.
##
##   godot --headless --path . -s res://tests/rogue_balance_test.gd -- --seeds=20 --policy=all
##   ... -- --seeds=3 --policy=cautious,military --weeks=40 --json=build/balance --jobs=4
##   ... -- --smoke                      # 1 seed x 4 policies x 2 weeks, quick tier
##   ... -- --one=1001:cautious --out=...  # internal: one run in this process
##   ... -- --merge=DIR1,DIR2 --json=OUT --seeds=20 --first=1001   # combine shards (no runs)
##
## Options
##   --seeds=N        how many seeds (default 20; seed numbers are 1001, 2002, 3003, ...)
##   --seed=1001      one explicit seed (repeatable as --seeds=1 --first=1001)
##   --first=S        the first seed number (default 1001; the next are +1001 each)
##   --policy=all     all four, or a comma-separated list (cautious, minimal, military, accept_all)
##   --weeks=N        weeks per run (default 40, the whole campaign)
##   --json=DIR       where the per-run JSON, summary.json and report.md go (default build/balance)
##   --jobs=N         concurrent runs (default: min(4, cores))
##   --bands=PATH     the Gate 1 bands (default tests/balance_bands.json)
##   --enforce        miss a band and exit 1; the bands file now asserts by itself
##                    ("enforce": true, P1.I2), so a full matrix misses-and-fails without
##                    the flag. The smoke (2-week shakedown) is never judged by the bands.
##   --report-only    ignore the file and only print the bands (a tuning experiment)
##   --timeout=S      seconds one run may take before it is killed (default 3600; smoke 300)
##   --smoke          the quick-tier shakedown: 1 seed, all policies, 2 weeks
##   --merge=DIRS     combine the run-*.json of shard directories into one report and
##                    summary.json (written to --json); plays nothing. With --seeds and
##                    --first, a seed x policy with no JSON is reported as broken, and so
##                    is anything a shard's own summary.json lists as broken. A GitHub job
##                    stops at 6 hours, so the 20-seed baseline runs as shards (EA_TASKS P1.A4).
##
## Exit: 0 all runs finished and every band held; 1 a run hung, never reached the
## election, wrote no JSON, or a band missed (P1.I2; --report-only for an experiment).

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Recorder = preload("res://scripts/sim/recorder.gd")
const Rogue = preload("res://scripts/campaign/rogue.gd")
const Policies = preload("res://tests/policies.gd")

const BANDS_PATH := "res://tests/balance_bands.json"
const SEED_STEP := 1001      # 1001, 2002, 3003 ... the playtest's own seed family
const GUARD_STEPS := 40000   # the step guard op_test uses: past this an operation is hung
const DEFAULT_SEEDS := 20

## The metrics the summary and the bands read, in report order. "kept" is a share.
const METRICS := [
	["min_fit", "lowest fit officers", "count"],
	["weeks_fit_below_12", "weeks under 12 fit", "weeks"],
	["weeks_below_zero", "weeks below $0", "weeks"],
	["weeks_below_zero_1_12", "weeks below $0 (1-12)", "weeks"],
	["balance_end", "account at week 40", "$"],
	["balance_min", "lowest account", "$"],
	["balance_max", "highest account", "$"],
	["unattended", "situations unattended", "count"],
	["officers_killed", "officers killed", "count"],
	["officers_killed_per_op", "killed per operation", "rate"],
	["civ_killed", "civilians killed", "count"],
	["findings", "findings", "count"],
	["allies_lost_end", "allies lost at the end", "of 4"],
	["allies_regained", "allies won back", "count"],
	["run_score", "run score", "score"],
	["kept_share", "chief kept", "share"],
]

var failures: Array = []


func _init() -> void:
	var args := _args()
	if args.has("one"):
		quit(_child(args))
		return
	quit(_parent(args))


static func _args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := String(a).trim_prefix("--").split("=")
		out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out


# ================================================================== one run
## Play one campaign under one policy. Returns the run record the summary is built from.
func play_run(seed_v: int, policy: String, weeks_wanted: int) -> Dictionary:
	var t0 := Time.get_ticks_msec()
	var c = Campaign.new()
	c.start(seed_v, true, "user://legacy_balance.json")
	var weeks: Array = []
	var hung := 0
	var ops_ran := 0
	var tot_killed := 0
	var tot_down := 0
	var tot_score := 0
	var tot_findings := 0
	var desk_lines: Array = []
	var op_log: Array = []      # one row per operation (EA_TASKS P1.C1)
	while not c.over() and c.dept.week <= weeks_wanted:
		var op_lines: Array = []   # ally lines from this week's operations (before end_week)
		var wk: int = int(c.dept.week)
		# 1. the desk, before the first operation (P1.A1: the interface's order)
		desk_lines.append_array(Policies.settle_desk(c, policy))
		# 2. the department's standing orders: findings, courses, hiring
		Policies.ia(c, policy)
		Policies.training(c, policy)
		Policies.hiring(c, policy)
		# 3. the week's calls
		for s in Policies.call_plan(c, policy):
			if String(s["status"]) != "open":
				continue
			var av: Array = c.available_for(s["id"])
			if av.is_empty():
				continue
			var lv = Maps.get_level(int(s["map"]))
			var nav = Nav.new()
			nav.build(lv)
			var plan: Dictionary = Autoplan.suggest(s, av, lv, false, Autoplan.share(c.board, s["id"], av.size()),
				Policies.issues_kit(policy))
			c.dept.settle_kits()
			s["plan"] = plan
			# P1.C5: a policy that does not buy kit itself takes or declines the kit Suggest
			# a plan proposes, the way the Force tab offers it (bought at Run)
			if not Policies.issues_kit(policy):
				plan["kit"] = Autoplan.propose_kit(s, plan, av)
				plan["kit_mode"] = "suggested" if Policies.takes_suggested_kit(policy) else "own"
				c.issue_plan_kit(s)
			if Campaign.plan_members(s).is_empty():
				s["plan"] = {}
				continue
			var b: Dictionary = Operation.build_planned(s, plan, c.dept, lv, nav)
			var w = World.new()
			w.setup(lv, nav, b["cfgs"], b["postures"], b["seed"], b["alerts"], b["opts"])
			w.recorder = Recorder.new(w)
			var guard := 0
			while not w.over and guard < GUARD_STEPS:
				w.step()
				w.events.clear()
				guard += 1
			if not w.over:
				hung += 1
			var res: Dictionary = Outcome.evaluate(s, w)
			var summary: Dictionary = w.incident.summary()
			tot_score += int(res.get("score", 0))
			tot_findings += int(res.get("findings", 0))
			tot_killed += int(summary["officers_killed"])
			tot_down += int(summary["officers_down"])
			ops_ran += 1
			for ln in c.dept.apply_result(w, lv.map_name):
				if _ally_line(ln):
					op_lines.append(String(ln))
			for ln2 in c.after_operation(s["id"], res, w):
				if _ally_line(ln2):
					op_lines.append(String(ln2))
			c.record(s["id"], res)
			op_log.append(_op_row(wk, s, lv, w, res, summary))
			w.dispose()
		# 4. the week closes: payroll, allocation, consequences, the next board
		var end_lines: Array = c.end_week()
		var wk_lines: Array = op_lines.duplicate()
		for ln in end_lines:
			if _ally_line(ln):
				wk_lines.append(String(ln))
		var allies := {}
		for a in c.politics.ALLY_ORDER:
			allies[a] = {"standing": int(c.politics.standing(a)), "lost": bool(c.politics.lost(a))}
		weeks.append({
			"week": wk, "balance": int(c.dept.balance), "morale": int(c.dept.morale),
			"fit": int(c.dept.available().size()),
			"academy": c.dept.officers.filter(func(r): return String(r["status"]) == "academy").size(),
			"injured": c.dept.officers.filter(func(r): return String(r["status"]) == "injured").size(),
			"dead_total": c.dept.officers.filter(func(r): return String(r["status"]) == "dead").size(),
			"open_cases": int(c.dept.open_cases().size()),
			"trust": snappedf(float(c.politics.avg_trust()), 0.1),
			"allies": allies,
			"polls": {"kettering": snappedf(float(c.politics.share("kettering")), 0.1),
				"okonjo": snappedf(float(c.politics.share("okonjo")), 0.1),
				"pell": snappedf(float(c.politics.share("pell")), 0.1)},
			"lines": wk_lines,
		})
	var out := {
		"version": 1, "seed": seed_v, "policy": policy, "policy_label": Policies.label(policy),
		"engine": Engine.get_version_info()["string"], "weeks_asked": weeks_wanted,
		"weeks_played": weeks.size(), "wall_ms": Time.get_ticks_msec() - t0,
		"ops": ops_ran, "hung": hung, "findings": tot_findings,
		"officers_killed_per_op": snappedf(float(tot_killed) / maxf(1.0, float(ops_ran)), 0.01),
		"officers_down_per_op": snappedf(float(tot_down) / maxf(1.0, float(ops_ran)), 0.01),
		"mean_op_score": tot_score / maxi(1, ops_ran),
		"record": c.politics.record.duplicate(), "election": {}, "run_score": {},
		"desk": desk_lines.size(), "weeks": weeks, "op_log": op_log,
	}
	if c.over():
		var e: Dictionary = c.politics.result["ending"]
		out["election"] = {"winner": String(e["winner"]), "kept": bool(e["keep"]),
			"votes": c.politics.result["votes"], "head": String(e["head"])}
		out["run_score"] = Rogue.run_score(c)
	return out


## Every operation of every run, one line each (EA_TASKS P1.C1), small enough to commit
## with the report: the per-run JSON is only the CI run's artifact. (Numbers read back
## from JSON are floats; whole ones are written as integers.)
const OPS_COLS := ["seed", "policy", "week", "type", "map", "map_name", "officers", "down", "killed",
	"killed_by_suspect", "killed_by_friendly", "bled_out", "suspects", "suspects_killed", "civ_killed",
	"kind", "score", "sim_s", "ended"]


func _ops_csv(runs: Array) -> String:
	var out: PackedStringArray = [",".join(OPS_COLS)]
	var sorted_runs := runs.duplicate()
	sorted_runs.sort_custom(func(a, b): return [int(a["seed"]), String(a["policy"])] < [int(b["seed"]), String(b["policy"])])
	for r in sorted_runs:
		for o in r.get("op_log", []):
			var kb: Dictionary = o["killed_by"]
			var row := [int(r["seed"]), String(r["policy"]), o["week"], o["type"], o["map"],
				"\"%s\"" % String(o["map_name"]).replace("\"", "'"), o["officers"], o["down"], o["killed"],
				kb["suspect"], kb["friendly"], kb["bled_out"], o["suspects"], o["suspects_killed"], o["civ_killed"],
				o["kind"], o["score"], o["sim_s"], 1 if o["ended"] else 0]
			out.append(",".join(row.map(func(x): return str(int(x)) if (x is float and x == floorf(x)) else str(x))))
	return "\n".join(out) + "\n"


## Every run's week-end roster and account, one line a week (EA_TASKS P1.C1: injury weeks
## lost, academy throughput, the fit curve).
const WEEK_COLS := ["seed", "policy", "week", "fit", "injured", "academy", "dead_total", "balance", "morale"]

## EA_TASKS P1.E1: every run-week's ally standings and lost flags, one line a week —
## the cause log itself (politics.ally_log) rides in the run JSON's record.
const ALLY_COLS := ["seed", "policy", "week", "ally", "standing", "lost"]


func _allies_csv(runs: Array) -> String:
	var out: PackedStringArray = [",".join(ALLY_COLS)]
	var sorted_runs := runs.duplicate()
	sorted_runs.sort_custom(func(a, b): return [int(a["seed"]), String(a["policy"])] < [int(b["seed"]), String(b["policy"])])
	for r in sorted_runs:
		for wk in r.get("weeks", []):
			var allies: Dictionary = wk.get("allies", {})
			for a in allies:
				out.append(",".join([int(r["seed"]), String(r["policy"]), int(wk["week"]), String(a),
					int(allies[a].get("standing", 0)), "1" if bool(allies[a].get("lost", false)) else "0"]))
	return "\n".join(out) + "\n"


func _weeks_csv(runs: Array) -> String:
	var out: PackedStringArray = [",".join(WEEK_COLS)]
	var sorted_runs := runs.duplicate()
	sorted_runs.sort_custom(func(a, b): return [int(a["seed"]), String(a["policy"])] < [int(b["seed"]), String(b["policy"])])
	for r in sorted_runs:
		for wk in r.get("weeks", []):
			out.append(",".join([int(r["seed"]), String(r["policy"]), int(wk["week"]), int(wk["fit"]), int(wk["injured"]),
				int(wk["academy"]), int(wk["dead_total"]), int(wk["balance"]), int(wk["morale"])].map(func(x): return str(x))))
	return "\n".join(out) + "\n"


## One operation for the roster-bleed measurement (EA_TASKS P1.C1): what it was, where,
## how many went, who went down and how (killed by a suspect, by a colleague, or bled out
## with nobody named), and how it ended.
func _op_row(wk: int, s: Dictionary, lv, w, res: Dictionary, summary: Dictionary) -> Dictionary:
	var by_cause := {"suspect": 0, "friendly": 0, "bled_out": 0}
	var down_cause := {"suspect": 0, "friendly": 0, "other": 0}
	var police := {}
	for o in w.ops:
		if o.judges:
			police[o.id] = true
	for f in w.incident.findings:
		var kind := String(f["kind"])
		if kind != "officer_killed" and kind != "officer_down":
			continue
		var by := String(f["by"])
		var cause := "bled_out" if by == "" else ("friendly" if police.has(by) else "suspect")
		if kind == "officer_killed":
			by_cause[cause] += 1
		else:
			down_cause["other" if cause == "bled_out" else cause] += 1
	return {"week": wk, "type": String(s["type"]), "map": int(s["map"]), "map_name": String(lv.map_name),
		"officers": int(summary["officers"]), "down": int(summary["officers_down"]),
		"killed": int(summary["officers_killed"]), "killed_by": by_cause, "down_by": down_cause,
		"suspects": int(summary["suspects"]), "suspects_killed": int(summary["suspects_killed"]),
		"civ_killed": int(summary["civ_killed"]), "kind": String(res.get("kind", "")),
		"score": int(res.get("score", 0)), "sim_s": snappedf(float(w.t), 0.1), "ended": bool(w.over)}


func _child(args: Dictionary) -> int:
	var parts := String(args["one"]).split(":")
	if parts.size() != 2 or not Policies.has(parts[1]):
		print("rogue_balance: --one wants SEED:POLICY, got '%s'" % args["one"])
		return 2
	var seed_v := int(parts[0])
	var policy := String(parts[1])
	var weeks := int(args.get("weeks", "40"))
	var run: Dictionary = play_run(seed_v, policy, weeks)
	var out_path := String(args.get("out", ""))
	if out_path != "":
		_write_json(out_path, run)
	var d: Dictionary = derive(run)
	print("RUN seed=%d policy=%s ops=%d kept=%s score=%d min_fit=%d below0=%d unattended=%d wall_ms=%d" % [
		seed_v, policy, int(run["ops"]), str(bool(d["kept"])), int(d["run_score"]), int(d["min_fit"]),
		int(d["weeks_below_zero"]), int(d["unattended"]), int(run["wall_ms"])])
	# A run that hung an operation, wrote no JSON, or never held its election is broken.
	var broken: Array = breakage(run, weeks)
	if not broken.is_empty():
		print("rogue_balance: BROKEN %s" % "; ".join(broken))
		return 1
	return 0


# ================================================================== the matrix
func _parent(args: Dictionary) -> int:
	if args.has("merge"):
		return _merge(args)
	var smoke := args.has("smoke")
	var policy_list: Array = Policies.parse(String(args.get("policy", "all")))
	if policy_list.is_empty():
		print("rogue_balance: no known policy in --policy=%s (have: %s)" % [args.get("policy", ""), ", ".join(Policies.all())])
		return 2
	var n_seeds := 1 if smoke else int(args.get("seeds", str(DEFAULT_SEEDS)))
	var first := int(args.get("first", "1001"))
	var weeks := int(args.get("weeks", "2" if smoke else "40"))
	var out_dir := String(args.get("json", "build/balance-smoke" if smoke else "build/balance"))
	if not out_dir.is_absolute_path():
		out_dir = ProjectSettings.globalize_path("res://").path_join(out_dir)
	var jobs := int(args.get("jobs", "0"))
	if jobs <= 0:
		jobs = clampi(OS.get_processor_count(), 1, 4)
	var timeout_s := int(args.get("timeout", "300" if smoke else "3600"))
	var bands_path := String(args.get("bands", BANDS_PATH))
	# P1.I2: the bands assert. The file decides (balance_bands.json "enforce"), the smoke
	# never does, and --report-only / --enforce override for one experiment.
	var bands_file: Dictionary = _load_bands(bands_path)
	var enforce := args.has("enforce") or (not smoke and bool(bands_file.get("enforce", false)))
	if args.has("report-only"):
		enforce = false
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)

	var jobs_list: Array = []
	for i in n_seeds:
		var seed_v := first + i * SEED_STEP
		for pol in policy_list:
			jobs_list.append({"seed": seed_v, "policy": String(pol),
				"out": "%s/run-%d-%s.json" % [out_dir, seed_v, String(pol)]})
	print("rogue_balance: %d run(s) — %d seed(s) x %d policy(ies), %d weeks, %d at a time -> %s" % [
		jobs_list.size(), n_seeds, policy_list.size(), weeks, jobs, out_dir])

	var t0 := Time.get_ticks_msec()
	var exe := OS.get_executable_path()
	var project := ProjectSettings.globalize_path("res://")
	var xdg_prev := OS.get_environment("XDG_DATA_HOME")
	var appdata_prev := OS.get_environment("APPDATA")
	var pending: Array = jobs_list.duplicate()
	var running: Array = []   # [{pid, job, started}]
	var broken: Array = []
	var done := 0
	while not pending.is_empty() or not running.is_empty():
		while running.size() < jobs and not pending.is_empty():
			var job: Dictionary = pending.pop_front()
			var home := "%s/user/%d-%s" % [out_dir, int(job["seed"]), String(job["policy"])]
			if not DirAccess.dir_exists_absolute(home):
				DirAccess.make_dir_recursive_absolute(home)
			# One user:// per run: no shared save, no shared legacy file.
			OS.set_environment("XDG_DATA_HOME", home)
			OS.set_environment("APPDATA", home)
			var cli := PackedStringArray(["--headless", "--path", project, "-s", "res://tests/rogue_balance_test.gd", "--",
				"--one=%d:%s" % [int(job["seed"]), String(job["policy"])],
				"--weeks=%d" % weeks, "--out=%s" % String(job["out"])])
			var pid := OS.create_process(exe, cli, false)
			if pid <= 0:
				broken.append("could not start seed %d %s" % [int(job["seed"]), String(job["policy"])])
				continue
			running.append({"pid": pid, "job": job, "started": Time.get_ticks_msec()})
		if xdg_prev == "":
			OS.unset_environment("XDG_DATA_HOME")
		else:
			OS.set_environment("XDG_DATA_HOME", xdg_prev)
		if appdata_prev == "":
			OS.unset_environment("APPDATA")
		else:
			OS.set_environment("APPDATA", appdata_prev)
		OS.delay_msec(250)
		var keep: Array = []
		for r in running:
			var pid2: int = int(r["pid"])
			if OS.is_process_running(pid2):
				if (Time.get_ticks_msec() - int(r["started"])) / 1000 > timeout_s:
					OS.kill(pid2)
					broken.append("seed %d %s timed out after %d s" % [int(r["job"]["seed"]), String(r["job"]["policy"]), timeout_s])
					continue
				keep.append(r)
				continue
			done += 1
			var code: int = OS.get_process_exit_code(pid2)
			var path := String(r["job"]["out"])
			if not FileAccess.file_exists(path):
				broken.append("seed %d %s wrote no JSON (exit %d)" % [int(r["job"]["seed"]), String(r["job"]["policy"]), code])
			elif code != 0:
				broken.append("seed %d %s exited %d" % [int(r["job"]["seed"]), String(r["job"]["policy"]), code])
		running = keep
	if OS.get_environment("XDG_DATA_HOME") != xdg_prev and xdg_prev != "":
		OS.set_environment("XDG_DATA_HOME", xdg_prev)

	var runs: Array = []
	for job2 in jobs_list:
		var path2 := String(job2["out"])
		if not FileAccess.file_exists(path2):
			continue
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(path2))
		if not (parsed is Dictionary):
			broken.append("seed %d %s: unreadable JSON" % [int(job2["seed"]), String(job2["policy"])])
			continue
		runs.append(parsed)
	return _finish(runs, broken, policy_list, weeks, n_seeds, Time.get_ticks_msec() - t0, out_dir,
		bands_path, enforce, done)


## Everything after the runs: breakage, bands, the report and summary.json, the exit code.
## Shared by a matrix that played its runs and by --merge, so a merged report and a
## single-process report of the same runs are the same document.
func _finish(runs: Array, broken: Array, policy_list: Array, weeks: int, n_seeds: int, wall: int,
		out_dir: String, bands_path: String, enforce: bool, done: int) -> int:
	for r2 in runs:
		var why: Array = breakage(r2, weeks)
		for w2 in why:
			broken.append("seed %d %s: %s" % [int(r2["seed"]), String(r2["policy"]), w2])

	var by_policy := {}
	for pol2 in policy_list:
		by_policy[String(pol2)] = []
	for r3 in runs:
		by_policy[String(r3["policy"])].append(derive(r3))

	var band_lines: Array = []
	var bands: Dictionary = _load_bands(bands_path)
	var misses := 0
	if not bands.is_empty() and not by_policy.is_empty():
		var res: Dictionary = _check_bands(bands, by_policy, policy_list)
		band_lines = res["lines"]
		misses = int(res["misses"])

	var report := _report(by_policy, policy_list, weeks, n_seeds, runs.size(), wall, band_lines, bands, misses, enforce, broken)
	_write_text("%s/report.md" % out_dir, report)
	_write_json("%s/summary.json" % out_dir, {
		"version": 1, "weeks": weeks, "seeds": n_seeds, "policies": policy_list,
		"runs": runs.size(), "wall_ms": wall, "engine": Engine.get_version_info()["string"],
		"bands": bands.get("bands", []), "band_status": String(bands.get("status", "report-only")),
		"misses": misses, "broken": broken,
		"derived": by_policy,
	})
	_write_text("%s/ops.csv" % out_dir, _ops_csv(runs))
	_write_text("%s/weeks.csv" % out_dir, _weeks_csv(runs))
	_write_text("%s/allies.csv" % out_dir, _allies_csv(runs))
	print(report)
	print("rogue_balance: %d run(s) in %d s, %d broken, %d band miss(es) -> %s" % [
		runs.size(), int(wall / 1000), broken.size(), misses, out_dir])
	if not broken.is_empty():
		return 1
	if enforce and misses > 0:
		return 1
	# A matrix that produced nothing is a failure, not a quiet zero.
	if runs.is_empty() or done == 0:
		return 1
	return 0


## --merge: the runs of several shard directories as one matrix (EA_TASKS P1.A4).
func _merge(args: Dictionary) -> int:
	var dirs: Array = String(args["merge"]).split(",", false)
	var out_dir := String(args.get("json", "build/balance"))
	if not out_dir.is_absolute_path():
		out_dir = ProjectSettings.globalize_path("res://").path_join(out_dir)
	if not DirAccess.dir_exists_absolute(out_dir):
		DirAccess.make_dir_recursive_absolute(out_dir)
	var weeks := int(args.get("weeks", "40"))
	var runs: Array = []
	var broken: Array = []
	var seen := {}
	var wall := 0
	for d in dirs:
		var dir := String(d)
		if not dir.is_absolute_path():
			dir = ProjectSettings.globalize_path("res://").path_join(dir)
		var da := DirAccess.open(dir)
		if da == null:
			broken.append("shard %s: no such directory" % dir)
			continue
		# what the shard itself knew went wrong (a run that timed out left no JSON)
		if FileAccess.file_exists(dir.path_join("summary.json")):
			var sm = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join("summary.json")))
			if sm is Dictionary:
				wall = maxi(wall, int(sm.get("wall_ms", 0)))   # shards run side by side
				for b in sm.get("broken", []):
					broken.append("shard %s: %s" % [dir.get_file(), String(b)])
		for f in da.get_files():
			if not (f.begins_with("run-") and f.ends_with(".json")):
				continue
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
			if not (parsed is Dictionary) or not parsed.has("seed") or not parsed.has("policy"):
				broken.append("shard %s: %s is unreadable" % [dir.get_file(), f])
				continue
			var key := "%d:%s" % [int(parsed["seed"]), String(parsed["policy"])]
			if seen.has(key):
				broken.append("seed %d %s appears in two shards" % [int(parsed["seed"]), String(parsed["policy"])])
				continue
			seen[key] = true
			runs.append(parsed)
	var policy_list: Array = []
	var wanted: Array = Policies.parse(String(args.get("policy", "all")))
	for pol in wanted:
		if runs.any(func(r): return String(r["policy"]) == String(pol)) or args.has("seeds"):
			policy_list.append(String(pol))
	var seeds := {}
	for r in runs:
		seeds[int(r["seed"])] = true
	var n_seeds := seeds.size()
	if args.has("seeds"):
		# the matrix that was asked for: every seed x policy must be there
		n_seeds = int(args["seeds"])
		var first := int(args.get("first", "1001"))
		for i in n_seeds:
			for pol2 in policy_list:
				var key2 := "%d:%s" % [first + i * SEED_STEP, String(pol2)]
				if not seen.has(key2):
					broken.append("seed %d %s: no run in any shard" % [first + i * SEED_STEP, String(pol2)])
	runs.sort_custom(func(a, b): return int(a["seed"]) * 10 + policy_list.find(String(a["policy"])) < int(b["seed"]) * 10 + policy_list.find(String(b["policy"])))
	print("rogue_balance: merging %d run(s) from %d shard(s) -> %s" % [runs.size(), dirs.size(), out_dir])
	return _finish(runs, broken, policy_list, weeks, n_seeds, wall, out_dir,
		String(args.get("bands", BANDS_PATH)), args.has("enforce"), runs.size())


# ================================================================== derived numbers
## The comparable numbers of one run: roster, money, allies, election, score. The same
## definitions tools/campaign_report.py uses, so a balance cell and a playtest cell mean
## the same thing.
func derive(run: Dictionary) -> Dictionary:
	var w: Array = run.get("weeks", [])
	var fits: Array = []
	var bal: Array = []
	var first_lost := {}
	var lost_end := 0
	var regained := 0
	var below0 := 0
	var below0_early := 0
	var out: Dictionary = {}
	for x in w:
		fits.append(int(x["fit"]))
		bal.append(int(x["balance"]))
		if int(x["balance"]) < 0:
			below0 += 1
			if int(x["week"]) <= 12:
				below0_early += 1
		for ln in x.get("lines", []):
			if String(ln).begins_with("LOST:"):
				for nm in _LOST_NAMES:
					if String(ln).find(nm) >= 0 and not first_lost.has(_LOST_NAMES[nm]):
						first_lost[_LOST_NAMES[nm]] = int(x["week"])
			elif String(ln).begins_with("Won back"):
				regained += 1
		for a in x.get("allies", {}):
			if bool(x["allies"][a].get("lost", false)) and not first_lost.has(a):
				first_lost[a] = int(x["week"])
	if not w.is_empty():
		var last: Dictionary = w[w.size() - 1]
		for a2 in last.get("allies", {}):
			if bool(last["allies"][a2].get("lost", false)):
				lost_end += 1
	var min_fit := 0
	var min_fit_week := 0
	if not fits.is_empty():
		min_fit = int(fits[0])
		for i in fits.size():
			if int(fits[i]) < min_fit:
				min_fit = int(fits[i])
				min_fit_week = int(w[i]["week"])
	var rec: Dictionary = run.get("record", {})
	var election: Dictionary = run.get("election", {})
	var score: Dictionary = run.get("run_score", {})
	out = {
		"seed": int(run.get("seed", 0)), "policy": String(run.get("policy", "")),
		"weeks": w.size(), "ops": int(run.get("ops", 0)), "hung": int(run.get("hung", 0)),
		"min_fit": min_fit, "min_fit_week": min_fit_week,
		"weeks_fit_below_12": fits.filter(func(f): return int(f) < 12).size(),
		"weeks_below_zero": below0, "weeks_below_zero_1_12": below0_early,
		"balance_min": 0 if bal.is_empty() else int(bal.min()), "balance_max": 0 if bal.is_empty() else int(bal.max()),
		"balance_end": 0 if bal.is_empty() else int(bal[bal.size() - 1]),
		"unattended": int(rec.get("unattended", 0)),
		"officers_killed": int(rec.get("officers_killed", 0)),
		"officers_killed_per_op": float(run.get("officers_killed_per_op", 0.0)),
		"civ_killed": int(rec.get("civ_killed", 0)) + int(rec.get("crowd_killed", 0)),
		"findings": int(run.get("findings", 0)),
		"successes": int(rec.get("successes", 0)), "failures": int(rec.get("failures", 0)),
		"allies_lost_end": lost_end, "allies_regained": regained, "allies_first_lost": first_lost,
		"run_score": int(score.get("total", 0)), "kept": bool(election.get("kept", false)),
		"winner": String(election.get("winner", "")), "wall_ms": int(run.get("wall_ms", 0)),
	}
	# EA_TASKS P1.D4.f: minimal must no longer end with an unspent six-figure account
	# (smoke check here; the full rebalancing is P1.D5).
	if String(run.get("policy", "")) == "minimal" and int(out["balance_end"]) >= 100000:
		failures.append("seed %d minimal ended with $%d unspent (P1.D4.f)" % [int(run.get("seed", 0)), int(out["balance_end"])])
	return out


const _LOST_NAMES := {"Marguerite Duff": "council", "Tommy Rourke": "union",
	"Rev. Alma Mbeki-Shaw": "coalition", "Paul Varga": "da"}


## A run is broken if it hung an operation or never held its election at 40 weeks.
func breakage(run: Dictionary, weeks_asked: int) -> Array:
	var why: Array = []
	if int(run.get("hung", 0)) > 0:
		why.append("%d operation(s) hung" % int(run["hung"]))
	if weeks_asked >= 40 and (run.get("election", {}) as Dictionary).is_empty():
		why.append("never reached the election")
	if (run.get("weeks", []) as Array).is_empty():
		why.append("no week snapshots")
	return why


static func _ally_line(ln) -> bool:
	var t := String(ln)
	return t.begins_with("LOST:") or t.begins_with("Won back:")


# ================================================================== the bands
func _load_bands(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("rogue_balance: no bands file at %s (reporting only)" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Evaluate every band for every policy it applies to. Returns the report lines and how
## many bands missed. Report-only until balance_bands.json says enforce: true (P1.I).
func _check_bands(bands: Dictionary, by_policy: Dictionary, policy_list: Array) -> Dictionary:
	var lines: Array = []
	var misses := 0
	for band in bands.get("bands", []):
		var metric := String(band.get("metric", ""))
		var agg := String(band.get("agg", "mean"))
		var test := String(band.get("test", ">="))
		var limit := float(band.get("value", 0.0))
		var scope: Array = band.get("policies", ["all"])
		for pol in policy_list:
			if not (scope.has("all") or scope.has(String(pol))):
				continue
			var rows: Array = by_policy.get(String(pol), [])
			if rows.is_empty():
				continue
			var got: float = _agg(rows, metric, agg)
			var ok := _pass(got, test, limit)
			if not ok:
				misses += 1
			lines.append("%s %-26s %-12s %s %s  (got %s)" % [
				"ok  " if ok else "MISS", String(band.get("id", metric)), String(pol), test,
				_num(limit), _num(got)])
	return {"lines": lines, "misses": misses}


func _agg(rows: Array, metric: String, how: String) -> float:
	var vals: Array = []
	for r in rows:
		if r.has(metric):
			vals.append(float(r[metric]))
	if metric == "kept_share":
		var kept := 0
		for r2 in rows:
			if bool(r2.get("kept", false)):
				kept += 1
		return float(kept) / maxf(1.0, float(rows.size()))
	if vals.is_empty():
		return 0.0
	match how:
		"min":
			return float(vals.min())
		"max":
			return float(vals.max())
	return float(vals.reduce(func(a, b): return float(a) + float(b), 0.0)) / float(vals.size())


static func _pass(got: float, test: String, limit: float) -> bool:
	match test:
		">=":
			return got >= limit
		">":
			return got > limit
		"<=":
			return got <= limit
		"<":
			return got < limit
		"==":
			return is_equal_approx(got, limit)
	return true


static func _num(v: float) -> String:
	if is_equal_approx(v, round(v)):
		return "%d" % int(round(v))
	return "%.2f" % v


func _report(by_policy: Dictionary, policy_list: Array, weeks: int, seeds: int, runs: int,
		wall_ms: int, band_lines: Array, bands: Dictionary, misses: int, enforce: bool,
		broken: Array) -> String:
	var out: Array = []
	out.append("# Run-layer balance — %d seed(s) × %d policy(ies), %d weeks" % [seeds, policy_list.size(), weeks])
	out.append("")
	out.append("%d run(s), %d s wall clock, %s." % [runs, int(wall_ms / 1000), Engine.get_version_info()["string"]])
	out.append("")
	var head := "| metric | " + " | ".join(policy_list.map(func(p): return Policies.label(String(p)))) + " |"
	out.append(head)
	out.append("|---|" + "---|".repeat(policy_list.size()))
	for m in METRICS:
		var key := String(m[0])
		var cells: Array = []
		for pol in policy_list:
			var rows: Array = by_policy.get(String(pol), [])
			if rows.is_empty():
				cells.append("—")
			elif key == "kept_share":
				var kept := 0
				for r in rows:
					if bool(r.get("kept", false)):
						kept += 1
				cells.append("%d/%d" % [kept, rows.size()])
			else:
				var vals: Array = []
				for r2 in rows:
					if r2.has(key):
						vals.append(float(r2[key]))
				if vals.is_empty():
					cells.append("—")
					continue
				var mean: float = vals.reduce(func(a, b): return float(a) + float(b), 0.0) / float(vals.size())
				cells.append("%s [%s–%s]" % [_num(mean), _num(float(vals.min())), _num(float(vals.max()))])
		out.append("| %s | " % String(m[1]) + " | ".join(cells) + " |")
	out.append("")
	if not band_lines.is_empty():
		out.append("## Gate 1 bands — %s" % String(bands.get("status", "report-only")))
		out.append("")
		out.append("```")
		out.append_array(band_lines)
		out.append("```")
		out.append("")
		out.append("%d band miss(es); %s." % [misses,
			"the tier fails on them (--enforce)" if enforce else "report-only until P1.I (balance_bands.json \"enforce\")"])
		out.append("")
	if not broken.is_empty():
		out.append("## Broken runs")
		out.append("")
		for b in broken:
			out.append("- %s" % String(b))
		out.append("")
	out.append("## What each policy does")
	out.append("")
	for pol3 in policy_list:
		out.append("- **%s** — %s" % [Policies.label(String(pol3)), Policies.describe(String(pol3))])
	return "\n".join(out)


# ================================================================== files
func _write_json(path: String, data) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("rogue_balance: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data, "  "))
	f.close()


func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("rogue_balance: cannot write %s" % path)
		return
	f.store_string(text)
	f.close()
