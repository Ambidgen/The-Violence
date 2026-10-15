extends RefCounted
## The simulation (bible sections 1-5). Fixed 30 Hz ticks, seeded RNG, no rendering.
## The view reads `ops`, `events` and `log_lines`; the brain makes the decisions.

const Habits = preload("res://scripts/data/habits.gd")
const Geom = preload("res://scripts/sim/geom.gd")
const Op = preload("res://scripts/sim/op.gd")
const Brain = preload("res://scripts/sim/brain.gd")

const DT := 1.0 / 30.0
const TIME_LIMIT := 300.0
const SPEEDS := {"walk": 1.6, "entry": 2.0, "clear": 1.2, "slice": 1.0, "creep": 0.8, "run": 3.0, "sprint": 4.0, "step": 1.2}

var level
var geom: Geom
var nav
var brain
var ops: Array = []
var teams: Array = []
var t := 0.0
var rng := RandomNumberGenerator.new()
var seed_used := 0
var events: Array = []
var keep_events := true
var log_lines: Array = []
var over := false
var winner := -1        # 0 = team A, 1 = team B, 2 = draw
var stat := {"shots": 0, "hits": 0, "friendly": 0, "stray": 0}


func setup(lv, nv, cfgs: Array, postures: Array, seed_val: int) -> void:
	level = lv
	geom = lv.geom
	nav = nv
	seed_used = seed_val
	rng.seed = seed_val
	ops.clear()
	for c in cfgs:
		if not c.get("enabled", true):
			continue
		var o = Op.new()
		o.configure(c)
		o.reset()
		o.perc_phase = rng.randf() * 0.1
		ops.append(o)
	teams = []
	for k in 2:
		teams.append({"id": k, "posture": postures[k], "members": [], "plan": [], "step": 0,
			"phase": "", "phase_t": 0.0, "cleared": {}, "lkps": {}, "sound": {}, "sectors": {},
			"bound": -1, "bound_from": Vector2.ZERO, "bound_t": 0.0, "last_contact": -99.0,
			"sector_half": deg_to_rad(80.0), "sector_pending": {},
			"entry": {}, "orig_posture": postures[k], "lost": {}})
	for o in ops:
		teams[o.team]["members"].append(o)
	brain = Brain.new(self)
	for o in ops:
		_update_bad(o, true)
	brain.init_teams()
	say("Seed %d. Team A: %d, %s. Team B: %d, %s." % [seed_val, teams[0]["members"].size(), postures[0],
		teams[1]["members"].size(), postures[1]], "info")


# ================================================================== main loop
func step() -> void:
	if over:
		return
	t += DT
	for o in ops:
		if o.alive():
			_update_bad(o, false)
	for o in ops:
		if o.alive():
			_perceive(o)
	for o in ops:
		if o.alive():
			_recognize(o)
	brain.update_teams()
	for o in ops:
		if o.alive():
			brain.think(o)
	for o in ops:
		if o.alive():
			_integrate(o)
	for o in ops:
		_passive(o)
	_check_end()


## Break reference cycles so a finished match frees its memory.
func dispose() -> void:
	if brain != null:
		brain.w = null
	brain = null
	ops.clear()
	teams.clear()


func say(text: String, kind := "info") -> void:
	var mm := int(t / 60.0)
	var ss := fmod(t, 60.0)
	log_lines.append({"t": t, "text": "%02d:%04.1f  %s" % [mm, ss, text], "kind": kind})


func emit(ev: Dictionary) -> void:
	if keep_events:
		events.append(ev)


func op_by_id(oid: String):
	for o in ops:
		if o.id == oid:
			return o
	return null


func enemies_of(o) -> Array:
	var out: Array = []
	for e in ops:
		if e.team != o.team:
			out.append(e)
	return out


func mates_of(o) -> Array:
	var out: Array = []
	for m in ops:
		if m.team == o.team and m != o and m.alive():
			out.append(m)
	return out


# ================================================================== bad habits
func _update_bad(o, first: bool) -> void:
	var anx := 70.0 if (o.bad.get("BH13", false) or o.bad.get("BH14", false)) else 40.0
	var eff: float = o.stress * (1.0 - o.ech["resist"])
	var changed := false
	for b in Habits.BAD:
		var bid: String = b["id"]
		var present: bool = o.bad.get(bid, false)
		var on: bool = o.active_bad.has(bid)
		if not present:
			if on:
				o.active_bad.erase(bid)
				changed = true
			continue
		if b["kind"] == "trait":
			if not on:
				o.active_bad[bid] = true
				changed = true
				if first:
					say("%s %s %s (%s): %s suspended" % [o.id, bid, b["name"], b["trait"], _list_owned(o, b["over"])], "bad")
			continue
		var thr: float = b["t"] - 0.3 * anx / 100.0
		if on and eff < thr - 0.1:
			o.active_bad.erase(bid)
			changed = true
			say("%s %s %s eases" % [o.id, bid, b["name"]], "bad")
		elif not on and eff >= thr:
			o.active_bad[bid] = true
			changed = true
			say("%s %s %s: %s suspended" % [o.id, bid, b["name"], _list_owned(o, b["over"])], "bad")
			emit({"type": "bad_on", "id": o.id, "bad": bid, "name": b["name"]})
	if changed or first:
		o.suspended.clear()
		for bid in o.active_bad:
			for gid in Habits.bad_info(bid)["over"]:
				if o.good.get(gid, false):
					o.suspended[gid] = true
		var n := 0
		for gid in o.good:
			if o.has(gid):
				n += 1
		o.m_h = 1.0 - 0.005 * n


func _list_owned(o, ids: Array) -> String:
	var owned: Array = []
	for gid in ids:
		if o.good.get(gid, false):
			owned.append(gid)
	return ", ".join(owned) if not owned.is_empty() else "nothing it owns"


# ================================================================== perception
func cone_half(o) -> float:
	if o.hb("BH04"):
		return deg_to_rad(25.0)
	var k := 0.5 if o.has("ED06") else 1.0
	return deg_to_rad(60.0 * (1.0 - 0.4 * o.stress * (1.0 - o.ech["resist"]) * k))


func _perceive(o) -> void:
	o.perc_phase -= DT
	if o.perc_phase > 0.0:
		return
	o.perc_phase += 0.1
	var ez: float = o.eye()
	var half := cone_half(o)
	for e in enemies_of(o):
		if not e.alive() and t - e.ticker.get("down_t", t) > 4.0:
			o.vis[e.id] = {"los": false, "head_only": false, "dist": 99.0}
			continue
		var d: Vector2 = e.pos - o.pos
		var dist := d.length()
		var ecc := absf(angle_difference(o.look_dir, d.angle()))
		if ecc > half + 0.05 or dist > 45.0:
			o.vis[e.id] = {"los": false, "head_only": false, "dist": dist}
			continue
		var hv := geom.sight_clear(o.pos, ez, e.pos, e.zone_centre("head"))
		var cv := geom.sight_clear(o.pos, ez, e.pos, e.zone_centre("chest"))
		o.vis[e.id] = {"los": hv or cv, "head_only": hv and not cv, "dist": dist}


func t_rec(o, e, ecc: float, head_only: bool) -> float:
	var ed := rad_to_deg(ecc) / 60.0
	var E := 1.0 + 2.5 * ed * ed
	var X := 1.5 if head_only else 1.0
	if e.ticker.get("in_cover_t", -9.0) > t - 0.3 and e.has("PF05"):
		X = maxf(X, 1.5)
	if e.vel.length() > 0.3:
		X *= 0.8
	var S: float = 1.0 + 0.5 * o.stress * (1.0 - o.ech["resist"])
	var C := 0.6 if o.cue.get(e.id, -1.0) > t else 1.0
	return o.ech["t_rec0"] * o.m_h * E * X * S * C


func _recognize(o) -> void:
	var half := cone_half(o)
	for e in enemies_of(o):
		var p: float = o.rec.get(e.id, 0.0)
		var was := p >= 1.0
		var v: Dictionary = o.vis.get(e.id, {})
		var seen := false
		if v.get("los", false):
			var d: Vector2 = e.pos - o.pos
			var ecc := absf(angle_difference(o.look_dir, d.angle()))
			if ecc <= half:
				seen = true
				p += DT / t_rec(o, e, ecc, v.get("head_only", false))
		if not seen:
			p = maxf(0.0, p - 0.5 * DT)
		p = minf(p, 1.0)
		o.rec[e.id] = p
		if seen and p >= 1.0:
			o.lkp[e.id] = {"p": e.pos, "t": t}
			if e.alive():
				o.last_enemy_seen_t = t
			if not was:
				_on_recognized(o, e)


func visible(o, e) -> bool:
	return o.rec.get(e.id, 0.0) >= 1.0 and o.vis.get(e.id, {}).get("los", false)


func visible_enemies(o) -> Array:
	var out: Array = []
	for e in enemies_of(o):
		if e.alive() and visible(o, e):
			out.append(e)
	return out


func _on_recognized(o, e) -> void:
	if not e.alive():
		return
	var dist: float = o.pos.distance_to(e.pos)
	var ecc := rad_to_deg(absf(angle_difference(o.look_dir, (e.pos - o.pos).angle())))
	if not o.first_rec.has(e.id):
		o.first_rec[e.id] = t
		say("%s recognizes %s: %.1f m, %d deg off eye line" % [o.id, e.id, dist, int(ecc)], "info")
	emit({"type": "recognized", "id": o.id, "target": e.id})
	teams[o.team]["last_contact"] = t
	if o.hb("BH01") and not o.ticker.has("froze_" + e.id):
		o.ticker["froze_" + e.id] = true
		o.freeze_add = rng.randf_range(0.4, 1.0)
		o.ticker["freeze_until"] = t + o.freeze_add
		say("%s freezes for %.1f s" % [o.id, o.freeze_add], "bad")
	if o.has("GD04") and t - o.ticker.get("callout_" + e.id, -99.0) > 5.0:
		o.ticker["callout_" + e.id] = t
		for m in mates_of(o):
			if m.has("GD04"):
				m.cue[e.id] = t + 3.0
				if visible_enemies(m).is_empty() and in_sector(m, (e.pos - m.pos).angle()):
					m.look_hint = {"dir": (e.pos - m.pos).angle(), "start": t + 0.5, "until": t + 2.0, "why": "callout"}
		teams[o.team]["lkps"][e.id] = {"p": e.pos, "t": t}
		var clock := int(round(fposmod(rad_to_deg((e.pos - o.pos).angle() - o.body_dir), 360.0) / 30.0)) % 12
		say("%s calls: contact, %d o'clock, %d m" % [o.id, 12 if clock == 0 else clock, int(dist)], "comms")


# ================================================================== actions
func start_action(o, type: String, dur: float, extra := {}) -> void:
	o.action = {"type": type, "left": dur, "total": dur}
	for k in extra:
		o.action[k] = extra[k]
	o.aim = {}
	if (type == "reload" or type == "clear") and o.has("GD08"):
		var cover = null
		for m in mates_of(o):
			if m.has("GD08") and m.action.is_empty() and visible_enemies(m).is_empty():
				if cover == null or m.pos.distance_to(o.pos) < cover.pos.distance_to(o.pos):
					cover = m
		if cover != null:
			cover.look_hint = {"dir": o.look_dir, "start": t + 0.5, "until": t + dur + 0.5, "why": "covering " + o.id}
			say("%s: %s, cover me. %s covers" % [o.id, "reloading" if type == "reload" else "stoppage", cover.id], "comms")
		else:
			say("%s: %s, nobody free to cover" % [o.id, "reloading" if type == "reload" else "stoppage"], "comms")


func _finish_action(o) -> void:
	var a: Dictionary = o.action
	o.action = {}
	match a["type"]:
		"transition":
			o.active = a["to"]
			say("%s on %s" % [o.id, "pistol" if o.active == "pistol" else "rifle"], "rule")
		"reload":
			var wn: String = a["w"]
			var s: Dictionary = o.weapons[wn]
			s["mag"] = Habits.WEAPONS[wn]["mag"]
			s["spare"] -= 1
			o.active = wn
			o.ticker["reengage"] = true
			say("%s reloaded %s (%d spare)" % [o.id, wn, s["spare"]], "info")
		"clear":
			if rng.randf() < a["p_ok"]:
				o.ws()["jam"] = false
				o.ticker["reengage"] = true
				say("%s cleared the stoppage" % o.id, "info")
			else:
				say("%s: stoppage still there, again" % o.id, "info")
				start_action(o, "clear", a["total"], {"p_ok": a["p_ok"]})
		"click":
			o.ticker["clicked"] = true


func blocks_move(o) -> bool:
	if o.ticker.get("freeze_until", -1.0) > t or o.ticker.get("flinch_until", -1.0) > t:
		return true
	if o.action.is_empty():
		return false
	return o.action["type"] in ["reload", "clear", "check", "stall", "click"]


# ================================================================== movement
func move_to(o, p: Vector2, mode: String, prof := -1) -> void:
	if prof < 0:
		prof = (1 if o.has("PF01") else 0) | (2 if o.has("PF02") else 0)
	o.goal_mode = mode
	var spd: float = SPEEDS.get(mode, 1.6)
	spd *= 1.0 - 0.04 * o.plates_max
	if o.wounds > 0:
		spd *= 0.7
	if o.leg_hit:
		spd *= 0.4
	o.speed = spd
	var stuck := false
	if t > o.repath_t:
		stuck = o.moving and o.pos.distance_to(o.ticker.get("prog_p", Vector2.INF)) < 0.1 and not blocks_move(o)
		o.ticker["prog_p"] = o.pos
		o.repath_t = t + 1.5
	var need: bool = o.path.is_empty() or o.goal.distance_to(p) > 0.4 or stuck or o.ticker.get("prof", -1) != prof
	if need and o.path.is_empty() and o.goal.distance_to(p) <= 0.4 and t < o.ticker.get("path_fail_until", -1.0):
		need = false
	if need:
		o.goal = p
		o.path = nav.find_path(prof, o.pos, p)
		if o.path.is_empty():
			o.ticker["path_fail_until"] = t + 1.0
		o.path_i = 1
		o.ticker["prof"] = prof
	o.moving = true


## Pause movement but keep the path, so resuming toward the same goal costs nothing.
func stop(o) -> void:
	o.moving = false


func at(o, p: Vector2, tol := 0.35) -> bool:
	return o.pos.distance_to(p) <= tol


func _move(o) -> void:
	var newp: Vector2 = o.pos
	if blocks_move(o):
		o.vel = Vector2.ZERO
		return
	if not o.sidestep.is_empty():
		var sd: Dictionary = o.sidestep
		sd["left"] -= DT
		var q: Vector2 = o.pos + sd["dir"] * SPEEDS["step"] * DT
		if sd["left"] <= 0.0 or not nav.is_free(q):
			o.sidestep = {}
		else:
			newp = q
	elif o.moving and o.path.size() > 0:
		while o.path_i < o.path.size() and o.pos.distance_to(o.path[o.path_i]) < 0.08:
			o.path_i += 1
		if o.path_i >= o.path.size():
			o.moving = false
		else:
			var target: Vector2 = o.path[o.path_i]
			var d: Vector2 = target - o.pos
			newp = o.pos + d.limit_length(o.speed * DT)
	# separation from other bodies (suspended briefly when two are jammed in a doorway)
	var ghost: bool = o.ticker.get("ghost_until", -1.0) > t
	for m in ops:
		if ghost or m == o or not m.alive():
			continue
		var sep: Vector2 = newp - m.pos
		var dd := sep.length()
		if dd < 0.5 and dd > 0.001:
			var q2: Vector2 = newp + sep / dd * (0.5 - dd) * 0.5
			if nav.is_free(q2):
				newp = q2
	var moved: float = newp.distance_to(o.pos)
	if o.moving and o.sidestep.is_empty() and moved < 0.005:
		o.ticker["jam_t"] = o.ticker.get("jam_t", 0.0) + DT
		if o.ticker["jam_t"] > 1.0:
			o.ticker["ghost_until"] = t + 0.8
			o.ticker["jam_t"] = 0.0
	else:
		o.ticker["jam_t"] = 0.0
	o.vel = (newp - o.pos) / DT
	o.pos = newp
	o.room = level.room_at(o.pos)
	if o.wounds > 0 or o.arm_hit or o.leg_hit:
		o.ticker["drip_d"] = o.ticker.get("drip_d", 0.0) + moved
		if o.ticker["drip_d"] > 0.45:
			o.ticker["drip_d"] = 0.0
			emit({"type": "drip", "p": o.pos + Vector2(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.12, 0.12))})


# ================================================================== aiming and firing
func sigma_shooter(o, settle: float) -> float:
	return o.ech["s_min"] + (o.ech["s_snap"] - o.ech["s_min"]) * exp(-settle / o.ech["tau"])


func engage(o, e, zone: String, fire := true) -> void:
	if o.aim.get("tid", "") != e.id or o.aim.get("zone", "") != zone or o.aim.get("weapon", "") != o.active:
		_start_acquire(o, e, zone)
	o.aim["want_t"] = t
	o.aim["fire"] = fire


func _start_acquire(o, e, zone: String) -> void:
	var to: Vector2 = e.pos - o.pos
	var d := maxf(to.length(), 0.5)
	var bearing := to.angle()
	var dth := absf(angle_difference(o.muzzle_dir, bearing))
	var W := 2.0 * atan(e.zone_radius(zone) / d)
	var w: Dictionary = o.wpn()
	var t_ready := 0.0 if (o.has("ED01") or o.weapon_up) else 0.25
	var a: float = o.ech["a"] + w["a_w"]
	var b: float = o.ech["b"] * w["b_w"]
	var tt: float = o.m_h * (t_ready + a + b * log(1.0 + dth / W) / log(2.0))
	tt = maxf(tt, dth / deg_to_rad(o.ech["turn"]))
	if o.arm_hit:
		tt += 0.2
	if o.freeze_add > 0.0:
		tt += o.freeze_add
		o.freeze_add = 0.0
	var plate_seen: bool = o.aim.get("plate_seen", false) and o.aim.get("tid", "") == e.id
	o.aim = {"tid": e.id, "zone": zone, "weapon": o.active, "acq_left": tt, "acq_total": tt,
		"from": o.muzzle_dir, "on": false, "settle": 0.0, "pair": 0, "pause": 0.0, "hold": 0.0,
		"want_t": t, "fire": true, "plate_seen": plate_seen, "dth": dth}


func _aim_update(o) -> void:
	if o.aim.is_empty():
		return
	if o.aim["want_t"] < t - 0.05:
		o.aim = {}
		return
	var e = op_by_id(o.aim["tid"])
	if e == null:
		o.aim = {}
		return
	o.weapon_up = true
	o.last_aim_t = t
	var bearing: float = (e.pos - o.pos).angle()
	if not o.aim["on"]:
		o.aim["acq_left"] -= DT
		var k: float = clampf(1.0 - o.aim["acq_left"] / maxf(o.aim["acq_total"], 0.001), 0.0, 1.0)
		o.muzzle_dir = lerp_angle(o.aim["from"], bearing, k)
		if o.aim["acq_left"] <= 0.0:
			o.aim["on"] = true
			o.aim["settle"] = 0.0
			if not o.ticker.has("tot_" + e.id) and e.alive():
				o.ticker["tot_" + e.id] = true
				say("%s on target %s after %.2f s (%.0f deg traverse)" % [o.id, e.id, o.aim["acq_total"], rad_to_deg(o.aim["dth"])], "info")
		return
	o.muzzle_dir = bearing
	o.aim["settle"] += DT
	if o.aim["pause"] > 0.0:
		o.aim["pause"] -= DT
		return
	if not o.aim["fire"] or not o.action.is_empty():
		return
	if o.ticker.get("flinch_until", -1.0) > t or o.ticker.get("stagger_until", -1.0) > t:
		return
	var s: Dictionary = o.ws()
	if s["mag"] <= 0 or s["jam"] or s["lost"]:
		return
	var w: Dictionary = o.wpn()
	var since: float = t - o.last_shot_t
	var split: float = w["snap"]
	var release := true
	if o.hb("BH02"):
		split = w["cadence"]
	elif o.hb("BH19"):
		split = 0.25
	elif o.has("WD07"):
		split = 0.25
		var dist: float = maxf(o.pos.distance_to(e.pos), 0.5)
		var W: float = 2.0 * atan(e.zone_radius(o.aim["zone"]) / dist) * 1000.0
		var cap := 0.5 if o.aim["zone"] == "head" else 0.15
		release = sigma_shooter(o, o.aim["settle"]) <= 0.35 * W or o.aim["settle"] >= cap
	if since < split or not release:
		return
	if o.has("WD10") and friend_in_line(o, e.pos):
		o.aim["hold"] += DT
		if o.aim["hold"] > 0.3 and o.sidestep.is_empty() and o.action.is_empty():
			var side := Vector2.from_angle(bearing + PI / 2.0)
			if not nav.is_free(o.pos + side * 0.5):
				side = -side
			o.sidestep = {"dir": side, "left": 0.45}
			o.aim["hold"] = 0.0
		return
	o.aim["hold"] = 0.0
	fire_at(o, e, o.aim["zone"], o.aim["settle"])
	o.aim["pair"] += 1
	o.aim["settle"] = 0.0
	if o.hb("BH19"):
		if o.aim["pair"] >= 2:
			o.aim["pause"] = 0.6
			o.aim["pair"] = 0
	elif o.has("WD07") and not o.hb("BH02"):
		if o.aim["pair"] >= 2:
			o.aim["pause"] = 0.3
			o.aim["pair"] = 0


func friend_in_line(o, target: Vector2) -> bool:
	var u: Vector2 = (target - o.pos)
	var L := u.length()
	if L < 0.01:
		return false
	u /= L
	for m in mates_of(o):
		var rel: Vector2 = m.pos - o.pos
		var s := rel.dot(u)
		if s > 0.2 and s < L and absf(rel.cross(u)) < 0.5:
			return true
	return false


func fire_at(o, e, zone: String, settle: float) -> void:
	var to: Vector2 = e.pos - o.pos
	_fire(o, to.angle(), e.zone_centre(zone), maxf(to.length(), 0.3), settle)


func _fire(o, bearing: float, aim_z: float, dist: float, settle: float) -> void:
	var w: Dictionary = o.wpn()
	var s: Dictionary = o.ws()
	if s["mag"] <= 0:
		return
	s["mag"] -= 1
	o.shots += 1
	stat["shots"] += 1
	o.last_shot_t = t
	o.weapon_up = true
	var sig := sqrt(pow(sigma_shooter(o, settle), 2.0) + pow(w["s_w"], 2.0))
	var sp: float = o.vel.length()
	if sp > 0.2:
		sig *= o.ech["move_s"] * (1.5 if sp > 2.5 else 1.0)
	sig *= 1.0 + o.stress * (1.0 - o.ech["resist"])
	if o.wounds > 0:
		sig *= 1.5
	if o.arm_hit:
		sig *= 1.4
	var yaw := bearing + rng.randfn(0.0, sig) / 1000.0
	var mz: float = o.eye() - 0.05
	var pitch: float = atan2(aim_z - mz, dist) + (rng.randfn(0.0, sig) - o.ech["flinch"] + o.recoil) / 1000.0
	o.recoil += w["kappa"]
	var u := Vector2.from_angle(yaw)
	var reach := 60.0
	var slope := tan(clampf(pitch, -1.2, 1.2))
	var mh: Dictionary = geom.trace_shot(o.pos, mz, o.pos + u * reach, mz + slope * reach)
	var stop_d: float = mh["t"] * reach
	var hit_op = null
	var hit_zone: Array = []
	var hit_lat := 0.0
	var best := stop_d
	for a in ops:
		if a == o:
			continue
		var rel: Vector2 = a.pos - o.pos
		var sa := rel.dot(u)
		if sa <= 0.15 or sa >= best:
			continue
		var lat := absf(rel.cross(u))
		var zn: Array = a.zone_at(mz + slope * sa)
		if not zn.is_empty() and lat <= zn[3]:
			best = sa
			hit_op = a
			hit_zone = zn
			hit_lat = lat
	var endp: Vector2 = o.pos + u * best
	emit({"type": "shot", "from": o.pos + u * 0.55, "to": endp, "team": o.team, "id": o.id})
	emit({"type": "casing", "p": o.pos, "dir": o.body_dir})
	_sound(o)
	for a in ops:
		if a == o or a == hit_op or not a.alive():
			continue
		var rel2: Vector2 = a.pos - o.pos
		var sa2 := rel2.dot(u)
		if sa2 > 0.3 and sa2 < best + 1.0 and absf(rel2.cross(u)) < 1.0:
			add_stress(a, 0.15, "near miss")
			a.ticker["near_t"] = t
	if hit_op != null:
		_hit(hit_op, hit_zone, hit_lat, u, o)
	elif mh["hit"]:
		emit({"type": "impact", "p": mh["p"], "n": mh["n"], "kind": mh["kind"]})
	var pj: float = w["stop"] * (0.5 if o.has("WD04") else 1.0)
	if rng.randf() < pj:
		s["jam"] = true
		say("%s stoppage (%s)" % [o.id, o.active], "rule")


func _sound(src) -> void:
	for o in ops:
		if o == src or not o.alive() or o.team == src.team:
			continue
		teams[o.team]["sound"] = {"p": src.pos, "t": t}
		if o.ticker.get("sweep_until", -1.0) > t:
			continue
		var engaged := not visible_enemies(o).is_empty()
		var dir: float = (src.pos - o.pos).angle()
		if o.has("ED07"):
			if not engaged:
				o.look_hint = {"dir": dir, "start": t + 0.3, "until": t + 1.8, "why": "gunfire"}
		elif not engaged and o.look_hint.get("why", "") != "gunfire":
			o.look_hint = {"dir": dir, "start": t + 1.0, "until": t + 2.4, "why": "gunfire"}


## Is a bearing inside this operator's assigned sector (or has it none)?
func in_sector(m, dir: float) -> bool:
	var sec = teams[m.team]["sectors"].get(m.id, null)
	if sec == null:
		return true
	return absf(angle_difference(dir, sec)) <= teams[m.team]["sector_half"] + deg_to_rad(20.0)


func add_stress(a, amt: float, _why: String) -> void:
	a.stress = minf(1.0, a.stress + amt)
	a.last_stress_t = t
	if amt >= 0.15 and a.alive() and not a.has("WD09") and a.stress > 0.6 and rng.randf() < 0.02:
		if a.ws()["mag"] > 0 and a.action.is_empty():
			say("%s fires a stray shot" % a.id, "bad")
			stat["stray"] += 1
			_fire(a, a.muzzle_dir, 1.0, 8.0, 0.0)


# ================================================================== damage
func _hit(a, zn: Array, lat: float, u: Vector2, shooter) -> void:
	var zone: String = zn[0]
	if (zone == "chest" or zone == "abd") and lat > 0.7 * zn[3] and rng.randf() < 0.5:
		zone = "arm"
	var side := signf(u.cross(a.pos - shooter.pos))
	if a.alive() and a.team == shooter.team:
		stat["friendly"] += 1
		say("%s hit by friendly fire from %s" % [a.id, shooter.id], "bad")
	if not a.alive():
		emit({"type": "blood", "p": a.pos, "dir": u, "power": 0.5, "zone": "body", "id": a.id, "side": side})
		return
	var from_dir: float = (shooter.pos - a.pos).angle()
	var front := absf(angle_difference(a.body_dir, from_dir)) <= deg_to_rad(60.0)
	add_stress(a, 0.25, "hit")
	if zone == "chest" and a.plates > 0 and front:
		a.plates -= 1
		a.ticker["flinch_until"] = maxf(a.ticker.get("flinch_until", -1.0), t + 0.15)
		a.muzzle_dir += deg_to_rad(5.0) * (1.0 if rng.randf() < 0.5 else -1.0)
		if not a.aim.is_empty():
			a.aim["settle"] = 0.0
		if shooter.aim.get("tid", "") == a.id:
			shooter.aim["plate_seen"] = true
		emit({"type": "plate", "p": a.pos, "id": a.id, "dir": u})
		say("%s: plate stops %s's round (%d left)" % [a.id, shooter.id, a.plates], "hit")
		return
	shooter.hits += 1
	stat["hits"] += 1
	var power := 1.0
	match zone:
		"head":
			power = 1.6
			_down(a, shooter, true, "head")
		"chest":
			if rng.randf() < 0.65 or a.wounds > 0:
				_down(a, shooter, false, "chest")
			else:
				_wound(a, "chest")
		"abd":
			power = 0.9
			if rng.randf() < 0.35 or a.wounds > 0:
				_down(a, shooter, false, "abdomen")
			else:
				_wound(a, "abdomen")
		"arm":
			power = 0.6
			a.arm_hit = true
			say("%s hit in the arm" % a.id, "hit")
			if a.active == "rifle" and rng.randf() < 0.25 and not a.weapons["rifle"]["lost"]:
				a.weapons["rifle"]["lost"] = true
				say("%s drops the rifle" % a.id, "hit")
		"legs":
			power = 0.6
			a.leg_hit = true
			say("%s hit in the leg" % a.id, "hit")
			if rng.randf() < 0.2:
				a.stance_goal = Op.CROUCH
	a.ticker["stagger_until"] = t + 0.3
	if not a.aim.is_empty():
		a.aim["settle"] = 0.0
	emit({"type": "blood", "p": a.pos, "dir": u, "power": power, "zone": zone, "id": a.id, "side": side})


func _wound(a, where: String) -> void:
	a.wounds += 1
	say("%s wounded (%s)" % [a.id, where], "hit")


func _down(a, shooter, killed: bool, where: String) -> void:
	a.state = "dead" if killed else "down"
	a.stance = Op.DOWN
	a.stance_goal = Op.DOWN
	a.vel = Vector2.ZERO
	a.action = {}
	a.aim = {}
	a.sidestep = {}
	stop(a)
	a.ticker["down_t"] = t
	shooter.kills += 1
	say("%s %s (%s, by %s)" % [a.id, "KILLED" if killed else "DOWN", where, shooter.id], "kill")
	emit({"type": "down", "id": a.id, "killed": killed, "p": a.pos})
	for m in ops:
		if m.team == a.team and m.alive():
			if geom.sight_clear(m.pos, m.eye(), a.pos, 0.3):
				add_stress(m, 0.10, "friend down")


# ================================================================== per-tick integration
func _integrate(o) -> void:
	if not o.action.is_empty():
		o.action["left"] -= DT
		if o.action["left"] <= 0.0:
			_finish_action(o)
	o.stance = o.stance_goal
	var eye_rate := deg_to_rad(400.0) * DT
	var body_rate: float = deg_to_rad(o.ech["turn"]) * DT
	o.look_dir = rotate_toward(o.look_dir, o.look_goal, eye_rate)
	_move(o)
	if not o.aim.is_empty():
		o.body_dir = rotate_toward(o.body_dir, o.muzzle_dir, body_rate)
	elif o.vel.length() > 0.2:
		o.body_dir = rotate_toward(o.body_dir, o.vel.angle(), body_rate)
	elif absf(angle_difference(o.body_dir, o.look_dir)) > deg_to_rad(50.0):
		o.body_dir = rotate_toward(o.body_dir, o.look_dir, body_rate)
	if o.aim.is_empty():
		var target_dir: float = o.look_dir if o.has("ED01") else o.body_dir
		o.muzzle_dir = rotate_toward(o.muzzle_dir, target_dir, body_rate)
		if t - o.last_aim_t > 2.0:
			o.weapon_up = false
	_aim_update(o)
	if o.ticker.get("in_cover_check", -1.0) < t:
		o.ticker["in_cover_check"] = t + 0.25
		if geom.dist_to_kinds(o.pos, [Geom.COVER, Geom.WALL], 1.3) < 1.25:
			o.ticker["in_cover_t"] = t


func _passive(o) -> void:
	o.recoil *= exp(-DT / o.ech["tr"])
	if not o.alive():
		return
	if t - o.last_stress_t > 1.0 and t - o.last_enemy_seen_t > 1.0:
		o.stress = maxf(0.0, o.stress - 0.1 * DT)


func _check_end() -> void:
	var alive := [0, 0]
	for o in ops:
		if o.alive():
			alive[o.team] += 1
	if alive[0] == 0 or alive[1] == 0 or t >= TIME_LIMIT:
		over = true
		if alive[0] == 0 and alive[1] == 0:
			winner = 2
		elif alive[0] == 0:
			winner = 1
		elif alive[1] == 0:
			winner = 0
		else:
			winner = 2
		var names := ["TEAM A WINS", "TEAM B WINS", "DRAW"]
		say("%s at %.1f s. %d shots, %d hits." % [names[winner], t, stat["shots"], stat["hits"]], "end")
		for o in ops:
			say("  %s %s: %d shots, %d hits, %d down; %s" % [o.id, o.ech["name"], o.shots, o.hits, o.kills, o.state.to_upper()], "end")
