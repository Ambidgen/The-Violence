extends SceneTree
## Focused test-range mechanics used by test_range_study.gd, without campaign state.
##   godot --headless --path . -s res://tests/test_range_mechanics_test.gd
const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const World = preload("res://scripts/sim/world.gd")

var fails := 0


func check(ok: bool, text: String) -> void:
	print(("ok    " if ok else "FAIL  ") + text)
	if not ok:
		fails += 1


func _init() -> void:
	Equipment.armory = {}
	var lv = Maps.get_level(0)
	var nav = Nav.new()
	nav.build(lv)
	var all_good := {}
	for g in Habits.good_ids():
		all_good[g] = true
	var cfgs: Array = []
	for team in 2:
		var id := "A1" if team == 0 else "B1"
		var kit: Dictionary = Equipment.validate(Equipment.preset("sof"), "sof")
		cfgs.append({"id": id, "team": team, "slot": 0, "echelon": "sof", "good": all_good,
			"bad": {}, "traits": {}, "exp": Habits.PRESET_EXP["sof"], "plates": kit["plates"], "kit": kit,
			"pos": lv.spawns[id]["p"], "face": lv.spawns[id]["face"], "enabled": true})
	var w = World.new()
	w.keep_events = false
	w.setup(lv, nav, cfgs, ["assault", "hold"], 710001, [1, 1], {})
	var a = w.by_id["A1"]
	var b = w.by_id["B1"]
	check(a.good.size() == 60 and a.bad.is_empty() and b.good.size() == 60 and b.bad.is_empty(),
		"all-good/no-bad baseline is applied to both SOF operators")
	check(a.kit["primary"] == "sbr" and a.kit["head"] == "sof_helmet" and a.plates_max == 3 and a.gear.get("flashbang", 0) == 2,
		"the actual SOF equipment preset reaches the simulation")
	check(is_equal_approx(a.m_h, 0.8), "40 active base habits give the expected 0.80 reaction multiplier")
	check(not a.has("HD07"), "hold habits sleep on assault")
	b.holding = true
	w._update_bad(b, true)
	check(b.has("HD07"), "a hold habit can activate while defending")
	b.holding = false
	w._update_bad(b, true)
	check(not b.has("HD07"), "the hold habit sleeps when the defender stops holding")
	# Resistance slows accumulation, but sustained input can cross a threshold even
	# after raw stress saturates. Other raw-stress mechanics retain their old formula.
	a.stress = 0.0
	a.habit_stress = 0.0
	a.ech["resist"] = 0.8
	a.bad["BH06"] = true
	for i in 6:
		w.add_stress(a, 0.15, "test")
	w._update_bad(a, true)
	check(not a.hb("BH06") and a.habit_stress < 0.38, "resistance delays BH06 under moderate exposure")
	w.add_stress(a, 0.15, "test")
	w._update_bad(a, false)
	check(a.stress == 1.0 and a.hb("BH06") and not a.has("PF01") and not a.has("PF04"),
		"sustained exposure activates BH06 despite high resistance and raw-stress saturation")
	a.habit_stress = 0.30
	w._update_bad(a, false)
	check(a.hb("BH06"), "BH06 remains active inside its 0.1 hysteresis band")
	a.habit_stress = 0.27
	w._update_bad(a, false)
	check(not a.hb("BH06") and a.has("PF04"), "BH06 eases below the hysteresis band and restores PF04")
	a.bad.erase("BH06")
	w._update_bad(a, true)
	check(not a.hb("BH06") and a.has("PF01") and a.has("PF04"), "turning the bad habit off restores the good habits")
	a.bad["BH11"] = true
	a.stress = 0.0
	a.habit_stress = 0.0
	w._update_bad(a, true)
	check(a.hb("BH11") and not a.has("PF03") and not a.has("GD01"), "trait habit BH11 activates without stress and overrides its good habits")
	a.bad.erase("BH11")
	w._update_bad(a, true)
	check(a.has("PF03") and a.has("GD01"), "disabling BH11 restores the overridden habits")
	var shield_kit: Dictionary = Equipment.preset("sof")
	shield_kit["gear"]["shield"] = 1
	shield_kit = Equipment.validate(shield_kit, "sof")
	check(shield_kit["primary"] == "" and shield_kit["gear"].has("shield"), "shield loadout correctly replaces the primary weapon")
	b.shield = true
	b.body_dir = (a.pos - b.pos).angle()
	var u: Vector2 = (b.pos - a.pos).normalized()
	var chest: Array = b.zone_at(b.zone_centre("chest"))
	var plates_before: int = b.plates
	w._hit(b, chest, 0.0, u, a)
	check(int(w.stat.get("shield", 0)) == 1 and b.plates == plates_before and b.alive(), "a shield stops a frontal rifle chest hit")
	b.shield = false
	w._hit(b, chest, 0.0, u, a)
	check(b.plates == plates_before - 1 and b.alive(), "a front-facing plate stops one chest hit")
	var head: Array = b.zone_at(b.zone_centre("head"))
	w._hit(b, head, 0.0, u, a)
	check(b.alive() and not b.helmet and b.stunned(w.t), "SOF helmet stops a head hit and stuns its wearer")
	w._hit(b, head, 0.0, u, a)
	check(b.state == "dead", "a second head hit is not stopped by a spent SOF helmet")
	w.dispose()
	print("test range mechanics: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
