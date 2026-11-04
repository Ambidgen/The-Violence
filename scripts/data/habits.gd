extends RefCounted
## Static design data from "The Violence - NPC CQB Bible": the 40 good habits,
## the 20 bad habits with the good habits each overrides, echelon presets
## (section 2.1) and the two weapons used in this slice (section 3.1).

const GROUPS := ["Pathfinding", "Group discipline", "Eye discipline", "Weapon discipline", "Defence"]
## Hold-mode habits (v0.7, HD01-HD20): they work only while the operator's squad is in
## Hold (defending, or police on a Post or Contain order). They do not add the 0.5%
## reaction bonus: the 40 base habits keep that to themselves.
const HOLD_PREFIX := "HD"

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
		"with": "On first engaging an enemy, at any range, sidesteps 1 m or more toward cover while firing.",
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
		"with": "Never walks through a teammate's muzzle line within 6 m, and steps out of one it is standing in.",
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
		"with": "Always knows rounds remaining: tops up in a lull below 30%.",
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
	# ---- hold mode (v0.7): only while the squad holds a position
	{"id": "HD01", "name": "Alternate and supplementary posts", "group": "Defence", "hold": true,
		"with": "Keeps an alternate post covering the same opening; hops to it within 2 s when suppressed or flanked.",
		"without": "Stays on the one post it was given."},
	{"id": "HD02", "name": "Fight from depth", "group": "Defence", "hold": true,
		"with": "Posts 2.5-4 m back from the opening, off its centre line.",
		"without": "Posts close to the opening, near its axis: seen from outside."},
	{"id": "HD03", "name": "Interlocking angles", "group": "Defence", "hold": true,
		"with": "Picks a post that crosses a teammate's line onto the same opening by 35 deg or more.",
		"without": "Covers its opening alone, whatever the others do."},
	{"id": "HD04", "name": "Don't re-peek", "group": "Defence", "hold": true,
		"with": "After firing from a post and losing the target, moves 1.5 m or more before showing again.",
		"without": "Comes back to the same spot."},
	{"id": "HD05", "name": "Deep-window discipline", "group": "Defence", "hold": true,
		"with": "Covers a window kneeling, 2 m or more back from the sill.",
		"without": "Stands at the window."},
	{"id": "HD06", "name": "Internal routes", "group": "Defence", "hold": true,
		"with": "Moves between posts by the least exposed route (doors and windows cost more).",
		"without": "Takes the shortest route, across open doorways."},
	{"id": "HD07", "name": "Canalize the entry", "group": "Defence", "hold": true,
		"with": "Picks a post that sees the lane 1.5 m inside the door as well as the doorway (not in the presets: measured harmful).",
		"without": "Covers the doorway."},
	{"id": "HD08", "name": "Wait for the funnel", "group": "Weapon discipline", "hold": true,
		"with": "Beyond 10 m, holds fire until the enemy is at an opening of the room, attacking, or a teammate opens up.",
		"without": "Fires at the first face at range."},
	{"id": "HD09", "name": "Drop the point man", "group": "Weapon discipline", "hold": true,
		"with": "Shoots first whoever is in or at a doorway of the room.",
		"without": "Shoots the closest."},
	{"id": "HD10", "name": "Enfilade the threshold", "group": "Weapon discipline", "hold": true,
		"with": "Picks a post 30-55 deg off the door's axis, across the entry line.",
		"without": "Faces the door square on."},
	{"id": "HD11", "name": "Lift and shift", "group": "Weapon discipline", "hold": true,
		"with": "Holds fire while a teammate is in the lane; reopens 0.5 s after it clears.",
		"without": "Fires into the doorway anyway (unless WD10)."},
	{"id": "HD12", "name": "Counterattack the foothold", "group": "Defence", "hold": true,
		"with": "When an enemy gets inside the room, the nearest pair rushes the entry point for 4 s.",
		"without": "Waits for the attackers to set up inside."},
	{"id": "HD13", "name": "Redistribute to the pressure", "group": "Group discipline", "hold": true,
		"with": "When the squad turns to a noise, one member keeps watch on the quiet side.",
		"without": "Everyone turns to the loudest door."},
	{"id": "HD14", "name": "Peel back", "group": "Defence", "hold": true,
		"with": "Falls back in two halves, one moving while the other covers, 2 s legs.",
		"without": "Everyone runs at once."},
	{"id": "HD15", "name": "Give up the room", "group": "Defence", "hold": true,
		"with": "Falls back to the next room when flanked, low on ammunition or half the squad is down.",
		"without": "Holds the room to the last."},
	{"id": "HD16", "name": "Keep the fifth man", "group": "Group discipline", "hold": true,
		"with": "In squads of four or more, one member stays back in the room as a reserve: first to counterattack or drag.",
		"without": "Everyone is on an opening."},
	{"id": "HD17", "name": "Early warning", "group": "Eye discipline", "hold": true,
		"with": "Stands to: never relaxes below yellow, and the first sighting turns the whole squad's eyes.",
		"without": "Relaxes to green; the first warning is the breach."},
	{"id": "HD18", "name": "Call the breach", "group": "Group discipline", "hold": true,
		"with": "An enemy at a doorway of the room is called within 0.2 s: the squad turns and recognizes 40% faster.",
		"without": "Says nothing."},
	{"id": "HD19", "name": "Drag the wounded", "group": "Group discipline", "hold": true,
		"with": "Once the doorway is quiet for a second, pulls a downed teammate 2.5 m back out of the lane.",
		"without": "Leaves them where they fell."},
	{"id": "HD20", "name": "Ammo in the position", "group": "Weapon discipline", "hold": true,
		"with": "A cache at the post: between contacts, tops up a magazine (up to two) from it.",
		"without": "Has only what it carries."},
]

## Stress habits use a separate accumulator. Each stress input contributes
## amount * (1 - 0.75 * resistance), capped at 1.0; sustained pressure can therefore
## eventually reach any threshold even for highly resistant operators. The existing
## 0.1 hysteresis and anxiety adjustment remain. Other stress effects still use the raw
## stress and their original resistance formulas.
const HABIT_RESIST_SCALE := 0.75


static func habit_stress_gain(amount: float, resistance: float) -> float:
	return maxf(0.0, amount) * (1.0 - HABIT_RESIST_SCALE * clampf(resistance, 0.0, 1.0))


## kind "stress": active when habit stress >= t - 0.3 x anxiety/100 (off 0.1 below).
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
	# ---- hold mode (v0.7): active only while the squad holds a position
	{"id": "BH21", "name": "First sight, first shot", "kind": "stress", "t": 0.55, "trait": "", "hold": true,
		"over": ["HD08", "HD09", "HD10"], "desc": "Opens up on the first silhouette at range; the ambush dies with the first round."},
	{"id": "BH22", "name": "Window silhouette", "kind": "trait", "t": 0.0, "trait": "Rigidity", "hold": true,
		"over": ["HD05", "HD04"], "desc": "Stands tall at the window it covers; the post is located before it fires twice."},
	{"id": "BH23", "name": "Die at the post", "kind": "trait", "t": 0.0, "trait": "Ego", "hold": true,
		"over": ["HD01", "HD14", "HD15"], "desc": "Will not give up the post; stays when the squad falls back."},
	{"id": "BH24", "name": "Door stare", "kind": "stress", "t": 0.70, "trait": "", "hold": true,
		"over": ["HD13", "HD03", "GD02", "ED02"], "desc": "Eyes locked on the nearest door of the room; flank and rear go unwatched."},
	{"id": "BH25", "name": "Sally out for a noise", "kind": "trait", "t": 0.0, "trait": "Aggression", "hold": true,
		"over": ["HD17", "HD13", "GD10"], "desc": "Leaves the post alone to chase a sound."},
	{"id": "BH26", "name": "Fire through the counter", "kind": "stress", "t": 0.60, "trait": "", "hold": true,
		"over": ["HD11", "GD03", "WD10"], "desc": "Fires with a teammate in the lane."},
	{"id": "BH27", "name": "Unprepared position", "kind": "trait", "t": 0.0, "trait": "Complacency", "hold": true,
		"over": ["HD01", "HD07", "HD20", "HD05"], "desc": "Stands in the middle of the room: no alternate, no cache, no angle."},
]

const ECHELON_ORDER := ["untrained", "militia", "patrol", "regular", "police", "sof"]
const ECHELONS := {
	"untrained": {"name": "Untrained", "t_rec0": 0.50, "a": 0.30, "b": 0.20, "turn": 360.0,
		"s_snap": 45.0, "s_min": 12.0, "tau": 0.60, "flinch": 8.0, "tr": 0.45, "move_s": 2.2,
		"resist": 0.00, "reload": 1.6, "transition": 1.4},
	"militia": {"name": "Militia / irregular", "t_rec0": 0.42, "a": 0.25, "b": 0.17, "turn": 360.0,
		"s_snap": 35.0, "s_min": 9.0, "tau": 0.50, "flinch": 5.0, "tr": 0.35, "move_s": 1.9,
		"resist": 0.25, "reload": 1.3, "transition": 1.0},
	# Patrol (v0.6): a new police hire, the midpoint of Militia and Regular in every stat
	"patrol": {"name": "Patrol", "t_rec0": 0.39, "a": 0.225, "b": 0.155, "turn": 450.0,
		"s_snap": 30.0, "s_min": 7.5, "tau": 0.45, "flinch": 4.0, "tr": 0.315, "move_s": 1.75,
		"resist": 0.375, "reload": 1.2, "transition": 0.9},
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
	"patrol": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01",
		"PF01", "GD01", "ED01", "ED02"],
	"regular": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01",
		"PF01", "PF02", "GD01", "GD02", "GD05", "GD06", "ED01", "ED02", "WD07",
		"HD01", "HD02", "HD05", "HD08", "HD17"],
	"police": ["PF06", "GD04", "PF05", "WD03", "WD05", "GD07", "ED07", "WD01",
		"PF01", "PF02", "GD01", "GD02", "GD05", "GD06", "ED01", "ED02", "WD07",
		"PF03", "PF04", "ED03", "ED05", "GD03", "WD10", "WD02", "ED10",
		"HD01", "HD02", "HD03", "HD04", "HD05", "HD06", "HD08", "HD09", "HD10", "HD11",
		"HD13", "HD14", "HD15", "HD16", "HD17", "HD18", "HD19", "HD20"],
	# HD07 is left out of both presets: every version tried made a held room easier to take
	"sof": ["ALL_BUT", "PF08", "ED09", "HD07"],
}
const PRESET_PLATES := {"untrained": 0, "militia": 0, "patrol": 0, "regular": 2, "police": 2, "sof": 3}
## Soft armour (v0.6): a vest under the shirt that stops pistol rounds to the chest from
## any side, but not rifle rounds. Patrol officers wear one.
const PRESET_VEST := {"untrained": false, "militia": false, "patrol": true, "regular": false, "police": false, "sof": false}
## Judgment (v0.6, 0-100): how long it takes to decide whether a recognized person is a
## threat, and how often that decision is wrong. Shoot/no-shoot training raises it.
const PRESET_JUDGMENT := {"untrained": 35, "militia": 40, "patrol": 50, "regular": 50, "police": 65, "sof": 70}

## Experience (a trait, tiers 1-5): how many enemies an operator tracks at once. Only
## tracked enemies are recognized, and every tracked enemy is recognized and set up for
## aiming in parallel, so switching to one already acquired is nearly instant. Tier 1
## takes one enemy at a time, from scratch.
const EXP_MAX := 5
const PRESET_EXP := {"untrained": 1, "militia": 1, "patrol": 1, "regular": 2, "police": 3, "sof": 4}
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


## Individual variation within an echelon: every operator is rolled once per match
## (a department officer once, at hire: the roll is saved with their record).
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


## Stats part of the way from one echelon to another (v0.7: an officer's years on the
## job move them from Patrol towards Regular, and past it towards Police tactical).
static func blend(from_e: String, to_e: String, f: float) -> Dictionary:
	var a: Dictionary = ECHELONS[from_e]
	var b: Dictionary = ECHELONS[to_e]
	var e := a.duplicate()
	for k in a:
		if typeof(a[k]) == TYPE_FLOAT and b.has(k):
			e[k] = lerpf(float(a[k]), float(b[k]), clampf(f, 0.0, 1.0))
	return e


## Patrol stats after a number of years of service: a rookie is Patrol; ten years
## brings Regular; the best-trained veterans go on part of the way to Police tactical.
static func service_stats(years: float) -> Dictionary:
	var f := years / 10.0
	if f <= 1.0:
		return blend("patrol", "regular", f)
	var e := blend("regular", "police", minf(f - 1.0, 0.6))
	e["name"] = ECHELONS["patrol"]["name"]
	return e


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
	"clear": 2.0, "reload": 4.0,
	# v0.7.5: the weapon roster and the entry tools
	"smg": 38.0, "rifle_loud": 50.0, "rifle_heavy": 55.0, "shotgun": 48.0, "pistol_heavy": 38.0,
	"breach_shot": 48.0, "ram": 30.0, "kick": 22.0, "door": 5.0, "flashbang": 60.0, "taser": 4.0, "launcher": 25.0,
	# v0.8: less-lethal
	"stingball": 50.0, "gas": 12.0, "pepperball": 15.0}


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


static func is_hold(id: String) -> bool:
	return id.begins_with("HD") or id in ["BH21", "BH22", "BH23", "BH24", "BH25", "BH26", "BH27"]


## The 40 base good habits (the hold-mode ones excluded).
static func base_good_ids() -> Array:
	return good_ids().filter(func(g): return not g.begins_with("HD"))


static func stress_bad_ids() -> Array:
	var out: Array = []
	for b in BAD:
		if b["kind"] == "stress":
			out.append(b["id"])
	return out
