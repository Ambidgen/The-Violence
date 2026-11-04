extends RefCounted
## Faction marks for the city plan: police solid, Kilbride dots, Corvino bands,
## Los Halcones hatch, Zarya cross-hatch, and paramedics a cross. In the crayon
## character view each gang also gets a distinct clothing family.

const TONE := {0: Color("#2e2e2e"), 1: Color("#4c4c4c"), 2: Color("#5e5e5e"), 3: Color("#3e3e3e"),
	4: Color("#555555"), 5: Color("#8a8a8a")}
const PATTERN := {0: "solid", 1: "dots", 2: "bands", 3: "hatch", 4: "check", 5: "cross"}
const NEUTRAL := Color("#9a9a96")
const Ink = preload("res://scripts/view/ink.gd")


## The alert pip (v0.8, red ink): the three states the rules name told apart by shape,
## so they read without colour. GREEN a hollow ring, YELLOW a grey disc, RED a red disc
## in a heavy ink ring.
static func alert_pip(ci: CanvasItem, p: Vector2, lvl: int) -> void:
	ci.draw_circle(p, 4.6, Color(Ink.PAPER, 0.95))
	match lvl:
		0:
			ci.draw_arc(p, 3.0, 0.0, TAU, 14, Ink.MID, 1.2)
		1:
			ci.draw_circle(p, 3.4, Ink.MID)
		_:
			ci.draw_circle(p, 3.4, Ink.accent(0.9))
			ci.draw_arc(p, 4.3, 0.0, TAU, 16, Ink.INK, 1.4)


static func faction(fi: int) -> Color:
	return TONE.get(fi, NEUTRAL)


static func pattern(fi: int) -> String:
	return PATTERN.get(fi, "")


static func hexs(fi: int) -> String:
	return "#" + faction(fi).to_html(false)


## Pure presentation choices: stable per person/operation and never consume the
## simulation RNG. A concealed attacker keeps a civilian look until revealed.
const CRIMINAL_LOOKS := ["hood", "leather", "workcoat", "track", "vestlook"]
const POLICE_LOOKS := ["patrol", "swat", "riot"]


static func look(o, w, reveal_attacker := false) -> String:
	if o.civ and not (reveal_attacker and o.attacker):
		return "c"
	if w == null:
		return "a" if o.team == 0 else "b"
	if o.medic:
		return "pmed" if o.faction == 0 else "med"
	var police: bool = o.judges or o.police
	if police:
		if not w.event.is_empty():
			return "riot"
		var tm: Dictionary = w.teams[o.team] if o.team >= 0 and o.team < w.teams.size() else {}
		var kit: Dictionary = o.kit
		if tm.get("kind", "") == "qrf" or o.echelon in ["police", "sof"] or kit.get("armour", "none") == "plates" or kit.get("head", "none") in ["ballistic_helmet", "sof_helmet"]:
			return "swat"
		return "patrol"
	if w.city:
		# City factions keep a recognizable clothing family, rather than changing each frame.
		return CRIMINAL_LOOKS[posmod(o.faction - 1, CRIMINAL_LOOKS.size())]
	if not w.factions.is_empty() and bool(w.factions[0].get("police", false)) and o.team == 1:
		return CRIMINAL_LOOKS[posmod(hash("%s:%s" % [o.id, w.seed_used]), CRIMINAL_LOOKS.size())]
	# The test range can still stage non-police military teams.
	return "a" if o.team == 0 else "b"


## A concealed event attacker needs a civilian-looking label as well as clothing.
## Put it after the real civilians' IDs so it does not alias an actual person.
static func disguise_id(o, w) -> String:
	var civilians := 0
	if w != null and w.teams.size() > 2:
		civilians = w.teams[2].get("members", []).size()
	return "C%d" % (civilians + maxi(0, int(o.slot)) + 1)


static func display_id(o, w) -> String:
	return disguise_id(o, w) if o.attacker and o.civ else String(o.id)


## Fill a rectangle (canvas pixels) with a faction's pattern. Hairlines, so the pattern
## reads as a tone from far out and as marks close up.
static func fill_pattern(ci: CanvasItem, r: Rect2, pat: String, col: Color, step: float) -> void:
	match pat:
		"solid":
			ci.draw_rect(r, Color(col, col.a * 0.35))
		"bands":
			var y := ceilf(r.position.y / step) * step
			while y < r.end.y:
				ci.draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), col, -1.0)
				y += step
		"dots":
			var y2 := ceilf(r.position.y / step) * step
			var row := 0
			while y2 < r.end.y:
				var x2 := ceilf(r.position.x / step) * step + (step * 0.5 if row % 2 == 1 else 0.0)
				while x2 < r.end.x:
					ci.draw_rect(Rect2(x2 - step * 0.12, y2 - step * 0.12, step * 0.24, step * 0.24), col)
					x2 += step
				y2 += step
				row += 1
		"hatch":
			_diag(ci, r, col, step, 1.0)
		"check":
			_diag(ci, r, col, step * 1.2, 1.0)
			_diag(ci, r, col, step * 1.2, -1.0)


## Diagonal lines clipped to a rectangle (sgn 1: rising to the right, -1: falling).
static func _diag(ci: CanvasItem, r: Rect2, col: Color, step: float, sgn: float) -> void:
	var w := r.size.x
	var h := r.size.y
	var s := -h
	s = ceilf((r.position.x + s) / step) * step - r.position.x
	while s < w:
		# line x = s + t (t from 0..h) going up (sgn 1) or down (sgn -1)
		var t0 := maxf(0.0, -s)
		var t1 := minf(h, w - s)
		if t1 > t0:
			var a := Vector2(s + t0, h - t0) if sgn > 0.0 else Vector2(s + t0, t0)
			var b := Vector2(s + t1, h - t1) if sgn > 0.0 else Vector2(s + t1, t1)
			ci.draw_line(r.position + a, r.position + b, col, -1.0)
		s += step
