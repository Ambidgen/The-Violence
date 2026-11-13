extends Node2D
## Native crayon interstitials. Every short is a small, deterministic drawing driven by
## the shared shorts manifest; campaign props and published text slots stay live.
## Presentation only: no simulation state or random-number stream is touched.

const C = preload("res://scripts/view/crayon.gd")
const W := 1600.0
const H := 900.0
# The bright child's-drawing palette of the opening scenes (scripts/view/proto/
# opening_view.gd). Visual overhaul 2026-11-03: the shorts were drawn on the darker grey
# stock of the second prototype plates and read as a different game from the opening.
const PAPER := Color("#fbf7ec")    # cream drawing paper
const STOCK := Color("#ffffff")    # notebook paper for panels and cards
const DARK := Color("#1e1b1c")     # wax-crayon black
const MID := Color("#5b5866")      # pencil grey
const RED := Color("#ff2b30")
const AMBER := Color("#ffc400")
const BLUE := Color("#2747e6")     # police blue, as the opening draws the uniforms
const NAVY := Color("#2747e6")
const UMBER := Color("#a5592a")
const SAP := Color("#2fcf3f")      # grass green
const SKY := Color("#33a6ff")
const NIGHT := Color("#251a7a")    # the opening's night sky; stands in for wet slate
const SUN := Color("#ffd60a")
const SUN_EDGE := Color("#ff9500")
const RULE := Color("#9cc3ff")     # notebook rules
const MARGIN := Color("#ff6f7d")   # notebook margin
const SOFT_GREY := Color("#9aa1ad")

static var _paper_cache: ImageTexture

var key := ""
var props: Dictionary = {}
var slots: Dictionary = {}
var seconds := 6.0
var t := 0.0
var vp := Vector2(W, H)
var paper: ImageTexture


func configure(
	short_key: String, short_props: Dictionary, slot_text: Dictionary, length: float
) -> void:
	key = short_key
	props = short_props.duplicate(true)
	slots = slot_text.duplicate(true)
	seconds = maxf(1.0, length)
	t = 0.0
	if is_inside_tree():
		queue_redraw()


func _ready() -> void:
	vp = get_viewport_rect().size
	if _paper_cache == null:
		_paper_cache = C.paper_texture(Vector2i(800, 450), PAPER, 29, 0.0)
	paper = _paper_cache
	set_process(true)


func _process(delta: float) -> void:
	t += delta
	C.frame = int(t * 8.0)
	queue_redraw()


func _reveal(at: float, span := 0.7) -> float:
	return clampf((t - at) / maxf(0.05, span), 0.0, 1.0)


func _alpha(color: Color, a: float) -> Color:
	var result := color
	result.a *= a
	return result


func _draw() -> void:
	if paper == null:
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(vp.x / W, vp.y / H))
	C.boil = 1.0
	draw_texture_rect(paper, Rect2(0, 0, W, H), false)
	# A child's page: a strip of scribbled sky along the top and a sun in the corner,
	# as in the opening scenes; the rest of the page is left to the drawing.
	C.hatch_rect(self, Rect2(0, -4, W, 52), SKY, 6.0, -0.35, 9, 3.6, 1.0)
	C.hatch_rect(self, Rect2(0, 0, W, 34), SKY, 9.0, 0.5, 11, 2.6, 1.0)
	var sun_c := Vector2(W - 70.0, 54.0)
	for i in 10:
		var ang := TAU * float(i) / 10.0 + 0.2
		C.line(self, sun_c + Vector2.from_angle(ang) * 40.0, sun_c + Vector2.from_angle(ang) * 58.0, SUN_EDGE, 3.0, 40 + i, 1.0, 1)
	C.hatch(self, C.ellipse_poly(sun_c, 32.0, 32.0, 18, 51, 0.05), SUN, 3.4, 0.4, 52, 3.4)
	C.outline(self, C.ellipse_poly(sun_c, 32.0, 32.0, 18, 51, 0.05), SUN_EDGE, 2.6, 53, 1.0)
	draw_short()
	_footer()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _panel(rect: Rect2, seed: int, tint: Color = STOCK, reveal := 1.0) -> void:
	# Notebook paper, like the opening's captions: white (or the tint, washed out), blue
	# rules, a red margin, and a crayon edge pressed hard.
	var fill := tint.lerp(STOCK, 0.55) if tint != STOCK else STOCK
	C.hatch_rect(self, rect, _alpha(fill, 0.95), 3.2, -0.7, seed, 2.6, reveal)
	var y := rect.position.y + 30.0
	while y < rect.end.y - 8.0:
		C.line(self, Vector2(rect.position.x + 6, y), Vector2(rect.end.x - 6, y), _alpha(RULE, 0.55), 1.2, seed + int(y), 0.4, 1, reveal)
		y += 30.0
	if rect.size.x > 160.0:
		C.line(self, Vector2(rect.position.x + 34, rect.position.y + 4), Vector2(rect.position.x + 34, rect.end.y - 4), _alpha(MARGIN, 0.7), 1.6, seed + 3, 0.5, 1, reveal)
	C.outline(self, C.rect_poly(rect), DARK, 3.1, seed + 1, 1.0, reveal)


func _box(rect: Rect2, seed: int, reveal := 1.0, color: Color = DARK) -> void:
	C.outline(self, C.rect_poly(rect), color, 2.6, seed, 1.2, reveal)


func _txt(
	text: String,
	at: Vector2,
	size: int,
	color: Color = DARK,
	seed := 100,
	max_width := 0.0,
	reveal := 1.0
) -> void:
	if text.is_empty() or reveal <= 0.0:
		return
	# Declared, not inferred: the two arms of the ternary below are an Array[String] and a
	# PackedStringArray, so `:=` infers Variant and 4.7 treats that as an error — which is
	# why no short could be constructed and crayon_shorts_test could not load its scenes
	# (2026-11-02). Both arms are turned into the same Array[String] here.
	var lines: Array[String] = []
	if max_width > 0.0:
		lines = _wrap_lines(text, size, max_width)
	else:
		for part in text.to_upper().split("\n", false):
			lines.append(String(part))
	var current_y := at.y
	for line_text in lines:
		var fitted := size
		if max_width > 0.0:
			while fitted > 12 and C.letters_width(line_text, fitted) > max_width:
				fitted -= 1
		var width := C.letters_width(line_text, fitted)
		C.letters(
			self,
			line_text,
			Vector2(at.x + maxf(0.0, (max_width - width) * 0.5), current_y),
			fitted,
			color,
			seed,
			2,
			0.82,
			reveal
		)
		current_y += fitted * 1.4


func _wrap_lines(text: String, size: int, max_width: float) -> Array[String]:
	var result: Array[String] = []
	for paragraph in text.to_upper().split("\n", false):
		var line_text := ""
		for word in paragraph.split(" ", false):
			var candidate := word if line_text.is_empty() else line_text + " " + word
			if not line_text.is_empty() and C.letters_width(candidate, size) > max_width:
				result.append(line_text)
				line_text = word
			else:
				line_text = candidate
		if not line_text.is_empty():
			result.append(line_text)
	return result


## A van, drawn the same way in the office and civic sheets. It lives on the base script
## because both sheets use it and neither extends the other (civic called `_draw_van` and
## could not compile, 2026-11-02: the function was only on the office sheet).
func _draw_van(c: Vector2, sc: float, seed: int) -> void:
	var r := Rect2(c - Vector2(89, 39) * sc, Vector2(178, 78) * sc)
	C.hatch_rect(self, r, _alpha(SOFT_GREY, _reveal(1.0, 0.5)), 3.7, -0.6, seed, 2.4)
	C.outline(self, C.rect_poly(r), DARK, 3.0, seed + 1)
	for side in [-1.0, 1.0]:
		C.hatch(
			self,
			C.ellipse_poly(
				c + Vector2(side * 52 * sc, 36 * sc), 19 * sc, 14 * sc, 14, seed + 2, 0.12
			),
			DARK,
			4.0,
			0.3,
			seed + 3,
			2.0
		)
	C.hatch(
		self,
		C.ellipse_poly(c + Vector2(-10 * sc, -43 * sc), 20 * sc, 9 * sc, 12, seed + 4),
		RED,
		3.4,
		0.1,
		seed + 5,
		3.0
	)
	C.hatch(
		self,
		C.ellipse_poly(c + Vector2(20 * sc, -43 * sc), 20 * sc, 9 * sc, 12, seed + 6),
		BLUE,
		3.4,
		-0.4,
		seed + 7,
		3.0
	)


func _slot(id: String, fallback: String) -> String:
	if slots.has(id) and not String(slots[id]).strip_edges().is_empty():
		return String(slots[id])
	return fallback


## A prop as text. The manifest is JSON, so whole numbers arrive as floats ("WEEK 23.0").
static func _ps(v) -> String:
	if v is float and is_equal_approx(v, round(v)):
		return str(int(round(v)))
	return str(v)


func _prop_text(id: String, fallback: String) -> String:
	return _ps(props.get(id, fallback))


func _heading(kicker: String, title: String, seed: int, title_size := 40) -> void:
	_txt(kicker, Vector2(82, 88), 18, MID, seed, 720, _reveal(0.0, 0.45))
	C.line(
		self, Vector2(82, 108), Vector2(1518, 108), DARK, 2.1, seed + 1, 1.0, 2, _reveal(0.12, 0.55)
	)
	_txt(title, Vector2(82, 178), title_size, DARK, seed + 2, 1220, _reveal(0.18, 0.8))


func _stamp(text: String, at: Vector2, seed: int, color: Color = RED) -> void:
	var width := C.letters_width(text, 31) + 34.0
	var rect := Rect2(at.x, at.y - 40, width, 54)
	C.outline(self, C.rect_poly(rect), color, 3.4, seed, 1.2, _reveal(maxf(0.0, t - 0.25), 0.45))
	C.letters(self, text, at, 31, color, seed + 1, 2, 0.72, _reveal(maxf(0.0, t - 0.25), 0.45))


func _person(foot: Vector2, scale: float, color: Color, seed: int, raised := false) -> void:
	var h := 44.0 * scale
	C.person_front(self, foot, h, color, seed, raised, "", 0.0)


func draw_short() -> void:
	_unknown()


func _unknown() -> void:
	_panel(Rect2(160, 218, 1280, 540), 1200, STOCK, _reveal(0.1, 0.4))
	_txt("PORT CARRICK POLICE DEPARTMENT", Vector2(340, 390), 28, DARK, 1201, 900)
	_txt(key.replace("_", " "), Vector2(400, 520), 26, RED, 1202, 800)


func _footer() -> void:
	C.line(self, Vector2(80, 858), Vector2(1520, 858), _alpha(DARK, 0.8), 1.8, 1300, 0.8, 2)
	C.letters(self, "PORT CARRICK POLICE DEPARTMENT", Vector2(82, 888), 13, MID, 1301, 1, 1.0, 1.0)
	var elapsed := clampi(int(t), 0, int(seconds))
	C.letters(
		self,
		"%02d / %02d" % [elapsed, int(seconds)],
		Vector2(1394, 888),
		13,
		MID,
		1302,
		1,
		1.0,
		1.0
	)
