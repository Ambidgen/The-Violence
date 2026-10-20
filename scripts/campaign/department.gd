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

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Squads = preload("res://scripts/data/squads.gd")
const Names = preload("res://scripts/data/names.gd")

const VERSION := 4        # 3: v0.7.5, every officer has a kit; 4: v0.8, pair bonds
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
	if n > 0:
		for k in n:
			hire("Officer", 0)
	else:
		for f in FOUNDING:
			hire(f[0], f[2], false, float(f[1]))
	note("Department inherited: %d officers (%d with five years or more on the job)." % [officers.size(),
		officers.filter(func(r): return float(r.get("years", 0.0)) >= 5.0).size()])


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
		"kit": Equipment.default_kit()}
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
	for o in w.ops:
		if o.officer_id == "":
			continue
		var r := get_officer(o.officer_id)
		if r.is_empty():
			continue
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
		elif o.state == "down":
			r["status"] = "injured"
			r["out_until"] = week + 8 + rng.randi_range(0, 6)
			r["wounded"] += 1
			r["file"].append({"week": week, "text": "Seriously wounded; out until week %d." % r["out_until"]})
			lines.append("%s is seriously wounded: out until week %d." % [who, r["out_until"]])
		elif hurt:
			r["status"] = "injured"
			r["out_until"] = week + 2 + rng.randi_range(0, 3)
			r["wounded"] += 1
			r["file"].append({"week": week, "text": "Wounded; out until week %d." % r["out_until"]})
			lines.append("%s is wounded: out until week %d." % [who, r["out_until"]])
		# findings that name this officer go into their file
		for f in data.get("findings", []):
			if f["by"] == o.id and f["kind"] in ["civilian_hit_by_police", "excessive_force", "misjudgment", "friendly_fire", "jumpy_fire"]:
				r["file"].append({"week": week, "text": "Finding: %s (%s; evidence: %s)." % [f["text"], f["place"], f["strength"]]})
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
	var s: Dictionary = data.get("summary", {})
	history.append({"week": week, "op": ops_run, "map": map_name, "seed": w.seed_used, "summary": s.duplicate(true)})
	if history.size() > 200:
		history = history.slice(history.size() - 200)
	note("Operation %d at %s: %d civilians hit, %d suspects down, %d arrested, %d findings." % [ops_run, map_name,
		int(s.get("civ_hit", 0)), int(s.get("suspects_down", 0)), int(s.get("arrested", 0)), int(s.get("findings", 0))])
	return lines


## A week passes: wounds heal, trauma eases a little.
func next_week() -> Array:
	week += 1
	var lines: Array = []
	for r in officers:
		if r["status"] == "injured" and int(r["out_until"]) <= week:
			r["status"] = "active"
			r["file"].append({"week": week, "text": "Back on duty."})
			lines.append("%s %s is back on duty." % [r["rank"], r["name"]])
		if r["status"] != "dead":
			r["trauma"] = maxf(0.0, float(r["trauma"]) - 0.5)
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
		"history": history.duplicate(true), "notes": notes.duplicate(true), "bonds": bonds.duplicate()}


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
				"hits", "kills", "civ_hits", "wounded", "arrests", "orders_broken"]:
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
		officers.append(r)
	# version 3 and earlier (before v0.8) had no pair bonds: everyone starts as strangers
	bonds = {}
	for bk in d.get("bonds", {}):
		bonds[bk] = int(d["bonds"][bk])
	history = d.get("history", [])
	notes = d.get("notes", [])
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
