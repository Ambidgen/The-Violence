extends RefCounted
## The red-ink palette (v0.8): ink, stepped greys, paper, and one red. Red is the only
## colour that reaches the page; it marks where a plan touches a real room (routes,
## attention, alarms, consequence, blood) and every red mark has a second cue (a number,
## an outline, a dash, a label), so the screen still reads with red turned off.
##
## Everything that draws red goes through accent(), so the monochrome proof (F2) is one
## switch. Gore (F3) hides blood but never the evidence markers or the paperwork. Both
## are presentation only: nothing here touches the simulation.
##
## Static, so scenes, the gallery and headless harnesses use it without an autoload.

const PAPER := Color(0.93, 0.93, 0.91)   # #e6dfcd page, document stock, bright cut-outs
const FLOOR := Color(0.83, 0.83, 0.81)   # #D4D4CF room base, plan marks
const LIGHT := Color(0.75, 0.75, 0.73)   # #BFBFBA furniture tops, paper edges, equipment marks
const MID := Color(0.45, 0.45, 0.44)     # #6e675c labels, secondary edges, door swings
const DARK := Color(0.17, 0.17, 0.17)    # #2B2B2B deep room value, cast shadows (low alpha)
const INK := Color(0.07, 0.07, 0.07)     # #141313 walls, outlines, silhouettes
const RED := Color(0.70, 0.12, 0.15)     # #B31F26 signal red
const RED_OFF := Color(0.36, 0.36, 0.36) # what red becomes in the monochrome proof

static var red_ink_enabled := true
static var gore_enabled := true
## Bumped on every change, so anything that draws red can redraw when it moves.
static var rev := 0


## Signal red at an alpha (intensity is alpha only, never the hue), or its grey stand-in.
static func accent(alpha: float) -> Color:
	if red_ink_enabled:
		return Color(RED.r, RED.g, RED.b, alpha)
	return Color(RED_OFF.r, RED_OFF.g, RED_OFF.b, alpha)


## The accent as a BBCode colour for rich text.
static func accent_hex() -> String:
	return "#" + accent(1.0).to_html(false)


static func set_red_ink(on: bool) -> void:
	red_ink_enabled = on
	rev += 1


static func set_gore(on: bool) -> void:
	gore_enabled = on
	rev += 1


## A shadow cast at low alpha (Dark at about 0.2).
static func shadow(alpha := 0.2) -> Color:
	return Color(DARK.r, DARK.g, DARK.b, alpha)


## Rich text with the signal red ("#b31f26", optionally with an alpha suffix) swapped
## for the current accent, so the monochrome proof reaches the text panels too.
static func bb(s: String) -> String:
	return s if red_ink_enabled else s.replace("#b31f26", accent_hex())
