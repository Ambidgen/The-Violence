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
const DT := 1.0 / 30.0

var w
var tick := 0


func _init(world) -> void:
	w = world


# ================================================================== team level
func init_teams() -> void:
	for tm in w.teams:
		_set_posture(tm, tm["posture"])


func _set_posture(tm: Dictionary, p: String) -> void:
	tm["posture"] = p
	if p == "assault":
		_start_assault(tm)
	elif p == "hunt":
		tm["hunt_i"] = 0
		tm["hunt_done_t"] = -1.0


func alive_members(tm: Dictionary) -> Array:
	var out: Array = []
	for m in tm["members"]:
		if m.alive():
			out.append(m)
	return out


func _any_has(tm: Dictionary, gid: String) -> bool:
	for m in alive_members(tm):
		if m.has(gid):
			return true
	return false


func _start_assault(tm: Dictionary) -> void:
	var al := alive_members(tm)
	if al.is_empty():
		return
	var c := Vector2.ZERO
	for m in al:
		c += m.pos
	c /= al.size()
	var key := "front" if c.x < 18.5 else "back"
	tm["plan"] = w.level.plans[key].duplicate(true)
	tm["step"] = 0
	w.say("Team %s assaults through the %s door" % ["AB"[tm["id"]], key], "info")
	_skip_steps(tm)
	if tm["posture"] == "assault":
		_begin_step(tm)


func _skip_steps(tm: Dictionary) -> void:
	while tm["step"] < tm["plan"].size():
		var st: Dictionary = tm["plan"][tm["step"]]
		if st.get("check", false) and not _any_has(tm, "PF10"):
			tm["step"] += 1
			continue
		if tm["cleared"].has(st["into"]):
			tm["step"] += 1
			continue
		break
	if tm["step"] >= tm["plan"].size():
		w.say("Team %s: house clear, hunting" % "AB"[tm["id"]], "info")
		_set_posture(tm, "hunt")


func _advance(tm: Dictionary) -> void:
	tm["step"] += 1
	_skip_steps(tm)
	if tm["posture"] == "assault":
		_begin_step(tm)


func _begin_step(tm: Dictionary) -> void:
	var st: Dictionary = tm["plan"][tm["step"]]
	var lv = w.level
	var D: Dictionary = lv.doors[st["door"]]
	var n_in: Vector2 = lv.inward(st["door"], st["into"])
	var c: Vector2 = D["c"]
	var tdir: Vector2 = D["t"]
	tm["phase"] = "check" if st.get("check", false) else "approach"
	tm["phase_t"] = w.t
	tm["entry"] = {}
	var al := alive_members(tm)
	al.sort_custom(func(a, b): return a.pos.distance_to(c) < b.pos.distance_to(c))
	for i in range(al.size()):
		if al[i].hb("BH11") and i > 0:
			var r = al[i]
			al.remove_at(i)
			al.insert(0, r)
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
	var slots := _stack_slots(c, n_in, side, D["half"], from_room)
	# entry geometry inside the room
	var inside := c + n_in * 0.7
	var ext_p: float = lv.extent_along(inside, tdir)
	var ext_n: float = lv.extent_along(inside, -tdir)
	var s1 := tdir if ext_p >= ext_n else -tdir
	var e1 := maxf(ext_p, ext_n)
	var e2 := minf(ext_p, ext_n)
	var depth: float = lv.extent_along(inside, n_in)
	var cap: int = lv.room_capacity(st["into"])
	for k in range(al.size()):
		var m = al[k]
		var enters: bool = k < cap
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
		var tgt: Array = _entry_target(m, k, c, n_in, inside, s1, e1, e2, depth)
		var my_side: Vector2 = tgt[1]
		d["target"] = _inside_room(w.nav.snap(tgt[0]), st["into"], c, n_in)
		var ext := e1 if my_side == s1 else e2
		d["corner"] = c + n_in * 0.25 + my_side * maxf(ext - 0.25, 0.3)
		tm["entry"][m.id] = d
	if tm["phase"] == "approach":
		var held := al.size() - cap
		w.say("Team %s moves on the %s%s" % ["AB"[tm["id"]], lv.rooms[st["into"]]["title"].to_lower(),
			(" (%d enter, %d hold rear security)" % [cap, held]) if held > 0 else ""], "info")


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
	if from_room == "OUT":
		return rm == "OUT" or rm == "PORCH"
	return rm == from_room


func update_teams() -> void:
	tick += 1
	for tm in w.teams:
		var al := alive_members(tm)
		if al.is_empty():
			continue
		_sectors(tm, al)
		_bounding(tm, al)
		match tm["posture"]:
			"assault":
				_assault_tick(tm, al)
			"hold":
				var quiet: float = w.t - maxf(tm["last_contact"], 0.0)
				if quiet > 60.0:
					w.say("Team %s: no contact for a minute, hunting" % "AB"[tm["id"]], "info")
					_set_posture(tm, "hunt")


## GD02 sector ownership for any team size. Moving teams split the arc around their
## direction of advance (110 deg each for two or three, 360/N for four or five), left to
## right by position. Holders own the arc they were placed facing. After a casualty,
## GD09 members re-sector within 1 s; anyone without GD09 keeps the old arcs, so the
## casualty's arc stays dark.
func _sectors(tm: Dictionary, al: Array) -> void:
	var gd2: Array = []
	for m in al:
		if m.has("GD02"):
			gd2.append(m)
	var key := ""
	for m in gd2:
		key += m.id
	var fwd := _team_forward(tm, al)
	var holding: bool = tm["posture"] == "hold"
	var first: bool = not tm.has("sector_key") or tm.get("sector_posture", "") != tm["posture"]
	if not holding and not first and absf(angle_difference(fwd, tm["sector_fwd"])) > 0.3:
		first = true
	if key == tm.get("sector_key", "") and not first:
		_adopt_sectors(tm)
		return
	var layout := _sector_layout(tm, gd2, fwd)
	if first:
		tm["sectors"] = layout
		tm["sector_pending"] = {}
	else:
		var pend := {}
		if holding:
			for x in tm["members"]:
				if x.alive() or not tm["sectors"].has(x.id):
					continue
				var best = null
				for m in al:
					if m.has("GD09") and m.pos.distance_to(x.pos) < 10.0:
						if best == null or m.pos.distance_to(x.pos) < best.pos.distance_to(x.pos):
							best = m
				if best != null:
					var own: float = tm["sectors"].get(best.id, best.spawn_face)
					pend[best.id] = {"dir": lerp_angle(own, tm["sectors"][x.id], 0.5), "at": w.t + 1.0}
		else:
			for m in al:
				if m.has("GD09"):
					pend[m.id] = {"dir": layout.get(m.id, null), "at": w.t + 1.0}
		tm["sector_pending"] = pend
	for oid in tm["sectors"].keys():
		var x = w.op_by_id(oid)
		if x == null or not x.alive():
			tm["sectors"].erase(oid)
	tm["sector_key"] = key
	tm["sector_fwd"] = fwd
	tm["sector_posture"] = tm["posture"]


func _sector_layout(tm: Dictionary, members: Array, fwd: float) -> Dictionary:
	var out := {}
	var n := members.size()
	if tm["posture"] == "hold":
		for m in members:
			out[m.id] = m.spawn_face
		tm["sector_half"] = deg_to_rad(80.0)
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
	tm["sector_half"] = clampf(spacing / 2.0 + deg_to_rad(15.0), deg_to_rad(50.0), deg_to_rad(80.0))
	for i in n:
		out[sorted[i].id] = fwd + (i - (n - 1) / 2.0) * spacing
	return out


func _adopt_sectors(tm: Dictionary) -> void:
	var pend: Dictionary = tm["sector_pending"]
	for oid in pend.keys():
		var p: Dictionary = pend[oid]
		if w.t < p["at"]:
			continue
		pend.erase(oid)
		var x = w.op_by_id(oid)
		if x == null or not x.alive():
			continue
		if p["dir"] == null:
			tm["sectors"].erase(oid)
		else:
			tm["sectors"][oid] = p["dir"]
		w.say("%s re-sectors after the casualty" % oid, "comms")


func _team_forward(tm: Dictionary, al: Array) -> float:
	if tm["posture"] == "assault" and tm["step"] < tm["plan"].size():
		var st: Dictionary = tm["plan"][tm["step"]]
		return w.level.inward(st["door"], st["into"]).angle()
	var v := Vector2.ZERO
	for m in al:
		v += Vector2.from_angle(m.spawn_face if tm["posture"] == "hold" else m.body_dir)
	return v.angle()


## GD05 bounding overwatch by elements: odd slots (1, 3, 5) and even slots (2, 4)
## alternate. One element moves while the other is static and covering.
func _bounding(tm: Dictionary, al: Array) -> void:
	var movers: Array = [[], []]
	for m in al:
		if m.has("GD05") and w.level.room_at(m.pos) in ["OUT", "PORCH"]:
			movers[m.slot % 2].append(m)
	var phase_ok: bool = tm["posture"] == "hunt" or (tm["posture"] == "assault" and tm["phase"] == "approach")
	if movers[0].is_empty() or movers[1].is_empty() or not phase_ok:
		tm["bound"] = -1
		return
	var cur: int = tm["bound"]
	if cur < 0:
		tm["bound"] = 0
		tm["bound_from"] = _centre(movers[0])
		tm["bound_t"] = w.t
		return
	var el: Array = movers[cur]
	var any_moving := false
	for m in el:
		if m.moving:
			any_moving = true
	var done: bool = _centre(el).distance_to(tm["bound_from"]) > 4.5 or w.t - tm["bound_t"] > 4.0
	if w.t - tm["bound_t"] > 0.8 and not any_moving:
		done = true
	if done:
		var nxt := 1 - cur
		tm["bound"] = nxt
		tm["bound_from"] = _centre(movers[nxt])
		tm["bound_t"] = w.t


func _centre(ms: Array) -> Vector2:
	var c := Vector2.ZERO
	for m in ms:
		c += m.pos
	return c / maxf(1.0, ms.size())


func _assault_tick(tm: Dictionary, al: Array) -> void:
	if tm["step"] >= tm["plan"].size():
		return
	var st: Dictionary = tm["plan"][tm["step"]]
	var entry: Dictionary = tm["entry"]
	for m in al:
		if not entry.has(m.id):
			_begin_step(tm)
			return
	match tm["phase"]:
		"check":
			if entry.has("check_done_t") and w.t >= entry["check_done_t"]:
				tm["cleared"][st["into"]] = true
				w.say("Team %s: bathroom checked" % "AB"[tm["id"]], "info")
				_advance(tm)
			elif w.t - tm["phase_t"] > 12.0:
				_advance(tm)
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
				go = all_ready or (any_ready and w.t - entry.get("first_ready_t", w.t) > 6.0)
			else:
				go = any_ready
			if w.t - tm["phase_t"] > 45.0:
				go = true
			if go:
				tm["phase"] = "entry"
				tm["phase_t"] = w.t
				w.say("Team %s enters the %s" % ["AB"[tm["id"]], w.level.rooms[st["into"]]["title"].to_lower()], "info")
		"entry":
			var done := true
			for m in al:
				if entry[m.id]["enters"] and not entry[m.id]["arrived"]:
					done = false
			if done or w.t - tm["phase_t"] > 9.0:
				tm["phase"] = "clear"
				tm["phase_t"] = w.t
		"clear":
			var quiet := true
			for m in al:
				if not w.visible_enemies(m).is_empty():
					quiet = false
			if quiet and w.t - tm["phase_t"] > 1.2:
				tm["cleared"][st["into"]] = true
				w.say("Team %s: %s clear" % ["AB"[tm["id"]], w.level.rooms[st["into"]]["title"].to_lower()], "info")
				_advance(tm)


# ================================================================== individual
func think(o) -> void:
	o.dbg = ""
	o.stance_goal = Op.STAND if not o.leg_hit or o.stance_goal != Op.CROUCH else Op.CROUCH
	var tm: Dictionary = w.teams[o.team]
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
	# P4: engage beyond 10 m
	var far = _far_target(o)
	if far == null and o.ticker.has("far_dest") and _to_far_dest(o):
		return
	if far != null:
		_engage_far(o, far)
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
	match tm["posture"]:
		"assault":
			_task_assault(o, tm)
		"hold":
			_task_hold(o)
		"hunt":
			_task_hunt(o, tm)
	_finish_look(o)


# ------------------------------------------------------------------ Rule 1
func _close_threat(o):
	var best = null
	var best_d := 10.0001
	var cur: String = o.aim.get("tid", "")
	var cur_d := INF
	for e in w.enemies_of(o):
		if not w.visible(o, e):
			continue
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
		return w.op_by_id(cur)
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
	if o.sidestep.is_empty():
		w.stop(o)
	w.engage(o, e, _aim_zone(o, e), true)


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


func _threats(o) -> Array:
	var out: Array = []
	for e in w.enemies_of(o):
		if not e.alive():
			continue
		if w.visible(o, e):
			out.append(e.pos)
		elif o.lkp.has(e.id) and w.t - o.lkp[e.id]["t"] < 15.0:
			out.append(o.lkp[e.id]["p"])
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


# ------------------------------------------------------------------ BH09
func _jumpy(o) -> bool:
	if not o.usable(o.active) or not o.action.is_empty():
		return false
	for e in w.enemies_of(o):
		if not e.alive() or w.visible(o, e):
			continue
		var p: float = o.rec.get(e.id, 0.0)
		if p >= 0.5 and o.vis.get(e.id, {}).get("los", false) and o.pos.distance_to(e.pos) <= 10.0 and e.vel.length() > 0.3:
			o.dbg = "jumpy trigger > " + e.id
			o.look_goal = (e.pos - o.pos).angle()
			w.stop(o)
			w.engage(o, e, "chest", true)
			return true
	for m in w.mates_of(o):
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
		w.move_to(o, e.pos, "walk")
	else:
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
		w.move_to(o, lk["p"], "sprint")
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
		if tl != null and o.pos.distance_to(tl) > 1.5:
			o.dbg = "lone wolf push"
			w.move_to(o, tl, "walk")
			return true
	return false


func _latest_lkp(o):
	var best = null
	for e in w.enemies_of(o):
		if not e.alive() or not o.lkp.has(e.id):
			continue
		var l: Dictionary = o.lkp[e.id]
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
	var threats := _threats(o)
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
	if o.has("WD03") and not threats.is_empty() and not _hidden(o.pos, threats, 0.82):
		o.dbg = "to cover to reload"
		_seek_cover(o, threats)
		return true
	w.stop(o)
	_reload(o, want, false)
	return true


# ------------------------------------------------------------------ P7 tasks
func _go(o, p: Vector2, mode: String, group := true) -> void:
	var tm: Dictionary = w.teams[o.team]
	var mates: Array = w.mates_of(o)
	var outside: bool = o.room == "OUT" or o.room == "PORCH"
	if group and not mates.is_empty():
		var near = mates[0]
		for m in mates:
			if m.pos.distance_to(o.pos) < near.pos.distance_to(o.pos):
				near = m
		if o.has("GD10") and o.pos.distance_to(near.pos) > 8.0 and (p - o.pos).dot(near.pos - o.pos) < 0.0:
			o.dbg = "waiting (tether)"
			w.stop(o)
			return
		if tm["bound"] >= 0 and o.slot % 2 != tm["bound"] and outside and o.has("GD05"):
			o.dbg = "overwatch"
			w.stop(o)
			_task_look(o, (p - o.pos).angle())
			return
		if o.hb("BH14") and o.pos.distance_to(near.pos) > 1.0 and near.pos.distance_to(p) > 2.0:
			p = near.pos + (o.pos - near.pos).limit_length(0.8)
		elif o.has("GD07"):
			var ahead: Vector2 = near.pos - o.pos
			if ahead.length() < 1.5 and ahead.dot(p - o.pos) > 0.0 and near.moving:
				o.dbg = "keeping spacing"
				w.stop(o)
				return
		if o.has("GD03") and _in_line_of_fire(o, mates):
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
	w.move_to(o, p, m2)


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
	for win in w.level.windows:
		var r: Rect2 = win["r"]
		if r.get_center().distance_to(p) < 1.4 and not w.level.is_inside(p):
			return true
	return false


func _task_look(o, dir: float) -> void:
	o.ticker["task_look"] = dir
	o.ticker["task_look_tick"] = tick


func _task_assault(o, tm: Dictionary) -> void:
	if tm["step"] >= tm["plan"].size():
		return
	var st: Dictionary = tm["plan"][tm["step"]]
	var D: Dictionary = w.level.doors[st["door"]]
	var c: Vector2 = D["c"]
	var n_in: Vector2 = w.level.inward(st["door"], st["into"])
	var entry: Dictionary = tm["entry"]
	if not entry.has(o.id):
		return
	var d: Dictionary = entry[o.id]
	match tm["phase"]:
		"check":
			if not entry.has("checker"):
				var best = null
				for m in alive_members(tm):
					if m.has("PF10") and (best == null or m.pos.distance_to(c) < best.pos.distance_to(c)):
						best = m
				entry["checker"] = best.id if best != null else ""
			if entry["checker"] == o.id:
				var cp: Vector2 = w.nav.snap(c - n_in * 1.1 + D["t"] * 0.35)
				o.dbg = "checking the bathroom"
				if not w.at(o, cp, 0.3):
					_go(o, cp, "clear", false)
					_task_look(o, (c - o.pos).angle())
				else:
					w.stop(o)
					_task_look(o, (c + n_in * 1.6 - o.pos).angle())
					if not entry.has("check_done_t"):
						entry["check_done_t"] = w.t + 1.0
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
				_go(o, target, mode)
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
				if d["ready"] and not entry.has("first_ready_t"):
					entry["first_ready_t"] = w.t
				o.dbg = "stacked" if o.has("GD01") else "waiting at the door"
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
				for m in alive_members(tm):
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
				_go(o, target, "sprint" if o.hb("BH11") else "entry", false)
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
				elif since < 2.5 and tm["phase"] == "entry":
					_task_look(o, (w.level.rooms[st["into"]]["label"] - o.pos).angle())


func _task_hold(o) -> void:
	if not w.at(o, o.spawn, 0.6):
		_go(o, o.spawn, "walk", false)
		o.dbg = "returning to post"
	else:
		w.stop(o)
		o.dbg = "holding"


func _task_hunt(o, tm: Dictionary) -> void:
	var target = null
	var best_t: float = tm.get("hunt_done_t", -1.0)
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
	var al := alive_members(tm)
	al.sort_custom(func(a, b): return a.slot < b.slot)
	var k := al.find(o)
	if target == null:
		var pts: Array = w.level.patrol
		target = pts[tm.get("hunt_i", 0) % pts.size()]
		if k == 0 and w.at(o, target, 1.2):
			tm["hunt_i"] = tm.get("hunt_i", 0) + 1
	elif k == 0 and w.at(o, target, 1.5):
		tm["hunt_done_t"] = w.t
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
	var tm: Dictionary = w.teams[o.team]
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
		for op in w.level.openings:
			var p: Vector2 = op["c"]
			var d: float = o.pos.distance_to(p)
			if d > 0.8 and d < bd and w.geom.sight_clear(o.pos, o.eye(), p, 1.2):
				bd = d
				best = p
		o.ticker["salient"] = best
	var sal = o.ticker.get("salient", null)
	if sal != null:
		o.look_goal = (sal - o.pos).angle()
	else:
		o.look_goal = o.spawn_face if tm["posture"] == "hold" else o.look_goal


func _is_rear(o) -> bool:
	var mates: Array = w.mates_of(o)
	if mates.is_empty():
		return false
	var dir: Vector2 = o.vel.normalized()
	for m in mates:
		if (m.pos - o.pos).dot(dir) < 0.0:
			return false
	return true


func _scan(o, tm: Dictionary) -> void:
	var sector = tm["sectors"].get(o.id, null)
	var half: float = tm["sector_half"]
	if w.t < o.ticker.get("scan_next", 0.0):
		if sector != null and absf(angle_difference(o.look_goal, sector)) > half:
			o.look_goal = sector
		return
	o.ticker["scan_next"] = w.t + w.rng.randf_range(0.9, 1.5)
	var cands: Array = []
	var i := 0
	for op in w.level.openings:
		var wt := 2.5
		if op["kind"] == "door":
			var D: Dictionary = w.level.doors[op["id"]]
			if tm["posture"] == "assault" and tm["cleared"].has(D["a"]) and tm["cleared"].has(D["b"]):
				wt = 1.0
			else:
				wt = 3.0
		cands.append({"p": op["c"], "w": wt, "k": "o%d" % i})
		i += 1
	for cr in w.level.corners:
		if cr["room"] == o.room:
			cands.append({"p": cr["p"], "w": 2.0, "k": "c%s" % str(cr["p"])})
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
