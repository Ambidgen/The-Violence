extends RefCounted
## Contact-aware fast-forward policy. This class only classifies presentation
## events; it never changes the world, RNG, orders, or simulation clock.

const CONTACT_EVENTS := ["shot", "blood", "down", "surrender", "cuff", "flash", "explosion", "hostage", "order_broken", "less", "gas"]
const RADIO_WORDS := ["contact", "shots", "shot", "down", "killed", "injur", "hostage", "attack", "surrender", "cuff", "broken", "gas", "bang", "civilian"]


static func event_reason(ev: Dictionary) -> String:
	var typ := String(ev.get("type", ""))
	if typ not in CONTACT_EVENTS:
		return ""
	match typ:
		"shot": return "shots fired"
		"blood", "down": return "casualty"
		"surrender", "cuff": return "suspect compliance"
		"hostage": return "hostage event"
		"order_broken": return "order broken"
		"gas": return "important radio"
		_: return "contact"


static func log_reason(ln: Dictionary) -> String:
	var kind := String(ln.get("kind", ""))
	var text := String(ln.get("text", "")).to_lower()
	if kind in ["kill", "bad", "end"]:
		return "important radio"
	if kind == "hit" and ("wound" in text or "injur" in text or "hurt" in text or "hit in" in text):
		return "casualty"
	if kind == "comms":
		for word in RADIO_WORDS:
			if word in text:
				return "important radio"
	return ""


static func hold_seconds(reason: String) -> float:
	return 6.0 if reason == "casualty" else 4.0


## EA_TASKS P1.G1: the default is contact-aware fast-forward, both ways. Away from
## anything that matters the presentation runs QUIET_MULT times the speed the player asked
## for (capped at QUIET_CAP); for a few seconds after shots, a casualty or important radio
## it drops to 1x so the moment can be read. A player who asks for 1x keeps 1x: that is a
## deliberate choice, not a quiet stretch. Presentation only — the simulation, the RNG and
## the clock never see this number.
const QUIET_MULT := 3.0
const QUIET_CAP := 8.0

## EA_TASKS P1.G2: after a minute of its own clock with nothing the policy calls contact,
## the operation may be run out to its end and the report opened (the simulation still
## steps; only the watching is skipped).
const QUIET_SKIP_AFTER := 60.0


static func quiet_enough(quiet_s: float) -> bool:
	return quiet_s >= QUIET_SKIP_AFTER


static func speed_for(requested: float, now: float, slow_until: float, enabled: bool) -> float:
	if not enabled or requested <= 1.0:
		return requested
	if now < slow_until:
		return 1.0
	return minf(requested * QUIET_MULT, maxf(requested, QUIET_CAP))
