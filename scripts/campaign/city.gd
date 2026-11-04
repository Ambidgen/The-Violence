extends RefCounted
## Adapter between the official generated city and the campaign. city.json is the
## source of site names, addresses, wards, coordinates and visibility; the only
## hand-authored data here is which existing tactical layout can stand in for a site.
## Layouts are schematic, not surveyed reproductions of those buildings.

const CITY_PATH := "res://port-carrick/city.json"
# Do not reorder: existing saves store ward trust and consequences by this index.
const WARD_IDS := ["northgate", "riverside", "oldtown", "ironworks", "eastport", "kilbride"]
const SITE_TYPES := {"warrant": "WS", "gang": "GH", "barricade": "BS", "hostage": "HT", "event": "PE"}

# Only sites with a usable tactical proxy are dealt. The Bridge Street eviction is a
# historical event, not a recurring call; indoor gatherings and vertical/yard sites
# need their own layouts before they can be added. Maps 00, 02, 07 and 09 remain in
# the test range, not falsely pinned to a city site.
const SITE_LAYOUTS := {
	"front-st-flat": {"type": "warrant", "map": 5},
	"foundry-row-warrant": {"type": "warrant", "map": 5},
	"heights-villa": {"type": "warrant", "map": 6},
	"mill-squat": {"type": "gang", "map": 8},
	"riverside-homes-block": {"type": "gang", "map": 10},
	"warehouse-row-7": {"type": "gang", "map": 8},
	"brass-rail": {"type": "barricade", "map": 3},
	"floodwall-shed": {"type": "barricade", "map": 1},
	"bluff-rd-bungalow": {"type": "barricade", "map": 4},
	"harlan-ave-bungalow": {"type": "barricade", "map": 4},
	"yard-office": {"type": "hostage", "map": 8},
	"kilbride-corner-store": {"type": "hostage", "map": 3},
	"wharf-st-flat": {"type": "hostage", "map": 5},
	"civic-plaza-rally": {"type": "event", "map": 11},
}

static var _cached: Dictionary = {}
static var _attempted := false


## A small retained subset: the full building table is not needed at runtime. A bad
## or missing city is reported once; callers use an explicitly unlocated fallback.
static func data() -> Dictionary:
	if not _attempted:
		_attempted = true
		_cached = read_city(CITY_PATH)
		if _cached.has("error"):
			push_warning("Port Carrick city data: " + String(_cached["error"]))
	return _cached


static func read_city(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"error": "Cannot open %s. Include the generated city.json in the project/export." % path}
	var parser := JSON.new()
	var err := parser.parse(f.get_as_text())
	f.close()
	if err != OK or not (parser.data is Dictionary):
		return {"error": "Invalid city JSON in %s." % path}
	return adapt(parser.data)


## Validate the contract we consume rather than assuming the JSON's old validation
## report is still current. Kept public so malformed/edited models can be tested.
static func adapt(doc: Dictionary) -> Dictionary:
	var meta = doc.get("meta", {})
	var wards = doc.get("wards", {})
	var sites = doc.get("sites", [])
	if not (meta is Dictionary) or not (wards is Dictionary) or not (sites is Array):
		return {"error": "City needs meta, wards and sites."}
	var frame = meta.get("frame", {})
	if not (frame is Dictionary) or not (frame.get("extent", null) is Array):
		return {"error": "City needs its coordinate frame and extent."}
	var extent: Array = frame["extent"]
	if extent.size() != 4:
		return {"error": "City extent must have four coordinates."}
	for coordinate in extent:
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
			return {"error": "City extent contains a non-finite coordinate."}
	if float(extent[2]) <= float(extent[0]) or float(extent[3]) <= float(extent[1]):
		return {"error": "City extent is empty or inverted."}
	var ward_polygons := {}
	for ward_id in WARD_IDS:
		if not wards.has(ward_id) or not (wards[ward_id] is Array) or wards[ward_id].is_empty():
			return {"error": "City is missing ward geometry for %s." % ward_id}
		var polygons: Array = []
		for ring in wards[ward_id]:
			if not (ring is Array) or ring.size() < 3:
				return {"error": "City has an invalid ward polygon for %s." % ward_id}
			var polygon := PackedVector2Array()
			for point in ring:
				if not (point is Array) or point.size() < 2:
					return {"error": "City has an invalid ward point for %s." % ward_id}
				for coordinate in point.slice(0, 2):
					if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
						return {"error": "City has a non-finite ward point for %s." % ward_id}
				polygon.append(Vector2(float(point[0]), float(point[1])))
			polygons.append(polygon)
		ward_polygons[ward_id] = polygons
	var found := {}
	var usable: Array = []
	for raw in sites:
		if not (raw is Dictionary):
			return {"error": "A city site is not an object."}
		var id := String(raw.get("id", ""))
		if id == "" or found.has(id):
			return {"error": "City site IDs must be non-empty and unique: %s." % id}
		found[id] = true
		if not SITE_LAYOUTS.has(id):
			continue
		var layout: Dictionary = SITE_LAYOUTS[id]
		var game_type := String(layout["type"])
		var ward_id := String(raw.get("ward", ""))
		var visibility = raw.get("visibility", null)
		if String(raw.get("type", "")) != SITE_TYPES[game_type] or not WARD_IDS.has(ward_id):
			return {"error": "Site %s has an incompatible type or ward." % id}
		if not (visibility is int or visibility is float) or int(visibility) < 1 or int(visibility) > 5 or float(visibility) != float(int(visibility)):
			return {"error": "Site %s has an invalid visibility." % id}
		if String(raw.get("name", "")) == "" or String(raw.get("address", "")) == "" or String(raw.get("archetype", "")) == "" or not (raw.get("x") is int or raw.get("x") is float) or not (raw.get("y") is int or raw.get("y") is float):
			return {"error": "Site %s needs a name, address and coordinates." % id}
		var x := float(raw["x"])
		var y := float(raw["y"])
		if not is_finite(x) or not is_finite(y) or x < float(extent[0]) or x > float(extent[2]) or y < float(extent[1]) or y > float(extent[3]):
			return {"error": "Site %s lies outside the city coordinate frame." % id}
		var inside_ward := false
		for polygon in ward_polygons[ward_id]:
			if Geometry2D.is_point_in_polygon(Vector2(x, y), polygon):
				inside_ward = true
				break
		if not inside_ward:
			return {"error": "Site %s lies outside its ward %s." % [id, ward_id]}
		var site: Dictionary = raw.duplicate(true)
		site["game_type"] = game_type
		site["map"] = int(layout["map"])
		usable.append(site)
	for id in SITE_LAYOUTS:
		if not found.has(id):
			return {"error": "City is missing mapped site %s." % id}
	usable.sort_custom(func(a, b): return String(a["id"]) < String(b["id"]))
	return {"version": String(meta.get("version", "unknown")), "sites": usable,
		"wards": wards, "water": doc.get("water", {}), "streets": doc.get("streets", []),
		"extent": extent}


## A separate RNG means site selection never consumes the operation's random stream.
## Exclude already-dealt sites, falling back only if every compatible site was used.
static func pick_site(game_type: String, seed_val: int, excluded: Array = []) -> Dictionary:
	var candidates: Array = []
	var all: Array = []
	for site in data().get("sites", []):
		if site["game_type"] != game_type:
			continue
		all.append(site)
		if not excluded.has(site["id"]):
			candidates.append(site)
	if candidates.is_empty():
		candidates = all
	if candidates.is_empty():
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val * 47 + 31337
	return candidates[rng.randi() % candidates.size()].duplicate(true)
