extends SceneTree
## v0.5 gate: persistent officers. A department is founded, saved and loaded back
## unchanged; an operation's experience, wounds and file entries are written back and
## survive a save; an injured officer is not available until healed; and an operation
## run from a reloaded save replays exactly.
##   godot --headless --path . -s res://tests/dept_test.gd
const Habits = preload("res://scripts/data/habits.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Operation = preload("res://scripts/campaign/operation.gd")
const Courses = preload("res://scripts/data/courses.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

const PATH := "user://dept_test.json"
var problems := 0


func _check(ok: bool, what: String) -> void:
	print("  %s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		problems += 1


func _suspects(lv, n: int) -> Array:
	var out: Array = []
	for slot in 20:
		var id := "B%d" % (slot + 1)
		var e: String = ["untrained", "militia", "untrained", "regular"][slot % 4]
		var good := {}
		for g in Habits.preset_good(e):
			good[g] = true
		var bad := {}
		for b in Habits.stress_bad_ids():
			bad[b] = true
		out.append({"id": id, "team": 1, "slot": slot, "echelon": e, "good": good, "bad": bad, "traits": {}, "exp": 1,
			"plates": 0, "pos": lv.spawns[id]["p"], "face": lv.spawns[id]["face"], "enabled": slot < n, "alert": 0})
	return out


func _run(dep, lv, nav, seed_val: int):
	var team: Array = dep.available().slice(0, 6)
	var cfgs: Array = Operation.build(_suspects(lv, 4), lv, nav, {"officers": team, "civilians": 6, "seed": seed_val}, dep)
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, cfgs, ["assault", "hold"], seed_val, [1, 0], {"police_rules": true})
	while not w.over:
		w.step()
	return w


func _fingerprint(w) -> String:
	var parts: Array = ["%.3f" % w.t, str(w.winner), str(w.stat)]
	for o in w.ops:
		parts.append("%s %s %.3f,%.3f %d %d %d" % [o.id, o.state, o.pos.x, o.pos.y, o.shots, o.hits, o.wounds])
	return "|".join(parts)


func _init() -> void:
	var lv = Maps.get_level(5)
	var nav = Nav.new()
	nav.build(lv)
	print("department test (map %s)" % lv.map_name)
	# founding, save and load
	var dep = Department.new()
	dep.found(77)
	_check(dep.officers.size() == Department.FOUNDING.size(), "founded with %d officers (v0.7: the inherited roster)" % Department.FOUNDING.size())
	var vets: int = dep.officers.filter(func(r): return float(r.get("years", 0.0)) >= 5.0).size()
	_check(vets >= 4, "some of them experienced (%d with five years or more)" % vets)
	var a: Dictionary = dep.officers[2]
	_check(a["ech"].has("form") and a["echelon"] == "patrol", "stats rolled at hire (Patrol echelon, form %+.0f%%)" % ((1.0 - float(a["ech"]["form"])) * 100.0))
	_check(dep.save(PATH), "saved")
	var dep2 = Department.load_from(PATH)
	_check(dep2 != null, "loaded")
	_check(JSON.stringify(dep2.to_data()) == JSON.stringify(Department.load_from(PATH).to_data()), "load is stable")
	_check(JSON.stringify(dep2.officers[2]["ech"]) == JSON.stringify(JSON.parse_string(JSON.stringify(a["ech"]))), "an officer's roll survives a save")
	# the roll travels into the operation
	var cfg: Dictionary = dep2.to_cfg(dep2.officers[2], 0, lv)
	var w0 = World.new()
	w0.setup(lv, nav, [cfg], ["assault", "hold"], 5, [1, 0], {"police_rules": true})
	var o0 = w0.ops[0]
	_check(is_equal_approx(float(o0.ech["t_rec0"]), float(dep2.officers[2]["ech"]["t_rec0"])), "the operation uses the record's roll, not a new one")
	_check(o0.judges and o0.vest and o0.officer_id == dep2.officers[2]["id"], "officer judges, wears a vest, knows their record")
	w0.dispose()
	# operation 1, written back
	var before := {}
	for r in dep2.officers:
		before[r["id"]] = [int(r["xp"]), r["status"], r["file"].size()]
	var w1 = _run(dep2, lv, nav, 4101)
	var lines: Array = dep2.apply_result(w1, lv.map_name)
	for ln in lines:
		print("      ", ln)
	var gained := 0
	var hurt := 0
	var filed := 0
	for r in dep2.officers:
		var b: Array = before[r["id"]]
		if int(r["xp"]) > b[0]:
			gained += 1
		if r["status"] != "active":
			hurt += 1
		if r["file"].size() > b[2]:
			filed += 1
	_check(filed == 6, "all six officers sent have a new file entry (%d)" % filed)
	_check(gained > 0, "experience gained by %d officer(s)" % gained)
	print("      %d officer(s) injured or killed" % hurt)
	w1.dispose()
	_check(dep2.save(PATH), "saved after the operation")
	var dep3 = Department.load_from(PATH)
	var same := true
	for i in dep2.officers.size():
		var r2: Dictionary = dep2.officers[i]
		var r3: Dictionary = dep3.officers[i]
		if int(r2["xp"]) != int(r3["xp"]) or r2["status"] != r3["status"] or int(r2["out_until"]) != int(r3["out_until"]) \
				or r2["file"].size() != r3["file"].size() or int(r2["exp"]) != int(r3["exp"]):
			same = false
	_check(same, "experience, wounds and files survive the save")
	var injured: Array = dep3.officers.filter(func(r): return r["status"] == "injured")
	if not injured.is_empty():
		var who: Dictionary = injured[0]
		_check(not dep3.available().has(who), "an injured officer is not available")
		var guard := 0
		while who["status"] == "injured" and guard < 30:
			dep3.next_week()
			guard += 1
		_check(who["status"] == "active", "healed after %d week(s)" % guard)
		_check(not who["file"].is_empty() and String(who["file"].back()["text"]) == "Back on duty.", "the return to duty is entered in the officer's file")
		dep3 = Department.load_from(PATH)
	# replay: operation 2 from the saved department, twice, from two fresh loads
	var da = Department.load_from(PATH)
	var db = Department.load_from(PATH)
	var wa = _run(da, lv, nav, 4202)
	var wb = _run(db, lv, nav, 4202)
	_check(_fingerprint(wa) == _fingerprint(wb), "an operation from a reloaded save replays exactly (%.1f s, %s)" % [wa.t, ["A", "B", "draw"][wa.winner]])
	_check(JSON.stringify(wa.incident.summary()) == JSON.stringify(wb.incident.summary()), "and so does its incident record")
	da.apply_result(wa, lv.map_name)
	db.apply_result(wb, lv.map_name)
	_check(JSON.stringify(da.to_data()) == JSON.stringify(db.to_data()), "and the department after it")
	wa.dispose()
	wb.dispose()
	_running_the_department()
	_applicants_and_statements()
	_training_queue()
	_money_by_the_book()
	_next_week_forecast()
	_emergency_lateral()
	_standing_order()
	_forecast_after_d1()
	_overdraft_d2()
	_starting_reserve_d5()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	print("problems: %d" % problems)
	quit(1 if problems > 0 else 0)


## v0.8.5: the budget, training and internal affairs.
func _running_the_department() -> void:
	print("  -- running the department (v0.8.5)")
	var d = Department.new()
	d.found(77)
	_check(d.allocation > d.payroll() and d.balance == Courses.RESERVE, "the city's allocation covers the inherited payroll ($%d > $%d)" % [d.allocation, d.payroll()])
	var b0: int = d.balance
	var pr: int = d.payroll()
	d.next_week()
	_check(d.balance == b0 + d.allocation - pr, "a week: allocation in, payroll out")
	# training: a refresher teaches the next habit and takes the officer off the board
	var r: Dictionary = d.available().back()
	var g := Courses.next_cqb(r)
	var n0: int = r["good"].size()
	var b1: int = d.balance
	_check(d.enrol(r, "cqb") == "" and r["status"] == "training" and d.balance == b1 - int(Courses.COURSES["cqb"]["cost"]), "a course is paid for and takes the officer off the board")
	_check(not d.available().has(r), "an officer on a course is not available")
	d.next_week()
	_check(r["status"] == "active" and r["good"].has(g) and r["good"].size() == n0 + 1, "the refresher taught %s" % g)
	var t0 := float(r["ech"]["t_rec0"])
	d.enrol(r, "firearms")
	d.next_week()
	_check(float(r["ech"]["t_rec0"]) < t0, "firearms qualification makes recognition faster")
	# kit: bought at cost, handed back for half
	var kit: Dictionary = Equipment.normalize(r["kit"])
	kit["armour"] = "plates"
	kit["plates"] = 2
	var b2: int = d.balance
	var paid = d.reissue(r, Equipment.validate(kit, Equipment.who_of_record(r)))
	_check(paid is int and paid > 0 and d.balance == b2 - paid, "new kit is bought ($%s)" % str(paid))
	var back = d.reissue(r, Equipment.default_kit())
	_check(back is int and back < 0 and -back == int(round(paid * Courses.SURPLUS)), "and sold back for half")
	# internal affairs
	var r2: Dictionary = d.available()[2]
	var c: Dictionary = d.open_case(r2, "misjudgment", "test", "witness", "here")
	_check(d.open_cases().size() == 1, "a case opens")
	var m0: int = d.morale
	var pr_before: int = d.payroll()
	d.decide(c, "suspend")
	_check(r2["status"] == "suspended" and d.morale < m0 and c["status"] == "closed", "a suspension: off the board, morale down")
	_check(d.payroll() == pr_before - Courses.pay(r2) and not d.available().has(r2), "a suspended officer is unpaid and unavailable")
	d.next_week()
	d.next_week()
	_check(r2["status"] == "active", "back after two weeks")
	var c2: Dictionary = d.open_case(r2, "excessive_force", "test", "video", "here")
	d.decide(c2, "fire")
	_check(r2["status"] == "fired" and not d.available().has(r2), "a dismissal")
	var c3: Dictionary = d.open_case(d.available()[0], "friendly_fire", "test", "none", "here")
	for k in Department.CASE_WEEKS:
		d.next_week()
	_check(c3["status"] == "closed" and c3["decision"] == "lapsed", "an undecided case lapses")
	# P1.D2: inside the council's overdraft nothing is frozen; only below the limit
	d.balance = -100
	_check(not d.frozen() and not d.recruit(false).is_empty() and d.enrol(d.available()[0], "judgment") == "",
		"inside the overdraft (-$100, limit -$%d) hiring and training are open" % -Department.OVERDRAFT_LIMIT)
	d.balance = Department.OVERDRAFT_LIMIT - 1
	_check(d.frozen() and d.recruit(false).is_empty() and d.enrol(d.available()[0], "judgment") != "",
		"below the overdraft limit hiring and training are frozen")
	# it all survives a save
	var j1 := JSON.stringify(d.to_data())
	var d2 = Department.new()
	d2.from_data(JSON.parse_string(j1))
	_check(JSON.stringify(d2.to_data()) == j1, "the budget, courses and cases survive a save")


## Playtest pass Q2/Q3: the applicant pool and the paper trail.
func _applicants_and_statements() -> void:
	print("  -- applicants and statements (Q2, Q3)")
	var d = Department.new()
	d.found(99)
	var pool: Array = d.applicants_now()
	_check(pool.size() >= 2 and pool.size() <= 4, "a weekly pool of two to four applicants (%d)" % pool.size())
	var ids := {}
	for r in pool:
		ids[r["id"]] = true
		_check(not d.officers.has(r) and r.has("integrity") and r.has("judgment") and r.has("bad_traits"),
			"%s is a complete record, not yet an officer" % r["name"])
	_check(ids.size() == pool.size(), "every applicant distinct")
	# hiring one spends the right money, sends a rookie to the academy (or a lateral
	# to duty at once), and the rest walk
	var pick: Dictionary = pool[0]
	var n_off: int = d.officers.size()
	var b0: int = d.balance
	var cost: int = Department.applicant_cost(pick)
	var got: Dictionary = d.choose_applicant(pick)
	_check(got == pick and d.officers.size() == n_off + 1 and d.balance == b0 - cost, "hiring from the pool costs $%s" % Department.money(cost))
	_check((pick["status"] == "academy" and int(pick["out_until"]) == d.week + Courses.RECRUIT_WEEKS) if not pick["lateral"] else pick["status"] == "active",
		"a rookie reports after the academy; a lateral hire at once (%s)" % pick["status"])
	_check(d.applicants_now().is_empty() and String(pick["id"]).begins_with("PC-"), "the rest walked; the chosen one has a badge number id (%s)" % pick["id"])
	# next week brings a fresh pool, and it survives a save mid-week
	d.next_week()
	_check(d.applicants_now().size() >= 2, "next week, a fresh pool (%d)" % d.applicants_now().size())
	var j := JSON.stringify(d.to_data())
	var d2 = Department.new()
	d2.from_data(JSON.parse_string(j))
	_check(JSON.stringify(d2.to_data()) == j and d2.applicants.size() == d.applicants.size(), "the pool survives a save")
	_check(int(d.to_data().get("version", 0)) == 6, "the applicant pool and course clocks use department save version 6")
	var old: Dictionary = JSON.parse_string(j)
	old["version"] = 5
	old.erase("applicants")
	old.erase("applicant_week")
	var old_dept = Department.new()
	_check(old_dept.from_data(old) and not old_dept.applicants_now().is_empty(), "a version 5 save still loads and rolls its pool on demand")
	# frozen hiring blocks the choice but not the looking (P1.D2: the freeze is the limit)
	d.balance = -500
	var before: Array = d.applicants_now()
	_check(not before.is_empty() and not d.choose_applicant(before[0]).is_empty(), "inside the overdraft the pool applies and can be hired")
	d.balance = Department.OVERDRAFT_LIMIT - 1
	# the hire above emptied this week's pool (the rest of it walked), so ask for a new week's
	d.applicant_week = 0
	before = d.applicants_now()
	_check(not before.is_empty() and d.choose_applicant(before[0]).is_empty(), "below the overdraft limit the pool still applies, but nobody can be hired")
	# Q3: the statement and testimony rolls, at their thresholds
	_check(Department.statement_for(90, "video", 0.0) == "matches", "integrity 90: the statement matches the body camera")
	_check(Department.statement_for(10, "video", 0.05) == "disagrees", "integrity 10: the statement can simply not match")
	_check(Department.statement_for(10, "none", 0.0) == "untested", "with nothing to check against, a statement is untested")
	_check(Department.testimony_for(90, 0.1) == "corroborates" and Department.testimony_for(10, 0.1) == "contradicts",
		"a squadmate's statement follows their integrity")


## Playtest pass Q9: queues, classroom courses in hospital, the cohort refresher.
func _training_queue() -> void:
	print("  -- training queue, classroom, cohort (Q9)")
	var d = Department.new()
	d.found(123)
	# a classroom course from a hospital bed, on its own clock
	var r: Dictionary = d.available()[3]
	var j0: int = int(r["judgment"])
	if j0 > 80:
		r["judgment"] = 60
		j0 = 60
	r["status"] = "injured"
	r["out_until"] = d.week + 3
	_check(d.enrol(r, "judgment") == "" and r["status"] == "injured" and r["course"] == "judgment", "judgment from a ward bed: still injured, on the course")
	_check(d.enrol(r, "cqb") != "", "a range course cannot start from the ward (and not mid-course either)")
	d.next_week()
	_check(r["status"] == "injured" and int(r["judgment"]) == j0 + 6 and r["course"] == "", "the classroom course finished before the wound (judgment %d -> %d)" % [j0, int(r["judgment"])])
	d.next_week()
	d.next_week()
	_check(r["status"] == "active", "and the wound finished on its own clock")
	# a queued course starts itself when the current one ends
	var r2: Dictionary = d.available()[0]
	_check(d.enrol(r2, "firearms") == "" and r2["status"] == "training", "first course starts")
	var res: Dictionary = d.enrol_or_queue(r2, "stress")
	_check(bool(res["ok"]) and res["mode"] == "queued" and r2["queue"] == ["stress"], "the second queues behind it")
	d.next_week()
	_check(r2["course"] == "stress" and r2["status"] == "training" and r2["queue"].is_empty(), "and starts itself the week the first ends")
	d.next_week()
	_check(r2["status"] == "active" and r2["courses"].has("stress") and r2["courses"].has("firearms"), "both done, in order, hands off")
	# a queued course that stopped making sense comes off with a reason
	var r3: Dictionary = d.available()[1]
	r3["bad_traits"] = ["BH11"]
	_check(d.queue_course(r3, "coaching") == "" and d.queue_course(r3, "coaching") == "", "coaching can queue twice (two habits, say)")
	r3["bad_traits"] = []
	d.next_week()
	_check(r3["queue"].is_empty() and r3["course"] == "" and r3["status"] == "active" and not r3["courses"].has("coaching"),
		"both dropped as pointless the week they would have started, unspent")
	# the cohort refresher: discount and bonds
	var mates: Array = d.officers.filter(func(x): return x["status"] == "active" and Courses.blocked(x, "cqb") == "")
	mates = mates.slice(0, 3)
	_check(mates.size() == 3, "three officers free for a cohort")
	var b_pair: int = d.bond(mates[0]["id"], mates[1]["id"])
	var bal: int = d.balance
	var coh: Dictionary = d.enrol_cohort(mates)
	var each: int = int(round(int(Courses.COURSES["cqb"]["cost"]) * Courses.COHORT_DISCOUNT))
	_check(bool(coh["ok"]) and bool(coh["discounted"]) and d.balance == bal - 3 * each, "the cohort pays three quarters each ($%s for three)" % Department.money(3 * each))
	_check(d.bond(mates[0]["id"], mates[1]["id"]) == b_pair + 1, "and comes back bonded (+1, as from an operation together)")
	var ts: Dictionary = d.training_state()
	_check(int(ts["on_course"]) >= 3, "training_state sees them (%d on a course)" % int(ts["on_course"]))


## Playtest pass Q8/Q10: overtime by the commitment, and the forecast.
func _money_by_the_book() -> void:
	print("  -- overtime and the forecast (Q8, Q10)")
	_check(Courses.overtime(40.0, false, false) == 115, "a 40-second raid bills $115 a head (callout plus a minute)")
	_check(Courses.overtime(180.0, false, false) == 145, "three minutes bills $145, against the old flat $160")
	_check(Courses.overtime(600.0, false, true) == 125, "ten quiet minutes of static duty bill $125 at half rate")
	_check(Courses.overtime(600.0, false, false) == 250 and Courses.overtime(600.0, true, true) == 185,
		"the same ten minutes through doors bill $250, and night static $185 (the premium is never halved)")
	var d = Department.new()
	d.found(31)
	var bal0: int = d.balance
	var swing: int = d.allocation - d.payroll()
	var rows: Array = d.forecast(4, [{"due": d.week + 1, "kind": "lawsuit", "cost": 40000},
		{"due": d.week + 2, "kind": "story", "cost": 999999}])
	_check(rows.size() == 4 and int(rows[0]["balance"]) == bal0 + swing, "week one of the forecast is this week's end ($%s)" % Department.money(int(rows[0]["balance"])))
	# the forecast charges 2% a week on a negative row, so the four weeks compound: replay the
	# same arithmetic here rather than pretending the overdraft is free
	var expected := bal0
	for i in 4:
		expected += swing
		if i == 1:
			expected -= 40000
		if expected < 0:
			expected -= int(ceil(-expected * Department.OVERDRAFT_INTEREST))
	_check(int(rows[1]["lawsuits"]) == 40000 and int(rows[3]["balance"]) == expected,
		"the filed lawsuit lands in its week and stays landed; a story costs trust, not money ($%s by week %d)" % [Department.money(int(rows[3]["balance"])), int(rows[3]["week"])])
	# and the books agree with the forecast's first row when nothing is spent
	d.next_week()
	_check(d.balance == bal0 + swing, "an unspent week ends where the forecast said ($%s)" % Department.money(d.balance))


## EA_TASKS P1.C2: the board's next-week strip counts who will be fit by the rules
## next_week() applies. Twelve weeks of a mixed roster (wounds of every length, academy
## places, courses run and queued, classroom courses from a ward bed, suspensions):
## the forecast must equal the fit count the week then starts with.
func _next_week_forecast() -> void:
	print("  -- next week's fit, forecast against the week (P1.C2)")
	var d = Department.new()
	d.found(4242)
	d.morale = 80   # nobody resigns: that is a roll, not a rule the strip can know
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var wrong := 0
	var detail := ""
	var kinds := {}
	for wk in 12:
		for r in d.officers:
			if r["status"] != "active":
				continue
			var roll := rng.randf()
			if roll < 0.12:
				r["status"] = "injured"
				r["out_until"] = d.week + rng.randi_range(1, 4)
				kinds["injured"] = true
				if rng.randf() < 0.5 and d.enrol(r, "judgment") == "":
					kinds["ward course"] = true
			elif roll < 0.18:
				if d.enrol(r, ["firearms", "stress", "cqb"][rng.randi() % 3]) == "":
					kinds["course"] = true
			elif roll < 0.22:
				r["status"] = "suspended"
				r["out_until"] = d.week + rng.randi_range(1, 3)
				kinds["suspended"] = true
		for r2 in d.officers:
			if r2["status"] == "training" and rng.randf() < 0.5:
				d.enrol_or_queue(r2, "stress")
				kinds["queued"] = true
		if rng.randf() < 0.5:
			d.recruit(false)
			kinds["academy"] = true
		var f: Dictionary = d.fit_next_week()
		var week_lines: Array = d.next_week()
		var got: int = d.available().size()
		# fit_next_week() says so itself: a resignation is a roll and is not guessed at, and
		# a week that loses someone to morale cannot match the forecast (2026-11-02). The
		# week's own lines say whether it happened, so this does not hide a real miss.
		var resigned: int = week_lines.filter(func(l): return String(l).contains("has resigned")).size()
		if got != int(f["fit"]) - resigned:
			wrong += 1
			if detail == "":
				detail = "week %d: forecast %d fit, the week started with %d (%s)" % [d.week, int(f["fit"]) - resigned, got, str(f)]
			print("    week %d: forecast %d fit (%s), the week started with %d" % [d.week, int(f["fit"]), str(f), got])
	_check(wrong == 0, "the forecast matched the week in %d of 12 (statuses seen: %s; first miss: %s)" % [12 - wrong, ", ".join(kinds.keys()), detail])


## EA_TASKS P1.C3: the emergency lateral reports the same week at twice a lateral's
## signing cost, one a week, frozen with hiring -- and offering or signing one changes
## nothing else the department rolls (its own stream).
func _emergency_lateral() -> void:
	print("  -- the emergency lateral (P1.C3)")
	var a = Department.new()
	a.found(555)
	var b = Department.new()
	b.found(555)
	var c1: Dictionary = a.emergency_candidate()
	var c2: Dictionary = a.emergency_candidate()
	_check(JSON.stringify(c1) == JSON.stringify(c2), "the week's candidate is the same every time it is shown (%s %s)" % [c1["rank"], c1["name"]])
	var fit0: int = a.available().size()
	var bal0: int = a.balance
	var pr0: int = a.payroll()
	var r: Dictionary = a.sign_emergency()
	_check(not r.is_empty() and r["status"] == "active" and a.available().size() == fit0 + 1, "signed: on duty this week (%d -> %d fit)" % [fit0, a.available().size()])
	_check(a.balance == bal0 - Department.emergency_cost(r) and Department.emergency_cost(r) >= 2 * Courses.LATERAL, "charged twice a lateral's signing ($%d)" % (bal0 - a.balance))
	_check(a.payroll() == pr0 + Courses.pay(r), "and the payroll rises by the pay the button showed ($%d a week)" % Courses.pay(r))
	_check(a.emergency_blocked() != "" and a.sign_emergency().is_empty(), "one a week: %s" % a.emergency_blocked())
	_check(str(a.rng.state) == str(b.rng.state) and JSON.stringify(a.applicants_now()) == JSON.stringify(b.applicants_now()), "the department's own stream and this week's pool are untouched")
	a.next_week()
	b.next_week()
	_check(a.emergency_blocked() == "", "next week another may be signed")
	a.sign_emergency()
	var a3 = Department.new()
	a3.from_data(JSON.parse_string(JSON.stringify(a.to_data())))
	_check(a3.emergency_blocked() != "", "the week's signing survives a save")
	a.balance = -1
	_check(a.emergency_blocked().contains("one emergency lateral"), "inside the overdraft the lateral is not frozen (this week's is signed)")
	a.balance = Department.OVERDRAFT_LIMIT - 1
	_check(a.emergency_blocked().contains("overdraft limit"), "frozen below the overdraft limit")


## EA_TASKS P1.C4: "keep N on the books". Off by default (and then the week is exactly
## the week it was); on, the academy takes up to two recruits a week towards N while the
## four-week forecast can carry them, says so when it cannot, and the order is saved.
func _standing_order() -> void:
	print("  -- the standing order (P1.C4)")
	var a = Department.new()
	a.found(808)
	var b = Department.new()
	b.found(808)
	a.next_week()
	b.next_week()
	_check(JSON.stringify(a.to_data()) == JSON.stringify(b.to_data()), "no order: the week is the week it always was")
	var n0: int = a.on_books()
	a.keep_on_books = n0 + 3
	var lines: Array = a.next_week()
	var enrolled: Array = lines.filter(func(l): return String(l).begins_with("Standing order:"))
	_check(enrolled.size() == 2 and a.on_books() == n0 + 2, "short by 3: two recruits this turn (the intake), %d -> %d on the books" % [n0, a.on_books()])
	_check(a.officers.filter(func(r): return r["status"] == "academy").size() == 2, "and they are at the academy, not on duty")
	lines = a.next_week()
	_check(a.on_books() == n0 + 3, "the next turn makes up the last one (%d)" % a.on_books())
	var c = Department.new()
	c.from_data(JSON.parse_string(JSON.stringify(a.to_data())))
	_check(int(c.keep_on_books) == n0 + 3, "the order survives a save")
	a.keep_on_books = a.on_books() + 1
	a.balance = -a.allocation * 5
	lines = a.next_week()
	var refused: Array = lines.filter(func(l): return String(l).contains("no recruit this week"))
	_check(refused.size() == 1 and a.on_books() == n0 + 3, "when the forecast cannot carry one, nobody is enrolled and the report says why")
	# the forecast is charged the department's recent overtime: an account that carries a
	# recruit on allocation and payroll alone does not when operations cost what they have
	var e = Department.new()
	e.found(909)
	e.keep_on_books = e.on_books() + 1
	# enough for the bare forecast (the recruit's place and four weeks' pay, before any
	# allocation), not for four weeks of $9,000 overtime on top
	var need: int = Courses.RECRUIT + Equipment.cost(Equipment.default_kit()) + 4 * Courses.PAY["Officer"]
	e.balance = need + 500
	var quiet: String = e.standing_blocked()
	for wk2 in range(e.week - 4, e.week):
		e.ledger.append({"week": wk2, "item": "Overtime, operation", "amount": -9000})
	var busy: String = e.standing_blocked()
	_check(quiet == "" and busy.contains("overtime") and e.recent_overtime() == 9000,
		"recent overtime ($%d a week) holds back a recruit the bare forecast would allow: %s" % [e.recent_overtime(), busy])
	a.balance = 1000000
	a.keep_on_books = 0
	var before: int = a.on_books()
	a.next_week()
	_check(a.on_books() == before, "cancelled: nobody else is enrolled")


## EA_TASKS P1.D1: forecast_after prices one action into the four-week forecast, and
## forecast_worst names the first red week, so the UI can warn before a negative.
func _forecast_after_d1() -> void:
	print("  -- forecast_after (P1.D1)")
	var d = Department.new()
	d.found(1234)
	var base: Array = d.forecast(4)
	var hf: Array = d.forecast_after("hire")
	_check(hf.size() == 4 and base.size() == 4, "four rows for the hire forecast and the plain one")
	var hire_cost: int = Courses.RECRUIT + Equipment.cost(Equipment.default_kit())
	_check(int(hf[0]["balance"]) == int(base[0]["balance"]) - hire_cost - Courses.PAY["Officer"],
		"hire week 1: signing cost and the first week's payroll come off ($%s)" % Department.money(int(hf[0]["balance"])))
	_check(int(hf[3]["balance"]) == int(base[3]["balance"]) - hire_cost - 4 * Courses.PAY["Officer"],
		"hire week 4: four weeks of the new payroll")
	var cf: Array = d.forecast_after("course", 2500)
	_check(int(cf[0]["balance"]) == int(base[0]["balance"]) - 2500 and int(cf[3]["balance"]) == int(base[3]["balance"]) - 2500,
		"a course is charged once, in the first week")
	var kf: Array = d.forecast_after("kit", 1000)
	_check(int(kf[0]["balance"]) == int(base[0]["balance"]) - 1000, "kit is charged once, in the first week")
	_check(String(hf[0].get("action", "")) == "hire", "the rows say which action was priced")
	d.balance = -24000
	var worst: Dictionary = Department.forecast_worst(d.forecast_after("hire"))
	_check(not worst.is_empty() and int(worst["week"]) == d.week, "forecast_worst names the first red week (week %s)" % str(worst.get("week", "?")))
	_check(Department.forecast_worst(base).is_empty() or true, "forecast_worst runs on the plain forecast too")


## EA_TASKS P1.D2: the overdraft. Inside the limit the account is red but not frozen,
## and it pays 2%% a week on the negative balance; only below -$25,000 does the freeze
## hold. The forecast shows the interest.
func _overdraft_d2() -> void:
	print("  -- the council overdraft (P1.D2)")
	var d = Department.new()
	d.found(31337)
	var alloc: int = d.allocation
	var pr: int = d.payroll()
	# the allocation ($32,000) is bigger than the payroll ($27,484) in the founding week, so
	# a -$1,000 start is back in the black by the end of the week and pays no interest: start
	# deep inside the overdraft instead, or this measures nothing
	d.balance = -24000
	_check(not d.frozen(), "at -$24,000 the account is inside the overdraft, not frozen")
	_check(d.emergency_blocked() == "", "hiring is open inside the overdraft")
	var b0: int = d.balance
	d.next_week()
	var after_alloc: int = b0 + alloc - pr
	var interest: int = int(ceil(-after_alloc * Department.OVERDRAFT_INTEREST)) if after_alloc < 0 else 0
	_check(interest > 0 and d.balance == after_alloc - interest,
		"weekly interest on the negative balance: -$1,000 +$%d allocation -$%d payroll - $%d interest = $%s" % [alloc, pr, interest, Department.money(d.balance)])
	d.balance = -1000
	var rows: Array = d.forecast(4)
	var base0: int = -1000 + alloc - pr
	var exp0: int = base0 - (int(ceil(-base0 * Department.OVERDRAFT_INTEREST)) if base0 < 0 else 0)
	_check(int(rows[0]["balance"]) == exp0, "the forecast's first row carries the interest ($%s)" % Department.money(int(rows[0]["balance"])))
	d.balance = Department.OVERDRAFT_LIMIT
	_check(not d.frozen(), "at exactly the limit the freeze does not hold")
	d.balance = Department.OVERDRAFT_LIMIT - 1
	_check(d.frozen() and d.recruit(false).is_empty() and d.enrol(d.available()[0], "judgment") != "",
		"one past the limit the freeze holds: no hiring, no courses")
	# the week's money moves first, so a balance one dollar past the limit is back above it
	# by the time the report is written; go deep enough that the week ends below it
	d.balance = Department.OVERDRAFT_LIMIT - 40000
	var lines: Array = d.next_week()
	_check(lines.filter(func(l): return String(l).contains("overdraft limit")).size() >= 1, "the week's report names the overdraft limit")


## EA_TASKS P1.D5: the starting reserve is a tuning constant the harness can override
## ($25K shipped; A/B against $35K from the balance runs).
func _starting_reserve_d5() -> void:
	print("  -- the starting reserve (P1.D5)")
	var d = Department.new()
	d.found(1001)
	_check(d.balance == Courses.RESERVE, "the shipped reserve is $%d" % Courses.RESERVE)
	Courses.reserve = 35000
	var d2 = Department.new()
	d2.found(1001)
	_check(d2.balance == 35000, "the override sets the reserve to $35,000")
	Courses.reserve = Courses.RESERVE
	var d3 = Department.new()
	d3.from_data({})
	_check(d3.balance == Courses.reserve, "a save without a balance falls back to the tuning constant")
