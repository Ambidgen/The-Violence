extends RefCounted
## Crayon figures (1.4): the parts the animated rig wears, drawn as a child draws people
## from above — a pebble of a body in its colour, a big round head (a cap, a helmet, a
## mop of hair), and lying down, limbs flung wide with whole arms, mittens and big boots.
## Arms, hands and feet in motion are drawn live by view/rig.gd in the same colours.
##
## Units are the sprite's own (80 per metre; the rig shows them at half size), origin at
## the canvas centre, facing +x. tools/bake_crayon.gd bakes them into assets/crayon/.

const C = preload("res://scripts/view/crayon.gd")

## look -> [body, shade, hair/cap]
const LOOK := {
	"a": [Color("#2f4a86"), Color("#1a2a52"), Color("#1d2c55")],       # police: navy, a shade bright to read at night
	"pd": [Color("#2f4a86"), Color("#1a2a52"), Color("#1d2c55")],
	"qrf": [Color("#1e2433"), Color("#0f121a"), Color("#141313")],
	# Colours of the separately authored character sprites; the rig's live limbs match.
	"patrol": [Color("#304d84"), Color("#1a294a"), Color("#202f56")],
	"swat": [Color("#343e4b"), Color("#1b222b"), Color("#262e36")],
	"riot": [Color("#2b4265"), Color("#19283d"), Color("#1f3049")],
	"hood": [Color("#866047"), Color("#4d392e"), Color("#372b25")],
	"leather": [Color("#694b42"), Color("#392b29"), Color("#211e1d")],
	"workcoat": [Color("#6d704e"), Color("#393f2c"), Color("#514232")],
	"track": [Color("#526963"), Color("#30433f"), Color("#302823")],
	"vestlook": [Color("#796f5d"), Color("#393b37"), Color("#272521")],
	"b": [Color("#6b5a34"), Color("#3e331c"), Color("#2a1d14")],       # suspects: olive-umber
	"c": [Color("#e4dccb"), Color("#a59b88"), Color("#4a3426")],       # civilians: pale (tinted live)
	"med": [Color("#e4dccb"), Color("#a59b88"), Color("#4a3426")],
	"pmed": [Color("#e4dccb"), Color("#a59b88"), Color("#26324f")],
}
const SKIN := Color("#d6a27f")
const BOOT := Color("#141313")


static func look(key: String) -> Array:
	return LOOK.get(key, LOOK["b"])


static func _ell(c: Vector2, rx: float, ry: float, s: int, wob := 0.07, n := 16) -> PackedVector2Array:
	return C.ellipse_poly(c, rx, ry, n, s, wob)


## The torso (64 x 64 canvas): the body pebble, shoulders, and its one mark.
static func torso(ci, key: String, s := 0) -> void:
	var lk := look(key)
	var body: Color = lk[0]
	var shade: Color = lk[1]
	var p := _ell(Vector2(-4, 0), 10.5, 21.5, s, 0.06)
	ci.draw_colored_polygon(p, body)
	C.hatch(ci, p, Color(shade, 0.85), 3.2, -0.8, s + 1, 2.4)
	C.hatch(ci, p, Color(body.lightened(0.18), 0.55), 4.6, 0.7, s + 2, 1.8)
	C.outline(ci, p, C.CHARCOAL, 3.0, s + 3, 1.0)
	match key:
		"a", "pd", "qrf":
			# the badge on the chest and a pale bar of the duty belt across the back
			C.line(ci, Vector2(-11, -15), Vector2(-11, 15), Color("#9aa6bd"), 3.2, s + 4, 0.6, 1)
			var star := PackedVector2Array()
			for k in 10:
				var r := 4.2 if k % 2 == 0 else 1.9
				star.append(Vector2(2, -8) + Vector2.from_angle(TAU * k / 10.0 - PI / 2.0) * r)
			ci.draw_colored_polygon(star, C.AMBER)
		"b":
			# a hood bunched at the back of the neck
			var hood := _ell(Vector2(-11, 0), 5.5, 9.0, s + 5, 0.15, 10)
			ci.draw_colored_polygon(hood, shade)
			C.outline(ci, hood, C.CHARCOAL, 2.0, s + 6, 0.6)
		"c", "med", "pmed":
			# buttons down the front of a coat
			for b in 3:
				ci.draw_circle(Vector2(3, -8 + b * 8), 1.8, C.CHARCOAL)
			if key != "c":
				ci.draw_colored_polygon(C.rect_poly(Rect2(-12, -3, 14, 6)), C.RED)
				ci.draw_colored_polygon(C.rect_poly(Rect2(-8, -8, 6, 16)), C.RED)


## The head (32 x 32 canvas), nose toward +x: big, round, and what sits on it.
static func head(ci, key: String, s := 0) -> void:
	var lk := look(key)
	var hair: Color = lk[2]
	match key:
		"a", "pd":
			var cap := _ell(Vector2.ZERO, 11.5, 11.5, s, 0.05)
			ci.draw_colored_polygon(cap, hair)
			C.hatch(ci, cap, Color("#3b4a72"), 3.0, 0.5, s + 1, 1.8)
			C.line(ci, Vector2(10, -9), Vector2(10, 9), C.CHARCOAL, 4.0, s + 2, 0.5, 1)      # the peak
			ci.draw_circle(Vector2(4, 0), 2.4, C.AMBER)                                     # the cap badge
			C.outline(ci, cap, C.CHARCOAL, 2.2, s + 3, 0.7)
		"qrf":
			var hel := _ell(Vector2.ZERO, 12.0, 12.0, s, 0.04)
			ci.draw_colored_polygon(hel, C.CHARCOAL)
			ci.draw_circle(Vector2(-3, -3), 4.0, C.GRAPHITE.lightened(0.25))
			C.outline(ci, hel, C.CHARCOAL, 2.0, s + 3, 0.5)
		_:
			var face := _ell(Vector2.ZERO, 11.0, 11.0, s, 0.05)
			ci.draw_colored_polygon(face, SKIN)
			# hair from the crown back, scribbled
			var hp := _ell(Vector2(-3, 0), 9.5, 10.5, s + 4, 0.12, 12)
			ci.draw_colored_polygon(hp, hair)
			for h in 8:
				var a := PI * 0.55 + h * 0.3
				C.line(ci, Vector2(-1, 0) + Vector2.from_angle(a) * 3.0, Vector2(-1, 0) + Vector2.from_angle(a) * 11.0, hair.darkened(0.3), 2.0, s + 10 + h, 0.6, 1)
			C.line(ci, Vector2(10, -1.5), Vector2(12.5, 0), C.CHARCOAL, 2.2, s + 5, 0.3, 1)   # the nose
			C.outline(ci, face, C.CHARCOAL, 2.2, s + 3, 0.7)


## A helmet worn over the head (32 x 32): dark dome, a pale strap, a glint.
static func helmet_head(ci, s := 0) -> void:
	var hel := _ell(Vector2(-1, 0), 13.0, 13.0, s, 0.04)
	ci.draw_colored_polygon(hel, Color("#1b2236"))
	C.hatch(ci, hel, C.CHARCOAL, 2.6, 0.8, s + 1, 1.8)
	ci.draw_circle(Vector2(-4, -4), 3.6, C.SLATE_LIGHT)
	C.line(ci, Vector2(9, -10), Vector2(9, 10), C.SLATE_LIGHT, 2.4, s + 2, 0.4, 1)
	C.outline(ci, hel, C.CHARCOAL, 2.2, s + 3, 0.5)


## Lying down (152 x 96 canvas), head toward +x: limbs flung, arms whole, mittens, boots.
## The injury is never drawn.
static func down(ci, key: String, s := 0) -> void:
	var lk := look(key)
	var body: Color = lk[0]
	var shade: Color = lk[1]
	# legs and boots
	for side: float in [-1.0, 1.0]:
		var hip := Vector2(-24, side * 7)
		var foot := Vector2(-56, side * (12 + 4 * C.rnd(s, int(side) + 2)))
		C.line(ci, hip, foot, shade, 9.0, s + 20 + int(side), 1.0, 1)
		var boot := _ell(foot + Vector2(-5, 0), 8.5, 5.5, s + 22 + int(side), 0.1, 10)
		ci.draw_colored_polygon(boot, BOOT)
	# arms, whole, flung out
	for side2: float in [-1.0, 1.0]:
		var sh := Vector2(10, side2 * 13)
		var elbow := Vector2(14, side2 * 27)
		var hand := Vector2(30 - 10 * C.rnd(s, 7 + int(side2)), side2 * 38)
		C.line(ci, sh, elbow, shade, 8.0, s + 30 + int(side2), 0.8, 1)
		C.line(ci, elbow, hand, body.darkened(0.1), 7.0, s + 32 + int(side2), 0.8, 1)
		ci.draw_circle(hand, 5.0, SKIN)
		C.outline(ci, _ell(hand, 5.0, 5.0, s + 34, 0.05, 8), C.CHARCOAL, 1.4, s + 34, 0.3)
	# the body
	var p := _ell(Vector2(-6, 0), 27.0, 16.0, s, 0.07)
	ci.draw_colored_polygon(p, body)
	C.hatch(ci, p, Color(shade, 0.85), 3.2, 0.7, s + 1, 2.4)
	C.outline(ci, p, C.CHARCOAL, 3.0, s + 2, 1.0)
	# the head
	ci.draw_set_transform(Vector2(30, 2), 0.0, Vector2.ONE)
	head(ci, key, s + 40)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Killed (176 x 176 canvas, origin where they stood, body frame: they faced +x). One of
## eight, by the direction the killing round travelled relative to where they faced
## (octant k: 0 = it came from behind, 4 = from the front, 2 = from their left, 6 = from
## their right). The body goes the way the blow drives it: shot from behind they pitch
## forward face down; from the front they go over backwards, face up, arms thrown back;
## from the side they fold onto that side, knees drawn up. The injury is never drawn.
static func dead(ci, key: String, k: int, s := 0) -> void:
	var lk := look(key)
	var body: Color = lk[0]
	var shade: Color = lk[1]
	var th := TAU * float(k) / 8.0
	var fwd := Vector2.from_angle(th)          # the way they fall
	var lat := fwd.orthogonal()
	var face_down := cos(th) > 0.3
	var face_up := cos(th) < -0.3
	var hips := -fwd * 10.0
	var chest := fwd * 14.0
	var head_c := fwd * 40.0 + lat * (C.rnd(s, k) - 0.5) * 8.0
	var r := RandomNumberGenerator.new()
	r.seed = s * 8 + k
	# legs and boots: straight and apart face down or up, drawn up on the side
	for side: float in [-1.0, 1.0]:
		var hip := hips + lat * side * 7.0
		var foot: Vector2
		var knee: Vector2
		if face_down or face_up:
			foot = hips - fwd * 38.0 + lat * side * r.randf_range(10.0, 20.0)
			knee = hip.lerp(foot, 0.5) + lat * side * 3.0
		else:
			knee = hips - fwd * 14.0 + lat * (12.0 + side * 6.0) * (1.0 if k == 2 else -1.0)
			foot = knee - fwd * r.randf_range(10.0, 20.0) + lat * side * 4.0
		C.line(ci, hip, knee, shade, 9.0, s + 20 + int(side), 0.8, 1)
		C.line(ci, knee, foot, shade, 8.5, s + 22 + int(side), 0.8, 1)
		var boot := C.ellipse_poly(foot - fwd * 4.0, 8.0, 5.2, 10, s + 24 + int(side), 0.1, (-fwd).angle())
		ci.draw_colored_polygon(boot, BOOT)
	# arms, whole, where the fall left them
	for side2: float in [-1.0, 1.0]:
		var sh := chest + lat * side2 * 13.0
		var hand: Vector2
		if face_up:
			hand = chest + fwd * r.randf_range(24.0, 40.0) + lat * side2 * r.randf_range(26.0, 40.0)
		elif face_down:
			hand = sh + (fwd * 30.0 + lat * side2 * 6.0 if side2 * (k - 4) <= 0.0 else -fwd * 20.0 + lat * side2 * 10.0)
		else:
			hand = chest + fwd * 14.0 + lat * (1.0 if k == 2 else -1.0) * (14.0 + side2 * 7.0)
		var elbow := sh.lerp(hand, 0.5) + lat * side2 * 6.0
		C.line(ci, sh, elbow, shade, 8.0, s + 30 + int(side2), 0.8, 1)
		C.line(ci, elbow, hand, body.darkened(0.1), 7.0, s + 32 + int(side2), 0.8, 1)
		ci.draw_circle(hand, 5.0, SKIN)
		C.outline(ci, C.ellipse_poly(hand, 5.0, 5.0, 8, s + 34, 0.05), C.CHARCOAL, 1.4, s + 34, 0.3)
	# the body, along the fall
	var torso_p := C.ellipse_poly((hips + chest) * 0.5, 28.0, 16.5, 16, s, 0.08, fwd.angle())
	ci.draw_colored_polygon(torso_p, body)
	C.hatch(ci, torso_p, Color(shade, 0.85), 3.2, fwd.angle() + 0.7, s + 1, 2.4)
	C.outline(ci, torso_p, C.CHARCOAL, 3.0, s + 2, 1.0)
	if key in ["a", "pd", "qrf"] and not face_down:
		var star := PackedVector2Array()
		for q in 10:
			star.append(chest - fwd * 4.0 + lat * 6.0 + Vector2.from_angle(TAU * q / 10.0) * (4.0 if q % 2 == 0 else 1.8))
		ci.draw_colored_polygon(star, C.AMBER)
	# the head: the back of it face down, the face (eyes shut) face up
	var hair: Color = lk[2]
	var police := key in ["a", "pd"]
	var hp := C.ellipse_poly(head_c, 11.5, 11.0, 14, s + 40, 0.05, fwd.angle())
	if key == "qrf":
		ci.draw_colored_polygon(hp, C.CHARCOAL)
	elif face_down:
		ci.draw_colored_polygon(hp, hair if not police else Color("#2a1d14"))
		for h in 7:
			var a := fwd.angle() + (h - 3) * 0.4
			C.line(ci, head_c - fwd * 3.0, head_c + Vector2.from_angle(a) * 10.0, Color(hair.darkened(0.3) if not police else Color("#1b130d")), 2.0, s + 50 + h, 0.5, 1)
	else:
		ci.draw_colored_polygon(hp, SKIN)
		var back := head_c + fwd * 5.0
		ci.draw_colored_polygon(C.ellipse_poly(back, 8.0, 10.5, 10, s + 41, 0.1, fwd.angle()), hair if not police else Color("#2a1d14"))
		for e: float in [-1.0, 1.0]:
			var ec := head_c - fwd * 3.0 + lat * e * 4.0
			C.line(ci, ec - lat * 2.0, ec + lat * 2.0, C.CHARCOAL, 1.6, s + 60 + int(e), 0.3, 1)
	C.outline(ci, hp, C.CHARCOAL, 2.2, s + 42, 0.7)
	# a police cap knocked off, lying beside them
	if police:
		var cap_c := head_c + fwd * 16.0 + lat * (14.0 if k % 2 == 0 else -14.0)
		var cap := C.ellipse_poly(cap_c, 9.5, 9.5, 12, s + 70, 0.05)
		ci.draw_colored_polygon(cap, lk[2])
		C.hatch(ci, cap, Color("#3b4a72"), 3.0, 0.5, s + 71, 1.8)
		ci.draw_circle(cap_c, 2.0, C.AMBER)
		C.outline(ci, cap, C.CHARCOAL, 2.0, s + 72, 0.6)
