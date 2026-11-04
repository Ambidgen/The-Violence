extends RefCounted
## Builds operator configurations for headless tests and playtests.
## spec = {"n": 1-20, "ech": echelon, "habits": "preset"|"none"|"all", "add": [good ids],
##         "remove": [good ids], "flaws": [bad ids], "flaw_slots": [slot indices that carry
##         the flaws], "plates": optional override, "exp": Experience tier override,
##         "traits": {TR01: true, ...}}
## team() is the legacy helper: it omits `kit` and enables all stress bad habits.
## Use team_with_preset_kit() for the actual test-range equipment. That helper preserves
## the same habit defaults; set up any all-good/no-bad comparison explicitly. As in the
## test-range UI, preset validation observes Equipment.armory; test suites that want the
## full armory should set it to {} before building configurations.

const Habits = preload("res://scripts/data/habits.gd")
const Equipment = preload("res://scripts/data/equipment.gd")


static func team(lv, team_i: int, spec: Dictionary) -> Array:
	var out: Array = []
	var letter := "AB"[team_i]
	for slot in 30:
		var id := "%s%d" % [letter, slot + 1]
		var ech: String = spec.get("ech", "regular")
		var good := {}
		match spec.get("habits", "preset"):
			"preset":
				for g in Habits.preset_good(spec.get("preset_of", ech)):
					good[g] = true
			"all":
				for g in Habits.good_ids():
					good[g] = true
			"none":
				pass
		for g in spec.get("add", []):
			good[g] = true
		for g in spec.get("remove", []):
			good.erase(g)
		var bad := {}
		for b in Habits.stress_bad_ids():
			bad[b] = true
		var flaw_slots: Array = spec.get("flaw_slots", range(30))
		if slot in flaw_slots:
			for b in spec.get("flaws", []):
				bad[b] = true
		out.append({"id": id, "team": team_i, "slot": slot, "echelon": ech, "good": good, "bad": bad,
			"plates": spec.get("plates", Habits.PRESET_PLATES[ech]),
			"exp": spec.get("exp", Habits.PRESET_EXP[ech]), "traits": spec.get("traits", {}).duplicate(),
			"pos": lv.spawns[id]["p"], "face": lv.spawns[id]["face"],
			"enabled": slot < int(spec.get("n", 2))})
	return out


## Opt in to the same validated equipment preset used by the test-range UI. No changes
## to team()'s habits, enabled slots, traits, or experience. An explicit plate override
## is applied through the kit so it is not silently ignored by Op.configure().
static func team_with_preset_kit(lv, team_i: int, spec: Dictionary) -> Array:
	var out := team(lv, team_i, spec)
	for cfg in out:
		var echelon: String = cfg["echelon"]
		var kit: Dictionary = Equipment.preset(echelon)
		if spec.has("plates"):
			kit["plates"] = int(spec["plates"])
		kit = Equipment.validate(kit, Equipment.who_of_echelon(echelon))
		cfg["kit"] = kit
		cfg["plates"] = kit["plates"]
	return out
