extends RefCounted
## The equipment database (v0.7.5). Every item is a record: its slot, weight, cost (for
## the v0.8 budget), who may carry it, and the numbers the simulation reads.
##
## A kit is what one operator carries:
##   {"primary": weapon id or "", "secondary": weapon id or "", "optic": optic id,
##    "armour": "none" | "vest" | "plates", "plates": 0-4, "head": "none" | "sof_helmet",
##    "gear": {gear id: count}}
## The simulation keeps two weapon slots under their old names: "rifle" is the primary
## slot and "pistol" the secondary, whatever is in them.
##
## Who may carry an item: "any"; "tactical" (Police tactical and Special operations, and
## department officers with five years on the job or Experience 3); "sof" (Special
## operations only).

const WHO_NAMES := {"any": "anyone", "tactical": "tactical training", "sof": "special operations only"}

## Weapons. Handling numbers are those of bible section 2.3-2.5: a_w and b_w add to and
## scale the Fitts time on target, s_w is the weapon's own dispersion (mrad), kappa its
## recoil per shot, cadence and snap the fastest and the usual split, switch the time to
## swing onto a target already acquired. pen is the round's class against walls and
## armour (see World.PEN); lethal scales the chance that a hit no armour stopped kills or
## downs; sound is the loudness class (Habits.SOUND). draw scales the holster draw.
const WEAPONS := {
	"service_pistol": {"name": "Service pistol (9 mm)", "short": "Pistol", "slot": "secondary", "cls": "pistol",
		"a_w": 0.00, "b_w": 1.00, "s_w": 2.5, "kappa": 9.0, "mag": 15, "spare": 2, "reload": 2.0, "stop": 0.003,
		"cadence": 0.15, "snap": 0.22, "switch": 0.06, "sound": "pistol", "pen": "pistol", "lethal": 1.0,
		"draw": 1.0, "kg": 0.9, "cost": 500, "who": "any",
		"desc": "The standard sidearm. Fifteen rounds."},
	"compact_pistol": {"name": "Compact pistol (9 mm)", "short": "Compact", "slot": "secondary", "cls": "pistol",
		"a_w": 0.00, "b_w": 1.00, "s_w": 3.2, "kappa": 10.0, "mag": 10, "spare": 2, "reload": 1.9, "stop": 0.003,
		"cadence": 0.16, "snap": 0.24, "switch": 0.06, "sound": "pistol", "pen": "pistol", "lethal": 0.95,
		"draw": 0.8, "kg": 0.6, "cost": 450, "who": "any",
		"desc": "Quicker out of the holster, ten rounds, less precise."},
	"heavy_pistol": {"name": "Heavy pistol (.45)", "short": ".45", "slot": "secondary", "cls": "pistol",
		"a_w": 0.01, "b_w": 1.02, "s_w": 2.6, "kappa": 13.0, "mag": 8, "spare": 3, "reload": 2.1, "stop": 0.003,
		"cadence": 0.20, "snap": 0.28, "switch": 0.07, "sound": "pistol_heavy", "pen": "pistol_heavy",
		"lethal": 1.2, "draw": 1.05, "kg": 1.1, "cost": 700, "who": "any",
		"desc": "Eight heavy rounds: more of them put a man down, slower to fire well."},
	"smg": {"name": "Submachine gun (9 mm)", "short": "SMG", "slot": "primary", "cls": "smg",
		"a_w": 0.03, "b_w": 0.85, "s_w": 1.6, "kappa": 3.0, "mag": 30, "spare": 3, "reload": 2.3, "stop": 0.004,
		"cadence": 0.08, "snap": 0.14, "switch": 0.07, "sound": "smg", "pen": "pistol", "lethal": 1.0,
		"draw": 0.85, "kg": 2.8, "cost": 1500, "who": "any",
		"desc": "Fast handling and fast follow-ups with pistol rounds: fewer go through walls."},
	"carbine": {"name": "Patrol carbine (5.56)", "short": "Carbine", "slot": "primary", "cls": "rifle",
		"a_w": 0.06, "b_w": 0.80, "s_w": 1.0, "kappa": 4.0, "mag": 30, "spare": 3, "reload": 2.6, "stop": 0.004,
		"cadence": 0.10, "snap": 0.18, "switch": 0.08, "sound": "rifle", "pen": "rifle", "lethal": 1.0,
		"draw": 1.0, "kg": 3.2, "cost": 1200, "who": "any",
		"desc": "The standard long gun (the v0.7 rifle). Thirty rounds."},
	"sbr": {"name": "Short-barrel rifle (5.56)", "short": "SBR", "slot": "primary", "cls": "rifle",
		"a_w": 0.045, "b_w": 0.78, "s_w": 1.15, "kappa": 4.6, "mag": 30, "spare": 3, "reload": 2.6, "stop": 0.004,
		"cadence": 0.10, "snap": 0.17, "switch": 0.075, "sound": "rifle_loud", "pen": "rifle", "lethal": 0.95,
		"draw": 0.9, "kg": 2.9, "cost": 1800, "who": "tactical",
		"desc": "Handier than the carbine in a hallway; louder, a little less precise."},
	"assault_rifle": {"name": "Assault rifle (7.62 short)", "short": "Rifle", "slot": "primary", "cls": "rifle",
		"a_w": 0.07, "b_w": 0.83, "s_w": 1.5, "kappa": 6.0, "mag": 30, "spare": 3, "reload": 2.8, "stop": 0.005,
		"cadence": 0.11, "snap": 0.20, "switch": 0.09, "sound": "rifle_loud", "pen": "rifle", "lethal": 1.15,
		"draw": 1.0, "kg": 3.6, "cost": 900, "who": "any",
		"desc": "The street's rifle: heavier rounds that put a man down more often, heavier recoil, slower on target."},
	"battle_rifle": {"name": "Battle rifle (7.62)", "short": "7.62", "slot": "primary", "cls": "rifle",
		"a_w": 0.10, "b_w": 0.86, "s_w": 0.9, "kappa": 7.5, "mag": 20, "spare": 3, "reload": 2.9, "stop": 0.004,
		"cadence": 0.14, "snap": 0.25, "switch": 0.10, "sound": "rifle_heavy", "pen": "heavy", "lethal": 1.3,
		"draw": 1.15, "kg": 4.6, "cost": 2600, "who": "tactical",
		"desc": "Goes through walls, cars and people. Slow to swing, twenty rounds."},
	"shotgun": {"name": "Pump shotgun (12 ga)", "short": "Shotgun", "slot": "primary", "cls": "shotgun",
		"a_w": 0.07, "b_w": 0.84, "s_w": 2.0, "kappa": 14.0, "mag": 6, "spare": 4, "reload": 3.6, "stop": 0.002,
		"cadence": 0.65, "snap": 0.70, "switch": 0.09, "sound": "shotgun", "pen": "buck", "lethal": 1.4,
		"spread": 0.03, "lethal_far": 0.7, "draw": 1.0, "kg": 3.6, "cost": 600, "who": "any",
		"desc": "Buckshot: the pattern spreads 3 cm a metre and hits hard up close, poorly past 20 m. Six shells. Takes breaching rounds."},
	"marksman": {"name": "Marksman rifle (7.62, magnified)", "short": "DMR", "slot": "primary", "cls": "rifle",
		"a_w": 0.12, "b_w": 0.90, "s_w": 0.45, "kappa": 7.0, "mag": 10, "spare": 3, "reload": 2.8, "stop": 0.003,
		"cadence": 0.45, "snap": 0.50, "switch": 0.11, "sound": "rifle_heavy", "pen": "heavy", "lethal": 1.3,
		"optic_fixed": "magnified", "draw": 1.2, "kg": 5.0, "cost": 3200, "who": "tactical",
		"desc": "Precise far out, slow up close. Ten rounds."},
}

## Sights on the primary weapon, relative to the red dot the v0.7 rifle had: near is
## inside 10 m, far beyond 25 m (b_w far applies beyond 10 m).
const OPTICS := {
	"irons": {"name": "Iron sights", "a_near": 0.0, "b_far": 1.25, "s_far": 1.15, "kg": 0.0, "cost": 0,
		"desc": "Slower on target beyond 10 m."},
	"red_dot": {"name": "Red dot", "a_near": 0.0, "b_far": 1.0, "s_far": 1.0, "kg": 0.2, "cost": 400,
		"desc": "The standard sight."},
	"magnified": {"name": "Magnified optic (1-6x)", "a_near": 0.06, "b_far": 0.95, "s_far": 0.6, "kg": 0.6, "cost": 1400,
		"desc": "Much more precise beyond 25 m, slower inside 10 m."},
}

const ARMOUR := {
	"none": {"name": "No armour", "kg": 0.0, "cost": 0},
	"vest": {"name": "Soft vest", "kg": 2.5, "cost": 700,
		"desc": "Stops pistol rounds and buckshot to the chest, from any side; not rifle rounds."},
	"plates": {"name": "Plate carrier", "kg": 3.0, "kg_plate": 2.5, "cost": 900, "cost_plate": 350,
		"desc": "Plates stop any round to the front of the chest, one plate segment a hit."},
}

const HEAD := {
	"none": {"name": "No helmet", "kg": 0.0, "cost": 0, "who": "any"},
	"sof_helmet": {"name": "Special operations helmet", "kg": 1.4, "cost": 4000, "who": "sof",
		"desc": "Stops the first head hit and is spent. The wearer is stunned: down on one knee, 2.5-4 s without aim or recognition, hearing gone for 15 s, stress +0.4. A second head hit kills as any would."},
}

## Accessories, by count. max is how many one person carries.
const GEAR := {
	"flashbang": {"name": "Flashbang", "short": "Bang", "kg": 0.45, "max": 3, "cost": 60, "who": "tactical",
		"desc": "Thrown into a room before the entry, 1.2 s fuse. Within 6 m with a line of sight: no recognition or aim for 3-5 s if facing it, 1.5-2.5 s if not; hearing gone for 10 s. Civilians too; within 1 m it burns."},
	"ram": {"name": "Door ram", "short": "Ram", "kg": 16.0, "max": 1, "cost": 400, "who": "any",
		"desc": "Opens a locked door in one to three blows of 1.2 s (six in ten land, more for a steady hand), heard at 30 m. Heavy: the carrier is slower."},
	"breach": {"name": "Breaching rounds", "short": "Breach", "kg": 0.4, "max": 1, "cost": 120, "who": "tactical",
		"needs": "shotgun", "desc": "Opens a locked door with one shotgun shot (0.8 s, nine times in ten). Needs the pump shotgun."},
	"shield": {"name": "Ballistic shield", "short": "Shield", "kg": 12.0, "max": 1, "cost": 3500, "who": "tactical",
		"desc": "Stops pistol and rifle rounds across 60 deg either side of the front: the body, nine head hits in ten, half the leg hits. Half of battle-rifle rounds go through. The carrier fights with the pistol, walks, and leads the entry."},
	"light": {"name": "Weapon light", "short": "Light", "kg": 0.15, "max": 1, "cost": 150, "who": "any",
		"desc": "At night, cancels the dark's penalty to recognizing anyone in its beam (30 deg either side, 25 m). Anyone who sees the beam sees the carrier as if by day."},
	"medkit": {"name": "Medical kit", "short": "Med", "kg": 0.6, "max": 1, "cost": 90, "who": "any",
		"desc": "Once the area is quiet, treats a downed person within 20 m (20 s): no bleeding out, and far better odds after the operation."},
	"stingball": {"name": "Sting-ball grenade", "short": "Sting", "kg": 0.45, "max": 3, "cost": 90, "who": "tactical",
		"fuse": 1.5, "radius": 5.0,
		"desc": "Thrown into a room before the entry in place of a flashbang, 1.5 s fuse: rubber pellets within 5 m with a line of sight. Down on one knee for 1-2.5 s, pain (stress +0.35), and those who show no weapon often give up. One in twenty-five within 2 m is hurt (an eye, a cut)."},
	"gas": {"name": "CS gas grenade", "short": "Gas", "kg": 0.5, "max": 2, "cost": 45, "who": "tactical",
		"fuse": 1.0, "linger": 90.0,
		"desc": "Thrown into a room, it fills it for 90 s. Anyone inside without a mask is gassed: three times slower to recognize anyone, aim twice as loose, coughing (stress). Suspects who will give up come out (and give up far more easily when challenged); civilians run; the defiant stay and suffer. The squad waits 20 s at the door before going in. Not thrown where hostages may be."},
	"gas_mask": {"name": "Gas mask", "short": "Mask", "kg": 0.8, "max": 1, "cost": 250, "who": "any",
		"desc": "Worn: no effect from CS gas or a pepper cloud. The visor slows recognizing anyone by a tenth."},
	"oc_spray": {"name": "OC (pepper) spray", "short": "OC", "kg": 0.2, "max": 1, "cost": 40, "who": "any",
		"less": true, "shots": 6, "range": 3.0, "min": 0.0, "p_hit": 0.85, "stun": [1.0, 2.0], "blind": 15.0, "give": 0.7,
		"splash": 1.2, "injury": 0.0, "act": 0.5,
		"desc": "Six bursts, 3 m. Eyes shut and burning: down for 1-2 s, then 15 s nearly blind (three times slower to recognize anyone, aim twice as loose); seven in ten give up. The cloud reaches anyone within 1.2 m of the target, officers too, unless masked."},
	"baton": {"name": "Expandable baton", "short": "Baton", "kg": 0.6, "max": 1, "cost": 60, "who": "any",
		"less": true, "shots": 99, "range": 1.6, "min": 0.0, "p_hit": 0.7, "stun": [1.5, 2.5], "blind": 0.0, "give": 0.45,
		"injury": 0.08, "serious": 0.02, "act": 0.6,
		"desc": "Strikes within arm's reach: knocked to a knee for 1.5-2.5 s, gives up nearly half the time. One strike in twelve breaks something (a wound); one in fifty is a head strike that puts the man down. The last tool tried: closest and most likely to hurt."},
	"taser": {"name": "Taser", "short": "Taser", "kg": 0.3, "max": 1, "cost": 1000, "who": "any",
		"less": true, "shots": 2, "range": 7.0, "min": 0.0, "p_hit": 0.75, "stun": [5.0, 5.0], "blind": 0.0, "give": 0.9,
		"injury": 0.01, "act": 0.4,
		"desc": "Two cartridges, 7 m. For someone covered and challenged who will not comply but shows no weapon: down for 5 s, and nearly always gives up. One in a hundred is hurt in the fall."},
	"pepperball": {"name": "Pepperball launcher", "short": "Pepperball", "kg": 3.2, "max": 1, "cost": 1600, "who": "tactical",
		"less": true, "shots": 10, "range": 18.0, "min": 2.0, "p_hit": 0.55, "stun": [0.5, 1.0], "blind": 8.0, "give": 0.5,
		"splash": 1.5, "injury": 0.01, "act": 0.4,
		"desc": "Ten volleys, 18 m. Powder balls burst into a pepper cloud: 8 s nearly blind, half give up. The cloud catches anyone within 1.5 m, unless masked."},
	"launcher": {"name": "40 mm launcher", "short": "40 mm", "kg": 3.0, "max": 1, "cost": 1300, "who": "tactical",
		"less": true, "shots": 5, "range": 30.0, "min": 3.0, "p_hit": 0.6, "stun": [3.0, 3.0], "blind": 0.0, "give": 0.6,
		"injury": 0.03, "close": 5.0, "serious_close": 0.12, "act": 0.4,
		"desc": "Five sponge rounds, 3-30 m. Knocked down for 3 s, gives up six times in ten. Three in a hundred are hurt; inside 5 m, one in eight is hurt badly enough to go down."},
	"beanbag": {"name": "Beanbag rounds", "short": "Beanbag", "kg": 0.3, "max": 1, "cost": 80, "who": "any",
		"needs": "shotgun", "less": true, "shots": 5, "range": 20.0, "min": 4.0, "p_hit": 0.65, "stun": [2.5, 3.5],
		"blind": 0.0, "give": 0.55, "injury": 0.05, "close": 6.0, "serious_close": 0.2, "act": 0.7,
		"desc": "Five rounds for the pump shotgun, 4-20 m. Knocked down for 2.5-3.5 s, gives up a little over half the time. One in twenty is hurt; inside 6 m, one in five is hurt badly enough to go down. Needs the pump shotgun."},
}

## The direct less-lethal tools in the order an officer reaches for them: the least
## likely to hurt first, among those in range.
const LESS_ORDER := ["oc_spray", "taser", "pepperball", "launcher", "beanbag", "baton"]
const THROWN := ["flashbang", "stingball", "gas"]

const GEAR_ORDER := ["flashbang", "stingball", "gas", "ram", "breach", "shield", "light", "medkit", "gas_mask",
	"oc_spray", "baton", "taser", "pepperball", "launcher", "beanbag"]
const PRIMARY_ORDER := ["carbine", "sbr", "smg", "shotgun", "battle_rifle", "marksman", "assault_rifle"]
const SECONDARY_ORDER := ["service_pistol", "compact_pistol", "heavy_pistol"]

## Kits by echelon for the test range. Every echelon but the untrained keeps the v0.7
## carbine and service pistol, so the matchups of earlier versions still stand.
const PRESETS := {
	"untrained": {"primary": "", "secondary": "service_pistol", "optic": "red_dot", "armour": "none", "plates": 0,
		"head": "none", "gear": {}},
	"militia": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "none", "plates": 0,
		"head": "none", "gear": {}},
	"patrol": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "vest", "plates": 0,
		"head": "none", "gear": {"light": 1, "medkit": 1, "taser": 1, "oc_spray": 1, "baton": 1}},
	"regular": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
		"head": "none", "gear": {"medkit": 1}},
	"police": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
		"head": "none", "gear": {"light": 1, "medkit": 1, "flashbang": 1, "oc_spray": 1}},
	"sof": {"primary": "sbr", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 3,
		"head": "sof_helmet", "gear": {"light": 1, "medkit": 1, "flashbang": 2}},
}

## What a new department officer is issued.
const DEPT_DEFAULT := {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "vest",
	"plates": 0, "head": "none", "gear": {"light": 1, "medkit": 1, "taser": 1, "oc_spray": 1, "baton": 1}}

## Ready-made squad kits on the Force screen: [name, kit for the point man, kit for the rest].
const SQUAD_KITS := {
	"patrol": {"name": "Patrol", "point": DEPT_DEFAULT, "rest": DEPT_DEFAULT},
	"entry": {"name": "Entry",
		"point": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"ram": 1, "medkit": 1, "light": 1}},
		"rest": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"flashbang": 1, "medkit": 1, "light": 1}}},
	"shield": {"name": "Shield",
		"point": {"primary": "", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"shield": 1, "light": 1}},
		"rest": {"primary": "sbr", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"flashbang": 1, "medkit": 1, "light": 1}}},
	"less": {"name": "Less-lethal",
		"point": {"primary": "shotgun", "secondary": "service_pistol", "optic": "red_dot", "armour": "vest", "plates": 0,
			"head": "none", "gear": {"beanbag": 1, "launcher": 1, "oc_spray": 1, "baton": 1, "medkit": 1}},
		"rest": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "vest", "plates": 0,
			"head": "none", "gear": {"taser": 1, "pepperball": 1, "oc_spray": 1, "baton": 1, "medkit": 1, "light": 1}}},
	"gas": {"name": "Gas",
		"point": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"gas": 2, "gas_mask": 1, "ram": 1, "medkit": 1}},
		"rest": {"primary": "carbine", "secondary": "service_pistol", "optic": "red_dot", "armour": "plates", "plates": 2,
			"head": "none", "gear": {"gas_mask": 1, "stingball": 1, "taser": 1, "oc_spray": 1, "medkit": 1, "light": 1}}},
}


static func weapon(id: String) -> Dictionary:
	return WEAPONS.get(id, {})


static func preset(echelon: String) -> Dictionary:
	return (PRESETS.get(echelon, PRESETS["militia"]) as Dictionary).duplicate(true)


static func default_kit() -> Dictionary:
	return DEPT_DEFAULT.duplicate(true)


## The training level a test-range echelon counts as.
static func who_of_echelon(echelon: String) -> String:
	if echelon == "sof":
		return "sof"
	if echelon == "police":
		return "tactical"
	return "any"


## A department officer: tactical with five years on the job, Experience 3, or the
## tactical team certification (v0.8.5).
static func who_of_record(r: Dictionary) -> String:
	if float(r.get("years", 0.0)) >= 5.0 or int(r.get("exp", 1)) >= 3 or r.get("tactical", false):
		return "tactical"
	return "any"


static func allowed(item_who: String, who: String) -> bool:
	match item_who:
		"any":
			return true
		"tactical":
			return who == "tactical" or who == "sof"
		"sof":
			return who == "sof"
	return false


## The kit with everything the carrier may not have taken out, and counts capped.
static func validate(kit: Dictionary, who: String) -> Dictionary:
	var k := normalize(kit)
	if k["primary"] != "" and not allowed(WEAPONS[k["primary"]]["who"], who):
		k["primary"] = "carbine"
	if k["secondary"] != "" and not allowed(WEAPONS[k["secondary"]]["who"], who):
		k["secondary"] = "service_pistol"
	if not allowed(HEAD[k["head"]]["who"], who):
		k["head"] = "none"
	var g := {}
	for gid in k["gear"]:
		var spec: Dictionary = GEAR[gid]
		if not allowed(spec["who"], who):
			continue
		if spec.has("needs") and k["primary"] != spec["needs"]:
			continue
		var n: int = clampi(int(k["gear"][gid]), 0, int(spec["max"]))
		if n > 0:
			g[gid] = n
	k["gear"] = g
	if g.has("shield"):
		k["primary"] = ""
	return k


## Fill in anything missing (old saves, hand-written kits).
static func normalize(kit: Dictionary) -> Dictionary:
	var k := kit.duplicate(true)
	if not k.has("primary") or (k["primary"] != "" and not WEAPONS.has(k["primary"])):
		k["primary"] = "carbine"
	if not k.has("secondary") or (k["secondary"] != "" and not WEAPONS.has(k["secondary"])):
		k["secondary"] = "service_pistol"
	if not OPTICS.has(k.get("optic", "")):
		k["optic"] = "red_dot"
	if not ARMOUR.has(k.get("armour", "")):
		k["armour"] = "none"
	k["plates"] = clampi(int(k.get("plates", 0)), 0, 4)
	if k["armour"] == "plates" and k["plates"] == 0:
		k["plates"] = 2
	if k["armour"] != "plates":
		k["plates"] = 0
	if not HEAD.has(k.get("head", "")):
		k["head"] = "none"
	var g := {}
	for gid in k.get("gear", {}):
		if GEAR.has(gid) and int(k["gear"][gid]) > 0:
			g[gid] = int(k["gear"][gid])
	k["gear"] = g
	return k


static func weight(kit: Dictionary) -> float:
	var k := normalize(kit)
	var kg := 0.0
	for slot in ["primary", "secondary"]:
		if k[slot] != "":
			kg += float(WEAPONS[k[slot]]["kg"])
	if k["primary"] != "":
		kg += float(OPTICS[k["optic"]]["kg"])
	kg += float(ARMOUR[k["armour"]]["kg"]) + float(ARMOUR["plates"]["kg_plate"]) * k["plates"]
	kg += float(HEAD[k["head"]]["kg"])
	for gid in k["gear"]:
		kg += float(GEAR[gid]["kg"]) * int(k["gear"][gid])
	return kg


static func cost(kit: Dictionary) -> int:
	var k := normalize(kit)
	var c := 0
	for slot in ["primary", "secondary"]:
		if k[slot] != "":
			c += int(WEAPONS[k[slot]]["cost"])
	if k["primary"] != "":
		c += int(OPTICS[k["optic"]]["cost"])
	c += int(ARMOUR[k["armour"]]["cost"]) + int(ARMOUR["plates"].get("cost_plate", 0)) * k["plates"]
	c += int(HEAD[k["head"]]["cost"])
	for gid in k["gear"]:
		c += int(GEAR[gid]["cost"]) * int(k["gear"][gid])
	return c


## Speed lost to carried weight beyond the plates (whose cost is counted separately):
## 0.6% a kilogram past 5 kg, so a ram costs about a tenth of the pace.
static func speed_factor(kit: Dictionary) -> float:
	var k := normalize(kit)
	var kg: float = weight(k) - float(ARMOUR["plates"]["kg_plate"]) * k["plates"] - float(ARMOUR[k["armour"]]["kg"])
	return clampf(1.0 - 0.006 * maxf(0.0, kg - 5.0), 0.8, 1.0)


## One line for a roster or a tooltip: "Carbine, pistol; plates (2); bang x2, med".
static func describe(kit: Dictionary) -> String:
	var k := normalize(kit)
	var parts: Array = []
	var guns: Array = []
	if k["primary"] != "":
		var p: String = WEAPONS[k["primary"]]["short"]
		if k["optic"] != "red_dot" and not WEAPONS[k["primary"]].has("optic_fixed"):
			p += " (%s)" % ("irons" if k["optic"] == "irons" else "scope")
		guns.append(p)
	if k["secondary"] != "":
		guns.append(String(WEAPONS[k["secondary"]]["short"]).to_lower() if not guns.is_empty() else WEAPONS[k["secondary"]]["short"])
	parts.append(", ".join(guns) if not guns.is_empty() else "Unarmed")
	match k["armour"]:
		"vest":
			parts.append("vest")
		"plates":
			parts.append("plates (%d)" % k["plates"])
	if k["head"] == "sof_helmet":
		parts.append("SOF helmet")
	var g: Array = []
	for gid in GEAR_ORDER:
		if k["gear"].has(gid):
			var n: int = k["gear"][gid]
			g.append(String(GEAR[gid]["short"]).to_lower() + (" x%d" % n if n > 1 else ""))
	if not g.is_empty():
		parts.append(", ".join(g))
	return "; ".join(parts)


## Gear counts as the simulation tracks them: flashbangs and less-lethal shots by number.
static func gear_counts(kit: Dictionary) -> Dictionary:
	var k := normalize(kit)
	var out := {}
	for gid in k["gear"]:
		var spec: Dictionary = GEAR[gid]
		out[gid] = int(k["gear"][gid]) * int(spec.get("shots", 1))
		if gid == "breach":
			out[gid] = 4
	return out
