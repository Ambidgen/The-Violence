extends Node2D
## The animated figure (1.1). From directly above, as before: a flat ink torso with its
## one pale mark, a head that turns on its own, and now arms, hands and feet drawn in
## code so they can move. Walking swings the feet and the free arms; aiming puts both
## hands on the weapon and follows its traverse; each shot kicks; a reload, a door, a
## throw, cuffs or a dressing each have their own hands. A hit staggers; a fall plays
## out before the figure lies still. The injury is never drawn.
##
## Presentation only: the rig reads what the caller sets each frame (from the live
## operator or from the recorder) and never touches the simulation.

const Decals = preload("res://scripts/view/decals.gd")
const Figs = preload("res://scripts/view/crayon_figures.gd")
const CRAYON_AMBER := Color("#f0b53b")
const BOOT := Color("#141313")
## Civilians' coats, one per person (1.4: bright, so the innocent read at a glance).
const COATS := [Color("#e8722b"), Color("#3fa59a"), Color("#e7c93b"), Color("#d4577a"), Color("#6fa83f"), Color("#9a6fd1"), Color("#e6dfcd")]
const SKINS := [Color("#d6a27f"), Color("#b98262"), Color("#8a5a3e"), Color("#e8bf9c"), Color("#6e4630")]

const PX := 40.0              # world pixels per metre
const INK := Color(0.07, 0.07, 0.07)
const PAPER := Color(0.93, 0.93, 0.91)
const SHADOW := Color(0.0, 0.0, 0.0, 0.2)
const SHOULDER_L := Vector2(-2, -17)
const SHOULDER_R := Vector2(-2, 17)

## Level of detail, set by the scene from the camera: far out, the limbs throw no shadow
## and the arms lose their paper edge (fewer draw calls for big fights).
static var detail := true
## The part of the world on screen (world px), set by the scene; figures outside it skip
## their animation work.
static var view := Rect2(-1e9, -1e9, 2e9, 2e9)

# ------------------------------------------------------------------ inputs (set each frame)
var body_dir := 0.0
var muzzle_dir := 0.0
var look_dir := 0.0
var stance := 0               # 0 stand, 1 crouch, 2 duck (Op.STAND / CROUCH / DUCK)
var pose := "aim"             # see _hands()
var pose_p := 0.0             # progress through a timed action, 0..1
var pistol := false           # the weapon in hand is a handgun
var gun_shown := true
var ready_low := false        # weapon drawn but not aimed
var hollow := false           # civilians and paramedics: outline figures
var down := false

# ------------------------------------------------------------------ parts
var torso: Sprite2D
var head: Sprite2D
var gun: Sprite2D
var down_body: Sprite2D
var arms: Node2D
var look_key := ""
var limb := 5.0
var sleeve := Color(0.07, 0.07, 0.07)
var skin := Color("#d6a27f")
var rim := Color(0, 0, 0, 0)
## 1.4: what is carried but not in the hands: "rifle" slung across the back, and whether
## a handgun sits holstered at the hip (set by the caller each frame).
var slung_key := ""
var holster := false
var death_k := -1             # which of the eight deaths (-1: not killed)
var _last_dir := Vector2.ZERO
var back_gun: Sprite2D

# ------------------------------------------------------------------ animation state
var _vis_dir := 0.0
var _head_rel := 0.0
var _gun_rel := 0.0
var _scale := 0.5
var _gait := 0.0
var _stride := 0.0
var _last_pos := Vector2.INF
var _recoil := 0.0
var _kick_side := 1.0
var _stagger := Vector2.ZERO
var _twist := 0.0
var _clock := 0.0
var _fall := -1.0             # seconds into the fall (-1: not falling)
var _fall_dir := Vector2.ZERO
var _fall_from := 0.0
var _fall_to := 0.0
var _dead := false
var _seed := 0.0
var _off := Vector2.ZERO      # whole-figure offset this frame (world px)
var _sway := 0.0
var _hands: Array = [Vector2.ZERO, Vector2.ZERO]
var _feet: Array = [Vector2.ZERO, Vector2.ZERO]
var _carry := ""              # what the free hand carries: "mag", "phone", "can", "baton", ""
var _flash := 0.0             # seconds of muzzle flash left


func setup(key: String, id_seed: int) -> void:
	_seed = float(id_seed % 997) * 0.37
	torso = Sprite2D.new()
	add_child(torso)
	gun = Sprite2D.new()
	gun.centered = false
	add_child(gun)
	arms = Arms.new()
	arms.rig = self
	add_child(arms)
	head = Sprite2D.new()
	add_child(head)
	down_body = Sprite2D.new()
	down_body.visible = false
	add_child(down_body)
	back_gun = Sprite2D.new()
	back_gun.visible = false
	back_gun.show_behind_parent = true
	torso.add_child(back_gun)
	set_look(key)


func set_look(key: String) -> void:
	if key == look_key:
		return
	look_key = key
	hollow = key in ["c", "med"]
	limb = 4.5 if hollow else 5.5
	var lk: Array = Figs.look(key)
	sleeve = lk[0]
	var si := int(_seed * 1000.0)
	skin = SKINS[si % SKINS.size()]
	rim = {"a": Color(0.66, 0.78, 0.96, 0.85), "pd": Color(0.66, 0.78, 0.96, 0.85), "qrf": Color(0.66, 0.78, 0.96, 0.85),
		"patrol": Color(0.66, 0.78, 0.96, 0.85), "swat": Color(0.66, 0.78, 0.96, 0.85), "riot": Color(0.66, 0.78, 0.96, 0.85),
		"b": Color(0.9, 0.72, 0.48, 0.8), "hood": Color(0.9, 0.72, 0.48, 0.8), "leather": Color(0.9, 0.72, 0.48, 0.8),
		"workcoat": Color(0.9, 0.72, 0.48, 0.8), "track": Color(0.9, 0.72, 0.48, 0.8), "vestlook": Color(0.9, 0.72, 0.48, 0.8)}.get(key, Color(0, 0, 0, 0))
	if key == "c":
		sleeve = COATS[(si / 7) % COATS.size()]
		var m := ShaderMaterial.new()
		m.shader = preload("res://shaders/coat_tint.gdshader")
		m.set_shader_parameter("tint", sleeve)
		torso.material = m
		down_body.material = m
	else:
		torso.material = null
		down_body.material = null
	head.material = null
	if key in ["patrol", "swat", "riot", "hood", "leather", "workcoat", "track", "vestlook"]:
		# Heads and fallen bodies share the same skin tone as the animated hands.
		var skin_mat := ShaderMaterial.new()
		skin_mat.shader = preload("res://shaders/character_skin.gdshader")
		skin_mat.set_shader_parameter("skin_tone", skin)
		head.material = skin_mat
		down_body.material = skin_mat
	torso.texture = Decals.tex("op/%s_torso" % key)
	head.texture = Decals.tex("op/%s_head" % key)
	down_body.texture = Decals.tex("op/%s_down" % key) if death_k < 0 else Decals.tex("op/%s_dead%d" % [key, death_k])


func set_gun(key: String) -> void:
	var tx: Texture2D = Decals.tex(key)
	if gun.texture == tx:
		return
	gun.texture = tx
	gun.offset = Vector2(0, -tx.get_height() / 2.0)


## Kit worn on the torso (armour) or the head (helmet, mask).
func wear(tex_key: String, on_head: bool) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Decals.tex(tex_key)
	(head if on_head else torso).add_child(s)
	return s


# ------------------------------------------------------------------ events
func shot() -> void:
	_recoil = 1.0
	_kick_side = -_kick_side
	_flash = 0.07


## A round arrived from direction `dir` (world, unit vector toward the figure's back).
func hit(dir: Vector2, side: float) -> void:
	_stagger += dir * 7.0
	_twist += 0.28 * (1.0 if side >= 0.0 else -1.0)


## 1.4: the eight deaths. Octant of the killing round's travel relative to the facing
## (0: from behind, 4: from the front); with no direction known (a replay, a rebuilt
## view), one of them by the person's own seed.
func _death(dir: Vector2) -> void:
	var k: int
	if dir.length() > 0.01:
		var rel := angle_difference(_vis_dir, dir.angle())
		k = posmod(int(round(rel / (TAU / 8.0))), 8)
	else:
		k = int(_seed * 100.0) % 8
	death_k = k
	down_body.texture = Decals.tex("op/%s_dead%d" % [look_key, k])


func fall(dir: Vector2, dead: bool) -> void:
	if _fall >= 0.0 or down:
		return
	_fall = 0.0
	_dead = dead
	_last_dir = dir
	_fall_dir = dir if dir.length() > 0.01 else Vector2.from_angle(_vis_dir + PI)
	_fall_from = _vis_dir
	_fall_to = _vis_dir + (0.5 if fmod(_seed, 2.0) > 1.0 else -0.5)
	if dead:
		_death(dir)
		_fall_to = _vis_dir
	down_body.visible = true
	down_body.modulate.a = 0.0


## Already lying there when first shown (a replay, a rebuilt view): no fall.
func lie(dir_angle: float, dead: bool) -> void:
	down = true
	_dead = dead
	if dead:
		_vis_dir = dir_angle
		_death(Vector2.ZERO)
	_fall = -1.0
	torso.visible = false
	head.visible = false
	gun.visible = false
	down_body.visible = true
	down_body.modulate.a = 1.0
	down_body.rotation = dir_angle
	down_body.scale = Vector2.ONE * 0.5
	down_body.position = Vector2.ZERO
	queue_redraw()


func stand_up() -> void:
	down = false
	death_k = -1
	_dead = false
	down_body.texture = Decals.tex("op/%s_down" % look_key)
	_fall = -1.0
	torso.visible = true
	head.visible = true
	torso.modulate.a = 1.0
	head.modulate.a = 1.0
	down_body.visible = false


# ------------------------------------------------------------------ per frame
## Advance by `dt` real seconds; `world_pos` is where the figure stands (world px).
func advance(dt: float, world_pos: Vector2) -> void:
	_clock += dt
	if _last_pos == Vector2.INF:
		_last_pos = world_pos
		_vis_dir = body_dir
		_gun_rel = _rel(muzzle_dir)
	var moved: float = world_pos.distance_to(_last_pos) / PX
	_last_pos = world_pos
	if down:
		_advance_down(dt)
		return
	if _fall >= 0.0:
		_advance_fall(dt)
		return
	# gait: phase from distance covered (one full cycle every 1.3 m), amplitude from speed
	var spd: float = moved / maxf(dt, 0.001)
	if moved > 2.0:          # a jump (rewind, respawn): not a stride
		spd = 0.0
	else:
		_gait += moved * TAU / 1.3
	var want := clampf(spd / 1.6, 0.0, 1.6) if stance == 0 else clampf(spd / 1.6, 0.0, 0.7)
	_stride = lerpf(_stride, want, 1.0 - exp(-dt * 10.0))
	# turn smoothly (the simulation turns at tick rate)
	_vis_dir = lerp_angle(_vis_dir, body_dir, 1.0 - exp(-dt * 22.0))
	var head_goal := clampf(angle_difference(body_dir, look_dir), -1.15, 1.15)
	_head_rel = lerpf(_head_rel, head_goal, 1.0 - exp(-dt * 14.0))
	_gun_rel = lerpf(_gun_rel, _rel(muzzle_dir), 1.0 - exp(-dt * 26.0))
	var sc_goal := 0.5 if stance == 0 else (0.45 if stance == 1 else 0.40)
	_scale = lerpf(_scale, sc_goal, 1.0 - exp(-dt * 12.0))
	_recoil *= exp(-dt * 16.0)
	_flash = maxf(0.0, _flash - dt)
	_stagger *= exp(-dt * 9.0)
	_twist *= exp(-dt * 8.0)
	_pose_frame()
	_place_parts()
	queue_redraw()


func _rel(a: float) -> float:
	return clampf(angle_difference(body_dir, a), -1.05, 1.05)


func _advance_fall(dt: float) -> void:
	_fall += dt
	var k := clampf(_fall / 0.42, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - k, 3.0)
	# the standing figure folds toward the floor and goes
	var rot := lerp_angle(_fall_from, _fall_to, e)
	var sc := _scale * (1.0 - 0.15 * e)
	torso.rotation = rot
	torso.scale = Vector2.ONE * sc
	torso.position = _fall_dir * 6.0 * e
	torso.modulate.a = 1.0 - smoothstep(0.35, 0.8, k)
	head.position = torso.position + Vector2.from_angle(rot) * 5.0 * sc + _fall_dir * 4.0 * e
	head.scale = torso.scale
	head.modulate.a = torso.modulate.a
	gun.visible = k < 0.25
	gun.modulate.a = 1.0 - k * 4.0
	# and the figure on its side arrives in its place
	down_body.modulate.a = smoothstep(0.25, 0.75, k)
	down_body.rotation = rot
	down_body.position = _fall_dir * 9.0 * e
	down_body.scale = Vector2(lerpf(0.32, 0.5, e), lerpf(0.42, 0.5, e))
	if k >= 1.0:
		down = true
		_fall = -1.0
		torso.visible = false
		head.visible = false
		gun.visible = false
		down_body.modulate.a = 1.0
	queue_redraw()


func _advance_down(_dt: float) -> void:
	# the living breathe; the dead do not
	if not _dead:
		var b := 1.0 + 0.018 * sin(_clock * 2.1 + _seed)
		down_body.scale = Vector2(0.5, 0.5 * b)
	else:
		down_body.scale = Vector2.ONE * 0.5


func set_dead(d: bool) -> void:
	if d and death_k < 0:
		_death(_last_dir)      # bled out where they lay: the body settles into its last pose
	_dead = d


# ------------------------------------------------------------------ poses
## Where the hands and feet go this frame, in the body's frame (SVG units, +x forward,
## +y the figure's right).
func _pose_frame() -> void:
	var swing := sin(_gait) * _stride
	_off = Vector2.ZERO
	_sway = 0.05 * swing
	_carry = ""
	var breath := sin(_clock * 1.7 + _seed)
	# feet: a step cycle when moving; kneeling or squatting when low
	match stance:
		1:
			_feet = [Vector2(9, -7), Vector2(-9, 8)]
		2:
			_feet = [Vector2(6, -8), Vector2(5, 8)]
		_:
			_feet = [Vector2(13.0 * swing - 2.0, -7), Vector2(-13.0 * swing - 2.0, 7)]
	var gun_piv := Vector2(9, 3)       # the butt in the shoulder, the cheek on the stock
	var gun_rot := _gun_rel
	var gun_sx := 1.0
	var gun_a := 1.0
	var show := gun_shown
	var p := pose_p
	var L := Vector2(22, -2)
	var R := Vector2(16, 2)
	match pose:
		"aim", "breach":
			if pistol:
				gun_piv = Vector2(16, 0)
			if ready_low:
				gun_sx = 0.84
				gun_a = 0.75
				gun_piv += Vector2(-3, 0)
		"low":
			# low carry: the muzzle down at the floor ahead, so from above the weapon is
			# short, angled off the leading side, both hands on it at the waist
			gun_piv = Vector2(6, 7)
			gun_rot = 0.55 + 0.04 * swing
			gun_sx = 0.55
			L = gun_piv + Vector2.from_angle(gun_rot) * 13.0 + Vector2(0, -2)
			R = gun_piv + Vector2.from_angle(gun_rot) * 3.0
		"high":
			# high carry: the muzzle up by the face, foreshortened to a stub over the chest
			gun_piv = Vector2(7, 2) if not pistol else Vector2(12, 1)
			gun_rot = -0.12
			gun_sx = 0.38 if not pistol else 0.55
			L = gun_piv + Vector2(9, -3)
			R = gun_piv + Vector2(2, 2)
		"holstered", "unarmed":
			show = false
			L = Vector2(2 + 7.0 * swing, -20)
			R = Vector2(2 - 7.0 * swing, 20)
		"hands":
			show = false
			L = Vector2(7, -11)
			R = Vector2(7, 11)
		"cuffed":
			show = false
			L = Vector2(-15, -3)
			R = Vector2(-15, 3)
		"cuffing":
			gun_piv = Vector2.from_angle(-1.2) * 18.0
			gun_rot = 1.15
			gun_a = 0.55
			var w2 := sin(_clock * 9.0) * 1.5
			_off = Vector2(4, 0)
			L = Vector2(27, -5 + w2)
			R = Vector2(27, 5 - w2)
		"reload":
			# canted in toward the chest while the magazine changes
			var cant := 0.55 * smoothstep(0.0, 0.15, p) * (1.0 - smoothstep(0.85, 1.0, p))
			gun_rot = _gun_rel + cant
			gun_piv = Vector2(6, 3).lerp(Vector2(2, 6), cant / 0.55)
			L = _reload_hand(p)
			R = Vector2(14, 3)
			if p > 0.32 and p < 0.82:
				_carry = "mag"
		"clear":
			gun_rot = _gun_rel + 0.45 + 0.05 * sin(_clock * 30.0)
			gun_piv = Vector2(4, 4)
			R = Vector2(14, 3)
			L = Vector2(12, 1) if p < 0.4 else Vector2(16, -9).lerp(Vector2(10, -9), clampf((p - 0.4) / 0.3, 0.0, 1.0))
		"swap":
			if p < 0.55:
				var k := p / 0.55
				gun_rot = lerpf(_gun_rel, 1.15, k)
				gun_piv = gun_piv.lerp(Vector2.from_angle(-1.2) * 18.0, k)
				gun_a = lerpf(1.0, 0.55, k)
				R = Vector2(16, 2).lerp(Vector2(-1, 18), k)
				L = Vector2(22, -2).lerp(Vector2(10, -7), k)
			else:
				var k2 := (p - 0.55) / 0.45
				show = false
				R = Vector2(-1, 18).lerp(Vector2(19, 1), k2)
				L = Vector2(10, -7).lerp(Vector2(19, -1), k2)
		"throw":
			gun_piv = Vector2.from_angle(-1.0) * 14.0
			gun_rot = 0.9
			gun_a = 0.8
			L = Vector2(10, -6)
			if p < 0.55:
				R = Vector2(14, 6).lerp(Vector2(-11, 22), p / 0.55)
			elif p < 0.75:
				R = Vector2(-11, 22).lerp(Vector2(30, 7), (p - 0.55) / 0.2)
				_off = Vector2(3, 0) * ((p - 0.55) / 0.2)
			else:
				R = Vector2(30, 7).lerp(Vector2(16, 3), (p - 0.75) / 0.25)
		"ram":
			show = false
			var beat := pow(maxf(0.0, sin(_clock * 6.5)), 6.0)
			_off = Vector2(6.0 * beat - 2.0, 0)
			L = Vector2(11, -11)
			R = Vector2(11, 11)
		"kick":
			gun_piv = Vector2(16, 0) if pistol else gun_piv
			var beat2 := pow(maxf(0.0, sin(_clock * 5.0)), 4.0)
			_off = Vector2(-3.0 * beat2, 0)
			_feet[1] = Vector2(-2, 7).lerp(Vector2(26, 5), beat2)
		"door":
			gun_piv = Vector2(16, 2) if pistol else Vector2(7, 4)
			gun_rot = _gun_rel + 0.25
			gun_a = 0.85
			L = Vector2(25, -13)
			R = Vector2(14, 4)
		"treat":
			gun_piv = Vector2.from_angle(-1.2) * 18.0
			gun_rot = 1.15
			gun_a = 0.55
			var t3 := _clock * 4.0
			L = Vector2(19 + 2.0 * sin(t3), -5 + 1.5 * cos(t3))
			R = Vector2(19 + 2.0 * sin(t3 + 2.2), 5 + 1.5 * cos(t3 + 2.2))
		"spray":
			gun_piv = Vector2.from_angle(-1.2) * 18.0
			gun_rot = 1.15
			gun_a = 0.55
			L = Vector2(9, -11)
			R = Vector2(27, 4)
			_carry = "can"
		"strike":
			gun_piv = Vector2.from_angle(-1.2) * 18.0
			gun_rot = 1.15
			gun_a = 0.55
			var a := -0.9 + 1.8 * (0.5 + 0.5 * sin(_clock * 9.0))
			R = Vector2(6, 18) + Vector2.from_angle(a) * 14.0
			L = Vector2(10, -11)
			_carry = "baton"
		"stunned":
			show = gun_shown and not pistol
			gun_piv = Vector2.from_angle(-1.2) * 18.0
			gun_rot = 1.15
			gun_a = 0.5
			_off = Vector2(sin(_clock * 37.0), cos(_clock * 29.0)) * 1.2
			L = Vector2(8, -8)
			R = Vector2(8, 8)
		"blind", "gassed":
			show = false
			_off = Vector2(sin(_clock * 3.1), sin(_clock * 2.3)) * 2.0
			_sway += 0.12 * sin(_clock * 2.7)
			L = Vector2(12, -4)
			R = Vector2(12, 4)
		"flinch":
			show = gun_shown
			gun_rot = _gun_rel + 0.5
			gun_a = 0.7
			L = Vector2(6, -9)
			R = Vector2(6, 9)
		"film":
			show = false
			L = Vector2(16, -3)
			R = Vector2(16, 3)
			_carry = "phone"
		"frozen":
			show = false
			L = Vector2(5, -15)
			R = Vector2(5, 15)
	# a shot: the weapon comes back into the shoulder and settles
	if _recoil > 0.01 and show:
		var back := Vector2.from_angle(gun_rot) * -5.0 * _recoil
		gun_piv += back
		gun_rot += 0.05 * _recoil * _kick_side * (2.0 if pistol else 1.0)
		gun_sx *= 1.0 - (0.10 if pistol else 0.05) * _recoil
		_off += Vector2(-1.2 * _recoil, 0)
	# a high or low carry keeps its own hands
	if pose in ["low", "high"]:
		ready_low = false
	# hands on the weapon, where the pose holds it
	if show and pose in ["aim", "breach", "kick", "door", "flinch"]:
		var dv := Vector2.from_angle(gun_rot)
		var pv := dv.orthogonal()
		if pistol:
			R = gun_piv + dv * 2.0 + pv * 2.0
			L = gun_piv + dv * 3.0 - pv * 2.0
		else:
			R = gun_piv + dv * 6.0 + pv * 1.5
			if pose != "door":
				L = gun_piv + dv * 16.0 - pv * 2.5
	elif show and pose in ["reload", "clear"]:
		var dv2 := Vector2.from_angle(gun_rot)
		R = gun_piv + dv2 * (2.0 if pistol else 9.0) + dv2.orthogonal() * 1.5
	# breathing while still
	var still := 1.0 - clampf(_stride, 0.0, 1.0)
	_scale_mul = 1.0 + 0.012 * breath * still + 0.018 * absf(swing)
	_hands = [L, R]
	_gun_piv = gun_piv
	_gun_rot = gun_rot
	_gun_sx = gun_sx
	_gun_a = gun_a
	_gun_show = show


var _scale_mul := 1.0
var _gun_piv := Vector2.ZERO
var _gun_rot := 0.0
var _gun_sx := 1.0
var _gun_a := 1.0
var _gun_show := true


## A rifle reload: the support hand drops the magazine, goes to the pouch, comes back
## with a fresh one and returns to the handguard.
func _reload_hand(p: float) -> Vector2:
	var well := Vector2(10, 4)
	var pouch := Vector2(2, -16)
	var guard := Vector2(20, -2)
	if p < 0.2:
		return guard.lerp(well, p / 0.2)
	if p < 0.32:
		return well
	if p < 0.5:
		return well.lerp(pouch, (p - 0.32) / 0.18)
	if p < 0.6:
		return pouch
	if p < 0.82:
		return pouch.lerp(well, (p - 0.6) / 0.22)
	return well.lerp(guard, (p - 0.82) / 0.18)


func _place_parts() -> void:
	var rot := _vis_dir + _sway + _twist
	var sc := _scale * _scale_mul
	var dv := Vector2.from_angle(rot)
	torso.visible = true
	head.visible = true
	torso.rotation = rot
	torso.scale = Vector2.ONE * sc
	torso.position = _off.rotated(rot) * sc + _stagger
	var o := torso.position
	head.rotation = rot + _head_rel
	head.scale = Vector2.ONE * sc
	head.position = o + dv * 5.0 * sc
	# a long gun not in the hands rides slung across the back
	var sl := slung_key != "" and (not _gun_show or pistol)
	back_gun.visible = sl
	if sl:
		if back_gun.texture != Decals.tex(slung_key):
			back_gun.texture = Decals.tex(slung_key)
		back_gun.rotation = 0.9
		back_gun.position = Vector2(-12, 2)
	gun.visible = _gun_show and gun.texture != null
	if gun.visible:
		gun.rotation = rot + _gun_rot
		gun.position = o + _gun_piv.rotated(rot) * sc
		gun.scale = Vector2(_gun_sx, 1.0) * sc
		gun.modulate.a = _gun_a


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	if down or _fall >= 0.0:
		return      # the figure on its side carries its own shadow
	var rot := torso.rotation
	var sc := torso.scale.x
	var base := torso.position
	# shadow: torso, head and arms, offset down-right like everything else on the plan
	draw_set_transform(base + Vector2(3, 3), rot, Vector2.ONE * sc)
	if detail:
		_draw_limbs(SHADOW, true)
	draw_texture(torso.texture, -torso.texture.get_size() / 2.0, SHADOW)
	draw_set_transform(head.position + Vector2(3, 3), head.rotation, Vector2.ONE * sc)
	draw_texture(head.texture, -head.texture.get_size() / 2.0, SHADOW)
	# 1.4: a pale rim in the side's colour, so a figure reads on dark wax
	if rim.a > 0.0 and detail:
		draw_set_transform(base, rot, Vector2(sc * 1.22, sc * 1.12))
		draw_texture(torso.texture, -torso.texture.get_size() / 2.0, rim)
		draw_set_transform(head.position, head.rotation, Vector2.ONE * sc * 1.25)
		draw_texture(head.texture, -head.texture.get_size() / 2.0, rim)
	# feet, under the torso (the arms are drawn above it, by Arms)
	draw_set_transform(base, rot, Vector2.ONE * sc)
	_draw_feet(self, INK)
	arms.queue_redraw()


## Big boots, always drawn: a dark oval sticking out from under the body, toe forward.
func _draw_feet(ci: CanvasItem, col: Color) -> void:
	var fw := 7.0 if not hollow else 6.0
	for f in _feet:
		var fv: Vector2 = f + Vector2(4, 0)
		ci.draw_line(fv + Vector2(-4.5, 0), fv + Vector2(4.5, 0), col, fw)
		ci.draw_circle(fv + Vector2(4.5, 0), fw * 0.55, col)
		ci.draw_circle(fv + Vector2(-4.5, 0), fw * 0.5, col)


func _draw_limbs(col: Color, shadow: bool) -> void:
	_draw_feet(self, col)
	_draw_arms(self, col, shadow)


## The arms, drawn over the torso with a paper hairline so a hand crossing the body
## (to a pouch, to the face) still reads.
class Arms extends Node2D:
	var rig

	func _draw() -> void:
		if rig.down or rig._fall >= 0.0:
			return
		draw_set_transform(rig.torso.position, rig.torso.rotation, rig.torso.scale)
		rig._draw_arms(self, rig.INK, false)


func _draw_arms(ci: CanvasItem, col: Color, shadow: bool) -> void:
	# arms: shoulder to hand, the elbow bowed outward
	for i in 2:
		var s := SHOULDER_L if i == 0 else SHOULDER_R
		var h: Vector2 = _hands[i]
		var side := -1.0 if i == 0 else 1.0
		var mid := (s + h) * 0.5
		var n := (h - s).orthogonal().normalized()
		if n.y * side < 0.0:
			n = -n
		var c := mid + n * clampf(s.distance_to(h) * 0.22, 2.0, 7.0)
		var pts := PackedVector2Array()
		for k in 7:
			var t := float(k) / 6.0
			pts.append(s.lerp(c, t).lerp(c.lerp(h, t), t))
		if not shadow and not hollow and detail:
			ci.draw_polyline(pts, PAPER, limb + 1.6)
			ci.draw_circle(h, limb * 0.62 + 0.8, PAPER)
		ci.draw_polyline(pts, col, limb)
		var hand_r := limb * 0.62
		if pose == "hands" and not shadow:
			ci.draw_circle(h, 3.2, PAPER)
			ci.draw_arc(h, 3.2, 0.0, TAU, 12, INK, 1.4)
		else:
			ci.draw_circle(h, hand_r, col)
	if shadow:
		return
	match _carry:
		"mag":
			var mr := Rect2(_hands[0] + Vector2(-2.5, -5.5), Vector2(5, 9))
			ci.draw_rect(mr.grow(0.8), PAPER)
			ci.draw_rect(mr, Color(0.17, 0.17, 0.17))
		"phone":
			ci.draw_rect(Rect2(Vector2(15, -3), Vector2(5, 6)), INK)
			ci.draw_line(Vector2(20, 0), Vector2(40, -12), Color(0.07, 0.07, 0.07, 0.35), 1.6)
			ci.draw_line(Vector2(20, 0), Vector2(40, 12), Color(0.07, 0.07, 0.07, 0.35), 1.6)
		"can":
			ci.draw_rect(Rect2(_hands[1] + Vector2(0, -2.5), Vector2(6, 5)), Color(0.45, 0.45, 0.44))
		"baton":
			var hv: Vector2 = _hands[1]
			ci.draw_line(hv, hv + (hv - Vector2(6, 18)).normalized() * 16.0, INK, 2.6)
	# the muzzle flash: a paper starburst ringed in ink, for a few frames (no colour: the
	# only red on the page is consequence, not the gun)
	if _flash > 0.0 and _gun_show and gun.texture != null:
		var dv := Vector2.from_angle(_gun_rot)
		var mz := _gun_piv + dv * (gun.texture.get_width() * _gun_sx + 3.0)
		var star := PackedVector2Array()
		var spikes := 7
		var r0 := 9.0 * (0.6 + _flash / 0.07 * 0.4)
		for k in spikes * 2:
			var a := dv.angle() + TAU * float(k) / float(spikes * 2) + _kick_side * 0.2
			var rr := r0 if k % 2 == 0 else r0 * 0.42
			if k % 2 == 0 and absf(angle_difference(a, dv.angle())) < 0.5:
				rr *= 1.6
			star.append(mz + Vector2.from_angle(a) * rr)
		ci.draw_colored_polygon(star, CRAYON_AMBER)
		star.append(star[0])
		ci.draw_polyline(star, Color("#e8722b"), 1.6)
	# weaponless: the handgun in its holster on the right hip
	if holster and not _gun_show:
		ci.draw_rect(Rect2(Vector2(-7, 13), Vector2(9, 6)), INK)
		ci.draw_rect(Rect2(Vector2(1, 14), Vector2(4, 4)), Color("#5d3a22"))
	if pose == "cuffed":
		ci.draw_circle(Vector2(-16, 0), 3.0, PAPER)
		ci.draw_arc(Vector2(-16, 0), 3.0, 0.0, TAU, 12, INK, 1.4)
