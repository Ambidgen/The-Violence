extends SceneTree
## Title cards for the trailers (1.1), drawn in the game's own hand: paper, a faint plan
## grid, ink lettering and one red rule. Not part of the game.
##   xvfb-run godot --path . --resolution 1920x1080 -s res://tools/ad_card.gd -- --out=card.png \
##       --kind=line --text="YOU PLAN.|THEY DECIDE." [--red=1] [--small="..."] [--w=1920 --h=1080]
## kinds: title (the game's name), line (one to three lines; --red=N puts line N in red ink),
## stamp (a rubber stamp over a line), end (name, tagline and the small print).
## A line may carry a red word between asterisks: "THE *ROOM*".

const PAPER := Color(0.93, 0.93, 0.91)
const FLOOR := Color(0.83, 0.83, 0.81)
const MID := Color(0.45, 0.45, 0.44)
const INK := Color(0.07, 0.07, 0.07)
const RED := Color(0.70, 0.12, 0.15)

var args := {}
var frame := 0


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		var i := a.find("=")
		if i < 0:
			args[a.trim_prefix("--")] = "1"
		else:
			args[a.substr(2, i - 2)] = a.substr(i + 1)
	var w := int(args.get("w", "1920"))
	var h := int(args.get("h", "1080"))
	get_root().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	get_root().size = Vector2i(w, h)
	RenderingServer.set_default_clear_color(PAPER)
	var c := Card.new()
	c.args = args
	c.size = Vector2(w, h)
	get_root().add_child(c)


func _process(_dt: float) -> bool:
	frame += 1
	if frame == 2:
		get_root().get_child(0).queue_redraw()
	if frame == 6:
		get_root().get_texture().get_image().save_png(args.get("out", "user://card.png"))
		return true
	return false


class Card extends Node2D:
	var args := {}
	var size := Vector2(1920, 1080)

	func _draw() -> void:
		size = get_viewport_rect().size       # the canvas, whatever the window stretch
		var font: Font = ThemeDB.fallback_font
		var k := size.y / 1080.0
		draw_rect(Rect2(Vector2.ZERO, size), PAPER)
		# the drawing sheet: a faint 1 m grid, the border, the title block corner
		var step := 40.0 * k
		var x := 0.0
		while x < size.x:
			draw_line(Vector2(x, 0), Vector2(x, size.y), Color(INK, 0.045), 1.0)
			x += step
		var y := 0.0
		while y < size.y:
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(INK, 0.045), 1.0)
			y += step
		var m := 36.0 * k
		draw_rect(Rect2(Vector2(m, m), size - Vector2(m, m) * 2.0), Color(INK, 0.5), false, 1.4)
		draw_rect(Rect2(Vector2(m + 8 * k, m + 8 * k), size - Vector2(m + 8 * k, m + 8 * k) * 2.0), Color(INK, 0.25), false, 1.0)
		for i in int((size.x - 2 * m) / (80 * k)):
			draw_line(Vector2(m + i * 80 * k, m), Vector2(m + i * 80 * k, m + 6 * k), Color(INK, 0.5), 1.2)
		var kind: String = args.get("kind", "line")
		var lines: PackedStringArray = String(args.get("text", "")).split("|")
		var red_line := int(args.get("red", "0"))
		match kind:
			"title", "end":
				var t := "T H E   V I O L E N C E"
				var fs := int(118 * k)
				var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var top := size.y * (0.40 if kind == "title" else 0.36)
				_text(font, "PORT CARRICK POLICE DEPARTMENT  ·  OFFICE OF THE CHIEF", Vector2(size.x / 2.0, top - 70 * k), int(24 * k), MID)
				draw_string(font, Vector2((size.x - tw) / 2.0, top + fs * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, INK)
				draw_rect(Rect2(Vector2((size.x - tw) / 2.0, top + fs * 0.55), Vector2(tw, 9 * k)), RED)
				var tag: String = args.get("tag", "Forty weeks to the election. Every operation is a plan until it meets a room.")
				_text(font, tag, Vector2(size.x / 2.0, top + fs * 0.55 + 70 * k), int(34 * k), Color(0.17, 0.17, 0.17))
				if kind == "end":
					var yy := top + fs * 0.55 + 170 * k
					for ln in lines:
						_rich(font, ln, Vector2(size.x / 2.0, yy), int(30 * k))
						yy += 50 * k
			"stamp":
				var fs2 := int(64 * k)
				var yy2 := size.y / 2.0 - (lines.size() - 1) * 50 * k
				for i in lines.size():
					_rich(font, lines[i], Vector2(size.x / 2.0, yy2 + i * 100 * k), fs2, i + 1 == red_line)
				var st: PackedStringArray = String(args.get("stamp", "FILED|NOT RESOLVED")).split("|")
				_stamp(font, st, Vector2(size.x * 0.70, size.y * 0.72), k)
			_:
				var fs3 := int(float(args.get("size", "110")) * k)
				var gap := fs3 * 1.35
				var yy3 := size.y / 2.0 - (lines.size() - 1) * gap / 2.0 + fs3 * 0.35
				for i in lines.size():
					_rich(font, lines[i], Vector2(size.x / 2.0, yy3 + i * gap), fs3, i + 1 == red_line)
		var small: String = args.get("small", "")
		if small != "":
			_text(font, small, Vector2(size.x / 2.0, size.y - 90 * k), int(24 * k), MID)

	func _text(font: Font, t: String, c: Vector2, fs: int, col: Color) -> void:
		var tw := font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(c.x - tw / 2.0, c.y), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)

	## A centred line; words between asterisks are set in red ink (or the whole line).
	func _rich(font: Font, t: String, c: Vector2, fs: int, all_red := false) -> void:
		var parts := t.split("*")
		var total := 0.0
		for p in parts:
			total += font.get_string_size(p, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var x := c.x - total / 2.0
		for i in parts.size():
			var col := RED if (all_red or i % 2 == 1) else INK
			draw_string(font, Vector2(x, c.y), parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
			x += font.get_string_size(parts[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

	func _stamp(font: Font, st: PackedStringArray, c: Vector2, k: float) -> void:
		draw_set_transform(c, -0.06)
		var fs := int(40 * k)
		var wmax := 0.0
		for s in st:
			wmax = maxf(wmax, font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x)
		var hh := st.size() * fs * 1.2 + 24 * k
		var r := Rect2(Vector2(-wmax / 2.0 - 22 * k, -hh / 2.0), Vector2(wmax + 44 * k, hh))
		draw_rect(r, Color(RED, 0.85), false, 4.0 * k)
		draw_rect(r.grow(-7 * k), Color(RED, 0.6), false, 1.6 * k)
		for i in st.size():
			draw_string(font, Vector2(-wmax / 2.0, -hh / 2.0 + 12 * k + (i + 1) * fs * 1.1), st[i], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(RED, 0.9))
		draw_set_transform(Vector2.ZERO, 0.0)
