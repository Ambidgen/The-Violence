extends RefCounted
## The department's money and schooling (v0.8.5): pay by rank, what things cost, and the
## training courses. Figures are weekly dollars. The city sets the allocation once, at
## the handover; everything the department does comes out of it.

## Weekly pay by rank, before seniority (1.5% a year of service, up to 20 years).
const PAY := {"Officer": 1150, "Corporal": 1300, "Sergeant": 1500, "Lieutenant": 1750, "Captain": 2050}
const SENIORITY := 0.015
## The allocation is the inherited payroll plus this much headroom.
const HEADROOM := 0.16
const RESERVE := 25000          # in the account at the handover

const OVERTIME := 160           # per officer per operation
const NIGHT_PREMIUM := 60       # on top, per officer, at night
const RECRUIT := 3500           # academy place for a rookie (two weeks before they report)
const RECRUIT_WEEKS := 2
const LATERAL := 6500           # signing an experienced officer from another force
const SEVERANCE_WEEKS := 2
const DEATH_BENEFIT := 3000     # line-of-duty death: the funeral (the pension board pays the family; v0.9.1)
const MEDICAL := 500            # wounded: what workers' compensation does not cover
const MEDICAL_SERIOUS := 1500   # seriously wounded
const SURPLUS := 0.5            # kit handed back is sold for half what it cost

## Department morale (0-100). It starts and drifts back towards MORALE0; below it every
## officer brings more stress into an operation, and below MORALE_QUIT people resign.
const MORALE0 := 60
const MORALE_DRIFT := 2
const MORALE_QUIT := 35

const COURSES := {
	"cqb": {"name": "Close-quarters refresher", "cost": 2400, "weeks": 1,
		"desc": "Teaches the next habit of a Regular's set the officer lacks (pathfinding, group, eye or weapon discipline)."},
	"firearms": {"name": "Firearms qualification", "cost": 1800, "weeks": 1,
		"desc": "Faster recognition, aim and reloads: about a year's worth of time on the job. At most four times."},
	"judgment": {"name": "De-escalation and judgment", "cost": 3000, "weeks": 1,
		"desc": "Judgment +6 (to 90 at most): fewer misjudged civilians, fewer shots at people giving up."},
	"stress": {"name": "Stress inoculation", "cost": 3200, "weeks": 1,
		"desc": "Trauma -4 and a little more resistance to stress under fire."},
	"coaching": {"name": "Behaviour coaching", "cost": 3800, "weeks": 1,
		"desc": "Works one personality bad habit out of the officer. Needs one to work on."},
	"tactical": {"name": "Tactical team certification", "cost": 8500, "weeks": 2,
		"desc": "Qualifies the officer for tactical kit (bangs, sting-balls, gas, the shield) and teaches two tactical habits. Needs two years on the job or Experience 2."},
	"uof": {"name": "Use-of-force review", "cost": 2500, "weeks": 1,
		"desc": "The discipline route: a week of review and retraining after a finding. Judgment +5."},
}
const COURSE_ORDER := ["cqb", "firearms", "judgment", "stress", "coaching", "tactical", "uof"]

## The habits a refresher teaches, in order: a Regular's set the academy leaves out, then
## the tactical ones.
const CQB_ORDER := ["PF02", "GD02", "GD05", "GD06", "WD07", "PF01", "GD01", "ED01", "ED02", "WD02", "ED10", "PF03"]
const TACTICAL_ORDER := ["PF03", "PF04", "ED03", "ED05", "GD03", "WD10", "WD02", "ED10"]


## Weekly pay for one officer record.
static func pay(r: Dictionary) -> int:
	var base: int = PAY.get(String(r.get("rank", "Officer")), PAY["Officer"])
	return int(round(base * (1.0 + SENIORITY * minf(20.0, float(r.get("years", 0.0))))))


## Can this officer take this course? Returns "" or the reason not.
static func blocked(r: Dictionary, cid: String) -> String:
	match cid:
		"coaching":
			if r.get("bad_traits", []).is_empty():
				return "no personality habit to work on"
		"tactical":
			if r.get("tactical", false):
				return "already certified"
			if float(r.get("years", 0.0)) >= 5.0 or int(r.get("exp", 1)) >= 3:
				return "already qualified by service"
			if float(r.get("years", 0.0)) < 2.0 and int(r.get("exp", 1)) < 2:
				return "needs two years or Experience 2"
		"firearms":
			if int(r.get("drill", 0)) >= 4:
				return "already qualified four times"
		"judgment":
			if int(r.get("judgment", 50)) >= 90:
				return "judgment already 90"
		"cqb":
			if next_cqb(r) == "":
				return "knows every habit the course teaches"
	return ""


static func next_cqb(r: Dictionary) -> String:
	for g in CQB_ORDER:
		if not r.get("good", []).has(g):
			return g
	return ""
