extends RefCounted
## Squads (v0.8): how a side is broken into squads, and how well a squad holds together.
##
## Formation, for every side (police, suspects, gangs, the test range):
##   1. form as many three-person squads as possible (whoever is left over joins them);
##   2. at most five squads;
##   3. once five are formed, spread everyone else so the squads are as even as possible;
##   4. at most six to a squad, so at most 30 to a side.
##
## Cohesion (0-1) sets how fast the squad follows its leader in a fight (the Lion brain):
## the leader acts at once, the rest after a delay that shrinks with cohesion and with
## their own experience. Department squads take it from the shared operations of each
## pair of officers (Department.bond) and the leader's experience; everyone else from
## their echelon.

const MAX_SQUADS := 5
const MAX_SIZE := 6
const MAX_SIDE := MAX_SQUADS * MAX_SIZE

## Cohesion by echelon for sides without a shared history (the test range, suspects).
const ECHELON_COHESION := {"untrained": 0.15, "militia": 0.35, "patrol": 0.45, "regular": 0.65,
	"police": 0.75, "sof": 0.9}

## Department ranks, lowest first: the highest rank alive leads.
const RANKS := ["Officer", "Corporal", "Sergeant", "Lieutenant", "Captain"]

## Shared operations a pair needs for a full bond.
const BOND_FULL := 6.0


## Squad sizes for n people, largest first. Threes first; whoever is left over (one or
## two) joins the squads, one each; past five squads everyone is spread evenly.
## 4 -> [4], 5 -> [5], 7 -> [4, 3], 8 -> [4, 4], 10 -> [4, 3, 3], 11 -> [4, 4, 3],
## 16 -> [4, 3, 3, 3, 3], 30 -> [6, 6, 6, 6, 6]. (Pairs come from tight interiors, not
## from formation: see Brain._split.)
static func sizes(n: int) -> Array:
	n = clampi(n, 0, MAX_SIDE)
	if n == 0:
		return []
	if n <= 2:
		return [n]
	var threes: int = n / 3
	var rest: int = n % 3
	var out: Array = []
	if threes >= MAX_SQUADS:
		for i in MAX_SQUADS:
			out.append(n / MAX_SQUADS + (1 if i < n % MAX_SQUADS else 0))
		return out
	for i in threes:
		out.append(3)
	for r in rest:
		out[r % out.size()] += 1
	return out


## Cohesion of a squad from its pairs' bonds (0 to BOND_FULL shared operations each) and
## its leader's experience tier (1-5).
static func cohesion_from(bonds: Array, leader_exp: int) -> float:
	var b := 0.0
	for v in bonds:
		b += clampf(float(v) / BOND_FULL, 0.0, 1.0)
	b = b / maxf(1.0, bonds.size()) if not bonds.is_empty() else 0.0
	return clampf(0.25 + 0.5 * b + 0.06 * float(leader_exp - 1), 0.05, 1.0)


## Seconds a subordinate takes to act on the leader's order in a fight: about 0.3 s in a
## tight veteran squad, about 2.5 s in a green one that has never worked together.
static func lag(cohesion: float, exp_tier: int) -> float:
	return clampf((0.3 + 2.4 * (1.0 - cohesion)) * (1.25 - 0.1 * float(exp_tier)), 0.15, 3.0)
