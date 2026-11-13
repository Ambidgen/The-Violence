extends SceneTree
## Focused regression coverage for the playtest improvements. No renderer or audio
## device is needed; run with Godot --headless --path . -s res://tests/improvements_test.gd.

const Risk = preload("res://scripts/campaign/risk.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Campaign = preload("res://scripts/campaign/campaign.gd")
const Outcome = preload("res://scripts/campaign/outcome.gd")
const Pacing = preload("res://scripts/sim/pacing.gd")
const Decals = preload("res://scripts/view/decals.gd")
const Version = preload("res://scripts/version.gd")
const Settings = preload("res://scripts/ui/settings.gd")

var failures := 0


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _init() -> void:
	_test_risk()
	_test_pacing()
	_test_ia()
	_test_score()
	_test_pools()
	_test_short_policy()
	_test_version()
	_test_version_line()
	_test_user_dir()
	_test_notices()
	print("improvements: ", "ALL OK" if failures == 0 else "%d failures" % failures)
	quit(0 if failures == 0 else 1)


func _test_risk() -> void:
	var sit: Dictionary = Situations.make("gang", 713, 2, 0)
	var officers: Array = [{"exp": 2, "judgment": 70, "kit": {"armour": "plates"}}]
	var a := Risk.assess(sit, {}, officers)
	var hidden: Dictionary = sit.duplicate(true)
	hidden["occupants"] = []
	hidden["attack"] = true
	hidden["attack_t"] = 1
	var b := Risk.assess(hidden, {}, officers)
	check(a == b, "risk must not read hidden occupants or attack state")
	check(int(a["low"]) >= 0 and int(a["high"]) <= 100 and int(a["low"]) <= int(a["high"]), "risk is a bounded range")
	var larger: Array = officers.duplicate(true)
	for i in 5:
		larger.append({"exp": 2, "judgment": 70, "kit": {"armour": "plates"}})
	var c := Risk.assess(sit, {}, larger)
	check(int(c["low"]) > int(a["low"]), "assigned force improves readiness")
	check(not String(a["label"]).contains("%"), "readiness is not a win percentage")


func _test_pacing() -> void:
	check(Pacing.event_reason({"type": "shot"}) == "shots fired", "shot triggers contact pacing")
	check(Pacing.event_reason({"type": "down"}) == "casualty", "down triggers casualty pacing")
	check(Pacing.event_reason({"type": "casing"}) == "", "cosmetic events do not trigger pacing")
	check(Pacing.event_reason({"type": "less", "hit": true}) == "contact", "less-lethal contact triggers pacing")
	check(Pacing.log_reason({"kind": "comms", "text": "A1: contact at the kitchen"}) == "important radio", "contact radio triggers pacing")
	check(Pacing.log_reason({"kind": "comms", "text": "A1: moving to the hallway"}) == "", "routine radio does not trigger pacing")
	check(Pacing.log_reason({"kind": "hit", "text": "A1 wounded (chest)"}) == "casualty", "injury radio triggers casualty pacing")
	check(Pacing.log_reason({"kind": "hit", "text": "B2 hurt by the baton"}) == "casualty", "less-lethal injury radio triggers casualty pacing")
	check(Pacing.hold_seconds("casualty") > Pacing.hold_seconds("shots fired"), "casualties hold long enough to read")
	check(Pacing.speed_for(8.0, 10.0, 12.0, true) == 1.0, "contact hold caps playback at 1x")
	check(Pacing.speed_for(8.0, 12.0, 12.0, true) == 8.0, "requested speed resumes after quiet")
	check(Pacing.speed_for(8.0, 10.0, 12.0, false) == 8.0, "adaptive playback is optional")


func _test_ia() -> void:
	var cases: Array = [
		{"id": "IA-1", "kind": "broke_order", "strength": "video", "week": 1, "status": "open"},
		{"id": "IA-2", "kind": "excessive_force", "strength": "witness", "week": 1, "status": "open"},
		{"id": "IA-3", "kind": "civilian_hit_by_police", "strength": "heard", "week": 1, "status": "open"},
		{"id": "IA-4", "kind": "excessive_force", "strength": "video", "week": 2, "status": "open"},
		{"id": "IA-5", "kind": "civilian_hit_by_police", "strength": "video", "week": 2, "status": "closed"},
	]
	var sorted := Department.sorted_open_cases(cases, 3)
	check(sorted.map(func(c): return c["id"]) == ["IA-3", "IA-4", "IA-2", "IA-1"], "IA severity then evidence ordering")
	check(Department.case_is_urgent(cases[0], 3), "IA due-soon threshold")
	var triage := Department.case_triage(cases, 4)
	check(triage["open"] == 4 and triage["grave"] == 3 and triage["video"] == 2 and triage["urgent"] == 4, "IA weekly triage counts")
	check(cases[0]["status"] == "open" and not cases[4].has("decision"), "IA sorting does not decide cases")


func _test_score() -> void:
	var w := FakeWorld.new()
	w.incident = FakeIncident.new()
	w.attack_on = true
	w.incident.summary_data = {"officers_killed": 1, "civ_killed": 2, "officers_down": 4, "civ_hit_police": 0}
	var res := Outcome.evaluate({"type": "event", "named": ""}, w)
	var sum := 0
	for p in res["score_parts"]:
		if not p.get("total", false):
			sum += int(p["amount"])
	check(res["score"] == 5 and sum == res["score"], "itemized score arithmetic and nonfatal downs")
	w.incident.summary_data = {"officers_killed": 8, "civ_killed": 4, "officers_down": 8, "civ_hit_police": 0}
	var floor_res := Outcome.evaluate({"type": "event", "named": ""}, w)
	check(floor_res["score"] == 0 and floor_res["score_raw"] < 0, "score floor is explicit")


func _test_pools() -> void:
	var rng := RandomNumberGenerator.new()
	var maker = Decals.new()
	rng.seed = 4401
	for n in 100:
		var shape := PackedFloat32Array()
		for i in 11:
			shape.append(rng.randf_range(0.72, 1.12))
		var rot := rng.randf() * TAU
		var outer := maker.pool_points(Vector2(30, 40), 18.0, rot, shape, 1.0)
		var inner := maker.pool_points(Vector2(30, 40), 18.0, rot, shape, 0.58)
		var ot := Geometry2D.triangulate_polygon(outer)
		var it := Geometry2D.triangulate_polygon(inner)
		check(ot.size() == (shape.size() - 2) * 3, "outer pool triangulation %d" % n)
		check(it.size() == (shape.size() - 2) * 3, "inner pool triangulation %d" % n)
		for i in shape.size():
			var ao := (outer[i] - Vector2(30, 40)).angle()
			var ai := (inner[i] - Vector2(30, 40)).angle()
			check(absf(angle_difference(ao, ai)) < 0.0001, "shared angular pool samples")
	maker.free()


func _test_short_policy() -> void:
	var c := Campaign.new()
	c.dept = Department.new()
	c.dept.week = 1
	check(c.claim_short("s06_officer_down"), "first consequential short allowed")
	check(not c.claim_short("s06_officer_down"), "same short cannot repeat")
	check(not c.claim_short("s09_case"), "ordinary shorts respect cooldown")
	check(c.claim_short("s11_election", true), "election can override cooldown")
	c.dept.week = 4
	check(c.claim_short("s09_case"), "a new short is allowed after cooldown")
	check(not c.claim_short("s09_case", true), "force cannot bypass per-key repetition limit")


## P0.D1: 1.3.x is the Early Access line, and the title and credits say so.
func _test_version_line() -> void:
	var v := Version.VALUE.split(".")
	check(v.size() == 3 and v[0] == "1" and v[1] == "3", "the tree is on the 1.3 Early Access line (%s)" % Version.VALUE)
	check(Version.CHANNEL == "Early Access", "the version line names its channel (%s)" % Version.CHANNEL)
	var front := FileAccess.get_file_as_string("res://scripts/ui/front.gd")
	check(front.contains("Version.CHANNEL") and front.contains("CHANNEL.to_upper()"),
		"the title corner prints the channel from Version.CHANNEL")
	for bit in ["THIRD_PARTY_NOTICES", "all rights reserved", "not finished"]:
		check(front.contains(bit), "the credits mention \"%s\"" % bit)


## P0.D4: the saves live in one fixed directory, and older folders are still carried.
func _test_user_dir() -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	check(project.contains("config/use_custom_user_dir=true"), "project.godot sets a custom user directory")
	check(project.contains('config/custom_user_dir_name="%s"' % Settings.USER_DIR),
		"and its name matches Settings.USER_DIR (%s)" % Settings.USER_DIR)
	var dirs: Array = Settings.legacy_dirs()
	check(dirs.size() >= 3 and String(dirs[0]).ends_with(Settings.OLD_DIR), "the original slice folder is still carried across")
	check(dirs.any(func(d): return String(d).ends_with("/The Violence")), "so is the folder the project name derived")
	check(dirs.any(func(d): return String(d).ends_with("/" + Settings.USER_DIR)), "and the fixed directory is recognised as current")
	check(Settings.CARRY.has("legacy.json"), "the legacy file (unlocked doctrines) is carried too")


## P0.D2: the licence and the third-party notices exist, and the export ships them.
func _test_notices() -> void:
	var lic := FileAccess.get_file_as_string("res://LICENSE")
	var notices := FileAccess.get_file_as_string("res://THIRD_PARTY_NOTICES")
	check(lic.length() > 500 and lic.contains("All rights reserved"), "LICENSE states the licence (all rights reserved)")
	check(lic.contains("THIRD_PARTY_NOTICES"), "LICENSE points at the third-party notices")
	check(notices.contains("Godot Engine contributors") and notices.contains("SIL OPEN FONT LICENCE"),
		"THIRD_PARTY_NOTICES carries the engine (MIT) and the font (OFL)")
	check(notices.contains("Remotion") and notices.contains("free"), "and records the Remotion position (P0.D3)")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	# String.split() returns a PackedStringArray, which has no filter(): wrap it (CI
	# caught exactly this as a parse error on 4.7.2 — the static audit cannot).
	var lines: Array = Array(presets.split("\n"))
	var includes: Array = lines.filter(func(l): return String(l).begins_with("include_filter"))
	var ships: Array = includes.filter(func(l): return String(l).contains("LICENSE") and String(l).contains("THIRD_PARTY_NOTICES"))
	check(includes.size() >= 2 and ships.size() == includes.size(),
		"every export preset ships LICENSE and THIRD_PARTY_NOTICES (%d of %d)" % [ships.size(), includes.size()])


func _test_version() -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(project.contains("config/version=\"%s\"" % Version.VALUE), "project version follows Version.VALUE")
	check(presets.contains("application/file_version=\"%s\"" % Version.WINDOWS), "export file version follows Version.WINDOWS")
	check(presets.contains("application/product_version=\"%s\"" % Version.WINDOWS), "export product version follows Version.WINDOWS")


class FakeIncident extends RefCounted:
	var summary_data := {}
	func summary() -> Dictionary:
		return summary_data


class FakeWorld extends RefCounted:
	var incident
	var ops: Array = []
	var teams: Array = []
	var broken: Array = []
	var aborted := false
	var attack_on := false
	var stood_down := false
	var t := 10.0
