extends SceneTree
## The generated city -> campaign contract, including deterministic selection,
## ward-indexed trust, old saves, schematic layouts and failure handling.
##   godot --headless --path . -s res://tests/city_integration_test.gd

const City = preload("res://scripts/campaign/city.gd")
const Situations = preload("res://scripts/campaign/situations.gd")
const Campaign = preload("res://scripts/campaign/campaign.gd")
const Maps = preload("res://scripts/maps/registry.gd")
const Autoplan = preload("res://scripts/campaign/autoplan.gd")
const SaveFile = preload("res://scripts/campaign/save_file.gd")
const CityMap = preload("res://scripts/ui/city_map.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const TEST_SAVE := "user://city_integration_test.json"

var fails := 0


class EmptyWorld:
	var ops: Array = []
	var incident = null


func check(ok: bool, what: String) -> void:
	print(("ok    " if ok else "FAIL  ") + what)
	if not ok:
		fails += 1


func _init() -> void:
	var doc = JSON.parse_string(FileAccess.get_file_as_string(City.CITY_PATH))
	check(doc is Dictionary, "the committed generator output parses")
	if not (doc is Dictionary):
		quit(1)
		return
	var city := City.data()
	check(not city.has("error") and city.get("version", "") == "0.4", "the v0.4 city contract loads")
	if city.has("error"):
		quit(1)
		return
	check(city["sites"].size() == City.SITE_LAYOUTS.size(), "every mapped site exists in the city")
	var source := {}
	for site in doc["sites"]:
		source[site["id"]] = site
	var ward_order_ok := true
	for i in City.WARD_IDS.size():
		ward_order_ok = ward_order_ok and City.WARD_IDS[i] == Situations.WARDS[i]["id"] and doc["wards"].has(City.WARD_IDS[i])
	check(ward_order_ok, "ward IDs follow the original saved trust order")
	var layouts_ok := true
	for id in City.SITE_LAYOUTS:
		var layout: Dictionary = City.SITE_LAYOUTS[id]
		layouts_ok = layouts_ok and source.has(id) and int(layout["map"]) >= 0 and int(layout["map"]) < Maps.count()
		if source.has(id):
			layouts_ok = layouts_ok and source[id]["type"] == City.SITE_TYPES[layout["type"]]
	check(layouts_ok and not City.SITE_LAYOUTS.has("bridge-st-eviction"), "mapped layouts match site types; the historical eviction is not replayed")

	var seen := {}
	var matches := true
	var generated_types := ["warrant", "gang", "barricade", "hostage", "event"]
	var trusts := [11, 22, 33, 44, 55, 66]
	for kind in generated_types:
		for seed_v in range(1, 81):
			var s := Situations.make(kind, seed_v * 101, 4, 0, trusts, true)
			var id := String(s.get("site_id", ""))
			if not source.has(id):
				matches = false
				continue
			seen[id] = true
			var src: Dictionary = source[id]
			var wi: int = City.WARD_IDS.find(String(src["ward"]))
			matches = matches and wi >= 0 and int(s["ward_i"]) == wi and s["ward"] == Situations.WARDS[wi]["name"]
			matches = matches and s["ward_id"] == src["ward"] and int(s["trust"]) == trusts[wi]
			matches = matches and s["address"] == src["address"] and s["site_name"] == src["name"]
			matches = matches and s["site_archetype"] == src["archetype"] and int(s["visibility"]) == int(src["visibility"])
			matches = matches and float(s["city_x"]) == float(src["x"]) and float(s["city_y"]) == float(src["y"])
			matches = matches and int(s["map"]) == int(City.SITE_LAYOUTS[id]["map"])
			if kind == "event":
				matches = matches and id == "civic-plaza-rally" and s["candidate"] in ["Royce Kettering", "Dana Okonjo-Vale", "Gordon Pell"]
	check(matches, "generated calls inherit the exact site, address, ward, trust, visibility and coordinates")
	check(seen.size() == City.SITE_LAYOUTS.size(), "seeded calls can reach all %d supported sites" % City.SITE_LAYOUTS.size())

	var repeatable := true
	var unique := true
	for seed_v in range(1, 41):
		var a := Situations.board(seed_v, 12, trusts, true)
		var b := Situations.board(seed_v, 12, trusts, true)
		repeatable = repeatable and JSON.stringify(a) == JSON.stringify(b)
		var ids := {}
		for s in a:
			var id: String = s.get("site_id", "")
			if id == "" or ids.has(id):
				unique = false
			ids[id] = true
	check(repeatable, "the same seed and week reproduce the same board")
	check(unique, "a board does not deal the same site twice")

	check(City.read_city("res://port-carrick/no-such-city.json").has("error"), "a missing city produces a descriptive error")
	check(City.adapt({}).has("error"), "a malformed city is rejected")
	var ward_doc := {"meta": doc["meta"], "wards": doc["wards"].duplicate(true), "sites": doc["sites"]}
	ward_doc["wards"]["northgate"] = []
	check(City.adapt(ward_doc).has("error"), "missing ward geometry is rejected")
	ward_doc["wards"] = doc["wards"].duplicate(true)
	ward_doc["wards"]["northgate"][0][0] = ["not-a-coordinate", 0]
	check(City.adapt(ward_doc).has("error"), "non-numeric ward geometry is rejected")
	var altered := {"meta": doc["meta"], "wards": doc["wards"], "sites": doc["sites"].duplicate(true)}
	for entry in altered["sites"]:
		if entry["id"] == "civic-plaza-rally":
			entry["ward"] = "not-a-ward"
	check(City.adapt(altered).has("error"), "a mapped site with an unknown ward is rejected")
	altered["sites"] = doc["sites"].duplicate(true)
	for entry in altered["sites"]:
		if entry["id"] == "civic-plaza-rally":
			entry["ward"] = "northgate"
	check(City.adapt(altered).has("error"), "a mapped site outside its named ward is rejected")
	altered["sites"] = doc["sites"].duplicate(true)
	for entry in altered["sites"]:
		if entry["id"] == "civic-plaza-rally":
			entry["x"] = 999999.0
	check(City.adapt(altered).has("error"), "a mapped site outside the coordinate frame is rejected")
	altered["sites"] = doc["sites"].duplicate(true)
	altered["sites"].append(altered["sites"][0].duplicate(true))
	check(City.adapt(altered).has("error"), "duplicate site IDs are rejected")
	altered["sites"] = doc["sites"].duplicate(true).filter(func(x): return x["id"] != "civic-plaza-rally")
	check(City.adapt(altered).has("error"), "a missing mapped site is rejected rather than invented")

	# Exercise the actual downstream fallback, not just the adapter's error value.
	var cached_city: Dictionary = City._cached
	City._cached = {"error": "test: city unavailable"}
	var unlocated_ok := true
	var unlocated_event := {}
	for kind in generated_types:
		var fallback := Situations.make(kind, 1234, 1, 0, trusts, true)
		unlocated_ok = unlocated_ok and fallback.get("city_error", false) and int(fallback["ward_i"]) == -1
		unlocated_ok = unlocated_ok and not fallback.has("site_id") and fallback["address"] == "Location unavailable" and not fallback["community"]
		if kind == "event":
			unlocated_event = fallback
	City._cached = cached_city
	check(unlocated_ok and int(unlocated_event["map"]) == 11, "all call types fall back to unlocated layouts, including the event proxy")
	var pol = Politics.new()
	pol.start(1234)
	var trust_before: Array = pol.trust.duplicate()
	pol.on_operation(1, unlocated_event, {"kind": "success", "civ_killed": 1}, EmptyWorld.new(), null)
	check(pol.trust == trust_before and String(pol.press.back()["head"]).contains("PUBLIC EVENT"), "an unlocated event changes no ward trust and its headline invents no plaza")

	var map = CityMap.new()
	map._extent = [-4000.0, -2400.0, 4000.0, 2400.0]
	map._map_rect = Rect2(10, 20, 800, 480)
	check(map._point(-4000, -2400).is_equal_approx(Vector2(10, 500)) and map._point(4000, 2400).is_equal_approx(Vector2(810, 20)),
		"the city projection preserves east and north")
	map.situations = [{"site_name": "Test site", "address": "1 Test Street", "ward": "Old Town", "city_x": -4000.0, "city_y": -2400.0}]
	check(map._get_tooltip(Vector2(10, 500)).contains("1 Test Street") and map._get_tooltip(Vector2(400, 200)) == "", "hovering a pin reveals its address, but empty map space does not")
	map.free()

	SaveFile.erase(TEST_SAVE)
	var c = Campaign.new()
	c.start(321)
	var saved_board := JSON.stringify(c.board)
	check(c.save(TEST_SAVE), "a campaign with mapped sites saves")
	var loaded = Campaign.load_from(TEST_SAVE)
	# JSON.parse_string represents all numbers as floats, including nested occupant
	# fields. Normalize both sides as JSON before comparing the complete board.
	var loaded_board := JSON.stringify(JSON.parse_string(JSON.stringify(loaded.board))) if loaded != null else ""
	check(loaded != null and loaded_board == JSON.stringify(JSON.parse_string(saved_board)), "the mapped board survives a save round trip")
	var old: Dictionary = c.to_data()
	old["version"] = 4
	for s in old["board"]:
		for key in ["site_id", "site_name", "site_archetype", "ward_id", "city_version", "city_x", "city_y"]:
			s.erase(key)
		s["address"] = "Old save address"
	var legacy = Campaign.new()
	check(legacy.from_data(old) and legacy.board[0]["address"] == "Old save address" and not legacy.board[0].has("site_id"),
		"an existing board keeps its original address and plan")
	legacy.end_week()
	check(not legacy.board.is_empty() and legacy.board[0].has("site_id"), "the next board of an older save uses canonical sites")
	c.end_week()
	check(not c.past.is_empty() and c.past[0].has("site_id") and c.past[0].has("address"), "history retains the original site and address")

	var c2 = Campaign.new()
	c2.start(832)
	var first: Dictionary = c2.board[0]
	var before := JSON.stringify(c2.dept.to_data())
	var av: Array = c2.available_for(first["id"])
	var lv = Maps.get_level(int(first["map"]))
	var plan := Autoplan.suggest(first, av, lv, c2.dept.bodycams, 6, false)
	check(not plan.is_empty() and JSON.stringify(c2.dept.to_data()) == before, "a non-purchasing plan suggestion leaves the department and kit unchanged")
	var target: Dictionary = c2.board[0]
	var officer: Dictionary = av[0]
	check(c2.canvass(target["id"], "unknown-officer").is_empty() and target["canvass"].is_empty(), "a nonexistent officer cannot canvass")
	officer["status"] = "injured"
	check(c2.canvass(target["id"], officer["id"]).is_empty() and target["canvass"].is_empty(), "an injured officer cannot canvass")
	officer["status"] = "active"
	check(c2.canvass(target["id"], officer["id"]).size() == 2 and c2.canvass(target["id"], officer["id"]).is_empty(), "a fit officer canvasses once and is committed")
	check(not c2.available_for(target["id"]).has(officer), "an officer canvassing this call cannot be re-assigned to its operation")
	var planned: Dictionary = av[1]
	target["plan"] = {"squads": [{"members": [planned["id"]]}]}
	planned["status"] = "injured"
	check(c2.canvass(target["id"], planned["id"]).is_empty() and Campaign.plan_members(target).has(planned["id"]), "a failed canvass leaves the plan intact")
	planned["status"] = "active"
	check(c2.available_for(target["id"]).has(planned), "planned members remain available while editing their own call")
	check(c2.canvass(target["id"], planned["id"]).size() == 2 and not Campaign.plan_members(target).has(planned["id"]), "a successful canvass atomically transfers an officer out of the plan")
	SaveFile.erase(TEST_SAVE)
	print("city integration: %s" % ("PASS" if fails == 0 else "%d FAILED" % fails))
	quit(1 if fails > 0 else 0)
