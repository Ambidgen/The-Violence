extends RefCounted
## Static design data from "The Violence - NPC CQB Bible": the 40 good habits,
## the 20 bad habits with the good habits each overrides, echelon presets
## (section 2.1) and the two weapons used in this slice (section 3.1).

const GROUPS := ["Pathfinding", "Group discipline", "Eye discipline", "Weapon discipline"]

const GOOD := [
	{"id": "PF01", "name": "Avoid the fatal funnel", "group": "Pathfinding",
		"with": "Doorway cells cost x8 to path through; never stops in a doorway, crosses at full speed.",
		"without": "Stops in the doorway to look, 1-2 s."},
	{"id": "PF02", "name": "Exposure-weighted routing", "group": "Pathfinding",
		"with": "Path cost +3 per door or window that sees the cell (cap +9); ducks under window sills.",
		"without": "Shortest distance, standing."},
	{"id": "PF03", "name": "Slice the pie", "group": "Pathfinding",
		"with": "Approaches doorways on a 2 m arc at 1 m/s, revealing the room a slice at a time.",
		"without": "Walks straight to the door."},
	{"id": "PF04", "name": "Points of domination", "group": "Pathfinding",
		"with": "On entry, gets 2 m along the wall to a corner position within 1.5 s.",
		"without": "Stops about 1 m inside the door."},
	{"id": "PF05", "name": "Standoff from cover", "group": "Pathfinding",
		"with": "Fights 0.8-1.2 m back from cover; only head and shoulders show to the enemy.",
		"without": "Hugs cover and steps fully out to shoot."},
	{"id": "PF06", "name": "Short rushes", "group": "Pathfinding",
		"with": "Crosses open yard ground at a sprint, in bounds of 3 s or less.",
		"without": "Walks across."},
	{"id": "PF07", "name": "Get off the X", "group": "Pathfinding",
		"with": "In a close fight, sidesteps 1 m or more toward cover while firing.",
		"without": "Stands still."},
	{"id": "PF08", "name": "Re-engage from a new spot", "group": "Pathfinding",
		"with": "Re-engages at least 1.5 m from the last exposure point.",
		"without": "Reappears where it was last seen."},
	{"id": "PF09", "name": "Pre-planned fallback", "group": "Pathfinding",
		"with": "Caches the best cover at 2 Hz; moves within 0.1 s when a weapon runs dry.",
		"without": "Searches when needed (+0.4 s) and takes the nearest cover by straight line."},
	{"id": "PF10", "name": "Clear before passing", "group": "Pathfinding",
		"with": "Checks the bathroom before passing it.",
		"without": "Walks past uncleared rooms."},
	{"id": "GD01", "name": "Stack discipline", "group": "Group discipline",
		"with": "Stacks on the wall beside the door, out of the doorway's line of sight.",
		"without": "Gathers loosely in front of the door."},
	{"id": "GD02", "name": "Sector ownership", "group": "Group discipline",
		"with": "Eyes stay in an assigned half of the room; team arcs barely overlap.",
		"without": "Both watch the same salient point."},
	{"id": "GD03", "name": "Respect lines of fire", "group": "Group discipline",
		"with": "Never walks through a teammate's muzzle line within 6 m.",
		"without": "Walks through friends' fields of fire."},
	{"id": "GD04", "name": "Contact callouts", "group": "Group discipline",
		"with": "Calls bearing and range within 0.2 s; listeners turn within 0.3 s and recognize 40% faster.",
		"without": "Silent."},
	{"id": "GD05", "name": "Bounding overwatch", "group": "Group discipline",
		"with": "In the open, one moves while the other covers; they alternate.",
		"without": "Both move at once."},
	{"id": "GD06", "name": "Opposite-direction entry", "group": "Group discipline",
		"with": "#2 takes the corner opposite #1 on entry.",
		"without": "Follows #1 to the same side."},
	{"id": "GD07", "name": "Spacing", "group": "Group discipline",
		"with": "Keeps 1.5 m from the nearest teammate; never two in one doorway.",
		"without": "Follows at 0.8 m and bunches in doorways."},
	{"id": "GD08", "name": "Cover the reloader", "group": "Group discipline",
		"with": "Announces reloads and stoppages; teammate takes the sector within 0.5 s.",
		"without": "The sector goes dark."},
	{"id": "GD09", "name": "Reassign on casualty", "group": "Group discipline",
		"with": "Takes over a downed teammate's sector within 1.0 s.",
		"without": "The casualty's sector stays empty."},
	{"id": "GD10", "name": "Mutual support distance", "group": "Group discipline",
		"with": "Stays within 8 m and in sight of the nearest teammate.",
		"without": "Drifts off alone."},
	{"id": "ED01", "name": "Eyes, muzzle, target", "group": "Eye discipline",
		"with": "Muzzle within 10 deg of the eye line; no ready-up delay.",
		"without": "Muzzle follows the body; +0.25 s to bring the weapon up."},
	{"id": "ED02", "name": "Scan danger points", "group": "Eye discipline",
		"with": "Looks at doors, windows, corners and last-known positions.",
		"without": "Looks along the direction of travel."},
	{"id": "ED03", "name": "Hard corner first", "group": "Eye discipline",
		"with": "Eyes on the nearest blind corner within 0.3 s of entering.",
		"without": "Looks into the middle of the room."},
	{"id": "ED04", "name": "Threat discrimination", "group": "Eye discipline",
		"with": "Beyond 10 m, engages whoever is pointing a weapon at the team first.",
		"without": "Engages whoever it recognized first."},
	{"id": "ED05", "name": "Shoot, then assess", "group": "Eye discipline",
		"with": "Confirms a kill in 0.15 s, then looks away to scan.",
		"without": "0.6 s to confirm (extra rounds), then stares at the body 1-2 s."},
	{"id": "ED06", "name": "Resist tunnel vision", "group": "Eye discipline",
		"with": "Stress narrows the vision cone half as much (never below 48 deg).",
		"without": "Narrows to 36 deg at full stress."},
	{"id": "ED07", "name": "Sound cueing", "group": "Eye discipline",
		"with": "Turns eyes to any sound it hears (shots, footsteps, reloads) within 0.3 s when not engaged.",
		"without": "Turns only to gunfire, after 1.0 s, and ignores it while engaged."},
	{"id": "ED08", "name": "Hold the last-known position", "group": "Eye discipline",
		"with": "Eyes and muzzle stay where contact broke for 3 s.",
		"without": "Drops the angle at once."},
	{"id": "ED09", "name": "Rear security", "group": "Eye discipline",
		"with": "Rear man looks back 1 s in every 4 s on the move.",
		"without": "Nobody looks back."},
	{"id": "ED10", "name": "Look before entering", "group": "Eye discipline",
		"with": "Views through the doorway for 0.5 s or more before entering.",
		"without": "Enters blind."},
	{"id": "WD01", "name": "Ammo count awareness", "group": "Weapon discipline",
		"with": "Always knows rounds remaining.",
		"without": "Finds out on the empty click: +0.4 s before switching weapons."},
	{"id": "WD02", "name": "Proactive reload", "group": "Weapon discipline",
		"with": "Reloads below 40% in any 2 s lull; resets to primary after contact.",
		"without": "Reloads only when dry."},
	{"id": "WD03", "name": "Reload from cover", "group": "Weapon discipline",
		"with": "Breaks sight to known enemies before every reload.",
		"without": "Only Rule 2 reloads use cover."},
	{"id": "WD04", "name": "Function check", "group": "Weapon discipline",
		"with": "Checks the weapon before entries; stoppage rate x0.5.",
		"without": "Base stoppage rate."},
	{"id": "WD05", "name": "Immediate action", "group": "Weapon discipline",
		"with": "Clears a stoppage in 1.2 s, 95% first time.",
		"without": "2.5-4 s, 80% first time."},
	{"id": "WD06", "name": "Close-range transition", "group": "Weapon discipline",
		"with": "A stoppage inside 10 m means drawing the pistol, not clearing the rifle.",
		"without": "Clears the rifle in place."},
	{"id": "WD07", "name": "Controlled pairs", "group": "Weapon discipline",
		"with": "Pairs at least 0.25 s apart; settles until spread fits the target; assesses after each pair.",
		"without": "Snap shots at a fast cadence; recoil stacks."},
	{"id": "WD08", "name": "Failure drill vs armour", "group": "Weapon discipline",
		"with": "After a plate hit, re-aims at the head if precise enough, otherwise the pelvis.",
		"without": "Keeps shooting the plate."},
	{"id": "WD09", "name": "Trigger discipline", "group": "Weapon discipline",
		"with": "No unintended shots.",
		"without": "Under stress, 2% chance per stress spike of a stray shot."},
	{"id": "WD10", "name": "Friendly-line check", "group": "Weapon discipline",
		"with": "Won't fire with a friend within 0.5 m of the line; waits up to 0.3 s.",
		"without": "Fires anyway."},
]

## kind "stress": active when stress x (1 - resist) >= t - 0.3 x anxiety/100 (off 0.1 below).
## kind "trait": always active when present (trait >= 60).
const BAD := [
	{"id": "BH01", "name": "Freeze", "kind": "stress", "t": 0.85, "trait": "", "over": ["PF07", "PF09", "GD04"],
		"desc": "On recognizing a new enemy: no movement, +0.4-1.0 s added to time on target, no callout."},
	{"id": "BH02", "name": "Spray and pray", "kind": "stress", "t": 0.60, "trait": "", "over": ["WD01", "WD07"],
		"desc": "Fires at top cadence with no settle; loses count of rounds."},
	{"id": "BH03", "name": "Overkill", "kind": "stress", "t": 0.60, "trait": "", "over": ["ED05", "WD07"],
		"desc": "Keeps firing into a downed target for 1.0 s or until the magazine is empty."},
	{"id": "BH04", "name": "Tunnel-vision lock", "kind": "stress", "t": 0.70, "trait": "", "over": ["ED02", "ED06", "ED09", "GD02"],
		"desc": "Cone fixed at 25 deg; eyes locked on the current target or last-known position."},
	{"id": "BH05", "name": "Panic reload", "kind": "stress", "t": 0.70, "trait": "", "over": ["WD03", "GD08"],
		"desc": "Reloads in place, unannounced, whenever firing stops for 0.5 s."},
	{"id": "BH06", "name": "Doorway stall", "kind": "stress", "t": 0.50, "trait": "", "over": ["PF01", "PF04"],
		"desc": "Halts in the threshold for 1.0 s on every entry."},
	{"id": "BH07", "name": "Flinch and turtle", "kind": "stress", "t": 0.50, "trait": "", "over": ["PF05", "PF07", "ED08"],
		"desc": "On a near miss: drops flat behind cover for 0.8 s and looks away."},
	{"id": "BH08", "name": "Comms blackout", "kind": "stress", "t": 0.75, "trait": "", "over": ["GD04", "GD08", "GD09"],
		"desc": "Sends no callouts or status; ignores sector reassignment."},
	{"id": "BH09", "name": "Jumpy trigger", "kind": "stress", "t": 0.60, "trait": "", "over": ["WD09", "WD10"],
		"desc": "Fires at movement within 10 m once recognition is half done, friend or foe."},
	{"id": "BH10", "name": "Bee-line to cover", "kind": "stress", "t": 0.65, "trait": "", "over": ["PF02", "PF06", "PF09"],
		"desc": "Runs the straight line to the nearest cover, ignoring exposure."},
	{"id": "BH11", "name": "Rush the room", "kind": "trait", "t": 0.0, "trait": "Aggression", "over": ["PF03", "GD01", "GD05", "ED10"],
		"desc": "Enters before the stack is set; sprints through uncleared rooms; no slicing or looking first."},
	{"id": "BH12", "name": "Chase the contact", "kind": "trait", "t": 0.0, "trait": "Aggression", "over": ["ED08", "GD10", "PF10"],
		"desc": "Runs to an enemy's last-known position within 1.0 s of losing sight."},
	{"id": "BH13", "name": "Hide and wait", "kind": "trait", "t": 0.0, "trait": "Anxiety", "over": ["PF08", "GD05", "GD08"],
		"desc": "Stays in cover 3 s after any contact and re-engages from the same spot."},
	{"id": "BH14", "name": "Cling to teammates", "kind": "trait", "t": 0.0, "trait": "Anxiety", "over": ["GD06", "GD07"],
		"desc": "Stays within 1.0 m of a teammate; follows them through doors."},
	{"id": "BH15", "name": "Lone wolf", "kind": "trait", "t": 0.0, "trait": "Ego", "over": ["GD02", "GD09", "GD10"],
		"desc": "Ignores sector and tether; pushes up to 15 m toward contacts."},
	{"id": "BH16", "name": "Glory shot", "kind": "trait", "t": 0.0, "trait": "Ego", "over": ["ED04", "GD03", "WD10"],
		"desc": "Beyond 10 m, shoots the most exposed enemy and fires past friends to do it."},
	{"id": "BH17", "name": "Skip the checks", "kind": "trait", "t": 0.0, "trait": "Complacency", "over": ["WD01", "WD02", "WD04"],
		"desc": "No function checks, no round count, reloads only when dry."},
	{"id": "BH18", "name": "Relaxed carry", "kind": "trait", "t": 0.0, "trait": "Complacency", "over": ["ED01", "ED02", "ED09"],
		"desc": "Out of contact: muzzle low, eyes along travel, no rear checks."},
	{"id": "BH19", "name": "Range scar", "kind": "trait", "t": 0.0, "trait": "Rigidity", "over": ["WD05", "WD06", "WD08"],
		"desc": "Always two rounds centre mass then a 0.6 s pause; full 3 s range drill on stoppages."},
	{"id": "BH20", "name": "Fixed scan pattern", "kind": "trait", "t": 0.0, "trait": "Rigidity", "over": ["ED03", "ED07"],
		"desc": "Sweeps left to right on every entry, ignoring corners and sounds until done."},
]

const ECHELON_ORDER := ["untrained", "militia", "regular", "police", "sof"]
const ECHELONS := {
	"untrained": {"name": "Untrained", "t_rec0": 0.50, "a": 0.30, "b": 0.20, "turn": 360.0,
		"s_snap": 45.0, "s_min": 12.0, "tau": 0.60, "flinch": 8.0, "tr": 0.45, "move_s": 2.2,
		"resist": 0.00, "reload": 1.6, "transition": 1.4},
	"militia": {"name": "Militia / irregular", "t_rec0": 0.42, "a": 0.25, "b": 0.17, "turn": 360.0,
		"s_snap": 35.0, "s_min": 9.0, "tau": 0.50, "flinch": 5.0, "tr": 0.35, "move_s": 1.9,
		"resist": 0.25, "reload": 1.3, "transition": 1.0},
	"regular": {"name": "Regular infantry", "t_rec0": 0.36, "a": 0.20, "b": 0.14, "turn": 540.0,
		"s_snap": 25.0, "s_min": 6.0, "tau": 0.40, "flinch": 3.0, "tr": 0.28, "move_s": 1.6,
		"resist": 0.50, "reload": 1.1, "transition": 0.8},
	"police": {"name": "Police tactical", "t_rec0": 0.32, "a": 0.17, "b": 0.12, "turn": 540.0,
		"s_snap": 20.0, "s_min": 4.5, "tau": 0.32, "flinch": 1.5, "tr": 0.22, "move_s": 1.4,
		"resist": 0.65, "reload": 1.0, "transition": 0.7},
	"sof": {"name": "Special operations", "t_rec0": 0.28, "a": 0.14, "b": 0.10, "turn": 540.0,
		"s_snap": 15.0, "s_min": 3.0, "tau": 0.25, "flinch": 0.5, "tr": 0.18, "move_s": 1.25,
		"resist": 0.80, "reload": 0.9, "transition": 0.6},
}

## Default good habits per echelon preset. Every preset carries all ten stress habits
## (anyone can be stressed); trait habits default to absent.
const PRESET_GOOD := {
	"untrained": ["PF06", "GD04"],
	"militia": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01"],
	"regular": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01",
		"PF01", "PF02", "GD01", "GD02", "GD05", "GD06", "ED01", "ED02", "WD07"],
	"police": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01",
		"PF01", "PF02", "GD01", "GD02", "GD05", "GD06", "ED01", "ED02", "WD07",
		"PF03", "PF04", "ED03", "ED05", "GD03", "WD10", "WD02", "ED10"],
	"sof": ["ALL_BUT", "PF08", "ED09"],
}
const PRESET_PLATES := {"untrained": 0, "militia": 0, "regular": 2, "police": 2, "sof": 3}

## Experience (a trait, tiers 1-5): how many enemies an operator tracks at once. Only
## tracked enemies are recognized, and every tracked enemy is recognized and set up for
## aiming in parallel, so switching to one already acquired is nearly instant. Tier 1
## takes one enemy at a time, from scratch.
const EXP_MAX := 5
const PRESET_EXP := {"untrained": 1, "militia": 1, "regular": 2, "police": 3, "sof": 4}
const EXP_NAMES := ["", "Green", "Blooded", "Seasoned", "Veteran", "Exceptional"]
const SWITCH_PER_PLATE := 0.004   # extra seconds to swing onto an acquired target, per plate

## One main weapon and one sidearm for everyone (section 3.1). Stoppage rates are
## raised above the bible's values so stoppage drills are visible in a short test.
const WEAPONS := {
	"rifle": {"name": "Carbine, red dot", "a_w": 0.06, "b_w": 0.80, "s_w": 1.0, "kappa": 4.0,
		"mag": 30, "spare": 3, "reload": 2.6, "stop": 0.004, "cadence": 0.10, "snap": 0.18, "switch": 0.08},
	"pistol": {"name": "Service pistol", "a_w": 0.00, "b_w": 1.00, "s_w": 2.5, "kappa": 9.0,
		"mag": 15, "spare": 2, "reload": 2.0, "stop": 0.003, "cadence": 0.15, "snap": 0.22, "switch": 0.06},
}


## Individual variation within an echelon: every operator is rolled once per match.
## A form factor (about +-6 %) moves every time-based stat together, each stat gets a
## little jitter, and one or two named strengths and weaknesses push single stats further.
## mul: stat multipliers; add: stat offsets (resist).
const QUIRKS_PLUS := [
	{"name": "Quick eyes", "grp": "eyes", "mul": {"t_rec0": 0.8}},
	{"name": "Fast hands", "grp": "hands", "mul": {"reload": 0.8, "transition": 0.8}},
	{"name": "Steady aim", "grp": "aim", "mul": {"s_snap": 0.8, "s_min": 0.8}},
	{"name": "Snap shooter", "grp": "target", "mul": {"a": 0.8, "b": 0.85}},
	{"name": "Cool head", "grp": "nerve", "add": {"resist": 0.15}},
	{"name": "Recoil master", "grp": "recoil", "mul": {"tr": 0.8, "flinch": 0.6}},
	{"name": "Quick to settle", "grp": "settle", "mul": {"tau": 0.8}},
]
const QUIRKS_MINUS := [
	{"name": "Slow eyes", "grp": "eyes", "mul": {"t_rec0": 1.2}},
	{"name": "Fumbles reloads", "grp": "hands", "mul": {"reload": 1.25, "transition": 1.25}},
	{"name": "Shaky aim", "grp": "aim", "mul": {"s_snap": 1.2, "s_min": 1.2}},
	{"name": "Slow on target", "grp": "target", "mul": {"a": 1.2, "b": 1.15}},
	{"name": "Jittery", "grp": "nerve", "add": {"resist": -0.15}},
	{"name": "Flincher", "grp": "recoil", "mul": {"tr": 1.2, "flinch": 1.6}},
	{"name": "Slow to settle", "grp": "settle", "mul": {"tau": 1.2}},
]
const FORM_STATS := ["t_rec0", "a", "b", "reload", "transition", "s_snap", "s_min", "tau"]


## A per-operator copy of an echelon's stats with form, jitter and quirks applied.
static func vary(base: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var e := base.duplicate()
	var form := clampf(1.0 + rng.randfn(0.0, 0.03), 0.94, 1.06)
	for k in FORM_STATS:
		e[k] = float(e[k]) * form * clampf(1.0 + rng.randfn(0.0, 0.035), 0.9, 1.1)
	e["resist"] = clampf(float(e["resist"]) + (1.0 - form) * 0.5 + rng.randfn(0.0, 0.02), 0.0, 0.95)
	e["turn"] = float(e["turn"]) / form
	var plus: Array = []
	var minus: Array = []
	var used := {}
	for k in (1 if rng.randf() < 0.6 else 2):
		var q: Dictionary = QUIRKS_PLUS[rng.randi() % QUIRKS_PLUS.size()]
		if used.has(q["grp"]):
			continue
		used[q["grp"]] = true
		plus.append(q)
	for k in (1 if rng.randf() < 0.6 else 2):
		var q2: Dictionary = QUIRKS_MINUS[rng.randi() % QUIRKS_MINUS.size()]
		if used.has(q2["grp"]):
			continue
		used[q2["grp"]] = true
		minus.append(q2)
	var names_p: Array = []
	var names_m: Array = []
	for q3 in plus + minus:
		var sc := rng.randf_range(0.75, 1.25)
		for st in q3.get("mul", {}):
			e[st] = float(e[st]) * (1.0 + (float(q3["mul"][st]) - 1.0) * sc)
		for st2 in q3.get("add", {}):
			e[st2] = clampf(float(e[st2]) + float(q3["add"][st2]) * sc, 0.0, 0.95)
		if plus.has(q3):
			names_p.append(q3["name"])
		else:
			names_m.append(q3["name"])
	e["form"] = form
	e["plus"] = names_p
	e["minus"] = names_m
	return e


# ================================================================== effect registry
## Every habit declares the hook points it touches. The registry is the single place
## that answers "what does this habit actually do?" -- it drives the coverage report
## (tests/habits_test.gd), the UI's hover text and the generic ablation sweep
## (tests/sim_test.gd --ablation=all), and it is where a new habit is registered.
## A habit with no hooks is a pure suspension habit (it only disables good habits).
const HOOKS := [
	{"id": "perception", "name": "Perception", "desc": "How fast a figure in view is recognized, and how wide the vision cone stays."},
	{"id": "attention", "name": "Attention", "desc": "What is held in short-term memory and how long it stays there."},
	{"id": "sound_reaction", "name": "Reaction to sound", "desc": "What an operator does with a noise it hears."},
	{"id": "target_selection", "name": "Target selection", "desc": "Which recognized enemy is engaged first."},
	{"id": "acquisition", "name": "Time on target", "desc": "How fast the muzzle comes onto the chosen target."},
	{"id": "fire_cadence", "name": "Cadence and stoppages", "desc": "Shot spacing, settling, weapon transitions and drills."},
	{"id": "movement_mode", "name": "Movement", "desc": "Pace, routing, spacing and bounding."},
	{"id": "entry_geometry", "name": "Entry geometry", "desc": "Stacking, slicing, points of domination, doors."},
	{"id": "reload_policy", "name": "Reload policy", "desc": "When and where a magazine is changed."},
	{"id": "cover_choice", "name": "Cover", "desc": "Which cover is picked, and when it is left."},
	{"id": "eyes", "name": "Eyes", "desc": "Where the eyes go when nothing is happening."},
	{"id": "team_task", "name": "Team task", "desc": "How the element picks and executes its job."},
	{"id": "comms", "name": "Comms", "desc": "Callouts, status and covering announcements."},
]

## habit id -> the hook points it changes. Kept in step with the call sites in
## scripts/sim/*.gd; tests/habits_test.gd fails when the two drift apart.
const EFFECTS := {
	"PF01": ["movement_mode", "entry_geometry"],
	"PF02": ["movement_mode", "cover_choice"],
	"PF03": ["entry_geometry", "eyes"],
	"PF04": ["entry_geometry"],
	"PF05": ["cover_choice", "movement_mode"],
	"PF06": ["movement_mode"],
	"PF07": ["movement_mode"],
	"PF08": ["cover_choice"],
	"PF09": ["cover_choice"],
	"PF10": ["team_task"],
	"GD01": ["entry_geometry"],
	"GD02": ["eyes"],
	"GD03": ["movement_mode"],
	"GD04": ["comms", "perception", "attention"],
	"GD05": ["team_task", "movement_mode"],
	"GD06": ["entry_geometry"],
	"GD07": ["movement_mode"],
	"GD08": ["comms", "team_task"],
	"GD09": ["eyes", "team_task"],
	"GD10": ["movement_mode"],
	"ED01": ["acquisition"],
	"ED02": ["eyes", "attention"],
	"ED03": ["eyes", "entry_geometry"],
	"ED04": ["target_selection"],
	"ED05": ["fire_cadence", "eyes"],
	"ED06": ["perception", "attention"],
	"ED07": ["sound_reaction", "attention", "eyes"],
	"ED08": ["eyes", "attention"],
	"ED09": ["eyes", "movement_mode"],
	"ED10": ["entry_geometry", "eyes"],
	"WD01": ["reload_policy"],
	"WD02": ["reload_policy"],
	"WD03": ["reload_policy", "cover_choice"],
	"WD04": ["fire_cadence", "entry_geometry"],
	"WD05": ["fire_cadence"],
	"WD06": ["fire_cadence", "target_selection"],
	"WD07": ["fire_cadence"],
	"WD08": ["target_selection"],
	"WD09": ["fire_cadence"],
	"WD10": ["fire_cadence", "target_selection"],
	"BH01": ["perception", "movement_mode", "comms"],
	"BH02": ["fire_cadence", "reload_policy"],
	"BH03": ["fire_cadence", "eyes"],
	"BH04": ["perception", "eyes", "attention"],
	"BH05": ["reload_policy"],
	"BH06": ["entry_geometry"],
	"BH07": ["movement_mode", "cover_choice", "eyes"],
	"BH08": ["comms", "eyes"],
	"BH09": ["fire_cadence", "target_selection"],
	"BH10": ["cover_choice", "movement_mode"],
	"BH11": ["entry_geometry", "movement_mode", "eyes"],
	"BH12": ["movement_mode", "target_selection", "eyes"],
	"BH13": ["cover_choice", "movement_mode", "comms"],
	"BH14": ["movement_mode", "entry_geometry"],
	"BH15": ["movement_mode", "eyes", "team_task"],
	"BH16": ["target_selection", "fire_cadence"],
	"BH17": ["fire_cadence", "reload_policy"],
	"BH18": ["acquisition", "eyes"],
	"BH19": ["fire_cadence", "target_selection"],
	"BH20": ["eyes", "sound_reaction", "entry_geometry"],
	"TR01": ["sound_reaction", "attention"],
	"TR02": ["sound_reaction", "attention"],
}

## Hooks that no habit touches: useful for spotting dead code paths.
static func hooks_unused() -> Array:
	var used := {}
	for k in EFFECTS:
		for h in EFFECTS[k]:
			used[h] = true
	var out: Array = []
	for h in HOOKS:
		if not used.has(h["id"]):
			out.append(h["id"])
	return out


static func hook_ids() -> Array:
	var out: Array = []
	for h in HOOKS:
		out.append(h["id"])
	return out


static func hooks_of(hid: String) -> Array:
	return EFFECTS.get(hid, []).duplicate()


static func hook_name(hid: String) -> String:
	for h in HOOKS:
		if h["id"] == hid:
			return h["name"]
	return hid


## Habits that claim a hook point, in declaration order.
static func by_hook(hook: String) -> Array:
	var out: Array = []
	for g in GOOD:
		if (EFFECTS.get(g["id"], []) as Array).has(hook):
			out.append(g["id"])
	for b in BAD:
		if (EFFECTS.get(b["id"], []) as Array).has(hook):
			out.append(b["id"])
	return out


# ================================================================== tuning
## Short-term memory / the cone of attention (the "general alertness" mechanic).
## Where the cone of vision and the cone of attention overlap, acquisition is
## faster: ATT_BOOST_MAX off the time on target when the two centre lines are
## identical, falling linearly to ATT_BOOST_MIN (7.5%) at the point where the
## two cones have shrunk to touching at one edge, and nothing at all beyond that.
## A boost of 35% removes 35% of the time. Recognition gets the same boost at
## ATT_REC_SHARE of the strength, because spotting a figure and swinging onto it
## are two halves of the same "I was already looking for it" effect.
const ATT_BOOST_MAX := 0.35
const ATT_BOOST_MIN := 0.075
const ATT_REC_SHARE := 0.5
## Half-angle (degrees) and lifetime (seconds) of an attention entry, by how the
## threat was learned about. Heard and fired-upon entries are wide and vague;
## a figure that was seen and lost is narrow and sharp.
const ATT_HALF_DEG := {"seen": 25.0, "called": 30.0, "heard": 35.0, "fire": 40.0}
const ATT_TTL := {"seen": 20.0, "called": 25.0, "heard": 18.0, "fire": 12.0}
const ATT_STRENGTH := {"seen": 1.0, "called": 0.8, "heard": 0.7, "fire": 0.9}
## Attention also decays with how alert the operator is: GREEN forgets quickly.
const ATT_ALERT_MUL := [0.6, 1.0, 1.2]

## Suppression: incoming fire you cannot answer degrades everything at once.
const SUPP_GAIN := 0.35        # per near miss, scaled by how close the round passed
const SUPP_IMPACT := 0.20      # per round striking cover within SUPP_IMPACT_R of you
const SUPP_IMPACT_R := 2.0
const SUPP_LATERAL := 1.0      # metres; a round passing within this is "close"
const SUPP_DECAY := 0.55       # per second
const SUPP_SIGMA := 0.60       # dispersion multiplier at full suppression
const SUPP_REC := 0.35         # recognition-time multiplier at full suppression
const SUPP_SPEED := 0.15       # fraction of movement speed lost at full suppression
const SUPP_STRAY := 0.030      # stray-shot chance per second past SUPP_STRAY_T
const SUPP_STRAY_T := 0.55
const SUPP_MIN_STRESS_BOOST := 0.05

## Wounds bleed. Bleed is per second as a fraction of the operator's blood
## volume; at 1.0 they go down. A wounded operator also gathers stress.
const BLEED_RATE := {"head": 0.0, "chest": 0.030, "abd": 0.022, "arm": 0.010, "legs": 0.014}
const BLEED_DOWN_STRESS := 0.020   # stress per second per wound level
const WOUND_SIGMA := 0.25          # dispersion penalty per wound level
const BLEEDOUT_WOUND_MUL := 0.5    # how much accumulated blood shortens the 5 min clock

## Doors as state. An open door is what every map had before: an arch.
const DOOR_STATE_OPEN := "open"
const DOOR_STATE_CLOSED := "closed"
const DOOR_STATE_LOCKED := "locked"
const DOOR_OPEN_TIME := 1.20       # push an unlocked door and step through
const DOOR_BREACH_TIME := 2.60     # kick or force a locked one
const DOOR_BREACH_P := 0.85        # first-attempt success, plus 0.15 x echelon composure

## Which sound a movement pace makes ("" means silent). Slicing the pie,
## creeping and a lateral sidestep make no noise; everything else does.
const MODE_SOUND := {"walk": "walk", "entry": "entry", "clear": "clear", "slice": "",
	"creep": "", "run": "run", "sprint": "sprint", "step": ""}


static func mode_loud(mode: String) -> String:
	return MODE_SOUND.get(mode, "")


## Physical traits (not habits, not overridden by stress). Hearing is a static attribute:
## every operator hears the same unless one of these changes it.
const TRAITS := [
	{"id": "TR01", "name": "Tinnitus", "kind": "negative", "hear": 0.5,
		"desc": "Ringing ears: hears every sound at half the normal range."},
	{"id": "TR02", "name": "Elephant Ears", "kind": "positive", "hear": 1.5,
		"desc": "Sharp hearing: hears every sound at 1.5 times the normal range."},
]

## Sound is a gameplay mechanic (nothing is played yet). Each kind of sound has a fixed
## loudness: the range in metres at which normal hearing picks it up in the open.
## Walls between source and listener halve it. Footsteps depend on the pace; creeping,
## slicing the pie and side-stepping are silent.
const SOUND := {"rifle": 45.0, "pistol": 35.0, "sprint": 8.0, "run": 5.0, "walk": 3.0, "entry": 3.5,
	"clear": 2.0, "reload": 4.0, "door": 6.0, "breach": 30.0}


static func trait_ids() -> Array:
	var out: Array = []
	for tr in TRAITS:
		out.append(tr["id"])
	return out


static func trait_info(id: String) -> Dictionary:
	for tr in TRAITS:
		if tr["id"] == id:
			return tr
	return {}


## Hearing multiplier from traits (1.0 = normal).
static func hearing(traits: Dictionary) -> float:
	var h := 1.0
	for tr in TRAITS:
		if traits.get(tr["id"], false):
			h *= tr["hear"]
	return h


static func good_ids() -> Array:
	var out: Array = []
	for g in GOOD:
		out.append(g["id"])
	return out


static func bad_ids() -> Array:
	var out: Array = []
	for b in BAD:
		out.append(b["id"])
	return out


static func good_info(id: String) -> Dictionary:
	for g in GOOD:
		if g["id"] == id:
			return g
	return {}


static func bad_info(id: String) -> Dictionary:
	for b in BAD:
		if b["id"] == id:
			return b
	return {}


static func preset_good(echelon: String) -> Array:
	var list: Array = PRESET_GOOD[echelon]
	if list.size() > 0 and list[0] == "ALL_BUT":
		var out := good_ids()
		for i in range(1, list.size()):
			out.erase(list[i])
		return out
	return list.duplicate()


static func stress_bad_ids() -> Array:
	var out: Array = []
	for b in BAD:
		if b["kind"] == "stress":
			out.append(b["id"])
	return out
