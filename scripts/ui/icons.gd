extends RefCounted
## Crayon icons for the campaign UI (2026-11-03: "less wordy, more symbol and button
## based"). Each icon is a tiny hand-drawn SVG in the opening's palette, rasterised at
## runtime (Image.load_svg_from_string), so there is no import step and no art pipeline:
## an icon is a string here. Ink outlines are slightly uneven on purpose.

const K := "#1e1b1c"   # ink
const R := "#ff2b30"   # red
const B := "#2747e6"   # police blue
const Y := "#ffd60a"   # sun
const G := "#2fcf3f"   # grass
const W := "#ffffff"
const P := "#ff8fab"   # pink
const O := "#ffb36b"   # orange
const S := "#16b7ff"   # sky
const DG := "#22a52a"  # a tick

static var _cache := {}


static func _svg(body: String) -> String:
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="%s" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">%s</svg>' % [K, body])


## Every icon's drawing (24 x 24, ink strokes, crayon fills).
static func _body(id: String) -> String:
	match id:
		"week":
			return '<rect x="3.5" y="5" width="17" height="15.5" rx="1.5" fill="%s"/><path d="M3.6 9.6h16.8"/><path d="M8 3v4M16 3v4"/><path d="M8 13.5h2M12 13.6h2M16 13.4h1M8 17h2M12 17.1h2" stroke-width="1.6"/>' % W
		"money":
			return '<rect x="2.5" y="6" width="19" height="12" rx="1.5" fill="%s"/><circle cx="12" cy="12" r="3.2" fill="%s"/><path d="M5.5 9v6M18.5 9v6" stroke-width="1.5"/>' % [G, W]
		"end_week":
			return '<path d="M15.5 4.5a7.6 7.6 0 1 0 4 10.4a6 6 0 0 1-4-10.4z" fill="%s"/><path d="M4 21h9" stroke-width="1.6"/>' % Y
		"paper":
			return '<path d="M4 4.5h13v15.5H6a2 2 0 0 1-2-2z" fill="%s"/><path d="M17 8.5h3v10a1.6 1.6 0 0 1-3 0" fill="%s"/><path d="M6.5 8h8" stroke="%s" stroke-width="2.4"/><path d="M6.6 11.8h7.6M6.5 14.8h7.8M6.6 17.6h5" stroke-width="1.4"/>' % [W, W, R]
		"menu":
			return '<path d="M4 6.5h16M4.2 12h15.6M4 17.5h16"/>'
		"close":
			return '<path d="M6 6l12 12M18 6L6 18"/>'
		"back":
			return '<path d="M19.5 12H5M10.5 6.2L4.6 12l5.9 5.8"/>'
		"next":
			return '<path d="M4.5 12H19M13.5 6.2l5.9 5.8-5.9 5.8"/>'
		"open":
			return '<path d="M9 5.5l6.5 6.5L9 18.5"/>'
		"map":
			return '<path d="M3.5 6l5.5-2 6 2 5.5-2v14l-5.5 2-6-2-5.5 2z" fill="%s"/><path d="M9 4v14M15 6v14"/><circle cx="17.5" cy="9.5" r="1.7" fill="%s" stroke-width="1.4"/>' % [Y, R]
		"plan", "briefing":
			return '<rect x="5" y="4.5" width="14" height="16" rx="1.5" fill="%s"/><rect x="8.5" y="3" width="7" height="3.5" rx="1" fill="%s"/><path d="M8 11h8M8 14.5h8M8 17.8h5" stroke-width="1.5"/>' % [W, Y]
		"force", "roster":
			return '<circle cx="8.5" cy="8" r="3" fill="%s"/><path d="M3 20c.4-4 2.6-6 5.5-6s5.1 2 5.5 6z" fill="%s"/><circle cx="16.5" cy="9" r="2.6" fill="%s"/><path d="M14.6 14.4c.6-.3 1.2-.4 1.9-.4 2.6 0 4.5 1.8 4.9 5.6h-5.4" fill="%s"/>' % ["#ffc39a", B, "#ffc39a", B]
		"orders":
			return '<path d="M6 21V3.5"/><path d="M6.2 4.5h11.5l-2.6 3.7 2.6 3.8H6.2z" fill="%s"/>' % R
		"suggest":
			return '<path d="M12 3a6 6 0 0 0-3.5 10.9V16.5h7v-2.6A6 6 0 0 0 12 3z" fill="%s"/><path d="M9.2 19.2h5.6M10.3 21.6h3.4"/>' % Y
		"run", "play":
			return '<path d="M7 4.5v15l12.5-7.5z" fill="%s"/>' % R
		"pause":
			return '<rect x="6" y="5" width="4" height="14" rx="1" fill="%s"/><rect x="14" y="5" width="4" height="14" rx="1" fill="%s"/>' % [B, B]
		"rewind":
			return '<path d="M11.5 6.5v11L4 12zM20 6.5v11L12.5 12z" fill="%s"/>' % S
		"live":
			return '<circle cx="12" cy="12" r="5.5" fill="%s"/><circle cx="12" cy="12" r="9" stroke-width="1.4"/>' % R
		"skip":
			return '<path d="M4 6v12l8-6zM12 6v12l7-6z" fill="%s"/><path d="M20.5 5.5v13"/>' % Y
		"abort":
			return '<path d="M5.5 21V3.5"/><path d="M5.7 4.5c3-1.5 5.5 1.2 8.5 0s4.3-.5 5 0v7.5c-.7-.5-2-1.2-5 0s-5.5-1.5-8.5 0z" fill="%s"/>' % W
		"check", "choose", "accept", "yes":
			return '<path d="M4.5 12.5l4.7 4.7L19.5 6.5" stroke="%s" stroke-width="3"/>' % DG
		"no", "decline", "pass":
			return '<path d="M6.5 6.5l11 11M17.5 6.5l-11 11" stroke="%s" stroke-width="2.8"/>' % R
		"hire", "add":
			return '<circle cx="9" cy="8" r="3.2" fill="%s"/><path d="M3 20c.4-4.2 2.8-6.2 6-6.2s5.6 2 6 6.2z" fill="%s"/><path d="M18.5 7v7M15 10.5h7" stroke="%s" stroke-width="2.4"/>' % ["#ffc39a", B, DG]
		"dismiss":
			return '<circle cx="9" cy="8" r="3.2" fill="%s"/><path d="M3 20c.4-4.2 2.8-6.2 6-6.2s5.6 2 6 6.2z" fill="%s"/><path d="M15 10.5h7" stroke="%s" stroke-width="2.4"/>' % ["#ffc39a", "#8e8a95", R]
		"train":
			return '<path d="M2.5 9.5L12 5l9.5 4.5L12 14z" fill="%s"/><path d="M6.5 11.5v4.5c3.5 2.6 7.5 2.6 11 0v-4.5"/><path d="M20.5 10v6"/>' % B
		"budget":
			return '<circle cx="12" cy="12" r="8.5" fill="%s"/><path d="M14.8 8.8c-.6-1-1.6-1.4-2.8-1.4-1.6 0-2.8.9-2.8 2.2 0 3 5.8 1.6 5.8 4.6 0 1.4-1.3 2.3-3 2.3-1.3 0-2.4-.5-3-1.5M12 5.8v1.6M12 16.5v1.7" stroke-width="1.8"/>' % Y
		"ia":
			return '<circle cx="10" cy="10" r="6" fill="%s"/><path d="M14.5 14.5l6 6" stroke-width="3"/><path d="M7.5 10.2l1.8 1.8 3.5-3.6" stroke="%s" stroke-width="1.8"/>' % [W, R]
		"armoury":
			return '<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.5-4.3-1.5-7.5-4.9-7.5-9.5V6z" fill="%s"/><path d="M12 7.5v9M8 11.5h8" stroke="%s" stroke-width="2.2"/>' % [B, W]
		"file":
			return '<path d="M3 6.5a1.5 1.5 0 0 1 1.5-1.5h5l2 2.2h8a1.5 1.5 0 0 1 1.5 1.5v9.8a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 18.5z" fill="%s"/>' % O
		"hall":
			return '<path d="M3 9.5L12 4l9 5.5z" fill="%s"/><path d="M4 20.5h16M3 9.6h18"/><path d="M6.5 11.5v7M10.2 11.5v7M13.8 11.5v7M17.5 11.5v7" stroke-width="1.8"/>' % P
		"people":
			return '<path d="M4 5h11a1.5 1.5 0 0 1 1.5 1.5v6A1.5 1.5 0 0 1 15 14H9l-4 3.5V14H4a1.5 1.5 0 0 1-1.5-1.5v-6A1.5 1.5 0 0 1 4 5z" fill="%s"/><path d="M18.5 9h1.5A1.5 1.5 0 0 1 21.5 10.5v5.5a1.5 1.5 0 0 1-1.5 1.5h-.5v3l-3.5-3h-4" fill="%s"/>' % [W, Y]
		"canvass":
			return '<path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z" fill="%s"/><circle cx="12" cy="12" r="3" fill="%s"/>' % [W, B]
		"eye":
			return '<path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z" fill="%s"/><circle cx="12" cy="12" r="2.6" fill="%s"/>' % [W, K]
		"clock":
			return '<circle cx="12" cy="12.5" r="8.5" fill="%s"/><path d="M12 7.5v5.2l3.4 2.2"/>' % W
		"trust":
			return '<path d="M12 20s-8-4.6-8-10.3A4.4 4.4 0 0 1 12 7a4.4 4.4 0 0 1 8 2.7C20 15.4 12 20 12 20z" fill="%s"/>' % P
		"hurt":
			return '<rect x="3" y="8.5" width="18" height="7" rx="3.5" fill="%s" transform="rotate(-35 12 12)"/><path d="M10.5 11.5h.1M13.5 12.5h.1M12 10h.1M12 14h.1" stroke-width="2.2"/>' % "#ffc39a"
		"busy":
			return '<path d="M3.5 15.5l2.2-5.5h12.6l2.2 5.5v3h-17z" fill="%s"/><path d="M8.5 7h7" stroke="%s" stroke-width="2.4"/><circle cx="7.5" cy="18.5" r="1.8" fill="%s"/><circle cx="16.5" cy="18.5" r="1.8" fill="%s"/>' % [W, R, K, K]
		"morale":
			return '<circle cx="12" cy="12" r="8.5" fill="%s"/><path d="M8.5 14c1 1.4 2.1 2 3.5 2s2.5-.6 3.5-2"/><path d="M9 9.8h.1M15 9.8h.1" stroke-width="2.6"/>' % Y
		"payroll":
			return '<path d="M5 3.5h14v17l-2.3-1.5-2.4 1.5-2.3-1.5-2.3 1.5-2.4-1.5L5 20.5z" fill="%s"/><path d="M8.5 8h7M8.5 11.5h7M8.5 15h4" stroke-width="1.5"/>' % W
		"income":
			return '<path d="M12 20V5M6 10.5L12 4.5l6 6" stroke="%s" stroke-width="2.6"/>' % DG
		"desk":
			return '<path d="M3 9h18v3H3z" fill="%s"/><path d="M5 12v8M19 12v8"/><rect x="7" y="4.5" width="7" height="4.5" fill="%s" stroke-width="1.6"/>' % [O, W]
		"event":
			return '<path d="M12 3.5l9.5 16.5h-19z" fill="%s"/><path d="M12 9.5v5M12 17.4v.1" stroke-width="2.4"/>' % Y
		"offer":
			return '<rect x="3" y="6" width="18" height="12.5" rx="1.5" fill="%s"/><path d="M3.3 6.5L12 13l8.7-6.5"/>' % W
		"radio":      # 2026-11-11: the patrol radio (a handset, its aerial, a lit dial)
			return '<path d="M9.5 8V2.8"/><rect x="6.5" y="8" width="11" height="13" rx="2" fill="%s"/><path d="M9.5 12h5" stroke="%s"/><path d="M9.5 14.6h5" stroke="%s"/><circle cx="12" cy="18" r="1.4" fill="%s" stroke-width="1.4"/>' % [B, W, W, Y]
		"help":
			return '<circle cx="12" cy="12" r="9" fill="%s"/><path d="M9.3 9.4a2.8 2.8 0 1 1 3.8 2.6c-.8.3-1.1.9-1.1 1.7v.6M12 17.4v.1" stroke-width="2.2"/>' % Y
		"fold":
			return '<path d="M6 12h12"/>'
		"unfold":
			return '<path d="M6 12h12M12 6v12"/>'
		"plus":
			return '<path d="M12 5.5v13M5.5 12h13" stroke-width="2.6"/>'
		"minus":
			return '<path d="M5.5 12h13" stroke-width="2.6"/>'
		"place":
			return '<path d="M12 21s-6.5-6.2-6.5-11A6.5 6.5 0 0 1 18.5 10c0 4.8-6.5 11-6.5 11z" fill="%s"/><circle cx="12" cy="10" r="2.2" fill="%s"/>' % [R, W]
		"route":
			return '<circle cx="5.5" cy="18.5" r="2.2" fill="%s"/><circle cx="18.5" cy="5.5" r="2.2" fill="%s"/><path d="M7.5 17.5c4-1 2-5.5 5-7s4.5-1 4.8-3" stroke-dasharray="2.5 2.5"/>' % [B, R]
		"rooms":
			return '<rect x="3.5" y="4.5" width="17" height="15" fill="%s"/><path d="M12 4.5v6.5M12 14v5.5M3.5 12h5M15 12h5.5"/>' % W
		"door":
			return '<rect x="6" y="3.5" width="12" height="17" fill="%s"/><path d="M3.5 20.5h17"/><circle cx="15" cy="12.5" r="1" fill="%s"/>' % [O, K]
		"squad":
			return '<circle cx="7" cy="9" r="2.4" fill="%s"/><circle cx="12" cy="7.5" r="2.4" fill="%s"/><circle cx="17" cy="9" r="2.4" fill="%s"/><path d="M3.5 19c.3-3 1.6-4.6 3.5-4.6M20.5 19c-.3-3-1.6-4.6-3.5-4.6M8 19.5c.3-3.8 1.8-6 4-6s3.7 2.2 4 6z" fill="%s"/>' % ["#ffc39a", "#ffc39a", "#ffc39a", B]
		"kit":
			return '<rect x="3.5" y="8" width="17" height="11.5" rx="1.5" fill="%s"/><path d="M9 8V5.5h6V8M12 11v5M9.5 13.5h5" stroke-width="1.9"/>' % O
		"bodycam":
			return '<rect x="5" y="6" width="14" height="12" rx="2" fill="%s"/><circle cx="12" cy="12" r="3" fill="%s"/><circle cx="16.4" cy="8.4" r=".8" fill="%s" stroke="none"/>' % [K, S, R]
		"documents":
			return '<rect x="6" y="3" width="13" height="16" rx="1" fill="%s"/><rect x="4" y="5" width="13" height="16" rx="1" fill="%s"/><path d="M7 10h7M7 13.5h7M7 17h4" stroke-width="1.4"/>' % [P, W]
		"vote":
			return '<path d="M4 12.5h16v8H4z" fill="%s"/><path d="M8 12.5V4h8v8.5" fill="%s"/><path d="M9.8 8.3l1.6 1.6 3-3" stroke-width="1.7"/>' % [B, W]
		"new":
			return '<path d="M12 3.5l2.4 5.2 5.6.6-4.2 3.8 1.2 5.6L12 15.9l-5 2.8 1.2-5.6L4 9.3l5.6-.6z" fill="%s"/>' % Y
		"suspend":
			return '<rect x="5.5" y="10.5" width="13" height="10" rx="1.5" fill="%s"/><path d="M8.5 10.5V7.5a3.5 3.5 0 0 1 7 0v3"/>' % Y
		"clear":
			return '<path d="M5 19l9.5-9.5 3.5 3.5L10 21H6z" fill="%s"/><path d="M14.5 9.5l3-3 3.5 3.5-3 3"/>' % P
		"warrant":
			return '<path d="M5 3.5h10l4 4v13H5z" fill="%s"/><path d="M15 3.5v4h4"/><circle cx="12" cy="14.5" r="3" fill="%s"/>' % [W, R]
		"guns":
			return '<rect x="3.5" y="9" width="17" height="11" fill="%s"/><path d="M3.5 9l3-4.5h11l3 4.5M8 13h8" stroke-width="1.8"/>' % O
		"barricade":
			return '<rect x="5.5" y="3.5" width="13" height="17" fill="%s"/><path d="M3.5 8.5l17 3.5M3.5 15l17-3" stroke="%s" stroke-width="3"/>' % [W, O]
		"hostage":
			return '<circle cx="12" cy="7" r="3" fill="%s"/><path d="M6 20.5c.4-5 2.6-7.5 6-7.5s5.6 2.5 6 7.5z" fill="%s"/><path d="M8 15.5h8" stroke="%s" stroke-width="2.6"/>' % ["#ffc39a", W, R]
		"rally":
			return '<path d="M4 10v4l3 .5 9 4.5V5L7 9.5z" fill="%s"/><path d="M19 9.5c1 .8 1.5 1.6 1.5 2.5s-.5 1.7-1.5 2.5M6.5 14.5l1 5h2.5l-.5-4.5"/>' % R
		"truce":
			return '<path d="M3 12l4-4 3 1.5 3-1.5 4 2 4 4-5 4.5-3-2.5-3 1z" fill="%s"/>' % Y
		"done":
			return '<path d="M5 4.5h10l4 4v12H5z" fill="%s"/><path d="M8 13.5l2.5 2.5 5-5.5" stroke="%s" stroke-width="2.4"/>' % [W, "#22a52a"]
		"unattended":
			return '<circle cx="12" cy="12" r="8.5" fill="%s"/><path d="M6 6l12 12"/>' % "#e9e2d2"
		"guide":
			return '<path d="M12 3.5l2.5 7.5-2.5 9.5-2.5-9.5z" fill="%s"/><circle cx="12" cy="12" r="8.5"/>' % R
	return '<circle cx="12" cy="12" r="7" fill="%s"/>' % W


## The icon as a texture, `px` pixels square.
static func tex(id: String, px := 22) -> Texture2D:
	var key := "%s@%d" % [id, px]
	if _cache.has(key):
		return _cache[key]
	var img := Image.new()
	var err := img.load_svg_from_string(_svg(_body(id)), float(px) / 24.0)
	var t: Texture2D = null
	if err == OK and not img.is_empty():
		t = ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


## Button text -> icon: the first rule whose words appear in the label wins. Keeps every
## button in the campaign UI pictured without touching each call site.
const RULES := [
	["end week", "end_week"], ["suggest", "suggest"], ["brief and plan", "plan"],
	["abandon the program", "no"], ["training program", "train"], ["plan", "plan"], ["new run", "new"], ["run", "run"], ["briefing", "briefing"],
	["force", "force"], ["orders", "orders"], ["back to the map", "map"], ["map", "map"],
	["main menu", "menu"], ["board", "map"], ["back", "back"], ["call ", "open"],
	["open conversation", "people"], ["read document", "documents"], ["open", "open"],
	["choose", "check"], ["pick rooms", "rooms"], ["pick doors", "door"], ["pick", "check"],
	["accept", "check"], ["yes", "check"], ["sign", "hire"], ["hire", "hire"],
	["decline", "no"], ["not now", "no"], ["pass", "no"], ["cancel", "no"], ["abandon", "no"],
	["dismiss", "dismiss"], ["suspend", "suspend"], ["train", "train"], ["course", "train"],
	["enrol", "train"], ["abort", "abort"], ["withdraw", "abort"], ["pause", "pause"],
	["play", "play"], ["live", "live"], ["skip guide", "close"], ["skip", "skip"],
	["roster", "roster"], ["budget", "budget"], ["grant", "budget"], ["internal affairs", "ia"],
	["armoury", "armoury"], ["campaign file", "file"], ["documents", "documents"],
	["city hall", "hall"], ["people", "people"], ["election", "vote"], ["canvass", "canvass"],
	["body camera", "bodycam"], ["kit", "kit"], ["add a squad", "squad"], ["remove squad", "no"],
	["squad", "squad"], ["place", "place"], ["route", "route"], ["clear", "clear"],
	["next", "next"], ["the week", "paper"], ["menu", "menu"],
]


static func for_label(text: String) -> String:
	var t := text.to_lower()
	for r in RULES:
		if String(r[0]) in t:
			return String(r[1])
	return ""
