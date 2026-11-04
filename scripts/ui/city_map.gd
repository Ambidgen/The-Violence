extends Control
## Campaign board overview. This draws the generator's actual ward polygons, river,
## basins and major roads; pins use the coordinates saved with each situation. It is
## an overview, not the tactical floor plan, and does not change simulation state.

const City = preload("res://scripts/campaign/city.gd")
const Ink = preload("res://scripts/view/ink.gd")
const PAPER := Color("#e6dfcd")
const CHARCOAL := Color("#302d2b")
const WATER := Color("#83939a")
const ROAD := Color("#a99a81")
const WARD_COLORS := [Color("#d8c9a8"), Color("#cfbea5"), Color("#dbc9a4"),
	Color("#c8b39c"), Color("#d3bc9d"), Color("#d5c8a7")]
# Label positions are cartographic annotations only, in the generator's metre frame.
const LABELS := {
	"northgate": [0.0, 2000.0], "riverside": [-2300.0, 650.0], "oldtown": [0.0, 620.0],
	"ironworks": [-2000.0, -1250.0], "eastport": [3000.0, -1200.0], "kilbride": [1050.0, -1200.0]
}

var situations: Array = []
var trust: Array = []
var week := 1
var _extent: Array = []
var _map_rect := Rect2()
var _ink_rev := -1


func show_city(board: Array, ward_trust: Array, current_week: int) -> void:
	situations = board
	trust = ward_trust
	week = current_week
	visible = true
	queue_redraw()


func _process(_delta: float) -> void:
	if visible and _ink_rev != Ink.rev:
		_ink_rev = Ink.rev
		queue_redraw()


func _point(x: float, y: float) -> Vector2:
	var xmin: float = float(_extent[0])
	var ymin: float = float(_extent[1])
	var xmax: float = float(_extent[2])
	var ymax: float = float(_extent[3])
	return Vector2(_map_rect.position.x + (x - xmin) / (xmax - xmin) * _map_rect.size.x,
		_map_rect.end.y - (y - ymin) / (ymax - ymin) * _map_rect.size.y)


## Native Control tooltip, using the same projection as the drawn pins.
func _get_tooltip(at_position: Vector2) -> String:
	if _extent.size() != 4:
		return ""
	var nearest := -1
	var distance := 14.0
	for i in situations.size():
		var s: Dictionary = situations[i]
		if not s.has("city_x") or not s.has("city_y"):
			continue
		var d := _point(float(s["city_x"]), float(s["city_y"])).distance_to(at_position)
		if d <= distance:
			distance = d
			nearest = i
	if nearest < 0:
		return ""
	var s: Dictionary = situations[nearest]
	return "%d. %s\n%s\n%s" % [nearest + 1, s.get("site_name", s.get("title", "Call")),
		s.get("address", "Location unavailable"), s.get("ward", "Unknown ward")]


func _points(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for xy in raw:
		if xy is Array and xy.size() >= 2:
			out.append(_point(float(xy[0]), float(xy[1])))
	return out


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	var font: Font = ThemeDB.fallback_font
	draw_string(font, Vector2(36, 47), "PORT CARRICK  /  WEEK %d" % week, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, CHARCOAL)
	draw_string(font, Vector2(37, 72), "CITY FILE  ·  ward trust and this week's calls", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, CHARCOAL)
	var city := City.data()
	if city.has("error"):
		draw_string(font, Vector2(37, 112), "City map unavailable. Check port-carrick/city.json.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CHARCOAL)
		return
	_extent = city.get("extent", [])
	if _extent.size() != 4 or float(_extent[2]) <= float(_extent[0]) or float(_extent[3]) <= float(_extent[1]):
		return
	var available := Vector2(maxf(1.0, size.x - 76.0), maxf(1.0, size.y - 175.0))
	var aspect := (float(_extent[2]) - float(_extent[0])) / (float(_extent[3]) - float(_extent[1]))
	var w := minf(available.x, available.y * aspect)
	var h := w / aspect
	_map_rect = Rect2(Vector2((size.x - w) * 0.5, 96.0 + (available.y - h) * 0.5), Vector2(w, h))
	draw_rect(_map_rect, Color("#eee6d5"))
	var wards: Dictionary = city.get("wards", {})
	for i in City.WARD_IDS.size():
		var id: String = City.WARD_IDS[i]
		for polygon in wards.get(id, []):
			if not (polygon is Array):
				continue
			var pts := _points(polygon)
			if pts.size() >= 3:
				draw_colored_polygon(pts, WARD_COLORS[i])
				draw_polyline(pts, Color("#998b78"), 1.0, true)
	var water: Dictionary = city.get("water", {}) if city.get("water", {}) is Dictionary else {}
	for polygon in water.get("river", []):
		if not (polygon is Array):
			continue
		var pts := _points(polygon)
		if pts.size() >= 3:
			draw_colored_polygon(pts, WATER)
	var basins = water.get("basins", {})
	if basins is Dictionary:
		for basin in basins.values():
			if not (basin is Dictionary) or not (basin.get("rect", []) is Array):
				continue
			var r: Array = basin.get("rect", [])
			if r.size() == 4:
				var a := _point(float(r[0]), float(r[1]))
				var b := _point(float(r[2]), float(r[3]))
				draw_rect(Rect2(Vector2(minf(a.x, b.x), minf(a.y, b.y)), Vector2(absf(a.x - b.x), absf(a.y - b.y))), WATER)
	for street in city.get("streets", []):
		if not (street is Dictionary) or not (street.get("pts", []) is Array):
			continue
		if not String(street.get("cls", "")) in ["A", "B", "C", "M", "Q", "S"]:
			continue
		var pts := _points(street.get("pts", []))
		if pts.size() >= 2:
			draw_polyline(pts, ROAD, 1.0, true)
	draw_rect(_map_rect, CHARCOAL, false, 1.0)
	for i in City.WARD_IDS.size():
		var id: String = City.WARD_IDS[i]
		var xy: Array = LABELS[id]
		var pos := _point(float(xy[0]), float(xy[1]))
		var value := "  %d" % int(trust[i]) if i < trust.size() else ""
		var name: String = "OLD TOWN" if id == "oldtown" else id.to_upper()
		draw_string(font, pos + Vector2(-55, 0), name + value, HORIZONTAL_ALIGNMENT_CENTER, 110, 12, CHARCOAL)
	var unlocated := 0
	for i in situations.size():
		var s: Dictionary = situations[i]
		if not s.has("city_x") or not s.has("city_y"):
			unlocated += 1
			continue
		var pos := _point(float(s["city_x"]), float(s["city_y"]))
		var ink := Ink.accent(1.0) if s.get("status", "open") == "open" else Color("#6f6b61")
		draw_circle(pos, 12.0, ink)
		draw_arc(pos, 12.0, 0.0, TAU, 24, CHARCOAL, 1.0, true)
		draw_string(font, pos + Vector2(-11, 5), str(i + 1), HORIZONTAL_ALIGNMENT_CENTER, 22, 14, Color.WHITE)
	var footer := "Pins match the numbered cards. Locations are canonical; tactical layouts are schematic."
	if unlocated > 0:
		footer += "  %d older/unlocated call(s) not pinned." % unlocated
	draw_string(font, Vector2(37, size.y - 38), footer, HORIZONTAL_ALIGNMENT_LEFT, maxf(1.0, size.x - 74.0), 12, CHARCOAL)
