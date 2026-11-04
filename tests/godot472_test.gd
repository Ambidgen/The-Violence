extends SceneTree
## Godot 4.7.2 compatibility regression (1.2.2). The engine's 4.7 analyzer is
## stricter than 4.4's and a few runtime paths were reachable with data the
## original code assumed could never arrive. This locks down what was fixed:
##   - the project declares the 4.7 feature tag;
##   - a save that *parses* as JSON but lost a key degrades instead of throwing
##     (SaveFile only falls back to .bak on a parse failure, not an incomplete file);
##   - an unbuilt navigator fails safely without inventing an unchecked route;
##   - version metadata stays in sync across the three generated files.
##   godot --headless --path . -s res://tests/godot472_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Department = preload("res://scripts/campaign/department.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const Nav = preload("res://scripts/sim/nav.gd")
const Version = preload("res://scripts/version.gd")

var fails := 0


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	_test_feature_tag()
	_test_version_sync()
	_test_department_bad_saves()
	_test_campaign_bad_saves()
	_test_politics_bad_saves()
	_test_nav_without_build()
	print("godot472_test: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)


## The project must advertise the engine it targets, or 4.7 offers to convert it.
func _test_feature_tag() -> void:
	var proj := FileAccess.get_file_as_string("res://project.godot")
	check(proj.contains("\"4.7\""), "project.godot declares the 4.7 feature tag")
	check(proj.contains("\"4.4\""), "project.godot keeps the 4.4 feature tag (both engines supported)")
	check(proj.contains("config_version=5"), "project.godot is still config_version 5")


func _test_version_sync() -> void:
	var project := FileAccess.get_file_as_string("res://project.godot")
	var presets := FileAccess.get_file_as_string("res://export_presets.cfg")
	check(project.contains("config/version=\"%s\"" % Version.VALUE), "project version follows Version.VALUE")
	check(presets.contains("application/file_version=\"%s\"" % Version.WINDOWS), "export file version follows Version.WINDOWS")
	check(presets.contains("application/product_version=\"%s\"" % Version.WINDOWS), "export product version follows Version.WINDOWS")


## Every one of these used to be `d["key"]`, which throws on an incomplete save.
## This is the boot path: a throw here means the game never reaches the title screen.
func _test_department_bad_saves() -> void:
	var cases := [
		["empty object", {}],
		["null officers", {"version": Department.VERSION, "officers": null}],
		["officers with a non-dictionary entry", {"version": Department.VERSION, "officers": ["junk", 7, null]}],
		["an officer record with no file", {"version": Department.VERSION, "officers": [{"id": "o1", "status": "active"}]}],
		["an officer record with a null kit", {"version": Department.VERSION, "officers": [{"id": "o1", "kit": null}]}],
		["a kit with no plates or gear", {"version": Department.VERSION, "officers": [{"id": "o1", "kit": {}}]}],
		["null bonds", {"version": Department.VERSION, "bonds": null}],
		["null notes", {"version": Department.VERSION, "notes": null}],
		["budget block with null ledger and cases", {"version": Department.VERSION, "allocation": 100, "ledger": null, "cases": null}],
		["ledger with junk entries", {"version": Department.VERSION, "allocation": 100, "ledger": ["x", 3, null]}],
	]
	for c in cases:
		var what: String = c[0]
		var data: Dictionary = c[1]
		# a valid version, so the check below is about the *shape* of the data and
		# not the version guard (which is tested separately further down)
		data["version"] = Department.VERSION
		data["seed"] = data.get("seed", 7)
		data["week"] = data.get("week", 3)
		data["serial"] = data.get("serial", 1)
		data["ops_run"] = data.get("ops_run", 0)
		var d = Department.new()
		var ok := d.from_data(data)
		check(ok, "department loads a save with " + what + " (no throw)")
		check(d.officers is Array, "  ...and still has an officers list (" + what + ")")


## Same for the campaign wrapper: `d["seed"]` and `d["department"]` were unguarded.
func _test_campaign_bad_saves() -> void:
	var good = Campaign.new()
	good.start(4242)
	check(good.dept != null and good.dept.officers.size() > 0, "a real campaign builds a department")

	# a board/past holding non-dictionary entries used to throw in _ints()
	var c = Campaign.new()
	var ok := c.from_data({
		"version": Campaign.VERSION,
		"seed": 4242,
		"department": good.dept.to_data(),
		"board": "not an array",
		"past": [null, 5, "junk"],
		"pressure": null,
		"short_history": null,
		"politics": null,
	})
	check(ok, "campaign loads with malformed board/past and a stale pressure key (no throw)")
	check(c.board is Array and c.board.is_empty(), "a non-array board degrades to empty")
	check(c.past is Array and c.past.is_empty(), "junk past entries are dropped, not loaded")
	check(c.run == null, "a save with no run block loads as a classic campaign")
	check(c.short_history is Dictionary, "a null short history degrades to {}")

	# A save with no department block at all must fail *softly*: refused, so the caller
	# can fall back to the .bak, rather than throwing before the title screen — and
	# rather than loading as an empty department, which the next save would write over
	# the backup. The previous assertion had this backwards.
	var c2 = Campaign.new()
	var ok2 := c2.from_data({"version": Campaign.VERSION, "seed": 1})
	check(not ok2, "campaign refuses a save with no department block (no throw)")

	# and the version guard still rejects the future
	var c3 = Campaign.new()
	check(not c3.from_data({"version": Campaign.VERSION + 99}), "a save from a newer version is still refused")
	var d3 = Department.new()
	check(not d3.from_data({"version": 0}), "a v0 department save is still refused")


## The same standard one layer down: Politics.from_data was the last save reader still
## indexing `d["allies"][a]["standing"]`, `press[i]["week"]` and `polls[c]` directly, so an
## incomplete save raised *after* the department had loaded cleanly.
func _test_politics_bad_saves() -> void:
	var cases := [
		["no keys at all", {}],
		["null trust, allies, polls, press", {"trust": null, "allies": null, "polls": null,
			"press": null, "pending": null, "record": null, "result": null}],
		["an ally with no standing", {"allies": {"council": {}, "union": {"standing": null}, "da": 7}}],
		["junk in the trust list", {"trust": [{}, null, "abc"]}],
		["press and pending holding junk", {"press": [null, 3, {"week": "junk"}],
			"pending": ["x", {"due": "late", "kind": "story"}]}],
		["polls with non-numbers", {"polls": {"kettering": {}, "okonjo": "abc", "pell": null}}],
		["junk record and result", {"record": {"civ_hit": "many"}, "result": "Pell won"}],
	]
	for c in cases:
		var what: String = c[0]
		var politics_data: Dictionary = c[1]
		var pol = Politics.new()
		pol.from_data(politics_data, 4242)
		# the reads every screen makes, on the data that just came back
		var stands: Array = []
		for a in Politics.ALLY_ORDER:
			stands.append(pol.standing(a))
		check(stands.size() == 4, "politics loads with " + what + " (no throw)")
		check(pol.lost("da") is bool, "  ...and a lost read (" + what + ")")
		check(pol.share("okonjo") >= 0.0, "  ...and a poll share (" + what + ")")
		check(pol.week_press(1) is Array, "  ...and the week's press (" + what + ")")
		check(pol.avg_trust() >= 0.0, "  ...and the ward average (" + what + ")")
		check(pol.trust.size() == 6, "  ...and six wards of trust (" + what + ")")
		# the campaign wrapper is the path that actually runs at boot
		var good = Campaign.new()
		good.start(4242)
		var camp = Campaign.new()
		var ok := camp.from_data({"version": Campaign.VERSION, "seed": 4242, "politics": politics_data,
			"department": good.dept.to_data(), "board": [], "past": [], "pressure": {}, "short_history": {}})
		check(ok and camp.politics != null, "campaign loads the same save with " + what + " (no throw)")
	# a missing ally key reads its default rather than raising
	var p2 = Politics.new()
	p2.from_data({"allies": {"council": {"standing": 10, "lost": true}}}, 7)
	check(p2.standing("union") == int(Politics.ALLIES["union"]["start"]), "a missing ally reads its starting standing")
	check(p2.standing("nobody") == 50, "an unknown ally id reads a default, not an error")


## A navigator that was never built used to index into an empty grids array.
func _test_nav_without_build() -> void:
	var nv = Nav.new()
	# build() not called: grids is empty on purpose
	var path: PackedVector2Array = nv._find_path(0, Vector2(1, 1), Vector2(9, 9))
	check(path.is_empty(), "an unbuilt navigator fails closed instead of inventing an unchecked route")
