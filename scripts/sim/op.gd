extends RefCounted
## One operator: configuration (echelon, habits, plates) plus all runtime state.

const Habits = preload("res://scripts/data/habits.gd")

enum {STAND, CROUCH, DUCK, DOWN}
enum {GREEN, YELLOW, RED}
const ALERT_NAMES := ["GREEN", "YELLOW", "RED"]
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
var traits := {}        # id -> bool (physical traits such as Tinnitus)
var exp := 1            # Experience tier 1-5: enemies tracked at once
var hear := 1.0         # hearing range multiplier (static; traits change it)
var spawn := Vector2.ZERO
var spawn_face := 0.0
var el := -1            # element index within the team (fire teams of up to five)
var eslot := 0          # position within the element
var faction := 0        # who this operator fights for (team = the unit within the faction)
var name := ""          # full name, for the ledger
var rank := ""          # rank or role, for the ledger
var medic := false      # paramedic: nobody targets them, bullets still hit them
var sidearm_only := false  # untrained carry only a pistol
var alert := 1          # GREEN relaxed (weapon low or holstered), YELLOW drawn, RED engaging
var alert_t := 0.0      # when the current alert level was last raised or refreshed
var alert_floor := 0    # never relaxes below this (a tasking or the team's starting state)

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
var tracked := {}       # enemy id -> {lost_t, ready_dur, ready_at}: held in attention
var cue := {}           # enemy id -> expiry time of a teammate callout
var lkp := {}           # enemy id -> {p, t}
var heard := {}         # last enemy sound heard {p, t, kind}
var perc_phase := 0.0
var n_los := 0          # enemies in line of sight at the last perception update

var active_bad := {}    # id -> true while active
var suspended := {}     # good id -> true while overridden
var m_h := 1.0          # habit multiplier on reaction times
var bad_lo := -INF      # effective-stress band inside which no bad habit can switch
var bad_hi := -INF

# ---------------------------------------------------------------- attention (short-term memory)
## The cone of attention: short-term memory of threats that are not currently in
## sight. `mem` maps a key (an enemy id, or "@n" for a noise with no known owner)
## to a record -- see scripts/sim/memory.gd for the shape. The strongest live
## record is the operator's focus and sets the direction of the attention cone.
var mem := {}
var mem_seq := 0
var vision_half := 1.0472     # cached cone of vision half-angle (rad, 60 deg), set by world.step()
var att := {}                 # resolved attention cone for this tick {dir, half, kind, ...}
var att_boost := 0.0          # acquisition boost on the current target, 0 .. 0.35
var watched := {}             # enemy id -> true once watched die (drops the memory)

# ---------------------------------------------------------------- suppression and wounds
var suppress := 0.0           # 0..1, incoming fire you cannot answer
var suppress_t := -99.0       # when it last spiked
var bleed := 0.0              # blood lost per second
var blood := 0.0              # accumulated blood loss, 0..1 (1.0 = down)
var attacker = null           # the last operator who hit this one

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
var ix := 0             # which class of interrupt fired last tick (Brain.Ix)
var events_bad := []    # for UI: recently activated bad habits
var shots := 0
var hits := 0
var kills := 0
var room := "OUT"
var stall_done := {}    # door ids where the doorway stall/pause already happened
var ticker := {}        # misc timers keyed by name

## The ticker namespace, declared. Every key used anywhere in the simulation must
## appear here; tools/gdlint.py and tests/habits_test.gd both fail on an
## undeclared key. Keys ending in "_" are id-prefixed and matched by prefix.
## Per-*enemy* bookkeeping no longer lives here at all: it moved to `mem`
## (scripts/sim/memory.gd), which is pruned with the memory it belongs to.
const TICKER_KEYS := [
	# --- movement (owner: world._move2 / world.move_to)
	"step_d", "jam_t", "ghost_until", "prog_p", "repath_t", "prof",
	"path_fail_until", "drip_d", "sprint_s", "open_t", "open", "prog",
	"loud_t", "loud_kind",
	# --- aiming and firing (owner: world._aim_update / _start_acquire)
	"clicked", "reengage", "hold_pos_until", "stance_t", "crouch", "task_look",
	"task_look_tick", "far_dest", "far_until", "form_key", "form_p", "support_key",
	"support_p",
	# --- reactions (owner: brain._think)
	"freeze_until", "flinch_until", "last_flinch", "stagger_until", "near_t",
	"fixate_until", "fixate_p", "sweep_until", "sweep_from", "sweep_t0",
	"salient", "salient_next", "duck_action", "retreat", "investigate",
	# --- cover (owner: brain._cover_point / _find_cover)
	"cover_next", "cover_cache", "cover_dest", "cover_dest_t", "cover_wait",
	"in_cover_check", "in_cover_t",
	# --- scanning (owner: brain._scan)
	"scan_next", "ll_",
	# --- attention (owner: brain._finish_look2 / on_heard)
	"att_next", "att_until", "heard_bearing", "heard_until",
	# --- group discipline (owner: brain._go)
	"gd03_wait",
	# --- survival (owner: world._hit / _down / _passive)
	"down_t", "down_where", "down_by", "down_by_name", "down_by_fac", "melee_until",
	# --- city (owner: brain / director)
	"flag_said", "claimed_by",
	# --- tests only (owner: tests/*)
	"no_bonus",
]

# ---------------------------------------------------------------- city (endless battle)
var assault := false    # gang expansion team: may fire on rival gangs and police at will
var clearing := false   # QRF member while the QRF is clearing its search buildings
var flag_t := -999.0    # last time police saw this gang member targeting someone
var armed_t := -999.0   # last time this operator was aiming at or firing on someone
var mounted = null      # vehicle carrying this operator (out of the simulation while aboard)
var carried := false    # a casualty on a stretcher or aboard an ambulance (no bleed-out clock)
var saved := false      # reached an ambulance alive
var hot := true         # a potential enemy is near (dormancy)
var hot_next := 0.0
var dormant := false
var idle_next := 0.0
var gid := 0            # serial number in the world
var gang := false       # city: a gang member (cached from the faction)
var police := false     # city: a police officer (paramedics included)


func configure(cfg: Dictionary) -> void:
	id = cfg["id"]
	team = cfg["team"]
	slot = cfg["slot"]
	echelon = cfg["echelon"]
	ech = Habits.ECHELONS[echelon]
	good = cfg["good"].duplicate()
	bad = cfg["bad"].duplicate()
	plates_max = cfg["plates"]
	traits = cfg.get("traits", {}).duplicate()
	hear = Habits.hearing(traits)
	exp = clampi(int(cfg.get("exp", Habits.PRESET_EXP[echelon])), 1, Habits.EXP_MAX)
	spawn = cfg["pos"]
	spawn_face = cfg["face"]
	faction = int(cfg.get("faction", team))
	name = cfg.get("name", "")
	rank = cfg.get("rank", "")
	medic = cfg.get("medic", false)
	sidearm_only = cfg.get("sidearm_only", echelon == "untrained")
	alert_floor = clampi(int(cfg.get("alert", 1)), 0, 2)


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
	if sidearm_only:
		weapons["rifle"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
		weapons["pistol"]["spare"] += 1
		active = "pistol"
	alert = alert_floor
	alert_t = 0.0
	mem = {}
	mem_seq = 0
	watched = {}
	att = {}
	att_boost = 0.0
	vision_half = 1.0472
	suppress = 0.0
	suppress_t = -99.0
	bleed = 0.0
	blood = 0.0
	attacker = null


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


## Carrying capacity left: a wounded operator cannot sprint.
func cap_mode(mode: String) -> String:
	if mode == "sprint" and (wounds > 0 or blood > 0.35):
		return "run"
	return mode


func bleeding() -> bool:
	return bleed > 0.0


func suppressed() -> bool:
	return suppress > 0.05


## Does this operator have something in short-term memory worth glancing at?
## True when a live attention entry exists and no enemy is currently in sight.
func att_alert() -> bool:
	return (not att.is_empty()) and n_los == 0


func moving_speed() -> float:
	return vel.length()
