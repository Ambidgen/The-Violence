extends RefCounted
## Situations (v0.7): what lands on the operations board each week, and what the
## department knows about each one.
##
## Every situation has a true state (who is inside, where, armed with what, how ready
## to run) and a briefing: each fact appears as an estimate with a confidence until a
## tip confirms it. Tips come from the public (more at high visibility) and from the
## ward's community group (more where trust is high, none where it has broken). An
## officer sent to canvass the neighbourhood brings in two more, and is gone for the week.
##
## Visibility (1-5) is how many people are watching. Isolated wards sit at 1-2: more
## guns, fewer tips, mistakes that stay quiet for months. A rally sits at 5.

const Names = preload("res://scripts/data/names.gd")
const Maps = preload("res://scripts/maps/registry.gd")

## The six wards (one per precinct): trust in police (0-100), how isolated they are.
const WARDS := [
	{"name": "Northgate", "trust": 58, "isolated": 0.2},
	{"name": "Riverside", "trust": 40, "isolated": 0.4},
	{"name": "Old Town", "trust": 62, "isolated": 0.0},
	{"name": "Ironworks", "trust": 24, "isolated": 0.9},
	{"name": "Eastport", "trust": 44, "isolated": 0.5},
	{"name": "Kilbride", "trust": 30, "isolated": 0.7},
]
const STREETS := ["Alder", "Foundry", "Canal", "Kings", "Water", "Union", "Hope", "Bridge", "Station", "Chapel", "Harbour",
	"Mill", "Grand", "Market", "Tannery", "Coke Oven", "Ore Dock", "Slag", "Furnace", "Rail"]
const TYPES := {
	"warrant": {"name": "Warrant service", "maps": [0, 1, 2, 4, 5, 6], "vis": [1, 3], "pressure": "none",
		"blurb": "An arrest warrant for a named suspect at a home. You choose the hour."},
	"gang": {"name": "Gang house raid", "maps": [2, 4, 5, 7, 8, 9, 10], "vis": [1, 2], "pressure": "low",
		"blurb": "A house the crew uses to store guns and product. Several armed members, a few bystanders."},
	"barricade": {"name": "Barricaded suspect", "maps": [0, 1, 3, 4, 6], "vis": [2, 3], "pressure": "low",
		"blurb": "One armed suspect refuses to come out. Time is on your side, unless it is not."},
	"hostage": {"name": "Hostage", "maps": [0, 3, 4, 5, 6], "vis": [3, 4], "pressure": "high",
		"blurb": "Captors are holding people inside and have set a deadline."},
	"event": {"name": "Public event", "maps": [11], "vis": [5, 5], "pressure": "set by the event",
		"blurb": "A rally on Civic Plaza. Assign officers to posts and patrol routes. Almost always, nothing happens."},
}
const PRESSURE_NAMES := {"none": "None: you pick the hour", "low": "Low", "high": "High: a deadline", "extreme": "Extreme",
	"set by the event": "Set by the event"}


## This week's board: two or three situations, and a public event most weeks in
## election season. Deterministic for the campaign seed and the week.
static func board(seed_val: int, week: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 7919 + week * 104729
	var types: Array = ["warrant", "gang", "barricade", "hostage"]
	var picks: Array = []
	# a warrant and a gang house are common; barricades and hostages less so
	var weights := {"warrant": 1.0, "gang": 0.9, "barricade": 0.55, "hostage": 0.35}
	var n := 2 if rng.randf() < 0.45 else 3
	for k in n:
		var total := 0.0
		for t in types:
			total += weights[t] * (0.35 if picks.has(t) else 1.0)
		var r := rng.randf() * total
		var pick: String = types[0]
		for t2 in types:
			r -= weights[t2] * (0.35 if picks.has(t2) else 1.0)
			if r <= 0.0:
				pick = t2
				break
		picks.append(pick)
	# rallies come more often as the election nears
	if rng.randf() < 0.35 + week * 0.012:
		picks.append("event")
	var out: Array = []
	for i in picks.size():
		out.append(make(picks[i], rng.randi(), week, i))
	return out


## One situation of a type, from a seed.
static func make(type: String, seed_val: int, week := 1, idx := 0) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var spec: Dictionary = TYPES[type]
	var mi: int = spec["maps"][rng.randi() % spec["maps"].size()]
	var lv = Maps.get_level(mi)
	var ward_i := rng.randi() % WARDS.size()
	if type == "event":
		ward_i = 2
	elif type == "gang" and rng.randf() < 0.5:
		ward_i = [3, 5, 1][rng.randi() % 3]
	var ward: Dictionary = WARDS[ward_i]
	var vr: Array = spec["vis"]
	var vis := rng.randi_range(vr[0], vr[1])
	if ward["isolated"] > 0.6 and type != "event":
		vis = maxi(1, vis - 1)
	var names = Names.new(seed_val)
	var addr := "%d %s Street" % [rng.randi_range(3, 240), STREETS[rng.randi() % STREETS.size()]]
	var s := {"id": "W%d-%d" % [week, idx + 1], "week": week, "type": type, "seed": seed_val, "map": mi,
		"ward": ward["name"], "ward_i": ward_i, "trust": ward["trust"], "visibility": vis, "pressure": spec["pressure"],
		"address": addr if type != "event" else "Civic Plaza", "status": "open", "assigned": [], "canvass": [],
		"night": false, "plan": {}, "result": {}, "occupants": [], "intel": [], "tips": [], "named": ""}
	var rooms := _rooms(lv)
	match type:
		"warrant":
			var nm: String = names.gang_name(rng.randi() % 4)
			s["named"] = nm
			s["title"] = "Warrant: %s, %s" % [nm, addr]
			var room: String = rooms[rng.randi() % rooms.size()]
			var ech := "militia" if rng.randf() < 0.6 else "untrained"
			var arms := "rifle" if rng.randf() < 0.25 else "pistol"
			var flight := snappedf(rng.randf_range(0.3, 0.9), 0.05)
			s["occupants"].append({"role": "suspect", "name": nm, "named": true, "ech": ech, "room": room, "arms": arms,
				"flight": flight, "alert": 0})
			var n_assoc := 0 if rng.randf() < 0.55 else rng.randi_range(1, 2)
			for k in n_assoc:
				s["occupants"].append({"role": "suspect", "name": names.gang_name(rng.randi() % 4), "ech": "untrained" if rng.randf() < 0.6 else "militia",
					"room": rooms[rng.randi() % rooms.size()], "arms": "pistol", "flight": 0.3, "alert": 0})
			var n_fam := rng.randi_range(0, 3)
			for k2 in n_fam:
				s["occupants"].append({"role": "civilian", "room": rooms[rng.randi() % rooms.size()]})
			_room_fact(s, lv, "named_room", "Where %s sleeps" % nm, room, _guess_room(rng, rooms, room, 0.6), 0.5)
			_fact(s, "armed", "Armed occupants", _count_text(1 + n_assoc), _range_text(rng, 1 + n_assoc, 1), 0.4)
			_fact(s, "arms", "Weapons", "a rifle" if arms == "rifle" else "handguns", "handguns, probably", 0.6)
			_fact(s, "civs", "Others in the home", _civ_text(n_fam), "family, number unknown" if n_fam > 0 or rng.randf() < 0.5 else "lives alone, probably", 0.3)
			_fact(s, "flight", "Will he run?", "has run from police before" if flight >= 0.6 else "no record of running",
				"unknown", 0.2)
		"gang":
			var crew := rng.randi() % 4
			var crews := ["Kilbride Crew", "Corvino Family", "Los Halcones", "Zarya Bratva"]
			s["title"] = "%s house, %s" % [crews[crew], addr]
			var n := rng.randi_range(3, mini(8, 2 + rooms.size()))
			var rifles := 0
			for k3 in n:
				var r := rng.randf()
				var ech2 := "untrained" if r < 0.7 else ("militia" if r < 0.9 else "regular")
				var arms2 := "rifle" if (ech2 != "untrained" and rng.randf() < 0.5) else "pistol"
				if arms2 == "rifle":
					rifles += 1
				s["occupants"].append({"role": "suspect", "name": names.gang_name(crew), "ech": ech2, "room": rooms[rng.randi() % rooms.size()],
					"arms": arms2, "flight": 0.25, "alert": 1 if rng.randf() < 0.3 else 0})
			var lookout := rng.randf() < 0.4
			if lookout:
				for oc in s["occupants"]:
					oc["alert"] = 1
			var n_by := rng.randi_range(0, 3)
			for k4 in n_by:
				s["occupants"].append({"role": "civilian", "room": rooms[rng.randi() % rooms.size()]})
			_fact(s, "armed", "Armed members inside", _count_text(n), _range_text(rng, n, 2), 0.35)
			_fact(s, "arms", "Weapons", ("%d rifle%s" % [rifles, "" if rifles == 1 else "s"]) if rifles > 0 else "handguns only",
				"handguns, maybe a rifle", 0.4)
			_fact(s, "civs", "Bystanders inside", _civ_text(n_by), "unknown", 0.2)
			_fact(s, "alert", "Lookouts", "a lookout watches the street" if lookout else "no lookout", "unknown", 0.2)
		"barricade":
			var nm2: String = names.gang_name(rng.randi() % 4)
			s["named"] = nm2
			s["title"] = "Barricaded: %s, %s" % [nm2, addr]
			var room2: String = rooms[rng.randi() % rooms.size()]
			var ech3 := "militia" if rng.randf() < 0.7 else "regular"
			var arms3 := "rifle" if rng.randf() < 0.45 else "pistol"
			s["occupants"].append({"role": "suspect", "name": nm2, "named": true, "ech": ech3, "room": room2, "arms": arms3,
				"flight": 0.1, "alert": 1})
			var n_c := 0 if rng.randf() < 0.6 else 1
			for k5 in n_c:
				s["occupants"].append({"role": "civilian", "room": rooms[rng.randi() % rooms.size()]})
			_room_fact(s, lv, "named_room", "Where he is holed up", room2, _guess_room(rng, rooms, room2, 0.5), 0.5)
			_fact(s, "arms", "Weapons", "a rifle" if arms3 == "rifle" else "a handgun", "a handgun, he says", 0.4)
			_fact(s, "civs", "Anyone else inside", _civ_text(n_c), "nobody, probably", 0.4)
			_fact(s, "training", "Background", "ex-military" if ech3 == "regular" else "no military background", "unknown", 0.2)
		"hostage":
			var nm3: String = names.gang_name(rng.randi() % 4)
			s["named"] = nm3
			s["title"] = "Hostages: %s, %s" % [nm3, addr]
			var room3: String = rooms[rng.randi() % rooms.size()]
			var n_cap := rng.randi_range(1, 3)
			for k6 in n_cap:
				s["occupants"].append({"role": "captor", "name": nm3 if k6 == 0 else names.gang_name(rng.randi() % 4), "named": k6 == 0,
					"ech": "militia" if rng.randf() < 0.6 else "untrained", "room": room3 if k6 < 2 else rooms[rng.randi() % rooms.size()],
					"arms": "rifle" if rng.randf() < 0.35 else "pistol", "flight": 0.0, "alert": 1})
			var n_h := rng.randi_range(1, 3)
			for k7 in n_h:
				s["occupants"].append({"role": "hostage", "room": room3})
			s["deadline"] = rng.randi_range(5, 9) * 60
			_room_fact(s, lv, "hostage_room", "Where the hostages are", room3, _guess_room(rng, rooms, room3, 0.55), 0.5)
			_fact(s, "captors", "Hostage takers", _count_text(n_cap), _range_text(rng, n_cap, 1), 0.4)
			_fact(s, "hostages", "Hostages", "%d" % n_h, "%d or more" % maxi(1, n_h - 1), 0.5)
			s["intel"].append({"key": "deadline", "label": "Deadline", "truth": "they say they start killing at %d minutes" % (s["deadline"] / 60),
				"est": "", "known": true, "conf": 1.0})
		"event":
			var who: Array = ["Mayor Pruett", "Council President Garrow", "Councillor Halvorsen"]
			var cand: String = who[rng.randi() % who.size()]
			s["title"] = "Rally: %s, Civic Plaza" % cand
			s["candidate"] = cand
			s["duration"] = 15 * 60
			s["crowd"] = rng.randi_range(36, 54)
			# whether anything will happen is rolled now and never shown
			var p: float = 0.08 + (0.05 if cand == "Council President Garrow" else 0.0) + (0.04 if cand == "Councillor Halvorsen" else 0.0)
			s["attack"] = rng.randf() < p
			s["attack_p"] = p
			if s["attack"]:
				var n_att := 1 if rng.randf() < 0.7 else 2
				for k8 in n_att:
					s["occupants"].append({"role": "attacker", "name": names.diverse_name(0.5), "ech": "militia" if rng.randf() < 0.6 else "untrained",
						"arms": "rifle" if rng.randf() < 0.4 else "pistol", "flight": 0.4, "alert": 0})
				s["attack_t"] = rng.randi_range(150, s["duration"] - 180)
			var est := "low (about 1 in %d)" % int(round(1.0 / p))
			s["intel"].append({"key": "threat", "label": "Threat estimate", "truth": est, "est": est, "known": false, "conf": 0.3, "never": true})
			_fact(s, "crowd", "Expected crowd", "%d" % s["crowd"], "%d-%d" % [s["crowd"] - 10, s["crowd"] + 10], 0.5)
			s["intel"].append({"key": "duration", "label": "Duration", "truth": "15 minutes", "est": "", "known": true, "conf": 1.0})
	_first_tips(s, rng)
	return s


static func _rooms(lv) -> Array:
	var out: Array = []
	for nm in lv.rooms:
		if lv.is_exterior(nm) or lv.room_area(nm) < 5.0:
			continue
		out.append(nm)
	out.sort()
	if out.is_empty():
		out = ["OUT"]
	return out


static func _fact(s: Dictionary, key: String, label: String, truth: String, est: String, conf: float) -> void:
	s["intel"].append({"key": key, "label": label, "truth": truth, "est": est, "known": false, "conf": conf})


static func _count_text(n: int) -> String:
	return "%d" % n


static func _range_text(rng: RandomNumberGenerator, n: int, spread: int) -> String:
	var lo := maxi(1, n - rng.randi_range(0, spread))
	var hi := n + rng.randi_range(0, spread)
	if lo == hi:
		return "%d, probably" % lo
	return "%d-%d" % [lo, hi]


static func _civ_text(n: int) -> String:
	return "nobody" if n == 0 else ("%d" % n)


static func _guess_room(rng: RandomNumberGenerator, rooms: Array, truth: String, p_right: float) -> String:
	if rng.randf() < p_right or rooms.size() < 2:
		return truth
	var other: String = rooms[rng.randi() % rooms.size()]
	if other == truth:
		other = rooms[(rooms.find(truth) + 1) % rooms.size()]
	return other


## A fact about a room: shown by the room's title, and kept by key for the plan.
static func _room_fact(s: Dictionary, lv, key: String, label: String, truth: String, est: String, conf: float) -> void:
	s["intel"].append({"key": key, "label": label, "truth": room_title(lv, truth), "est": room_title(lv, est) + "?",
		"known": false, "conf": conf, "room": truth, "room_est": est})


## A room's name as the briefing says it: its title, or its key when the title is shared.
static func room_title(lv, rm: String) -> String:
	if lv.rooms.has(rm):
		var tt: String = lv.rooms[rm]["title"]
		var same: Array = []
		for other in lv.rooms:
			if lv.rooms[other]["title"] == tt:
				same.append(other)
		if same.size() > 1:
			same.sort()
			return "%s %d" % [tt.to_lower(), same.find(rm) + 1]
		return tt.to_lower()
	return rm.to_lower()


## Tips that come in on their own: from the public (more at high visibility) and from
## the ward's community group (more where trust is high, none below 25).
static func _first_tips(s: Dictionary, rng: RandomNumberGenerator) -> void:
	var n := 0
	if int(s["trust"]) >= 25:
		n += int(s["trust"]) / 30
	if int(s["visibility"]) >= 3:
		n += 1
	if rng.randf() < 0.4:
		n += 1
	if s["type"] == "event":
		n = mini(n, 2)
	s["tip_count"] = n
	for k in n:
		tip(s, rng, "community" if int(s["trust"]) >= 25 and k < int(s["trust"]) / 30 else "public")


## One tip: turns an estimate into a fact (or, for a rally, moves the threat estimate
## without ever confirming it). Returns the tip's text.
static func tip(s: Dictionary, rng: RandomNumberGenerator, source: String) -> String:
	var open: Array = []
	for f in s["intel"]:
		if not f["known"] and not f.get("never", false):
			open.append(f)
	var who: String = {"community": "%s community group" % s["ward"], "public": "a neighbour", "canvass": "canvassing"}.get(source, source)
	if s["type"] == "event" and (open.is_empty() or rng.randf() < 0.6):
		var th: Dictionary = {}
		for f2 in s["intel"]:
			if f2["key"] == "threat":
				th = f2
		var up: bool = s.get("attack", false) and rng.randf() < 0.65 or (not s.get("attack", false) and rng.randf() < 0.2)
		var p: float = float(s.get("attack_p", 0.1)) * (1.8 if up else 0.6)
		th["est"] = "%s (about 1 in %d)" % ["raised" if up else "lowered", maxi(2, int(round(1.0 / clampf(p, 0.02, 0.6))))]
		var txt := "%s: %s" % [_cap(who), "someone online is talking about the rally in a way that worries people" if up
			else "nothing unusual heard about the rally"]
		s["tips"].append(txt)
		return txt
	if open.is_empty():
		var txt2 := "%s: nothing new" % _cap(who)
		s["tips"].append(txt2)
		return txt2
	var f3: Dictionary = open[rng.randi() % open.size()]
	f3["known"] = true
	var txt3 := "%s: %s, %s" % [_cap(who), String(f3["label"]).to_lower(), f3["truth"]]
	s["tips"].append(txt3)
	return txt3


static func _cap(t: String) -> String:
	return t.substr(0, 1).to_upper() + t.substr(1)


## Readable briefing lines: known facts and estimates with their confidence.
static func briefing_lines(s: Dictionary) -> Array:
	var out: Array = []
	for f in s["intel"]:
		if f["known"]:
			out.append({"label": f["label"], "text": f["truth"], "known": true})
		else:
			out.append({"label": f["label"], "text": "%s (estimate, %d%% confidence)" % [f["est"], int(f["conf"] * 100.0)], "known": false})
	return out
