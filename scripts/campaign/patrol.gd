extends RefCounted
## Patrol encounters (2026-11-05, owner request): one a day, seven a week.
##
## A patrol pair (always two officers) radios in that it is responding to something,
## with the basic details. The chief answers:
##   0  Proceed, no backup: the right call for most of what a patrol meets.
##   1  Proceed, backup en route: for what may be urgent and dangerous; riskier than 2.
##   2  Wait for backup: the lowest risk to officers; the time it takes can cost the outcome.
##
## Most encounters are resolved on the desk: a roll from the encounter, the pair's
## judgment and the choice, read back as a short report. An encounter that turns out to
## involve an armed suspect becomes a small operation (type "patrol") that plays out in
## the tactical sim with the pair, and the backup if one was called.
##
## Every random number an encounter needs is rolled when it is made (escalation, lateness,
## who is armed), so the three choices are judged against the same street: the choice
## changes the thresholds, never the dice. Answering is never required: at the end of the
## week anything left unanswered is handled by the pair on their own (choice 0).

const Situations = preload("res://scripts/campaign/situations.gd")
const City = preload("res://scripts/campaign/city.gd")
const Orders = preload("res://scripts/campaign/orders.gd")

const DAYS := ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
const PER_WEEK := 7

const CHOICES := [
	{"id": "proceed", "name": "Proceed", "short": "no backup",
		"desc": "The pair handles it now, on their own."},
	{"id": "enroute", "name": "Proceed, backup en route", "short": "backup en route",
		"desc": "The pair goes in now; a second car is on its way."},
	{"id": "wait", "name": "Wait for backup", "short": "waited for backup",
		"desc": "The pair holds back until the second car arrives. Safest for officers; the time it takes may cost the outcome."},
]
## By choice: how much of an encounter's danger turns into violence (a second car on the
## way, or already there, makes a fight less likely and shorter), how much of its urgency
## arrives too late, and the overtime the second car costs.
const ESCALATE := [1.0, 0.45, 0.12]
const HARM_SCALE := [1.0, 0.7, 0.5]
const LATE := [0.0, 0.05, 0.7]
const OVERTIME := [0, 150, 200]
## The sim: the second car reaches the scene this long after the pair (choice 1).
const BACKUP_T := 75.0

## The encounters. w: weight in the draw (the routine ten sum to 75 of 100, the call the
## owner set: proceeding alone is right about three times in four). urgent: how much
## waiting costs (0-1). danger: the chance it turns violent if the pair goes in alone,
## at average judgment. harm: what violence does to an officer. victim: the chance
## someone is hurt when police arrive too late (victim_kill: of those, killed). arrest:
## the chance of an arrest when it goes to plan. armed: the chance the suspect has a gun,
## which sends the encounter to the sim (base: the site type it uses; civs: bystanders).
## alert and flight: the armed suspect's readiness and wish to run.
const KINDS := {
	"traffic": {"name": "Traffic stop", "w": 12, "urgent": 0.0, "danger": 0.04, "harm": "minor", "victim": 0.0, "arrest": 0.12, "armed": 0.0,
		"dispatch": ["stopping a car that ran the light at %s", "pulling over a pickup with no plates on %s"],
		"ok": "A ticket and a warning. The driver was sorry, or said so.",
		"esc": "The driver came out of the car swinging. He was taken down and cuffed.",
		"late": "Nobody to stop: the car was long gone."},
	"noise": {"name": "Noise complaint", "w": 9, "urgent": 0.1, "danger": 0.03, "harm": "minor", "victim": 0.0, "arrest": 0.02, "armed": 0.0,
		"dispatch": ["a party that will not stop, %s", "a neighbour's complaint about shouting and music, %s"],
		"ok": "The music went down. The neighbour says thank you, which is rare.",
		"esc": "A guest took exception to the uniform. It ended in a scuffle on the stairs.",
		"late": "By the time anyone knocked, the neighbour had called the councillor instead."},
	"shoplift": {"name": "Shoplifter held by security", "w": 8, "urgent": 0.3, "danger": 0.03, "harm": "minor", "victim": 0.0, "arrest": 0.75, "armed": 0.0,
		"dispatch": ["store security holding a shoplifter, %s", "a pharmacy clerk holding a man who filled his coat, %s"],
		"ok": "Booked and released with a court date.",
		"esc": "He ran for the door through the officers. He did not get far.",
		"late": "Security could not hold him: he walked out before the car came."},
	"welfare": {"name": "Welfare check", "w": 8, "urgent": 0.6, "danger": 0.01, "harm": "minor", "victim": 0.35, "victim_kill": 0.15, "arrest": 0.0, "armed": 0.0,
		"dispatch": ["checking on an elderly man nobody has seen in three days, %s", "a daughter out of town who cannot reach her mother, %s"],
		"ok": "Found on the floor, cold and frightened but alive. An ambulance took her in.",
		"esc": "A confused, frightened resident lashed out at the officers before he knew them.",
		"late": "The ambulance came too late to do much."},
	"collision": {"name": "Collision, no injuries reported", "w": 7, "urgent": 0.3, "danger": 0.02, "harm": "minor", "victim": 0.0, "arrest": 0.08, "armed": 0.0,
		"dispatch": ["a fender-bender blocking the lane at %s", "two cars and an argument at %s"],
		"ok": "Details exchanged, a tow called, the lane open again.",
		"esc": "The argument turned into a fight before the officers got between them.",
		"late": "The drivers settled it with fists while they waited. Both went to hospital."},
	"lost_child": {"name": "Lost child", "w": 6, "urgent": 0.7, "danger": 0.0, "harm": "minor", "victim": 0.3, "victim_kill": 0.0, "arrest": 0.0, "armed": 0.0,
		"dispatch": ["a seven-year-old missing from the playground, %s", "a mother who lost her son in the market crowd, %s"],
		"ok": "Found two streets over, eating someone else's chips. Returned.",
		"esc": "Found, and a frantic father took his fear out on the officers.",
		"late": "Found hours later by a stranger, cold and hurt from a fall."},
	"suspicious": {"name": "Suspicious person", "w": 7, "urgent": 0.1, "danger": 0.06, "harm": "minor", "victim": 0.0, "arrest": 0.15, "armed": 0.0,
		"dispatch": ["a man sitting in a parked car for three hours, %s", "someone trying car doors along %s"],
		"ok": "A man waiting for his shift, or a warrant out for him: either way, sorted.",
		"esc": "He did not want to talk and did not want to be searched. It got physical.",
		"late": "Whoever it was had moved on."},
	"vandalism": {"name": "Vandalism in progress", "w": 6, "urgent": 0.4, "danger": 0.05, "harm": "minor", "victim": 0.0, "arrest": 0.45, "armed": 0.0,
		"dispatch": ["kids breaking windows at a closed school, %s", "someone smashing car windows on %s"],
		"ok": "Caught paint-handed and taken home to their parents, or booked.",
		"esc": "One of them threw a bottle at the officers. Arrests followed.",
		"late": "Glass everywhere and nobody to arrest."},
	"intox": {"name": "Intoxicated man in the road", "w": 6, "urgent": 0.5, "danger": 0.05, "harm": "minor", "victim": 0.25, "victim_kill": 0.2, "arrest": 0.1, "armed": 0.0,
		"dispatch": ["a man lying in the road, %s", "a drunk weaving through traffic on %s"],
		"ok": "Walked to the kerb and driven to the shelter.",
		"esc": "He fought being helped, the way drunks do.",
		"late": "A car found him before the officers did."},
	"alarm": {"name": "Burglar alarm", "w": 6, "urgent": 0.3, "danger": 0.04, "harm": "minor", "victim": 0.0, "arrest": 0.3, "armed": 0.08, "base": "barricade", "civs": 0,
		"alert": 0, "flight": 0.7,
		"dispatch": ["an alarm at a closed shop, %s", "a back-door alarm at a warehouse office, %s"],
		"ok": "A burglar caught with the till drawer, or a raccoon.",
		"esc": "A burglar with a crowbar did not want to come quietly.",
		"late": "The till empty, the back door open, nobody inside."},
	# the dangerous quarter
	"bar_fight": {"name": "Fight outside a bar", "w": 6, "urgent": 0.7, "danger": 0.35, "harm": "serious", "victim": 0.45, "victim_kill": 0.1, "arrest": 0.6, "armed": 0.0,
		"dispatch": ["a fight spilling out of a bar, %s; the caller counts five or six", "a brawl outside a club on %s, a man on the ground"],
		"ok": "Pulled apart and the two worst booked. Nobody badly hurt.",
		"esc": "The crowd turned on the officers when they made the arrests.",
		"late": "By the time anyone arrived, a man on the ground had been kicked unconscious."},
	"domestic": {"name": "Domestic disturbance", "w": 7, "urgent": 0.8, "danger": 0.35, "harm": "serious", "victim": 0.4, "victim_kill": 0.12, "arrest": 0.55, "armed": 0.15, "base": "warrant", "civs": 1,
		"alert": 1, "flight": 0.3,
		"dispatch": ["screaming and breaking glass in a flat, %s", "a woman's call cut off mid-sentence, %s"],
		"ok": "He was cuffed in the kitchen; she gave a statement.",
		"esc": "He came at the first officer through the door.",
		"late": "She was hurt before anyone got there."},
	"robbery": {"name": "Armed robbery in progress", "w": 3, "urgent": 0.8, "danger": 0.5, "harm": "serious", "victim": 0.35, "victim_kill": 0.3, "arrest": 0.5, "armed": 1.0, "base": "barricade", "civs": 1,
		"alert": 1, "flight": 0.6,
		"dispatch": ["a silent alarm and a man with a gun at the counter, %s", "a clerk's panic button at a corner store, %s"],
		"ok": "Taken at the counter.",
		"esc": "He fired at the officers in the doorway.",
		"late": "Gone with the till, and the clerk shot."},
	"shots": {"name": "Shots fired", "w": 3, "urgent": 0.6, "danger": 0.4, "harm": "serious", "victim": 0.3, "victim_kill": 0.3, "arrest": 0.35, "armed": 0.6, "base": "warrant", "civs": 1,
		"alert": 1, "flight": 0.5,
		"dispatch": ["several calls reporting shots, %s", "two shots heard from a house, %s"],
		"ok": "Fireworks, a car backfiring, or a shooter long gone: nobody hurt.",
		"esc": "Someone in the house was still angry, and had more than a gun's worth of reasons.",
		"late": "A man shot on the porch, found by the neighbours first."},
	"crisis": {"name": "Man in crisis with a knife", "w": 3, "urgent": 0.2, "danger": 0.55, "harm": "lethal", "victim": 0.2, "victim_kill": 0.25, "arrest": 0.4, "armed": 0.0,
		"dispatch": ["a man with a kitchen knife shouting in the street, %s; his sister called", "a man on a balcony with a knife, threatening himself, %s"],
		"ok": "Talked down. The knife on the ground, the man in an ambulance.",
		"esc": "He rushed the officers with the knife.",
		"late": "He hurt himself before anyone could reach him."},
	"gun_seen": {"name": "Man with a gun", "w": 3, "urgent": 0.05, "danger": 0.6, "harm": "serious", "victim": 0.1, "victim_kill": 0.3, "arrest": 0.5, "armed": 1.0, "base": "warrant", "civs": 0,
		"alert": 0, "flight": 0.4,
		"dispatch": ["a man seen with a handgun in his waistband going into a house, %s; nobody threatened", "a resident reporting a neighbour cleaning a pistol on the porch, drunk, %s"],
		"ok": "Taken without a shot.",
		"esc": "He reached for the gun.",
		"late": "He was gone before anyone arrived."},
}
## Handguns an armed patrol suspect carries: the .22 is the street's cheapest.
const STREET_GUNS := [["light_pistol", 0.4], ["service_pistol", 0.3], ["compact_pistol", 0.2], ["heavy_pistol", 0.1]]


## The week's seven encounters. dept supplies the pair named in each dispatch.
static func week_encounters(seed_val: int, wk: int, dept) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 6151 + wk * 92821 + 17
	var out: Array = []
	var kinds: Array = KINDS.keys()
	kinds.sort()
	var total := 0.0
	for k in kinds:
		total += float(KINDS[k]["w"])
	for day in PER_WEEK:
		var r := rng.randf() * total
		var kind: String = kinds[0]
		for k2 in kinds:
			r -= float(KINDS[k2]["w"])
			if r <= 0.0:
				kind = k2
				break
		out.append(make(kind, rng.randi(), wk, day, dept))
	return out


## One encounter of a kind. The dice are rolled here, once.
static func make(kind: String, seed_v: int, wk: int, day: int, dept = null) -> Dictionary:
	var spec: Dictionary = KINDS[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ward_i := rng.randi() % Situations.WARDS.size()
	var ward: String = Situations.WARDS[ward_i]["name"]
	var where := _street(rng, String(City.WARD_IDS[ward_i]))
	var lines: Array = spec["dispatch"]
	var text: String = String(lines[rng.randi() % lines.size()]) % where
	var e := {"id": "P%d-%d" % [wk, day + 1], "week": wk, "day": day, "kind": kind, "seed": seed_v,
		"ward_i": ward_i, "ward": ward, "where": where, "dispatch": text, "status": "pending", "choice": -1,
		"pair": [], "backup": [], "result": {},
		# the street, rolled once (see the header)
		"esc_roll": rng.randf(), "late_roll": rng.randf(), "harm_roll": rng.randf(), "victim_roll": rng.randf(),
		"arrest_roll": rng.randf(), "force_roll": rng.randf(), "trust_roll": rng.randf(),
		"armed": rng.randf() < float(spec.get("armed", 0.0)), "night": rng.randf() < 0.45}
	if dept != null:
		e["pair"] = pick_officers(e, dept, 2, [])
	return e


## Officers for an encounter: fit officers, chosen by the encounter's own seed, so the
## same week names the same pair. exclude: ids already picked.
static func pick_officers(e: Dictionary, dept, n: int, exclude: Array) -> Array:
	var pool: Array = dept.available().filter(func(r): return not exclude.has(r["id"]))
	pool.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(e["seed"]) * 3 + 1 + exclude.size() * 101
	var out: Array = []
	while out.size() < n and not pool.is_empty():
		out.append(String(pool.pop_at(rng.randi() % pool.size())["id"]))
	return out


## Keep the named pair if they are still fit; otherwise the radio names someone else.
static func refresh_pair(e: Dictionary, dept) -> void:
	var keep: Array = []
	for oid in e.get("pair", []):
		var r: Dictionary = dept.get_officer(String(oid))
		if not r.is_empty() and r["status"] == "active":
			keep.append(String(oid))
	if keep.size() < 2:
		keep.append_array(pick_officers(e, dept, 2 - keep.size(), keep))
	e["pair"] = keep


static func _street(rng: RandomNumberGenerator, ward_id: String) -> String:
	var names: Array = []
	for st in City.data().get("streets", []):
		if st is Dictionary and String(st.get("ward", "")) == ward_id and String(st.get("name", "")) != "" and String(st.get("kind", "")) != "quay":
			if not names.has(st["name"]):
				names.append(st["name"])
	names.sort()
	if names.size() < 2:
		return "the %d block of Main Street" % (100 * rng.randi_range(1, 9))
	var a: String = names[rng.randi() % names.size()]
	if rng.randf() < 0.5:
		return "the %d block of %s" % [100 * rng.randi_range(1, 12), a]
	var b: String = names[rng.randi() % names.size()]
	if b == a:
		b = names[(names.find(a) + 1) % names.size()]
	return "%s and %s" % [a, b]


# ================================================================== reading it
static func spec(e: Dictionary) -> Dictionary:
	return KINDS.get(String(e.get("kind", "")), KINDS["noise"])


## What the radio says: who is responding, to what, where.
static func radio_line(e: Dictionary, dept) -> String:
	var names: Array = []
	for oid in e.get("pair", []):
		var r: Dictionary = dept.get_officer(String(oid))
		if not r.is_empty():
			names.append("%s %s" % [r["rank"], r["name"]])
	var who: String = " and ".join(names) if not names.is_empty() else "A patrol car"
	return "%s responding to %s (%s)." % [who, String(e["dispatch"]), String(e["ward"])]


## How the dispatch reads to the chief: the public half of the encounter, as words.
static func read(e: Dictionary) -> Dictionary:
	var s := spec(e)
	var u: float = float(s["urgent"])
	var d: float = float(s["danger"])
	return {"urgency": "urgent" if u >= 0.6 else ("time matters" if u >= 0.3 else "no rush"),
		"danger": "dangerous" if d >= 0.3 else ("could turn" if d >= 0.06 else "routine")}


static func pending(list: Array) -> Array:
	return list.filter(func(e): return String(e["status"]) == "pending")


## The day that answers next (encounters come in order, one a day).
static func next_pending(list: Array) -> Dictionary:
	for e in list:
		if String(e["status"]) == "pending":
			return e
	return {}


# ================================================================== resolving it
## Mean judgment of the officers at the scene, as a factor on the danger: 1.0 at the
## academy's 50, lower for the calm and experienced.
static func judgment_factor(dept, ids: Array) -> float:
	var tot := 0.0
	var n := 0
	for oid in ids:
		var r: Dictionary = dept.get_officer(String(oid))
		if not r.is_empty():
			tot += float(r.get("judgment", 50))
			n += 1
	var j: float = tot / n if n > 0 else 50.0
	return clampf(1.3 - 0.006 * j, 0.6, 1.3)


## Does waiting (or the second car's trip) cost this encounter its outcome?
static func is_late(e: Dictionary, choice: int) -> bool:
	return float(e["late_roll"]) < float(spec(e)["urgent"]) * LATE[choice]


## Does it turn violent?
static func escalates(e: Dictionary, choice: int, jf: float) -> bool:
	return float(e["esc_roll"]) < float(spec(e)["danger"]) * ESCALATE[choice] * jf


## The harm to one officer when it turns violent, from the encounter's harm class.
static func harm_of(e: Dictionary, choice: int) -> String:
	var h: float = float(e["harm_roll"]) / HARM_SCALE[choice]
	match String(spec(e)["harm"]):
		"lethal":
			return "dead" if h < 0.05 else ("down" if h < 0.3 else ("hurt" if h < 0.7 else ""))
		"serious":
			return "dead" if h < 0.015 else ("down" if h < 0.165 else ("hurt" if h < 0.6 else ""))
	return "hurt" if h < 0.3 else ""


## Resolve an encounter on the desk. Returns the result; the caller applies it (money,
## officers, the city) through apply().
static func resolve_desk(e: Dictionary, choice: int, dept) -> Dictionary:
	var s := spec(e)
	var at: Array = (e["pair"] as Array) + (e.get("backup", []) as Array)
	var jf := judgment_factor(dept, at)
	var late := is_late(e, choice)
	var esc := false if late else escalates(e, choice, jf)
	var res := {"kind": "success", "late": late, "escalated": esc, "officers_hurt": 0, "officers_killed": 0,
		"civ_hurt": 0, "civ_killed": 0, "arrests": 0, "harm": "", "complaint": false, "trust": 0, "text": ""}
	if late:
		res["text"] = String(s["late"])
		if float(e["victim_roll"]) < float(s.get("victim", 0.0)):
			res["kind"] = "failure"
			if float(e["victim_roll"]) < float(s.get("victim", 0.0)) * float(s.get("victim_kill", 0.0)):
				res["civ_killed"] = 1
			else:
				res["civ_hurt"] = 1
			res["trust"] = -3
		else:
			res["kind"] = "partial"
			res["trust"] = -1
		return res
	if esc:
		res["text"] = String(s["esc"])
		res["harm"] = harm_of(e, choice)
		if res["harm"] == "dead":
			res["officers_killed"] = 1
			res["kind"] = "failure"
		elif res["harm"] != "":
			res["officers_hurt"] = 1
			res["kind"] = "partial"
		res["arrests"] = 1 if float(e["arrest_roll"]) < 0.8 else 0
		# force on the street draws complaints, more from a hot-tempered officer
		var temper := 40.0
		var r0: Dictionary = dept.get_officer(String(at[0])) if not at.is_empty() else {}
		if not r0.is_empty():
			temper = float(r0.get("temper", 40))
		if float(e["force_roll"]) < 0.15 * temper / 40.0:
			res["complaint"] = true
			res["trust"] = -1
		return res
	res["text"] = String(s["ok"])
	res["arrests"] = 1 if float(e["arrest_roll"]) < float(s.get("arrest", 0.0)) else 0
	# done well, and seen to be: the ward notices now and then
	if float(e["trust_roll"]) < 0.25:
		res["trust"] = 1
	return res


## Apply a desk result to the department: overtime, the hurt officer, a complaint.
## Returns lines for the report. The city's side is Politics.on_patrol.
static func apply(e: Dictionary, choice: int, res: Dictionary, dept) -> Array:
	var lines: Array = []
	var s := spec(e)
	if OVERTIME[choice] > 0 and not bool(e.get("overtime_paid", false)):
		dept.spend("Overtime, patrol backup (%s, %s)" % [String(s["name"]).to_lower(), DAYS[int(e["day"])]], OVERTIME[choice])
	var at: Array = (e["pair"] as Array) + (e.get("backup", []) as Array)
	if String(res.get("harm", "")) != "" and not at.is_empty():
		# the first through the door takes it
		var r: Dictionary = dept.get_officer(String(at[int(e["harm_roll"] * 1000.0) % mini(2, at.size())]))
		var ln: String = dept.patrol_casualty(r, String(res["harm"]), String(s["name"]).to_lower())
		if ln != "":
			lines.append(ln)
	if bool(res.get("complaint", false)) and not at.is_empty():
		var r2: Dictionary = dept.get_officer(String(at[0]))
		if not r2.is_empty() and r2["status"] != "dead":
			var c: Dictionary = dept.open_case(r2, "excessive_force", "a complaint of force at a %s (%s)" % [String(s["name"]).to_lower(), String(e["where"])], "witness", String(e["where"]))
			lines.append("Internal affairs: %s opened on %s %s (a complaint from the street)." % [c["id"], r2["rank"], r2["name"]])
	for oid in at:
		var r3: Dictionary = dept.get_officer(String(oid))
		if not r3.is_empty() and r3["status"] != "dead":
			r3["file"].append({"week": int(e["week"]), "text": "Patrol, %s: %s." % [String(s["name"]).to_lower(), _label(res)]})
			r3["arrests"] = int(r3.get("arrests", 0)) + (int(res.get("arrests", 0)) if oid == at[0] else 0)
	return lines


static func _label(res: Dictionary) -> String:
	if bool(res.get("late", false)):
		return "too late" if String(res.get("kind", "")) == "failure" else "late"
	if bool(res.get("escalated", false)):
		return "it turned violent"
	return "handled"


## Nothing the chief has to read about: nobody hurt, no complaint (2026-11-11). The
## week's report folds these into one line; the radio's own list keeps every call.
static func uneventful(e: Dictionary) -> bool:
	var res: Dictionary = e.get("result", {})
	return (int(res.get("officers_killed", 0)) == 0 and int(res.get("officers_hurt", 0)) == 0
		and int(res.get("civ_killed", 0)) == 0 and int(res.get("civ_hurt", 0)) == 0
		and not bool(res.get("complaint", false)))


## One line for the board and the week's report.
static func summary_line(e: Dictionary) -> String:
	var res: Dictionary = e.get("result", {})
	var ch: String = String(CHOICES[clampi(int(e.get("choice", 0)), 0, 2)]["short"])
	var bits: Array = []
	if int(res.get("arrests", 0)) > 0:
		bits.append("%d arrest%s" % [int(res["arrests"]), "" if int(res["arrests"]) == 1 else "s"])
	if int(res.get("officers_killed", 0)) > 0:
		bits.append("an officer killed")
	elif int(res.get("officers_hurt", 0)) > 0:
		bits.append("an officer hurt")
	if int(res.get("civ_killed", 0)) > 0:
		bits.append("a civilian killed")
	elif int(res.get("civ_hurt", 0)) > 0:
		bits.append("a civilian hurt")
	if bool(res.get("complaint", false)):
		bits.append("a complaint")
	var tail := (" (%s)" % ", ".join(bits)) if not bits.is_empty() else ""
	return "%s, %s: %s%s" % [String(spec(e)["name"]), ch, String(res.get("text", "")), tail]


# ================================================================== the armed ones: a small operation
## The handgun an armed patrol suspect carries, by the encounter's own dice.
static func street_gun(e: Dictionary) -> String:
	var r: float = fmod(float(e["arrest_roll"]) * 7.0 + float(e["force_roll"]), 1.0)
	for g in STREET_GUNS:
		r -= float(g[1])
		if r <= 0.0:
			return String(g[0])
	return "service_pistol"


## The encounter as a situation for the sim: a site, one armed suspect and any
## bystanders, and the plan the choice makes (the pair now; the backup with a phase line
## if it is en route, or alongside if the pair waited). Returns {} for an unarmed one.
static func to_situation(e: Dictionary, choice: int, dept, trusts := [], community := true, used_sites := []) -> Dictionary:
	if not bool(e.get("armed", false)):
		return {}
	var spc := spec(e)
	var base: String = String(spc.get("base", "warrant"))
	var s: Dictionary = Situations.make(base, int(e["seed"]), int(e["week"]), 20 + int(e["day"]), trusts, community, used_sites)
	s["id"] = String(e["id"])
	s["type"] = "patrol"
	s["patrol_id"] = String(e["id"])
	s["patrol_kind"] = String(e["kind"])
	s["pressure"] = "high" if float(spc["urgent"]) >= 0.6 else "low"
	s["night"] = bool(e.get("night", false))
	s["title"] = "Patrol: %s, %s" % [String(spc["name"]), String(s.get("address", e["where"]))]
	# one armed suspect; the bystanders the encounter has (a clerk, a partner)
	var sus: Dictionary = {}
	for oc in s["occupants"]:
		if oc["role"] in ["suspect", "captor"]:
			sus = oc
			break
	if sus.is_empty():
		sus = {"role": "suspect", "room": "OUT"}
	sus["role"] = "suspect"
	sus["named"] = true
	sus["arms"] = "pistol"
	sus.erase("long_gun")
	sus["handgun"] = street_gun(e)
	sus["ech"] = "untrained" if float(e["esc_roll"]) < 0.6 else "militia"
	sus["vest"] = false
	sus["alert"] = int(spc.get("alert", 1))
	sus["flight"] = float(spc.get("flight", 0.4))
	s["named"] = String(sus.get("name", ""))
	var occ: Array = [sus]
	var n_civ: int = int(spc.get("civs", 0))
	for k in n_civ:
		occ.append({"role": "civilian", "room": sus.get("room", "OUT")})
	s["occupants"] = occ
	s["intel"] = []
	s["tips"] = []
	s["tip_count"] = 0
	s.erase("deadline")
	# a patrol walks up to an ordinary door, not a fortified one
	s["doors"] = {}
	var squads: Array = []
	var od0: Dictionary = Orders.empty_orders("arrest")
	squads.append({"members": (e["pair"] as Array).duplicate(), "stage": 0, "orders": od0})
	if choice >= 1 and not (e.get("backup", []) as Array).is_empty():
		var od1: Dictionary = Orders.empty_orders("arrest")
		if choice == 1:
			od1["phase"] = {"kind": "time", "t": BACKUP_T}
		squads.append({"members": (e["backup"] as Array).duplicate(), "stage": 1, "orders": od1})
	s["plan"] = {"squads": squads, "night": s["night"], "bodycams": bool(dept.bodycams), "kit": {}, "kit_mode": "own"}
	s["suggested"] = s["plan"].duplicate(true)
	return s


## Back from the sim: the operation's result read as the encounter's.
static func from_operation(e: Dictionary, op_res: Dictionary) -> Dictionary:
	var kind: String = String(op_res.get("kind", "failure"))
	var res := {"kind": "success" if kind in ["success", "quiet"] else ("partial" if kind == "partial" else "failure"),
		"late": false, "escalated": true, "sim": true, "officers_hurt": int(op_res.get("officers_hurt", 0)),
		"officers_killed": int(op_res.get("officers_killed", 0)), "civ_hurt": 0, "civ_killed": int(op_res.get("civ_killed", 0)),
		"arrests": int(op_res.get("arrests", 0)), "harm": "", "complaint": false, "trust": 0,
		"text": "Armed. It went to an operation: %s." % String(op_res.get("goal", "over"))}
	return res
