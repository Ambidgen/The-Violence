extends RefCounted
## Character conversations and documentary views assembled from the active campaign.
## This layer is read-only: it introduces neither a new save field nor a new game rule.

const Department = preload("res://scripts/campaign/department.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const Situations = preload("res://scripts/campaign/situations.gd")

const CONTACTS := [
	{
		"id": "outgoing",
		"name": "Outgoing chief",
		"role": "Former chief · handover",
		"intro": "He gave the Bridge Street briefing. You signed the order."
	},
	{
		"id": "dana",
		"name": "Dana Okonjo-Vale",
		"role": "Mayoral candidate · Carrick Together",
		"intro": "She wants the Bridge Street order read aloud, with your name on it."
	},
	{
		"id": "varga",
		"name": "Paul Varga",
		"role": "District Attorney",
		"intro": "He wants the recording, the statement and the time stamp kept separate."
	},
	{
		"id": "duff",
		"name": "Marguerite Duff",
		"role": "Budget committee chair",
		"intro": "She reads the account before she reads the room."
	},
	{
		"id": "rourke",
		"name": "Tommy Rourke",
		"role": "Police Benevolent Association president",
		"intro": "He speaks for the people who have to take the next call."
	},
	{
		"id": "alma",
		"name": "Rev. Alma Mbeki-Shaw",
		"role": "Carrick Community Coalition",
		"intro": "She knows which doors open to a uniform—and which ones do not."
	},
	{
		"id": "kettering",
		"name": "Royce Kettering",
		"role": "Mayoral candidate · Safe Streets",
		"intro": "He promises more money, more police and fewer questions."
	},
	{
		"id": "pell",
		"name": "Gordon Pell",
		"role": "Mayoral candidate · Independent",
		"intro": "He believes every problem can be made legible in a form."
	},
]

const QUESTIONS := {
	"outgoing":
	[
		{
			"id": "signature",
			"label": "Ask about the signature",
			"question": "Why did I sign the Bridge Street order?"
		},
		{
			"id": "briefing",
			"label": "Ask about the briefing",
			"question": "What did you tell the room?"
		},
		{
			"id": "handover",
			"label": "Ask what he left behind",
			"question": "What did you leave out of the handover?"
		},
	],
	"dana":
	[
		{
			"id": "bridge",
			"label": "Ask about Bridge Street",
			"question": "What do you want from me about Bridge Street?"
		},
		{
			"id": "record",
			"label": "Ask about the record",
			"question": "What should the city see in the file?"
		},
		{
			"id": "mandate",
			"label": "Ask about the election",
			"question": "What changes if you win?"
		},
	],
	"varga":
	[
		{
			"id": "evidence",
			"label": "Ask what counts as evidence",
			"question": "What makes a finding hold up?"
		},
		{
			"id": "clear",
			"label": "Ask about cleared cases",
			"question": "What happens when I clear a case?"
		},
		{
			"id": "charge",
			"label": "Ask about charges",
			"question": "When does an internal case become a criminal charge?"
		},
	],
	"duff":
	[
		{
			"id": "account",
			"label": "Ask about the account",
			"question": "What does the account say this week?"
		},
		{
			"id": "grant",
			"label": "Ask about a grant",
			"question": "Can the committee help before the next payroll?"
		},
		{
			"id": "contracts",
			"label": "Ask about contracts",
			"question": "Does Kettering's family business concern you?"
		},
	],
	"rourke":
	[
		{
			"id": "staff",
			"label": "Ask about the roster",
			"question": "How many people can answer the next call?"
		},
		{
			"id": "discipline",
			"label": "Ask about discipline",
			"question": "What does the union want from an internal review?"
		},
		{
			"id": "morale",
			"label": "Ask about morale",
			"question": "What does the morale number miss?"
		},
	],
	"alma":
	[
		{"id": "trust", "label": "Ask about trust", "question": "Which ward trusts us least?"},
		{
			"id": "tips",
			"label": "Ask about community tips",
			"question": "What does a tip mean to the person who gives it?"
		},
		{
			"id": "record",
			"label": "Ask about public harm",
			"question": "What should be in the public record?"
		},
	],
	"kettering":
	[
		{
			"id": "budget",
			"label": "Ask what he would fund",
			"question": "What do you mean when you promise more money?"
		},
		{
			"id": "family",
			"label": "Ask about his brother-in-law",
			"question": "Would your family bid on a city contract?"
		},
		{
			"id": "chief",
			"label": "Ask about the chief's job",
			"question": "What happens to me if you win?"
		},
	],
	"pell":
	[
		{
			"id": "review",
			"label": "Ask what needs review",
			"question": "How many open cases are too many?"
		},
		{
			"id": "books",
			"label": "Ask about the books",
			"question": "How long before the account turns red?"
		},
		{"id": "vote", "label": "Ask about the vote", "question": "What will the voters decide?"},
	],
}


static func _winner_name(winner: String) -> String:
	match winner:
		"kettering":
			return "Royce Kettering"
		"okonjo":
			return "Dana Okonjo-Vale"
		"pell":
			return "Gordon Pell"
	return "The new mayor"


## Contacts and replies are views of the current campaign, not another saved state.
static func contacts(campaign) -> Array:
	if campaign == null:
		return []
	var rows: Array = CONTACTS.duplicate(true)
	for person in rows:
		person["status"] = contact_status(campaign, String(person["id"]))
	return rows


static func contact(campaign, contact_id: String) -> Dictionary:
	for person in contacts(campaign):
		if String(person["id"]) == contact_id:
			return person
	return {}


static func contact_status(campaign, contact_id: String) -> String:
	if campaign == null:
		return "No campaign file."
	var politics = campaign.politics
	# The archive's contact ids are not the politics layer's candidate ids: Dana
	# Okonjo-Vale is "dana" in the story and "okonjo" in the polls. Passing the
	# contact id straight to politics.share() read a key that is not there, which
	# logged an engine error and printed a 0.0% share for her.
	var cand_ids := {"kettering": "kettering", "dana": "okonjo", "pell": "pell"}
	if contact_id in cand_ids:
		if campaign.over():
			var winner := String(politics.result.get("winner", ""))
			return "Election result: %s won." % _winner_name(winner)
		var cand: String = cand_ids[contact_id]
		var lead := "leading" if politics.leader() == cand else "in the field"
		return "Poll share %.1f%% · %s." % [politics.share(cand), lead]
	var ally_ids := {
		"duff": "council",
		"rourke": "union",
		"alma": "coalition",
		"varga": "da",
	}
	var ally_id: String = String(ally_ids.get(contact_id, ""))
	if ally_id != "":
		var condition := "lost" if politics.lost(ally_id) else "standing"
		return "%s · %d/100." % [condition, politics.standing(ally_id)]
	if contact_id == "outgoing":
		return "Handover copy on file · Bridge Street order inherited."
	return "No current entry."


static func topics(contact_id: String) -> Array:
	return QUESTIONS.get(contact_id, []).duplicate(true)


## The speaker answers from the current ledger. Choosing a question never spends
## money, changes standing, advances time or edits the campaign save.
static func dialogue(campaign, contact_id: String, topic_id: String) -> Dictionary:
	if campaign == null:
		return {}
	var selected: Dictionary = {}
	for topic in QUESTIONS.get(contact_id, []):
		if String(topic["id"]) == topic_id:
			selected = topic
			break
	if selected.is_empty():
		return {}
	var politics = campaign.politics
	var dept = campaign.dept
	var reply := ""
	var reference := ""
	match contact_id:
		"outgoing":
			reference = "handover"
			match topic_id:
				"signature":
					reply = (
						"I did not put the pen in your hand. I did put the briefing on your desk. "
						+ "We can share the room; we cannot share the signature."
					)
				"briefing":
					reply = (
						"I told the room what the order said. That is not the same as telling them "
						+ "what would happen when it was served."
					)
				"handover":
					reply = "I left the signed copy. I did not leave you a clean account. There wasn't one."
		"dana":
			match topic_id:
				"bridge":
					reference = "bridge-order"
					reply = "Call it an eviction when you talk about it. An operation makes a street sound empty."
				"record":
					reference = "force-ledger"
					var killed := int(politics.record.get("civ_killed", 0))
					var hit := int(politics.record.get("civ_hit", 0))
					if killed > 0:
						reply = "The record shows %d civilians killed by police. " % killed
						reply += "Put the number beside what you decide next; don't call the count a full account."
					elif hit > 0:
						reply = "The record shows %d civilians hit by police. " % hit
						reply += "The count is a start, not the account. Put the finding and the decision beside it."
					else:
						reply = (
							"The current record says no civilian harm. Keep the word current. "
							+ "You know what one operation can change."
						)
				"mandate":
					reference = "candidate-tally"
					if campaign.over() and String(politics.result.get("winner", "")) == "okonjo":
						reply = (
							"The vote gives me an office. It does not give me a clean past. "
							+ "That file still has to be answered."
						)
					elif campaign.over():
						reply = "The voters chose someone else. My question about Bridge Street hasn't changed."
					else:
						reply = (
							"I don't want a pledge written for a camera. Put the order and its "
							+ "consequences in the public record."
						)
		"varga":
			reference = "case-register"
			match topic_id:
				"evidence":
					var open_cases: int = dept.open_cases().size()
					if open_cases > 0:
						reply = "There are %d open files. " % open_cases
						reply += (
							"Video fixes a frame; a witness gives you a point of view; "
							+ "an officer gives you a statement. Keep them separate."
						)
					else:
						reply = (
							"There are no open Internal Affairs cases. That's a docket count, "
							+ "not a finding that every action was right."
						)
				"clear":
					var charged := int(politics.record.get("charged", 0))
					if politics.lost("da") and charged > 0:
						reply = (
							"My office has charged %d officer%s after department clearances. "
							% [charged, "" if charged == 1 else "s"]
						)
						reply += "The record you release is still the record we review."
					elif politics.lost("da"):
						reply = (
							"My office reviews serious cases the department clears. "
							+ "The loss of standing won't make evidence disappear."
						)
					else:
						reply = (
							"A clearance closes the department's case. It doesn't turn a statement "
							+ "into footage or bind a court."
						)
				"charge":
					reply = (
						"An internal finding and a criminal charge are different entries. "
						+ "My office needs evidence we can test in court. A headline isn't a docket."
					)
		"duff":
			match topic_id:
				"account":
					reference = "account-statement"
					reply = (
						"Balance: $%s. Weekly allocation: $%s. Payroll: $%s. %s"
						% [
							Department.money(dept.balance),
							Department.money(dept.allocation),
							Department.money(dept.payroll()),
							(
								"Hiring, training and new kit are frozen."
								if dept.frozen()
								else "The account is not frozen."
							)
						]
					)
				"grant":
					reference = "account-statement"
					if campaign.over():
						reply = "The term ended at week 40. The next budget chair handles applications."
					else:
						var reason: String = politics.can_grant(_campaign_week(campaign))
						if reason == "":
							reply = (
								"The committee can offer $%s. "
								% Department.money(Politics.GRANT_AMOUNT)
							)
							reply += (
								(
									"Asking costs %d standing, and the next application is eight weeks away. "
									+ "That is an offer, not an endorsement."
								)
								% Politics.GRANT_FAVOUR
							)
						else:
							reply = (
								"Not today. %s. The threshold is written down; I won't pretend otherwise."
								% reason
							)
				"contracts":
					reference = "candidate-tally"
					reply = (
						"My committee examines the bid and records the relationship. "
						+ "Kettering's brother-in-law building vehicles is not a footnote we can remove."
					)
		"rourke":
			reference = "force-ledger"
			match topic_id:
				"staff":
					var busy: Dictionary = campaign.committed()
					var fit := 0
					var injured := 0
					var suspended := 0
					for officer in dept.officers:
						if String(officer["status"]) == "active" and not busy.has(officer["id"]):
							fit += 1
						if String(officer["status"]) == "injured":
							injured += 1
						elif String(officer["status"]) == "suspended":
							suspended += 1
					reply = (
						"This week: %d fit, %d injured, %d suspended. " % [fit, injured, suspended]
					)
					reply += "They're names on a roster, not spare parts."
				"discipline":
					reference = "case-register"
					var dismissed := int(politics.record.get("dismissed", 0))
					if dismissed > 0:
						reply = (
							"You've dismissed %d officer%s. "
							% [dismissed, "" if dismissed == 1 else "s"]
						)
						reply += (
							"I won't ask you to ignore a finding. I will ask you to read the evidence "
							+ "before you name the next one."
						)
					else:
						reply = (
							"Read the statement and the evidence before you decide. A headline is "
							+ "not a case file, Chief."
						)
				"morale":
					reply = "Morale is %d. " % dept.morale
					reply += (
						"It tells me how the department reports for the next shift. "
						+ "It doesn't tell me whether a resident trusts us."
					)
		"alma":
			reference = "force-ledger"
			match topic_id:
				"trust":
					reference = "community-liaison"
					if politics.trust.is_empty():
						reply = (
							"This file has no ward-trust readings. I won't invent a number "
							+ "for the door that won't open."
						)
					else:
						var lowest := 101
						var ward_name := "the wards"
						for i in range(mini(politics.trust.size(), Situations.WARDS.size())):
							if int(politics.trust[i]) < lowest:
								lowest = int(politics.trust[i])
								ward_name = String(Situations.WARDS[i]["name"])
						reply = "%s is lowest at %d. " % [ward_name, lowest]
						reply += "The number tells you where not to start. It doesn't tell you whom to ask."
				"tips":
					reference = "community-liaison"
					if politics.lost("coalition"):
						reply = (
							"The coalition asked its groups to stop sharing tips, and they have. "
							+ "A canvasser can knock; they cannot make a door open."
						)
					else:
						reply = "A tip is a neighbor choosing to tell you something. "
						reply += "It gives you a lead, not permission to treat everyone at an address as guilty."
				"record":
					var hit := int(politics.record.get("civ_hit", 0))
					var killed := int(politics.record.get("civ_killed", 0))
					if hit + killed > 0:
						reply = (
							"The file says %d civilians hit by police and %d killed. "
							% [hit, killed]
						)
						reply += "Keep the finding beside the department's summary. "
						reply += "Don't make the families read only one side."
					else:
						reply = "The record holds no civilian harm yet. Keep the word yet in the sentence."
		"kettering":
			match topic_id:
				"budget":
					reference = "candidate-tally"
					if campaign.over():
						var votes: Dictionary = politics.result.get("votes", {})
						var share := float(votes.get("kettering", 0.0))
						reply = (
							"The account is $%s. My ticket got %.1f%%. "
							% [Department.money(dept.balance), share]
						)
						reply += "The vote is counted. The budget still has to show what it bought."
					else:
						reply = (
							"The account is $%s; my poll share is %.1f%%. "
							% [Department.money(dept.balance), politics.share("kettering")]
						)
						reply += "Two ledgers, Chief. I want the department funded; "
						reply += "I want voters to see what the money buys."
				"family":
					reference = "candidate-tally"
					reply = "My brother-in-law builds armoured vehicles. If the city buys from his firm, "
					reply += "put the relationship in the contract file and let people read it. "
					reply += "I'm not afraid of the price."
				"chief":
					reference = "candidate-tally"
					if campaign.over() and String(politics.result.get("winner", "")) == "kettering":
						reply = "I said I would keep you. I did. The next question is what you can show me."
					elif campaign.over():
						reply = "The voters chose another name. I don't hold the office, so I can't offer you yours."
					else:
						reply = "I won't promise your chair before the votes. "
						reply += "I will promise a budget and ask what the city got for it."
		"pell":
			match topic_id:
				"review":
					reference = "case-register"
					var open_cases: int = dept.open_cases().size()
					var closed_cases := 0
					for case_file in dept.cases:
						if String(case_file["status"]) == "closed":
							closed_cases += 1
					reply = (
						"There are %d open and %d closed Internal Affairs files. "
						% [open_cases, closed_cases]
					)
					reply += "A case that lapsed is not a case that was answered."
				"books":
					reference = "account-statement"
					if campaign.over():
						reply = "Final balance: $%s. " % Department.money(dept.balance)
						reply += "The books stop here; a pending lawsuit may not."
					else:
						var first_red := 0
						for row in campaign.forecast(4):
							if int(row["balance"]) < 0 and first_red == 0:
								first_red = int(row["week"])
						if first_red > 0:
							reply = (
								"On today's numbers, the account turns red in week %d. " % first_red
							)
							reply += "That table leaves out overtime, wounds and lawsuits not yet filed."
						else:
							reply = "Today's numbers stay above zero for four weeks. "
							reply += "Overtime, wounds and lawsuits not yet filed are not in that table."
				"vote":
					reference = "candidate-tally"
					if campaign.over():
						var winner := String(politics.result.get("winner", ""))
						var votes: Dictionary = politics.result.get("votes", {})
						var vote_share := float(votes.get(winner, 0.0))
						reply = (
							"The votes are in. %s has %.1f%%. " % [_winner_name(winner), vote_share]
						)
						reply += "The count is arithmetic; what follows isn't."
					else:
						reply = (
							"I can tell you the poll share, not the result: %.1f%%. A forecast is not an instruction."
							% politics.share("pell")
						)
	return {
		"speaker": String(_contact_name(contact_id)),
		"question": String(selected["question"]),
		"reply": reply,
		"reference": reference,
	}


static func _contact_name(contact_id: String) -> String:
	for contact in CONTACTS:
		if String(contact["id"]) == contact_id:
			return String(contact["name"])
	return "Unknown contact"


static func _campaign_week(campaign) -> int:
	return clampi(int(campaign.week()), 1, int(campaign.WEEKS))


## The filing cabinet is assembled from existing campaign data. Nothing is written back.
static func documents(campaign, filter := "all") -> Array:
	if campaign == null:
		return []
	var docs: Array = []
	if filter in ["all", "office"]:
		var handover := _document(
			"handover",
			"office",
			"WEEK 1 · HANDOVER",
			"Bridge Street: handover memorandum",
			"Outgoing chief",
			"Incoming chief",
			(
				"I gave the Bridge Street briefing. You signed the eviction order as deputy chief. "
				+ "Dana Okonjo-Vale remembers who signed and who briefed it. "
				+ "This memo records that sequence; it does not decide whether the order was lawful."
			)
		)
		docs.append(handover)
		var bridge_order := _document(
			"bridge-order",
			"office",
			"INHERITED · ROUTING COPY",
			"Bridge Street: order abstract",
			"Office of the Chief",
			"Campaign file",
			(
				"Action described in the record: eviction at Bridge Street. Signatory: deputy chief (you). "
				+ "Briefing: outgoing chief. The file records who authorized the order and who explained it. "
				+ "It makes no finding on legality."
			)
		)
		docs.append(bridge_order)
		docs.append(_force_document(campaign))
		docs.append(_account_document(campaign))
		docs.append(_candidate_document(campaign))
		docs.append(_office_log_document(campaign))
	if filter in ["all", "cases"]:
		var cases: Array = campaign.dept.cases
		var open_count: int = campaign.dept.open_cases().size()
		var closed_count := cases.size() - open_count
		var docket_body := (
			"Opened: %d. Open: %d. Closed: %d.\n" % [cases.size(), open_count, closed_count]
		)
		docket_body += "A docket records the department's status; "
		docket_body += "it is not a finding that no misconduct occurred."
		docs.append(
			_document(
				"case-register",
				"cases",
				"WEEK %d · INTERNAL AFFAIRS" % _campaign_week(campaign),
				"Internal Affairs docket",
				"Department",
				"Chief's office",
				docket_body
			)
		)
		for i in range(cases.size() - 1, maxi(-1, cases.size() - 9), -1):
			docs.append(_case_document(cases[i], campaign.dept))
	if filter in ["all", "press"]:
		var press: Array = campaign.politics.press
		if press.is_empty():
			docs.append(
				_document(
					"press-empty",
					"press",
					"THE CARRICK LEDGER",
					"No clippings filed",
					"City desk",
					"Campaign file",
					"The public record has no clipping yet."
				)
			)
		else:
			for i in range(press.size() - 1, maxi(-1, press.size() - 9), -1):
				var item: Dictionary = press[i]
				var issue_week := int(item.get("week", _campaign_week(campaign)))
				if issue_week < 1:
					issue_week = _campaign_week(campaign)
				docs.append(
					_document(
						"press-%d-%d" % [issue_week, i],
						"press",
						"WEEK %d · %s" % [issue_week, String(item.get("kind", "city")).to_upper()],
						String(item.get("head", "Untitled clipping")),
						"The Carrick Ledger",
						"Public file",
						"%s\n\n%s" % [String(item.get("head", "")), String(item.get("body", ""))]
					)
				)
	if filter in ["all", "street"]:
		docs.append(_community_document(campaign))
		docs.append(_unattended_document(campaign))
	return docs


static func _document(
	id: String,
	category: String,
	date: String,
	title: String,
	from: String,
	to: String,
	body: String
) -> Dictionary:
	return {
		"id": id,
		"category": category,
		"date": date,
		"title": title,
		"from": from,
		"to": to,
		"body": body,
	}


static func _force_document(campaign) -> Dictionary:
	var p = campaign.politics
	var dept = campaign.dept
	var closed_cases := 0
	for case_file in dept.cases:
		if String(case_file["status"]) == "closed":
			closed_cases += 1
	var busy: Dictionary = campaign.committed()
	var fit := 0
	var injured := 0
	var suspended := 0
	for officer in dept.officers:
		var status := String(officer["status"])
		if status == "active" and not busy.has(officer["id"]):
			fit += 1
		elif status == "injured":
			injured += 1
		elif status == "suspended":
			suspended += 1
	var record: Dictionary = p.record
	var body := (
		"Operations succeeded: %d. Failed: %d. Situations unattended: %d.\n"
		% [
			int(record.get("successes", 0)),
			int(record.get("failures", 0)),
			int(record.get("unattended", 0))
		]
	)
	body += (
		"Civilians hit by police: %d. Killed by police: %d. Officers killed: %d.\n"
		% [
			int(record.get("civ_hit", 0)),
			int(record.get("civ_killed", 0)),
			int(record.get("officers_killed", 0))
		]
	)
	body += (
		"Internal Affairs cases: %d open, %d closed. Average ward trust: %.0f."
		% [
			dept.open_cases().size(),
			closed_cases,
			p.avg_trust(),
		]
	)
	body += (
		"\nStaffing: %d fit and uncommitted, %d injured, %d suspended. Department morale: %d."
		% [fit, injured, suspended, dept.morale]
	)
	return _document(
		"force-ledger",
		"office",
		"WEEK %d · FORCE RECORD" % _campaign_week(campaign),
		"Department force ledger",
		"Chief's office",
		"Campaign file",
		body
	)


static func _account_document(campaign) -> Dictionary:
	var dept = campaign.dept
	var pending_suits: Array = campaign.politics.pending.filter(
		func(item): return String(item.get("kind", "")) == "lawsuit"
	)
	var due := 0
	for suit in pending_suits:
		due += int(suit.get("cost", 0))
	var body := (
		"Balance: $%s. Weekly allocation: $%s. Payroll: $%s.\n"
		% [
			Department.money(dept.balance),
			Department.money(dept.allocation),
			Department.money(dept.payroll())
		]
	)
	body += (
		"Hiring, training and new kit: %s. Pending lawsuit settlements: %d ($%s).\n"
		% ["frozen" if dept.frozen() else "available", pending_suits.size(), Department.money(due)]
	)
	body += "Recent account entries:\n"
	var shown := 0
	for i in range(dept.ledger.size() - 1, maxi(-1, dept.ledger.size() - 7), -1):
		var entry: Dictionary = dept.ledger[i]
		var amount := int(entry.get("amount", 0))
		body += (
			"Week %d · %s$%s · %s\n"
			% [
				int(entry.get("week", 0)),
				"+" if amount >= 0 else "-",
				Department.money(absi(amount)),
				String(entry.get("item", "account entry"))
			]
		)
		shown += 1
	if shown == 0:
		body += "No account entries yet.\n"
	return _document(
		"account-statement",
		"office",
		"WEEK %d · ACCOUNTS" % _campaign_week(campaign),
		"Department account statement",
		"Finance desk",
		"Budget committee",
		body.strip_edges()
	)


static func _candidate_document(campaign) -> Dictionary:
	var p = campaign.politics
	var body := "Candidate briefs and current poll shares; not a ballot count:\n"
	for candidate in Politics.CAND_ORDER:
		var profile: Dictionary = Politics.CANDIDATES[candidate]
		body += (
			"%s · %.1f%%\n%s\n\n"
			% [String(profile["name"]), p.share(candidate), String(profile["blurb"])]
		)
	if campaign.over():
		var winner := String(p.result.get("winner", ""))
		var votes: Dictionary = p.result.get("votes", {})
		body += (
			"\nElection result: %s, %.1f%% of the vote."
			% [_winner_name(winner), float(votes.get(winner, 0.0))]
		)
	else:
		body += "\nElection day: the end of week 40. A poll is not a result."
	return _document(
		"candidate-tally",
		"office",
		"WEEK %d · CITY HALL" % _campaign_week(campaign),
		"Candidate file and tally",
		"City Hall",
		"Campaign file",
		body
	)


static func _office_log_document(campaign) -> Dictionary:
	var notes: Array = campaign.dept.notes
	var body := "Latest entries from the department's working log:\n"
	var shown := 0
	for i in range(notes.size() - 1, maxi(-1, notes.size() - 9), -1):
		var note: Dictionary = notes[i]
		body += "Week %d · %s\n" % [int(note.get("week", 0)), String(note.get("text", ""))]
		shown += 1
	if shown == 0:
		body += "No entries yet.\n"
	return _document(
		"office-log",
		"office",
		"WEEK %d · INTERNAL" % _campaign_week(campaign),
		"Chief's office log",
		"Department",
		"Chief's office",
		body.strip_edges()
	)


static func _case_document(case_file: Dictionary, dept) -> Dictionary:
	var officer: Dictionary = dept.get_officer(String(case_file.get("officer", "")))
	var name := "%s %s" % [String(officer.get("rank", "")), String(officer.get("name", "?"))]
	name = name.strip_edges()
	var kind := String(
		Department.CASE_KINDS.get(
			String(case_file.get("kind", "")), String(case_file.get("kind", "finding"))
		)
	)
	var status := "OPEN" if String(case_file.get("status", "")) == "open" else "CLOSED"
	var decision := String(case_file.get("decision", ""))
	var body := (
		"Officer: %s. Finding: %s.\nPlace: %s. Evidence: %s.\n"
		% [
			name,
			kind,
			String(case_file.get("place", "not recorded")),
			String(case_file.get("strength", "not recorded"))
		]
	)
	body += "Finding text: %s\n" % String(case_file.get("text", "not recorded"))
	var statement := String(case_file.get("statement", "untested"))
	body += "Officer statement: %s.\n" % statement.replace("_", " ")
	var witness_id := String(case_file.get("witness", ""))
	var witness: Dictionary = dept.get_officer(witness_id) if witness_id != "" else {}
	if not witness.is_empty():
		body += (
			"Squadmate: %s %s; testimony: %s.\n"
			% [
				String(witness.get("rank", "")),
				String(witness.get("name", "")),
				String(case_file.get("testimony", "unclear")).replace("_", " ")
			]
		)
	body += "Status: %s%s." % [status, " · " + decision if decision != "" else ""]
	return _document(
		"case-%s" % String(case_file.get("id", "unknown")),
		"cases",
		"WEEK %d · INTERNAL AFFAIRS" % int(case_file.get("week", 0)),
		"%s · %s" % [String(case_file.get("id", "IA")), kind],
		"Internal Affairs",
		"Chief's office",
		body
	)


static func _community_document(campaign) -> Dictionary:
	var politics = campaign.politics
	var contact_line := (
		"Community groups are not sharing tips while the coalition has withdrawn."
		if politics.lost("coalition")
		else "Community groups remain a potential source of tips; individual calls may still have none."
	)
	var body := (
		"Coalition standing: %d/100. %s\n\nWard trust:"
		% [politics.standing("coalition"), contact_line]
	)
	for i in range(mini(politics.trust.size(), Situations.WARDS.size())):
		var ward_name: String = String(Situations.WARDS[i]["name"])
		var trust: int = int(politics.trust[i])
		body += (
			"\n%s · %d/100%s"
			% [ward_name, trust, " · community tips unavailable" if trust < 25 else ""]
		)
	return _document(
		"community-liaison",
		"street",
		"WEEK %d · COMMUNITY LIAISON" % _campaign_week(campaign),
		"Coalition and ward trust report",
		"Carrick Community Coalition",
		"Chief's office",
		body
	)


static func _unattended_document(campaign) -> Dictionary:
	var missed: Array = campaign.past.filter(
		func(item): return String(item.get("status", "")) == "unattended"
	)
	var body := "Unattended situations from completed weeks:\n"
	var shown := 0
	for i in range(missed.size() - 1, maxi(-1, missed.size() - 9), -1):
		var item: Dictionary = missed[i]
		body += (
			"Week %d · %s · %s ward · %s\n"
			% [
				int(item.get("week", 0)),
				String(item.get("title", "Call")),
				String(item.get("ward", "unassigned")),
				String(item.get("type", "situation"))
			]
		)
		shown += 1
	if shown == 0:
		body += "No completed week has a call filed as unattended.\n"
	return _document(
		"unattended-log",
		"street",
		"WEEK %d · PUBLIC SERVICE" % _campaign_week(campaign),
		"Unanswered calls register",
		"Campaign board",
		"Chief's office",
		body.strip_edges()
	)
