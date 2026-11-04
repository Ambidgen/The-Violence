extends RefCounted
## One operator: configuration (echelon, habits, plates) plus all runtime state.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")

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
var officer_id := ""    # department record this officer was built from ("" = not from a roster)
var vest := false       # soft armour: stops pistol rounds to the chest, not rifle rounds
var bodycam := false    # records what the officer sees (evidence; v0.7: the player's live view)
var judgment := 50      # 0-100: how fast and how well a recognized person is judged a threat
var temper := 40        # 0-100: how long the trigger stays pulled after someone gives up
var integrity := 60     # 0-100: whether reports match what happened (read by the department after the operation: statements, testimony, leaks)
var civ := false        # a civilian: nobody targets them on purpose; every bullet can hit them

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
var stress := 0.0        # raw stress for perception, accuracy, judgment, etc.
var habit_stress := 0.0  # resistance-adjusted accumulated inputs for bad-habit thresholds
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
var tracked := {}       # enemy id -> {lost_t, ready_t}: the enemies held in attention
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
var mind := ""          # which of the four brains drove it this tick (v0.8): lizard, lion, ape, wolf
var events_bad := []    # for UI: recently activated bad habits
var shots := 0
var hits := 0
var kills := 0
var room := "OUT"
var stall_done := {}    # door ids where the doorway stall/pause already happened
var ticker := {}        # misc timers keyed by name

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

# ---------------------------------------------------------------- judgment, surrender (v0.6)
var judges := false     # must decide a recognized person is a threat before firing (police rules)
var judged := {}        # person id -> {"until": t, "v": "" | "threat" | "unknown" | "civilian" | "complying"}
var misjudged := {}     # person id -> true: a civilian or someone complying wrongly judged a threat
var cleared := {}       # person id -> time judged harmless (not re-judged for a while)
var complying := false  # has given up: hands up, kneeling, weapons dropped
var arrested := false   # cuffed
var cstate := ""        # civilian: unaware, alarmed, flee, hide, freeze, comply, film
var persona := {}       # civilian: {panic, curiosity, defiance, mobility, phone}

# ---------------------------------------------------------------- planned operations (v0.7)
var squad := -1         # police squad (element) this officer was assigned to (-1: formed automatically)
var pace_cap := ""      # order: "walk" or "creep" caps movement speed
var roe_tight := false  # order Weapons tight: fire only at someone firing or pointing a weapon
var less_first := false # order Less-lethal first: a tool, not a round, on a covered man inside 4 m
var avoid_key := ""     # order Avoid: the navigation overlay this officer's paths use
var flight := 0.0       # suspect: readiness to run for it when police are close (0-1)
var hostage := false    # civilian held by captors (stays put until freed)
var captor := false     # suspect guarding hostages
var attacker := false   # event attacker: hidden in the crowd (as a civilian) until the attack
var arms := ""          # what a concealed attacker carries: "pistol" or "rifle"
var gone := false       # out of the operation: escaped over the fence, or withdrawn to the vehicles
var gone_how := ""      # "escaped" | "withdrew"
var pistols_only := false
var holding := false    # the squad is in Hold: hold-mode habits (HD01-HD20, BH21-BH27) apply

# ---------------------------------------------------------------- equipment (v0.7.5)
var kit := {}           # Equipment kit: primary, secondary, optic, armour, plates, head, gear
var gear := {}          # gear id -> uses left (flashbangs, ram, breaching rounds, shots)
var kit_speed := 1.0    # pace lost to carried weight
var helmet := false     # the special operations helmet is on and not yet spent
var helmet_ballistic := false   # a handgun-rated police helmet (v0.9.1)
var shield := false     # carries the ballistic shield
var light := false      # weapon light
var defiant := false    # will not give up when covered and challenged (a taser's job)


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
	# a department officer's stats were rolled once, at hire, and travel with the record
	if cfg.has("ech"):
		ech = (cfg["ech"] as Dictionary).duplicate(true)
	officer_id = cfg.get("officer_id", "")
	vest = cfg.get("vest", Habits.PRESET_VEST.get(echelon, false))
	bodycam = cfg.get("bodycam", false)
	judgment = int(cfg.get("judgment", Habits.PRESET_JUDGMENT.get(echelon, 50)))
	temper = int(cfg.get("temper", 40))
	integrity = int(cfg.get("integrity", 60))
	civ = cfg.get("civ", false)
	persona = cfg.get("persona", {}).duplicate()
	squad = int(cfg.get("squad", -1))
	pace_cap = cfg.get("pace", "")
	roe_tight = cfg.get("tight", false)
	less_first = cfg.get("less", false)
	avoid_key = cfg.get("avoid_key", "")
	pistols_only = cfg.get("pistols", false)
	# equipment: a kit given with the configuration, or the v0.7 issue (carbine and
	# pistol, armour from the plates and vest settings) when none is
	if cfg.has("kit"):
		kit = Equipment.normalize(cfg["kit"])
		plates_max = int(kit["plates"])
		vest = kit["armour"] == "vest"
	else:
		kit = Equipment.normalize({"primary": "" if sidearm_only else "carbine", "secondary": "service_pistol",
			"optic": "red_dot", "armour": "plates" if plates_max > 0 else ("vest" if vest else "none"),
			"plates": plates_max, "head": "none", "gear": {}})
	if kit["primary"] == "" and not cfg.get("civ", false):
		sidearm_only = true
	kit_speed = Equipment.speed_factor(kit)
	defiant = cfg.get("defiant", false)
	shield = kit["gear"].has("shield")
	light = kit["gear"].has("light")
	flight = float(cfg.get("flight", 0.0))
	hostage = cfg.get("hostage", false)
	captor = cfg.get("captor", false)
	attacker = cfg.get("attacker", false)
	arms = cfg.get("arms", "")
	if attacker:
		# hidden in the crowd: a civilian to every eye until the attack begins
		civ = true
	if civ:
		sidearm_only = false
		alert_floor = 0


func reset() -> void:
	pos = spawn
	body_dir = spawn_face
	look_dir = spawn_face
	look_goal = spawn_face
	muzzle_dir = spawn_face
	plates = plates_max
	stress = 0.0
	gear = Equipment.gear_counts(kit)
	helmet = kit["head"] == "sof_helmet"
	helmet_ballistic = kit["head"] == "ballistic_helmet"
	weapons = {
		"rifle": {"mag": wdef("rifle")["mag"], "spare": wdef("rifle")["spare"], "jam": false, "lost": false},
		"pistol": {"mag": wdef("pistol")["mag"], "spare": wdef("pistol")["spare"], "jam": false, "lost": false},
	}
	active = "rifle"
	if kit["secondary"] == "":
		weapons["pistol"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
	if sidearm_only or shield:
		weapons["rifle"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
		if not weapons["pistol"].get("none", false):
			weapons["pistol"]["spare"] += 1
		active = "pistol"
	if pistols_only and not civ:
		weapons["rifle"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
		weapons["pistol"]["spare"] += 1
		active = "pistol"
	if civ:
		weapons["rifle"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
		weapons["pistol"] = {"mag": 0, "spare": 0, "jam": false, "lost": true, "none": true}
		active = "pistol"
		cstate = "hostage" if hostage else "unaware"
	gone = false
	gone_how = ""
	# came in with rounds (v0.7.8: only they can run dry)
	var a0 := false
	for wn0 in weapons:
		var s0: Dictionary = weapons[wn0]
		if not s0.get("lost", false) and (int(s0["mag"]) > 0 or int(s0["spare"]) > 0):
			a0 = true
	ticker["armed0"] = a0
	alert = alert_floor
	alert_t = 0.0
	stress = clampf(float(ech.get("stress0", 0.0)), 0.0, 0.5)
	habit_stress = Habits.habit_stress_gain(stress, float(ech.get("resist", 0.0)))


## A good habit counts only if the operator has it and no active bad habit overrides it.
func has(gid: String) -> bool:
	return good.get(gid, false) and not suspended.has(gid)


func hb(bid: String) -> bool:
	return active_bad.has(bid)


func alive() -> bool:
	return state == "ok"


## Still in the fight: alive, not a civilian, not given up, not gone from the scene.
func fighting() -> bool:
	return state == "ok" and not civ and not complying and not gone


## A concealed attacker drops the act (v0.7): weapons out, a combatant from now on.
func reveal() -> void:
	civ = false
	cstate = ""
	weapons["pistol"] = {"mag": wdef("pistol")["mag"], "spare": wdef("pistol")["spare"] + 1, "jam": false, "lost": false}
	if arms == "rifle" or Equipment.WEAPONS.get(arms, {}).get("slot", "") == "primary":
		if Equipment.WEAPONS.has(arms):
			kit["primary"] = arms
		elif kit["primary"] == "":
			kit["primary"] = "carbine"
		weapons["rifle"] = {"mag": wdef("rifle")["mag"], "spare": wdef("rifle")["spare"], "jam": false, "lost": false}
		active = "rifle"
	else:
		active = "pistol"
	alert_floor = YELLOW
	alert = RED


## What an observer can see in this person's hands: a rifle carried, or any weapon drawn.
func shows_weapon() -> bool:
	if civ or complying:
		return false
	if weapon_up or not aim.is_empty() or alert >= YELLOW:
		return not (weapons["rifle"]["lost"] and weapons["pistol"]["lost"])
	return active == "rifle" and not weapons["rifle"]["lost"]


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


## The weapon in a slot ("rifle" = primary, "pistol" = secondary). An empty slot reads
## as the v0.7 issue so stats lookups never fail; its weapon state is marked lost.
func wdef(slot: String) -> Dictionary:
	var w_id: String = kit.get("primary" if slot == "rifle" else "secondary", "")
	if w_id == "":
		w_id = "carbine" if slot == "rifle" else "service_pistol"
	return Equipment.WEAPONS[w_id]


func wid(slot: String) -> String:
	return kit.get("primary" if slot == "rifle" else "secondary", "")


func wpn() -> Dictionary:
	return wdef(active)


## The optic on the weapon in hand (pistols have plain sights, the v0.7 baseline).
func optic() -> String:
	if active != "rifle":
		return "red_dot"
	return wpn().get("optic_fixed", kit.get("optic", "red_dot"))


## Is this person stunned (flashbang, taser, sponge round, a helmet hit)?
func stunned(now: float) -> bool:
	return ticker.get("stun_until", -1.0) > now


## Less-lethal (v0.8): eyes full of pepper (OC spray, a pepperball cloud), or in CS gas.
func blind(now: float) -> bool:
	return ticker.get("blind_until", -1.0) > now


func gassed(now: float) -> bool:
	return ticker.get("gassed_until", -1.0) > now


func masked() -> bool:
	return gear.has("gas_mask")


## Recognition time multiplier: pepper or gas in the eyes, or a mask's visor.
func vision_m(now: float) -> float:
	var m := 1.1 if masked() else 1.0
	if blind(now) or gassed(now):
		m *= 3.0
	return m


## Dispersion multiplier while blinded or gassed.
func aim_m(now: float) -> float:
	return 2.0 if blind(now) or gassed(now) else 1.0


func ws() -> Dictionary:
	return weapons[active]


func other() -> String:
	return "pistol" if active == "rifle" else "rifle"


func usable(w: String) -> bool:
	var s: Dictionary = weapons[w]
	return not s["lost"] and s["mag"] > 0 and not s["jam"]


func any_loaded() -> bool:
	return usable("rifle") or usable("pistol")


## Out of the fight for good (v0.7.8): came in with rounds, and has no rounds left in any
## weapon, no spare magazine and no top-up from a cache (HD20 takes two). A jam can be
## cleared, so it does not count.
func dry() -> bool:
	# nobody who came in unarmed runs dry (a target, a civilian in disguise, a man the
	# taser is for): only those who had rounds and have spent them
	if not ticker.get("armed0", false):
		return false
	for wn in ["rifle", "pistol"]:
		if not weapons.has(wn):
			continue
		var s: Dictionary = weapons[wn]
		if not s["lost"] and (int(s["mag"]) > 0 or int(s["spare"]) > 0):
			return false
	return not (has("HD20") and int(ticker.get("cache_used", 0)) < 2)


func busy() -> bool:
	return not action.is_empty()


func moving_speed() -> float:
	return vel.length()
