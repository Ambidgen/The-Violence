extends RefCounted
## The department (v0.5): persistent officers and their files, saved as versioned JSON.
##
## Every officer is rolled once, at hire: stats (form, jitter and quirks of the Patrol
## echelon), habits, personality, Judgment, Temper and Integrity. The roll travels with
## the record into every operation, and what happens there comes back: experience,
## wounds and weeks out, trauma, rounds fired, and a line in their file for every
## finding the incident record ties to them.
##
## One save slot (ironman): the department is saved after every operation and every week.
##
## v0.8.5 adds the running of it: a weekly budget (the city's allocation against pay,
## overtime, kit, hiring, training, injuries and deaths), training courses, internal
## affairs cases with their decisions, and department morale.
##
## Playtest pass (Q2, Q3, Q8, Q9, Q10): hiring by choice from a weekly applicant pool
## instead of a blind roll; Integrity read after every operation (the officer's own
## statement and a squadmate's testimony can disagree with the evidence in their IA
## case, and the city's leak roll reads the same stat); a per-officer course queue
## with classroom courses at a hospital bedside and a cohort refresher; overtime
## priced by time on target (static event duty at half rate); and a four-week
## cash-flow forecast.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Squads = preload("res://scripts/data/squads.gd")
const Names = preload("res://scripts/data/names.gd")
const Courses = preload("res://scripts/data/courses.gd")

const VERSION := 6        # 4: v0.8, pair bonds; 5: v0.8.5, budget/training/cases; 6: applicant pool and course clocks
const SAVE_PATH := "user://department.json"
## EA_TASKS P1.D2: the council overdraft. The account may go to OVERDRAFT_LIMIT before
## anything freezes; below $0 it pays weekly interest (next_week), and each week in
## overdraft costs the budget chair standing (politics.week_end).
const OVERDRAFT_LIMIT := -25000      # the freeze applies only below this
const OVERDRAFT_INTEREST := 0.02     # weekly interest on the negative balance
## Experience points needed for tiers 1-5 (Green, Blooded, Seasoned, Veteran, Exceptional).
const XP_TIERS := [0, 6, 18, 40, 80]
const RANKS := ["Officer", "Corporal", "Sergeant", "Lieutenant", "Captain"]
## Personality traits and the bad habits each brings (habits.gd, trait habits).
const PERSONALITY := {"Aggression": ["BH11", "BH12", "BH25"], "Anxiety": ["BH13", "BH14"], "Ego": ["BH15", "BH16", "BH23"],
	"Complacency": ["BH17", "BH18", "BH27"], "Rigidity": ["BH19", "BH20", "BH22"]}
## The department the player inherits (v0.7): twenty officers. A lieutenant, two
## sergeants and four corporals with years on the job, six officers with a little, and
## seven rookies.
## New hires are rookies: Patrol, between Militia and Regular infantry.
const FOUNDING := [
	["Lieutenant", 14, 46], ["Sergeant", 11, 28], ["Sergeant", 9, 22],
	["Corporal", 7, 14], ["Corporal", 5, 10], ["Corporal", 4, 8],
	["Corporal", 3, 7], ["Officer", 3, 7], ["Officer", 2, 6], ["Officer", 2, 4], ["Officer", 1, 2], ["Officer", 1, 2],
	["Officer", 1, 1], ["Officer", 0, 0], ["Officer", 0, 0], ["Officer", 0, 0], ["Officer", 0, 0], ["Officer", 0, 0],
	["Officer", 0, 0], ["Officer", 0, 0]]
## Habits a Regular has that the academy's Patrol twelve lack, and those a tactical
## team adds on top: years on the job bring the first, the best veterans some of both.
const SERVICE_HABITS := ["PF02", "GD02", "GD05", "GD06", "WD07"]
const VETERAN_HABITS := ["PF03", "PF04", "ED03", "ED05", "GD03", "WD10", "WD02", "ED10"]

var seed_val := 1
var week := 1
var serial := 0
var officers: Array = []      # records (see _new_record)
var history: Array = []       # [{week, op, map, summary, lines}] one per operation
var notes: Array = []         # [{week, text}] department log
var ops_run := 0
var bodycams := false
var bonds := {}               # "id|id" (sorted) -> operations the pair came back from in the same squad (v0.8)
# v0.8.5: the running of the department
var allocation := 0           # the city's weekly allocation
var balance := 0              # the department's account
var ledger: Array = []        # [{week, item, amount}] (amount negative for spending)
var morale := Courses.MORALE0
var cases: Array = []         # internal affairs: [{id, officer, week, kind, text, strength, place, status, decision}]
var case_serial := 0
var deficit_weeks := 0
var morale_home := Courses.MORALE0   # v0.9: where morale settles (the union's goodwill)
var applicants: Array = []           # Q2: this week's applicant pool (full records, not yet officers)
var applicant_week := 0              # the week the pool was rolled; unchosen applicants walk at week's end
var emergency_week := 0              # EA_TASKS P1.C3: the week an emergency lateral was last signed (one a week)
var keep_on_books := 0               # EA_TASKS P1.C4: standing order, officers to keep on the books (0: none)
var curriculum: Array = []           # 1.3: habits department programs added to the academy (every hire learns them)
## EA_TASKS P1.D4: capital items the department owns (Equipment.CAPITAL ids: the armoured
## rescue vehicle and its kind, bought as contracts) and the training range an offer builds.
## Declared 2026-11-02: rogue.gd has been setting both since 1.D and department.gd has been
## reading them, but neither was ever declared, so the script did not compile.
var capital := {}                    # contract id -> true, once signed
var has_range := false               # own range: courses a quarter cheaper and a week sooner
var _founding := false
var rng := RandomNumberGenerator.new()
var names


# ================================================================== founding and hiring
## A new department, all rolled from the seed: by default the FOUNDING roster (veterans,
## officers with a few years in, and rookies). n > 0 founds n rookies instead (tests).
func found(seed_v: int, n := 0) -> void:
	seed_val = seed_v
	rng.seed = seed_v
	names = Names.new(seed_v * 7 + 3)
	week = 1
	serial = 0
	officers = []
	history = []
	notes = []
	ops_run = 0
	ledger = []
	cases = []
	case_serial = 0
	deficit_weeks = 0
	curriculum = []
	morale = Courses.MORALE0
	_founding = true
	if n > 0:
		for k in n:
			hire("Officer", 0)
	else:
		for f in FOUNDING:
			hire(f[0], f[2], false, float(f[1]))
	_founding = false
	allocation = int(round(payroll() * (1.0 + Courses.HEADROOM) / 500.0)) * 500
	# P1.D5: the tuning constant, not the shipped default (the harness overrides it per run)
	balance = Courses.reserve
	note("Department inherited: %d officers (%d with five years or more on the job)." % [officers.size(),
		officers.filter(func(r): return float(r.get("years", 0.0)) >= 5.0).size()])
	note("The city allocates $%s a week; payroll is $%s; $%s in the account." % [money(allocation), money(payroll()), money(balance)])
	_roll_applicants()


## Hire one officer. A rookie is Patrol (the midpoint of Militia and Regular in every
## stat); years of service move the stats towards Regular and add habits. A lateral
## hire arrives with experience.
func hire(rank := "Officer", xp := 0, lateral := false, years := 0.0) -> Dictionary:
	var r := _roll_record(rank, xp, lateral, years)
	officers.append(r)
	return r


## Roll one complete record without adding it to the roster (Q2: the applicant pool
## rolls people the chief can inspect before anyone is hired). The rolls happen in
## exactly the order hire() has always made them, so a founded department comes out
## the same for the same seed; only the serial (no rng in it) is pool-aware.
func _roll_record(rank := "Officer", xp := 0, lateral := false, years := 0.0, pool := false) -> Dictionary:
	if names == null:
		names = Names.new(seed_val * 7 + 3 + serial)
	var rid := ""
	if pool:
		rid = "APP-%d" % (applicants.size() + 1)
	else:
		serial += 1
		rid = "PC-%04d" % serial
	if lateral and years <= 0.0:
		years = 3.0
	var r := {"id": rid, "badge": 1000 + serial * 7 + rng.randi_range(0, 6), "name": names.diverse_name(0.3),
		"rank": rank, "echelon": "patrol", "hired_week": week, "status": "applicant" if pool else "active", "out_until": 0, "years": years,
		"ech": Habits.vary(Habits.service_stats(years), rng), "good": [], "bad_traits": [], "traits": [],
		"personality": "", "judgment": _trait(50.0 + 1.2 * years, 11.0), "temper": _trait(40.0, 15.0),
		"integrity": _trait(65.0, 15.0), "exp": 1, "xp": 0, "trauma": 0.0, "ops": 0, "shots": 0, "hits": 0, "kills": 0,
		"civ_hits": 0, "wounded": 0, "arrests": 0, "misjudged": 0, "file": [], "lateral": lateral, "orders_broken": 0,
		"kit": Equipment.default_kit(), "issued": 0, "tactical": false, "drill": 0, "course": "", "courses": [],
		"queue": [], "course_until": 0}
	r["issued"] = Equipment.cost(r["kit"])
	# habits: the academy's twelve, sometimes one swapped for another Regular habit;
	# years on the job add Regular habits, and the senior veterans some tactical ones
	var good: Array = Habits.preset_good("patrol")
	if rng.randf() < 0.5 and years < 1.0:
		var extra: Array = Habits.preset_good("regular").filter(func(g): return not good.has(g))
		if not extra.is_empty():
			good.remove_at(rng.randi() % good.size())
			good.append(extra[rng.randi() % extra.size()])
	var more: Array = SERVICE_HABITS.filter(func(g): return not good.has(g))
	for k in mini(more.size(), int(round(years * 0.6))):
		good.append(more.pop_at(rng.randi() % more.size()))
	if years >= 9.0:
		var vet: Array = VETERAN_HABITS.duplicate()
		for k2 in clampi(int(years - 8.0) / 2 + 1, 1, 4):
			good.append(vet.pop_at(rng.randi() % vet.size()))
	for cg in curriculum:
		if not good.has(cg):
			good.append(cg)
	good.sort()
	r["good"] = good
	# a career leaves something behind
	if years >= 4.0:
		r["trauma"] = snappedf(rng.randf() * years * 0.35, 0.5)
	# personality: some recruits bring a trait and the bad habits that come with it
	if rng.randf() < 0.4:
		var keys: Array = PERSONALITY.keys()
		var pk: String = keys[rng.randi() % keys.size()]
		r["personality"] = pk
		var bh: Array = PERSONALITY[pk]
		r["bad_traits"] = bh.duplicate() if rng.randf() < 0.3 else [bh[rng.randi() % bh.size()]]
	if rng.randf() < 0.06:
		r["traits"].append("TR01")
	elif rng.randf() < 0.05:
		r["traits"].append("TR02")
	r["xp"] = xp
	r["exp"] = tier_for(xp)
	if pool:
		r["file"].append({"week": week, "text": "Applied in week %d%s." % [week, " (lateral, %d years elsewhere)" % int(years) if lateral else ""]})
	elif years >= 1.0 and not lateral:
		r["file"].append({"week": week, "text": "%s, %d year%s on the job when you took command." % [rank, int(years), "" if int(years) == 1 else "s"]})
	else:
		r["file"].append({"week": week, "text": "Hired as %s%s." % [rank.to_lower(), " (lateral)" if lateral else ""]})
	return r


# ------------------------------------------------------------------ the applicant pool (Q2)
## This week's applicants: two to four complete records, everything visible (echelon,
## judgment, temper, integrity, personality and its habits, hearing traits, the pay
## they will draw). The chief hires one; the rest walk at the end of the week.
## Looking is free: the pool is rolled even while hiring is frozen.
func _roll_applicants() -> void:
	applicants = []
	applicant_week = week
	var n := 2 + rng.randi_range(0, 2)
	for k in n:
		if rng.randf() < 0.35:
			var yrs := float(rng.randi_range(3, 6))
			applicants.append(_roll_record("Corporal" if yrs >= 5.0 else "Officer", rng.randi_range(6, 14), true, yrs, true))
		else:
			applicants.append(_roll_record("Officer", 0, false, 0.0, true))


## The pool, rolled fresh if the week has moved on since it was.
func applicants_now() -> Array:
	if applicant_week != week:
		_roll_applicants()
	return applicants


## EA_TASKS P1.C3: the emergency lateral. Whatever the pool holds, the chief can sign an
## experienced officer from a neighbouring force who reports this week, at twice a
## lateral's signing cost and one a week. The candidate is a full record (pay, habits,
## personality all visible before signing), rolled from its own stream -- seeded by the
## run and the week -- so offering one changes nothing else the department rolls.
func emergency_candidate() -> Dictionary:
	var keep_rng := rng
	var keep_names = names
	rng = RandomNumberGenerator.new()
	rng.seed = hash([seed_val, week, "emergency lateral"])
	names = Names.new(int(hash([seed_val, week, "emergency names"])) & 0x7fffffff)
	var taken := {}
	for o in officers:
		taken[String(o["name"])] = true
	var r := {}
	for attempt in 6:
		var yrs := float(rng.randi_range(3, 8))
		r = _roll_record("Corporal" if yrs >= 5.0 else "Officer", rng.randi_range(6, 16), true, yrs, true)
		if not taken.has(String(r["name"])):
			break
	rng = keep_rng
	names = keep_names
	r["emergency"] = true
	return r


## Why the emergency lateral cannot be signed now, or "".
func emergency_blocked() -> String:
	if frozen():
		return "the account is below the overdraft limit (-%s): hiring is frozen" % money(-OVERDRAFT_LIMIT)
	if emergency_week == week:
		return "one emergency lateral a week, and this week's has signed"
	return ""


static func emergency_cost(r: Dictionary) -> int:
	return Courses.EMERGENCY_LATERAL + int(r.get("issued", 0))


## Sign this week's emergency lateral: on duty at once. Returns the record, or {}.
func sign_emergency() -> Dictionary:
	if emergency_blocked() != "":
		return {}
	var r := emergency_candidate()
	r.erase("emergency")
	serial += 1
	r["id"] = "PC-%04d" % serial
	r["hired_week"] = week
	r["status"] = "active"
	r["out_until"] = 0
	r["file"].append({"week": week, "text": "Signed as an emergency lateral from a neighbouring force; on duty the same week."})
	spend("Emergency lateral: %s" % r["name"], emergency_cost(r))
	officers.append(r)
	emergency_week = week
	note("Signed %s %s as an emergency lateral." % [r["rank"].to_lower(), r["name"]])
	return r


## What hiring this applicant costs today: the academy place or the lateral signing,
## plus the kit they are issued.
static func applicant_cost(r: Dictionary) -> int:
	return (Courses.LATERAL if r.get("lateral", false) else Courses.RECRUIT) + int(r.get("issued", 0))


## Hire the chosen applicant: a rookie goes to the academy for two weeks, a lateral
## hire reports at once, and the rest of the pool walks. Returns the new officer's
## record, or {} if hiring is frozen or the applicant has already gone.
func choose_applicant(r: Dictionary) -> Dictionary:
	if frozen() or r.is_empty() or not applicants.has(r):
		return {}
	var walked: int = applicants.size() - 1
	serial += 1
	r["id"] = "PC-%04d" % serial
	r["hired_week"] = week
	if r.get("lateral", false):
		r["status"] = "active"
		r["out_until"] = 0
		r["file"].append({"week": week, "text": "Hired laterally from the applicant pool."})
		spend("Lateral hire: %s" % r["name"], Courses.LATERAL + int(r["issued"]))
	else:
		r["status"] = "academy"
		r["out_until"] = week + Courses.RECRUIT_WEEKS
		r["file"].append({"week": week, "text": "Hired from the applicant pool; at the academy until week %d." % r["out_until"]})
		spend("Academy place: %s" % r["name"], Courses.RECRUIT + int(r["issued"]))
	officers.append(r)
	applicants = []
	note("Hired %s %s from the applicant pool%s." % [r["rank"].to_lower(), r["name"],
		(" (%d other applicant%s walked)" % [walked, "" if walked == 1 else "s"]) if walked > 0 else ""])
	return r


func _trait(mean: float, sd: float) -> int:
	return clampi(int(round(rng.randfn(mean, sd))), 10, 95)


static func tier_for(xp: int) -> int:
	var tier := 1
	for k in range(1, XP_TIERS.size()):
		if xp >= XP_TIERS[k]:
			tier = k + 1
	return tier


func get_officer(oid: String) -> Dictionary:
	for r in officers:
		if r["id"] == oid:
			return r
	return {}


func available() -> Array:
	return officers.filter(func(r): return r["status"] == "active")


## Who will be fit when next week starts, by the rules next_week() applies (EA_TASKS
## P1.C2): today's fit officers, plus the injured who are due back, graduates of the
## academy, courses and suspensions that end -- less anyone free next week who starts a
## queued course (Q9), which next_week() decides after the week's allocation and payroll,
## in roster order, against the account as each course is paid for. Operations still to
## run this week, and resignations (a roll), are not guessed at.
func fit_next_week() -> Dictionary:
	var nw: int = week + 1
	var out := {"fit": 0, "back": 0, "graduates": 0, "returning": 0, "to_course": 0}
	var acct: int = balance + allocation - payroll()
	# P1.D2: next_week() charges the overdraft interest before any queued course starts
	if acct < 0:
		acct -= int(ceil(-acct * OVERDRAFT_INTEREST))
	for r in officers:
		var st := String(r.get("status", "active"))
		var due: bool = int(r.get("out_until", 0)) <= nw
		var studying: bool = String(r.get("course", "")) != ""
		var course_done: bool = studying and int(r.get("course_until", 0)) <= nw
		var why := ""
		match st:
			"active":
				why = "fit"
			"injured":
				if due and (not studying or course_done):
					why = "back"
			"training":
				if due or course_done:
					why = "returning"
			"academy":
				if due:
					why = "graduates"
			"suspended":
				if due:
					why = "returning"
		if why == "":
			continue
		if (not studying or course_done) and acct >= OVERDRAFT_LIMIT:  # P1.D2: courses start above the overdraft limit, as in next_week()
			var cid := _first_startable(r)
			if cid != "":
				acct -= course_cost(cid)
				out["to_course"] += 1
				continue
		out["fit"] += 1
		if why != "fit":
			out[why] += 1
	return out


## The queued course an officer free next week would start: the first that still makes
## sense (next_week() drops the others with a line).
func _first_startable(r: Dictionary) -> String:
	for cid in r.get("queue", []):
		if not Courses.COURSES.has(cid):
			continue
		if Courses.blocked(r, cid) == "":
			return String(cid)
	return ""


func note(text: String) -> void:
	notes.append({"week": week, "text": text})


# ================================================================== the budget (v0.8.5)
static func money(n: int) -> String:
	# 4.72: absi() overflows on -2^63; clamp and handle zero early
	if n == 0:
		return "0"
	var neg := n < 0
	# Use 64-bit safe abs: absi(n) would overflow for INT64_MIN
	var s := str(absi(n)) if n != -9223372036854775807 - 1 else "9223372036854775808"
	var out := ""
	var guard := 0
	while s.length() > 3 and guard < 10:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
		guard += 1
	return ("-" if neg else "") + s + out


## Weekly pay of everyone on the books: on duty, injured, in training or at the academy.
## Suspended officers are unpaid.
func payroll() -> int:
	var t := 0
	for r in officers:
		# 4.72: a loaded record may have lost `status`; an unreadable status is a
		# paid officer (the boot-path default), not a crash.
		if String(r.get("status", "active")) in ["active", "injured", "training", "academy"]:
			t += Courses.pay(r)
	return t


func spend(item: String, amount: int) -> void:
	if amount == 0:
		return
	balance -= amount
	ledger.append({"week": week, "item": item, "amount": -amount})
	if ledger.size() > 400:
		ledger = ledger.slice(ledger.size() - 400)


func income(item: String, amount: int) -> void:
	if amount == 0:
		return
	balance += amount
	ledger.append({"week": week, "item": item, "amount": amount})


## In the red: no hiring, no training and no new kit until the account is back above zero.
## EA_TASKS P1.D2: the freeze only applies below the overdraft limit.
## Above the limit, hiring, training and new kit are open.
func frozen() -> bool:
	return balance < OVERDRAFT_LIMIT


func shift_morale(d: int, why := "") -> void:
	morale = clampi(morale + d, 0, 100)


## Hire through the budget: a rookie goes to the academy for two weeks; a lateral hire
## (three to six years elsewhere) reports at once. Returns the record, or {} if frozen.
func recruit(lateral := false) -> Dictionary:
	if frozen():
		return {}
	var r: Dictionary
	if lateral:
		var yrs := float(rng.randi_range(3, 6))
		r = hire("Corporal" if yrs >= 5.0 else "Officer", rng.randi_range(6, 14), true, yrs)
		spend("Lateral hire: %s" % r["name"], Courses.LATERAL + int(r["issued"]))
	else:
		r = hire()
		r["status"] = "academy"
		r["out_until"] = week + Courses.RECRUIT_WEEKS
		r["file"].append({"week": week, "text": "At the academy until week %d." % r["out_until"]})
		spend("Academy place: %s" % r["name"], Courses.RECRUIT + int(r["issued"]))
	note("Hired %s %s%s." % [r["rank"].to_lower(), r["name"], " (lateral)" if lateral else " (academy until week %d)" % r["out_until"]])
	return r


## EA_TASKS P1.C4: the standing order "keep N officers on the books". At the turn of
## each week, while fewer than N are on the books (on duty, injured, on a course, at the
## academy or suspended), the academy takes a recruit -- if the four-week forecast stays
## in the black after the academy place and four weeks of the recruit's pay. When it
## cannot, the week's report says so; the order stays until the chief changes it.
## Two recruits a week at most: the academy's intake, and no week's money all at once.
const STANDING_INTAKE := 2


func on_books() -> int:
	return officers.filter(func(r): return String(r.get("status", "active")) in ["active", "injured", "training", "academy", "suspended"]).size()


## Average weekly overtime over the last n weeks of the ledger: what operations cost on
## top of the forecast, which knows only the allocation, the payroll and filed lawsuits.
func recent_overtime(n := 4) -> int:
	var t := 0
	for e in ledger:
		if int(e.get("week", 0)) >= week - n and int(e.get("week", 0)) < week \
				and String(e.get("item", "")).begins_with("Overtime"):
			t += -int(e.get("amount", 0))
	return int(round(float(t) / float(n)))


## Can the forecast carry one more recruit? Returns "" or why not. The four-week forecast
## is charged the recruit's academy place and pay and, each week, the department's recent
## overtime: the 1.C pilot's standing order otherwise enrolled down to $0 and the week's
## operations then put the account in the red (cautious: 36 of 40 weeks below zero).
func standing_blocked() -> String:
	if frozen():
		return "the account is in the red"
	var cost: int = Courses.RECRUIT + Equipment.cost(Equipment.default_kit())
	var pay: int = Courses.PAY["Officer"]
	var ot: int = recent_overtime()
	var rows: Array = forecast(4)
	for i in rows.size():
		var left: int = int(rows[i]["balance"]) - cost - (pay + ot) * (i + 1)
		if left < 0:
			return "the four-week forecast cannot carry another recruit (week %d would end at $%s, counting $%s a week of overtime)" % [
				int(rows[i]["week"]), money(left), money(ot)]
	return ""


func _standing_order() -> Array:
	var out: Array = []
	if keep_on_books <= 0:
		return out
	var n := 0
	while on_books() < keep_on_books and n < STANDING_INTAKE:
		var why := standing_blocked()
		if why != "":
			out.append("Standing order (keep %d on the books, %d now): no recruit this week -- %s." % [keep_on_books, on_books(), why])
			return out
		var r := recruit(false)
		if r.is_empty():
			break
		r["file"].append({"week": week, "text": "Enrolled by the standing order to keep %d on the books." % keep_on_books})
		n += 1
		out.append("Standing order: %s %s enrols at the academy (until week %d); %d of %d on the books." % [
			r["rank"], r["name"], int(r["out_until"]), on_books(), keep_on_books])
	return out


## Let an officer go: two weeks' severance, and the union remembers.
func fire(r: Dictionary, why := "") -> void:
	if r["status"] in ["dead", "fired", "resigned"]:
		return
	spend("Severance: %s" % r["name"], Courses.pay(r) * Courses.SEVERANCE_WEEKS)
	r["status"] = "fired"
	r["file"].append({"week": week, "text": "Dismissed%s." % ((": " + why) if why != "" else "")})
	note("%s %s dismissed%s." % [r["rank"], r["name"], (" (" + why + ")") if why != "" else ""])
	shift_morale(-6)


## Issue a new kit: new kit is bought at cost, kit handed back is sold for half. Returns
## what it cost (negative for a refund), or a string saying why not.
func reissue(r: Dictionary, kit: Dictionary):
	var old: int = int(r.get("issued", Equipment.cost(r["kit"])))
	var nv: int = Equipment.cost(kit)
	var d := nv - old
	if d > 0 and frozen():
		return "the account is in the red: no new kit until it is back above zero"
	r["kit"] = kit
	r["issued"] = nv
	if d > 0:
		spend("Kit: %s" % r["name"], d)
		return d
	var back := int(round(-d * Courses.SURPLUS))
	income("Kit returned: %s" % r["name"], back)
	return -back


## Settle any kit that changed without going through reissue (the suggested plan hands
## out squad kits directly): bought at cost, handed back for half. Returns the net cost.
func settle_kits() -> int:
	var net := 0
	for r in officers:
		if r["status"] in ["dead", "fired", "resigned"]:
			continue
		var was: int = int(r.get("issued", Equipment.cost(r["kit"])))
		var now: int = Equipment.cost(r["kit"])
		if now > was:
			spend("Kit: %s" % r["name"], now - was)
			net += now - was
		elif now < was:
			var back := int(round((was - now) * Courses.SURPLUS))
			income("Kit returned: %s" % r["name"], back)
			net -= back
		r["issued"] = now
	return net


## Send an officer on a course now. A classroom course (judgment, the use-of-force
## review) can be taken from a hospital bed: the wound keeps its own clock
## (out_until) and the course keeps another (course_until) (Q9). Returns "" or why not.
func enrol(r: Dictionary, cid: String) -> String:
	if not Courses.COURSES.has(cid):
		return "no such course"
	var c: Dictionary = Courses.COURSES[cid]
	if String(r.get("course", "")) != "":
		return "already on a course"
	if r["status"] != "active" and not (r["status"] == "injured" and bool(c.get("classroom", false))):
		return "not on duty"
	var why := Courses.blocked(r, cid)
	if why != "":
		return why
	if frozen():
		return "the account is in the red"
	spend("%s: %s" % [c["name"], r["name"]], int(c["cost"]))
	return _start_course(r, cid)


## Put an officer on a paid-for course: the clocks and the file line.
func _start_course(r: Dictionary, cid: String) -> String:
	var c: Dictionary = Courses.COURSES[cid]
	r["course"] = cid
	r["course_until"] = week + int(c["weeks"])
	if r["status"] == "active":
		r["status"] = "training"
		r["out_until"] = int(r["course_until"])
	r["file"].append({"week": week, "text": "On the %s course until week %d%s." % [c["name"].to_lower(), int(r["course_until"]),
		", while recovering" if r["status"] == "injured" else ""]})
	shift_morale(1)
	return ""


## Queue a course behind whatever the officer is doing (Q9): it starts itself in
## next_week when they can take it, and is paid for then. Returns "" or why not.
func queue_course(r: Dictionary, cid: String) -> String:
	if not Courses.COURSES.has(cid):
		return "no such course"
	if r["status"] in ["dead", "fired", "resigned", "suspended"]:
		return "not with the department"
	var q: Array = r.get("queue", [])
	if q.size() >= Courses.QUEUE_MAX:
		return "the queue is full (%d waiting)" % Courses.QUEUE_MAX
	var why := Courses.blocked(r, cid)
	if why != "":
		return why
	q.append(cid)
	r["queue"] = q
	r["file"].append({"week": week, "text": "Queued for the %s course." % Courses.COURSES[cid]["name"].to_lower()})
	return ""


## Take a queued course off again.
func unqueue(r: Dictionary, cid: String) -> void:
	var q: Array = r.get("queue", [])
	q.erase(cid)
	r["queue"] = q


## The roster's one button: start the course if the officer can take it today,
## queue it if they cannot (on a course, in hospital with a range course, or the
## money is not there this week). Returns {ok, mode: "now"|"queued", why}.
func enrol_or_queue(r: Dictionary, cid: String) -> Dictionary:
	if not Courses.COURSES.has(cid):
		return {"ok": false, "mode": "", "why": "no such course"}
	var c: Dictionary = Courses.COURSES[cid]
	var can_now: bool = String(r.get("course", "")) == "" and (r["status"] == "active"
		or (r["status"] == "injured" and bool(c.get("classroom", false))))
	if can_now:
		var why: String = enrol(r, cid)
		if why == "":
			return {"ok": true, "mode": "now", "why": ""}
		if why != FROZEN_WHY:
			return {"ok": false, "mode": "now", "why": why}
	var why2: String = queue_course(r, cid)
	return {"ok": why2 == "", "mode": "queued", "why": why2}


## The text the queue path reports when the freeze holds a course back (P1.D2: the
## freeze is the overdraft limit now, not zero).
const FROZEN_WHY := "below the overdraft limit: no courses while the freeze holds"


## Send a group on the close-quarters refresher together (Q9): three or more who can
## start today pay three quarters each, and every pair of them gains a bond, as if
## they had come back from an operation in the same squad (cohesion in squads.gd).
## Returns {ok, started: [names], discounted, cost, why}.
func enrol_cohort(members: Array, cid := "cqb") -> Dictionary:
	if cid != "cqb" or not Courses.COURSES.has(cid):
		return {"ok": false, "started": [], "discounted": false, "cost": 0, "why": "the cohort discount is for the close-quarters refresher"}
	if frozen():
		return {"ok": false, "started": [], "discounted": false, "cost": 0, "why": "the account is in the red"}
	var elig: Array = []
	for r in members:
		if r["status"] == "active" and String(r.get("course", "")) == "" and Courses.blocked(r, cid) == "" and not elig.has(r):
			elig.append(r)
	if elig.is_empty():
		return {"ok": false, "started": [], "discounted": false, "cost": 0, "why": "nobody picked can start the refresher this week"}
	var c: Dictionary = Courses.COURSES[cid]
	var discounted: bool = elig.size() >= Courses.COHORT_N
	var each: int = int(round(int(c["cost"]) * (Courses.COHORT_DISCOUNT if discounted else 1.0)))
	var names2: Array = []
	for r2 in elig:
		spend("%s (cohort): %s" % [c["name"], r2["name"]], each)
		_start_course(r2, cid)
		names2.append(String(r2["name"]))
	if discounted:
		for i in elig.size():
			for j in range(i + 1, elig.size()):
				var key := bond_key(elig[i]["id"], elig[j]["id"])
				bonds[key] = int(bonds.get(key, 0)) + 1
		note("A cohort of %d took the %s together at three quarters' cost, and bonded over it." % [elig.size(), c["name"].to_lower()])
	return {"ok": true, "started": names2, "discounted": discounted, "cost": each * elig.size(), "why": ""}


## How much schooling the roster is carrying, and how much it could start today —
## the bottleneck, readable at a glance (Q9).
func training_state() -> Dictionary:
	var st := {"on_course": 0, "queued": 0, "officers_queued": 0, "startable": 0, "startable_injured": 0}
	for r in officers:
		if r["status"] in ["dead", "fired", "resigned"]:
			continue
		if String(r.get("course", "")) != "":
			st["on_course"] += 1
		elif r["status"] == "active":
			st["startable"] += 1
		elif r["status"] == "injured":
			st["startable_injured"] += 1
		var qn: int = (r.get("queue", []) as Array).size()
		st["queued"] += qn
		if qn > 0:
			st["officers_queued"] += 1
	return st


## What the queued courses will cost when they start (Q8/Q9): known spending that
## has not hit the account yet.
func queued_cost() -> int:
	var t := 0
	for r in officers:
		for cid in r.get("queue", []):
			t += int(Courses.COURSES.get(cid, {}).get("cost", 0))
	return t


## The account, four weeks out, as far as it is knowable today (Q8): each week's
## allocation against today's payroll, minus the lawsuits already filed and due
## (pending entries of kind "lawsuit" from the city — instalments land in their own
## weeks, P1.D3), minus the council's overdraft interest on any negative week (P1.D2).
## It cannot know next week's overtime, wounds or settlements nobody has filed yet —
## but a cash crunch made of things already on the books should never be a surprise.
## First row is the end of this week. Returns [{week, allocation, payroll, lawsuits, balance}].
func forecast(weeks_n := 4, pending: Array = []) -> Array:
	var rows: Array = []
	var bal: int = balance
	var pr: int = payroll()
	for i in weeks_n:
		var wk: int = week + i
		var suits := 0
		for p in pending:
			if String(p.get("kind", "")) != "lawsuit":
				continue
			var inst = p.get("instalments", null)
			if inst is Array:
				for it in inst:
					if it is Dictionary and not bool(it.get("paid", false)) and int(it.get("week", -1)) == wk:
						suits += int(it.get("amount", 0))
			elif int(p.get("due", -1)) == wk:
				suits += int(p.get("cost", 0))
		bal += allocation - pr - suits
		if bal < 0:
			bal -= int(ceil(-bal * OVERDRAFT_INTEREST))
		rows.append({"week": wk, "allocation": allocation, "payroll": pr, "lawsuits": suits, "balance": bal})
	return rows


## EA_TASKS P1.D1: the four-week forecast with one action added, so every hire, course
## and kit button can say "week N goes to -$X" before the chief commits. "hire" charges
## the signing cost now and the new payroll every week from this one (the academy pays);
## "course" and "kit" charge once, in this week's row. cost/per_week override the
## defaults so a specific applicant or course is priced, not the generic one.
func forecast_after(action: String, cost := -1, per_week := 0, pending: Array = []) -> Array:
	var rows := forecast(4, pending)
	var out: Array = []
	for i in rows.size():
		var row: Dictionary = rows[i]
		var bal: int = int(row["balance"])
		match action:
			"hire":
				if cost < 0:
					cost = Courses.RECRUIT + Equipment.cost(Equipment.default_kit())
				if per_week <= 0:
					per_week = Courses.PAY["Officer"]
				bal -= cost + per_week * (i + 1)
			"course":
				if cost < 0:
					cost = course_cost("uof")
				bal -= cost
			"kit":
				if cost < 0:
					cost = Equipment.cost(Equipment.default_kit())
				bal -= cost
		out.append({"week": int(row["week"]), "balance": bal, "action": action})
	return out


## The first week a forecast row goes negative (what "week 6 goes to -$2,100" means),
## or {} when it never does.
static func forecast_worst(rows: Array) -> Dictionary:
	for row in rows:
		if int(row["balance"]) < 0:
			return {"week": int(row["week"]), "balance": int(row["balance"])}
	return {}


## EA_TASKS P1.D4: what a course costs now — a quarter less with the department's own
## training range — and how many weeks it takes (one fewer, at least one).
func course_cost(cid: String) -> int:
	var c: Dictionary = Courses.COURSES.get(cid, {})
	var base: int = int(c.get("cost", 0))
	if has_range:
		base = int(round(base * Courses.RANGE_DISCOUNT))
	return base


func course_weeks(cid: String) -> int:
	var c: Dictionary = Courses.COURSES.get(cid, {})
	var wks: int = int(c.get("weeks", 1))
	if has_range:
		wks = maxi(1, wks - Courses.RANGE_WEEKS_OFF)
	return wks

## A course ends: what it teaches.
func _finish_course(r: Dictionary) -> String:
	var cid: String = r.get("course", "")
	var c: Dictionary = Courses.COURSES.get(cid, {})
	var what := ""
	match cid:
		"cqb":
			var g := Courses.next_cqb(r)
			if g != "":
				r["good"].append(g)
				r["good"].sort()
				what = "learned %s" % Habits.good_info(g).get("name", g)
		"firearms":
			var d := int(r.get("drill", 0))
			var y := float(r.get("years", 0.0)) + float(d)
			var a: Dictionary = Habits.service_stats(y)
			var b: Dictionary = Habits.service_stats(y + 1.0)
			for k in Habits.FORM_STATS:
				if float(a.get(k, 0.0)) > 0.0:
					r["ech"][k] = float(r["ech"][k]) * float(b[k]) / float(a[k])
			r["drill"] = d + 1
			what = "qualified (%d of 4)" % r["drill"]
		"judgment":
			r["judgment"] = mini(90, int(r["judgment"]) + 6)
			what = "judgment now %d" % r["judgment"]
		"stress":
			r["trauma"] = maxf(0.0, float(r["trauma"]) - 4.0)
			r["ech"]["resist"] = minf(0.95, float(r["ech"].get("resist", 0.3)) + 0.03)
			what = "trauma eased"
		"coaching":
			if not r["bad_traits"].is_empty():
				var bh: String = r["bad_traits"].pop_front()
				what = "no longer prone to %s" % Habits.bad_info(bh).get("name", bh)
				if r["bad_traits"].is_empty():
					r["personality"] = ""
		"tactical":
			r["tactical"] = true
			var n := 0
			for g2 in Courses.TACTICAL_ORDER:
				if n < 2 and not r["good"].has(g2):
					r["good"].append(g2)
					n += 1
			r["good"].sort()
			what = "certified for tactical kit"
		"uof":
			r["judgment"] = mini(90, int(r["judgment"]) + 5)
			what = "use-of-force review complete; judgment now %d" % r["judgment"]
	r["courses"].append(cid)
	r["course"] = ""
	r["file"].append({"week": week, "text": "Completed the %s course: %s." % [String(c.get("name", cid)).to_lower(), what]})
	return "%s %s completed %s: %s." % [r["rank"], r["name"], c.get("name", cid), what]


# ================================================================== internal affairs (v0.8.5)
const CASE_KINDS := {"civilian_hit_by_police": "A civilian hit by police fire", "excessive_force": "Excessive force",
	"misjudgment": "A misjudgment", "friendly_fire": "Friendly fire", "jumpy_fire": "Shots without a threat",
	"broke_order": "Broke an order"}
const DECISIONS := ["clear", "retrain", "suspend", "fire"]
## Gravest first, for the case that leads; strongest evidence first.
const CASE_ORDER := ["civilian_hit_by_police", "excessive_force", "friendly_fire", "misjudgment", "jumpy_fire", "broke_order"]
const EVIDENCE_ORDER := ["video", "witness", "radio log", "heard", "none"]
const CASE_WEEKS := 3           # open cases close themselves, without action, after this long


## Triage changes the order in which the chief sees cases, never their evidence or
## the available individual decisions. Severity is primary; evidence breaks ties.
static func case_is_urgent(c: Dictionary, at_week: int) -> bool:
	return at_week - int(c.get("week", at_week)) >= CASE_WEEKS - 1


static func sorted_open_cases(case_list: Array, at_week: int) -> Array:
	var out: Array = case_list.filter(func(c): return c.get("status", "open") == "open")
	out.sort_custom(func(a, b):
		var sa := CASE_ORDER.find(a.get("kind", ""))
		var sb := CASE_ORDER.find(b.get("kind", ""))
		if sa != sb:
			return (sa if sa >= 0 else 99) < (sb if sb >= 0 else 99)
		var ea := EVIDENCE_ORDER.find(a.get("strength", "none"))
		var eb := EVIDENCE_ORDER.find(b.get("strength", "none"))
		if ea != eb:
			return (ea if ea >= 0 else 99) < (eb if eb >= 0 else 99)
		var ua := case_is_urgent(a, at_week)
		var ub := case_is_urgent(b, at_week)
		if ua != ub:
			return ua
		if int(a.get("week", 0)) != int(b.get("week", 0)):
			return int(a.get("week", 0)) < int(b.get("week", 0))
		return String(a.get("id", "")) < String(b.get("id", "")))
	return out


static func case_triage(case_list: Array, at_week: int) -> Dictionary:
	var open: Array = case_list.filter(func(c): return c.get("status", "open") == "open")
	var grave := 0
	var video := 0
	var urgent := 0
	var untested := 0
	for c in open:
		var severity := CASE_ORDER.find(c.get("kind", ""))
		if severity >= 0 and severity <= 1:
			grave += 1
		if c.get("strength", "none") == "video":
			video += 1
		if case_is_urgent(c, at_week):
			urgent += 1
		if c.get("statement", "") == "untested":
			untested += 1
	return {"open": open.size(), "grave": grave, "video": video, "urgent": urgent, "untested": untested}


static func triage_line(case_list: Array, at_week: int) -> String:
	var t := case_triage(case_list, at_week)
	if int(t["open"]) == 0:
		return ""
	return "IA triage: %d open · %d grave · %d video · %d due before lapse · %d untested statements." % [
		t["open"], t["grave"], t["video"], t["urgent"], t["untested"]]


## Q3: the officer's own account of it. Where there is evidence to check it against
## (video or witnesses), a low-integrity officer's statement can simply not match;
## at 65 integrity and above it always does. With nothing to check against, the
## statement is untested and neither helps nor harms the officer (yet).
static func statement_for(integrity: int, strength: String, roll: float) -> String:
	if strength not in ["video", "witness"]:
		return "untested"
	var p := clampf((65.0 - float(integrity)) / 120.0, 0.0, 0.55)
	return "disagrees" if roll < p else "matches"


## Q3: what a squadmate who was there says in a colleague's case. A straight officer's
## testimony corroborates the record and firms weak evidence up one step (never to
## video: testimony is not footage); a crooked one's can contradict it, and evidence
## nobody corroborates slips one step the other way (video itself never slips).
static func testimony_for(integrity: int, roll: float) -> String:
	if integrity >= 75:
		return "corroborates" if roll < 0.8 else "unclear"
	if integrity <= 30:
		return "contradicts" if roll < 0.5 else "unclear"
	return "corroborates" if roll < 0.35 else "unclear"


func open_case(r: Dictionary, kind: String, text: String, strength: String, place: String) -> Dictionary:
	case_serial += 1
	var c := {"id": "IA-%03d" % case_serial, "officer": r["id"], "week": week, "kind": kind, "text": text,
		"strength": strength, "place": place, "status": "open", "decision": ""}
	cases.append(c)
	r["file"].append({"week": week, "text": "Internal affairs case %s opened: %s." % [c["id"], CASE_KINDS.get(kind, kind).to_lower()]})
	return c


func open_cases() -> Array:
	return cases.filter(func(c): return c["status"] == "open")


## Decide a case. Returns a line, or "" if the decision could not be carried out.
func decide(c: Dictionary, decision: String) -> String:
	if c["status"] != "open":
		return ""
	var r := get_officer(c["officer"])
	if r.is_empty() or r["status"] in ["dead", "fired", "resigned"]:
		c["status"] = "closed"
		c["decision"] = "moot"
		return "%s closed: the officer is no longer with the department." % c["id"]
	var who := "%s %s" % [r["rank"], r["name"]]
	match decision:
		"clear":
			c["decision"] = "cleared"
			r["file"].append({"week": week, "text": "%s: cleared." % c["id"]})
			shift_morale(1)
		"retrain":
			# the use-of-force review is a classroom course: a wounded officer can
			# answer for a finding from the ward (Q9)
			if r["status"] not in ["active", "injured"]:
				return ""
			if enrol(r, "uof") != "":
				return ""
			c["decision"] = "retrained"
		"suspend":
			r["status"] = "suspended"
			r["out_until"] = maxi(int(r["out_until"]), week + 2)
			r["file"].append({"week": week, "text": "%s: suspended without pay until week %d." % [c["id"], r["out_until"]]})
			c["decision"] = "suspended"
			shift_morale(-3)
		"fire":
			fire(r, c["id"])
			c["decision"] = "dismissed"
		_:
			return ""
	c["status"] = "closed"
	note("%s (%s): %s." % [c["id"], who, c["decision"]])
	return "%s: %s %s." % [c["id"], who, c["decision"]]


# ================================================================== into an operation
## The configuration for one officer in team A's slot `slot` (spawn from the map).
func to_cfg(r: Dictionary, slot: int, level, alert := 1) -> Dictionary:
	var id := "A%d" % (slot + 1)
	var good := {}
	for g in r["good"]:
		good[g] = true
	var bad := {}
	for b in Habits.stress_bad_ids():
		bad[b] = true
	for b2 in r["bad_traits"]:
		bad[b2] = true
	var traits := {}
	for tr in r["traits"]:
		traits[tr] = true
	var ech: Dictionary = (r["ech"] as Dictionary).duplicate(true)
	# trauma raises the stress an officer brings into every operation
	ech["stress0"] = minf(0.3, float(r["trauma"]) * 0.015)
	# low department morale: everyone brings more of it in (v0.8.5)
	if morale < Courses.MORALE0:
		# v0.9.1: at most +0.05 (it was +0.12, which fed a death spiral: low morale, more
		# stress habits under fire, more officers killed, lower morale)
		ech["stress0"] = minf(0.4, float(ech["stress0"]) + float(Courses.MORALE0 - morale) / 1200.0)
	var kit: Dictionary = Equipment.validate(r.get("kit", Equipment.default_kit()), Equipment.who_of_record(r))
	return {"id": id, "team": 0, "slot": slot, "echelon": r["echelon"], "good": good, "bad": bad,
		"plates": int(kit["plates"]), "exp": int(r["exp"]), "traits": traits, "pos": level.spawns[id]["p"], "face": level.spawns[id]["face"],
		"enabled": true, "alert": alert, "ech": ech, "officer_id": r["id"], "name": r["name"], "rank": r["rank"],
		"vest": kit["armour"] == "vest", "kit": kit, "bodycam": bodycams, "judgment": int(r["judgment"]), "temper": int(r["temper"]),
		"integrity": int(r["integrity"])}


# ================================================================== hurt on patrol
## A patrol encounter resolved on the desk (Patrol, 2026-11-05) hurt an officer:
## "hurt" (one to three weeks), "down" (four to eight) or "dead", by the same rules,
## costs and morale as an operation. Returns the line for the report.
func patrol_casualty(r: Dictionary, harm: String, what: String) -> String:
	if r.is_empty() or r["status"] == "dead" or harm == "":
		return ""
	var who := "%s %s" % [r["rank"], r["name"]]
	match harm:
		"dead":
			r["status"] = "dead"
			r["file"].append({"week": week, "text": "Killed on patrol: %s." % what})
			note("%s killed on patrol (%s)." % [who, what])
			spend("Line-of-duty death benefit: %s" % r["name"], Courses.DEATH_BENEFIT)
			shift_morale(-3)
			return "%s was killed." % who
		"down":
			r["status"] = "injured"
			r["out_until"] = week + 4 + rng.randi_range(0, 4)
			r["wounded"] += 1
			r["trauma"] = float(r["trauma"]) + 2.0
			r["file"].append({"week": week, "text": "Seriously hurt on patrol (%s); out until week %d." % [what, r["out_until"]]})
			spend("Medical: %s" % r["name"], Courses.MEDICAL_SERIOUS)
			shift_morale(-2)
			return "%s is seriously hurt: out until week %d." % [who, r["out_until"]]
		_:
			r["status"] = "injured"
			r["out_until"] = week + 1 + rng.randi_range(0, 2)
			r["wounded"] += 1
			r["trauma"] = float(r["trauma"]) + 0.5
			r["file"].append({"week": week, "text": "Hurt on patrol (%s); out until week %d." % [what, r["out_until"]]})
			spend("Medical: %s" % r["name"], Courses.MEDICAL)
			shift_morale(-1)
			return "%s is hurt: out until week %d." % [who, r["out_until"]]


# ================================================================== back from an operation
## Write what happened to each department officer back into their record, file the
## incident summary, and save. Returns readable lines for the debrief.
## EA_TASKS P1.D4: sit_type is passed so a capital item can matter — the armoured rescue
## vehicle (capital["arv"]) carries the first officer downed in a gang raid out alive.
func apply_result(w, map_name: String, sit_type := "") -> Array:
	ops_run += 1
	var lines: Array = []
	var inc = w.incident
	var data: Dictionary = inc.to_data() if inc != null else {}
	var per_op: Dictionary = data.get("per_op", {})
	var officers_dead := 0
	for o in w.ops:
		if o.officer_id != "" and o.state == "dead":
			officers_dead += 1
	var arv := bool(capital.get("arv", false)) and sit_type == "gang"
	var arv_used := false
	var n_off := 0
	var restock := 0.0
	for o in w.ops:
		if o.officer_id == "":
			continue
		var r := get_officer(o.officer_id)
		if r.is_empty():
			continue
		n_off += 1
		# spent gear is restocked at cost (bangs, gas, cartridges, rounds, medical kits)
		var had: Dictionary = Equipment.gear_counts(o.kit)
		for gid in had:
			if gid in ["ram", "shield", "light", "gas_mask", "baton"]:
				continue
			var used: int = int(had[gid]) - int(o.gear.get(gid, had[gid]))
			if used > 0:
				var spec: Dictionary = Equipment.GEAR.get(gid, {})
				restock += float(spec.get("cost", 0)) * float(used) / maxf(1.0, float(spec.get("shots", 1)))
		var po: Dictionary = per_op.get(o.id, {})
		r["ops"] += 1
		r["shots"] += o.shots
		r["hits"] += int(po.get("hits_threat", o.hits))
		r["kills"] += o.kills
		r["civ_hits"] += int(po.get("hits_civ", 0))
		var arrests := 0
		for a in data.get("arrests", []):
			if a["by"] == o.id:
				arrests += 1
		r["arrests"] += arrests
		# experience: contact, being under fire, hits on a threat, arrests, coming back hurt
		var gain := 0
		var contact := false
		for pid in o.first_rec:
			var p = w.by_id.get(pid, null)
			if p != null and not p.civ:
				contact = true
				break
		if contact:
			gain += 2
		if o.last_stress_t > 0.0:
			gain += 2
		gain += mini(3, int(po.get("hits_threat", 0)))
		gain += arrests
		var hurt: bool = o.wounds > 0 or o.arm_hit or o.leg_hit or o.state == "down"
		if hurt and o.state != "dead":
			gain += 1
		var old_tier: int = r["exp"]
		r["xp"] += gain
		r["exp"] = tier_for(r["xp"])
		var who: String = "%s %s" % [r["rank"], r["name"]]
		var opline := "Operation %d (%s): %d rounds, %d hit a threat%s." % [ops_run, map_name, o.shots, int(po.get("hits_threat", 0)),
			(", %d arrest%s" % [arrests, "" if arrests == 1 else "s"]) if arrests > 0 else ""]
		r["file"].append({"week": week, "text": opline})
		if r["exp"] > old_tier:
			r["file"].append({"week": week, "text": "Now %s (experience tier %d)." % [Habits.EXP_NAMES[r["exp"]], r["exp"]]})
			lines.append("%s is now %s (tier %d)." % [who, Habits.EXP_NAMES[r["exp"]], r["exp"]])
		# trauma: taking a life, being hit, losing a partner, hitting a civilian
		var tr := 0.0
		if o.kills > 0:
			tr += 2.0
		if hurt:
			tr += 2.0
		if officers_dead > (1 if o.state == "dead" else 0):
			tr += 1.0
		if int(po.get("hits_civ", 0)) > 0:
			tr += 3.0
		r["trauma"] = float(r["trauma"]) + tr
		# injuries and deaths
		if o.state == "dead":
			r["status"] = "dead"
			r["file"].append({"week": week, "text": "Killed in operation %d, %s." % [ops_run, map_name]})
			lines.append("%s was killed." % who)
			note("%s killed in operation %d." % [who, ops_run])
			spend("Line-of-duty death benefit: %s" % r["name"], Courses.DEATH_BENEFIT)
			shift_morale(-3)
		elif o.state == "down":
			r["status"] = "injured"
			# v0.9.1: four to eight weeks (it was eight to fourteen, which kept most of the
			# department out at once); "down" is every incapacitating hit, limbs included
			r["out_until"] = week + 4 + rng.randi_range(0, 4)
			r["wounded"] += 1
			r["file"].append({"week": week, "text": "Seriously wounded; out until week %d." % r["out_until"]})
			spend("Medical: %s" % r["name"], Courses.MEDICAL_SERIOUS)
			shift_morale(-2)
			lines.append("%s is seriously wounded: out until week %d." % [who, r["out_until"]])
		elif hurt:
			r["status"] = "injured"
			r["out_until"] = week + 1 + rng.randi_range(0, 2)
			r["wounded"] += 1
			r["file"].append({"week": week, "text": "Wounded; out until week %d." % r["out_until"]})
			spend("Medical: %s" % r["name"], Courses.MEDICAL)
			shift_morale(-1)
			lines.append("%s is wounded: out until week %d." % [who, r["out_until"]])
		# findings that name this officer go into their file
		var mine: Array = []
		for f in data.get("findings", []):
			if f["by"] == o.id and f["kind"] in ["civilian_hit_by_police", "excessive_force", "misjudgment", "friendly_fire", "jumpy_fire"]:
				r["file"].append({"week": week, "text": "Finding: %s (%s; evidence: %s)." % [f["text"], f["place"], f["strength"]]})
				mine.append(f)
		# one internal affairs case per officer per operation, led by the gravest finding
		if not mine.is_empty() and r["status"] != "dead":
			mine.sort_custom(func(a, b): return CASE_ORDER.find(a["kind"]) < CASE_ORDER.find(b["kind"]))
			var top: Dictionary = mine[0]
			var best_ev := "none"
			for f2 in mine:
				if EVIDENCE_ORDER.find(String(f2["strength"])) < EVIDENCE_ORDER.find(best_ev):
					best_ev = String(f2["strength"])
			var txt: String = top["text"] + ((" (and %d more finding%s)" % [mine.size() - 1, "" if mine.size() == 2 else "s"]) if mine.size() > 1 else "")
			# Q3: a squadmate who was there gives a statement in the case; the most
			# upright one still standing is who internal affairs believes it can use
			var wit: Dictionary = {}
			for o3 in w.ops:
				if o3.officer_id == "" or o3.officer_id == o.officer_id or o3.state == "dead" or o3.squad != o.squad or o.squad < 0:
					continue
				var wr: Dictionary = get_officer(o3.officer_id)
				if not wr.is_empty() and (wit.is_empty() or int(wr["integrity"]) > int(wit["integrity"])):
					wit = wr
			var testimony := "none"
			if not wit.is_empty():
				testimony = testimony_for(int(wit["integrity"]), rng.randf())
				if testimony == "corroborates":
					best_ev = {"none": "heard", "heard": "witness"}.get(best_ev, best_ev)
				elif testimony == "contradicts":
					best_ev = {"witness": "heard", "heard": "none"}.get(best_ev, best_ev)
			# and the officer's own statement, checked against what evidence there is
			var statement: String = statement_for(int(r["integrity"]), best_ev, rng.randf())
			if statement == "disagrees":
				txt += " The officer's statement does not match the %s." % ("body camera" if best_ev == "video" else "witnesses")
			var c := open_case(r, top["kind"], txt, best_ev, String(top["place"]))
			c["findings"] = mine.size()
			c["statement"] = statement
			c["integrity"] = int(r["integrity"])
			c["witness"] = wit.get("id", "")
			c["testimony"] = testimony
			if statement == "disagrees":
				r["integrity"] = clampi(int(r["integrity"]) - 5, 10, 95)
				r["file"].append({"week": week, "text": "Statement in %s contradicted by the %s; integrity now %d." % [c["id"],
					"body camera" if best_ev == "video" else "witnesses", int(r["integrity"])]})
				lines.append("%s's statement in %s does not match the %s." % [who, c["id"], "body camera" if best_ev == "video" else "witnesses"])
			if not wit.is_empty() and testimony != "unclear":
				wit["file"].append({"week": week, "text": "Statement in %s (%s): %s the record." % [c["id"], who,
					"corroborated" if testimony == "corroborates" else "contradicted"]})
			lines.append("Internal affairs: %s opened on %s (%s%s)." % [c["id"], who, CASE_KINDS.get(top["kind"], top["kind"]).to_lower(),
				(", %d findings" % mine.size()) if mine.size() > 1 else ""])
	# shared experience (v0.8): every pair that came back alive from the same squad
	var by_squad := {}
	for o2 in w.ops:
		if o2.officer_id != "" and o2.state != "dead" and o2.squad >= 0:
			if not by_squad.has(o2.squad):
				by_squad[o2.squad] = []
			by_squad[o2.squad].append(o2.officer_id)
	for sq in by_squad:
		var ids: Array = by_squad[sq]
		for i in ids.size():
			for j in range(i + 1, ids.size()):
				var key := bond_key(ids[i], ids[j])
				bonds[key] = int(bonds.get(key, 0)) + 1
	# what the operation cost: overtime for everyone sent, priced by the commitment
	# (Q8: callout plus time on target; Q10: static post/patrol duty at half rate)
	var static_ids := {}
	if w.teams.size() > 0:
		for el in w.teams[0].get("elements", []):
			var kinds: Array = (el.get("orders", {}).get("objs", []) as Array).map(func(ob): return ob.get("kind", ""))
			if not kinds.is_empty() and kinds.all(func(k): return k in ["post", "patrol"]):
				for m in el["members"]:
					static_ids[m.id] = true
	var ot := 0
	var n_static := 0
	for o4 in w.ops:
		if o4.officer_id == "":
			continue
		var st: bool = static_ids.has(o4.id)
		ot += Courses.overtime(w.t, w.night, st)
		n_static += 1 if st else 0
	spend("Overtime, operation %d (%d officers, %d min%s)" % [ops_run, n_off, maxi(1, int(ceil(w.t / 60.0))),
		(", %d on static duty at half rate" % n_static) if n_static > 0 else ""], ot)
	spend("Restock, operation %d" % ops_run, int(round(restock)))
	lines.append("Cost: $%s overtime, $%s to restock. Account: $%s." % [money(ot), money(int(round(restock))), money(balance)])
	var ts: Dictionary = training_state()
	lines.append("Training: %d on a course, %d queued; %d officer%s could start one now%s." % [int(ts["on_course"]), int(ts["queued"]),
		int(ts["startable"]) + int(ts["startable_injured"]), "" if int(ts["startable"]) + int(ts["startable_injured"]) == 1 else "s",
		(" (%d of them a classroom course from a ward bed)" % int(ts["startable_injured"])) if int(ts["startable_injured"]) > 0 else ""])
	var s: Dictionary = data.get("summary", {})
	history.append({"week": week, "op": ops_run, "map": map_name, "seed": w.seed_used, "summary": s.duplicate(true)})
	if history.size() > 200:
		history = history.slice(history.size() - 200)
	note("Operation %d at %s: %d civilians hit, %d suspects down, %d arrested, %d findings." % [ops_run, map_name,
		int(s.get("civ_hit", 0)), int(s.get("suspects_down", 0)), int(s.get("arrested", 0)), int(s.get("findings", 0))])
	return lines


## A week passes: wounds heal, trauma eases a little.
func next_week() -> Array:
	var lines: Array = []
	# the week's money: the allocation in, the payroll out
	var pr := payroll()
	income("City allocation, week %d" % week, allocation)
	spend("Payroll, week %d" % week, pr)
	# EA_TASKS P1.D2: 2% a week on whatever is still negative after the week's money. The
	# forecast charges it the same way (forecast()), so the two agree week for week; the
	# charge was documented in 1.D and never applied here, which is why the account never
	# actually cost anything to run overdrawn.
	if balance < 0:
		var interest := int(ceil(-balance * OVERDRAFT_INTEREST))
		if interest > 0:
			spend("Interest on the overdraft, week %d" % week, interest)
			lines.append("The council charges $%s of interest on the overdraft this week." % money(interest))
	week += 1
	for r in officers:
		var due: bool = int(r["out_until"]) <= week
		match r["status"]:
			"injured":
				if due:
					var studying: bool = String(r.get("course", "")) != ""
					r["status"] = "training" if studying else "active"
					if studying:
						r["out_until"] = int(r["course_until"])
					r["file"].append({"week": week, "text": "Recovered from their wound." if studying else "Back on duty."})
					lines.append("%s %s %s." % [r["rank"], r["name"], "has recovered and continues their course" if studying else "is back on duty"])
			"training":
				if due:
					r["status"] = "active"
			"academy":
				if due:
					r["status"] = "active"
					r["file"].append({"week": week, "text": "Graduated from the academy; reporting for duty."})
					lines.append("%s %s reports from the academy." % [r["rank"], r["name"]])
			"suspended":
				if due:
					r["status"] = "active"
					r["file"].append({"week": week, "text": "Suspension over; back on duty."})
					lines.append("%s %s is back from suspension." % [r["rank"], r["name"]])
		# Classroom courses have their own clock. They can finish while the wound
		# keeps the officer in hospital, and an officer recovered mid-course stays
		# unavailable until the course is done.
		if String(r.get("course", "")) != "" and int(r.get("course_until", 0)) <= week:
			lines.append(_finish_course(r))
			if r["status"] == "training":
				r["status"] = "active"
		if r["status"] not in ["dead", "fired", "resigned"]:
			r["trauma"] = maxf(0.0, float(r["trauma"]) - 0.5)
	# Q9: queued courses start themselves as soon as the officer can take them;
	# one that has stopped making sense (the habit coached by other means, judgment
	# already at the cap) comes off the queue with a line saying why
	for r2 in officers:
		while String(r2.get("course", "")) == "" and not (r2.get("queue", []) as Array).is_empty():
			var cid: String = String(r2["queue"][0])
			var cc: Dictionary = Courses.COURSES.get(cid, {})
			if cc.is_empty():
				r2["queue"].pop_front()
				continue
			var can: bool = r2["status"] == "active" or (r2["status"] == "injured" and bool(cc.get("classroom", false)))
			if not can or frozen():
				break
			r2["queue"].pop_front()
			var whyq: String = enrol(r2, cid)
			if whyq == "":
				lines.append("%s %s starts the %s course (it was queued)." % [r2["rank"], r2["name"], cc["name"].to_lower()])
			else:
				lines.append("%s %s comes off the %s queue: %s." % [r2["rank"], r2["name"], cc["name"].to_lower(), whyq])
	lines.append_array(_standing_order())
	# cases nobody decided close themselves
	for c in cases:
		if c["status"] == "open" and week - int(c["week"]) >= CASE_WEEKS:
			c["status"] = "closed"
			c["decision"] = "lapsed"
			lines.append("%s lapsed without a decision." % c["id"])
			note("%s lapsed without a decision." % c["id"])
	# the account
	if balance < 0:
		deficit_weeks += 1
		shift_morale(-3)
		if balance < OVERDRAFT_LIMIT:
			lines.append("The account is $%s in the red, below the overdraft limit (-%s): hiring, training and new kit are frozen. The council has noticed (%d week%s in deficit)." % [money(-balance), money(-OVERDRAFT_LIMIT), deficit_weeks, "" if deficit_weeks == 1 else "s"])
		else:
			lines.append("The account is $%s in the red, inside the overdraft: interest is charged weekly and hiring, training and new kit stay open. The council has noticed (%d week%s in deficit)." % [money(-balance), deficit_weeks, "" if deficit_weeks == 1 else "s"])
		note("Week %d: in deficit ($%s)." % [week, money(balance)])
	# morale drifts home; very low morale costs people
	if morale < morale_home:
		# the further down, the faster it comes back: people get on with it
		morale = mini(morale_home, morale + Courses.MORALE_DRIFT + (morale_home - morale) / 10)
	elif morale > morale_home:
		morale = maxi(morale_home, morale - Courses.MORALE_DRIFT)
	if morale < Courses.MORALE_QUIT:
		var cand: Array = officers.filter(func(r): return r["status"] == "active")
		if not cand.is_empty() and rng.randf() < float(Courses.MORALE_QUIT - morale) / 50.0:
			cand.sort_custom(func(a, b): return int(a["integrity"]) < int(b["integrity"]) if int(a["integrity"]) != int(b["integrity"]) else a["id"] < b["id"])
			var q: Dictionary = cand[0]
			q["status"] = "resigned"
			q["file"].append({"week": week, "text": "Resigned."})
			lines.append("%s %s has resigned. Morale is %d." % [q["rank"], q["name"], morale])
			shift_morale(-2)
			note("%s %s resigned (morale %d)." % [q["rank"], q["name"], morale])
	note("Week %d." % week)
	return lines


## Operations two officers have come back from together in the same squad.
static func bond_key(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a


func bond(a: String, b: String) -> int:
	return int(bonds.get(bond_key(a, b), 0))


## Cohesion of a squad of department officers (records): their pair bonds and the
## leader's experience (the highest rank, then the most experienced, leads).
func squad_cohesion(members: Array) -> float:
	var vals: Array = []
	for i in members.size():
		for j in range(i + 1, members.size()):
			vals.append(bond(members[i]["id"], members[j]["id"]))
	var lead_exp := 1
	var best_rank := -1
	for r in members:
		var ri: int = Squads.RANKS.find(String(r.get("rank", "")))
		if ri > best_rank or (ri == best_rank and int(r.get("exp", 1)) > lead_exp):
			best_rank = ri
			lead_exp = int(r.get("exp", 1))
	return Squads.cohesion_from(vals, lead_exp)


# ================================================================== saving
func to_data() -> Dictionary:
	return {"version": VERSION, "seed": seed_val, "week": week, "serial": serial, "ops_run": ops_run,
		"bodycams": bodycams, "rng_state": str(rng.state), "officers": officers.duplicate(true),
		"history": history.duplicate(true), "notes": notes.duplicate(true), "bonds": bonds.duplicate(),
		"allocation": allocation, "balance": balance, "ledger": ledger.duplicate(true), "morale": morale,
		"cases": cases.duplicate(true), "case_serial": case_serial, "deficit_weeks": deficit_weeks, "morale_home": morale_home,
		"applicants": applicants.duplicate(true), "applicant_week": applicant_week, "curriculum": curriculum.duplicate(),
		"emergency_week": emergency_week, "keep_on_books": keep_on_books,
		"capital": capital.duplicate(), "has_range": has_range}


## One loaded record put back the way the game keeps it: JSON's floats back to ints,
## and the fields older versions did not have. Officers and applicants are the same
## shape of record, so both go through here.
func _fix_record(r: Dictionary) -> Dictionary:
	for k in ["badge", "hired_week", "out_until", "judgment", "temper", "integrity", "exp", "xp", "ops", "shots",
			"hits", "kills", "civ_hits", "wounded", "arrests", "orders_broken", "drill", "misjudged"]:
		r[k] = int(r.get(k, 0))
	r["trauma"] = float(r.get("trauma", 0.0))
	# version 1 (v0.5-v0.6) had no years of service, version 2 (v0.7) no kit
	r["years"] = float(r.get("years", 0.0))
	# 4.72: `r.get("kit", default)` still returns null when the save *has* the key with
	# a null value, and Equipment.normalize() cannot take null — it logged an engine
	# error before the fallback below could run. Decide the argument first.
	var kit_in = r.get("kit", null)
	r["kit"] = Equipment.normalize(kit_in if kit_in is Dictionary else Equipment.default_kit())
	# 4.72: a damaged save may carry a kit without these sub-keys. Normalising the
	# kit should always produce them, but a half-written record can still arrive
	# here, and this runs while the game is starting: a throw would stop the boot.
	if not (r["kit"] is Dictionary):
		r["kit"] = Equipment.default_kit()
	if not r["kit"].has("plates"):
		r["kit"]["plates"] = 0
	if not r["kit"].has("gear") or not (r["kit"]["gear"] is Dictionary):
		r["kit"]["gear"] = {}
	r["kit"]["plates"] = int(r["kit"]["plates"])
	for gk in r["kit"]["gear"]:
		r["kit"]["gear"][gk] = int(r["kit"]["gear"][gk])
	if not (r.get("status", null) is String) or String(r.get("status", "")) == "":
		r["status"] = "active"
	if not (r.get("name", null) is String):
		r["name"] = "Officer"
	if not (r.get("rank", null) is String):
		r["rank"] = "Officer"
	if not (r.get("ech", null) is Dictionary):
		r["ech"] = Habits.service_stats(float(r.get("years", 0.0)))
	if not (r.get("good", null) is Array):
		r["good"] = []
	if not (r.get("bad_traits", null) is Array):
		r["bad_traits"] = []
	if not (r.get("traits", null) is Array):
		r["traits"] = []
	if not (r.get("courses", null) is Array):
		r["courses"] = []
	if not (r.get("queue", null) is Array):
		r["queue"] = []
	if not r.has("file") or not (r["file"] is Array):
		r["file"] = []
	for fe in r["file"]:
		if fe is Dictionary:
			fe["week"] = int(fe.get("week", 0))
	# version 4 and earlier (before v0.8.5): the kit they carry counts as issued
	r["issued"] = int(r.get("issued", Equipment.cost(r["kit"])))
	r["tactical"] = bool(r.get("tactical", false))
	r["course"] = String(r.get("course", ""))
	r["courses"] = r.get("courses", [])
	# version 5 and earlier (before the playtest pass) had no queue and one clock for
	# injury and course alike: the course clock starts as that clock
	r["queue"] = r.get("queue", [])
	r["course_until"] = int(r.get("course_until", int(r["out_until"]) if r["course"] != "" else 0))
	return r


func from_data(d: Dictionary) -> bool:
	# a save with no balance at all (an empty or an older file) starts from the tuning
	# constant rather than from zero: P1.D5, Courses.reserve
	balance = Courses.reserve
	var ver := int(d.get("version", 0))
	if ver < 1 or ver > VERSION:
		return false
	# 4.72: every key below used to be read as d["..."], which throws on a save that
	# parses as JSON but lost a record. This is the boot path and SaveFile keeps a
	# .bak for exactly this case, so a damaged file must fail *softly* (empty
	# department) rather than take the whole game down before the title screen.
	seed_val = int(d.get("seed", 1))
	week = int(d.get("week", 1))
	serial = int(d.get("serial", 0))
	ops_run = int(d.get("ops_run", 0))
	bodycams = bool(d.get("bodycams", false))
	rng.seed = seed_val
	rng.state = String(d.get("rng_state", "0")).to_int()
	names = Names.new(seed_val * 7 + 3 + serial)
	officers = []
	var raw_off: Array = d.get("officers", []) if d.get("officers", []) is Array else []
	for r0 in raw_off:
		if r0 is Dictionary:
			officers.append(_fix_record(r0))
	# version 5 and earlier had no applicant pool: this week's is rolled on demand
	applicants = []
	var raw_app: Array = d.get("applicants", []) if d.get("applicants", []) is Array else []
	for a0 in raw_app:
		if a0 is Dictionary:
			applicants.append(_fix_record(a0))
	applicant_week = int(d.get("applicant_week", 0))
	emergency_week = int(d.get("emergency_week", 0))
	keep_on_books = int(d.get("keep_on_books", 0))
	# P1.D4: capital items and the training range. Version 6 and earlier never wrote them;
	# a save from before this reads as owning nothing, and the range follows the item.
	capital = {}
	var raw_cap: Dictionary = d.get("capital", {}) if d.get("capital", {}) is Dictionary else {}
	for ck in raw_cap:
		if bool(raw_cap[ck]):
			capital[String(ck)] = true
	has_range = bool(d.get("has_range", false)) or capital.has("range")
	curriculum = []
	for cg in (d.get("curriculum", []) if d.get("curriculum", []) is Array else []):
		if cg is String:
			curriculum.append(cg)
	# version 3 and earlier (before v0.8) had no pair bonds: everyone starts as strangers
	bonds = {}
	var raw_bonds: Dictionary = d.get("bonds", {}) if d.get("bonds", {}) is Dictionary else {}
	for bk in raw_bonds:
		bonds[bk] = int(raw_bonds[bk])
	history = d.get("history", []) if d.get("history", []) is Array else []
	notes = d.get("notes", []) if d.get("notes", []) is Array else []
	# version 4 and earlier had no budget: the city sets it from the payroll now
	if d.has("allocation"):
		allocation = int(d.get("allocation", 0))
		balance = int(d.get("balance", Courses.RESERVE))
		morale = int(d.get("morale", Courses.MORALE0))
		case_serial = int(d.get("case_serial", 0))
		deficit_weeks = int(d.get("deficit_weeks", 0))
		morale_home = int(d.get("morale_home", Courses.MORALE0))
		ledger = d.get("ledger", []) if d.get("ledger", []) is Array else []
		for le in ledger:
			if le is Dictionary:
				le["week"] = int(le.get("week", 0))
				le["amount"] = int(le.get("amount", 0))
		cases = d.get("cases", []) if d.get("cases", []) is Array else []
		for c in cases:
			if not (c is Dictionary):
				continue
			c["week"] = int(c.get("week", 0))
			for ck in ["integrity", "findings"]:
				if c.has(ck):
					c[ck] = int(c[ck])
	else:
		allocation = int(round(payroll() * (1.0 + Courses.HEADROOM) / 500.0)) * 500
		balance = Courses.reserve
		morale = Courses.MORALE0
		ledger = []
		cases = []
	for n in notes:
		if n is Dictionary:
			n["week"] = int(n.get("week", 0))
	return true


func save(path := SAVE_PATH) -> bool:
	return load("res://scripts/campaign/save_file.gd").write_json(path, to_data())


static func load_from(path := SAVE_PATH):
	var d = load("res://scripts/campaign/save_file.gd").read_json(path)
	if d == null:
		return null
	var dep = load("res://scripts/campaign/department.gd").new()
	if not dep.from_data(d):
		return null
	return dep
