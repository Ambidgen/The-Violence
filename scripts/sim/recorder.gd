extends RefCounted
## The operation's record for rewind and the debrief replay (v0.7). Twice a second it
## keeps where everyone is and how they stand; between snapshots it keeps the shots,
## the falls and the shouted words. Rewinding only reads this record: the simulation
## never goes back, so rewind is a way of looking, not of changing anything.

const Palette = preload("res://scripts/view/palette.gd")

const EVERY := 15            # ticks between snapshots (2 per simulated second)
const STRIDE := 6            # floats per person: x, y, body, muzzle, state, flags

var w
var ids: Array = []          # person ids, in snapshot order
var info: Array = []         # per person: {team, civ, attacker, judges, name}
var times := PackedFloat32Array()
var data: Array = []         # PackedFloat32Array per snapshot
var shots: Array = []        # [t, from, to, police]
var downs: Array = []        # [t, id, killed, p]
var floats: Array = []       # [t, p, text]
var know := {}               # snapshot index -> {"vis": {id: true}, "lkp": [[p, t]]} (the fog view fills it)
var doors0 := {}             # door states at the start (v0.7.5): id -> "closed" | "locked"
var doors: Array = []        # [t, id, state, how]: every door opened since
var bangs: Array = []        # [t, p]: flashbangs going off
var _n := 0


func _init(world) -> void:
	w = world
	if w.level != null and w.level.has_method("door_states"):
		doors0 = w.level.door_states()
	for o in w.ops:
		ids.append(o.id)
		# Record presentation metadata separately from the simulation. The revealed
		# look is stored even for a disguised attacker; snapshot flags keep them
		# looking like a civilian until the actual reveal.
		info.append({"team": o.team, "civ": o.civ and not o.attacker, "attacker": o.attacker, "judges": o.judges,
			"name": o.name, "faction": o.faction, "primary": o.kit.get("primary", ""), "secondary": o.kit.get("secondary", ""),
			"look": Palette.look(o, w, true), "disguise_id": Palette.disguise_id(o, w) if o.attacker else "",
			"medic": o.medic, "armour": o.kit.get("armour", "none"),
			"head": o.kit.get("head", "none"), "mask": o.gear.has("gas_mask"), "shield": o.shield, "ram": int(o.gear.get("ram", 0)) > 0})
	snap()


func tick() -> void:
	_n += 1
	if _n % EVERY == 0:
		snap()


func snap() -> void:
	if w == null:
		return
	if not times.is_empty() and absf(times[times.size() - 1] - w.t) < 0.001:
		return
	var a := PackedFloat32Array()
	a.resize(ids.size() * STRIDE)
	for i in ids.size():
		var o = w.by_id.get(ids[i], null)
		if o == null:
			continue
		var st := 0.0
		if o.state == "down":
			st = 1.0
		elif o.state == "dead":
			st = 2.0
		var fl := 0
		if o.complying:
			fl |= 1
		if o.arrested:
			fl |= 2
		if o.civ:
			fl |= 4
		if o.gone:
			fl |= 8
		if o.weapon_up or not o.aim.is_empty():
			fl |= 16
		fl |= (clampi(o.stance, 0, 3) << 5)
		fl |= (clampi(o.alert, 0, 2) << 7)
		if o.active == "rifle" and not o.weapons["rifle"]["lost"]:
			fl |= 512
		if o.cstate in ["comply", "hostage", "escorted", "safe"]:
			fl |= 1024
		if o.helmet or o.helmet_ballistic:
			fl |= 2048
		var k := i * STRIDE
		a[k] = o.pos.x
		a[k + 1] = o.pos.y
		a[k + 2] = o.body_dir
		a[k + 3] = o.muzzle_dir
		a[k + 4] = st
		a[k + 5] = float(fl)
	times.append(w.t)
	data.append(a)


func on_event(ev: Dictionary) -> void:
	if w == null:
		return
	match ev["type"]:
		"shot":
			var sh = w.by_id.get(ev.get("id", ""), null)
			shots.append([w.t, ev["from"], ev["to"], sh != null and sh.judges])
		"down":
			downs.append([w.t, ev["id"], ev["killed"], ev["p"]])
		"float":
			floats.append([w.t, ev["p"], ev["text"]])
		"door":
			doors.append([w.t, ev["id"], ev["state"], ev.get("how", "")])
		"flash":
			bangs.append([w.t, ev["p"]])


func duration() -> float:
	return times[times.size() - 1] if not times.is_empty() else 0.0


## Snapshot index at or before time tt.
func index_at(tt: float) -> int:
	var lo := 0
	var hi := times.size() - 1
	if hi < 0:
		return -1
	if tt >= times[hi]:
		return hi
	while lo < hi:
		var mid := (lo + hi + 1) / 2
		if times[mid] <= tt:
			lo = mid
		else:
			hi = mid - 1
	return lo


## Everyone as they were at time tt (positions and facings interpolated).
## Returns [{id, p, body, muzzle, state, flags, info}].
func state_at(tt: float) -> Array:
	var out: Array = []
	var i0 := index_at(tt)
	if i0 < 0:
		return out
	var i1 := mini(i0 + 1, times.size() - 1)
	var a: PackedFloat32Array = data[i0]
	var b: PackedFloat32Array = data[i1]
	var f := 0.0
	if i1 != i0:
		f = clampf((tt - times[i0]) / maxf(times[i1] - times[i0], 0.001), 0.0, 1.0)
	for i in ids.size():
		var k := i * STRIDE
		var pa := Vector2(a[k], a[k + 1])
		var pb := Vector2(b[k], b[k + 1])
		var moving: bool = a[k + 4] == 0.0 and b[k + 4] == 0.0
		var p: Vector2 = pa.lerp(pb, f) if moving else pa
		out.append({"id": ids[i], "p": p, "body": lerp_angle(a[k + 2], b[k + 2], f) if moving else a[k + 2],
			"muzzle": lerp_angle(a[k + 3], b[k + 3], f) if moving else a[k + 3], "state": int(a[k + 4]),
			"flags": int(a[k + 5]), "info": info[i]})
	return out


## Shots fired between t0 and t1.
func shots_between(t0: float, t1: float) -> Array:
	var out: Array = []
	for s in shots:
		if s[0] > t1:
			break
		if s[0] >= t0:
			out.append(s)
	return out


## Door states at time tt: [states (id -> closed|locked), forced (id -> true)].
func doors_at(tt: float) -> Array:
	var st: Dictionary = doors0.duplicate()
	var br := {}
	for d in doors:
		if d[0] > tt:
			break
		if d[2] == "open":
			st.erase(d[1])
		else:
			st[d[1]] = d[2]
		if d[3] in ["ram", "kick", "breach_shot"]:
			br[d[1]] = true
	return [st, br]


func knowledge_at(tt: float) -> Dictionary:
	var i := index_at(tt)
	while i >= 0:
		if know.has(i):
			return know[i]
		i -= 1
	return {}
