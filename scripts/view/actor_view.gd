extends Node2D
## One operator on the plan. Starts as a clean architectural figure; the figure itself
## (1.1) is an animated rig (rig.gd): it walks, aims, recoils, reloads, works doors and
## cuffs, staggers when hit and falls. The injury is never drawn: the consequence is on
## the floor (Decals) and in the paperwork.

const Op = preload("res://scripts/sim/op.gd")
const Decals = preload("res://scripts/view/decals.gd")
const Palette = preload("res://scripts/view/palette.gd")
const Rig = preload("res://scripts/view/rig.gd")
const PX := 40.0

const ACTION_POSE := {"reload": "reload", "transition": "swap", "clear": "clear", "check": "clear",
	"cuff": "cuffing", "open": "door", "unlock": "door", "ram": "ram", "kick": "kick", "breach_shot": "breach",
	"throw": "throw", "throw_sting": "throw", "throw_gas": "throw", "treat": "treat", "spray": "spray",
	"strike": "strike", "tase": "aim", "sponge": "aim", "pepperball": "aim", "beanbag": "aim",
	"stall": "aim", "click": "aim"}

var op
var world
var rig
var label: Label
var tag: Label
var stains: Array = []
var rng := RandomNumberGenerator.new()
var was_down := false
var gun_key := ""
var pip: Pip
var look_key := ""
var shield: Sprite2D
var ram: Sprite2D
var helmet: Sprite2D
var armour: Sprite2D
var mask: Sprite2D
var _last_hit := Vector2.ZERO


func setup(o, w) -> void:
	op = o
	world = w
	rng.seed = hash(o.id)
	var team: String = Palette.look(o, w)
	look_key = team
	rig = Rig.new()
	add_child(rig)
	rig.setup(team, hash(o.id))
	# what they carry, seen from above (v0.7.5)
	var kit: Dictionary = o.kit if "kit" in o else {}
	if kit.get("armour", "none") != "none":
		armour = rig.wear("kit/plates" if kit["armour"] == "plates" else "kit/vest", false)
		armour.visible = not o.civ
	if kit.get("head", "none") in ["sof_helmet", "ballistic_helmet"]:
		# A public-order visor is only shown when a real helmet was equipped.
		helmet = rig.wear("kit/riot_head" if team == "riot" else "kit/helmet_head", true)
		helmet.visible = not o.civ
	if o.gear.has("gas_mask"):
		mask = rig.wear("kit/gas_mask_head", true)
		mask.visible = not o.civ
	if o.shield:
		shield = Sprite2D.new()
		shield.texture = Decals.tex("kit/shield")
		shield.scale = Vector2.ONE * 0.5
		shield.visible = not o.civ
		add_child(shield)
	if int(o.gear.get("ram", 0)) > 0:
		ram = Sprite2D.new()
		ram.texture = Decals.tex("kit/ram")
		ram.scale = Vector2.ONE * 0.5
		ram.visible = not o.civ
		add_child(ram)
	pip = Pip.new()
	pip.op = o
	add_child(pip)
	label = Label.new()
	label.text = Palette.display_id(o, w)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#141313"))
	label.position = Vector2(-26, -30)
	add_child(label)
	tag = Label.new()
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#2f2e2d"))
	tag.position = Vector2(-26, 14)
	add_child(tag)
	_set_gun()
	if not o.alive():
		was_down = true
		rig.lie(o.body_dir + rng.randf_range(-0.6, 0.6), o.state == "dead")
		label.modulate.a = 0.55
		tag.text = "KIA" if o.state == "dead" else "DOWN"
	sync(true)


func _set_gun() -> void:
	var key := "op/pistol" if op.active == "pistol" else "op/rifle"
	var wid: String = op.wid(op.active) if op.has_method("wid") else ""
	if wid != "":
		key = "w/" + wid
	if key == gun_key:
		return
	gun_key = key
	rig.set_gun(key)


## A simulation event about this operator: a shot fired, a hit taken, a fall.
func event(ev: Dictionary) -> void:
	match ev["type"]:
		"shot":
			if ev.get("id", "") == op.id:
				rig.shot()
		"blood":
			var d: Vector2 = ev.get("dir", Vector2.ZERO)
			_last_hit = d
			if not was_down:
				rig.hit(d, float(ev.get("side", 1.0)))


func sync(force := false) -> void:
	if op == null:
		return
	var dt := get_process_delta_time() if not force else 0.0
	label.text = Palette.display_id(op, world)
	position = op.pos * PX
	var down: bool = not op.alive()
	if down and not was_down:
		was_down = true
		rig.fall(_last_hit, op.state == "dead")
		if shield != null:
			shield.visible = false
		if ram != null:
			ram.visible = false
		label.modulate.a = 0.55
		tag.text = "KIA" if op.state == "dead" else "DOWN"
		pip.refresh()
	if down:
		if op.state == "dead" and tag.text == "DOWN":
			tag.text = "KIA"
			rig.set_dead(true)
		if visible and (force or Rig.view.has_point(position)):
			rig.advance(dt, position)
		return
	# a concealed attacker drops the act (v0.7): redraw as who they really are
	var lk: String = Palette.look(op, world)
	if lk != look_key:
		look_key = lk
		rig.set_look(lk)
	_set_gun()
	if visible and (force or Rig.view.has_point(position)):
		_drive()
		rig.advance(dt, position)
	# A concealed attacker must not expose any carried kit; it becomes visible on reveal.
	if armour != null:
		armour.visible = not op.civ
	if mask != null:
		mask.visible = not op.civ
	if helmet != null:
		helmet.visible = not op.civ
		helmet.modulate.a = 1.0 if (op.helmet or op.helmet_ballistic) else 0.45
	if shield != null:
		shield.visible = not op.civ
		shield.rotation = op.body_dir
		shield.position = rig.torso.position + Vector2.from_angle(op.body_dir) * 13.0
	if ram != null:
		ram.visible = not op.civ
		ram.rotation = op.body_dir
		var off := Vector2.from_angle(op.body_dir + PI / 2.0) * 11.0 - Vector2.from_angle(op.body_dir) * 6.0
		ram.position = rig.torso.position + off
	pip.refresh()
	tag.text = _tag()


## What the figure is doing, as a pose for the rig.
func _drive() -> void:
	rig.body_dir = op.body_dir
	rig.muzzle_dir = op.muzzle_dir
	rig.look_dir = op.look_dir
	rig.stance = op.stance
	rig.pistol = op.active == "pistol"
	rig.gun_shown = not op.civ and not (op.active == "rifle" and op.weapons.get("rifle", {}).get("lost", false)) \
		and not (op.active == "pistol" and op.weapons.get("pistol", {}).get("lost", false))
	rig.ready_low = not (op.weapon_up or not op.aim.is_empty())
	rig.pose_p = 0.0
	var t: float = world.t if world != null else 0.0
	var pose := "aim"
	if op.civ or op.medic:
		pose = "unarmed"
		if op.civ:
			match String(op.cstate):
				"comply":
					pose = "hands"
				"film":
					pose = "film"
				"freeze":
					pose = "frozen"
				"hide":
					pose = "frozen"
	elif op.arrested:
		pose = "cuffed"
	elif op.complying:
		pose = "hands"
	elif not op.action.is_empty():
		var a: String = op.action["type"]
		pose = ACTION_POSE.get(a, "aim")
		var total: float = float(op.action.get("total", 0.0))
		if total > 0.0:
			rig.pose_p = clampf(1.0 - float(op.action.get("left", 0.0)) / total, 0.0, 1.0)
	elif world != null and op.stunned(t):
		pose = "stunned"
	elif world != null and op.gassed(t):
		pose = "gassed"
	elif world != null and op.blind(t):
		pose = "blind"
	elif world != null and op.ticker.get("flinch_until", -1.0) > t:
		pose = "flinch"
	elif op.alert == Op.GREEN and op.aim.is_empty() and not op.weapon_up:
		pose = "low" if op.active == "rifle" and rig.gun_shown else "holstered"
	if pose == "aim" and not rig.gun_shown:
		pose = "unarmed"
	# 1.4: carries. Ready but not aiming: high carry; relaxed: low carry (long gun) or
	# holstered (handgun); a long gun not in hand is slung, a handgun not in hand holstered
	if pose == "aim" and rig.ready_low:
		pose = "high"
	var has_rifle: bool = not op.civ and op.weapons.has("rifle") and not op.weapons["rifle"].get("lost", false)
	var has_pistol: bool = not op.civ and op.weapons.has("pistol") and not op.weapons["pistol"].get("lost", false)
	var rk := ""
	if has_rifle:
		var rw: String = op.wid("rifle") if op.has_method("wid") else ""
		rk = ("w/" + rw) if rw != "" else "op/rifle"
	rig.slung_key = rk if (op.active != "rifle" or pose in ["holstered", "unarmed", "hands", "cuffed", "treat"]) else ""
	rig.holster = has_pistol and (op.active != "pistol" or pose in ["holstered", "unarmed", "hands", "cuffed", "treat"])
	rig.pose = pose


func _tag() -> String:
	var t := ""
	if op.civ:
		t = {"flee": "FLEEING", "hide": "HIDING", "freeze": "FROZEN", "comply": "HANDS UP", "film": "FILMING",
			"alarmed": "!"}.get(op.cstate, "")
	elif op.arrested:
		t = "CUFFED"
	elif op.complying:
		t = "HANDS UP"
	elif not op.action.is_empty():
		var a: String = op.action["type"]
		t = {"reload": "RELOADING", "transition": "> PISTOL" if op.active == "rifle" else "> LONG GUN",
			"clear": "STOPPAGE", "check": "CHECK", "stall": "STALLS", "click": "*click*", "cuff": "CUFFING",
			"open": "OPENING", "unlock": "UNLOCKING", "ram": "RAMMING", "kick": "KICKING", "breach_shot": "BREACHING",
			"throw": "BANG OUT", "treat": "TREATING", "tase": "TASER", "sponge": "40 MM",
			"throw_sting": "STING OUT", "throw_gas": "GAS OUT", "spray": "OC SPRAY", "strike": "BATON",
			"pepperball": "PEPPERBALL", "beanbag": "BEANBAG"}.get(a, a.to_upper())
	elif world != null and op.stunned(world.t):
		t = "STUNNED"
	elif world != null and op.gassed(world.t):
		t = "GASSED"
	elif world != null and op.blind(world.t):
		t = "BLINDED"
	elif world != null and op.ticker.get("freeze_until", -1.0) > world.t:
		t = "FROZEN"
	elif world != null and op.ticker.get("flinch_until", -1.0) > world.t:
		t = "FLINCH"
	return t


## The alert pip beside the figure: green relaxed, yellow ready, red engaging.
class Pip extends Node2D:
	var op
	var lvl := -1

	func refresh() -> void:
		var want: int = -1 if (op == null or op.medic or op.civ or op.complying or not op.alive()) else clampi(op.alert, 0, 2)
		if want != lvl:
			lvl = want
			queue_redraw()

	func _draw() -> void:
		if lvl < 0:
			return
		Palette.alert_pip(self, Vector2(-14, 14), lvl)


## A hit on a standing operator (retired in v0.8: the figure is never marked).
func stain(_zone: String, _side: float) -> void:
	pass
