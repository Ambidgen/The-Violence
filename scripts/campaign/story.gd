extends RefCounted
## The campaign's story spine. The forty-week mode is a social procedural: one fixed
## backstory, five acts, a weekly case in the foreground, and a public record that grows
## from the player's own decisions. This is an original house voice, not a pastiche.
## Narrative reads campaign state; it never changes the simulation or the save format.

const WEEKS := 40
const PROLOGUE := (
	"Before this appointment, you were deputy chief. You signed the Bridge Street eviction order; "
	+ "the outgoing chief gave the briefing. "
	+ "Dana Okonjo-Vale remembers who signed and who briefed it. "
	+ "The campaign does not "
	+ "ask whether the order was legal. It asks what you do with the authority that came from it."
)

const ACTS := [
	{
		"number": 1,
		"first": 1,
		"last": 9,
		"title": "The Inheritance",
		"summary": "The office is new to you. The order in the Bridge Street file is not."
	},
	{
		"number": 2,
		"first": 10,
		"last": 19,
		"title": "The Pattern",
		"summary":
		"One incident can be called an exception. " + "Repeated choices begin to look like policy."
	},
	{
		"number": 3,
		"first": 20,
		"last": 29,
		"title": "The Record",
		"summary":
		(
			"The camera, the case file and the witness do not always tell the same story. "
			+ "Your decisions decide which account the city can use."
		)
	},
	{
		"number": 4,
		"first": 30,
		"last": 39,
		"title": "The Count",
		"summary":
		(
			"The election turns every decision into a number. The people living with those "
			+ "decisions do not fit in the margin."
		)
	},
	{
		"number": 5,
		"first": 40,
		"last": 40,
		"title": "Aftermath",
		"summary":
		(
			"The vote decides who holds the office. "
			+ "It does not decide what happened on any street."
		)
	},
]

const BEATS := {
	1:
	{
		"title": "A signature",
		"text":
		(
			"The last chief left his chair, not his account of Bridge Street. "
			+ "You signed the order; he gave the briefing."
		),
		"speaker": "Outgoing chief",
		"quote":
		(
			"I put it on your desk. You put your name on it. "
			+ "The minutes only have room for one of us."
		),
	},
	10:
	{
		"title": "The first contradiction",
		"text":
		(
			"The city has had ten weeks to watch you work. It still wants to know whether "
			+ "Bridge Street was a mistake—or only a bad week in the papers."
		),
		"speaker": "Dana Okonjo-Vale",
		"quote":
		(
			"Don't call Bridge Street an operation. "
			+ "It was an eviction. The order has your signature."
		),
	},
	20:
	{
		"title": "Halfway on paper",
		"text":
		(
			"Half the calendar is spent. Statements, camera records and accounts do not always agree. "
			+ "The gap is where the work begins."
		),
		"speaker": "Paul Varga",
		"quote": "Bring me the tape, the statement and the time stamp. Leave me the conclusion.",
	},
	30:
	{
		"title": "A public record",
		"text":
		(
			"The election has become a second investigation. Every candidate wants the same file; "
			+ "they differ on what should happen after it is read."
		),
		"speaker": "Marguerite Duff",
		"quote": "I need the exact number. The committee can argue about the rest.",
	},
	39:
	{
		"title": "Last week",
		"text": "A week remains. The public story is shorter now. It has not become more accurate.",
		"speaker": "Royce Kettering",
		"quote": "People vote on the result, Chief. Not the folder.",
	},
}


static func act_for_week(week: int) -> Dictionary:
	var w := clampi(week, 1, WEEKS)
	for act in ACTS:
		if w >= int(act["first"]) and w <= int(act["last"]):
			return act.duplicate(true)
	return ACTS[ACTS.size() - 1].duplicate(true)


## One page for the board and the campaign file. Milestones turn the campaign's
## backstory; ordinary weeks keep the act's question beside the live situation.
static func current(campaign) -> Dictionary:
	if campaign == null:
		return {}
	var week := clampi(int(campaign.week()), 1, WEEKS)
	var act := act_for_week(week)
	var beat: Dictionary = BEATS.get(week, {})
	var page := {
		"week": week,
		"act": int(act["number"]),
		"act_title": String(act["title"]),
		"act_first": int(act["first"]),
		"act_last": int(act["last"]),
		"title": String(beat.get("title", act["title"])),
		"text": String(beat.get("text", act["summary"])),
		"speaker": String(beat.get("speaker", "")),
		"quote": String(beat.get("quote", "")),
		"focus": _focus_line(campaign),
		"record": _record_line(campaign),
	}
	if campaign.over() and not campaign.politics.result.is_empty():
		var winner: String = String(campaign.politics.result.get("winner", ""))
		page["title"] = "The vote is in"
		page["text"] = (
			"The city has chosen its next mayor. Your term is over; the department, the cases "
			+ "and the people on the other side of the door remain."
		)
		page["speaker"] = _winner_name(winner)
		page["quote"] = _ending_line(winner)
	return page


static func _focus_line(campaign) -> String:
	if campaign.over():
		return ""
	var focus: Dictionary = {}
	var best_visibility := -1
	for sit in campaign.board:
		if String(sit.get("status", "open")) != "open":
			continue
		var visibility := int(sit.get("visibility", 0))
		if visibility > best_visibility:
			best_visibility = visibility
			focus = sit
	if focus.is_empty():
		return ""
	var ward := String(focus.get("ward", "the city"))
	var detail := ""
	match String(focus.get("type", "")):
		"warrant":
			detail = (
				"the warrant names %s; " % String(focus.get("named", "a suspect"))
				+ "it does not say who will answer the door"
			)
		"gang":
			detail = "the file names a crew and an address; " + "it does not say who lives there"
		"barricade":
			detail = "one person is named; " + "the rooms behind the door are not"
		"hostage":
			detail = "the deadline is reported; " + "the account of everyone inside is not complete"
		"event":
			detail = "Civic Plaza is in public view; " + "the threat estimate is still a guess"
		_:
			return ""
	return "%s: %s." % [ward, detail]


static func _record_line(campaign) -> String:
	var record: Dictionary = campaign.politics.record
	var killed := int(record.get("civ_killed", 0))
	var hit := int(record.get("civ_hit", 0))
	var officers := int(record.get("officers_killed", 0))
	if killed > 0:
		return (
			(
				"The department's record shows %d civilian%s killed "
				% [killed, "" if killed == 1 else "s"]
			)
			+ "by police. The number will travel."
		)
	if hit > 0:
		return (
			(
				"The department's record shows %d civilian%s hit by police. "
				% [hit, "" if hit == 1 else "s"]
			)
			+ "The record keeps the count, not the whole event."
		)
	if officers > 0:
		return (
			"The roster records %d officer%s killed. " % [officers, "" if officers == 1 else "s"]
			+ "Every line has a name."
		)
	for pending in campaign.politics.pending:
		match String(pending.get("kind", "")):
			"story":
				return (
					(
						"A finding about police force is due in week %d. "
						% int(pending.get("due", campaign.week()))
					)
					+ "The public account has not arrived."
				)
			"leak":
				return (
					"A cleared internal affairs case is due to return to public view. "
					+ "The file is not closed to everyone."
				)
			"neglect":
				return (
					"A call left unattended is due to reach the papers. "
					+ "The address is already in the file."
				)
	var open_cases: int = campaign.dept.open_cases().size()
	if open_cases > 0:
		return (
			(
				"%d internal affairs case%s remain open. "
				% [open_cases, "" if open_cases == 1 else "s"]
			)
			+ "The decision is still yours."
		)
	return "No civilian harm is on the current record. That is a fact so far, not a promise."


static func acts() -> Array:
	return ACTS.duplicate(true)


static func _winner_name(winner: String) -> String:
	match winner:
		"kettering":
			return "Royce Kettering"
		"okonjo":
			return "Dana Okonjo-Vale"
		"pell":
			return "Gordon Pell"
	return "The new mayor"


static func _ending_line(winner: String) -> String:
	match winner:
		"kettering":
			return "The department has the budget. Now show me what it bought."
		"okonjo":
			return "The file stays open. So does the oversight board."
		"pell":
			return "The books close on Friday. The review begins Monday."
	return "The vote is counted. The record is not."
