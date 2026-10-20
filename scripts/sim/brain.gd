extends RefCounted
## Decisions (bible section 4). Root priorities, re-evaluated every tick:
##   P1 Rule 1 (closest visible enemy within 10 m: fire until dry or eliminated)
##   P2 Rule 2 (primary dry -> sidearm; both dry -> break line of sight, then reload)
##   P3 stoppage  P4 engage beyond 10 m  P5 react  P6 maintain  P7 team task  P8 scan
## Good habits change how each branch runs; active bad habits suspend the good habits
## they override (op.has() is false for a suspended habit) and add their own behaviour.

const Op = preload("res://scripts/sim/op.gd")
const Geom = preload("res://scripts/sim/geom.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const DT := 1.0 / 30.0
const GAS_WAIT := 20.0     # s a squad holds the door after gassing a room (v0.8)

# Hold-post geometry, kept as static values so the hold test can sweep them (tuned
# 2026-10-20: the drafted 50-80 deg HD10 band cost a police defence 9 points of attacker
# wins; 30-55 deg is neutral. Every HD07 variant tried cost 4-7 points, so HD07 is out of
# the presets until it is reworked).
static var hd07_lane := 1.5          # HD07: how far inside the door the lane is covered
static var hd07_door_too := true     # HD07: the post must also see the doorway itself
static var hd07_hidden := 0.0        # HD07: penalty for a post seen from 4 m outside the door
static var hd10_lo := 0.5            # HD10: the band off the door's axis (radians)
static var hd10_hi := 0.95
static var hd10_bonus := 0.5
static var hd07_face_door := true    # HD07: pick the post on the lane, but keep the eyes on the door

var w
var tick := 0


func _init(world) -> void:
	w = world


# ================================================================== team level
## Teams of more than five split into elements (fire teams) of up to five: balanced,
## contiguous blocks of slots (6 = 3+3, 7 = 4+3, 11 = 4+4+3, 20 = 5x4). Each element
## picks its own room, stacks, enters, holds its own sectors and bounds on its own; the
## team shares what is cleared, which rooms are claimed, and every callout. A team of
## five or fewer is a single element and behaves exactly as before.
func init_teams() -> void:
	for tm in w.teams:
		if tm.get("civ", false):
			continue
		init_team(tm)


## Form a unit's elements and start it on its posture (also for units created mid-match).
## A police unit with orders (v0.7) forms the player's squads and starts each on its
## first objective instead.
func init_team(tm: Dictionary) -> void:
	_form_elements(tm)
	if tm.has("orders"):
		for el in tm["elements"]:
			el["obj_i"] = 0
			el["results"] = []
			_begin_objective(tm, el)
		return
	# occupants of a planned operation (v0.7) stay where the situation put them until
	# something happens: no gathering into one room
	if tm.get("posted", false):
		for el in tm["elements"]:
			var posts: Array = []
			for m in el["members"]:
				posts.append({"p": m.spawn, "face": m.spawn_face})
			_set_posts(tm, el, posts, -1)
		return
	if tm["posture"] == "hold":
		# squads already gathered in one room claim it first
		var order: Array = tm["elements"].duplicate()
		order.sort_custom(func(a, b): return _concentration(a) > _concentration(b))
		for el in order:
			_set_mode(tm, el, "hold")
	else:
		_set_posture(tm, tm["posture"])


func _concentration(el: Dictionary) -> int:
	var counts := {}
	var best := 0
	for m in el["members"]:
		var rm: String = w.level.room_at(m.pos)
		if w.level.is_exterior(rm):
			continue
		counts[rm] = counts.get(rm, 0) + 1
		best = maxi(best, counts[rm])
	return best


func _form_elements(tm: Dictionary) -> void:
	var ms: Array = tm["members"].duplicate()
	ms.sort_custom(func(a, b): return a.slot < b.slot)
	# the player's squads (v0.7): one element per squad, whatever its size
	if tm.has("orders") and not ms.is_empty() and ms[0].squad >= 0:
		var n_sq: int = tm["orders"].size()
		tm["elements"] = []
		for i in n_sq:
			var el0 := _new_element(i)
			el0["orders"] = tm["orders"][i]
			tm["elements"].append(el0)
		for m0 in ms:
			var si := clampi(m0.squad, 0, n_sq - 1)
			var e0: Dictionary = tm["elements"][si]
			m0.el = si
			m0.eslot = e0["members"].size()
			e0["members"].append(m0)
		var parts: Array = []
		for e1 in tm["elements"]:
			parts.append(str(e1["members"].size()))
		w.say("Police: %d squad%s (%s)" % [n_sq, "" if n_sq == 1 else "s", " + ".join(parts)], "info")
		return
	var n := ms.size()
	var n_el := maxi(1, int(ceil(n / 5.0)))
	tm["elements"] = []
	var k := 0
	var sizes: Array = []
	for i in n_el:
		var size := n / n_el + (1 if i < n % n_el else 0)
		var el := _new_element(i)
		for j in size:
			var m = ms[k]
			k += 1
			m.el = i
			m.eslot = j
			el["members"].append(m)
		tm["elements"].append(el)
		sizes.append(str(size))
	if n_el > 1:
		w.say("%s forms %d elements (%s)" % [tm["tag"], n_el, " + ".join(sizes)], "info")


func _new_element(i: int) -> Dictionary:
	return {"i": i, "members": [], "mode": "", "task": {}, "phase": "", "phase_t": 0.0, "entry": {}, "ctl": {},
		"geo": {}, "sectors": {}, "sector_half": deg_to_rad(80.0), "sector_pending": {}, "bound": -1,
		"bound_from": Vector2.ZERO, "bound_t": 0.0, "hunt_i": 0, "hunt_done_t": -1.0, "sweep": [],
		"sweep_target": null, "last_room": "", "retask_t": 0.0}


func _set_posture(tm: Dictionary, p: String) -> void:
	tm["posture"] = p
	for el in tm["elements"]:
		if not _alive(el).is_empty():
			_set_mode(tm, el, p)


func _set_mode(tm: Dictionary, el: Dictionary, mode: String) -> void:
	if el["mode"] == "hold" and mode != "hold":
		_release_hold(tm, el)
	el["mode"] = mode
	for m0 in el["members"]:
		w.wake(m0)
	# taskings that go looking for the enemy keep weapons drawn
	var floor_lvl: int = Op.YELLOW if mode in ["assault", "hunt", "support"] else int(tm.get("base_alert", -1))
	if floor_lvl >= 0:
		for m in el["members"]:
			m.alert_floor = floor_lvl
			if m.alert < floor_lvl and m.alive():
				w.raise_alert(m, floor_lvl)
	if mode == "assault":
		_next_task(tm, el)
	elif mode == "hold":
		_hold_on(el)
		_consolidate(tm, el)
	elif mode == "hunt":
		_release(tm, el)
		el["task"] = {}
		var n_el: int = tm["elements"].size()
		el["hunt_i"] = 0 if el.has("patrol") else int(el["i"] * tm.get("patrol", w.level.patrol).size() / maxi(1, n_el))
		el["hunt_done_t"] = -1.0


func alive_members(tm: Dictionary) -> Array:
	var out: Array = []
	for m in tm["members"]:
		if m.alive():
			out.append(m)
	return out


func _alive(el: Dictionary) -> Array:
	var out: Array = []
	for m in el["members"]:
		if m.alive():
			out.append(m)
	return out


func _el(o) -> Dictionary:
	return w.teams[o.team]["elements"][o.el]


func _el_mates(o) -> Array:
	var out: Array = []
	for m in _el(o)["members"]:
		if m != o and m.alive():
			out.append(m)
	return out


func _tag(tm: Dictionary, el: Dictionary) -> String:
	if el.has("orders"):
		return "Squad %d" % (el["i"] + 1)
	if tm["elements"].size() <= 1:
		return tm["tag"]
	return "%s-%d" % [tm["tag"], el["i"] + 1]


func _any_has(tm: Dictionary, gid: String) -> bool:
	for m in alive_members(tm):
		if m.has(gid):
			return true
	return false


func _release(tm: Dictionary, el: Dictionary) -> void:
	var into: String = el["task"].get("into", "")
	if into != "" and tm["claimed"].get(into, -1) == el["i"]:
		tm["claimed"].erase(into)


## Pick the element's next room: any uncleared interior room reachable through a door
## from outside or from a cleared room, not claimed by another element. Nearest by
## path wins; a small room off the room just cleared goes first (no open door left
## behind). Small rooms (PF10 check rooms) are looked into by someone with PF10, or
## skipped if nobody on the team has it.
func _next_task(tm: Dictionary, el: Dictionary) -> void:
	_release(tm, el)
	el["task"] = {}
	var al := _alive(el)
	if al.is_empty():
		return
	var lv = w.level
	var c := _centre(al)
	var pf10_team := _any_has(tm, "PF10")
	var pf10_el := false
	for m in al:
		if m.has("PF10"):
			pf10_el = true
	var cands: Array = []
	var bi: int = tm.get("bldg", -1)
	var door_ids: Array = lv.building_doors(bi) if bi >= 0 else lv.doors.keys()
	# orders (v0.7): only the rooms the objective needs, never an avoided room, and the
	# first entry through the ordered door while the room behind it is still to clear
	var od: Dictionary = el.get("orders", {})
	var allowed: Dictionary = el.get("allowed", {})
	var avoid: Array = od.get("avoid", [])
	var entry: String = od.get("entry", "")
	var use_entry := false
	if entry != "" and not el.get("entered", false) and lv.doors.has(entry):
		for side in [lv.doors[entry]["a"], lv.doors[entry]["b"]]:
			if not lv.is_exterior(side) and not tm["cleared"].has(side) and not avoid.has(side):
				use_entry = true
	for did in door_ids:
		if use_entry and did != entry:
			continue
		var D: Dictionary = lv.doors[did]
		for into in [D["a"], D["b"]]:
			if lv.is_exterior(into) or tm["cleared"].has(into) or tm["skipped"].has(into):
				continue
			if avoid.has(into) or (not allowed.is_empty() and not allowed.has(into)):
				continue
			if tm["claimed"].has(into) and tm["claimed"][into] != el["i"]:
				continue
			var frm: String = lv.from_room(did, into)
			if not (lv.is_exterior(frm) or tm["cleared"].has(frm) or tm["skipped"].has(frm) or _held_hall(tm, frm)):
				continue
			var check: bool = lv.is_check_room(into)
			if check and not pf10_team:
				tm["skipped"][into] = true
				continue
			if check and not pf10_el:
				continue
			var bonus := -4.0 if (check and frm == el["last_room"]) else 0.0
			cands.append([c.distance_to(D["c"]) + bonus, did, into, check, bonus])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var best = null
	var best_s := INF
	var start: Vector2 = w.nav.snap(c)
	for k in mini(4, cands.size()):
		var cd: Array = cands[k]
		var D2: Dictionary = lv.doors[cd[1]]
		var app: Vector2 = D2["c"] - lv.inward(cd[1], cd[2]) * 1.2
		var pth: PackedVector2Array = w.nav.find_path(0, start, app)
		var L: float = w.nav.path_length(pth) if not pth.is_empty() else 999.0
		var sc: float = L + cd[4]
		if sc < best_s:
			best_s = sc
			best = cd
	if best != null:
		el["task"] = {"door": best[1], "into": best[2], "check": best[3]}
		tm["claimed"][best[2]] = el["i"]
		el["mode"] = "assault"
		if best[1] == entry:
			el["entered"] = true
		_begin_task(tm, el)
		return
	# nothing open to this element: wait behind another element, or hunt if all clear
	var remaining := false
	for name in (lv.building_rooms(bi) if bi >= 0 else lv.rooms.keys()):
		if lv.is_exterior(name) or tm["cleared"].has(name) or tm["skipped"].has(name):
			continue
		if lv.adj.get(name, []).is_empty():
			continue
		if avoid.has(name) or (not allowed.is_empty() and not allowed.has(name)):
			continue
		remaining = true
	var others_busy := false
	for other in tm["elements"]:
		if other != el and not other["task"].is_empty() and not _alive(other).is_empty():
			others_busy = true
	if remaining and others_busy:
		if el["mode"] != "support":
			w.say("%s waits on the next room" % _tag(tm, el), "info")
		el["mode"] = "support"
		el["retask_t"] = w.t + 1.0
		return
	if el.has("orders"):
		# a squad under orders reports its rooms done instead of going hunting
		el["mode"] = "assault"
		if not el.get("rooms_said", false):
			el["rooms_said"] = true
			var unchecked := 0
			for rk in tm["skipped"]:
				if bi < 0 or lv.building_rooms(bi).has(rk):
					unchecked += 1
			var note := "" if unchecked == 0 else ", %d small room%s not checked" % [unchecked, "" if unchecked == 1 else "s"]
			w.say("%s: %s%s" % [_tag(tm, el), "rooms clear" if not remaining else "rooms out of reach", note], "info")
		_objective_done(tm, el, not remaining, "rooms clear" if not remaining else "rooms out of reach")
		return
	if bi >= 0:
		# a building search: report done and wait for the next tasking
		if not tm["clear_said"]:
			tm["clear_said"] = true
			tm["done_t"] = w.t
			w.say("%s: building %s" % [tm["tag"], "clear" if not remaining else "searched (rooms out of reach)"], "info")
		el["mode"] = "done"
		return
	if not tm["clear_said"]:
		tm["clear_said"] = true
		if remaining:
			w.say("%s: no room left it can reach, hunting" % tm["tag"], "info")
		else:
			w.say("%s: building clear, hunting" % tm["tag"], "info")
	tm["posture"] = "hunt"
	for other in tm["elements"]:
		if other == el or other["mode"] == "support" or (other["mode"] == "assault" and other["task"].is_empty()):
			_set_mode(tm, other, "hunt")


## A corridor or stair hall that an element has entered and is clearing or sweeping is
## held: other elements may peel off it into the rooms along it.
func _held_hall(tm: Dictionary, name: String) -> bool:
	if not w.level.rooms.has(name) or not w.level.rooms[name]["hall"]:
		return false
	var ei: int = tm["claimed"].get(name, -1)
	if ei < 0:
		return false
	var el: Dictionary = tm["elements"][ei]
	return el["phase"] == "clear" or el["phase"] == "sweep"


func _begin_task(tm: Dictionary, el: Dictionary) -> void:
	var st: Dictionary = el["task"]
	var lv = w.level
	var D: Dictionary = lv.doors[st["door"]]
	var n_in: Vector2 = lv.inward(st["door"], st["into"])
	var c: Vector2 = D["c"]
	var tdir: Vector2 = D["t"]
	el["phase"] = "check" if st.get("check", false) else "approach"
	el["phase_t"] = w.t
	el["entry"] = {}
	el["ctl"] = {}
	el["sweep"] = []
	el["sweep_target"] = null
	var al := _alive(el)
	al.sort_custom(func(a, b): return a.pos.distance_to(c) < b.pos.distance_to(c))
	for i in range(al.size()):
		if al[i].hb("BH11") and i > 0:
			var r = al[i]
			al.remove_at(i)
			al.insert(0, r)
			break
	# a ballistic shield leads the entry (v0.7.5)
	for i2 in range(al.size()):
		if al[i2].shield and i2 > 0:
			var r2 = al[i2]
			al.remove_at(i2)
			al.insert(0, r2)
			break
	# stack side: the wall side with more walkable room on the near side of the door
	var from_room: String = lv.from_room(st["door"], st["into"])
	var side := tdir
	var free_pos := 0
	var free_neg := 0
	for k in 3:
		if _near_side_ok(c - n_in * 0.55 + tdir * (D["half"] + 0.5 + 0.8 * k), from_room):
			free_pos += 1
		if _near_side_ok(c - n_in * 0.55 - tdir * (D["half"] + 0.5 + 0.8 * k), from_room):
			free_neg += 1
	if free_neg > free_pos:
		side = -tdir
	# entry geometry inside the room (runs are capped at 4.5 m in big rooms)
	var inside := c + n_in * 0.7
	var ext_p: float = minf(lv.extent_along(inside, tdir), 4.5)
	var ext_n: float = minf(lv.extent_along(inside, -tdir), 4.5)
	var s1 := tdir if ext_p >= ext_n else -tdir
	el["geo"] = {"c": c, "n_in": n_in, "tdir": tdir, "side": side, "from": from_room, "inside": inside,
		"s1": s1, "e1": maxf(ext_p, ext_n), "e2": minf(ext_p, ext_n),
		"depth": minf(lv.extent_along(inside, n_in), 4.5), "cap": lv.room_capacity(st["into"]),
		"slots": _stack_slots(c, n_in, side, D["half"], from_room)}
	for k in range(al.size()):
		el["entry"][al[k].id] = _entry_record(el, al[k], k, true)
	if el["phase"] == "approach":
		var cap: int = el["geo"]["cap"]
		var held: int = al.size() - cap
		w.say("%s moves on the %s%s" % [_tag(tm, el), lv.rooms[st["into"]]["title"].to_lower(),
			(" (%d enter, %d hold rear security)" % [cap, held]) if held > 0 else ""], "info")


## One member's part in an entry: wait point (stack, or a loose clump without GD01),
## optional pie-slicing arc (PF03), point of domination and corner to clear.
func _entry_record(el: Dictionary, m, k: int, may_enter: bool) -> Dictionary:
	var g: Dictionary = el["geo"]
	var c: Vector2 = g["c"]
	var n_in: Vector2 = g["n_in"]
	var tdir: Vector2 = g["tdir"]
	var side: Vector2 = g["side"]
	var from_room: String = g["from"]
	var slots: Array = g["slots"]
	var enters: bool = may_enter and k < g["cap"]
	var d := {"order": k, "wi": 0, "at_stack": false, "ready": false, "looked": 0.0,
		"checked": not m.has("WD04"), "arrived": false, "paused": false, "swept": false, "enters": enters}
	var stack: Vector2
	if m.has("GD01"):
		stack = slots[k] if k < slots.size() else _cluster_point(c, n_in, tdir, k, from_room)
	else:
		stack = _cluster_point(c, n_in, tdir, k, from_room)
	var wps: Array = []
	if m.has("PF03"):
		for arc_side in [-side, side]:
			var arc: Array = []
			for a_deg in [70.0, 45.0, 20.0]:
				var a := deg_to_rad(a_deg)
				var q: Vector2 = c - n_in * 2.0 * cos(a) + arc_side * 2.0 * sin(a)
				if _near_side_ok(q, from_room) and w.geom.sight_clear(q, 1.6, c + n_in * 0.6, 1.6):
					arc.append(q)
			if arc.size() >= 2:
				wps = arc
				break
	wps.append(stack)
	d["wps"] = wps
	d["stack"] = stack
	var tgt: Array = _entry_target(m, k, c, n_in, g["inside"], g["s1"], g["e1"], g["e2"], g["depth"])
	var my_side: Vector2 = tgt[1]
	d["target"] = _inside_room(w.nav.snap(tgt[0]), el["task"]["into"], c, n_in)
	var ext: float = g["e1"] if my_side == g["s1"] else g["e2"]
	d["corner"] = c + n_in * 0.25 + my_side * maxf(ext - 0.25, 0.3)
	return d


## A member who joins mid-task (from a merged element) enters if the stack has not gone
## yet and there is room; otherwise holds rear security.
func _add_to_entry(el: Dictionary, m) -> void:
	if el["geo"].is_empty():
		return
	var k: int = el["entry"].size()
	el["entry"][m.id] = _entry_record(el, m, k, el["phase"] == "approach" or el["phase"] == "check")


## Stack positions along the wall beside the door: up to five on the near wall, then a
## split stack on the far side of the door, then a second row.
func _stack_slots(c: Vector2, n_in: Vector2, side: Vector2, half: float, from_room: String) -> Array:
	var out: Array = []
	for k in 5:
		var q: Vector2 = c - n_in * 0.55 + side * (half + 0.5 + 0.8 * k)
		if not _near_side_ok(q, from_room):
			break
		out.append(q)
	for k in 3:
		var q2: Vector2 = c - n_in * 0.55 - side * (half + 0.5 + 0.8 * k)
		if not _near_side_ok(q2, from_room):
			break
		out.append(q2)
	for k in 4:
		var q3: Vector2 = c - n_in * 1.4 + side * (half + 0.5 + 0.8 * k)
		if not _near_side_ok(q3, from_room):
			break
		out.append(q3)
	return out


## Where an operator without stack discipline waits: a loose clump behind the door,
## kept on the near side so nobody waits in the room being cleared.
func _cluster_point(c: Vector2, n_in: Vector2, tdir: Vector2, k: int, from_room: String) -> Vector2:
	for dep in [1.8 + 0.7 * k, 1.8 + 0.4 * k, 1.4, 1.0]:
		for lat in [0.35 * k, -0.35 * k, 0.8, -0.8, 0.0]:
			var q: Vector2 = c - n_in * dep + tdir * lat
			if _near_side_ok(q, from_room):
				return q
	return w.nav.snap(c - n_in * 1.2)


## Point of domination for entry order k. Returns [target, side used].
## PF04: #1 and #2 run the entry wall to the corners (#2 opposite with GD06); #3 and #4
## step into the room behind them, alternating sides with GD06. Without PF04 everyone
## stops just inside the door, bunched in the funnel.
func _entry_target(m, k: int, c: Vector2, n_in: Vector2, inside: Vector2, s1: Vector2, e1: float, e2: float, depth: float) -> Array:
	if not m.has("PF04"):
		if k == 0:
			return [c + n_in * 1.0, s1]
		var sd := s1 if k % 2 == 1 else -s1
		return [c + n_in * (1.0 + 0.5 * int((k - 1) / 2)) + sd * 0.7, sd]
	var gd6: bool = m.has("GD06")
	if k == 0:
		return [inside + s1 * maxf(e1 - 0.6, 0.6), s1]
	if k == 1:
		if gd6:
			return [inside - s1 * maxf(e2 - 0.6, 0.6), -s1]
		return [inside + s1 * maxf(e1 - 1.6, 0.5), s1]
	if not gd6:
		return [inside + s1 * maxf(e1 - 0.6 - 1.0 * k, 0.4), s1]
	var sd2 := s1 if k % 2 == 0 else -s1
	var ext := e1 if sd2 == s1 else e2
	var d2: float = clampf(depth - 1.2, 0.8, 2.2)
	return [c + n_in * (0.7 + d2) + sd2 * clampf(ext - 0.9, 0.3, 1.3), sd2]


func _inside_room(p: Vector2, into: String, c: Vector2, n_in: Vector2) -> Vector2:
	if w.level.room_at(p) == into and w.nav.is_free(p):
		return p
	var aim := c + n_in * 1.5
	for k in range(1, 9):
		var q := p.lerp(aim, k / 8.0)
		if w.level.room_at(q) == into and w.nav.is_free(q):
			return q
	return w.nav.snap(aim)


func _near_side_ok(q: Vector2, from_room: String) -> bool:
	if not w.nav.is_free(q):
		return false
	var rm: String = w.level.room_at(q)
	if w.level.is_exterior(from_room):
		return w.level.is_exterior(rm)
	return rm == from_room


func update_teams() -> void:
	tick += 1
	for tm in w.teams:
		if tm["free"] or tm["sleep"] or tm.get("civ", false):
			continue
		if w.dormancy and not tm.get("hot", true) and (tick + tm["id"]) % 4 != 0:
			continue
		var al := alive_members(tm)
		if al.is_empty():
			continue
		_merge_elements(tm)
		for el in tm["elements"]:
			var eal := _alive(el)
			if eal.is_empty():
				continue
			_sectors(el, eal)
			_bounding(el, eal)
			if el.has("orders") and (tick + el["i"]) % 10 == 0:
				_orders_tick(tm, el)
			var hold_now: bool = el["mode"] == "hold"
			for hm in eal:
				hm.holding = hold_now
			if hold_now and (tick + el["i"]) % 15 == 0:
				_hold_tick(tm, el, eal)
			match el["mode"]:
				"assault":
					_assault_tick(tm, el, eal)
				"support":
					if w.t >= el["retask_t"]:
						el["retask_t"] = w.t + 1.0
						_next_task(tm, el)
		if tm["posture"] == "hold" and not tm.get("stay", false):
			var quiet: float = w.t - maxf(tm["last_contact"], 0.0)
			if quiet > 60.0:
				w.say("%s: no contact for a minute, hunting" % tm["tag"], "info")
				_set_posture(tm, "hunt")


## An element cut down to one joins the nearest element that still has people; an
## element wiped out releases the room it had claimed.
func _merge_elements(tm: Dictionary) -> void:
	var els: Array = tm["elements"]
	if els.size() < 2:
		return
	for el in els:
		var al := _alive(el)
		if al.is_empty():
			if el["mode"] == "lost":
				continue
			if not el["task"].is_empty():
				_release(tm, el)
				el["task"] = {}
			_release_hold(tm, el)
			el["mode"] = "lost"
			continue
		if al.size() != 1:
			continue
		var lone = al[0]
		var best = null
		var bd := INF
		for other in els:
			if other == el:
				continue
			var oal := _alive(other)
			if oal.is_empty():
				continue
			var d: float = _centre(oal).distance_to(lone.pos) + (25.0 if oal.size() >= 5 else 0.0)
			if d < bd:
				bd = d
				best = other
		if best == null:
			continue
		_release(tm, el)
		_release_hold(tm, el)
		el["task"] = {}
		el["mode"] = "merged"
		el["members"].erase(lone)
		var top := -1
		for m in best["members"]:
			top = maxi(top, m.eslot)
		lone.el = best["i"]
		lone.eslot = top + 1
		best["members"].append(lone)
		best["sector_key"] = "?"
		w.say("%s, last of %s, joins %s" % [lone.id, _tag(tm, el), _tag(tm, best)], "comms")
		if best["mode"] == "assault" and not best["task"].is_empty():
			_add_to_entry(best, lone)
		elif best["mode"] == "hold" and best.get("hold_room", "") != "":
			_post_member(best, lone, {})


## GD02 sector ownership for any element size. Moving elements split the arc around
## their direction of advance (110 deg each for two or three, 360/N for four or five),
## left to right by position. Holders own the arc they were placed facing. After a
## casualty, GD09 members re-sector within 1 s; anyone without GD09 keeps the old arcs,
## so the casualty's arc stays dark.
func _sectors(el: Dictionary, al: Array) -> void:
	var gd2: Array = []
	for m in al:
		if m.has("GD02"):
			gd2.append(m)
	var key := ""
	for m in gd2:
		key += m.id
	var fwd := _team_forward(el, al)
	var holding: bool = el["mode"] == "hold"
	var first: bool = not el.has("sector_key") or el.get("sector_posture", "") != el["mode"]
	if not holding and not first and absf(angle_difference(fwd, el["sector_fwd"])) > 0.3:
		first = true
	if key == el.get("sector_key", "") and not first:
		_adopt_sectors(el)
		return
	var layout := _sector_layout(el, gd2, fwd)
	if first:
		el["sectors"] = layout
		el["sector_pending"] = {}
	else:
		var pend := {}
		if holding:
			for x in el["members"]:
				if x.alive() or not el["sectors"].has(x.id):
					continue
				var best = null
				for m in al:
					if m.has("GD09") and m.pos.distance_to(x.pos) < 10.0:
						if best == null or m.pos.distance_to(x.pos) < best.pos.distance_to(x.pos):
							best = m
				if best != null:
					var own: float = el["sectors"].get(best.id, best.spawn_face)
					pend[best.id] = {"dir": lerp_angle(own, el["sectors"][x.id], 0.5), "at": w.t + 1.0}
		else:
			for m in al:
				if m.has("GD09"):
					pend[m.id] = {"dir": layout.get(m.id, null), "at": w.t + 1.0}
		el["sector_pending"] = pend
	for oid in el["sectors"].keys():
		var x = w.op_by_id(oid)
		if x == null or not x.alive():
			el["sectors"].erase(oid)
	el["sector_key"] = key
	el["sector_fwd"] = fwd
	el["sector_posture"] = el["mode"]


func _sector_layout(el: Dictionary, members: Array, fwd: float) -> Dictionary:
	var out := {}
	var n := members.size()
	if el["mode"] == "hold":
		for m in members:
			out[m.id] = m.spawn_face
		el["sector_half"] = deg_to_rad(80.0)
		return out
	if n < 2:
		return out
	var c := Vector2.ZERO
	for m in members:
		c += m.pos
	c /= n
	var f := Vector2.from_angle(fwd)
	var sorted := members.duplicate()
	sorted.sort_custom(func(a, b): return f.cross(a.pos - c) < f.cross(b.pos - c))
	var spacing := minf(deg_to_rad(110.0), TAU / n)
	el["sector_half"] = clampf(spacing / 2.0 + deg_to_rad(15.0), deg_to_rad(50.0), deg_to_rad(80.0))
	for i in n:
		out[sorted[i].id] = fwd + (i - (n - 1) / 2.0) * spacing
	return out


func _adopt_sectors(el: Dictionary) -> void:
	var pend: Dictionary = el["sector_pending"]
	for oid in pend.keys():
		var p: Dictionary = pend[oid]
		if w.t < p["at"]:
			continue
		pend.erase(oid)
		var x = w.op_by_id(oid)
		if x == null or not x.alive():
			continue
		if p["dir"] == null:
			el["sectors"].erase(oid)
		else:
			el["sectors"][oid] = p["dir"]
		w.say("%s re-sectors after the casualty" % oid, "comms")


func _team_forward(el: Dictionary, al: Array) -> float:
	if el["mode"] == "assault" and not el["task"].is_empty():
		return w.level.inward(el["task"]["door"], el["task"]["into"]).angle()
	var v := Vector2.ZERO
	for m in al:
		v += Vector2.from_angle(m.spawn_face if el["mode"] == "hold" else m.body_dir)
	return v.angle()


## GD05 bounding overwatch inside each element: odd slots (1, 3, 5) and even slots (2, 4)
## alternate. One half moves while the other is static and covering.
func _bounding(el: Dictionary, al: Array) -> void:
	var movers: Array = [[], []]
	for m in al:
		if m.has("GD05") and w.level.is_exterior(w.level.room_at(m.pos)):
			movers[m.eslot % 2].append(m)
	var phase_ok: bool = el["mode"] == "hunt" or el["mode"] == "support" or (el["mode"] == "assault" and el["phase"] == "approach")
	if movers[0].is_empty() or movers[1].is_empty() or not phase_ok:
		el["bound"] = -1
		return
	var cur: int = el["bound"]
	if cur < 0:
		el["bound"] = 0
		el["bound_from"] = _centre(movers[0])
		el["bound_t"] = w.t
		return
	var grp: Array = movers[cur]
	var any_moving := false
	for m in grp:
		if m.moving:
			any_moving = true
	var done: bool = _centre(grp).distance_to(el["bound_from"]) > 4.5 or w.t - el["bound_t"] > 4.0
	if w.t - el["bound_t"] > 0.8 and not any_moving:
		done = true
	if done:
		var nxt := 1 - cur
		el["bound"] = nxt
		el["bound_from"] = _centre(movers[nxt])
		el["bound_t"] = w.t


func _centre(ms: Array) -> Vector2:
	var c := Vector2.ZERO
	for m in ms:
		c += m.pos
	return c / maxf(1.0, ms.size())


func _room_done(tm: Dictionary, el: Dictionary, what: String) -> void:
	var into: String = el["task"]["into"]
	tm["cleared"][into] = true
	w.say("%s: %s %s" % [_tag(tm, el), w.level.rooms[into]["title"].to_lower(), what], "info")
	el["last_room"] = into
	# Consolidate (v0.7): hold this room, covering every door off it, before going on
	if el.get("orders", {}).get("consolidate", "") == into and not el.get("consol_done", false):
		el["consol_done"] = true
		el["consolidating"] = true
		el["consol_t"] = w.t
		_release(tm, el)
		el["task"] = {}
		el["fixed_room"] = into
		el["mode"] = "hold"
		_consolidate(tm, el)
		w.say("%s consolidates the %s before going on" % [_tag(tm, el), w.level.rooms[into]["title"].to_lower()], "info")
		w.mark("%s consolidated the %s" % [_tag(tm, el), w.level.rooms[into]["title"].to_lower()], "order")
		return
	_next_task(tm, el)


func _assault_tick(tm: Dictionary, el: Dictionary, al: Array) -> void:
	if el["task"].is_empty():
		if w.t >= el["retask_t"]:
			el["retask_t"] = w.t + 1.0
			_next_task(tm, el)
		return
	var st: Dictionary = el["task"]
	var entry: Dictionary = el["entry"]
	var ctl: Dictionary = el["ctl"]
	for m in al:
		if not entry.has(m.id):
			_add_to_entry(el, m)
	match el["phase"]:
		"check":
			if ctl.has("check_done_t") and w.t >= ctl["check_done_t"]:
				_room_done(tm, el, "checked")
			elif w.t - el["phase_t"] > 12.0:
				el["last_room"] = st["into"]
				tm["skipped"][st["into"]] = true
				_next_task(tm, el)
		"approach":
			var all_ready := true
			var any_ready := false
			var rusher := false
			var all_gd01 := true
			for m in al:
				var d: Dictionary = entry[m.id]
				if d["ready"]:
					any_ready = true
				else:
					all_ready = false
				if m.hb("BH11") and d["at_stack"]:
					rusher = true
				if not m.has("GD01"):
					all_gd01 = false
			var go := false
			if rusher:
				go = true
			elif all_gd01 and al.size() > 1:
				go = all_ready or (any_ready and w.t - ctl.get("first_ready_t", w.t) > 6.0)
			else:
				go = any_ready
			if w.t - el["phase_t"] > 45.0:
				go = true
			# Knock and announce (v0.7): the first squad to the door knocks, then gives
			# the occupants ten seconds
			if go and el.get("orders", {}).get("knock", false) and not w.knock_done:
				var knocker = null
				for m in al:
					if entry[m.id]["at_stack"] and (knocker == null or entry[m.id]["order"] < entry[knocker.id]["order"]):
						knocker = m
				if knocker != null:
					w.announce(knocker)
					el["knock_wait"] = w.t + 10.0
			if el.get("knock_wait", -1.0) > w.t and not rusher:
				go = false
			if go:
				_after_stack(tm, el, al)
		"breach":
			# a shut door: the breacher opens it, rams it, shoots the lock or kicks it in
			if not w.level.door_shut(st["door"]):
				_after_stack(tm, el, al)
			elif w.t - el["phase_t"] > 60.0:
				w.say("%s cannot get through the %s door" % [_tag(tm, el), w.level.rooms[st["into"]]["title"].to_lower()], "info")
				el["last_room"] = st["into"]
				tm["skipped"][st["into"]] = true
				_next_task(tm, el)
		"bang":
			# flashbang in once nobody stands in front of the door; everyone looks away;
			# the entry goes the moment it goes off
			var det: float = float(ctl.get("bang_det", -1.0))
			var kind: String = ctl.get("kind", "flashbang")
			if det < 0.0:
				var th = w.by_id.get(ctl.get("thrower", ""), null)
				if th == null or not th.alive() or th.stunned(w.t) or int(th.gear.get(kind, 0)) <= 0:
					_go_entry(tm, el)
				elif _funnel_clear(el, al, _bang_point(el)) and th.action.is_empty():
					w.throw_flash(th, _bang_point(el), kind)
					ctl["bang_det"] = w.t + 0.4 + w.fuse_of(kind)
				elif w.t - el["phase_t"] > 4.0:
					# somebody cannot get out of its way: go without it
					_go_entry(tm, el)
			elif w.t >= det + 0.15:
				if kind == "gas":
					# gas (v0.8): hold the door while it works, then go in
					el["phase"] = "gas_wait"
					el["phase_t"] = w.t
					w.say("%s holds the door while the gas works" % _tag(tm, el), "info")
				else:
					_go_entry(tm, el)
		"gas_wait":
			if w.t - el["phase_t"] >= GAS_WAIT:
				_go_entry(tm, el)
		"entry":
			var done := true
			for m in al:
				if entry[m.id]["enters"] and not entry[m.id]["arrived"]:
					done = false
			if done or w.t - el["phase_t"] > 9.0:
				el["phase"] = "clear"
				el["phase_t"] = w.t
		"clear":
			var quiet := true
			for m in al:
				if not w.visible_enemies(m).is_empty():
					quiet = false
			if quiet and w.t - el["phase_t"] > 1.2:
				if w.level.needs_sweep(st["into"]):
					el["phase"] = "sweep"
					el["phase_t"] = w.t
					el["sweep"] = _sweep_points(st["into"])
					w.say("%s sweeps the %s" % [_tag(tm, el), w.level.rooms[st["into"]]["title"].to_lower()], "info")
				else:
					_room_done(tm, el, "clear")
		"sweep":
			if tick % 15 == 0:
				_prune_sweep(el, al)
			if el["sweep"].is_empty() or w.t - el["phase_t"] > 120.0:
				_room_done(tm, el, "clear")


## The stack is ready (v0.7.5): breach a shut door first, then a flashbang if anyone
## carries one, then the entry.
func _after_stack(tm: Dictionary, el: Dictionary, al: Array) -> void:
	var st: Dictionary = el["task"]
	var ctl: Dictionary = el["ctl"]
	if w.level.door_shut(st["door"]):
		ctl["was_shut"] = true
		if el["phase"] != "breach":
			el["phase"] = "breach"
			el["phase_t"] = w.t
			ctl["breacher"] = _breacher(el, al)
			var how := "opens"
			if w.level.door_locked(st["door"]):
				var b = w.by_id.get(ctl["breacher"], null)
				how = "breaches" if b != null and (int(b.gear.get("ram", 0)) > 0 or int(b.gear.get("breach", 0)) > 0) else "forces"
			w.say("%s %s the %s door" % [_tag(tm, el), how, w.level.rooms[st["into"]]["title"].to_lower()], "info")
		return
	if not ctl.has("bang_done") and el.get("orders", {}).get("bangs", true) and _bang_wanted(tm, el):
		# v0.8: gas first where someone is known to be inside and no hostage could be,
		# then a flashbang, then a sting-ball
		var kinds: Array = ["flashbang", "stingball"]
		if _gas_wanted(tm, el):
			kinds.push_front("gas")
		for kind in kinds:
			var thrower = null
			for m in al:
				if int(m.gear.get(kind, 0)) > 0 and not m.stunned(w.t) and m.pos.distance_to(st_c(el)) < 3.5:
					if thrower == null or m.pos.distance_to(st_c(el)) < thrower.pos.distance_to(st_c(el)):
						thrower = m
			if thrower != null:
				ctl["bang_done"] = true
				ctl["thrower"] = thrower.id
				ctl["kind"] = kind
				ctl["bang_det"] = -1.0
				el["phase"] = "bang"
				el["phase_t"] = w.t
				return
	_go_entry(tm, el)


## Gas the room (v0.8)? Only where the briefing puts the suspect or someone has been
## seen or heard in it lately, never where hostages are held, and not a room already
## full of it.
func _gas_wanted(tm: Dictionary, el: Dictionary) -> bool:
	var into: String = el["task"]["into"]
	for h in w.ops:
		if h.hostage:
			return false
	for c in w.clouds:
		if c["room"] == into:
			return false
	if w.intel_rooms.has(into):
		return true
	for eid in tm["lkps"]:
		var l: Dictionary = tm["lkps"][eid]
		if w.level.room_at(l["p"]) == into and w.t - float(l["t"]) < 90.0:
			return true
	var snd: Dictionary = tm.get("sound", {})
	return not snd.is_empty() and w.level.room_at(snd["p"]) == into and w.t - float(snd["t"]) < 60.0


## Is this room worth a flashbang? Someone has been seen or heard in it, its door was
## shut (nobody has seen inside), or the orders name it.
func _bang_wanted(tm: Dictionary, el: Dictionary) -> bool:
	var into: String = el["task"]["into"]
	if el["ctl"].get("was_shut", false):
		return true
	for eid in tm["lkps"]:
		var l: Dictionary = tm["lkps"][eid]
		if w.level.room_at(l["p"]) == into and w.t - float(l["t"]) < 90.0:
			return true
	var snd: Dictionary = tm.get("sound", {})
	if not snd.is_empty() and w.level.room_at(snd["p"]) == into and w.t - float(snd["t"]) < 60.0:
		return true
	var ob: Dictionary = el.get("obj", {})
	return ob.get("rooms", []).has(into)


## Would the flash catch anyone of the element (in range, with a line of sight to it)?
func _funnel_clear(el: Dictionary, al: Array, p: Vector2) -> bool:
	for m in al:
		if _exposed(m.pos, p):
			return false
	return true


func _exposed(q: Vector2, p: Vector2) -> bool:
	return q.distance_to(p) <= w.BANG_R + 0.5 and w.geom.sight_clear(p, 0.4, q, 1.6)


## The nearest spot out of the flash's sight on the near side of the door.
func _bang_safe(el: Dictionary, m, p: Vector2) -> Vector2:
	var into: String = el["task"]["into"]
	var best: Vector2 = m.pos
	var bd := INF
	for r in [0.6, 1.2, 1.8, 2.4, 3.0]:
		for k in 16:
			var q: Vector2 = w.nav.snap(m.pos + Vector2.from_angle(TAU * k / 16.0) * r)
			if not w.nav.reachable(q) or w.level.room_at(q) == into or _exposed(q, p):
				continue
			var d: float = q.distance_to(m.pos)
			if d < bd:
				bd = d
				best = q
		if bd < INF:
			break
	return best


func _bang_point(el: Dictionary) -> Vector2:
	var g: Dictionary = el["geo"]
	var depth: float = clampf(float(g["depth"]) * 0.6, 1.2, 3.0)
	return w.nav.snap(g["c"] + g["n_in"] * depth)


func st_c(el: Dictionary) -> Vector2:
	return el["geo"].get("c", Vector2.ZERO)


func _go_entry(tm: Dictionary, el: Dictionary) -> void:
	el["phase"] = "entry"
	el["phase_t"] = w.t
	w.say("%s enters the %s" % [_tag(tm, el), w.level.rooms[el["task"]["into"]]["title"].to_lower()], "info")


## Who breaks the door: a ram, then breaching rounds, then the point man.
func _breacher(el: Dictionary, al: Array) -> String:
	var best = null
	var best_s := -INF
	for m in al:
		var sc := -float(el["entry"].get(m.id, {}).get("order", 9))
		if int(m.gear.get("ram", 0)) > 0:
			sc += 100.0
		elif int(m.gear.get("breach", 0)) > 0 and m.wid("rifle") == "shotgun":
			sc += 50.0
		if m.shield:
			sc -= 20.0
		if sc > best_s:
			best_s = sc
			best = m
	return best.id if best != null else ""


## A medical kit (v0.7.5): six seconds after the last contact, with nobody in sight, go
## to the nearest downed person within 20 m who is not treated (one's own side first)
## and treat them (20 s).
func _treat(o, tm: Dictionary) -> bool:
	if not o.gear.has("medkit") or not o.action.is_empty():
		return false
	# the task first: a squad in the middle of an entry needs everyone; only a teammate
	# down close by is treated then
	var el := _el(o)
	var busy: bool = el["mode"] in ["assault", "hunt"] and not el["task"].is_empty() and el.get("phase", "") in ["approach", "breach", "bang", "gas_wait", "entry", "clear", "check"]
	if busy and o.ticker.get("treat_tid", "") == "":
		var near_mate := false
		for x0 in w.ops:
			if x0.team == o.team and x0.state == "down" and not x0.ticker.get("treated", false) and x0.pos.distance_to(o.pos) < 8.0:
				near_mate = true
		if not near_mate:
			return false
	if w.t - float(tm.get("last_contact", -99.0)) < 6.0 or not w.visible_enemies(o).is_empty():
		o.ticker.erase("treat_tid")
		return false
	var pt = w.by_id.get(o.ticker.get("treat_tid", ""), null)
	if pt == null or pt.state != "down" or pt.ticker.get("treated", false):
		pt = null
		var best_s := INF
		for x in w.ops:
			if x.state != "down" or x.ticker.get("treated", false) or x.mounted != null or x.gone:
				continue
			var by: String = x.ticker.get("treat_by", "")
			if by != "" and by != o.id:
				continue
			var d: float = x.pos.distance_to(o.pos)
			if d > 20.0:
				continue
			var sc: float = d + (0.0 if x.team == o.team else 15.0)
			if sc < best_s:
				best_s = sc
				pt = x
		if pt == null:
			o.ticker.erase("treat_tid")
			return false
		o.ticker["treat_tid"] = pt.id
		pt.ticker["treat_by"] = o.id
	o.dbg = "treating %s" % pt.id
	if not w.at(o, pt.pos, 0.9):
		_go(o, pt.pos, "walk" if w.level.is_inside(o.pos) else "run", false)
	else:
		w.stop(o)
		o.look_goal = (pt.pos - o.pos).angle()
		o.stance_goal = Op.CROUCH
		w.start_action(o, "treat", 20.0, {"tid": pt.id})
		w.say("%s treats %s" % [o.id, pt.id], "info")
	return true


## Big rooms are swept: a lattice of points about 5 m apart that each must be seen from
## within 12 m by someone in the element before the room counts as clear.
func _sweep_points(into: String) -> Array:
	var pts: Array = []
	for rv in w.level.rooms[into]["rects"]:
		var r: Rect2 = rv
		var nx := maxi(1, int(round(r.size.x / 5.0)))
		var ny := maxi(1, int(round(r.size.y / 5.0)))
		for i in nx:
			for j in ny:
				var p := r.position + Vector2((i + 0.5) * r.size.x / nx, (j + 0.5) * r.size.y / ny)
				var q: Vector2 = w.nav.snap(p)
				if w.level.room_at(q) == into:
					pts.append(q)
	return pts


func _prune_sweep(el: Dictionary, al: Array) -> void:
	var keep: Array = []
	for p in el["sweep"]:
		var seen := false
		for m in al:
			if m.pos.distance_to(p) < 12.0 and w.geom.sight_clear(m.pos, m.eye(), p, 1.0):
				seen = true
				break
		if not seen:
			keep.append(p)
	el["sweep"] = keep
	var tg = el["sweep_target"]
	if tg != null and not keep.has(tg):
		el["sweep_target"] = null

# ================================================================== individual
var fine := false   # fine-grained profiling into w.prof


func think(o) -> void:
	if not fine:
		_think(o)
		return
	var t0 := Time.get_ticks_usec()
	var tm0: Dictionary = w.teams[o.team]
	var md: String = tm0["elements"][o.el]["mode"] if o.el >= 0 and o.el < tm0["elements"].size() else "?"
	_think(o)
	var k: String = "th_" + md + ("_" + o.dbg.split(" ")[0] if o.dbg != "" else "")
	w.prof[k] = w.prof.get(k, 0) + Time.get_ticks_usec() - t0


func _think(o) -> void:
	o.dbg = ""
	o.stance_goal = Op.STAND if not o.leg_hit or o.stance_goal != Op.CROUCH else Op.CROUCH
	var tm: Dictionary = w.teams[o.team]
	var el: Dictionary = tm["elements"][o.el]
	# stunned (flashbang, taser, sponge round, a helmet hit): nothing at all (v0.7.5)
	if o.stunned(w.t):
		o.dbg = "STUNNED"
		o.stance_goal = Op.CROUCH
		o.aim = {}
		w.stop(o)
		return
	# gassed (v0.8): someone who would give up runs for clean air instead of fighting
	var flg: Dictionary = o.ticker.get("flee", {})
	if flg.get("gas", false) and not o.judges and not o.complying and o.gassed(w.t):
		o.dbg = "out of the gas"
		o.aim = {}
		w.move_to(o, flg["p"], "run")
		_finish_look(o)
		return
	# PF09: keep a fallback cover point cached while threats are known
	if o.has("PF09") and w.t >= o.ticker.get("cover_next", 0.0):
		o.ticker["cover_next"] = w.t + 0.5
		var th := _threats(o)
		if not th.is_empty():
			var sig: Vector2 = o.pos.snapped(Vector2(1, 1))
			for tp in th:
				sig += (tp as Vector2).snapped(Vector2(1, 1)) * 0.001
			var cache: Dictionary = o.ticker.get("cover_cache", {})
			if cache.is_empty() or cache.get("sig", Vector2.INF) != sig or w.t - cache["t"] > 2.0:
				o.ticker["cover_cache"] = {"p": _find_cover(o, th, true), "t": w.t, "sig": sig}
			else:
				cache["t"] = w.t
	# blocking reactions
	if o.ticker.get("flinch_until", -1.0) > w.t:
		o.dbg = "flinch"
		o.stance_goal = Op.DUCK
		return
	if o.hb("BH07") and o.ticker.get("near_t", -9.0) > o.ticker.get("last_flinch", -9.0) + 0.9:
		o.ticker["last_flinch"] = w.t
		o.ticker["flinch_until"] = w.t + 0.8
		o.look_goal = o.look_dir + PI * 0.6
		o.aim = {}
		w.stop(o)
		o.stance_goal = Op.DUCK
		w.say("%s flinches and turtles" % o.id, "bad")
		return
	if not o.action.is_empty() and o.ticker.get("duck_action", false):
		o.stance_goal = Op.DUCK
	if o.action.is_empty():
		o.ticker["duck_action"] = false
	if o.ticker.get("freeze_until", -1.0) > w.t:
		o.dbg = "FROZEN"
	# BH09: shoots at half-recognized movement, and sometimes at friends
	if o.hb("BH09") and _jumpy(o):
		return
	# P1: Rule 1
	var close = _close_threat(o)
	if close != null:
		_rule1(o, close)
		return
	# retreat (city): a gang member who broke on seeing the police runs for safety
	var rt: Dictionary = o.ticker.get("retreat", {})
	if not rt.is_empty():
		if w.t > rt["until"] or w.at(o, rt["p"], 1.5):
			o.ticker.erase("retreat")
		else:
			o.dbg = "RETREATING"
			o.aim = {}
			w.move_to(o, rt["p"], "sprint")
			_finish_look(o)
			return
	# P2: Rule 2
	var s: Dictionary = o.ws()
	if s["mag"] <= 0 or s["lost"]:
		_rule2(o)
		return
	# P3: stoppage
	if s["jam"]:
		_stoppage(o)
		return
	# BH05: panic reload whenever firing stops
	if o.hb("BH05") and o.action.is_empty() and s["mag"] < o.wpn()["mag"] and s["spare"] > 0:
		var since: float = w.t - o.last_shot_t
		if since >= 0.5 and since < 6.0:
			_reload(o, o.active, false)
			w.say("%s panic-reloads in the open" % o.id, "bad")
			return
	# a suspect running for it keeps running unless shot at (v0.7)
	var fl: Dictionary = o.ticker.get("flee", {})
	if not fl.is_empty() and (w.t - o.last_stress_t > 1.2 or fl.get("gas", false)):
		o.dbg = "running for it"
		o.aim = {}
		w.move_to(o, fl["p"], "sprint")
		_finish_look(o)
		return
	var withdrawing: bool = el["mode"] == "withdraw"
	# P4: engage beyond 10 m (a squad withdrawing only answers fire)
	var far = _far_target(o)
	if far != null and withdrawing and not w.attacking(far, o):
		far = null
	if far == null and o.ticker.has("far_dest") and _to_far_dest(o):
		return
	if far != null:
		_engage_far(o, far)
		return
	# police rules: cuff anyone close by who has given up (v0.6)
	if o.judges and not withdrawing and _arrest(o):
		_finish_look(o)
		return
	# Rescue (v0.7): walk a freed hostage out to the casualty point
	if o.ticker.has("escort") and not withdrawing:
		if _task_escort(o):
			_finish_look(o)
			return
	# a medical kit (v0.7.5): once it is quiet, treat the downed nearby
	if not withdrawing and _treat(o, tm):
		_finish_look(o)
		return
	# fixation on a body (no ED05)
	if o.ticker.get("fixate_until", -1.0) > w.t:
		o.dbg = "staring at body"
		w.stop(o)
		o.look_goal = (o.ticker["fixate_p"] - o.pos).angle()
		return
	# P5 react
	if _react(o, tm):
		_finish_look(o)
		return
	# P6 maintain
	if _maintain(o):
		_finish_look(o)
		return
	# P7 task
	match el["mode"]:
		"assault":
			_task_assault(o, tm, el)
		"hold":
			_task_hold(o)
		"hunt":
			_task_hunt(o, tm, el)
		"support":
			_task_support(o, tm, el)
		"transit":
			_task_transit(o, el)
		"withdraw":
			_task_withdraw(o, el)
		"wait":
			w.stop(o)
			o.dbg = "waiting on the phase line"
		_:
			w.stop(o)
			o.dbg = "waiting"
	_finish_look(o)


# ------------------------------------------------------------------ Rule 1
func _close_threat(o):
	var best = null
	var best_d := 10.0001
	var cur: String = o.aim.get("tid", "")
	var cur_d := INF
	for e in w.visible_tracked(o):
		if not e.alive():
			var until: float = o.ticker.get("confirm_" + e.id, -1.0)
			if until < 0.0 and cur == e.id:
				until = e.ticker.get("down_t", w.t) + (0.15 if o.has("ED05") else 0.6) + (1.0 if o.hb("BH03") else 0.0)
				o.ticker["confirm_" + e.id] = until
			if w.t > until:
				if until > 0.0 and not o.ticker.has("assessed_" + e.id):
					o.ticker["assessed_" + e.id] = true
					if not o.has("ED05"):
						o.ticker["fixate_until"] = w.t + w.rng.randf_range(1.0, 2.0)
						o.ticker["fixate_p"] = e.pos
				continue
		var d: float = o.pos.distance_to(e.pos)
		if d > 10.0:
			continue
		if e.id == cur:
			cur_d = d
		if d < best_d:
			best_d = d
			best = e
	if best != null and cur != "" and cur_d <= 10.0 and best.id != cur and best_d > cur_d - 0.5:
		best = w.op_by_id(cur)
	# HD09 drop the point man (hold): whoever is in a doorway of the room goes first
	if best != null and o.holding and o.has("HD09"):
		var door_e = _at_room_door(o)
		if door_e != null:
			return door_e
	return best


func _rule1(o, e) -> void:
	var tm: Dictionary = w.teams[o.team]
	tm["last_contact"] = w.t
	o.last_contact_t = w.t
	o.dbg = "RULE 1 > " + e.id
	o.look_goal = (e.pos - o.pos).angle()
	if not o.action.is_empty() and o.action["type"] in ["check", "stall"]:
		o.action = {}
	if not o.action.is_empty():
		return
	var s: Dictionary = o.ws()
	if s["mag"] <= 0 or s["lost"]:
		if o.usable(o.other()):
			_transition(o)
		else:
			_rule2(o)
		return
	if s["jam"]:
		if o.active == "rifle" and o.has("WD06") and o.usable("pistol"):
			w.say("%s: stoppage inside 10 m, transitions to pistol" % o.id, "rule")
			_transition(o)
		else:
			_clear(o)
		return
	if o.has("PF07") and o.sidestep.is_empty() and not o.ticker.has("pf07_" + e.id) and e.alive():
		o.ticker["pf07_" + e.id] = true
		var b: float = (e.pos - o.pos).angle()
		var best_dir := Vector2.ZERO
		var best_s := INF
		for sgn in [1.0, -1.0]:
			var dv := Vector2.from_angle(b + PI / 2.0 * sgn)
			if not w.nav.is_free(o.pos + dv * 1.2):
				continue
			if not w.geom.sight_clear(o.pos + dv * 1.2, o.eye(), e.pos, e.zone_centre("chest")):
				continue
			var sc: float = w.geom.dist_to_kinds(o.pos + dv * 1.2, [Geom.COVER, Geom.WALL], 3.0)
			if sc < best_s:
				best_s = sc
				best_dir = dv
		if best_dir != Vector2.ZERO:
			o.sidestep = {"dir": best_dir, "left": 1.0}
	if o.sidestep.is_empty() and not _close_in(o, e):
		w.stop(o)
	w.engage(o, e, _aim_zone(o, e), true)


## Less-lethal (v0.8): an unarmed man who has ignored two challenges, and no tool this
## officer carries is in range now: one officer moves to where one is, walking in for OC
## spray (3 m) or a baton (arm's reach), stepping back for beanbags (4 m and more), while
## the others cover. True while moving.
func _close_in(o, e) -> bool:
	if not o.judges or not e.alive() or e.complying or e.civ or e.shows_weapon() or e.stunned(w.t):
		return false
	if int(o.ticker.get("chal_n_" + e.id, 0)) < 2 or o.judged.get(e.id, {}).get("v", "") != "unknown":
		return false
	var d: float = o.pos.distance_to(e.pos)
	if d > 12.0 or w.less_tool(o, e, d) != "":
		return false
	# the smallest move that puts a carried tool in range
	var want := -1.0
	for gid in Equipment.LESS_ORDER:
		if int(o.gear.get(gid, 0)) <= 0:
			continue
		var sp: Dictionary = Equipment.GEAR[gid]
		if float(sp.get("blind", 0.0)) > 0.0 and (e.blind(w.t) or e.masked()):
			continue
		var lo: float = float(sp.get("min", 0.0))
		var hi: float = float(sp["range"])
		var goal: float = hi * 0.7 if d > hi else (minf(lo * 1.25 + 0.5, hi) if d < lo else d)
		if want < 0.0 or absf(goal - d) < absf(want - d):
			want = goal
	if want < 0.0:
		return false
	var by: String = e.ticker.get("close_by", "")
	if by != "" and by != o.id:
		var other = w.by_id.get(by, null)
		if other != null and other.alive() and w.t - float(e.ticker.get("close_t", -99.0)) < 2.0:
			return false
	var away: Vector2 = (o.pos - e.pos).normalized() if d > 0.05 else Vector2.RIGHT
	var spot: Vector2 = w.nav.snap(e.pos + away * want)
	if want > d and (spot.distance_to(e.pos) < d + 0.3 or not w.geom.sight_clear(spot, 1.6, e.pos, 1.2)):
		return false
	e.ticker["close_by"] = o.id
	e.ticker["close_t"] = w.t
	w.move_to(o, spot, "walk")
	o.dbg = ("closing in > " if want < d else "stepping back > ") + e.id
	return true


func _aim_zone(o, e) -> String:
	if not e.alive():
		return "chest"
	if o.hb("BH19"):
		return "chest"
	if o.has("WD08") and o.aim.get("plate_seen", false) and o.aim.get("tid", "") == e.id:
		var d: float = maxf(o.pos.distance_to(e.pos), 0.5)
		var w_head := 2.0 * atan(0.11 / d) * 1000.0
		if w.sigma_shooter(o, 0.3) <= 0.5 * w_head:
			return "head"
		return "abd"
	return "chest"


# ------------------------------------------------------------------ Rule 2 and weapon handling
func _transition(o) -> void:
	if not o.action.is_empty():
		return
	var other: String = o.other()
	if not o.usable(other):
		return
	if o.ws()["mag"] <= 0 and not o.has("WD01") and not o.ticker.get("clicked", false):
		w.start_action(o, "click", 0.4)
		return
	o.ticker["clicked"] = false
	w.start_action(o, "transition", o.ech["transition"], {"to": other})
	w.say("%s transitions to %s (Rule 2)" % [o.id, other], "rule")


func _rule2(o) -> void:
	o.dbg = "RULE 2"
	if not o.action.is_empty():
		return
	if o.usable(o.other()):
		_transition(o)
		return
	var threats := _threats(o)
	var which := _reload_choice(o)
	if which == "":
		o.dbg = "out of ammo"
		_seek_cover(o, threats)
		return
	if threats.is_empty() or _hidden(o.pos, threats, 0.82):
		w.stop(o)
		if not threats.is_empty():
			o.stance_goal = Op.DUCK
			o.ticker["duck_action"] = true
		o.ticker.erase("cover_wait")
		_reload(o, which, true)
		return
	_seek_cover(o, threats)


func _seek_cover(o, threats: Array) -> void:
	if threats.is_empty():
		return
	var dest = _cover_point(o, threats)
	if dest == null:
		o.dbg += " (finding cover)"
		w.stop(o)
		return
	o.dbg += " > cover"
	var prof := 0 if o.hb("BH10") else -1
	if not w.at(o, dest, 0.3):
		w.move_to(o, dest, "run", prof)
	else:
		w.stop(o)
		o.stance_goal = Op.DUCK
	var lk = _latest_lkp(o)
	if lk != null:
		o.look_goal = (lk["p"] - o.pos).angle()


func _reload_choice(o) -> String:
	if not o.weapons["rifle"]["lost"] and o.weapons["rifle"]["spare"] > 0:
		return "rifle"
	if o.weapons["pistol"]["spare"] > 0:
		return "pistol"
	return ""


func _reload(o, which: String, from_rule2: bool) -> void:
	var dur: float = Habits.WEAPONS[which]["reload"] * o.ech["reload"]
	if which != o.active:
		dur += o.ech["transition"]
	w.start_action(o, "reload", dur, {"w": which})
	if from_rule2:
		w.say("%s reloads %s behind cover" % [o.id, which], "rule")


func _clear(o) -> void:
	if not o.action.is_empty():
		return
	var dur := 0.0
	var p_ok := 0.8
	if o.hb("BH19"):
		dur = 3.0
		p_ok = 0.95
	elif o.has("WD05"):
		dur = 1.2
		p_ok = 0.95
	else:
		dur = w.rng.randf_range(2.5, 4.0)
	w.start_action(o, "clear", dur, {"p_ok": p_ok})


func _stoppage(o) -> void:
	o.dbg = "stoppage"
	if not o.action.is_empty():
		return
	var threats := _threats(o)
	if o.has("WD03") and not threats.is_empty() and not _hidden(o.pos, threats, 0.82):
		_seek_cover(o, threats)
		return
	w.stop(o)
	if not threats.is_empty():
		o.stance_goal = Op.DUCK
		o.ticker["duck_action"] = true
	_clear(o)


## Positions of the threats an operator knows about: seen now, or last seen within 15 s.
## Only the nearest five within 40 m count (cover is chosen against what matters).
func _threats(o) -> Array:
	var out: Array = []
	for eid in o.lkp:
		var e = w.by_id.get(eid, null)
		if e == null or not e.alive():
			continue
		if w.visible(o, e):
			out.append(e.pos)
		elif w.t - o.lkp[eid]["t"] < 15.0:
			out.append(o.lkp[eid]["p"])
	if out.size() > 1:
		out = out.filter(func(p): return o.pos.distance_to(p) <= 40.0)
		if out.size() > 5:
			out.sort_custom(func(a, b): return o.pos.distance_squared_to(a) < o.pos.distance_squared_to(b))
			out.resize(5)
	return out


func _hidden(p: Vector2, threats: Array, head_z: float) -> bool:
	for tp in threats:
		if w.geom.sight_clear(tp, 1.65, p, head_z):
			return false
	return true


func _cover_point(o, threats: Array):
	if o.has("PF09"):
		var cache: Dictionary = o.ticker.get("cover_cache", {})
		if not cache.is_empty() and cache["p"] != null and w.t - cache["t"] < 0.8:
			return cache["p"]
		return _find_cover(o, threats, true)
	if o.ticker.has("cover_dest") and w.t - o.ticker["cover_dest_t"] < 3.0:
		return o.ticker["cover_dest"]
	if not o.ticker.has("cover_wait"):
		o.ticker["cover_wait"] = w.t + 0.4
		return null
	if w.t < o.ticker["cover_wait"]:
		return null
	var p = _find_cover(o, threats, false)
	o.ticker["cover_dest"] = p
	o.ticker["cover_dest_t"] = w.t
	return p


func _find_cover(o, threats: Array, smart: bool):
	var cands: Array = w.nav.spots_near(o.pos, 12.0)
	var best = null
	var best_s := INF
	var n := 0
	for item in cands:
		n += 1
		var d := sqrt(item[0])
		if n > 60 or d >= best_s:
			break
		var c: Dictionary = item[1]
		var p: Vector2 = c["p"]
		if not _hidden(p, threats, 0.82):
			continue
		var sc := d
		if smart:
			sc += 2.5 * _route_exposure(o.pos, p, threats)
			if o.has("PF05"):
				sc += 2.0 * absf(c["gap"] - 1.0)
		else:
			sc += 0.3 * c["gap"]
		if sc < best_s:
			best_s = sc
			best = p
	return best


func _route_exposure(a: Vector2, b: Vector2, threats: Array) -> float:
	var n := 0.0
	for k in range(1, 5):
		var p := a.lerp(b, k / 5.0)
		for tp in threats:
			if w.geom.sight_clear(tp, 1.65, p, 1.3):
				n += 1.0
				break
	return n


# ------------------------------------------------------------------ arrests (v0.6)
## The nearest person who has given up and is not yet cuffed, within 20 m and in sight,
## that no other officer is already cuffing: walk up and cuff them (3 s).
func _arrest(o) -> bool:
	if not o.action.is_empty():
		return o.action.get("type", "") == "cuff"
	var best = null
	var bd := 20.0
	for e in w.ops:
		if not e.complying or e.arrested or not e.alive():
			continue
		var by: String = e.ticker.get("cuff_by", "")
		if by != "" and by != o.id:
			var other = w.by_id.get(by, null)
			if other != null and other.alive() and w.t - e.ticker.get("cuff_t", -99.0) < 30.0:
				continue
		var d: float = o.pos.distance_to(e.pos)
		if d < bd and (d < 3.0 or w.geom.sight_clear(o.pos, o.eye(), e.pos, 0.8)):
			bd = d
			best = e
	if best == null:
		return false
	if best.ticker.get("cuff_by", "") != o.id:
		w.say("%s moves in to cuff %s" % [o.id, best.id], "comms")
	best.ticker["cuff_by"] = o.id
	best.ticker["cuff_t"] = w.t
	o.dbg = "ARREST > " + best.id
	o.look_goal = (best.pos - o.pos).angle()
	if bd > 0.95:
		var side: Vector2 = (o.pos - best.pos).normalized()
		var spot: Vector2 = best.pos + side * 0.75
		w.move_to(o, spot if w.nav.is_free(spot) else best.pos, "walk")
		return true
	w.stop(o)
	w.start_action(o, "cuff", 3.0, {"tid": best.id})
	return true


# ------------------------------------------------------------------ BH09
func _jumpy(o) -> bool:
	if not o.usable(o.active) or not o.action.is_empty():
		return false
	for eid in o.vis:
		var e = w.by_id.get(eid, null)
		if e == null or not e.alive() or w.visible(o, e) or not w.attends(o, e):
			continue
		var p: float = o.rec.get(e.id, 0.0)
		if p >= 0.5 and o.vis.get(e.id, {}).get("los", false) and o.pos.distance_to(e.pos) <= 10.0 and e.vel.length() > 0.3:
			o.dbg = "jumpy trigger > " + e.id
			o.look_goal = (e.pos - o.pos).angle()
			w.stop(o)
			# fires before knowing who it is: friend, foe or a civilian running
			w.engage(o, e, "chest", true, true)
			return true
	for m in w.mates_near(o, 4.0):
		var d: Vector2 = m.pos - o.pos
		if d.length() < 4.0 and m.vel.length() > 0.5 and absf(angle_difference(o.look_dir, d.angle())) < deg_to_rad(40.0):
			if w.rng.randf() < 0.05 * DT and o.ws()["mag"] > 0:
				w.say("%s startles and fires at %s" % [o.id, m.id], "bad")
				w._fire(o, d.angle(), 1.3, d.length(), 0.0)
	return false


# ------------------------------------------------------------------ P4
func _far_target(o):
	var vis: Array = w.visible_enemies(o)
	if vis.is_empty():
		return null
	var cur: String = o.aim.get("tid", "")
	if o.has("ED04"):
		var team_pos: Array = [o.pos]
		for m in w.mates_of(o):
			team_pos.append(m.pos)
		for e in vis:
			for tp in team_pos:
				if absf(angle_difference(e.muzzle_dir, (tp - e.pos).angle())) < deg_to_rad(20.0):
					return e
	elif o.hb("BH16"):
		var best = null
		var best_s := INF
		for e in vis:
			var sc: float = o.pos.distance_to(e.pos) + (20.0 if o.vis[e.id].get("head_only", false) else 0.0)
			if sc < best_s:
				best_s = sc
				best = e
		return best
	for e in vis:
		if e.id == cur:
			return e
	var first = vis[0]
	for e in vis:
		if o.first_rec.get(e.id, 0.0) < o.first_rec.get(first.id, 0.0):
			first = e
	return first


func _engage_far(o, e) -> void:
	var tm: Dictionary = w.teams[o.team]
	tm["last_contact"] = w.t
	o.last_contact_t = w.t
	o.dbg = "engage > " + e.id
	o.look_goal = (e.pos - o.pos).angle()
	if not o.action.is_empty():
		return
	if o.hb("BH13") and o.hide_until > w.t:
		o.dbg = "hiding"
		o.stance_goal = Op.DUCK
		w.stop(o)
		return
	# under fire at range, trained shooters move to a fighting position: hidden when
	# ducked, able to shoot over the cover when crouched
	var key: String = "farcover_" + e.id
	var under_fire: bool = w.t - o.last_stress_t < 1.5
	if (o.has("PF05") or o.has("PF09")) and under_fire and not o.ticker.has(key):
		o.ticker[key] = true
		if not _hidden(o.pos, [e.pos], 0.82):
			var dest = _fighting_position(o, e)
			if dest != null:
				o.ticker["far_dest"] = dest
				o.ticker["far_until"] = w.t + 3.0
	if o.ticker.has("far_dest") and _to_far_dest(o):
		return
	# PF08: come up somewhere new after reloading or clearing behind cover
	if o.ticker.get("reengage", false):
		o.ticker["reengage"] = false
		if o.has("PF08") and o.last_exposure != Vector2.INF:
			var spot = _new_spot(o, e)
			if spot != null:
				o.ticker["far_dest"] = spot
				return
	if o.hb("BH15") and o.pos.distance_to(e.pos) > 6.0:
		w.move_to(o, e.pos, "walk", -1, true)
	elif not _close_in(o, e):
		w.stop(o)
	# fire over half cover from a crouch
	if o.ticker.get("stance_t", -1.0) < w.t:
		o.ticker["stance_t"] = w.t + 0.5
		var hidden_ducked: bool = not w.geom.sight_clear(e.pos, e.eye(), o.pos, 0.82)
		var seen_crouched: bool = w.geom.sight_clear(e.pos, e.eye(), o.pos, 1.125)
		o.ticker["crouch"] = hidden_ducked and seen_crouched
	if o.ticker.get("crouch", false):
		o.stance_goal = Op.CROUCH
	o.last_exposure = o.pos
	if o.hb("BH13"):
		o.hide_until = maxf(o.hide_until, o.last_stress_t + 3.0) if w.t - o.last_stress_t < 0.2 else o.hide_until
	# HD08 wait for the funnel (hold): aim, but hold fire at range until the enemy is at
	# an opening of the room, attacking, or the squad has opened up
	if o.holding and o.has("HD08") and not _funnel_ready(o, e):
		o.dbg = "waiting for the funnel > " + e.id
		w.engage(o, e, _aim_zone(o, e), false)
		return
	w.engage(o, e, _aim_zone(o, e), true)


func _fighting_position(o, e):
	var best = null
	var best_s := INF
	for item in w.nav.spots_near(o.pos, 4.0):
		var c: Dictionary = item[1]
		var p: Vector2 = c["p"]
		var d: float = sqrt(item[0])
		if d >= best_s:
			break
		if w.geom.sight_clear(e.pos, e.eye(), p, 0.82):
			continue
		if not w.geom.sight_clear(e.pos, e.eye(), p, 1.125):
			continue
		var sc: float = d + (2.0 * absf(c["gap"] - 1.0) if o.has("PF05") else 0.5 * c["gap"])
		if sc < best_s:
			best_s = sc
			best = p
	return best


## Keep moving to a chosen fighting position for up to 3 s, even if sight is lost on
## the way; on arrival, hold it for a moment instead of drifting back to the task.
func _to_far_dest(o) -> bool:
	var dest: Vector2 = o.ticker["far_dest"]
	if w.at(o, dest, 0.3) or w.t > o.ticker.get("far_until", 0.0):
		o.ticker.erase("far_dest")
		o.ticker["hold_pos_until"] = w.t + 2.5
		return false
	w.move_to(o, dest, "run")
	o.dbg = "to fighting position"
	var lk = _latest_lkp(o)
	if lk != null:
		o.look_goal = (lk["p"] - o.pos).angle()
	return true


func _new_spot(o, e):
	for item in w.nav.spots_near(o.pos, 4.0):
		var c: Dictionary = item[1]
		var p: Vector2 = c["p"]
		var d: float = sqrt(item[0])
		if d < 1.5 or p.distance_to(o.last_exposure) < 1.5:
			continue
		if w.geom.sight_clear(e.pos, e.eye(), p, 1.3):
			return p
	return null


# ------------------------------------------------------------------ P5 react
func _react(o, tm: Dictionary) -> bool:
	var lk = _latest_lkp(o)
	if o.ticker.get("hold_pos_until", -1.0) > w.t and lk != null:
		o.dbg = "holding fighting position"
		w.stop(o)
		o.stance_goal = Op.CROUCH
		o.look_goal = (lk["p"] - o.pos).angle()
		return true
	if o.hb("BH13") and w.t - o.last_contact_t < 3.0:
		o.dbg = "hiding"
		o.stance_goal = Op.DUCK
		w.stop(o)
		return true
	if o.hb("BH12") and lk != null and w.t - lk["t"] > 0.3 and w.t - lk["t"] < 15.0 and o.pos.distance_to(lk["p"]) > 1.2:
		o.dbg = "chasing contact"
		w.move_to(o, lk["p"], "sprint", -1, true)
		o.look_goal = (lk["p"] - o.pos).angle()
		_task_look(o, o.look_goal)
		return true
	if o.has("ED08") and lk != null and w.t - lk["t"] < 3.0 and w.t - lk["t"] > 0.05:
		o.dbg = "holding last-known position"
		w.stop(o)
		var dir: float = (lk["p"] - o.pos).angle()
		_task_look(o, dir)
		o.muzzle_dir = rotate_toward(o.muzzle_dir, dir, deg_to_rad(o.ech["turn"]) * DT)
		return true
	if o.hb("BH15"):
		var tl = _team_lkp(tm, 15.0, o.pos)
		if tl != null and o.pos.distance_to(tl) > 1.5 and not _stuck_on(o, tl):
			o.dbg = "lone wolf push"
			w.move_to(o, tl, "walk", -1, true)
			return true
	return false


func _latest_lkp(o):
	var best = null
	for eid in o.lkp:
		var e2 = w.by_id.get(eid, null)
		if e2 == null or not e2.alive():
			continue
		var l: Dictionary = o.lkp[eid]
		if best == null or l["t"] > best["t"]:
			best = l
	return best


func _team_lkp(tm: Dictionary, within: float, from: Vector2):
	var best = null
	var bt := -INF
	for eid in tm["lkps"]:
		var e = w.op_by_id(eid)
		if e == null or not e.alive():
			continue
		var l: Dictionary = tm["lkps"][eid]
		if l["t"] > bt and from.distance_to(l["p"]) <= within:
			bt = l["t"]
			best = l["p"]
	return best


# ------------------------------------------------------------------ P6 maintain
func _maintain(o) -> bool:
	if not o.action.is_empty():
		o.dbg = o.action["type"]
		return true
	var lull: float = w.t - o.last_enemy_seen_t
	var s: Dictionary = o.ws()
	var cap: int = o.wpn()["mag"]
	var want := ""
	if o.active == "pistol" and lull > 3.0:
		if o.weapons["rifle"]["mag"] > 0 and not o.weapons["rifle"]["lost"] and not o.weapons["rifle"]["jam"]:
			if o.has("WD02") and s["mag"] < cap and s["spare"] > 0:
				want = "pistol"
			else:
				w.start_action(o, "transition", o.ech["transition"], {"to": "rifle"})
				return true
		elif not o.weapons["rifle"]["lost"] and o.weapons["rifle"]["spare"] > 0:
			want = "rifle"
	elif o.has("WD02") and lull > 2.0 and s["mag"] < int(cap * 0.4) and s["spare"] > 0:
		want = o.active
	if want == "":
		return false
	var threats := _threats(o)
	if o.has("WD03") and not threats.is_empty() and not _hidden(o.pos, threats, 0.82):
		o.dbg = "to cover to reload"
		_seek_cover(o, threats)
		return true
	w.stop(o)
	_reload(o, want, false)
	return true


# ------------------------------------------------------------------ P7 tasks
func _go(o, p: Vector2, mode: String, group := true, free := false) -> void:
	var el := _el(o)
	var mates: Array = _el_mates(o)
	var outside: bool = w.level.is_exterior(o.room)
	if group and not mates.is_empty():
		var near = mates[0]
		for m in mates:
			if m.pos.distance_to(o.pos) < near.pos.distance_to(o.pos):
				near = m
		if o.has("GD10") and o.pos.distance_to(near.pos) > 8.0 and (p - o.pos).dot(near.pos - o.pos) < 0.0:
			o.dbg = "waiting (tether)"
			w.stop(o)
			return
		if el["bound"] >= 0 and o.eslot % 2 != el["bound"] and outside and o.has("GD05"):
			o.dbg = "overwatch"
			w.stop(o)
			_task_look(o, (p - o.pos).angle())
			return
		if o.hb("BH14") and o.pos.distance_to(near.pos) > 1.0 and near.pos.distance_to(p) > 2.0:
			p = near.pos + (o.pos - near.pos).limit_length(0.8)
		elif o.has("GD07"):
			var ahead: Vector2 = near.pos - o.pos
			if ahead.length() < 1.5 and ahead.dot(p - o.pos) > 0.0 and near.vel.length() > 0.2:
				o.dbg = "keeping spacing"
				w.stop(o)
				return
		if o.has("GD03") and _in_line_of_fire(o, w.mates_near(o, 7.0)):
			if o.ticker.get("gd03_wait", -1.0) < 0.0:
				o.ticker["gd03_wait"] = w.t
			if w.t - o.ticker["gd03_wait"] < 1.0:
				o.dbg = "not crossing line of fire"
				w.stop(o)
				return
		else:
			o.ticker["gd03_wait"] = -1.0
	var m2 := mode
	if outside and (mode == "walk" or mode == "clear"):
		m2 = "walk"
		if o.has("PF06") and _open_ground(o):
			var sp: float = o.ticker.get("sprint_s", 0.0)
			if sp < 3.0:
				m2 = "sprint"
				o.ticker["sprint_s"] = sp + DT
			elif sp < 3.4:
				o.ticker["sprint_s"] = sp + DT
				w.stop(o)
				o.dbg = "between rushes"
				return
			else:
				o.ticker["sprint_s"] = 0.0
		if o.has("PF02") and _near_window(o.pos):
			m2 = "creep"
			o.stance_goal = Op.DUCK
	w.move_to(o, p, m2, -1, free)


## A teammate's muzzle line is live while they are aiming or have fired in the last
## 1.5 s; an overwatcher who is only scanning keeps the muzzle off friends.
func _in_line_of_fire(o, mates: Array) -> bool:
	for m in mates:
		if m.aim.is_empty() and w.t - m.last_shot_t > 1.5:
			continue
		var u := Vector2.from_angle(m.muzzle_dir)
		var rel: Vector2 = (o.pos + o.vel.normalized() * 0.4) - m.pos
		var s := rel.dot(u)
		if s > 0.3 and s < 6.0 and absf(rel.cross(u)) < 0.45:
			return true
	return false


func _open_ground(o) -> bool:
	if o.ticker.get("open_t", -1.0) < w.t:
		o.ticker["open_t"] = w.t + 0.25
		o.ticker["open"] = w.geom.dist_to_kinds(o.pos, [Geom.COVER, Geom.WALL], 3.0) >= 2.9
	return o.ticker["open"]


func _near_window(p: Vector2) -> bool:
	for i in w.level.openings_near(p, 1.4):
		if w.level.openings[i]["kind"] == "window" and not w.level.is_inside(p):
			return true
	return false


func _task_look(o, dir: float) -> void:
	o.ticker["task_look"] = dir
	o.ticker["task_look_tick"] = tick


func _task_assault(o, tm: Dictionary, el: Dictionary) -> void:
	if el["task"].is_empty():
		w.stop(o)
		return
	var st: Dictionary = el["task"]
	var D: Dictionary = w.level.doors[st["door"]]
	var c: Vector2 = D["c"]
	var n_in: Vector2 = w.level.inward(st["door"], st["into"])
	var entry: Dictionary = el["entry"]
	var ctl: Dictionary = el["ctl"]
	if not entry.has(o.id):
		return
	var d: Dictionary = entry[o.id]
	match el["phase"]:
		"check":
			if not ctl.has("checker"):
				var best = null
				for m in _alive(el):
					if m.has("PF10") and (best == null or m.pos.distance_to(c) < best.pos.distance_to(c)):
						best = m
				ctl["checker"] = best.id if best != null else ""
			if ctl["checker"] == o.id:
				var cp: Vector2 = w.nav.snap(c - n_in * 1.1 + D["t"] * 0.35)
				o.dbg = "checking the " + w.level.rooms[st["into"]]["title"].to_lower()
				if not w.at(o, cp, 0.3):
					_go(o, cp, "clear", false)
					_task_look(o, (c - o.pos).angle())
				else:
					w.stop(o)
					_task_look(o, (c + n_in * 1.6 - o.pos).angle())
					if not ctl.has("check_done_t"):
						ctl["check_done_t"] = w.t + 1.0
			else:
				o.dbg = "covering the check"
				w.stop(o)
		"approach":
			var wps: Array = d["wps"]
			if d["wi"] < wps.size():
				var target: Vector2 = wps[d["wi"]]
				var slicing: bool = d["wi"] < wps.size() - 1
				var mode := "walk"
				if slicing and o.pos.distance_to(c) < 3.2:
					mode = "slice"
				if not w.level.is_inside(o.pos) and not slicing:
					mode = "walk"
				elif w.level.is_inside(o.pos):
					mode = "clear"
				if o.hb("BH11"):
					mode = "sprint"
				_go(o, target, mode, true, o.hb("BH11"))
				if slicing:
					o.dbg = "slicing the pie"
					_task_look(o, (c + n_in * 2.5 - o.pos).angle())
				if w.at(o, target, 0.35):
					d["wi"] += 1
			else:
				w.stop(o)
				d["at_stack"] = true
				if not d["checked"] and o.action.is_empty():
					d["checked"] = true
					w.start_action(o, "check", 1.0)
					w.say("%s function check" % o.id, "info")
				var look_in: float = (c + n_in * 2.5 - o.pos).angle()
				if o.has("ED10"):
					_task_look(o, look_in)
					if absf(angle_difference(o.look_dir, look_in)) < 0.3:
						d["looked"] += DT
				d["ready"] = d["checked"] and o.action.is_empty() and (not o.has("ED10") or d["looked"] >= 0.5)
				if d["ready"] and not ctl.has("first_ready_t"):
					ctl["first_ready_t"] = w.t
				o.dbg = "stacked" if o.has("GD01") else "waiting at the door"
		"breach":
			if ctl.get("breacher", "") == o.id:
				# a ram, a breaching round or a boot work from in front of the door; a door
				# that is only shut is opened from beside it, out of the doorway
				var bp: Vector2 = w.nav.snap(c - n_in * 0.7)
				if not w.level.door_locked(st["door"]):
					var g2: Dictionary = el["geo"]
					var side_p: Vector2 = c - n_in * 0.45 + (g2["side"] as Vector2) * (float(D["half"]) + 0.55)
					if w.nav.reachable(w.nav.snap(side_p)):
						bp = w.nav.snap(side_p)
				o.dbg = "breaching"
				if not w.at(o, bp, 0.45):
					_go(o, bp, "walk", false)
				else:
					w.stop(o)
					o.look_goal = (c - o.pos).angle()
					w.work_door(o, st["door"])
			else:
				w.stop(o)
				_task_look(o, (c + n_in * 2.5 - o.pos).angle())
				o.dbg = "stacked for the breach"
		"bang":
			# out of the flash's sight, eyes away until it goes off
			var bp2: Vector2 = _bang_point(el)
			var key: String = "safe_" + o.id
			if not ctl.has(key):
				# back to the stack slot, or somewhere out of the flash's sight if the slot is not
				ctl[key] = d["stack"] if not _exposed(d["stack"], bp2) else _bang_safe(el, o, bp2)
			var sp2: Vector2 = ctl[key]
			if not w.at(o, sp2, 0.3):
				_go(o, sp2, "run", false)
			else:
				w.stop(o)
			if float(ctl.get("bang_det", -1.0)) >= 0.0:
				_task_look(o, (-n_in).angle())
				o.dbg = "flashbang: eyes away"
			else:
				_task_look(o, (c + n_in * 2.0 - o.pos).angle())
				o.dbg = "flashbang: clearing the throw"
		"gas_wait":
			# out of the room's line of fire (where they stood for the throw), weapons on
			# the door: whoever comes out of the gas is met there
			var gsp: Vector2 = ctl.get("safe_" + o.id, d["stack"])
			if not w.at(o, gsp, 0.35):
				_go(o, gsp, "walk", false)
			else:
				w.stop(o)
			_task_look(o, (c - o.pos).angle())
			o.dbg = "gas: holding the door"
		"sweep":
			_task_sweep(o, el)
		"entry", "clear":
			if not d["enters"]:
				var sp: Vector2 = d["stack"]
				if not w.at(o, sp, 0.35):
					_go(o, sp, "walk", false)
				else:
					w.stop(o)
				o.dbg = "rear security"
				if o.has("ED09"):
					_task_look(o, (-n_in).angle() + sin(w.t * 0.7 + o.slot) * 0.8)
				else:
					_task_look(o, (c + n_in * 2.0 - o.pos).angle())
				return
			if d["order"] > 0:
				var lead = null
				var lead_order := -1
				for m in _alive(el):
					if entry.has(m.id) and entry[m.id]["enters"] and entry[m.id]["order"] < d["order"] and entry[m.id]["order"] > lead_order:
						lead = m
						lead_order = entry[m.id]["order"]
				if lead != null:
					var depth: float = (lead.pos - c).dot(n_in)
					var ok := depth >= 0.0
					if o.has("GD07"):
						ok = lead.pos.distance_to(c) >= 1.4 or entry[lead.id]["arrived"]
					if not ok:
						w.stop(o)
						_task_look(o, (c + n_in * 2.0 - o.pos).angle())
						o.dbg = "waiting for #%d" % (lead_order + 1)
						return
			var depth_me: float = (o.pos - c).dot(n_in)
			var lateral: float = absf((o.pos - c).dot(D["t"]))
			var in_door := absf(depth_me) < 0.45 and lateral < 0.7
			if in_door and not d["paused"] and (not o.has("PF01") or o.hb("BH06")):
				d["paused"] = true
				var dur: float = 1.0 if o.hb("BH06") else w.rng.randf_range(1.0, 2.0)
				w.start_action(o, "stall", dur)
				w.say("%s stops in the doorway (%.1f s)%s" % [o.id, dur, " - BH06" if o.hb("BH06") else ""], "bad" if o.hb("BH06") else "info")
				_task_look(o, (w.level.rooms[st["into"]]["label"] - o.pos).angle())
				return
			var target: Vector2 = d["target"]
			if not w.at(o, target, 0.3):
				_go(o, target, "sprint" if o.hb("BH11") else "entry", false, o.hb("BH11"))
			else:
				w.stop(o)
				if not d["arrived"]:
					d["arrived"] = true
			if depth_me > -0.7:
				if not d.has("look_t0"):
					d["look_t0"] = w.t
				var since: float = w.t - d["look_t0"]
				if o.hb("BH20"):
					if not d["swept"]:
						d["swept"] = true
						o.ticker["sweep_until"] = w.t + 2.0
						o.ticker["sweep_from"] = n_in.angle() - PI / 2.0
						o.ticker["sweep_t0"] = w.t
						w.say("%s sweeps left to right (BH20)" % o.id, "bad")
				elif o.has("ED03") and since < 0.9:
					_task_look(o, (d["corner"] - o.pos).angle())
					o.dbg = "hard corner"
				elif since < 2.5 and el["phase"] == "entry":
					_task_look(o, (w.level.rooms[st["into"]]["label"] - o.pos).angle())


func _task_hold(o) -> void:
	var inv: Dictionary = o.ticker.get("investigate", {})
	if not inv.is_empty():
		if w.t > inv["until"] or w.at(o, inv["p"], 1.5):
			o.ticker.erase("investigate")
		else:
			o.dbg = "going after a sound"
			_go(o, inv["p"], "walk", false)
			_task_look(o, (inv["p"] - o.pos).angle())
			return
	if _hold_extras(o):
		return
	if not w.at(o, o.spawn, 0.6):
		# HD14 peel back: one half moves while the other covers
		var el := _el(o)
		if el.get("peel_until", -1.0) > w.t and o.has("HD14") and o.eslot % 2 != int(el.get("peel_half", 0)):
			w.stop(o)
			o.dbg = "covering the peel"
			o.stance_goal = Op.CROUCH
			return
		var prof := (1 if o.has("PF01") else 0) | (2 if o.has("PF02") or o.has("HD06") else 0)
		w.move_to(o, o.spawn, "walk", prof)
		o.dbg = "returning to post"
	else:
		w.stop(o)
		o.dbg = "holding"
		var kind: String = o.ticker.get("post_kind", "")
		if kind == "window" and o.has("HD05"):
			o.stance_goal = Op.CROUCH
		elif kind == "window" and o.hb("BH22"):
			o.stance_goal = Op.STAND


## Progress watchdog for operators who should be closing on a point: true once they have
## gained less than 0.4 m on it for 8 s (blocked, unreachable, or circling), so the
## caller can give the point up.
func _stuck_on(o, p: Vector2) -> bool:
	var key := p.snapped(Vector2(0.5, 0.5))
	var d: float = o.pos.distance_to(p)
	var g: Dictionary = o.ticker.get("prog", {})
	if g.get("key", Vector2.INF) != key:
		o.ticker["prog"] = {"key": key, "best": d, "t": w.t}
		return false
	if d < g["best"] - 0.4:
		g["best"] = d
		g["t"] = w.t
		return false
	return w.t - g["t"] > 8.0


func _task_hunt(o, tm: Dictionary, el: Dictionary) -> void:
	var target = null
	var best_t: float = el["hunt_done_t"]
	var lk = _latest_lkp(o)
	if lk != null and lk["t"] > best_t:
		target = lk["p"]
		best_t = lk["t"]
	for eid in tm["lkps"]:
		var l: Dictionary = tm["lkps"][eid]
		var e = w.op_by_id(eid)
		if e != null and e.alive() and l["t"] > best_t:
			target = l["p"]
			best_t = l["t"]
	var snd: Dictionary = tm["sound"]
	if not snd.is_empty() and snd["t"] > best_t and w.t - snd["t"] < 40.0:
		target = snd["p"]
	var al := _alive(el)
	al.sort_custom(func(a, b): return a.eslot < b.eslot)
	var k := al.find(o)
	if target == null:
		var pts: Array = el.get("patrol", tm.get("patrol", w.level.patrol))
		if pts.is_empty():
			w.stop(o)
			return
		target = pts[el["hunt_i"] % pts.size()]
		if k == 0 and (w.at(o, target, 1.2) or _stuck_on(o, target)):
			el["hunt_i"] += 1
	elif k == 0 and (w.at(o, target, 1.5) or _stuck_on(o, target)):
		el["hunt_done_t"] = w.t
	o.dbg = "hunting"
	if k > 0:
		# followers take wedge slots behind the leader's objective: 1.5 m apart with GD07,
		# bunched at 0.6 m without it; recomputed only when the objective moves
		var key := str((target as Vector2).snapped(Vector2(1, 1)))
		if o.ticker.get("form_key", "") != key:
			o.ticker["form_key"] = key
			var lead = al[0]
			var to_t: Vector2 = target - lead.pos
			var dir: Vector2 = to_t.normalized() if to_t.length() > 0.5 else Vector2.from_angle(lead.body_dir)
			var sp := 1.5 if o.has("GD07") else 0.6
			var row := int((k + 1) / 2)
			var lat := 1.0 if k % 2 == 1 else -1.0
			o.ticker["form_p"] = w.nav.snap(target - dir * sp * row + dir.orthogonal() * sp * 0.8 * lat)
		target = o.ticker["form_p"]
	_go(o, target, "clear" if w.level.is_inside(o.pos) else "walk")


# ------------------------------------------------------------------ P8 eyes
func _finish_look(o) -> void:
	if fine:
		var t0 := Time.get_ticks_usec()
		_finish_look2(o)
		w.prof["look"] = w.prof.get("look", 0) + Time.get_ticks_usec() - t0
		return
	_finish_look2(o)


func _finish_look2(o) -> void:
	var tm: Dictionary = w.teams[o.team]
	# BH24 door stare (hold): eyes locked on the room's nearest door
	if o.holding and o.hb("BH24"):
		var dp = _stare_door(o)
		if dp != null:
			o.look_goal = (dp - o.pos).angle()
			return
	if o.hb("BH04"):
		var lk = _latest_lkp(o)
		if lk != null:
			o.look_goal = (lk["p"] - o.pos).angle()
			return
	if o.ticker.get("sweep_until", -1.0) > w.t:
		o.look_goal = o.ticker["sweep_from"] + deg_to_rad(90.0) * (w.t - o.ticker["sweep_t0"])
		return
	var h: Dictionary = o.look_hint
	if not h.is_empty() and w.t >= h["start"] and w.t <= h["until"]:
		o.look_goal = h["dir"]
		return
	if o.ticker.get("task_look_tick", -1) == tick:
		o.look_goal = o.ticker["task_look"]
		return
	# a posted squad (Contain, Post, occupants where the situation put them) faces its post
	var el0 := _el(o)
	if el0.get("posted", false) and el0["mode"] == "hold" and w.at(o, o.spawn, 0.6):
		o.look_goal = o.spawn_face
		return
	if o.has("ED09") and o.moving and _is_rear(o):
		if fmod(w.t + o.slot * 1.7, 4.0) < 1.0:
			o.look_goal = o.vel.angle() + PI
			return
	if o.has("ED02"):
		_scan(o, tm)
		return
	if o.moving and o.vel.length() > 0.3:
		o.look_goal = o.vel.angle()
		return
	if w.t >= o.ticker.get("salient_next", 0.0):
		o.ticker["salient_next"] = w.t + 2.0
		var best = null
		var bd := INF
		for oi in w.level.openings_near(o.pos, 15.0):
			var p: Vector2 = w.level.openings[oi]["c"]
			var d: float = o.pos.distance_to(p)
			if d > 0.8 and d < bd and w.geom.sight_clear(o.pos, o.eye(), p, 1.2):
				bd = d
				best = p
		o.ticker["salient"] = best
	var sal = o.ticker.get("salient", null)
	if sal != null:
		o.look_goal = (sal - o.pos).angle()
	else:
		o.look_goal = o.spawn_face if _el(o)["mode"] == "hold" else o.look_goal


func _is_rear(o) -> bool:
	var mates: Array = _el_mates(o)
	if mates.is_empty():
		return false
	var dir: Vector2 = o.vel.normalized()
	for m in mates:
		if (m.pos - o.pos).dot(dir) < 0.0:
			return false
	return true


func _scan(o, tm: Dictionary) -> void:
	var el := _el(o)
	var sector = el["sectors"].get(o.id, null)
	var half: float = el["sector_half"]
	if w.t < o.ticker.get("scan_next", 0.0):
		if sector != null and absf(angle_difference(o.look_goal, sector)) > half:
			o.look_goal = sector
		return
	o.ticker["scan_next"] = w.t + w.rng.randf_range(0.9, 1.5)
	var cands: Array = []
	for i in w.level.openings_near(o.pos, 24.0):
		var op: Dictionary = w.level.openings[i]
		var wt := 2.5
		if op["kind"] == "door":
			var D: Dictionary = w.level.doors[op["id"]]
			if el["mode"] == "assault" and _cleared_side(tm, D["a"]) and _cleared_side(tm, D["b"]):
				wt = 1.0
			else:
				wt = 3.0
		cands.append({"p": op["c"], "w": wt, "k": "o%d" % i})
	for cp in w.level.corners_by_room.get(o.room, []):
		cands.append({"p": cp, "w": 2.0, "k": "c%s" % str(cp)})
	for eid in o.lkp:
		var l: Dictionary = o.lkp[eid]
		if w.t - l["t"] < 30.0:
			cands.append({"p": l["p"], "w": 4.0, "k": "l" + eid})
	var best = null
	var best_s := -1.0
	for c in cands:
		var p: Vector2 = c["p"]
		var d: float = o.pos.distance_to(p)
		if d < 0.8 or d > 30.0:
			continue
		var dir: float = (p - o.pos).angle()
		if sector != null and absf(angle_difference(dir, sector)) > half:
			continue
		if not w.geom.sight_clear(o.pos, o.eye(), p, 1.2):
			continue
		var last: float = o.ticker.get("ll_" + c["k"], -99.0)
		var sc: float = c["w"] * minf(3.0, (w.t - last) / 2.0 + 0.3) * w.rng.randf_range(0.8, 1.2)
		if sc > best_s:
			best_s = sc
			best = c
	if best != null:
		o.look_goal = (best["p"] - o.pos).angle()
		o.ticker["ll_" + best["k"]] = w.t
	elif sector != null:
		o.look_goal = sector
	elif o.moving and o.vel.length() > 0.3:
		o.look_goal = o.vel.angle()


## A door side counts as cleared for scanning when the team has cleared that room.
func _cleared_side(tm: Dictionary, rm: String) -> bool:
	return tm["cleared"].has(rm)


## Sweeping a big room: the element's lead walks to the nearest unseen sweep point, the
## rest follow in a wedge (1.5 m apart with GD07, bunched without it).
func _task_sweep(o, el: Dictionary) -> void:
	var al := _alive(el)
	al.sort_custom(func(a, b): return a.eslot < b.eslot)
	var k := al.find(o)
	var lead = al[0]
	var tg = el["sweep_target"]
	if tg == null:
		var bd := INF
		for p in el["sweep"]:
			var dd: float = lead.pos.distance_to(p)
			if dd < bd:
				bd = dd
				tg = p
		el["sweep_target"] = tg
	if tg == null:
		w.stop(o)
		return
	o.dbg = "sweeping"
	var target: Vector2 = tg
	if k > 0:
		var key := str(target.snapped(Vector2(1, 1)))
		if o.ticker.get("form_key", "") != key:
			o.ticker["form_key"] = key
			var to_t: Vector2 = target - lead.pos
			var dir: Vector2 = to_t.normalized() if to_t.length() > 0.5 else Vector2.from_angle(lead.body_dir)
			var sp := 1.5 if o.has("GD07") else 0.6
			var row := int((k + 1) / 2)
			var lat := 1.0 if k % 2 == 1 else -1.0
			o.ticker["form_p"] = w.nav.snap(target - dir * sp * row + dir.orthogonal() * sp * 0.8 * lat)
		target = o.ticker["form_p"]
	if w.at(o, target, 0.5):
		w.stop(o)
	else:
		_go(o, target, "clear")


## An element with no room of its own waits a few metres behind the nearest element that
## is working a door, watching that door.
func _task_support(o, tm: Dictionary, el: Dictionary) -> void:
	var best = null
	var bd := INF
	for other in tm["elements"]:
		if other == el or other["task"].is_empty() or _alive(other).is_empty():
			continue
		var dc: Vector2 = w.level.doors[other["task"]["door"]]["c"]
		var dd: float = o.pos.distance_to(dc)
		if dd < bd:
			bd = dd
			best = other
	if best == null:
		w.stop(o)
		o.dbg = "waiting"
		return
	var st: Dictionary = best["task"]
	var D: Dictionary = w.level.doors[st["door"]]
	var n_in: Vector2 = w.level.inward(st["door"], st["into"])
	var key: String = st["door"] + str(o.eslot)
	if o.ticker.get("support_key", "") != key:
		o.ticker["support_key"] = key
		var lat: float = (o.eslot - 2) * 1.2
		var q: Vector2 = D["c"] - n_in * (4.5 + 0.6 * (o.eslot % 2)) + D["t"] * lat
		o.ticker["support_p"] = w.nav.snap(q)
	var sp: Vector2 = o.ticker["support_p"]
	o.dbg = "supporting " + _tag(tm, best)
	if w.at(o, sp, 0.5):
		w.stop(o)
		_task_look(o, (D["c"] - o.pos).angle())
	else:
		_go(o, sp, "walk")


# ================================================================== defence and sound
## Defensive squads consolidate: one squad per room. A squad takes the free room where
## most of its members already are (ties: the nearest, then the bigger), big enough for
## all of it; members already inside keep their posts, the rest move in to posts covering
## the room's doors and windows. A squad with no room left holds where it stands.
func _consolidate(tm: Dictionary, el: Dictionary) -> void:
	var al := _alive(el)
	if al.is_empty():
		return
	var lv = w.level
	var held: Dictionary = tm["held"]
	var counts := {}
	for m in al:
		var rm: String = lv.room_at(m.pos)
		if not lv.is_exterior(rm):
			counts[rm] = counts.get(rm, 0) + 1
	var c := _centre(al)
	var best := ""
	var best_s := -INF
	var fixed: String = el.get("fixed_room", tm.get("fixed_room", ""))
	var bi: int = tm.get("bldg", -1)
	for name in ([fixed] if fixed != "" else (lv.building_rooms(bi) if bi >= 0 else lv.rooms.keys())):
		if lv.is_exterior(name) or (held.has(name) and fixed == ""):
			continue
		var n_in: int = counts.get(name, 0)
		if lv.room_area(name) < 3.5 * al.size() and n_in < al.size() and fixed == "":
			continue
		var sc: float = n_in * 100.0 - c.distance_to(lv.rooms[name]["label"]) + minf(lv.room_area(name), 40.0) * 0.1
		if lv.rooms[name]["hall"]:
			sc -= 8.0
		if sc > best_s:
			best_s = sc
			best = name
	el["hold_room"] = best
	el["cover_open"] = -1
	if best == "":
		return
	held[best] = el["i"]
	_hold_on(el)
	# members already in the room keep their posts, unless their hold habits choose a
	# post of their own (depth, angles, windows); HD16 keeps one back as a reserve
	var reserve = null
	if al.size() >= 4:
		for m0 in al:
			if m0.has("HD16"):
				reserve = m0
				break
	var moved: Array = []
	var taken: Array = []
	for m in al:
		if m == reserve:
			continue
		if lv.room_at(m.spawn) != best or _picky(m):
			moved.append(m)
		else:
			taken.append(m.spawn)
	for m in moved:
		_post_member(el, m, {}, taken)
		taken.append(m.spawn)
	if reserve != null:
		_reserve_post(el, reserve, taken)
	if not moved.is_empty() or tm["elements"].size() > 1:
		w.say("%s consolidates in the %s" % [_tag(tm, el), lv.rooms[best]["title"].to_lower()], "info")
	el["sector_posture"] = ""


func _release_hold(tm: Dictionary, el: Dictionary) -> void:
	var hr: String = el.get("hold_room", "")
	if hr != "" and tm["held"].get(hr, -1) == el["i"]:
		tm["held"].erase(hr)
	el["hold_room"] = ""


## Give one member a post in the squad's room covering an opening (or the given one).
func _post_member(el: Dictionary, m, only: Dictionary, taken0 := []) -> void:
	var taken: Array = taken0.duplicate()
	for x in _alive(el):
		if x != m and not taken.has(x.spawn):
			taken.append(x.spawn)
	var ops: Array = w.level.room_openings(el["hold_room"])
	var op: Dictionary = only
	if op.is_empty() and not ops.is_empty():
		op = ops[m.eslot % ops.size()]
	var post: Dictionary = _hold_post(el["hold_room"], m, op, taken)
	if post.is_empty():
		var posts: Array = w.level.cover_posts(el["hold_room"], 1, taken, w.nav, op)
		if posts.is_empty():
			return
		post = posts[0]
	m.spawn = post["p"]
	m.spawn_face = post["face"]
	m.ticker["post_op"] = op
	m.ticker["post_kind"] = op.get("kind", "")


## Somebody heard an enemy. Aggressive operators (a hunting team, or the Aggression
## personality) go after the sound; a defensive squad re-posts to cover the opening of
## its room closest to the sound.
func on_heard(o, p: Vector2, kind: String) -> void:
	var tm: Dictionary = w.teams[o.team]
	if o.el < 0 or o.el >= tm["elements"].size():
		return
	var el: Dictionary = tm["elements"][o.el]
	if el["mode"] != "hold":
		return
	if o.hb("BH11") or o.hb("BH12") or o.hb("BH25"):
		var inv: Dictionary = o.ticker.get("investigate", {})
		if inv.is_empty():
			w.say("%s hears %s and goes after it (aggression)" % [o.id, _sound_name(kind)], "bad")
		o.ticker["investigate"] = {"p": p, "until": w.t + 25.0}
		return
	_cover_sound(tm, el, p, kind)


func _sound_name(kind: String) -> String:
	if w.GUN_SOUNDS.has(kind):
		return "gunfire"
	match kind:
		"reload":
			return "a reload"
		"ram", "kick":
			return "a door being broken in"
		"door":
			return "a door"
		"flashbang":
			return "a flashbang"
		"launcher":
			return "a launcher"
	return "footsteps"


func _cover_sound(tm: Dictionary, el: Dictionary, p: Vector2, kind: String) -> void:
	var al := _alive(el)
	var hr: String = el.get("hold_room", "")
	if hr == "":
		# no room: face the sound where they stand
		for m in al:
			if w.visible_enemies(m).is_empty():
				m.spawn_face = (p - m.spawn).angle()
		el["sector_posture"] = ""
		return
	var ops: Array = w.level.room_openings(hr)
	if ops.is_empty():
		return
	var bi := 0
	for i in ops.size():
		if (ops[i]["c"] as Vector2).distance_to(p) < (ops[bi]["c"] as Vector2).distance_to(p):
			bi = i
	if el.get("cover_open", -1) == bi and w.t - el.get("cover_t", -99.0) < 8.0:
		return
	el["cover_open"] = bi
	el["cover_t"] = w.t
	var op: Dictionary = ops[bi]
	# everyone covers that opening, except one rear watcher (ED09 first) in squads of 3+
	# HD13 redistribute to the pressure: someone (ED09 or HD13 first) keeps watching the
	# quiet side; without either habit the whole squad turns to the noise
	var watcher = null
	# an HD16 reserve already watches from the depth of the room
	for m0 in al:
		if m0.ticker.get("reserve", false) and m0.has("HD16"):
			watcher = m0
	if watcher == null and al.size() >= 3:
		for m in al:
			if m.has("HD13") or m.has("ED09"):
				watcher = m
				break
	var taken: Array = []
	if watcher != null:
		taken.append(watcher.spawn)
	for m in al:
		if m == watcher or not w.visible_enemies(m).is_empty():
			continue
		if m.ticker.get("reserve", false) and m.has("HD16"):
			continue
		var post: Dictionary = _hold_post(hr, m, op, taken)
		if post.is_empty():
			var posts: Array = w.level.cover_posts(hr, 1, taken, w.nav, op)
			if posts.is_empty():
				continue
			post = posts[0]
		m.spawn = post["p"]
		m.spawn_face = post["face"]
		m.ticker["post_op"] = op
		m.ticker["post_kind"] = op.get("kind", "")
		taken.append(m.spawn)
	el["sector_posture"] = ""
	var what: String = "door" if op["kind"] == "door" else "window"
	var where: String = ""
	if op["kind"] == "door":
		where = " to outside" if w.level.is_exterior(op["other"]) else " to the " + w.level.rooms[op["other"]]["title"].to_lower()
	w.say("%s hears %s: covers the %s %s%s" % [_tag(tm, el), _sound_name(kind), w.level.rooms[hr]["title"].to_lower(), what, where], "comms")


## Travelling across the city as a squad: the leader heads for the destination, the rest
## follow in a loose file behind. The director watches for arrival.
func _task_transit(o, el: Dictionary) -> void:
	var al := _alive(el)
	al.sort_custom(func(a, b): return a.eslot < b.eslot)
	var k := al.find(o)
	var dv = el.get("dest", w.teams[o.team].get("dest", null))
	if dv == null:
		w.stop(o)
		return
	var dest: Vector2 = dv
	o.dbg = "moving"
	if k <= 0:
		if w.at(o, dest, 2.0):
			w.stop(o)
			if not el.has("arrived_t"):
				el["arrived_t"] = w.t
			return
		_go(o, dest, el.get("pace", w.teams[o.team].get("pace", "run")), false)
		return
	var lead = al[0]
	var gap := 1.6 * k
	if lead.pos.distance_to(o.pos) < gap and lead.pos.distance_to(dest) > 2.5:
		w.stop(o)
		return
	var key := str(dest.snapped(Vector2(1, 1)))
	if o.ticker.get("form_key", "") != key:
		o.ticker["form_key"] = key
		var off := Vector2.from_angle(TAU * k / maxf(1.0, al.size())) * 1.3
		o.ticker["form_p"] = w.nav.snap(dest + off)
	var fp: Vector2 = o.ticker["form_p"]
	if w.at(o, fp, 0.8):
		w.stop(o)
	else:
		_go(o, fp, el.get("pace", "run"), false)


# ================================================================== orders (v0.7)
## A squad's objectives run in order: Clear (the building or listed rooms), Arrest (a
## named suspect), Rescue (hostages), Contain (posts outside listed doors and windows),
## Post (a point, for the event) and Patrol (a route). Constraints shape how: Avoid,
## Consolidate, Phase line, Entry point, Pace, Weapons tight, Knock, Pistols only.
func _begin_objective(tm: Dictionary, el: Dictionary) -> void:
	var od: Dictionary = el.get("orders", {})
	var objs: Array = od.get("objs", [])
	if _alive(el).is_empty():
		el["mode"] = "lost"
		return
	# a phase line holds the squad where it starts until its condition is met
	if int(el.get("obj_i", 0)) == 0 and not od.get("phase", {}).is_empty() and not el.get("phase_ok", false):
		el["mode"] = "wait"
		for m in el["members"]:
			m.alert_floor = Op.YELLOW
			if m.alive() and m.alert < Op.YELLOW:
				w.raise_alert(m, Op.YELLOW)
		return
	if int(el.get("obj_i", 0)) >= objs.size():
		el["obj"] = {}
		_orders_done(tm, el)
		return
	var ob: Dictionary = objs[el["obj_i"]]
	el["obj"] = ob
	el["obj_t"] = w.t
	el.erase("holding_for")
	el.erase("rooms_said")
	match ob.get("kind", "clear"):
		"clear", "arrest", "rescue":
			el["allowed"] = _allowed_rooms(el, ob.get("rooms", []))
			if ob.get("kind", "") == "arrest":
				for m in el["members"]:
					m.ticker["arrest_tid"] = ob.get("target", "")
			_set_mode(tm, el, "assault")
		"contain", "post":
			_set_posts(tm, el, ob.get("posts", []))
		"patrol":
			el["patrol"] = ob.get("route", [])
			_set_mode(tm, el, "hunt")
		_:
			_orders_done(tm, el)


## Rooms a Clear objective may enter: the listed rooms and the rooms on the way to them
## from outside (fewest doors, never through an avoided room). Empty: the whole building.
func _allowed_rooms(el: Dictionary, rooms: Array) -> Dictionary:
	var out := {}
	if rooms.is_empty():
		return out
	var lv = w.level
	var avoid: Array = el.get("orders", {}).get("avoid", [])
	# breadth-first from outside over the room graph
	var prev := {"OUT": ""}
	var queue: Array = ["OUT"]
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for did in lv.adj.get(cur, []):
			var D: Dictionary = lv.doors[did]
			for nb in [D["a"], D["b"]]:
				var key: String = "OUT" if lv.is_exterior(nb) else nb
				if prev.has(key) or avoid.has(key):
					continue
				prev[key] = cur
				queue.append(key)
	for rm in rooms:
		out[rm] = true
		var c: String = prev.get(rm, "")
		while c != "" and c != "OUT":
			out[c] = true
			c = prev.get(c, "")
	return out


## Contain and Post: each member takes the post planned for them, facing their sector.
## floor: the alert they will not relax below (-1 leaves it as it is).
func _set_posts(tm: Dictionary, el: Dictionary, posts: Array, floor := Op.YELLOW) -> void:
	_release(tm, el)
	_release_hold(tm, el)
	el["task"] = {}
	el["mode"] = "hold"
	el["hold_room"] = ""
	el["posted"] = true
	el["sector_posture"] = ""
	_hold_on(el)
	var al := _alive(el)
	for k in al.size():
		var m = al[k]
		w.wake(m)
		if floor >= 0:
			m.alert_floor = floor
			if m.alert < floor:
				w.raise_alert(m, floor)
		if not posts.is_empty():
			var p: Dictionary = posts[k % posts.size()]
			m.spawn = p["p"] + (Vector2(0.9, 0).rotated(k * 2.4) if k >= posts.size() else Vector2.ZERO)
			m.spawn = w.nav.snap(m.spawn)
			m.spawn_face = float(p["face"])


## The squad stays where it stands, each member facing where they look.
func _hold_here(tm: Dictionary, el: Dictionary) -> void:
	var posts: Array = []
	for m in _alive(el):
		posts.append({"p": m.pos, "face": m.look_dir})
	_set_posts(tm, el, posts)


func _objective_done(tm: Dictionary, el: Dictionary, ok: bool, why: String) -> void:
	var ob: Dictionary = el.get("obj", {})
	var kind: String = ob.get("kind", "")
	# an Arrest or Rescue squad that has run out of rooms holds until its target resolves
	if kind in ["arrest", "rescue"] and why in ["rooms clear", "rooms out of reach"]:
		if not el.get("holding_for", false):
			el["holding_for"] = true
			el["holding_t"] = w.t
			_hold_here(tm, el)
		return
	if el.get("obj_closed_" + str(el.get("obj_i", 0)), false):
		return
	el["obj_closed_" + str(el.get("obj_i", 0))] = true
	el["results"].append({"kind": kind, "ok": ok, "why": why, "t": w.t})
	if int(el.get("obj_i", 0)) == 0:
		el["first_done"] = true
	for m in el["members"]:
		m.ticker.erase("arrest_tid")
	w.mark("%s: %s %s (%s)" % [_tag(tm, el), kind, "done" if ok else "failed", why], "objective")
	el["obj_i"] = int(el.get("obj_i", 0)) + 1
	el.erase("allowed")
	_begin_objective(tm, el)


## No objectives left: hold where they are.
func _orders_done(tm: Dictionary, el: Dictionary) -> void:
	if el.get("all_done", false):
		return
	el["all_done"] = true
	_hold_here(tm, el)
	w.say("%s holds: orders complete" % _tag(tm, el), "info")


func _phase_ok(tm: Dictionary, el: Dictionary) -> bool:
	var ph: Dictionary = el["orders"].get("phase", {})
	match ph.get("kind", ""):
		"time":
			return w.t >= float(ph.get("t", 0.0))
		"squad":
			var k: int = int(ph.get("squad", 0))
			if k < 0 or k >= tm["elements"].size() or k == el["i"]:
				return true
			var other: Dictionary = tm["elements"][k]
			return other.get("first_done", false) or _alive(other).is_empty()
	return true


## Every ten ticks per squad: phase lines, consolidation, and whether the objective in
## hand has been met or has failed.
func _orders_tick(tm: Dictionary, el: Dictionary) -> void:
	if el["mode"] == "withdraw":
		return
	if el["mode"] == "wait":
		if _phase_ok(tm, el):
			el["phase_ok"] = true
			w.say("%s crosses the phase line" % _tag(tm, el), "info")
			w.mark("%s crossed its phase line" % _tag(tm, el), "order")
			_begin_objective(tm, el)
		return
	if el.get("consolidating", false):
		var quiet := true
		var rusher = null
		for m in _alive(el):
			if not w.visible_enemies(m).is_empty():
				quiet = false
			if m.hb("BH11") and rusher == null:
				rusher = m
		quiet = quiet and w.t - float(tm["last_contact"]) > 6.0
		var held: float = w.t - float(el["consol_t"])
		if (held >= 20.0 and quiet) or (rusher != null and held > 3.0) or held > 90.0:
			if rusher != null and held < 20.0:
				w.order_broken(rusher, "consolidate", "rushes on before the room is held")
			el["consolidating"] = false
			el.erase("fixed_room")
			_set_mode(tm, el, "assault")
		return
	var ob: Dictionary = el.get("obj", {})
	match ob.get("kind", ""):
		"contain", "post":
			# a standing order: "in position" once everyone has reached their post (other
			# squads' phase lines can wait for this)
			if not el.get("first_done", false):
				var all_in := true
				for m in _alive(el):
					if m.pos.distance_to(m.spawn) > 1.2:
						all_in = false
				if all_in or w.t - float(el.get("obj_t", 0.0)) > 60.0:
					el["first_done"] = true
					w.say("%s in position" % _tag(tm, el), "comms")
					w.mark("%s in position" % _tag(tm, el), "order")
		"clear":
			var rooms: Array = ob.get("rooms", [])
			if not rooms.is_empty():
				var all := true
				for rm in rooms:
					if not tm["cleared"].has(rm) and not tm["skipped"].has(rm):
						all = false
				if all:
					_objective_done(tm, el, true, "rooms clear")
		"arrest":
			var tg = w.by_id.get(ob.get("target", ""), null)
			if tg == null:
				_objective_done(tm, el, false, "no such suspect")
			elif tg.arrested:
				_objective_done(tm, el, true, "%s in cuffs" % tg.id)
			elif tg.gone:
				_objective_done(tm, el, false, "%s escaped" % tg.id)
			elif not tg.alive():
				_objective_done(tm, el, false, "%s %s" % [tg.id, "killed" if tg.state == "dead" else "down"])
			elif el.get("holding_for", false) and w.t - float(el["holding_t"]) > 120.0 and not tg.complying:
				_objective_done(tm, el, false, "%s not found" % tg.id)
		"rescue":
			var left := 0
			var lost := 0
			for h in w.ops:
				if not h.hostage:
					continue
				if not h.alive():
					lost += 1
				elif h.cstate != "safe":
					left += 1
					if h.cstate in ["hostage", "freed"] and h.ticker.get("free_ok", false):
						rescuer_for(h)
			if left == 0:
				_objective_done(tm, el, lost == 0, "hostages out" if lost == 0 else "%d hostage%s lost" % [lost, "" if lost == 1 else "s"])


## When the operation ends: settle every squad's objective in hand (the last checks may
## not have run). Standing orders (Contain, Post, Patrol) count as held if anyone stands;
## a squad still at its phase line is judged on its first objective, whoever met it.
func close_orders() -> void:
	if w.teams.is_empty():
		return
	var tm: Dictionary = w.teams[0]
	for el in tm["elements"]:
		if not el.has("orders"):
			continue
		var objs: Array = el["orders"].get("objs", [])
		if el["mode"] == "wait":
			if not objs.is_empty():
				var v0: Dictionary = _settle(tm, el, objs[0])
				el["results"].append({"kind": objs[0].get("kind", ""), "ok": v0["ok"], "why": v0["why"] + "; the squad never crossed its phase line", "t": w.t})
			continue
		var closed: bool = el.get("obj_closed_" + str(el.get("obj_i", 0)), false)
		if el["mode"] == "withdraw":
			var ob1: Dictionary = el.get("obj", {})
			if ob1.is_empty() and int(el.get("obj_i", 0)) < objs.size():
				ob1 = objs[int(el.get("obj_i", 0))]
			if not ob1.is_empty() and not closed:
				el["results"].append({"kind": ob1.get("kind", ""), "ok": false, "why": "withdrawn on the abort", "t": w.t})
			continue
		_orders_tick(tm, el)
		var ob: Dictionary = el.get("obj", {})
		if ob.is_empty() or el.get("obj_closed_" + str(el.get("obj_i", 0)), false):
			continue
		var v: Dictionary = _settle(tm, el, ob)
		el["results"].append({"kind": ob.get("kind", ""), "ok": v["ok"], "why": v["why"], "t": w.t})


## The verdict on one objective as things stand.
func _settle(tm: Dictionary, el: Dictionary, ob: Dictionary) -> Dictionary:
	var standing: bool = not _alive(el).is_empty()
	match ob.get("kind", ""):
		"contain", "post", "patrol":
			return {"ok": standing, "why": "held to the end" if standing else "squad lost"}
		"clear":
			var left := 0
			for rm in ob.get("rooms", []):
				if not tm["cleared"].has(rm) and not tm["skipped"].has(rm):
					left += 1
			if left == 0:
				if not standing:
					return {"ok": false, "why": "squad lost (the rooms were cleared by others)"}
				return {"ok": true, "why": "rooms clear"}
			return {"ok": false, "why": "%d room%s not cleared" % [left, "" if left == 1 else "s"]}
		"arrest":
			var tg = w.by_id.get(ob.get("target", ""), null)
			if tg == null:
				return {"ok": false, "why": "no such suspect"}
			if tg.arrested:
				return {"ok": true, "why": "%s in cuffs" % tg.id}
			if tg.gone:
				return {"ok": false, "why": "%s escaped" % tg.id}
			if not tg.alive():
				return {"ok": false, "why": "%s %s" % [tg.id, "killed" if tg.state == "dead" else "down"]}
			return {"ok": false, "why": "%s still at large" % tg.id}
		"rescue":
			var left2 := 0
			var lost := 0
			for h in w.ops:
				if h.hostage:
					if not h.alive():
						lost += 1
					elif h.cstate != "safe":
						left2 += 1
			if left2 == 0 and lost == 0:
				return {"ok": true, "why": "hostages out"}
			return {"ok": false, "why": "%d still inside, %d lost" % [left2, lost]}
	return {"ok": standing, "why": "ended"}


## When every squad sent to search (Clear, Arrest, Rescue) has finished its objectives
## or has nobody left standing: the latest time one finished. -1 while any is still at
## it, or when no squad was sent to search at all.
func searches_done_t() -> float:
	if w.teams.is_empty():
		return -1.0
	var latest := -1.0
	var any := false
	for el in w.teams[0]["elements"]:
		if not el.has("orders"):
			continue
		var objs: Array = el["orders"].get("objs", [])
		var searching := false
		for ob in objs:
			if ob.get("kind", "") in ["clear", "arrest", "rescue"]:
				searching = true
		if not searching:
			continue
		any = true
		if _alive(el).is_empty():
			continue
		if int(el.get("obj_i", 0)) < objs.size() and not el.get("obj_closed_" + str(el.get("obj_i", 0)), false):
			var cur: String = el.get("obj", {}).get("kind", "")
			if cur in ["clear", "arrest", "rescue"] or el["mode"] == "wait":
				return -1.0
		for r in el.get("results", []):
			latest = maxf(latest, float(r["t"]))
	return latest if any else -1.0


## The nearest free member of a Rescue squad walks a freed hostage out. Returns the
## officer, or null when no Rescue squad has anyone free.
func rescuer_for(h):
	if h.ticker.has("escort_by"):
		var cur = w.by_id.get(h.ticker["escort_by"], null)
		if cur != null and cur.fighting() and cur.ticker.get("escort", "") == h.id:
			return cur
	var tm: Dictionary = w.teams[0]
	var best = null
	var bd := INF
	for el in tm["elements"]:
		if el.get("obj", {}).get("kind", "") != "rescue" or el["mode"] == "withdraw":
			continue
		for m in _alive(el):
			if m.ticker.has("escort") or not m.fighting():
				continue
			var d: float = m.pos.distance_to(h.pos)
			if d < bd:
				bd = d
				best = m
	if best != null:
		best.ticker["escort"] = h.id
		h.ticker["escort_by"] = best.id
	return best


## Walking a hostage out: stay a metre behind them; done when they reach safety.
func _task_escort(o) -> bool:
	var h = w.by_id.get(o.ticker["escort"], null)
	if h == null or not h.alive() or h.cstate == "safe" or not h.hostage:
		o.ticker.erase("escort")
		return false
	if h.cstate == "hostage":
		# go and get them
		o.dbg = "going to the hostage"
		if not w.at(o, h.pos, 1.2):
			_go(o, h.pos, "clear" if w.level.is_inside(o.pos) else "walk", false)
		else:
			w.stop(o)
		return true
	o.dbg = "escorting %s" % h.id
	var cp: Vector2 = w.casualty_point
	var behind: Vector2 = h.pos - (cp - h.pos).normalized() * 1.0
	if o.pos.distance_to(behind) > 0.6:
		_go(o, behind, "walk", false)
	else:
		w.stop(o)
	return true


## Abort: every squad withdraws to its vehicles, at a run, fighting only if fired on.
func withdraw(tm: Dictionary) -> void:
	for el in tm["elements"]:
		_release(tm, el)
		_release_hold(tm, el)
		el["task"] = {}
		el["consolidating"] = false
		el["mode"] = "withdraw"
		var v: Vector2 = _centre(el["members"]) if not el["members"].is_empty() else Vector2.ZERO
		if el["i"] < w.vehicles.size():
			v = w.vehicles[el["i"]]
		el["veh"] = v
		for m in el["members"]:
			m.ticker.erase("escort")
			m.ticker.erase("arrest_tid")
			m.pace_cap = ""
			w.wake(m)


func _task_withdraw(o, el: Dictionary) -> void:
	var v: Vector2 = el.get("veh", o.spawn)
	var spot: Vector2 = w.nav.snap(v + Vector2(1.1, 0).rotated(o.eslot * 1.3) * (0.0 if o.eslot == 0 else 1.0))
	o.dbg = "withdrawing to the vehicles"
	if o.pos.distance_to(spot) < 1.6:
		w.leave(o, "withdrew")
		return
	_go(o, spot, "run", false)


## The attack at an event: the attackers go hunting through the crowd.
func attack(tm: Dictionary, crowd: Array) -> void:
	tm["stay"] = true
	for el in tm["elements"]:
		var route: Array = crowd.duplicate()
		if route.is_empty():
			route = w.level.patrol.duplicate()
		el["patrol"] = route
		_set_mode(tm, el, "hunt")



# ================================================================== hold-mode habits (v0.7)
## HD01-HD20 and BH21-BH27 work only while the squad holds (defending a room, or police
## on a Post or Contain order). Switch them on for the squad now, before posts are picked.
func _hold_on(el: Dictionary) -> void:
	for m in el["members"]:
		if m.alive() and not m.holding:
			m.holding = true
			if not m.civ:
				w._update_bad(m, false)


## Does this member pick a post of their own rather than keep the one they stand on?
func _picky(m) -> bool:
	for g in ["HD02", "HD03", "HD05", "HD07", "HD10"]:
		if m.has(g):
			return true
	return m.bad.get("BH22", false) or m.bad.get("BH27", false)


## A post covering one opening (or, outdoors, a spot near the current post), chosen by the
## member's hold habits:
##   HD02 depth (2.5-4 m back, off the axis; without it close to the opening, near the axis)
##   HD05 windows from 2.6 m back, kneeling   HD07 see the lane 1.5 m inside the door too
##   HD10 30-55 deg off the door's axis       HD03 cross a teammate's line by 35 deg or more
##   BH22 stands at the window                BH27 stands in the middle of the room
func _hold_post(room: String, m, op: Dictionary, taken: Array, away_from := Vector2.INF) -> Dictionary:
	var lv = w.level
	var kind: String = op.get("kind", "")
	var deep: bool = m.has("HD02")
	var win := kind == "window"
	var target_d := 3.2 if deep else 1.6
	if win and m.has("HD05"):
		target_d = maxf(target_d, 2.6)
	if win and m.hb("BH22"):
		target_d = 0.8
	var c: Vector2 = op.get("c", m.spawn)
	var n_in: Vector2 = op.get("n_in", Vector2.ZERO)
	var lane: bool = kind == "door" and m.has("HD07")
	var aim: Vector2 = c + n_in * (hd07_lane if lane else 0.25)
	var indoor: bool = room != "" and lv.rooms.has(room) and not lv.is_exterior(room)
	if m.hb("BH27") and indoor:
		var lp: Vector2 = w.nav.snap(lv.rooms[room]["label"])
		return {"p": lp, "face": (c - lp).angle()}
	var mates: Array = []
	if m.el >= 0:
		for x in _alive(_el(m)):
			if x != m and (x.ticker.get("post_op", {}) as Dictionary).get("c", Vector2.INF) == c:
				mates.append(x.spawn)
	var cands: Array = []
	if indoor:
		var step := 0.5 if lv.room_area(room) < 100.0 else 1.0
		for rv in lv.rooms[room]["rects"]:
			var r: Rect2 = rv
			var x := r.position.x + 0.45
			while x <= r.end.x - 0.4:
				var y := r.position.y + 0.45
				while y <= r.end.y - 0.4:
					cands.append(Vector2(x, y))
					y += step
				x += step
	else:
		var ctr: Vector2 = m.spawn
		for ring in [1.5, 2.25, 3.0]:
			for k in 12:
				cands.append(ctr + Vector2.from_angle(TAU * k / 12.0) * ring)
	var room_doors: Array = []
	if indoor:
		for did in lv.adj.get(room, []):
			room_doors.append(lv.doors[did]["c"])
	var best = null
	var best_s := -INF
	for p in cands:
		if not w.nav.reachable(p):
			continue
		if indoor and lv.room_at(p) != room:
			continue
		if away_from != Vector2.INF and p.distance_to(away_from) < 1.5:
			continue
		var bad := false
		for dc in room_doors:
			if (dc as Vector2).distance_to(p) < 1.0:
				bad = true
				break
		if bad:
			continue
		for q in taken:
			if (q as Vector2).distance_to(p) < 1.2:
				bad = true
				break
		if bad:
			continue
		var s := 0.0
		if indoor or kind != "":
			var v: Vector2 = p - c
			var dist := v.length()
			s -= absf(dist - target_d)
			if n_in != Vector2.ZERO:
				var ang := absf(v.angle_to(n_in))
				if deep:
					s += 1.0 if (ang > 0.35 and ang < 1.2) else 0.0
				else:
					s += 0.6 if ang < 0.4 else 0.0
				if kind == "door" and m.has("HD10"):
					s += hd10_bonus if (ang > hd10_lo and ang < hd10_hi) else 0.0
			if m.has("HD03") and not mates.is_empty():
				var crossed := false
				for q2 in mates:
					var cross := absf((p - c).angle_to((q2 as Vector2) - c))
					if cross >= 0.61:
						crossed = true
					elif cross < 0.35:
						s -= 0.8
				if crossed:
					s += 1.2
		else:
			s -= absf(p.distance_to(m.spawn) - 2.0)
		if not w.geom.sight_clear(p, 1.1, aim, 1.0):
			continue
		if lane and hd07_door_too and not w.geom.sight_clear(p, 1.1, c, 1.0):
			continue
		if lane and hd07_hidden > 0.0 and w.geom.sight_clear(p, 1.1, c - n_in * 4.0, 1.6):
			s -= hd07_hidden
		if w.geom.dist_to_kinds(p, [Geom.COVER, Geom.WALL], 1.0) < 0.75:
			s += 0.6
		if s > best_s:
			best_s = s
			best = p
	if best == null:
		return {}
	return {"p": best, "face": ((c if (lane and hd07_face_door) else aim) - best).angle()}


## HD16: the reserve stands back in the depth of the room, facing its main door.
func _reserve_post(el: Dictionary, m, taken: Array) -> void:
	var lv = w.level
	var room: String = el.get("hold_room", "")
	if room == "" or not lv.rooms.has(room):
		return
	var ops: Array = lv.room_openings(room)
	# the main door: the one closest to where the attack will come from (the stage)
	var main_op = null
	for op0 in ops:
		if op0["kind"] == "door" and (main_op == null or (op0["c"] as Vector2).distance_to(lv.stage_centre()) < (main_op["c"] as Vector2).distance_to(lv.stage_centre())):
			main_op = op0
	var best = null
	var best_s := -INF
	for rv in lv.rooms[room]["rects"]:
		var r: Rect2 = rv
		var x := r.position.x + 0.5
		while x <= r.end.x - 0.45:
			var y := r.position.y + 0.5
			while y <= r.end.y - 0.45:
				var p := Vector2(x, y)
				y += 0.5
				if not w.nav.reachable(p) or lv.room_at(p) != room:
					continue
				var ok := true
				for q in taken:
					if (q as Vector2).distance_to(p) < 1.2:
						ok = false
				if not ok:
					continue
				var dmin := 99.0
				for op in ops:
					dmin = minf(dmin, (op["c"] as Vector2).distance_to(p))
				# deep, but still able to shoot at the room's main door
				var sc := dmin
				if main_op != null and w.geom.sight_clear(p, 1.1, main_op["c"] + main_op["n_in"] * 0.5, 1.0):
					sc += 4.0
				if sc > best_s:
					best_s = sc
					best = p
			x += 0.5
	if best == null:
		return
	m.spawn = best
	m.spawn_face = ((main_op["c"] as Vector2) - best).angle() if main_op != null else m.spawn_face
	m.ticker["reserve"] = true
	m.ticker["post_op"] = {}
	m.ticker["post_kind"] = ""


## The room a holder defends: the squad's hold room, or the room they stand in.
func _hold_room(o) -> String:
	var el := _el(o)
	var hr: String = el.get("hold_room", "")
	if hr == "" and not w.level.is_exterior(o.room):
		hr = o.room
	return hr


## A visible enemy within 1.8 m of a door of the holder's room (HD09), or null.
func _at_room_door(o):
	var hr := _hold_room(o)
	if hr == "":
		return null
	var best = null
	var bd := INF
	for e in w.visible_enemies(o):
		if o.pos.distance_to(e.pos) > 12.0:
			continue
		for did in w.level.adj.get(hr, []):
			var d: float = (w.level.doors[did]["c"] as Vector2).distance_to(e.pos)
			if d < 1.8 and d < bd:
				bd = d
				best = e
	return best


## HD08: is it time to open up on this enemy?
func _funnel_ready(o, e) -> bool:
	var el := _el(o)
	if w.t - float(el.get("initiated_t", -99.0)) < 10.0 or w.attacking(e, o) or w.t - o.last_stress_t < 2.0:
		return true
	var hr := _hold_room(o)
	if hr == "":
		return true
	if e.room == hr:
		return true
	for op in w.level.room_openings(hr):
		if (op["c"] as Vector2).distance_to(e.pos) < 2.5:
			return true
	return false


## BH24: the door of the room the starer keeps their eyes on (nearest the last contact).
func _stare_door(o):
	var hr := _hold_room(o)
	if hr == "":
		return null
	var ref: Vector2 = o.pos
	var lk = _latest_lkp(o)
	if lk != null:
		ref = lk["p"]
	var best = null
	var bd := INF
	for did in w.level.adj.get(hr, []):
		var c: Vector2 = w.level.doors[did]["c"]
		if c.distance_to(ref) < bd:
			bd = c.distance_to(ref)
			best = c
	return best


## Seen by a holder (world calls this on recognition): HD17 turns the squad's eyes at the
## first sighting; HD18 calls an enemy at a door of the room.
func hold_sighting(o, e) -> void:
	if o.el < 0 or not e.alive():
		return
	var el := _el(o)
	if o.has("HD17") and w.t > float(el.get("standto_t", -99.0)) + 10.0:
		el["standto_t"] = w.t
		for m in _el_mates(o):
			w.raise_alert(m, Op.YELLOW)
			var dir: float = (e.pos - m.pos).angle()
			if w.visible_enemies(m).is_empty() and w.in_sector(m, dir):
				m.look_hint = {"dir": dir, "start": w.t + 0.2, "until": w.t + 2.0, "why": "stand-to"}
	if o.has("HD18"):
		var hr := _hold_room(o)
		if hr == "":
			return
		var at_door := false
		for did in w.level.adj.get(hr, []):
			if (w.level.doors[did]["c"] as Vector2).distance_to(e.pos) < 2.5:
				at_door = true
		if at_door and w.t - float(o.ticker.get("breach_call", -99.0)) > 4.0:
			o.ticker["breach_call"] = w.t
			w.say("%s: breach! %s at the door" % [o.id, e.id], "comms")
			for m2 in _el_mates(o):
				m2.cue[e.id] = w.t + 3.0
				if w.visible_enemies(m2).is_empty():
					m2.look_hint = {"dir": (e.pos - m2.pos).angle(), "start": w.t + 0.2, "until": w.t + 2.0, "why": "breach"}


## Per member, ahead of returning to the post: a counterattack (HD12), a drag (HD19), a
## hop to an alternate post (HD01, HD04), a top-up from the cache (HD20). True when one
## of them took the tick.
func _hold_extras(o) -> bool:
	var el := _el(o)
	# HD12: rush the foothold
	if o.ticker.get("counter_until", -1.0) > w.t:
		var cp: Vector2 = o.ticker["counter_p"]
		if o.pos.distance_to(cp) > 1.2:
			o.dbg = "counterattacking the foothold"
			w.move_to(o, cp, "sprint")
			return true
	# HD19: drag a downed teammate out of the lane
	if o.ticker.has("drag"):
		var cas = w.by_id.get(o.ticker["drag"], null)
		var to: Vector2 = o.ticker.get("drag_to", o.pos)
		if cas == null or cas.state == "ok" or cas.mounted != null or not w.visible_enemies(o).is_empty():
			o.ticker.erase("drag")
		elif o.pos.distance_to(cas.pos) > 0.9 and not o.ticker.get("dragging", false):
			o.dbg = "going to drag " + cas.id
			_go(o, cas.pos, "run", false)
			return true
		else:
			o.ticker["dragging"] = true
			o.dbg = "dragging " + cas.id
			if o.pos.distance_to(to) < 0.4:
				o.ticker.erase("drag")
				o.ticker.erase("dragging")
				w.say("%s drags %s out of the lane" % [o.id, cas.id], "info")
				return false
			w.move_to(o, to, "creep")
			cas.pos = o.pos - (to - o.pos).normalized() * 0.6
			cas.room = w.level.room_at(cas.pos)
			return true
	# HD01 / HD04: hop to an alternate post
	if (o.has("HD01") or o.has("HD04")) and w.t > float(o.ticker.get("hop_next", 0.0)) and not o.ticker.get("reserve", false):
		var why := ""
		if o.has("HD01") and w.t - float(o.ticker.get("near_t", -9.0)) < 1.0 and w.t - o.last_stress_t < 1.0:
			why = "suppressed"
		elif o.has("HD01") and _flanked(o):
			why = "flanked"
		elif o.has("HD04") and w.t - o.last_shot_t < 1.5 and w.visible_enemies(o).is_empty() \
				and float(o.ticker.get("hop_shot", -1.0)) != o.last_shot_t:
			o.ticker["hop_shot"] = o.last_shot_t
			why = "off the spot it fired from"
		if why != "":
			o.ticker["hop_next"] = w.t + 6.0
			_hop(o, el, why)
	# HD20: top up from the cache between contacts
	if o.has("HD20") and o.action.is_empty() and o.pos.distance_to(o.spawn) < 0.8 and int(o.ticker.get("cache_used", 0)) < 2 \
			and w.t - o.last_enemy_seen_t > 5.0 and w.t - o.last_stress_t > 5.0:
		for wn in [o.active, o.other()]:
			var ws: Dictionary = o.weapons[wn]
			if ws["lost"] or ws.get("none", false):
				continue
			if int(ws["spare"]) < int(Habits.WEAPONS[wn]["spare"]):
				o.ticker["cache_used"] = int(o.ticker.get("cache_used", 0)) + 1
				w.start_action(o, "restock", 2.0, {"w": wn})
				return true
	return false


func _flanked(o) -> bool:
	for e in w.visible_enemies(o):
		if absf(angle_difference(o.spawn_face, (e.pos - o.pos).angle())) > deg_to_rad(100.0):
			return true
	return false


func _hop(o, el: Dictionary, why: String) -> void:
	var room := _hold_room(o)
	var op: Dictionary = o.ticker.get("post_op", {})
	if op.is_empty():
		op = {"c": o.pos + Vector2.from_angle(o.spawn_face) * 4.0, "n_in": -Vector2.from_angle(o.spawn_face), "kind": "point"}
	var taken: Array = []
	for x in _alive(el):
		if x != o:
			taken.append(x.spawn)
	var post := _hold_post(room if not el.get("posted", false) else "", o, op, taken, o.spawn)
	if post.is_empty():
		return
	o.spawn = post["p"]
	o.spawn_face = post["face"]
	w.say("%s moves to an alternate post (%s)" % [o.id, why], "info")


## Per squad, every half second while holding: stand-to (HD17), who has opened fire
## (HD08), counterattack (HD12), drags (HD19), and whether to give up the room (HD15,
## peeling back with HD14).
func _hold_tick(tm: Dictionary, el: Dictionary, al: Array) -> void:
	var lv = w.level
	var room: String = el.get("hold_room", "")
	for m in al:
		if m.has("HD17") and m.alert_floor < Op.YELLOW:
			m.alert_floor = Op.YELLOW
			if m.alert < Op.YELLOW:
				w.raise_alert(m, Op.YELLOW)
		if w.t - m.last_shot_t < 0.6:
			el["initiated_t"] = w.t
	if el.get("peel_until", -1.0) > w.t and w.t - float(el.get("peel_flip", -99.0)) > 2.0:
		el["peel_flip"] = w.t
		el["peel_half"] = 1 - int(el.get("peel_half", 0))
	if room == "":
		return
	# HD12: an enemy inside the room is rushed by the nearest pair
	if w.t > float(el.get("counter_t", -99.0)) + 8.0:
		var intruder = null
		for m in al:
			for e in w.visible_enemies(m):
				if e.room == room:
					intruder = e
		if intruder != null:
			var cands: Array = al.filter(func(x): return x.has("HD12") and x.action.is_empty())
			cands.sort_custom(func(a, b):
				var ra: int = 0 if a.ticker.get("reserve", false) else 1
				var rb: int = 0 if b.ticker.get("reserve", false) else 1
				if ra != rb:
					return ra < rb
				return a.pos.distance_to(intruder.pos) < b.pos.distance_to(intruder.pos))
			var n := 0
			for c in cands:
				if n >= 2:
					break
				c.ticker["counter_until"] = w.t + 4.0
				c.ticker["counter_p"] = intruder.pos
				n += 1
			if n > 0:
				el["counter_t"] = w.t
				w.say("%s counterattacks %s in the %s" % [_tag(tm, el), intruder.id, lv.rooms[room]["title"].to_lower()], "info")
	# HD19: drag a downed teammate once the doorway has been quiet for a second
	var quiet := true
	for m2 in al:
		if not w.visible_enemies(m2).is_empty():
			quiet = false
	if quiet:
		el["quiet_since"] = el.get("quiet_since", w.t)
	else:
		el.erase("quiet_since")
	if quiet and w.t - float(el.get("quiet_since", w.t)) >= 1.0:
		for x in el["members"]:
			if x.state != "down" or x.ticker.get("dragged", false) or x.pos.distance_to(lv.rooms[room]["label"]) > 12.0:
				continue
			var best = null
			for m3 in al:
				if m3.has("HD19") and m3.action.is_empty() and not m3.ticker.has("drag") and (best == null or m3.pos.distance_to(x.pos) < best.pos.distance_to(x.pos)):
					best = m3
			if best == null:
				continue
			var near_c: Vector2 = x.pos
			var bd := INF
			for op in lv.room_openings(room):
				if (op["c"] as Vector2).distance_to(x.pos) < bd:
					bd = (op["c"] as Vector2).distance_to(x.pos)
					near_c = op["c"]
			var dir: Vector2 = (x.pos - near_c).normalized() if bd < INF and bd > 0.01 else Vector2.RIGHT
			var to: Vector2 = w.nav.snap(x.pos + dir * 2.5)
			if lv.room_at(to) != room:
				to = w.nav.snap(lv.rooms[room]["label"])
			best.ticker["drag"] = x.id
			best.ticker["drag_to"] = to
			x.ticker["dragged"] = true
	# HD15: give up the room when it cannot be held
	if w.t < float(el.get("fallback_t", -99.0)) + 30.0:
		return
	var has15 := false
	for m4 in al:
		if m4.has("HD15"):
			has15 = true
	if not has15:
		return
	var n0: int = el["members"].size()
	var dry := 0
	for m5 in al:
		if not m5.any_loaded() and int(m5.weapons["rifle"]["spare"]) + int(m5.weapons["pistol"]["spare"]) == 0:
			dry += 1
	# enemies at the room's openings (within 3 m), by opening; an enemy already inside
	# means running is worse than fighting
	var at_ops := {}
	var inside := false
	var ops: Array = lv.room_openings(room)
	for m6 in al:
		for e2 in w.visible_enemies(m6):
			if e2.room == room:
				inside = true
			for i in ops.size():
				if (ops[i]["c"] as Vector2).distance_to(e2.pos) < 3.0:
					at_ops[i] = true
	if inside or al.size() <= 2:
		return
	for m7 in al:
		if not w.visible_enemies(m7).is_empty() or w.t - m7.last_stress_t < 2.0:
			return
	var why := ""
	if n0 >= 2 and al.size() * 2 <= n0:
		why = "half the squad is down"
	elif dry * 2 > al.size():
		why = "out of ammunition"
	elif at_ops.size() >= 2:
		why = "flanked"
	if why == "":
		return
	var fb := _fallback_room(tm, room)
	if fb == "":
		return
	el["fallback_t"] = w.t
	var stay: Array = al.filter(func(x): return x.hb("BH23"))
	var keep := {}
	for x2 in stay:
		keep[x2.id] = [x2.spawn, x2.spawn_face]
	_release_hold(tm, el)
	el["fixed_room"] = fb
	_consolidate(tm, el)
	el.erase("fixed_room")
	for x3 in stay:
		x3.spawn = keep[x3.id][0]
		x3.spawn_face = keep[x3.id][1]
	el["peel_until"] = w.t + 8.0
	el["peel_flip"] = w.t
	el["peel_half"] = 0
	w.say("%s gives up the %s (%s) and falls back to the %s" % [_tag(tm, el), lv.rooms[room]["title"].to_lower(), why,
		lv.rooms[fb]["title"].to_lower()], "info")


## The next room back: an interior room next door, with no enemy known in it, as far
## from the enemy as possible.
func _fallback_room(tm: Dictionary, room: String) -> String:
	var lv = w.level
	var foes: Array = []
	for eid in tm["lkps"]:
		foes.append(tm["lkps"][eid]["p"])
	var best := ""
	var best_s := -INF
	for did in lv.adj.get(room, []):
		var D: Dictionary = lv.doors[did]
		var other: String = D["a"] if D["b"] == room else D["b"]
		if lv.is_exterior(other) or tm["held"].has(other):
			continue
		var s := 0.0
		var ok := true
		for f in foes:
			# no enemy known in it, and none close to the door the squad must use
			if lv.room_at(f) == other or (f as Vector2).distance_to(D["c"]) < 6.0:
				ok = false
			s += minf((f as Vector2).distance_to(lv.rooms[other]["label"]), 30.0)
		if not ok:
			continue
		if s > best_s:
			best_s = s
			best = other
	return best
