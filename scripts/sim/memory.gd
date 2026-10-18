extends RefCounted
## Short-term memory and the cone of attention (the "general alertness" mechanic).
##
## Every operator carries a handful of ATTENTION ENTRIES: things that have recently
## demanded their attention and whose position is only approximate.
##
##   seen    a figure that was recognized and then lost, and never watched die
##   heard   a sound (gunfire, footsteps, a reload), localised to within ~8%
##   called  a teammate's contact callout
##   fire    incoming fire: a near miss or a round into cover beside you
##
## Entries fade. The strongest entry still live is the operator's FOCUS, and the
## operator is treated as attending to it through a second cone -- the CONE OF
## ATTENTION -- which is independent of where the eyes are pointing (the cone of
## vision, `cone_half()` in world.gd). Where the two cones overlap, acquisition is
## faster:
##
##   eyes dead on the focus          -> Habits.ATT_BOOST_MAX (35%) off time on target
##   the two cones just touching     -> Habits.ATT_BOOST_MIN (7.5%)
##   no overlap, or the target lies  -> nothing
##   outside the intersection
##
## scaled linearly in between. So an operator whose eyes are already where their
## attention is acquires a target a third faster; one who has to swing both the
## eyes and the attention onto a new bearing gets almost nothing. That is the
## whole point of the mechanic: awareness is only worth something if you act on it.
##
## `mem` also replaces the old per-target `ticker` keys (confirm_/tot_/froze_/
## pf07_/assessed_/callout_), which were a string-prefixed namespace with a
## hand-maintained cleanup list in world.remove_op(). They are now fields on the
## same record as the memory itself.
##
## Everything here is static and takes the operator as an untyped argument, so
## the module has no preload cycle with op.gd.

const Habits = preload("res://scripts/data/habits.gd")

## Tolerance on the cone gates in boost(), so that a target sitting exactly on a
## cone edge counts as inside it. angle_difference() round-trips through a
## modulo and can land a single ULP outside.
const EDGE_EPS := 1e-9

const SEEN := "seen"
const HEARD := "heard"
const CALLED := "called"
const FIRE := "fire"
const KINDS := [SEEN, HEARD, CALLED, FIRE]

## Fields carried on every memory record (documented so the record has a shape).
##   kind      one of KINDS
##   p         approximate position of the threat
##   t         when the entry was last refreshed
##   str       strength 0..1 at the moment it was written
##   err       positional error in metres (heard/fire only)
##   eid       the enemy's id, or "" for a threat with no known owner
##   gone      true once the enemy has been watched die
##   confirm_t the "I have finished looking at the body" deadline (was confirm_<id>)
##   tot       true once time-on-target has been logged (was tot_<id>)
##   froze     true once BH01 has fired for this enemy (was froze_<id>)
##   pf07      true once PF07 has stepped off the X for this enemy (was pf07_<id>)
##   assessed  true once the kill has been assessed (was assessed_<id>)
##   callout_t when this enemy was last called out (was callout_<id>)


static func _rec(o, key: String) -> Dictionary:
	var m: Dictionary = o.mem
	if not m.has(key):
		m[key] = {"kind": "", "p": Vector2.ZERO, "t": -99.0, "str": 0.0, "err": 0.0,
			"eid": "" if key.begins_with("@") else key, "gone": false}
	return m[key]


## A fresh key for a threat with no known owner (a noise). Keys cycle so the
## dictionary cannot grow without bound over a long city run.
static func _anon_key(o) -> String:
	o.mem_seq += 1
	return "@" + str(o.mem_seq % 32)


## Record (or refresh) an attention entry.
static func note(o, kind: String, p: Vector2, eid: String, now: float, err := 0.0,
		strength := -1.0) -> Dictionary:
	var key: String = eid if eid != "" else _anon_key(o)
	var r := _rec(o, key)
	var base: float = strength if strength >= 0.0 else float(Habits.ATT_STRENGTH.get(kind, 0.6))
	var prev: float = salience(o, r, now)
	r["kind"] = kind
	r["p"] = p
	r["t"] = now
	r["err"] = maxf(err, 0.0)
	r["eid"] = eid
	r["gone"] = false
	r["str"] = maxf(prev, base)
	return r


## A recognized figure has slipped out of sight before being watched die. Uses
## the operator's own last-known position for that enemy.
static func note_lost(o, eid: String, now: float) -> void:
	if eid == "":
		return
	var l: Dictionary = o.lkp.get(eid, {})
	if l.is_empty():
		return
	note(o, SEEN, l["p"], eid, now, 0.0)


## The operator watched this enemy die: drop the memory instead of keeping it.
static func forget(o, eid: String) -> void:
	if eid == "":
		return
	o.mem.erase(eid)


## The enemy died out of sight. The entry is NOT dropped -- the operator keeps
## covering a man who is already dead, for as long as the entry would have
## lived. But the keeper fields (confirm_t, tot, ...) that keep a record alive
## "until the enemy does" lose their job here: the enemy already has. Strip them
## so the entry fades on its TTL like every other entry ("entries fade").
static func fade(o, eid: String) -> void:
	if eid == "" or not o.mem.has(eid):
		return
	var r: Dictionary = o.mem[eid]
	for k in KEEPERS:
		r.erase(k)


## Bookkeeping fields that keep a record alive on their own: they describe an
## enemy, and they must survive until the enemy does (or is forgotten).
const KEEPERS := ["confirm_t", "tot", "froze", "pf07", "assessed", "callout_t"]


static func _is_keeper(r: Dictionary) -> bool:
	for k in KEEPERS:
		if r.has(k):
			return true
	return false


## Drop every record whose salience has run out. Called once per operator per tick.
static func prune(o, now: float) -> void:
	var m: Dictionary = o.mem
	if m.is_empty():
		return
	var dead: Array = []
	for k in m.keys():
		var r: Dictionary = m[k]
		if bool(r.get("gone", false)):
			dead.append(k)
		elif salience(o, r, now) <= 0.0 and not _is_keeper(r):
			dead.append(k)
	for k in dead:
		m.erase(k)


## How long an entry of this kind stays alive for this operator, in seconds.
static func ttl_of(o, r: Dictionary) -> float:
	var kind: String = r["kind"]
	var base: float = float(Habits.ATT_TTL.get(kind, 15.0))
	var alert: int = clampi(int(o.alert), 0, 2)
	base *= Habits.ATT_ALERT_MUL[alert]
	if kind == SEEN or kind == CALLED:
		if o.has("ED08"):
			base *= 1.5       # holds the last-known position
		elif o.has("ED02"):
			base *= 1.4       # scans back to danger points
		if o.hb("BH12"):
			base *= 1.3       # wants to chase it
	else:
		if bool(o.traits.get("TR01", false)):
			base *= 0.6       # tinnitus: heard it, didn't place it
		if bool(o.traits.get("TR02", false)):
			base *= 1.4
		if o.has("ED07"):
			base *= 1.3       # sound cueing: turns the eyes to it and remembers it
		if o.hb("BH20"):
			base *= 0.5       # fixed scan pattern: ignores what it hears
	if o.hb("BH04"):
		base *= 1.3           # tunnel-vision lock: stuck on the one thing
	if kind == FIRE:
		base *= 1.0 - 0.4 * float(o.ech["resist"])   # steady troops settle sooner
	return maxf(base, 0.5)


## How much an entry is demanding attention right now: strength fading to zero
## over its lifetime.
static func salience(o, r: Dictionary, now: float) -> float:
	if bool(r.get("gone", false)):
		return 0.0
	var ttl: float = ttl_of(o, r)
	if ttl <= 0.0:
		return 0.0
	var age: float = now - float(r["t"])
	if age < 0.0:
		return float(r["str"])
	return float(r["str"]) * clampf(1.0 - age / ttl, 0.0, 1.0)


## The single strongest live entry, resolved into a direction and a cone.
## Empty when the operator is attending to nothing in particular.
static func focus(o, now: float) -> Dictionary:
	var m: Dictionary = o.mem
	if m.is_empty():
		return {}
	var best: Dictionary = {}
	var bs := 0.0
	var bkey := ""
	for k in m.keys():
		var r: Dictionary = m[k]
		if bool(r.get("gone", false)):
			continue
		var s: float = salience(o, r, now)
		if s <= 0.0:
			continue
		if s > bs:
			bs = s
			best = r
			bkey = k
	if best.is_empty():
		return {}
	var p: Vector2 = best["p"]
	var d: Vector2 = p - o.pos
	var dist: float = maxf(d.length(), 0.5)
	var kind: String = best["kind"]
	var half: float = deg_to_rad(float(Habits.ATT_HALF_DEG.get(kind, 30.0)))
	# a noise is only placed to within its error: the further away, the vaguer
	if kind == HEARD or kind == FIRE:
		half += atan(float(best["err"]) / dist)
	if o.hb("BH04"):
		half = minf(half, deg_to_rad(25.0))
	else:
		var eff: float = clampf(o.stress * (1.0 - float(o.ech["resist"])), 0.0, 1.0)
		var narrow: float = 0.15 if o.has("ED06") else 0.30
		half *= 1.0 - narrow * eff
		if o.has("ED06"):
			half = maxf(half, deg_to_rad(24.0))
	return {"dir": d.angle(), "half": half, "str": bs, "kind": kind, "p": p,
		"eid": best["eid"], "key": bkey, "dist": dist}


## The acquisition boost for a target on `bearing`, 0 .. ATT_BOOST_MAX.
## Zero unless the bearing lies inside BOTH cones; then scaled by how well the
## two cones are lined up with each other.
static func boost(o, bearing: float, now: float) -> float:
	# o.att is the focus resolved once per tick in world.step(); fall back to
	# resolving it here for callers outside the tick (tests, the overlay).
	var f: Dictionary = o.att
	if f.is_empty():
		f = focus(o, now)
	if f.is_empty():
		return 0.0
	var vhalf: float = float(o.vision_half)
	var ahalf: float = float(f["half"])
	# The gates are inclusive: a target sitting exactly on a cone edge is inside
	# it. angle_difference() round-trips through a modulo and can land a single
	# ULP outside, which would make the "the two cones just touching" case --
	# the one ATT_BOOST_MIN is defined at -- unreachable in principle.
	if absf(angle_difference(bearing, o.look_dir)) > vhalf + EDGE_EPS:
		return 0.0
	if absf(angle_difference(bearing, f["dir"])) > ahalf + EDGE_EPS:
		return 0.0
	var span: float = vhalf + ahalf
	if span <= 1e-6:
		return 0.0
	var u: float = clampf(absf(angle_difference(o.look_dir, f["dir"])) / span, 0.0, 1.0)
	return lerpf(Habits.ATT_BOOST_MAX, Habits.ATT_BOOST_MIN, u)


## The boost against a specific operator.
static func boost_on(o, e, now: float) -> float:
	if e == null:
		return 0.0
	var d: Vector2 = e.pos - o.pos
	if d.length_squared() < 0.01:
		return 0.0
	return boost(o, d.angle(), now)


## The attention cone itself, for the overlay: {dir, half, kind, p} or empty.
static func cone(o, now: float) -> Dictionary:
	return focus(o, now)


## Per-target bookkeeping that used to live in the string-keyed ticker bag.
static func field(o, eid: String, name: String, default):
	var m: Dictionary = o.mem
	if not m.has(eid):
		return default
	var r: Dictionary = m[eid]
	if not r.has(name):
		return default
	return r[name]


static func set_field(o, eid: String, name: String, value) -> void:
	_rec(o, eid)[name] = value


static func has_field(o, eid: String, name: String) -> bool:
	var m: Dictionary = o.mem
	if not m.has(eid):
		return false
	return (m[eid] as Dictionary).has(name)
