extends SceneTree
## Character art, role selection, and replay regression. Run after Godot imports assets:
##   godot --headless --path . -s res://tests/character_assets_test.gd

const Palette = preload("res://scripts/view/palette.gd")
const Figs = preload("res://scripts/view/crayon_figures.gd")
const Rig = preload("res://scripts/view/rig.gd")
const Decals = preload("res://scripts/view/decals.gd")
const Replay = preload("res://scripts/view/replay_view.gd")
const ActorView = preload("res://scripts/view/actor_view.gd")
const Recorder = preload("res://scripts/sim/recorder.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")
const Teams = preload("res://tests/teams.gd")

const LOOKS := ["patrol", "swat", "riot", "hood", "leather", "workcoat", "track", "vestlook"]
const PARTS := ["torso", "head", "stand", "down", "dead0", "dead1", "dead2", "dead3", "dead4", "dead5", "dead6", "dead7"]
var failures := 0


class FakeOp:
	var id := "B1"
	var team := 1
	var slot := 0
	var faction := 1
	var civ := false
	var attacker := false
	var medic := false
	var judges := false
	var police := false
	var echelon := "patrol"
	var kit := {}


class FakeWorld:
	var city := false
	var event := {}
	var factions := [{"police": true}, {"police": false}]
	var teams := [{}, {}]
	var seed_used := 721
	var rng := RandomNumberGenerator.new()


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var o := FakeOp.new()
	var w := FakeWorld.new()
	o.team = 0
	o.faction = 0
	o.judges = true
	check(Palette.look(o, w) == "patrol", "an ordinary officer wears patrol uniform")
	o.kit = {"armour": "plates", "head": "none"}
	check(Palette.look(o, w) == "swat", "tactical armour selects the SWAT uniform")
	o.kit = {"armour": "none", "head": "ballistic_helmet"}
	check(Palette.look(o, w) == "swat", "a helmeted officer gets a SWAT look outside public events")
	w.event = {"attack_t": -1}
	check(Palette.look(o, w) == "riot", "public-event officers use the riot uniform")
	w.event = {}
	o.kit = {}
	w.city = true
	w.teams[0] = {"kind": "qrf"}
	check(Palette.look(o, w) == "swat", "city quick-response units use the SWAT look")
	o.medic = true
	check(Palette.look(o, w) == "pmed", "police paramedics retain their recognizable appearance")
	o.medic = false
	o.judges = false
	o.team = 1
	o.faction = 1
	var city_looks := {}
	for fi in range(1, 5):
		o.faction = fi
		city_looks[Palette.look(o, w)] = true
	check(city_looks.size() == 4, "the four city gangs retain distinct clothing families")
	w.city = false
	var choices := {}
	w.rng.seed = 987
	var before := w.rng.state
	for k in 30:
		o.id = "B%d" % (k + 1)
		choices[Palette.look(o, w)] = true
	check(choices.size() == Palette.CRIMINAL_LOOKS.size(), "campaign suspects use all five criminal models")
	check(w.rng.state == before and Palette.look(o, w) == Palette.look(o, w), "appearance selection is stable and does not consume simulation RNG")
	o.civ = true
	o.attacker = true
	check(Palette.look(o, w) == "c" and Palette.look(o, w, true) in Palette.CRIMINAL_LOOKS,
		"a concealed attacker looks civilian until the reveal")
	w.teams.append({"members": [1, 2]})
	o.slot = 0
	var alias0 := Palette.display_id(o, w)
	o.slot = 1
	check(alias0 == "C3" and Palette.display_id(o, w) == "C4", "concealed labels do not collide with real civilian IDs or each other")
	o.attacker = false
	check(Palette.look(o, w, true) == "c", "ordinary civilians never receive a criminal look")
	o.civ = false
	w.factions[0]["police"] = false
	check(Palette.look(o, w) == "b", "non-police test-range teams retain their original look")

	var complete := true
	var animated := true
	for style in LOOKS:
		complete = complete and Figs.LOOK.has(style)
		for part in PARTS:
			var key := "op/%s_%s" % [style, part]
			complete = complete and FileAccess.file_exists("res://assets/svg/%s.svg" % key)
			for frame in 3:
				complete = complete and FileAccess.file_exists("res://assets/crayon/%s_%d.png" % [key, frame])
			var texture: Texture2D = Decals.tex(key)
			if not (texture is AnimatedTexture) or texture.frames != 3:
				animated = false
			else:
				for frame in 3:
					animated = animated and texture.get_frame_texture(frame) != null
	check(complete, "every model has a vector source and three frames for standing, downed and all eight deaths")
	check(animated and Decals.tex("kit/riot_head") is AnimatedTexture, "all character parts and the riot visor load as animated textures")
	var actor := Rig.new()
	root.add_child(actor)
	actor.setup("patrol", 41)
	for style in LOOKS:
		actor.set_look(style)
		check(actor.torso.texture != null and actor.head.texture != null and actor.down_body.texture != null and actor.head.material != null,
			"the animated rig can wear %s with matching skin" % style)
	actor.queue_free()

	# Exercise real world/recorder wiring: a concealed B1, an armed police officer,
	# and the same entries seen after the attack, rather than only testing a mock.
	var lv = Maps.get_level(0)
	var nav = Nav.new()
	nav.build(lv)
	var a: Array = Teams.team(lv, 0, {"n": 1, "ech": "patrol"})
	var b: Array = Teams.team(lv, 1, {"n": 1, "ech": "untrained"})
	a[0]["kit"] = {"primary": "carbine", "secondary": "service_pistol", "armour": "vest", "head": "ballistic_helmet", "gear": {"shield": 1, "ram": 1}}
	var civilian: Dictionary = b[0].duplicate(true)
	civilian["id"] = "C1"
	civilian["team"] = 2
	civilian["faction"] = 2
	civilian["slot"] = 0
	civilian["civ"] = true
	b[0]["attacker"] = true
	b[0]["arms"] = "pistol"
	b[0]["kit"] = {"primary": "", "secondary": "service_pistol", "armour": "vest", "head": "none", "gear": {}}
	var world = World.new()
	world.setup(lv, nav, a + b + [civilian], ["assault", "hold"], 1234, [1, 1], {"police_rules": true, "event": {"attack_t": -1}})
	var live := ActorView.new()
	root.add_child(live)
	live.setup(world.by_id["A1"], world)
	check(live.rig.look_key == "riot" and live.helmet != null and live.helmet.texture == Decals.tex("kit/riot_head") and live.shield != null,
		"the live officer wears a riot visor and shield only when equipped")
	var live_attacker := ActorView.new()
	root.add_child(live_attacker)
	live_attacker.setup(world.by_id["B1"], world)
	check(live_attacker.armour != null and not live_attacker.armour.visible and live_attacker.label.text == "C2",
		"a disguised attacker's vest and suspect ID are hidden live")
	var recorder = Recorder.new(world)
	var entries: Array = recorder.state_at(0.0)
	var first_a: Dictionary = entries.filter(func(e): return e["id"] == "A1")[0]
	var first_b: Dictionary = entries.filter(func(e): return e["id"] == "B1")[0]
	var replay := Replay.new()
	root.add_child(replay)
	check(first_a["info"]["look"] == "riot" and (int(first_a["flags"]) & 2048) != 0,
		"the recorder captures the riot look and equipped helmet state")
	check(replay._look(first_b) == "c" and first_b["info"]["look"] in Palette.CRIMINAL_LOOKS,
		"a replay does not reveal a disguised attacker prematurely")
	replay.setup(recorder, false)
	replay.show_at(0.0)
	var sprite: Dictionary = replay.sprites["A1"]
	check(replay.sprites["B1"]["armour"] != null and not replay.sprites["B1"]["armour"].visible and replay.sprites["B1"]["label"].text == live_attacker.label.text,
		"a disguised attacker's equipment and ID remain hidden in replay")
	check(sprite["rig"].look_key == "riot" and sprite["helmet"] != null and sprite["shield"] != null and sprite["ram"] != null,
		"replay constructs the same uniform and equipped accessories")
	world.by_id["B1"].reveal()
	live_attacker.sync(true)
	check(live_attacker.armour.visible and live_attacker.rig.look_key in Palette.CRIMINAL_LOOKS and live_attacker.label.text == "B1",
		"the live attacker reveals clothing, equipment and ID")
	world.by_id["A1"].helmet_ballistic = false
	world.t = 1.0
	recorder.snap()
	var after: Array = recorder.state_at(1.0)
	var after_a: Dictionary = after.filter(func(e): return e["id"] == "A1")[0]
	var after_b: Dictionary = after.filter(func(e): return e["id"] == "B1")[0]
	check(replay._look(after_b) == Palette.look(world.by_id["B1"], world) and (int(after_a["flags"]) & 2048) == 0,
		"the replay switches on reveal and records a spent helmet")
	replay.show_at(1.0)
	check(replay.sprites["B1"]["rig"].look_key == replay._look(after_b) and replay.sprites["B1"]["armour"].visible and replay.sprites["B1"]["label"].text == "B1" and is_equal_approx(sprite["helmet"].modulate.a, 0.45),
		"replayed actors update their appearance, equipment and helmet state")
	var unprotected = world.by_id["A1"]
	unprotected.kit["head"] = "none"
	unprotected.helmet_ballistic = false
	unprotected.shield = false
	unprotected.gear.erase("shield")
	var plain := ActorView.new()
	root.add_child(plain)
	plain.setup(unprotected, world)
	check(plain.rig.look_key == "riot" and plain.helmet == null and plain.shield == null,
		"riot clothing alone does not create helmet or shield equipment")
	plain.queue_free()
	replay.queue_free()
	live.queue_free()
	live_attacker.queue_free()
	world.dispose()
	await process_frame
	print("character assets: %s" % ("PASS" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)
