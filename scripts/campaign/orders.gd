extends RefCounted
## Orders (v0.7): what the player can tell each squad before Run, and what it costs.
##
## Every squad gets one objective free; a second costs a point. Constraints cost points.
## The squad leader's experience sets how many points the squad has: a green sergeant
## can carry one constraint, a veteran lieutenant five.

const Habits = preload("res://scripts/data/habits.gd")

const POINTS := [0, 1, 2, 3, 5, 7]      # by the leader's experience tier (1-5)
const RANKS := ["Officer", "Corporal", "Sergeant", "Lieutenant", "Captain"]
const MAX_SQUADS := 5
const MAX_SQUAD := 6

const OBJECTIVES := {
	"clear": {"name": "Clear", "desc": "Clear the building, or only the rooms you pick (and the rooms on the way to them). Done when they are clear."},
	"arrest": {"name": "Arrest", "desc": "Clear the building to arrest the named suspect: officers hold fire on them unless they attack, and challenge instead."},
	"rescue": {"name": "Rescue", "desc": "Clear to the hostages and walk each one out to the casualty point by the vehicles."},
	"contain": {"name": "Contain", "desc": "Posts outside the doors and windows you pick. Anyone coming out is challenged."},
	"post": {"name": "Post", "desc": "Stand at a point for the whole event, facing the way you set."},
	"patrol": {"name": "Patrol route", "desc": "Walk a route you draw, again and again; go to any contact."},
}
const CONSTRAINTS := {
	"avoid": {"name": "Avoid", "cost": 1, "desc": "Never go through the rooms you pick (a point per room). Chasing a contact can break it."},
	"consolidate": {"name": "Consolidate", "cost": 1, "desc": "Hold the room you pick, covering every door off it, for 20 s before going on. Rushing breaks it."},
	"phase": {"name": "Phase line", "cost": 1, "desc": "Wait at the start until a time, or until another squad has met its first objective."},
	"entry": {"name": "Entry point", "cost": 1, "desc": "Make the first entry through the door you pick."},
	"pace": {"name": "Pace", "cost": 1, "desc": "Walk (or creep) only, unless in a fight: slower and quieter."},
	"tight": {"name": "Weapons tight", "cost": 1, "desc": "Fire only at someone firing or pointing a weapon at police. Armed is not enough."},
	"knock": {"name": "Knock and announce", "cost": 1, "desc": "Announce at the door and give the occupants ten seconds: suspects get time, civilians get to put their hands up."},
	"pistols": {"name": "Pistols only", "cost": 1, "desc": "Rifles stay in the car: fewer rounds through walls, less reach."},
	"less": {"name": "Less-lethal first", "cost": 1, "desc": "Inside 4 m, challenge once and use OC, taser or baton on anyone not firing or pointing a weapon. A weapon raised or a shot fired lifts the rule."},
}


static func empty_orders(kind := "clear") -> Dictionary:
	return {"objs": [{"kind": kind, "rooms": []}], "avoid": [], "consolidate": "", "phase": {}, "entry": "", "pace": "",
		"tight": false, "knock": false, "pistols": false, "less": false}


static func rank_i(r: Dictionary) -> int:
	return RANKS.find(String(r.get("rank", "Officer")))


## The squad's leader: the highest rank, ties to the most experience.
static func leader(records: Array):
	var best = null
	for r in records:
		if best == null or rank_i(r) > rank_i(best) or (rank_i(r) == rank_i(best) and int(r["xp"]) > int(best["xp"])):
			best = r
	return best


static func points_for(records: Array) -> int:
	var ld = leader(records)
	if ld == null:
		return 0
	return POINTS[clampi(int(ld["exp"]), 1, 5)]


## Points an order set uses: a second objective, then each constraint.
static func cost(od: Dictionary) -> int:
	var c := maxi(0, od.get("objs", []).size() - 1)
	c += od.get("avoid", []).size() * int(CONSTRAINTS["avoid"]["cost"])
	if od.get("consolidate", "") != "":
		c += 1
	if not od.get("phase", {}).is_empty():
		c += 1
	if od.get("entry", "") != "":
		c += 1
	if od.get("pace", "") != "":
		c += 1
	if od.get("tight", false):
		c += 1
	if od.get("knock", false):
		c += 1
	if od.get("pistols", false):
		c += 1
	if od.get("less", false):
		c += 1
	return c


## One line per order, for the plan and the debrief.
static func describe(od: Dictionary, lv) -> Array:
	var out: Array = []
	for i in od.get("objs", []).size():
		var ob: Dictionary = od["objs"][i]
		var k: String = ob.get("kind", "clear")
		var t: String = OBJECTIVES[k]["name"]
		match k:
			"clear", "rescue":
				var rooms: Array = ob.get("rooms", [])
				t += (": " + ", ".join(rooms.map(func(r): return _room(lv, r)))) if not rooms.is_empty() else (" the building" if k == "clear" else " the hostages")
			"arrest":
				t += " " + String(ob.get("target_name", "the named suspect"))
			"contain":
				t += ": %d opening%s" % [ob.get("openings", []).size(), "" if ob.get("openings", []).size() == 1 else "s"]
			"post":
				t += " at the marked point"
			"patrol":
				t += ": %d waypoints" % ob.get("route", []).size()
		out.append(("Then: " if i > 0 else "") + t)
	if not od.get("avoid", []).is_empty():
		out.append("Avoid: " + ", ".join(od["avoid"].map(func(r): return _room(lv, r))))
	if od.get("consolidate", "") != "":
		out.append("Consolidate: " + _room(lv, od["consolidate"]))
	var ph: Dictionary = od.get("phase", {})
	if not ph.is_empty():
		out.append("Phase line: " + (("wait %d s" % int(ph.get("t", 0))) if ph.get("kind", "") == "time" else ("wait for squad %d" % (int(ph.get("squad", 0)) + 1))))
	if od.get("entry", "") != "":
		out.append("Entry point: " + String(od["entry"]).to_lower())
	if od.get("pace", "") != "":
		out.append("Pace: " + String(od["pace"]))
	if od.get("tight", false):
		out.append("Weapons tight")
	if od.get("less", false):
		out.append("Less-lethal first inside 4 m")
	if od.get("knock", false):
		out.append("Knock and announce")
	if od.get("pistols", false):
		out.append("Pistols only")
	return out


static func _room(lv, rm: String) -> String:
	if lv != null and lv.rooms.has(rm):
		return String(lv.rooms[rm]["title"]).to_lower()
	return rm.to_lower()
