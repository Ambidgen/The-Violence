extends RefCounted
## One operator: configuration (echelon, habits, plates) plus all runtime state.

const Habits = preload("res://scripts/data/habits.gd")

enum {STAND, CROUCH, DUCK, DOWN}
## Eye height and body zones [name, z_lo, z_hi, plan radius] per stance (bible 1.1).
## DUCK is "fully behind half cover": the eye sits below a 0.9 m sill or wall.
const STANCES := {
	STAND: {"eye": 1.65, "zones": [["legs", 0.0, 0.85, 0.16], ["abd", 0.85, 1.15, 0.18], ["chest", 1.15, 1.55, 0.20], ["head", 1.55, 1.80, 0.11]]},
	CROUCH: {"eye": 1.10, "zones": [["legs", 0.0, 0.45, 0.16], ["abd", 0.45, 0.70, 0.18], ["chest", 0.70, 1.00, 0.20], ["head", 1.00, 1.25, 0.11]]},
	DUCK: {"eye": 0.80, "zones": [["legs", 0.0, 0.30, 0.16], ["abd", 0.30, 0.50, 0.18], ["chest", 0.50, 0.72, 0.20], ["head", 0.72, 0.92, 0.11]]},
	DOWN: {"eye": 0.20, "zones": [["chest", 0.0, 0.30, 0.32]]},
}

# ---------------------------------------------------------------- config
var id := "A1"
var team := 0
var slot := 0
var echelon := "regular"
var ech: Dictionary = {}
var good := {}          # id -> bool (has the habit)
var bad := {}           # id -> bool (habit present)
var plates_max := 0
var spawn := Vector2.ZERO
var spawn_face := 0.0

# ---------------------------------------------------------------- runtime
var pos := Vector2.ZERO
var vel := Vector2.ZERO
var body_dir := 0.0
var look_dir := 0.0
var look_goal := 0.0
var muzzle_dir := 0.0
var stance := STAND
var stance_goal := STAND
var state := "ok"       # ok | down | dead
var wounds := 0
var arm_hit := false
var leg_hit := false
var stress := 0.0
var last_stress_t := -99.0
var plates := 0
var weapons := {}       # "rifle"/"pistol" -> {mag, spare, jam, lost}
var active := "rifle"
var recoil := 0.0
var weapon_up := false
var last_aim_t := -99.0

var rec := {}           # enemy id -> recognition progress 0..1+
var vis := {}           # enemy id -> {los, head_only, ecc, dist}
var first_rec := {}     # enemy id -> time first recognized
var cue := {}           # enemy id -> expiry time of a teammate callout
var lkp := {}           # enemy id -> {p, t}
var perc_phase := 0.0

var active_bad := {}    # id -> true while active
var suspended := {}     # good id -> true while overridden
var m_h := 1.0          # habit multiplier on reaction times

var action := {}        # current blocking action {type, left, ...}
var aim := {}           # aiming state
var path := PackedVector2Array()
var path_i := 0
var goal := Vector2.INF
var goal_mode := ""
var repath_t := 0.0
var moving := false
var speed := 0.0
var look_hint := {}     # {dir, until, why}
var sidestep := {}      # PF07 lateral step state
var freeze_add := 0.0   # BH01 delay added to next time on target
var hide_until := -1.0  # BH13
var last_exposure := Vector2.INF
var last_contact_t := -99.0
var last_shot_t := -99.0
var last_enemy_seen_t := -99.0
var reloaded_after_contact := true
var dbg := ""           # short text describing what the brain is doing
var events_bad := []    # for UI: recently activated bad habits
var shots := 0
var hits := 0
var kills := 0
var room := "OUT"
var stall_done := {}    # door ids where the doorway stall/pause already happened
var ticker := {}        # misc timers keyed by name


func configure(cfg: Dictionary) -> void:
	id = cfg["id"]
	team = cfg["team"]
	slot = cfg["slot"]
	echelon = cfg["echelon"]
	ech = Habits.ECHELONS[echelon]
	good = cfg["good"].duplicate()
	bad = cfg["bad"].duplicate()
	plates_max = cfg["plates"]
	spawn = cfg["pos"]
	spawn_face = cfg["face"]


func reset() -> void:
	pos = spawn
	body_dir = spawn_face
	look_dir = spawn_face
	look_goal = spawn_face
	muzzle_dir = spawn_face
	plates = plates_max
	stress = 0.0
	weapons = {
		"rifle": {"mag": Habits.WEAPONS["rifle"]["mag"], "spare": Habits.WEAPONS["rifle"]["spare"], "jam": false, "lost": false},
		"pistol": {"mag": Habits.WEAPONS["pistol"]["mag"], "spare": Habits.WEAPONS["pistol"]["spare"], "jam": false, "lost": false},
	}
	active = "rifle"


## A good habit counts only if the operator has it and no active bad habit overrides it.
func has(gid: String) -> bool:
	return good.get(gid, false) and not suspended.has(gid)


func hb(bid: String) -> bool:
	return active_bad.has(bid)


func alive() -> bool:
	return state == "ok"


func eye() -> float:
	return STANCES[stance]["eye"]


func zones() -> Array:
	return STANCES[stance]["zones"]


func zone_at(z: float) -> Array:
	for zn in zones():
		if z >= zn[1] and z <= zn[2]:
			return zn
	return []


func zone_centre(zone: String) -> float:
	for zn in zones():
		if zn[0] == zone:
			return (zn[1] + zn[2]) * 0.5
	var all: Array = zones()
	return (all[0][1] + all[-1][2]) * 0.5


func zone_radius(zone: String) -> float:
	for zn in zones():
		if zn[0] == zone:
			return zn[3]
	return 0.2


func wpn() -> Dictionary:
	return Habits.WEAPONS[active]


func ws() -> Dictionary:
	return weapons[active]


func other() -> String:
	return "pistol" if active == "rifle" else "rifle"


func usable(w: String) -> bool:
	var s: Dictionary = weapons[w]
	return not s["lost"] and s["mag"] > 0 and not s["jam"]


func any_loaded() -> bool:
	return usable("rifle") or usable("pistol")


func busy() -> bool:
	return not action.is_empty()


func moving_speed() -> float:
	return vel.length()
