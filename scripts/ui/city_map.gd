extends Control
## Campaign board overview. This draws the generator's actual ward polygons, river,
## basins and major roads; pins use the coordinates saved with each situation. It is
## an overview, not the tactical floor plan, and does not change simulation state.

const City = preload("res://scripts/campaign/city.gd")
const Ink = preload("res://scripts/view/ink.gd")
const C = preload("res://scripts/view/crayon.gd")
# Visual overhaul 2026-11-03: the board map was flat vector beige and read as a different
# game from the opening scenes. It is now drawn in the opening's crayon palette.
const PAPER := Color("#fbf7ec")
const CHARCOAL := Color("#1e1b1c")
const PENCIL := Color("#5b5866")
const WATER := Color("#16b7ff")
const WATER_EDGE := Color("#2747e6")
const ROAD := Color("#8a909b")
const RED := Color("#ff2b30")
const WARD_COLORS := [Color("#ffd166"), Color("#ff8fab"), Color("#86e35c"),
	Color("#c69cff"), Color("#ffb36b"), Color("#f2b866")]
# Label positions are cartographic annotations only, in the generator's metre frame.
const LABELS := {
	"northgate": [0.0, 2000.0], "riverside": [-2300.0, 650.0], "oldtown": [0.0, 620.0],
	"ironworks": [-2000.0, -1250.0], "eastport": [3000.0, -1200.0], "kilbride": [1050.0, -1200.0]
}

## Campaign UI 2026-11-03: the map is the board. A pin opens its call; a landmark opens
## the department (Police HQ), the politics (City Hall) or the week's paper (the Ledger).
signal pin_pressed(index: int)
signal landmark_pressed(id: String)

# Landmark id -> [label, icon offset from the building in screen pixels, colour]
const LANDMARKS := {
	"police-hq": ["POLICE HQ", Vector2(-92, -92), Color("#2747e6")],
	"city-hall": ["CITY HALL", Vector2(78, -100), Color("#ffc400")],
	"ledger": ["THE LEDGER", Vector2(-150, 34), Color("#fbf7ec")],
}
const ICON := Vector2(64, 50)

var selected := -1
var _hover := ""            # "pin:3", "lm:police-hq" or ""
var _lm_rects := {}         # landmark id -> Rect2 of its icon and label
var _lm_cache := {}
var _lm_at := {}

var situations: Array = []
var trust: Array = []
var week := 1
var _extent: Array = []
var _map_rect := Rect2()
var _ink_rev := -1


func show_city(board: Array, ward_trust: Array, current_week: int) -> void:
	if board != situations:
		selected = -1
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
		for id in _lm_rects:
			if (_lm_rects[id] as Rect2).has_point(at_position):
				return {"police-hq": "Carrick Street Station (Police HQ)\nRoster, budget, internal affairs, armoury, campaign file",
					"city-hall": "City Hall and Council Chambers\nThe mayor, the council and the campaign",
					"ledger": "The Carrick Ledger\nThis week: the desk, results and the front page"}.get(id, "")
		return ""
	var s: Dictionary = situations[nearest]
	return "%d. %s\n%s\n%s" % [nearest + 1, s.get("site_name", s.get("title", "Call")),
		s.get("address", "Location unavailable"), s.get("ward", "Unknown ward")]


## The projection and the landmarks' hit boxes, worked out from the size alone so the
## map answers clicks (and the UI walk) whether or not it has been drawn yet.
func layout() -> bool:
	var city := City.data()
	if city.has("error"):
		return false
	_extent = city.get("extent", [])
	if _extent.size() != 4 or float(_extent[2]) <= float(_extent[0]) or float(_extent[3]) <= float(_extent[1]):
		return false
	var available := Vector2(maxf(1.0, size.x - 76.0), maxf(1.0, size.y - 175.0))
	var aspect := (float(_extent[2]) - float(_extent[0])) / (float(_extent[3]) - float(_extent[1]))
	var w := minf(available.x, available.y * aspect)
	var h := w / aspect
	_map_rect = Rect2(Vector2((size.x - w) * 0.5, 106.0 + (available.y - h) * 0.5), Vector2(w, h))
	_lm_rects.clear()
	_lm_at.clear()
	for id in LANDMARKS:
		var xy := _landmark_xy(city, id)
		if xy.size() != 2:
			continue
		var at := _point(float(xy[0]), float(xy[1]))
		var spec: Array = LANDMARKS[id]
		var c: Vector2 = at + spec[1]
		var lw := C.letters_width(String(spec[0]), 15, 0.9)
		var bw := maxf(ICON.x, lw + 16.0)
		_lm_at[id] = at
		_lm_rects[id] = Rect2(c - Vector2(bw * 0.5, ICON.y * 0.5), Vector2(bw, ICON.y + 24.0))
	return true


## Screen position of a pin or a landmark (for the UI walk and the popups).
func pin_pos(i: int) -> Vector2:
	if not layout() or i < 0 or i >= situations.size() or not situations[i].has("city_x"):
		return Vector2(-1, -1)
	return _point(float(situations[i]["city_x"]), float(situations[i]["city_y"]))


func landmark_pos(id: String) -> Vector2:
	if not layout() or not _lm_rects.has(id):
		return Vector2(-1, -1)
	return (_lm_rects[id] as Rect2).get_center()


## What is under the mouse: a pin first (they are the point of the map), then a landmark.
func _target(at: Vector2) -> String:
	if _extent.size() != 4 and not layout():
		return ""
	var best := -1
	var dist := 20.0
	for i in situations.size():
		var s: Dictionary = situations[i]
		if not s.has("city_x") or not s.has("city_y"):
			continue
		var d := _point(float(s["city_x"]), float(s["city_y"])).distance_to(at)
		if d <= dist:
			dist = d
			best = i
	if best >= 0:
		return "pin:%d" % best
	for id in _lm_rects:
		if (_lm_rects[id] as Rect2).has_point(at):
			return "lm:" + String(id)
	return ""


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var t := _target((ev as InputEventMouseMotion).position)
		if t != _hover:
			_hover = t
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if t != "" else Control.CURSOR_ARROW
			queue_redraw()
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var t := _target(mb.position)
			if t.begins_with("pin:"):
				pin_pressed.emit(int(t.substr(4)))
				accept_event()
			elif t.begins_with("lm:"):
				landmark_pressed.emit(t.substr(3))
				accept_event()


func _landmark_xy(city: Dictionary, id: String) -> Array:
	if _lm_cache.has(id):
		return _lm_cache[id]
	var out := []
	for lm in city.get("landmarks", []):
		if lm is Dictionary and String(lm.get("id", "")) == id:
			out = [float(lm.get("x", 0.0)), float(lm.get("y", 0.0))]
	_lm_cache[id] = out
	return out


## A drawn landmark: a small crayon picture on a white scrap with its name under it,
## pinned to the building by a pencil line.
func _draw_landmark(id: String, at: Vector2, k: int) -> void:
	var spec: Array = LANDMARKS[id]
	var col: Color = spec[2]
	var c: Vector2 = at + spec[1]
	var label: String = spec[0]
	var lw := C.letters_width(label, 15, 0.9)
	var r: Rect2 = _lm_rects[id]
	var hot := _hover == "lm:" + id
	C.line(self, at, c + Vector2(0, ICON.y * 0.5), Color(CHARCOAL, 0.7), 1.6, 900 + k, 0.8, 1)
	var dot := C.ellipse_poly(at, 5.0, 5.0, 10, 905 + k, 0.1)
	C.hatch(self, dot, CHARCOAL, 2.0, 0.5, 906 + k, 2.6)
	draw_rect(r.grow(2.0), Color(1, 1, 1, 0.96))
	if hot:
		C.hatch_rect(self, r.grow(2.0), Color("#ffd60a", 0.55), 5.0, -0.7, 910 + k, 3.0)
	C.outline(self, C.rect_poly(r.grow(2.0)), CHARCOAL, 2.6 if hot else 2.0, 915 + k, 1.0)
	var ic := Rect2(Vector2(c.x - 26, r.position.y + 6), Vector2(52, 36))
	match id:
		"police-hq":
			var body := Rect2(ic.position + Vector2(4, 10), Vector2(44, 26))
			C.hatch_rect(self, body, col, 3.4, -0.7, 920 + k, 3.0)
			C.outline(self, C.rect_poly(body), CHARCOAL, 2.0, 921 + k, 0.8)
			C.line(self, body.position + Vector2(-3, 0), body.position + Vector2(body.size.x + 3, 0), CHARCOAL, 3.0, 922 + k, 0.6, 1)
			var lamp := C.ellipse_poly(Vector2(c.x, ic.position.y + 5), 5.0, 5.0, 10, 923 + k, 0.1)
			C.hatch(self, lamp, RED, 2.0, 0.4, 924 + k, 3.0)
			C.outline(self, lamp, CHARCOAL, 1.6, 925 + k, 0.6)
			var door := Rect2(Vector2(c.x - 5, body.end.y - 13), Vector2(10, 13))
			draw_rect(door, Color.WHITE)
			C.outline(self, C.rect_poly(door), CHARCOAL, 1.4, 926 + k, 0.5)
		"city-hall":
			var base := Rect2(ic.position + Vector2(2, 16), Vector2(48, 20))
			C.hatch_rect(self, base, col, 3.4, -0.7, 930 + k, 3.0)
			C.outline(self, C.rect_poly(base), CHARCOAL, 2.0, 931 + k, 0.8)
			var roof := PackedVector2Array([base.position + Vector2(-3, 0), Vector2(c.x, ic.position.y + 2), Vector2(base.end.x + 3, base.position.y)])
			C.hatch(self, roof, Color("#ff8fab"), 3.0, 0.6, 932 + k, 2.8)
			C.outline(self, roof, CHARCOAL, 2.0, 933 + k, 0.8)
			for j in 4:
				var x := base.position.x + 8.0 + j * 10.5
				C.line(self, Vector2(x, base.position.y + 3), Vector2(x, base.end.y - 2), CHARCOAL, 1.8, 934 + k * 4 + j, 0.4, 1)
		_:
			var sheet := Rect2(ic.position + Vector2(8, 2), Vector2(36, 32))
			draw_rect(sheet, Color.WHITE)
			C.outline(self, C.rect_poly(sheet), CHARCOAL, 2.0, 940 + k, 0.8)
			C.line(self, sheet.position + Vector2(4, 7), sheet.position + Vector2(32, 7), RED, 3.0, 941 + k, 0.5, 1)
			for j in 3:
				var y := sheet.position.y + 15.0 + j * 6.0
				C.line(self, Vector2(sheet.position.x + 4, y), Vector2(sheet.end.x - 4, y), PENCIL, 1.4, 942 + k * 3 + j, 0.4, 1)
	C.letters(self, label, Vector2(c.x - lw * 0.5, r.end.y - 6), 15, CHARCOAL, 950 + k, 2, 0.9)


func _points(raw: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for xy in raw:
		if xy is Array and xy.size() >= 2:
			out.append(_point(float(xy[0]), float(xy[1])))
	return out


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), PAPER)
	var font: Font = ThemeDB.fallback_font
	C.letters(self, "PORT CARRICK  /  WEEK %d" % week, Vector2(36, 54), 30, CHARCOAL, 7, 2, 0.9)
	C.line(self, Vector2(36, 64), Vector2(36 + C.letters_width("PORT CARRICK  /  WEEK %d" % week, 30, 0.9), 64), RED, 3.0, 8, 1.2, 2)
	var city := City.data()
	if city.has("error"):
		draw_string(font, Vector2(37, 122), "City map unavailable. Check port-carrick/city.json.", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, CHARCOAL)
		return
	if not layout():
		return
	var wards: Dictionary = city.get("wards", {})
	for i in City.WARD_IDS.size():
		var id: String = City.WARD_IDS[i]
		var k := 0
		for polygon in wards.get(id, []):
			if not (polygon is Array):
				continue
			var pts := _points(polygon)
			if pts.size() >= 3:
				var col: Color = WARD_COLORS[i]
				C.hatch(self, pts, Color(col, 0.75), 4.6, -0.6 + 0.25 * i, 300 + i * 7 + k, 3.4)
				C.outline(self, pts, col.darkened(0.35), 2.4, 320 + i * 7 + k, 1.0)
				k += 1
	var water: Dictionary = city.get("water", {}) if city.get("water", {}) is Dictionary else {}
	var wk := 0
	for polygon in water.get("river", []):
		if not (polygon is Array):
			continue
		var pts := _points(polygon)
		if pts.size() >= 3:
			C.hatch(self, pts, Color(WATER, 0.85), 4.0, -0.25, 400 + wk, 3.6)
			C.outline(self, pts, WATER_EDGE, 2.6, 410 + wk, 1.0)
			wk += 1
	var basins = water.get("basins", {})
	if basins is Dictionary:
		for basin in basins.values():
			if not (basin is Dictionary) or not (basin.get("rect", []) is Array):
				continue
			var r: Array = basin.get("rect", [])
			if r.size() == 4:
				var a2 := _point(float(r[0]), float(r[1]))
				var b2 := _point(float(r[2]), float(r[3]))
				var rr := Rect2(Vector2(minf(a2.x, b2.x), minf(a2.y, b2.y)), Vector2(absf(a2.x - b2.x), absf(a2.y - b2.y)))
				C.hatch_rect(self, rr, Color(WATER, 0.85), 4.0, -0.25, 420 + wk, 3.6)
				C.outline(self, C.rect_poly(rr), WATER_EDGE, 2.4, 430 + wk, 1.0)
				wk += 1
	var sk := 0
	for street in city.get("streets", []):
		if not (street is Dictionary) or not (street.get("pts", []) is Array):
			continue
		var cls := String(street.get("cls", ""))
		if not cls in ["A", "B", "C", "M", "Q", "S"]:
			continue
		var pts := _points(street.get("pts", []))
		var wide := 2.4 if cls in ["A", "M"] else 1.5
		for j in range(1, pts.size()):
			C.line(self, pts[j - 1], pts[j], Color(ROAD, 0.85), wide, 500 + sk * 13 + j, 0.7, 1)
		sk += 1
	C.outline(self, C.rect_poly(_map_rect), CHARCOAL, 3.0, 9, 1.4)
	for i in City.WARD_IDS.size():
		var id: String = City.WARD_IDS[i]
		var xy: Array = LABELS[id]
		var pos := _point(float(xy[0]), float(xy[1]))
		var value := "  %d" % int(trust[i]) if i < trust.size() else ""
		var name: String = "OLD TOWN" if id == "oldtown" else id.to_upper()
		var label := name + value
		var lw := C.letters_width(label, 18, 0.9)
		C.letters(self, label, pos + Vector2(-lw * 0.5, 6), 18, CHARCOAL, 600 + i, 2, 0.9)
	var lk := 0
	for id in LANDMARKS:
		if _lm_at.has(id):
			_draw_landmark(id, _lm_at[id], lk)
		lk += 1
	var unlocated := 0
	for i in situations.size():
		var s: Dictionary = situations[i]
		if not s.has("city_x") or not s.has("city_y"):
			unlocated += 1
			continue
		var pos := _point(float(s["city_x"]), float(s["city_y"]))
		var open: bool = s.get("status", "open") == "open"
		var hot := _hover == "pin:%d" % i or selected == i
		if hot:
			C.scribble_ring(self, pos, 24.0, 24.0, Color("#ffd60a"), 760 + i, 1.0, 4.0)
		var dot := C.ellipse_poly(pos, 17.0 if hot else 15.0, 17.0 if hot else 15.0, 16, 700 + i, 0.08)
		C.hatch(self, dot, RED if open else ROAD, 2.6, 0.6, 710 + i, 3.6)
		C.outline(self, dot, CHARCOAL, 2.4, 720 + i, 1.0)
		var num := str(i + 1)
		C.letters(self, num, pos + Vector2(-C.letters_width(num, 18, 0.9) * 0.5, 8), 18, Color.WHITE, 730 + i, 2, 0.9)
	var footer := "Pin: a call   ·   Police HQ: the department   ·   City Hall: politics   ·   Ledger: the week"
	if unlocated > 0:
		footer += "  %d older/unlocated call(s) not pinned." % unlocated
	draw_string(font, Vector2(37, size.y - 38), footer, HORIZONTAL_ALIGNMENT_LEFT, maxf(1.0, size.x - 74.0), 13, PENCIL)
