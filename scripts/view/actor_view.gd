extends Node2D
## One operator on the plan. Starts as a clean architectural figure; every hit
## leaves a stain on it, and a fallen operator is redrawn lying in the pool.

const Op = preload("res://scripts/sim/op.gd")
const Decals = preload("res://scripts/view/decals.gd")
const PX := 40.0

var op
var world
var body: Sprite2D
var down_body: Sprite2D
var gun: Sprite2D
var label: Label
var tag: Label
var stains: Array = []
var rng := RandomNumberGenerator.new()
var was_down := false
var gun_key := ""


func setup(o, w) -> void:
	op = o
	world = w
	rng.seed = hash(o.id)
	var team := "a" if o.team == 0 else "b"
	gun = Sprite2D.new()
	gun.centered = false
	add_child(gun)
	body = Sprite2D.new()
	body.texture = Decals.tex("op/%s_stand" % team)
	body.scale = Vector2.ONE * 0.5
	add_child(body)
	down_body = Sprite2D.new()
	down_body.texture = Decals.tex("op/%s_down" % team)
	down_body.scale = Vector2.ONE * 0.5
	down_body.visible = false
	add_child(down_body)
	label = Label.new()
	label.text = o.id
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color("#1c1c1c"))
	label.position = Vector2(-26, -30)
	add_child(label)
	tag = Label.new()
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("#3a3a3a"))
	tag.position = Vector2(-26, 14)
	add_child(tag)
	_set_gun()
	sync(true)


func _set_gun() -> void:
	var key := "op/pistol" if op.active == "pistol" else "op/rifle"
	if key == gun_key:
		return
	gun_key = key
	gun.texture = Decals.tex(key)
	gun.scale = Vector2.ONE * 0.5
	gun.offset = Vector2(0, -gun.texture.get_height() / 2.0)


func sync(force := false) -> void:
	if op == null:
		return
	position = op.pos * PX
	var down: bool = not op.alive()
	if down and not was_down:
		was_down = true
		body.visible = false
		gun.visible = false
		down_body.visible = true
		down_body.rotation = op.body_dir + rng.randf_range(-0.6, 0.6)
		for s in stains:
			s.queue_free()
		stains.clear()
		for k in maxi(2, op.wounds + 2):
			var st := Sprite2D.new()
			st.texture = Decals.tex("fx/stain%d" % rng.randi_range(1, 3))
			st.position = Vector2(rng.randf_range(60, 125), rng.randf_range(-22, 22)) - down_body.texture.get_size() / 2.0
			st.rotation = rng.randf() * TAU
			st.scale = Vector2.ONE * rng.randf_range(0.9, 1.6)
			down_body.add_child(st)
		label.modulate.a = 0.55
		tag.text = "KIA" if op.state == "dead" else "DOWN"
		return
	if down:
		return
	body.rotation = op.body_dir
	var sc := 0.5
	if op.stance == Op.CROUCH:
		sc = 0.45
	elif op.stance == Op.DUCK:
		sc = 0.40
	body.scale = Vector2.ONE * sc
	_set_gun()
	gun.rotation = op.muzzle_dir
	gun.position = Vector2.from_angle(op.muzzle_dir) * 4.0
	gun.modulate.a = 1.0 if op.weapon_up or not op.aim.is_empty() else 0.65
	var t := ""
	if not op.action.is_empty():
		var a: String = op.action["type"]
		t = {"reload": "RELOADING", "transition": "> PISTOL" if op.active == "rifle" else "> RIFLE",
			"clear": "STOPPAGE", "check": "CHECK", "stall": "STALLS", "click": "*click*"}.get(a, a.to_upper())
	elif world != null and op.ticker.get("freeze_until", -1.0) > world.t:
		t = "FROZEN"
	elif world != null and op.ticker.get("flinch_until", -1.0) > world.t:
		t = "FLINCH"
	tag.text = t


## A hit on a standing operator: stain the figure where the round went in.
func stain(zone: String, side: float) -> void:
	if was_down:
		return
	var st := Sprite2D.new()
	st.texture = Decals.tex("fx/stain%d" % rng.randi_range(1, 3))
	var local := Vector2.ZERO
	match zone:
		"head":
			local = Vector2(2, 0)
		"chest":
			local = Vector2(-2, rng.randf_range(-10, 10))
		"abd":
			local = Vector2(-4, rng.randf_range(-6, 6))
		"arm":
			local = Vector2(4, 18.0 * side)
		_:
			local = Vector2(-6, rng.randf_range(-14, 14))
	st.position = local
	st.rotation = rng.randf() * TAU
	st.scale = Vector2.ONE * rng.randf_range(0.7, 1.1)
	body.add_child(st)
	stains.append(st)
