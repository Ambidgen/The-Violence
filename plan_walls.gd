extends Node2D
## The floor plan's upper layer (v0.8): walls, windows, doors, room lettering, dimension
## strings, the title block and its stamps. It sits above the blood, so a stain slides
## under a wall and stops at its face.

const FP = preload("res://scripts/view/floor_plan.gd")
const Ink = preload("res://scripts/view/ink.gd")

var plan

func _draw() -> void:
	var level = plan.level
	if level == null:
		return
	var font: Font = ThemeDB.fallback_font
	var W: float = level.W * FP.PX
	var H: float = level.H * FP.PX
	FP.paint_walls(self, level, font)
	FP.paint_labels(self, level, font)
	if not level.dims.is_empty():
		for dm in level.dims:
			FP._dimension(self, dm["a"], dm["b"], dm["text"], font)
			var horiz: bool = absf(dm["b"].x - dm["a"].x) > absf(dm["b"].y - dm["a"].y)
			for tk in dm.get("ticks", []):
				if horiz:
					draw_line(Vector2(tk * FP.PX, (dm["a"].y - 0.15) * FP.PX), Vector2(tk * FP.PX, (dm["a"].y + 0.15) * FP.PX), FP.LINE, 1.0)
				else:
					draw_line(Vector2((dm["a"].x - 0.15) * FP.PX, tk * FP.PX), Vector2((dm["a"].x + 0.15) * FP.PX, tk * FP.PX), FP.LINE, 1.0)
	else:
		for b in level.buildings:
			var box: Rect2 = b
			var ytop := box.position.y - 0.9
			var xr := box.end.x + 0.9
			FP._dimension(self, Vector2(box.position.x, ytop), Vector2(box.end.x, ytop), "%.2f m" % box.size.x, font)
			FP._dimension(self, Vector2(xr, box.position.y), Vector2(xr, box.end.y), "%.2f" % box.size.y, font)
	# title block, scale bar, legend
	var tb := Rect2(W - 560, H + 14, 560, 92)
	draw_rect(tb, FP.PAPER)
	draw_rect(tb, FP.INK, false, 1.5)
	draw_line(Vector2(tb.position.x, tb.position.y + 30), Vector2(tb.end.x, tb.position.y + 30), FP.LINE, 1.0)
	draw_line(Vector2(tb.position.x + 360, tb.position.y + 30), Vector2(tb.position.x + 360, tb.end.y), FP.LINE, 1.0)
	draw_string(font, tb.position + Vector2(12, 21), FP._spaced(level.title), HORIZONTAL_ALIGNMENT_LEFT, 536, 14, FP.INK)
	for i in mini(3, level.notes.size()):
		draw_string(font, tb.position + Vector2(12, 50 + 16 * i), level.notes[i], HORIZONTAL_ALIGNMENT_LEFT, 340, 11, FP.LINE if i < 2 else FP.FAINT)
	draw_string(font, tb.position + Vector2(372, 50), "COVER: solid fill / hatched", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FP.LINE)
	draw_string(font, tb.position + Vector2(372, 66), "CONCEALMENT: outline only", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FP.LINE)
	draw_string(font, tb.position + Vector2(372, 82), "WINDOWS: sill 0.9 m, head 2.1 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FP.LINE)
	var sb := Vector2(0, H + 40)
	for k in 5:
		var seg := Rect2(sb.x + k * FP.PX, sb.y, FP.PX, 8)
		draw_rect(seg, FP.INK if k % 2 == 0 else FP.PAPER)
		draw_rect(seg, FP.INK, false, 1.0)
	for k in [0, 1, 5]:
		draw_string(font, sb + Vector2(k * FP.PX - 3, 24), str(k), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FP.LINE)
	draw_string(font, sb + Vector2(5 * FP.PX + 12, 9), "m", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, FP.LINE)
	# the stamps, in a band under the title block: the model's confidence, then what it cost
	var x := 0.0
	var y := H + 112.0
	if plan.state == "theory":
		x += FP._stamp(self, font, Vector2(x, y), ["MODEL: COMPLETE", "UNKNOWN: NONE"], FP.INK, -0.015) + 26.0
		FP._stamp(self, font, Vector2(x, y + 2), ["RISK: APPROVED", "OWNER: NOT LISTED"], FP.FAINT, 0.012)
		return
	var st: Dictionary = plan.stamp
	var secs := float(st.get("actual", 0.0))
	var col := Ink.accent(0.8)
	x += FP._stamp(self, font, Vector2(x, y + 2), ["ACTUAL: %02d:%02d" % [int(secs / 60.0), int(secs) % 60], "FRICTION: ALL"], col, -0.03) + 26.0
	if int(st.get("forms", 0)) > 0:
		x += FP._stamp(self, font, Vector2(x, y), ["PAPERWORK: %02d FORMS" % int(st["forms"]),
			"MOP: REQUESTED" if st.get("mop", false) else "MOP: NOT REQUIRED"], FP.INK, 0.015) + 26.0
	if st.get("filed", false):
		FP._stamp(self, font, Vector2(x, y + 4), ["FILED", "NOT RESOLVED"], col, -0.045)
