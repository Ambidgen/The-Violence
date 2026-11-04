extends SceneTree
## Story-layer gate: the act spine is legible at each boundary, the weekly page reads
## the saved campaign, and rendering prose cannot change simulation state.
##   godot --headless --path . -s res://tests/story_test.gd

const Campaign = preload("res://scripts/campaign/campaign.gd")
const Story = preload("res://scripts/campaign/story.gd")
const StoryArchive = preload("res://scripts/campaign/story_archive.gd")

var problems := 0


func _check(ok: bool, what: String) -> void:
	print("  %s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		problems += 1


func _init() -> void:
	Campaign.read_city_file = false
	var c = Campaign.new()
	c.start(2401)
	var opening: Dictionary = Story.current(c)
	var before := JSON.stringify(c.to_data())
	var reread: Dictionary = Story.current(c)
	_check(
		opening["act"] == 1 and opening["title"] == "A signature",
		"week one opens on the inherited Bridge Street order"
	)
	_check(
		(
			String(opening["text"]).contains("You signed the order")
			and String(opening["quote"]).contains("one of us")
		),
		"the outgoing chief owns the briefing, not the signature"
	)
	_check(
		String(opening["focus"]) != "" and String(opening["record"]).contains("not a promise"),
		"the page reads this week's open call and the current force record"
	)
	_check(
		reread == opening and before == JSON.stringify(c.to_data()),
		"reading the story page is deterministic and does not mutate the campaign"
	)
	var people: Array = StoryArchive.contacts(c)
	var library: Array = StoryArchive.documents(c)
	var document_ids: Array = []
	for document in library:
		document_ids.append(String(document["id"]))
	var dana_reply: Dictionary = StoryArchive.dialogue(c, "dana", "bridge")
	_check(people.size() == 8, "the campaign file lists the eight people with a public stake")
	var all_dialogue_present := true
	var dialogue_count := 0
	for person in people:
		var contact_id := String(person["id"])
		for topic in StoryArchive.topics(contact_id):
			var exchange: Dictionary = StoryArchive.dialogue(c, contact_id, String(topic["id"]))
			if (
				String(exchange.get("reply", "")).is_empty()
				or not document_ids.has(String(exchange.get("reference", "")))
			):
				all_dialogue_present = false
			dialogue_count += 1
	_check(
		StoryArchive.topics("dana").size() == 3 and dialogue_count == 24 and all_dialogue_present,
		"each key character offers three playable questions with a reply"
	)
	_check(
		(
			String(dana_reply.get("reply", "")).contains("eviction")
			and String(dana_reply.get("reference", "")) == "bridge-order"
		),
		"a conversation answers from character voice and cites a matching document"
	)
	var required_docs := [
		"handover",
		"bridge-order",
		"force-ledger",
		"account-statement",
		"candidate-tally",
		"case-register",
		"community-liaison",
		"unattended-log",
	]
	_check(
		required_docs.all(func(document_id): return document_ids.has(document_id)),
		"the filing cabinet assembles handover, office, case and street records"
	)
	_check(
		before == JSON.stringify(c.to_data()),
		"opening a conversation or assembling documents does not mutate the campaign"
	)

	var boundaries := {1: 1, 10: 2, 20: 3, 30: 4, 40: 5}
	for week in range(1, Campaign.WEEKS + 1):
		var page: Dictionary = Story.current(c)
		if boundaries.has(week):
			_check(
				int(page["act"]) == int(boundaries[week]),
				(
					"week %d belongs to act %d (%s)"
					% [week, int(page["act"]), String(page["act_title"])]
				)
			)
		c.end_week()
	_check(c.over(), "the campaign reaches election night after week 40")
	var ending: Dictionary = Story.current(c)
	_check(
		(
			ending["week"] == 40
			and ending["title"] == "The vote is in"
			and String(ending["quote"]) != ""
		),
		"election night files the winner's voice against the full campaign"
	)
	_check(String(ending["focus"]) == "", "the closed campaign has no open-call focus")

	c.politics.record["civ_killed"] = 2
	var harm: Dictionary = Story.current(c)
	var dana_harm: Dictionary = StoryArchive.dialogue(c, "dana", "record")
	_check(
		String(harm["record"]).contains("2 civilians killed by police"),
		"the public record updates from campaign consequences"
	)
	_check(
		String(dana_harm["reply"]).contains("2 civilians killed"),
		"character replies change when the saved force record changes"
	)
	var case_file := {
		"id": "IA-TEST",
		"officer": c.dept.officers[0]["id"],
		"week": 12,
		"kind": "broke_order",
		"text": "Test finding",
		"strength": "witness",
		"place": "Market Street",
		"status": "open",
		"decision": "",
		"statement": "matches",
		"witness": "",
	}
	c.dept.cases.append(case_file)
	var case_docs: Array = StoryArchive.documents(c, "cases")
	_check(
		(
			case_docs.size() == 2
			and case_docs.any(func(document): return String(document["id"]) == "case-IA-TEST")
		),
		"the Internal Affairs cabinet files case details from campaign state"
	)
	print("problems: %d" % problems)
	quit(1 if problems > 0 else 0)
