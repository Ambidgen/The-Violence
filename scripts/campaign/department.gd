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

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Squads = preload("res://scripts/data/squads.gd")
const Names = preload("res://scripts/data/names.gd")
const Courses = preload("res://scripts/data/courses.gd")

const VERSION := 5        # 3: v0.7.5, every officer has a kit; 4: v0.8, pair bonds; 5: v0.8.5, budget, training, cases
const SAVE_PATH := "user://department.json"
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
	balance = Courses.RESERVE
	note("Department inherited: %d officers (%d with five years or more on the job)." % [officers.size(),
		officers.filter(func(r): return float(r.get("years", 0.0)) >= 5.0).size()])
	note("The city allocates $%s a week; payroll is $%s; $%s in the account." % [money(allocation), money(payroll()), money(balance)])


## Hire one officer. A rookie is Patrol (the midpoint of Militia and Regular in every
## stat); years of service move the stats towards Regular and add habits. A lateral
## hire arrives with experience.
func hire(rank := "Officer", xp := 0, lateral := false, years := 0.0) -> Dictionary:
	if names == null:
		names = Names.new(seed_val * 7 + 3 + serial)
	serial += 1
	if lateral and years <= 0.0:
		years = 3.0
	var r := {"id": "PC-%04d" % serial, "badge": 1000 + serial * 7 + rng.randi_range(0, 6), "name": names.diverse_name(0.3),
		"rank": rank, "echelon": "patrol", "hired_week": week, "status": "active", "out_until": 0, "years": years,
		"ech": Habits.vary(Habits.service_stats(years), rng), "good": [], "bad_traits": [], "traits": [],
		"personality": "", "judgment": _trait(50.0 + 1.2 * years, 11.0), "temper": _trait(40.0, 15.0),
		"integrity": _trait(65.0, 15.0), "exp": 1, "xp": 0, "trauma": 0.0, "ops": 0, "shots": 0, "hits": 0, "kills": 0,
		"civ_hits": 0, "wounded": 0, "arrests": 0, "file": [], "lateral": lateral, "orders_broken": 0,
		"kit": Equipment.default_kit(), "issued": 0, "tactical": false, "drill": 0, "course": "", "courses": []}
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
	if years >= 1.0 and not lateral:
		r["file"].append({"week": week, "text": "%s, %d year%s on the job when you took command." % [rank, int(years), "" if int(years) == 1 else "s"]})
	else:
		r["file"].append({"week": week, "text": "Hired as %s%s." % [rank.to_lower(), " (lateral)" if lateral else ""]})
	officers.append(r)
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


func note(text: String) -> void:
	notes.append({"week": week, "text": text})


# ================================================================== the budget (v0.8.5)
static func money(n: int) -> String:
	var neg := n < 0
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if neg else "") + s + out


## Weekly pay of everyone on the books: on duty, injured, in training or at the academy.
## Suspended officers are unpaid.
func payroll() -> int:
	var t := 0
	for r in officers:
		if r["status"] in ["active", "injured", "training", "academy"]:
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
func frozen() -> bool:
	return balance < 0


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


## Send an officer on a course. Returns "" or why not.
func enrol(r: Dictionary, cid: String) -> String:
	if not Courses.COURSES.has(cid):
		return "no such course"
	if r["status"] != "active":
		return "not on duty"
	var why := Courses.blocked(r, cid)
	if why != "":
		return why
	var c: Dictionary = Courses.COURSES[cid]
	if frozen():
		return "the account is in the red"
	spend("%s: %s" % [c["name"], r["name"]], int(c["cost"]))
	r["status"] = "training"
	r["course"] = cid
	r["out_until"] = week + int(c["weeks"])
	r["file"].append({"week": week, "text": "On the %s course until week %d." % [c["name"].to_lower(), r["out_until"]]})
	shift_morale(1)
	return ""


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
			if r["status"] != "active":
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


# ================================================================== back from an operation
## Write what happened to each department officer back into their record, file the
## incident summary, and save. Returns readable lines for the debrief.
func apply_result(w, map_name: String) -> Array:
	ops_run += 1
	var lines: Array = []
	var inc = w.incident
	var data: Dictionary = inc.to_data() if inc != null else {}
	var per_op: Dictionary = data.get("per_op", {})
	var officers_dead := 0
	for o in w.ops:
		if o.officer_id != "" and o.state == "dead":
			officers_dead += 1
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
			var c := open_case(r, top["kind"], txt, best_ev, String(top["place"]))
			c["findings"] = mine.size()
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
	# what the operation cost: overtime for everyone sent, and the restock
	var ot: int = n_off * (Courses.OVERTIME + (Courses.NIGHT_PREMIUM if w.night else 0))
	spend("Overtime, operation %d (%d officers)" % [ops_run, n_off], ot)
	spend("Restock, operation %d" % ops_run, int(round(restock)))
	lines.append("Cost: $%s overtime, $%s to restock. Account: $%s." % [money(ot), money(int(round(restock))), money(balance)])
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
	week += 1
	for r in officers:
		var due: bool = int(r["out_until"]) <= week
		match r["status"]:
			"injured":
				if due:
					r["status"] = "active"
					r["file"].append({"week": week, "text": "Back on duty."})
					lines.append("%s %s is back on duty." % [r["rank"], r["name"]])
			"training":
				if due:
					r["status"] = "active"
					lines.append(_finish_course(r))
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
		if r["status"] not in ["dead", "fired", "resigned"]:
			r["trauma"] = maxf(0.0, float(r["trauma"]) - 0.5)
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
		lines.append("The account is $%s in the red: hiring, training and new kit are frozen. The council has noticed (%d week%s in deficit)." % [money(-balance), deficit_weeks, "" if deficit_weeks == 1 else "s"])
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
		"cases": cases.duplicate(true), "case_serial": case_serial, "deficit_weeks": deficit_weeks, "morale_home": morale_home}


func from_data(d: Dictionary) -> bool:
	var ver := int(d.get("version", 0))
	if ver < 1 or ver > VERSION:
		return false
	seed_val = int(d["seed"])
	week = int(d["week"])
	serial = int(d["serial"])
	ops_run = int(d["ops_run"])
	bodycams = bool(d.get("bodycams", false))
	rng.seed = seed_val
	rng.state = String(d["rng_state"]).to_int()
	names = Names.new(seed_val * 7 + 3 + serial)
	officers = []
	for r0 in d["officers"]:
		var r: Dictionary = r0
		# JSON has no integers: restore them
		for k in ["badge", "hired_week", "out_until", "judgment", "temper", "integrity", "exp", "xp", "ops", "shots",
				"hits", "kills", "civ_hits", "wounded", "arrests", "orders_broken", "drill"]:
			r[k] = int(r.get(k, 0))
		r["trauma"] = float(r.get("trauma", 0.0))
		# version 1 (v0.5-v0.6) had no years of service, version 2 (v0.7) no kit
		r["years"] = float(r.get("years", 0.0))
		r["kit"] = Equipment.normalize(r.get("kit", Equipment.default_kit()))
		r["kit"]["plates"] = int(r["kit"]["plates"])
		for gk in r["kit"]["gear"]:
			r["kit"]["gear"][gk] = int(r["kit"]["gear"][gk])
		for fe in r["file"]:
			fe["week"] = int(fe["week"])
		# version 4 and earlier (before v0.8.5): the kit they carry counts as issued
		r["issued"] = int(r.get("issued", Equipment.cost(r["kit"])))
		r["tactical"] = bool(r.get("tactical", false))
		r["course"] = String(r.get("course", ""))
		r["courses"] = r.get("courses", [])
		officers.append(r)
	# version 3 and earlier (before v0.8) had no pair bonds: everyone starts as strangers
	bonds = {}
	for bk in d.get("bonds", {}):
		bonds[bk] = int(d["bonds"][bk])
	history = d.get("history", [])
	notes = d.get("notes", [])
	# version 4 and earlier had no budget: the city sets it from the payroll now
	if d.has("allocation"):
		allocation = int(d["allocation"])
		balance = int(d["balance"])
		morale = int(d.get("morale", Courses.MORALE0))
		case_serial = int(d.get("case_serial", 0))
		deficit_weeks = int(d.get("deficit_weeks", 0))
		morale_home = int(d.get("morale_home", Courses.MORALE0))
		ledger = d.get("ledger", [])
		for le in ledger:
			le["week"] = int(le["week"])
			le["amount"] = int(le["amount"])
		cases = d.get("cases", [])
		for c in cases:
			c["week"] = int(c["week"])
	else:
		allocation = int(round(payroll() * (1.0 + Courses.HEADROOM) / 500.0)) * 500
		balance = Courses.RESERVE
		morale = Courses.MORALE0
		ledger = []
		cases = []
	for n in notes:
		n["week"] = int(n["week"])
	return true


func save(path := SAVE_PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_data(), "\t"))
	f.close()
	return true


static func load_from(path := SAVE_PATH):
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(d) != TYPE_DICTIONARY:
		return null
	var dep = load("res://scripts/campaign/department.gd").new()
	if not dep.from_data(d):
		return null
	return dep
