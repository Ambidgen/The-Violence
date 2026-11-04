extends Node2D
## The plan (1.4, crayon). Draws any level as a child's drawing of it: the ground, the
## floors coloured in (view/crayon_plan.gd), and on the Walls layer above the blood, the
## walls pressed hard, the windows, the room names, the title scrap and its stamps.
##
## Two states, one map: "theory" (the briefing: daylight pencil on cream, sparse and
## certain) and "application" (the live operation, the replay, the debrief: night, in
## charcoal). The topology never changes; only the rendering does.
##
## The strokes are recorded once per state into Sketch variants and replayed, one
## variant per boil frame, so the page shivers for the cost of replaying pre-cut lines.

const CP = preload("res://scripts/view/crayon_plan.gd")
const Crayon = preload("res://scripts/view/crayon.gd")
const Sketch = preload("res://scripts/view/sketch.gd")
const Ink = preload("res://scripts/view/ink.gd")
const PX := 40.0
const VARIANTS := 3

var level
## "theory" or "application"
var state := "theory"
## Application only: {"actual": seconds, "forms": n, "mop": bool, "filed": bool}
var stamp := {}
var walls: Node2D
var _rev := -1
var _cache := {}        # night(bool) -> {"ground": [Sketch], "walls": [Sketch]}
var _title: Array = []  # Sketch variants for the title scrap and stamps
var _title_sig := ""
var _bi := -1
static var _paper: Texture2D


func setup(lv) -> void:
	level = lv
	_cache.clear()
	_title_sig = ""
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	queue_redraw()
	if walls != null:
		walls.queue_redraw()


func set_state(st: String, info := {}) -> void:
	if st == state and info == stamp:
		return
	state = st
	stamp = info
	queue_redraw()
	if walls != null:
		walls.queue_redraw()


func night() -> bool:
	return state == "application"


## The boil frame now (all crayon layers agree on it).
static func boil_index() -> int:
	return Crayon.tick() % VARIANTS


func _process(_d: float) -> void:
	var bi := boil_index()
	if _rev != Ink.rev:
		_rev = Ink.rev
		_title_sig = ""
		bi = -2
	if bi != _bi:
		_bi = maxi(bi, 0)
		queue_redraw()
		if walls != null:
			walls.queue_redraw()


func sketches() -> Dictionary:
	var n := night()
	if not _cache.has(n):
		var lv = level
		_cache[n] = {
			"ground": Sketch.variants(VARIANTS, func(s): CP.paint_ground(s, lv, n)),
			"walls": Sketch.variants(VARIANTS, func(s): CP.paint_walls(s, lv, n)),
		}
	return _cache[n]


func title_sketches() -> Array:
	var sig := state + str(stamp) + str(Ink.red_ink_enabled)
	if sig != _title_sig:
		_title_sig = sig
		var lv = level
		var st := state
		var sp := stamp
		_title = Sketch.variants(VARIANTS, func(s): CP.paint_title(s, lv, st, sp))
	return _title


static func paper() -> Texture2D:
	if _paper == null:
		_paper = Crayon.paper_texture(Vector2i(256, 256), Crayon.PAPER_CREAM, 7, 0.0)
	return _paper


func _draw() -> void:
	if level == null:
		return
	var W: float = level.W * PX
	var H: float = level.H * PX
	var sheet := Rect2(-60, -60, W + 120, H + 236)
	var tint := Color.WHITE if not night() else Color(0.62, 0.6, 0.57)
	draw_texture_rect(paper(), sheet, true, tint)
	var sk: Array = sketches()["ground"]
	sk[maxi(_bi, 0) % sk.size()].replay(self)


## The upper layer (walls, labels, title) asks for its sketches here.
func replay_walls(ci: CanvasItem) -> void:
	if level == null:
		return
	var i := maxi(_bi, 0)
	var sk: Array = sketches()["walls"]
	sk[i % sk.size()].replay(ci)
	var ts := title_sketches()
	ts[i % ts.size()].replay(ci)
