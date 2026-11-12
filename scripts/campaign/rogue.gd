extends RefCounted
## The run layer (1.3, roguelike story mode). A campaign is a run: forty weeks from one
## seed, one ironman file, the election at the end. What this layer adds is the build —
## the things the chief drafts and answers that make one run unlike the last:
##
##   - procurement drafts: the armoury starts with patrol stock; every few weeks three
##     contracts are offered and one can be signed (Equipment.armory gates every kit);
##   - department training programs: three on offer every few weeks; the one chosen
##     teaches a single habit to every officer on the force when it completes, and the
##     academy keeps teaching it to every hire after (Department.curriculum);
##   - offers from the city's power brokers, its press and its community leaders:
##     accept or let them lapse at the end of the week;
##   - events with two to four responses, some of them gambles, that must be answered
##     before the week can end;
##   - a week-1 inheritance draft of starting doctrines, widened between runs by the
##     legacy file (user://legacy.json).
##
## Nothing here touches a combat roll. It changes the inputs the simulation reads —
## kit, habits, money, allies, intel — and leaves the CQB model alone.
##
## Deterministic for the campaign seed: every roll comes from this object's own rng,
## saved with the campaign, so the same seed deals the same desk.

const Equipment = preload("res://scripts/data/equipment.gd")
const Habits = preload("res://scripts/data/habits.gd")
const Courses = preload("res://scripts/data/courses.gd")
const Politics = preload("res://scripts/campaign/politics.gd")
const Situations = preload("res://scripts/campaign/situations.gd")

const VERSION := 1
const LEGACY_PATH := "user://legacy.json"

## What the armoury holds on day one: the patrol kit every inherited officer already
## carries, plus iron sights and the door ram. ("none" armour and helmet always exist.)
const BASE_STOCK := ["service_pistol", "carbine", "red_dot", "irons", "vest", "light", "medkit", "oc_spray",
	"baton", "taser", "ram"]

## Procurement contracts. tier 1 from week 1, tier 2 from week 5, tier 3 from week 13.
## tag: restraint (the coalition approves), neutral, military (Safe Streets cheers, the
## coalition and the Ledger take note).
const CONTRACTS := {
	"plates": {"name": "Plate carriers", "items": ["plates"], "cost": 6000, "tier": 1, "tag": "neutral",
		"desc": "Rifle plates front and back. Stops what a soft vest cannot; heavier on the stairs."},
	"helmets": {"name": "Ballistic helmets", "items": ["ballistic_helmet"], "cost": 4000, "tier": 1, "tag": "neutral",
		"desc": "Handgun-rated helmets. A head hit from a pistol is no longer the end of the file."},
	"shotgun": {"name": "Shotguns and beanbag rounds", "items": ["shotgun", "beanbag"], "cost": 3500, "tier": 1, "tag": "restraint",
		"desc": "The pump shotgun, and the beanbag rounds that make it a way to stop someone without killing them."},
	"gas": {"name": "CS gas and masks", "items": ["gas", "gas_mask"], "cost": 3000, "tier": 1, "tag": "neutral",
		"desc": "Time is on the police side at a barricade. Gas makes that true. Tactically trained officers throw it."},
	"bangs": {"name": "Flashbangs", "items": ["flashbang"], "cost": 3000, "tier": 1, "tag": "military",
		"desc": "Two seconds of nobody thinking clearly in the room. Tactically trained officers only."},
	"smg": {"name": "Submachine guns", "items": ["smg"], "cost": 5000, "tier": 1, "tag": "neutral",
		"desc": "Fast handling indoors with pistol rounds: fewer of them go through the wall into the flat next door."},
	"pistols": {"name": "Compact, light and heavy pistols", "items": ["compact_pistol", "light_pistol", "heavy_pistol"], "cost": 2500, "tier": 1, "tag": "neutral",
		"desc": "A quicker draw, or a heavier round. Choice for the sidearm."},
	"pepper": {"name": "Pepperball launchers", "items": ["pepperball"], "cost": 4500, "tier": 2, "tag": "restraint",
		"desc": "Irritant rounds at a distance. Tactically trained officers only."},
	"launcher": {"name": "40 mm less-lethal launchers", "items": ["launcher"], "cost": 5000, "tier": 2, "tag": "restraint",
		"desc": "A sponge round that ends an argument at fifteen metres. Tactically trained officers only."},
	"sting": {"name": "Sting-ball grenades", "items": ["stingball"], "cost": 2500, "tier": 2, "tag": "neutral",
		"desc": "Rubber pellets in a room. It hurts; it usually does not maim."},
	"sbr": {"name": "Short-barrel rifles", "items": ["sbr"], "cost": 6500, "tier": 2, "tag": "military",
		"desc": "Handier than the carbine in a hallway, louder. Tactically trained officers only."},
	"shield": {"name": "Ballistic shields", "items": ["shield"], "cost": 7000, "tier": 2, "tag": "neutral",
		"desc": "A wall the point man carries. Slow, heavy, and the reason someone comes home."},
	"breach": {"name": "Breaching rounds", "items": ["breach", "shotgun"], "cost": 4500, "tier": 2, "tag": "military",
		"desc": "A locked door opened with one shotgun shot. Comes with the shotguns to fire it."},
	"surplus": {"name": "Seized-weapons program", "items": ["assault_rifle"], "cost": 1500, "tier": 2, "tag": "military",
		"desc": "Rifles taken off the street, re-issued. Cheap. The papers will ask where they came from."},
	"optics": {"name": "Marksman rifles and magnified optics", "items": ["marksman", "magnified"], "cost": 8000, "tier": 3, "tag": "military",
		"desc": "A precision rifle and a 1-6x sight for the officer covering the windows."},
	"battle": {"name": "Battle rifles", "items": ["battle_rifle"], "cost": 7000, "tier": 3, "tag": "military",
		"desc": "7.62 through armour and through the wall behind it."},
	# EA_TASKS P1.D4: a capital item, not a kit line — bought once, never carried. Its entry
	# here is what puts it in the procurement draft and prices it; dept.capital records the
	# purchase and the gang-raid rescue reads it. Declared 2026-11-02: `_sign` looked up
	# CONTRACTS["arv"] and there was no such contract, so the ARV could not be bought at all.
	"arv": {"name": "Armoured rescue vehicle", "items": [], "cost": 22000, "tier": 3, "tag": "military",
		"desc": "An armoured truck and a crew for it. On a gang raid it carries the first officer downed out alive. Not carried in a kit: it waits at the kerb."},
}
const CONTRACT_EVERY := 4       # a procurement draft in week 1, 5, 9, ...
const PROGRAM_FIRST := 2        # a program draft in week 2, 8, 14, ...
const PROGRAM_EVERY := 6
const PASS_REFUND := 2000       # passing on a procurement draft: surplus sold off
const DRAFT_N := 3

## Programs: a habit for the whole force. Not the academy's own twelve (every officer
## has those); weighted towards what the department's record says it lacks.
const PROGRAM_BASE := 1800
const PROGRAM_PER := 140        # per officer on the books
const SPECIAL_PROGRAMS := {
	"crisis": {"name": "Crisis intervention training", "tag": "restraint", "weeks": 3,
		"desc": "Every officer: judgment +4 (to 90 at most). Fewer misjudged civilians, more surrenders taken."},
	"peer": {"name": "Peer support program", "tag": "restraint", "weeks": 2,
		"desc": "Every officer: trauma -3, and department morale +4 when it ends."},
	"inservice": {"name": "Firearms in-service", "tag": "neutral", "weeks": 2,
		"desc": "Every officer short of four qualifications gets one more: faster recognition, aim and reloads."},
}
## Habits that answer findings the department keeps collecting.
const FINDING_HABITS := {"friendly_fire": ["GD03", "WD10", "GD07"], "civilian_hit_by_police": ["ED04", "WD09", "WD10"],
	"misjudgment": ["ED04", "ED06"], "officer_down": ["PF05", "PF07", "GD08", "WD03"], "excessive_force": ["WD09", "ED04"]}

## Starting doctrines for the week-1 inheritance draft. The first three are always
## there; the rest unlock between runs (legacy), one per finished run, two for a run
## that ends with the chief kept on.
const DOCTRINES := {
	"reserve": {"name": "A quiet reserve", "desc": "The outgoing chief left $10,000 the auditors never found. It is yours now."},
	"plates": {"name": "Plate carriers on day one", "desc": "A contract signed before you arrived: plate carriers are in the armoury."},
	"pie": {"name": "Slice the pie", "desc": "A training sergeant's legacy: every officer, and every hire from now on, approaches doorways on an arc (PF03)."},
	"liaison": {"name": "Community liaison office", "desc": "The coalition +10, trust +4 in every ward."},
	"union": {"name": "An old friend at the union", "desc": "Tommy Rourke owes you one: the union +15."},
	"cams": {"name": "Body cameras from a federal grant", "desc": "Every officer wears a body camera from week 1, at no cost."},
	"tactical": {"name": "A tactical cadre", "desc": "The three most experienced officers without it are tactically certified."},
	"lines": {"name": "Respect lines of fire", "desc": "Every officer, and every hire, never walks through a teammate's muzzle (GD03)."},
}
const DOCTRINE_ORDER := ["reserve", "plates", "pie", "liaison", "union", "cams", "tactical", "lines"]
const DOCTRINE_BASE := 3

## Who makes offers. Allies and candidates come from Politics; these are the rest.
const PEOPLE := {
	"ferrante": {"name": "Nadia Ferrante", "title": "crime reporter, the Carrick Ledger"},
	"crane": {"name": "Hollis Crane", "title": "anchor, Channel 6 Nightly"},
	"osei": {"name": "Pastor Ruth Osei", "title": "Kilbride Tenants' Association"},
	"lindqvist": {"name": "Arne Lindqvist", "title": "Riverside Business Association"},
	"diaz": {"name": "Councillor Ana Diaz", "title": "Ironworks ward"},
}

## Offers: accept, or let them lapse at the end of the week. "who" is an ally id, a
## candidate id or a PEOPLE id. Effects are read by apply().
const OFFERS := [
	{"id": "kettering_armour", "who": "kettering", "min": 3,
		"text": "George Carrick wants to be photographed handing you the keys to an armoured rescue vehicle. His son Kevin's firm will throw in a rifle contract. All you have to do is stand next to him.",
		"accept": {"money": 6000, "contract": "military", "poll": {"kettering": 3.0}, "ally": {"coalition": -8},
			"headline": ["CHIEF, CARRICK POSE WITH ARMOURED TRUCK", "Beddrow: 'A tank is not a policy.'"]},
		"decline": {"poll": {"kettering": -0.5}}},
	{"id": "okonjo_board", "who": "okonjo", "min": 4,
		"text": "Alicia Beddrow will stop reading the Bridge Street order into every microphone if you agree to a civilian review board with subpoena power.",
		"accept": {"trust": 4, "ally": {"coalition": 8, "union": -10}, "poll": {"okonjo": 1.0}, "morale": -4,
			"headline": ["CHIEF AGREES TO CIVILIAN REVIEW BOARD", "Rourke (union): 'They will be second-guessing us from a conference room.'"]},
		"decline": {"poll": {"okonjo": 0.5}}},
	{"id": "pell_audit", "who": "pell", "min": 2,
		"text": "Gordon Pell would like to run an efficiency audit of the department. His people say it will find money. It will also find things.",
		"accept": {"money": 4000, "later": {"weeks": 4, "text": "Pell's audit reports: overtime practices 'irregular'.", "effects": {"ally": {"union": -6}, "poll": {"pell": 1.0}}}},
		"decline": {}},
	{"id": "duff_overtime", "who": "council", "min": 5,
		"text": "Marguerite Duff can move an overtime line from Parks into your budget. She wants the department's help clearing the encampment under the Riverside overpass next week. Quietly.",
		"accept": {"money": 9000, "trust_ward": [1, -8], "ally": {"council": 4, "coalition": -6},
			"later": {"weeks": 2, "text": "The overpass was cleared at dawn. Someone filmed it.", "effects": {"trust": -1, "poll": {"okonjo": 1.5}}}},
		"decline": {"ally": {"council": -3}}},
	{"id": "rourke_overtime", "who": "union", "min": 3,
		"text": "Tommy Rourke wants overtime paid at time-and-a-half for callouts, not just shifts. Agree and the union stands behind you; refuse and he files a grievance.",
		"accept": {"money": -3000, "ally": {"union": 10}, "morale": 6},
		"decline": {"ally": {"union": -6}, "morale": -3}},
	{"id": "mbeki_ridealong", "who": "coalition", "min": 2,
		"text": "Rev. Mbeki-Shaw proposes a ride-along program: coalition volunteers with your officers on patrol. People talk to officers they know.",
		"accept": {"ally": {"coalition": 6}, "intel_weeks": 6, "money": -1500},
		"decline": {"ally": {"coalition": -2}}},
	{"id": "varga_taskforce", "who": "da", "min": 6,
		"text": "Paul Varga wants a joint gang task force: his investigators sit in your briefings. Better files on the crews; his name on your arrests.",
		"accept": {"ally": {"da": 8}, "intel_weeks": 4, "poll": {"pell": 0.5}},
		"decline": {"ally": {"da": -3}}},
	{"id": "ferrante_embargo", "who": "ferrante", "min": 2, "needs": "pending_story",
		"text": "Nadia Ferrante has a story about one of your operations. She will hold it three weeks if you give her the exclusive when it runs.",
		"accept": {"delay_stories": 3, "later": {"weeks": 3, "text": "Ferrante's exclusive runs: it is fair, and it is long.", "effects": {"poll": {"pell": 0.5}}}},
		"decline": {}},
	{"id": "crane_profile", "who": "crane", "min": 3,
		"text": "Channel 6 wants a week embedded with your best officer for a prime-time profile. Good television; an officer committed to the cameras.",
		"accept": {"trust": 2, "poll": {"kettering": 0.8}, "officer": {"pick": "best", "morale_file": "Profiled on Channel 6 Nightly.", "commit": 1}},
		"decline": {}},
	{"id": "osei_mediators", "who": "osei", "min": 3,
		"text": "Pastor Osei's tenants' association will train volunteer mediators for Kilbride if the department pays for the course and stays out of the courtyards during it.",
		"accept": {"money": -2500, "trust_ward": [5, 8], "ally": {"coalition": 3}},
		"decline": {"trust_ward": [5, -2]}},
	{"id": "lindqvist_cameras", "who": "lindqvist", "min": 4,
		"text": "The Riverside Business Association will donate a CCTV network along the docks if the department prioritises their calls.",
		"accept": {"intel_weeks": 3, "ally": {"council": 3, "coalition": -4}, "trust_ward": [1, -3]},
		"decline": {}},
	{"id": "diaz_academy", "who": "diaz", "min": 5,
		"text": "Councillor Diaz has a federal grant for academy places, earmarked for recruits from Ironworks. Two academy places, free; the recruits are hers to name.",
		"accept": {"recruits": 2, "trust_ward": [3, 5], "ally": {"council": 2}},
		"decline": {"trust_ward": [3, -2]}},
	{"id": "kettering_donor", "who": "kettering", "min": 10,
		"text": "A Safe Streets donor wants to pay for a department gala. You give a speech. It will be on the evening news.",
		"accept": {"money": 8000, "poll": {"kettering": 2.0, "pell": -0.5}, "ally": {"da": -4},
			"headline": ["POLICE CHIEF HEADLINES SAFE STREETS GALA", "Pell: 'Policing is not a party.' Varga declines to comment."]},
		"decline": {}},
	{"id": "okonjo_listening", "who": "okonjo", "min": 12,
		"text": "Beddrow invites you to a public listening session in Eastport. She will be there. So will everyone who has a reason to be angry.",
		"accept": {"chance": {"p": 0.55, "text": "the session", "win": {"trust": 3, "poll": {"pell": 0.5}, "ally": {"coalition": 5}},
			"lose": {"trust": -1, "poll": {"okonjo": 1.5}, "headline": ["CHIEF SHOUTED DOWN IN EASTPORT", "'Say the names,' the room chanted."]}}},
		"decline": {"poll": {"okonjo": 0.8}}},
	# EA_TASKS P1.D4: late-game sinks with real effects, dealt like any other offer.
	{"id": "range_build", "who": "diaz", "min": 10,
		"text": "Councillor Diaz has a state grant for a training range on the old Foundry Road lot — if the department pays the construction balance itself.",
		"accept": {"money": -8000, "range": true, "trust_ward": [3, 4], "ally": {"council": 3},
			"headline": ["PORT CARRICK PD OPENS ITS OWN TRAINING RANGE", "Diaz: 'The county range is forty minutes away. This one is not.'"]},
		"decline": {}},
	{"id": "union_contract", "who": "union", "min": 12,
		"text": "Tommy Rourke can hold the room for a contract: a one-time payment now, and the morale floor of this department rises for good.",
		"accept": {"money": -6000, "morale_floor": 10, "ally": {"union": 10}, "morale": 4,
			"headline": ["POLICE SIGN UNION CONTRACT", "Rourke: 'The floor is the floor. It does not move again.'"]},
		"decline": {"ally": {"union": -3}}},
	{"id": "return_surplus", "who": "council", "min": 6,
		"text": "Marguerite Duff notes, quietly, that the department's account is getting heavy. Return $5,000 of surplus to the city and the committee will remember it.",
		"accept": {"money": -5000, "ally": {"council": 6}},
		"decline": {}},
]

## Events: two to four responses, answered before the week can end. {officer} names an
## officer from the roster (rolled when the event lands). A choice may need money.
const EVENTS := [
	{"id": "viral_stop", "min": 2, "title": "A video from a traffic stop",
		"text": "Forty seconds of {officer} shouting at a teenager during a traffic stop has two hundred thousand views. Nobody was hurt. The comments are not about that.",
		"choices": [
			{"label": "Back {officer} publicly", "effects": {"ally": {"union": 5, "coalition": -6}, "trust": -2}},
			{"label": "Open a use-of-force review", "effects": {"money": -2500, "ally": {"union": -3}, "officer": {"judgment": 5, "out": 1}}},
			{"label": "Suspend {officer} for two weeks", "effects": {"ally": {"union": -8, "coalition": 4}, "trust": 2, "officer": {"suspend": 2}}},
		]},
	{"id": "ammo_recall", "min": 3, "title": "An ammunition recall",
		"text": "The manufacturer has recalled the lot of duty ammunition the department bought last spring. Squib loads, one in a few thousand.",
		"choices": [
			{"label": "Replace it all now", "effects": {"money": -4000}},
			{"label": "Use it up in training first", "effects": {"chance": {"p": 0.8, "text": "the old lot", "win": {}, "lose": {"officer": {"trauma": 3}, "morale": -4, "headline": ["OFFICER HURT BY RECALLED AMMUNITION", "The department had been told."]}}}},
		]},
	{"id": "evidence_theft", "min": 4, "title": "Missing from the evidence room",
		"text": "Eleven thousand dollars in seized cash is missing from the evidence room. The log says {officer} signed for the bag last.",
		"choices": [
			{"label": "Call the state police in", "effects": {"ally": {"da": 6, "union": -6}, "headline": ["STATE POLICE PROBE CARRICK EVIDENCE ROOM", "The chief called them in. Rourke: 'Guilty until proven innocent.'"]}},
			{"label": "Handle it internally", "effects": {"chance": {"p": 0.6, "text": "the internal inquiry", "win": {"money": 11000}, "lose": {"ally": {"da": -8}, "headline": ["EVIDENCE CASH 'HANDLED INTERNALLY', SAYS DA", "Varga: 'Internally is not a place.'"]}}}},
			{"label": "Dismiss {officer}", "effects": {"officer": {"fire": true}, "ally": {"union": -10, "da": 3}}},
		]},
	{"id": "heat_wave", "min": 6, "title": "A heat wave",
		"text": "Nine days over thirty-five degrees. Calls are up. Tempers are up. The station air conditioning is not.",
		"choices": [
			{"label": "Fix the air conditioning", "effects": {"money": -3500, "morale": 4}},
			{"label": "Cooling buses in the hottest wards", "effects": {"money": -2000, "trust": 2, "ally": {"coalition": 2}}},
			{"label": "Ride it out", "effects": {"morale": -6}},
		]},
	{"id": "gang_truce", "min": 8, "title": "A truce on offer",
		"text": "A go-between says the Zarya Bratva and the Los Halcones will stop shooting each other for a month if the department stops raiding their houses for a month.",
		"choices": [
			{"label": "Take the truce", "effects": {"ally": {"coalition": 4, "da": -6}, "poll": {"kettering": 1.0}, "quiet_weeks": 3}},
			{"label": "Refuse", "effects": {}},
			{"label": "Take it and keep raiding", "effects": {"ally": {"da": 2}, "later": {"weeks": 2, "text": "The crews have worked out the truce was a trap. Two shootings in a night.", "effects": {"trust": -2, "poll": {"kettering": 1.0}}}}},
		]},
	{"id": "sickout", "min": 7, "needs": "low_morale", "title": "The blue flu",
		"text": "A third of the night shift has called in sick. Rourke says he knows nothing about it.",
		"choices": [
			{"label": "Meet the union", "effects": {"money": -2000, "ally": {"union": 6}, "morale": 5}},
			{"label": "Dock their pay", "effects": {"money": 3000, "ally": {"union": -10}, "morale": -4}},
			{"label": "Say nothing", "effects": {"morale": -2}},
		]},
	{"id": "witness", "min": 3, "title": "A witness asks for protection",
		"text": "A woman who saw a shooting in Kilbride will testify if the department keeps an officer outside her building for two weeks.",
		"choices": [
			{"label": "Assign {officer}", "effects": {"officer": {"commit": 2}, "ally": {"da": 5}, "trust_ward": [5, 3]}},
			{"label": "Refer her to the DA's program", "effects": {"chance": {"p": 0.7, "text": "the witness", "win": {}, "lose": {"ally": {"da": -4}, "trust_ward": [5, -4]}}}},
		]},
	{"id": "offduty", "min": 5, "title": "An off-duty arrest",
		"text": "{officer} was arrested off duty after a fight outside a bar in Northgate. The other man is in hospital.",
		"choices": [
			{"label": "Suspend pending charges", "effects": {"officer": {"suspend": 3}, "ally": {"da": 3, "union": -3}}},
			{"label": "Dismiss {officer}", "effects": {"officer": {"fire": true}, "ally": {"union": -6}, "trust": 1}},
			{"label": "Let the courts decide", "effects": {"ally": {"da": -5}, "headline": ["OFFICER CHARGED IN BAR FIGHT STILL ON DUTY", "The department declined to comment."]}},
		]},
	{"id": "surplus_offer", "min": 4, "title": "Federal surplus",
		"text": "A federal program will ship the department military surplus — rifles, an armoured truck, night vision — for the cost of shipping.",
		"choices": [
			{"label": "Sign for all of it", "effects": {"money": -1000, "contract": "military", "poll": {"kettering": 1.5}, "ally": {"coalition": -8},
				"headline": ["CARRICK PD TAKES MILITARY SURPLUS", "Mbeki-Shaw: 'We asked for officers who know our names, not a truck.'"]}},
			{"label": "Take the rifles only", "effects": {"contract": "surplus", "ally": {"coalition": -3}}},
			{"label": "Decline", "effects": {"ally": {"coalition": 2}}},
		]},
	{"id": "records_request", "min": 6, "title": "A records request",
		"text": "Nadia Ferrante has filed a request for every use-of-force report since you took office. The law gives you thirty days.",
		"choices": [
			{"label": "Release them in full", "effects": {"trust": 2, "poll": {"pell": 0.5}, "chance": {"p": 0.5, "text": "the reports", "win": {}, "lose": {"poll": {"okonjo": 1.5}}}}},
			{"label": "Release them redacted", "effects": {"money": -1500}},
			{"label": "Fight it in court", "effects": {"money": -5000, "ally": {"coalition": -4}, "headline": ["POLICE FIGHT LEDGER'S RECORDS REQUEST", "Ferrante: 'We will see them in court.'"]}},
		]},
	{"id": "nephew", "min": 5, "title": "The councillor's nephew",
		"text": "Councillor Duff's nephew was picked up for possession. She would like it to go away. She has not said so; she has asked how the department is fixed for money.",
		"choices": [
			{"label": "It goes away", "effects": {"ally": {"council": 8}, "later": {"weeks": 5, "text": "The Ledger has the Duff nephew story.", "effects": {"ally": {"da": -8}, "trust": -2, "headline": ["DUFF NEPHEW CASE 'LOST', SAYS LEDGER", "Duff: 'I never asked for anything.'"]}}}},
			{"label": "It goes to the DA", "effects": {"ally": {"council": -8, "da": 3}}},
		]},
	{"id": "training_accident", "min": 4, "title": "An accident at the range",
		"text": "{officer} was hurt in a live-fire drill. A ricochet. The range officer says the berm needs rebuilding.",
		"choices": [
			{"label": "Rebuild the berm", "effects": {"money": -3000, "officer": {"out": 2}}},
			{"label": "Move drills to the county range", "effects": {"money": -800, "officer": {"out": 2}, "morale": -2}},
		]},
	{"id": "memorial", "min": 8, "needs": "officer_killed", "title": "A memorial",
		"text": "The union wants a memorial wall in the station lobby for officers killed in the line of duty. The names this year are yours.",
		"choices": [
			{"label": "Build it", "effects": {"money": -3000, "morale": 6, "ally": {"union": 6}}},
			{"label": "A plaque, for now", "effects": {"money": -500, "morale": 2}},
		]},
	{"id": "protest_permit", "min": 10, "title": "A protest permit",
		"text": "Port Carrick Together wants to march from Eastport to City Hall. The permit office asks the department what it recommends.",
		"choices": [
			{"label": "Recommend the permit", "effects": {"trust": 2, "ally": {"coalition": 3}, "poll": {"okonjo": 0.5}}},
			{"label": "Recommend a shorter route", "effects": {"ally": {"council": 2, "coalition": -2}}},
			{"label": "Recommend against", "effects": {"ally": {"coalition": -8}, "poll": {"kettering": 1.0, "okonjo": 1.0}, "trust": -3}},
		]},
	{"id": "bodycam_vendor", "min": 3, "needs": "no_bodycams", "title": "A body camera salesman",
		"text": "A vendor offers body cameras for every officer, a year's storage included. Evidence for every case — the ones you want and the ones you do not.",
		"choices": [
			{"label": "Buy them ($6,000)", "cost": 6000, "effects": {"money": -6000, "bodycams": true, "ally": {"da": 4, "coalition": 3}}},
			{"label": "Not this year", "effects": {}},
		]},
	{"id": "hospital_escort", "min": 2, "title": "The hospital asks",
		"text": "St. Brendan's emergency department has had three assaults on nurses this month. The chief medical officer wants an officer posted overnight.",
		"choices": [
			{"label": "Post {officer} for a week", "effects": {"officer": {"commit": 1}, "trust": 2}},
			{"label": "Train their security instead", "effects": {"money": -1500, "trust": 1}},
			{"label": "No officers to spare", "effects": {"trust": -1}},
		]},
	{"id": "audit", "min": 12, "title": "A funding audit",
		"text": "The state comptroller is auditing the department's overtime. Every line since the handover.",
		"choices": [
			{"label": "Open the books", "effects": {"chance": {"p": 0.7, "text": "the audit", "win": {"ally": {"council": 3}}, "lose": {"money": -5000, "ally": {"council": -4}}}}},
			{"label": "Hire an outside accountant", "effects": {"money": -3000, "ally": {"council": 1}}},
		]},
	{"id": "resignation", "min": 6, "title": "A resignation letter",
		"text": "{officer} has put a letter on your desk. Burned out, they say. A private security firm is offering double.",
		"choices": [
			{"label": "Counter-offer ($2,500)", "cost": 2500, "effects": {"money": -2500, "officer": {"trauma": -2}}},
			{"label": "Two weeks of leave", "effects": {"officer": {"out": 2, "trauma": -4}}},
			{"label": "Accept the letter", "effects": {"officer": {"resign": true}, "morale": -2}},
		]},
	{"id": "tipline", "min": 3, "title": "The tip line floods",
		"text": "A reward poster has the tip line ringing day and night. Most of it is nothing. Some of it is not.",
		"choices": [
			{"label": "Staff it ($2,000)", "cost": 2000, "effects": {"money": -2000, "intel_weeks": 2}},
			{"label": "Let it go to voicemail", "effects": {"trust": -1}},
		]},
	{"id": "rookie_freeze", "min": 3, "title": "A rookie froze",
		"text": "At the range, {officer} froze in the shoot-house and did not fire at the threat target. Twice.",
		"choices": [
			{"label": "Extra range time ($1,200)", "cost": 1200, "effects": {"money": -1200, "officer": {"drill": 1}}},
			{"label": "Pair them with a veteran", "effects": {"officer": {"trauma": -1}}},
			{"label": "Note it and move on", "effects": {}},
		]},
]
const OFFER_P := 0.4
const EVENT_P := 0.55

## EA_TASKS P1.E2: reconciliation — a lost ally can be won back. At most one offer every
## RECONCILE_COOLDOWN weeks, one per ally per run, at a big price.
const RECONCILE_COST := 15000
const RECONCILE_STANDING := 20
const RECONCILE_COOLDOWN := 4

## EA_TASKS P1.D4: tier-3 training programs (tactical habits) join the program drafts from
## this week on, at a higher price.
const PROGRAM_TIER3_WEEK := 20
const PROGRAM_TIER3_MULT := 1.5
const PROGRAM_TIER3 := ["PF04", "ED03", "ED05", "WD02", "ED10"]

var rng := RandomNumberGenerator.new()
## The replacement stream (EA_TASKS P0.C2). Re-dealing a draft card after a stocking
## change draws from here and never from `rng`, so the rest of the desk — offers,
## events, future drafts — stays exactly where the seed put it. Saved with the run.
var draft_rng := RandomNumberGenerator.new()
var armory: Array = []        # stocked item ids
var contracts: Array = []     # signed contract ids, in order
var programs_done: Array = [] # finished program ids
var program := {}             # the running one: {id, name, weeks_left, ...} or {}
var drafts: Array = []        # open drafts: [{kind: procurement|program|doctrine, week, cards: [...]}]
var offers: Array = []        # this week's: [{...offer, week, who_name}]
var events: Array = []        # unanswered: [{...event, week, officer_id, officer_name}]
var later: Array = []         # delayed effects: [{due, text, effects}]
var intel_weeks := 0          # weeks left with a free tip on every new situation
var quiet_weeks := 0          # weeks left with no gang raids on the board
var desk_log: Array = []       # [{week, text}] what the desk decided
var seen: Dictionary = {}     # offer and event ids already dealt (each once per run)
var doctrine := ""
var unlocked: Array = []     # doctrine ids this run could draw from
var last_reconcile := -99    # EA_TASKS P1.E2: week of the last reconciliation offer
var reconciled := {}         # EA_TASKS P1.E2: ally ids offered reconciliation this run


## Two independent streams from one seed: the desk's (rng) and the replacement
## stream's (draft_rng). Multiplication constants are distinct so the two sequences
## never coincide.
func _seed_streams(seed_v: int) -> void:
	rng.seed = seed_v * 6151 + 29
	draft_rng.seed = seed_v * 9241 + 137


func start(seed_v: int, legacy: Dictionary = {}) -> void:
	_seed_streams(seed_v)
	armory = BASE_STOCK.duplicate()
	contracts = []
	programs_done = []
	program = {}
	drafts = []
	offers = []
	events = []
	later = []
	intel_weeks = 0
	quiet_weeks = 0
	desk_log = []
	seen = {}
	doctrine = ""
	unlocked = unlocked_doctrines(legacy)
	last_reconcile = -99
	reconciled = {}


# ================================================================== the armoury
func armory_set() -> Dictionary:
	var d := {}
	for it in armory:
		d[it] = true
	return d


func stock(items: Array) -> void:
	for it in items:
		if not armory.has(it):
			armory.append(it)
	Equipment.armory = armory_set()


func contract_tier_ok(cid: String, week: int) -> bool:
	var t: int = int(CONTRACTS[cid]["tier"])
	return t == 1 or (t == 2 and week >= 5) or (t == 3 and week >= 13)


## Every item the contract carries is already in the armoury, so signing it would
## charge the department and add nothing (EA_TASKS P0.C3). A contract with *some* new
## items is still worth buying: breaching rounds arrive with a shotgun the armoury may
## already hold.
func contract_stocked(cid: String) -> bool:
	if not CONTRACTS.has(cid):
		return false
	# a capital contract carries no kit: it is bought once and `contracts` is the record,
	# so it is never "already stocked" (which would keep it out of every draft for good)
	if Equipment.CAPITAL.has(cid):
		return false
	for it in CONTRACTS[cid]["items"]:
		if not armory.has(it):
			return false
	return true


## Contracts still worth offering: not signed, allowed at this week, carrying at least
## one item the armoury lacks (P0.C1).
func _open_contracts(week: int, tag := "") -> Array:
	var out: Array = []
	for cid in CONTRACTS:
		if contracts.has(cid) or not contract_tier_ok(cid, week):
			continue
		if tag != "" and CONTRACTS[cid]["tag"] != tag:
			continue
		if contract_stocked(cid):
			continue
		out.append(cid)
	return out


## A draft is dealt before the chief picks an inheritance or takes an offer, so a
## stocking change can make one of its cards redundant. Replace it from the same tier
## on the replacement stream, or drop the card if nothing is left to offer; drop the
## whole draft when it has no cards. Nothing is charged, nothing is refunded, and the
## main rng does not move, so a seed still deals the same desk either way (P0.C2).
func _revalidate_drafts() -> Array:
	var lines: Array = []
	var di := drafts.size() - 1
	while di >= 0:
		var d: Dictionary = drafts[di]
		if String(d.get("kind", "")) != "procurement":
			di -= 1
			continue
		var week: int = int(d.get("week", 1))
		var cards_v = d.get("cards", null)
		if not (cards_v is Array):
			di -= 1
			continue
		var cards: Array = cards_v
		var i := cards.size() - 1
		while i >= 0:
			var cid := String(cards[i])
			if CONTRACTS.has(cid) and (contracts.has(cid) or contract_stocked(cid)):
				var tier: int = int(CONTRACTS[cid]["tier"])
				var pool: Array = _open_contracts(week).filter(
					func(x): return int(CONTRACTS[x]["tier"]) == tier and not cards.has(x))
				var ln := ""
				if pool.is_empty():
					cards.remove_at(i)
					ln = "%s is already in the armoury; that card is gone from the draft." % CONTRACTS[cid]["name"]
				else:
					var alt: String = String(pool[draft_rng.randi() % pool.size()])
					cards[i] = alt
					ln = "%s is already in the armoury; the draft offers %s instead." % [CONTRACTS[cid]["name"], CONTRACTS[alt]["name"]]
				lines.append(ln)
				_log(week, "Procurement re-dealt: %s" % ln)
			i -= 1
		if cards.is_empty():
			drafts.remove_at(di)
		di -= 1
	return lines


# ================================================================== the week
## A new week on the desk: drafts by the calendar, perhaps an offer, perhaps an event.
func on_week_start(c) -> Array:
	var lines: Array = []
	var week: int = c.week()
	offers = []
	if week == 1 and doctrine == "":
		var pool: Array = unlocked.duplicate()
		var cards: Array = []
		while cards.size() < DRAFT_N and not pool.is_empty():
			cards.append(pool.pop_at(rng.randi() % pool.size()))
		drafts.append({"kind": "doctrine", "week": week, "cards": cards})
	if (week - 1) % CONTRACT_EVERY == 0:
		var pool2: Array = _open_contracts(week)
		var cards2: Array = []
		while cards2.size() < DRAFT_N and not pool2.is_empty():
			cards2.append(pool2.pop_at(rng.randi() % pool2.size()))
		if not cards2.is_empty():
			drafts.append({"kind": "procurement", "week": week, "cards": cards2})
	if week >= PROGRAM_FIRST and (week - PROGRAM_FIRST) % PROGRAM_EVERY == 0 and program.is_empty():
		var cards3: Array = _program_cards(c)
		if not cards3.is_empty():
			drafts.append({"kind": "program", "week": week, "cards": cards3})
	if week >= 2 and rng.randf() < OFFER_P:
		var o: Dictionary = _deal_offer(c)
		if not o.is_empty():
			offers.append(o)
	if week >= 2 and rng.randf() < EVENT_P:
		var e: Dictionary = _deal_event(c)
		if not e.is_empty():
			events.append(e)
	lines.append_array(_maybe_reconcile(c))
	if not drafts.is_empty() or not offers.is_empty() or not events.is_empty():
		lines.append("On your desk: %s." % desk_summary())
	return lines


## EA_TASKS P1.E2: a lost ally gets a reconciliation offer — at most one every
## RECONCILE_COOLDOWN weeks, and one per ally per run. Accepting restores the standing
## past the regain threshold (the "reconcile" effect in apply()).
func _maybe_reconcile(c) -> Array:
	var lines: Array = []
	var week: int = c.week()
	if week - last_reconcile < RECONCILE_COOLDOWN:
		return lines
	for a in Politics.ALLY_ORDER:
		if not c.politics.lost(a) or reconciled.has(a):
			continue
		reconciled[a] = true
		last_reconcile = week
		var o := {"id": "reconcile_%s" % a, "who": a, "week": week, "who_name": _who_name(a),
			"text": "%s will take the department back — on paper, at least: $%s in costs, meetings and apologies, and the standing is restored." % [
				Politics.ALLIES[a]["name"], _money(RECONCILE_COST)],
			"accept": {"money": -RECONCILE_COST, "reconcile": a,
				"headline": ["%s RECONCILES WITH THE DEPARTMENT" % String(Politics.ALLIES[a]["name"]).to_upper(),
					"The chief paid for the seat at the table. The table is small."]},
			"decline": {"ally": {a: -2}}}
		seen[o["id"]] = true
		offers.append(o)
		lines.append("On your desk: a reconciliation offer from %s." % o["who_name"])
		_log(week, "Reconciliation offered to %s." % a)
		break   # at most one every RECONCILE_COOLDOWN weeks
	return lines


## The week ends: programs advance, offers lapse, delayed consequences land.
func on_week_end(c) -> Array:
	var lines: Array = []
	var week: int = c.week()
	for o in offers:
		_log(week, "Let %s's offer lapse." % o["who_name"])
	offers = []
	if not program.is_empty():
		program["weeks_left"] = int(program["weeks_left"]) - 1
		if int(program["weeks_left"]) <= 0:
			lines.append_array(_finish_program(c))
	var keep: Array = []
	for l in later:
		if int(l["due"]) <= week:
			lines.append(String(l["text"]))
			lines.append_array(apply(c, l["effects"], {}))
		else:
			keep.append(l)
	later = keep
	intel_weeks = maxi(0, intel_weeks - 1)
	quiet_weeks = maxi(0, quiet_weeks - 1)
	return lines


## A new board has been dealt: what the run layer does to it.
func on_board(c) -> void:
	if quiet_weeks > 0:
		for s in c.board:
			if s["type"] == "gang" and s["status"] == "open":
				s["status"] = "unattended"
				s["result"] = {"label": "Truce", "score": 0, "goal": "the crews are keeping the truce"}
				s["truce"] = true
	if intel_weeks > 0:
		for s2 in c.board:
			if s2["status"] == "open":
				Situations.tip(s2, rng, "task force")


## Things that must be settled before the week can end (drafts and events; offers lapse).
func blocking() -> Array:
	var out: Array = []
	for d in drafts:
		out.append({"doctrine": "the inheritance draft", "procurement": "a procurement draft", "program": "a training program draft"}.get(d["kind"], "a draft"))
	for e in events:
		out.append(String(e["title"]).to_lower())
	return out


func desk_summary() -> String:
	var parts: Array = []
	for d in drafts:
		parts.append({"doctrine": "the inheritance", "procurement": "procurement", "program": "a training program"}.get(d["kind"], "a draft"))
	for o in offers:
		parts.append("an offer from %s" % o["who_name"])
	for e in events:
		parts.append(String(e["title"]).to_lower())
	return ", ".join(parts)


# ================================================================== drafts
func card_info(kind: String, cid: String, c) -> Dictionary:
	match kind:
		"doctrine":
			return {"name": DOCTRINES[cid]["name"], "desc": DOCTRINES[cid]["desc"], "cost": 0, "tag": ""}
		"procurement":
			var ct: Dictionary = CONTRACTS[cid]
			var names: Array = []
			for it in ct["items"]:
				names.append(item_name(it))
			return {"name": ct["name"], "desc": "%s Adds: %s." % [ct["desc"], ", ".join(names)], "cost": int(ct["cost"]), "tag": ct["tag"]}
		"program":
			return program_info(cid, c)
	return {}


func program_info(pid: String, c) -> Dictionary:
	var n: int = _force(c).size()
	var cost: int = PROGRAM_BASE + PROGRAM_PER * n
	if SPECIAL_PROGRAMS.has(pid):
		var sp: Dictionary = SPECIAL_PROGRAMS[pid]
		return {"name": sp["name"], "desc": sp["desc"], "cost": cost, "weeks": int(sp["weeks"]), "tag": sp["tag"]}
	var h: Dictionary = _habit(pid)
	var lacking: int = _force(c).filter(func(r): return not (r["good"] as Array).has(pid)).size()
	var tier3: bool = PROGRAM_TIER3.has(pid) and c.week() >= PROGRAM_TIER3_WEEK
	if tier3:
		cost = int(round(cost * PROGRAM_TIER3_MULT))   # P1.D4: repriced tier-3 program
	return {"name": "%s (%s)" % [h.get("name", pid), pid], "desc": "%s %d of %d officers lack it. Without it: %s" % [
		h.get("with", ""), lacking, n, h.get("without", "")], "cost": cost, "weeks": 2 + (1 if String(pid).begins_with("HD") else 0) + (hash(pid) % 2),
		"tag": "restraint" if pid in ["ED04", "WD09", "WD10", "GD03"] else ("military" if tier3 else "neutral"), "group": h.get("group", "")}


static func _habit(pid: String) -> Dictionary:
	for g in Habits.GOOD:
		if g["id"] == pid:
			return g
	return {}


static func item_name(it: String) -> String:
	if Equipment.WEAPONS.has(it):
		return String(Equipment.WEAPONS[it]["name"])
	if Equipment.GEAR.has(it):
		return String(Equipment.GEAR[it]["name"])
	if Equipment.OPTICS.has(it):
		return String(Equipment.OPTICS[it]["name"])
	if Equipment.ARMOUR.has(it):
		return String(Equipment.ARMOUR[it]["name"])
	if Equipment.HEAD.has(it):
		return String(Equipment.HEAD[it]["name"])
	if Equipment.CAPITAL.has(it):
		return String(Equipment.CAPITAL[it]["name"])
	return it


func _force(c) -> Array:
	return c.dept.officers.filter(func(r): return String(r.get("status", "")) not in ["dead", "fired", "resigned"])


func _program_cards(c) -> Array:
	var academy: Array = Habits.preset_good("patrol")
	var weights := {}
	for g in Habits.GOOD:
		var id: String = g["id"]
		if academy.has(id) or programs_done.has(id):
			continue
		if id.begins_with("HD") and not ["HD03", "HD08", "HD13", "HD17", "HD19"].has(id):
			continue
		weights[id] = 1.0
	# what the record says the department lacks
	var counts := {}
	for r in c.dept.cases:
		counts[r.get("kind", "")] = int(counts.get(r.get("kind", ""), 0)) + 1
	for kind in FINDING_HABITS:
		for hid in FINDING_HABITS[kind]:
			if weights.has(hid):
				weights[hid] = float(weights[hid]) + 1.5 * float(counts.get(kind, 0)) + 0.5
	for sp in SPECIAL_PROGRAMS:
		if not programs_done.has(sp):
			weights[sp] = 1.6
	# EA_TASKS P1.D4: from PROGRAM_TIER3_WEEK on, the repriced tier-3 habits are on the menu.
	if c.week() >= PROGRAM_TIER3_WEEK:
		for t3 in PROGRAM_TIER3:
			if not programs_done.has(t3) and not academy.has(t3):
				weights[t3] = 1.2
	var cards: Array = []
	for k in DRAFT_N:
		var tot := 0.0
		for id2 in weights:
			tot += float(weights[id2])
		if tot <= 0.0:
			break
		var x := rng.randf() * tot
		for id3 in weights.keys():
			x -= float(weights[id3])
			if x <= 0.0:
				cards.append(id3)
				weights.erase(id3)
				break
	return cards


## Pick a card from an open draft (or pass with cid ""). Returns readable lines.
func pick(c, di: int, cid: String) -> Array:
	if di < 0 or di >= drafts.size():
		return []
	var d: Dictionary = drafts[di]
	var week: int = c.week()
	var lines: Array = []
	if cid != "" and not (d["cards"] as Array).has(cid):
		return []
	match d["kind"]:
		"doctrine":
			if cid == "":
				cid = String(d["cards"][0])
			lines.append_array(_doctrine(c, cid))
		"procurement":
			if cid == "":
				c.dept.income("Surplus sold (procurement passed)", PASS_REFUND)
				lines.append("No contract this round. Surplus sold: $%s." % c.dept.money(PASS_REFUND))
				_log(week, "Passed on procurement.")
			else:
				var ct: Dictionary = CONTRACTS[cid]
				if contract_stocked(cid):
					_log(week, "Declined a redundant contract: %s (already stocked)." % ct["name"])
					return ["%s is already in the armoury. No contract is needed, and nothing is charged." % ct["name"]]
				# P1.D2: the council's overdraft carries a purchase, but not past its limit.
				if c.dept.balance - int(ct["cost"]) < c.dept.OVERDRAFT_LIMIT:
					return ["The account cannot cover the %s contract ($%s): past that, the overdraft limit (-$%s) holds." % [
						ct["name"].to_lower(), c.dept.money(int(ct["cost"])), c.dept.money(-c.dept.OVERDRAFT_LIMIT)]]
				c.dept.spend("Contract: %s" % ct["name"], int(ct["cost"]))
				lines.append_array(_sign(c, cid, true))
		"program":
			if cid == "":
				lines.append("No program this round.")
				_log(week, "Passed on a training program.")
			else:
				var info: Dictionary = program_info(cid, c)
				if c.dept.balance - int(info["cost"]) < c.dept.OVERDRAFT_LIMIT:
					return ["The account cannot cover %s ($%s): past that, the overdraft limit (-$%s) holds." % [
						info["name"], c.dept.money(int(info["cost"])), c.dept.money(-c.dept.OVERDRAFT_LIMIT)]]
				c.dept.spend("Program: %s" % info["name"], int(info["cost"]))
				program = {"id": cid, "name": info["name"], "weeks_left": int(info["weeks"]), "started": week}
				lines.append("%s begins: %d weeks of in-service training for the whole force." % [info["name"], int(info["weeks"])])
				_log(week, "Started %s." % info["name"])
				_tag(c, String(info.get("tag", "")), lines)
	drafts.remove_at(di)
	# The pick may have stocked the armoury (a plate-carrier inheritance, a signed
	# contract): any card it made redundant is re-dealt now, after this draft is gone.
	lines.append_array(_revalidate_drafts())
	c.dept.note("Desk: %s" % " ".join(lines))
	return lines


## A contract enters the armoury (bought, or given by an offer).
func _sign(c, cid: String, bought: bool) -> Array:
	var ct: Dictionary = CONTRACTS[cid]
	var lines: Array = []
	contracts.append(cid)
	stock(ct["items"])
	if Equipment.CAPITAL.has(cid):
		c.dept.capital[cid] = true
		if cid == "arv":
			lines.append("The armoured rescue vehicle is in service: on a gang raid it carries the first officer downed out alive.")
	var delivered := ", ".join(ct["items"].map(func(i): return item_name(i)))
	if delivered == "":
		lines.append("%s %s." % [ct["name"], "contract signed" if bought else "arrives"])
	else:
		lines.append("%s %s: %s in the armoury." % [ct["name"], "contract signed" if bought else "arrive", delivered])
	_log(c.week(), "Armoury: %s." % ct["name"])
	_tag(c, String(ct["tag"]), lines)
	return lines


func _tag(c, tag: String, lines: Array) -> void:
	var pol = c.politics
	match tag:
		"military":
			pol._poll("kettering", 0.8)
			pol._ally("coalition", -3, c.dept, lines)
			pol._headline(c.week(), "CARRICK PD ARMS UP", "Mbeki-Shaw: 'Every new weapon is a promise about how it will be used.' Carrick calls it 'overdue'.", "politics")
		"restraint":
			pol._ally("coalition", 2, c.dept, lines)
			pol._poll("pell", 0.3)


func _finish_program(c) -> Array:
	var lines: Array = []
	var pid: String = program["id"]
	var n := 0
	var force: Array = _force(c)
	match pid:
		"crisis":
			for r in force:
				r["judgment"] = mini(90, int(r["judgment"]) + 4)
				n += 1
		"peer":
			for r2 in force:
				r2["trauma"] = maxf(0.0, float(r2["trauma"]) - 3.0)
				n += 1
			c.dept.shift_morale(4)
		"inservice":
			for r3 in force:
				if int(r3.get("drill", 0)) < 4:
					r3["drill"] = int(r3.get("drill", 0)) + 1
					r3["ech"] = _drilled(r3["ech"])
					n += 1
		_:
			for r4 in force:
				if not (r4["good"] as Array).has(pid):
					r4["good"].append(pid)
					r4["good"].sort()
					r4["file"].append({"week": c.week(), "text": "Learned %s in a department program." % _habit(pid).get("name", pid)})
					n += 1
			if not c.dept.curriculum.has(pid):
				c.dept.curriculum.append(pid)
	programs_done.append(pid)
	lines.append("%s complete: %d officer%s trained.%s" % [program["name"], n, "" if n == 1 else "s",
		" The academy teaches it to every hire from now on." if not SPECIAL_PROGRAMS.has(pid) else ""])
	_log(c.week(), "Finished %s (%d trained)." % [program["name"], n])
	program = {}
	return lines


## A firearms qualification's worth of improvement (as the course gives).
static func _drilled(ech: Dictionary) -> Dictionary:
	var e := ech.duplicate(true)
	for k in ["recog", "aim_a", "aim_b", "reload"]:
		if e.has(k) and (e[k] is float or e[k] is int):
			e[k] = float(e[k]) * 0.97
	return e


func abandon_program(c) -> Array:
	if program.is_empty():
		return []
	var ln := "%s abandoned with %d week%s to go. The money is spent." % [program["name"], int(program["weeks_left"]), "" if int(program["weeks_left"]) == 1 else "s"]
	_log(c.week(), ln)
	program = {}
	return [ln]


func _doctrine(c, did: String) -> Array:
	doctrine = did
	var lines: Array = ["Inheritance: %s." % DOCTRINES[did]["name"]]
	var pol = c.politics
	match did:
		"reserve":
			c.dept.income("The outgoing chief's reserve", 10000)
		"plates":
			contracts.append("plates")
			stock(["plates"])
		"pie", "lines":
			var hid := "PF03" if did == "pie" else "GD03"
			for r in _force(c):
				if not (r["good"] as Array).has(hid):
					r["good"].append(hid)
					r["good"].sort()
			if not c.dept.curriculum.has(hid):
				c.dept.curriculum.append(hid)
		"liaison":
			pol._ally("coalition", 10, c.dept, lines)
			for i in pol.trust.size():
				pol._trust(i, 4)
		"union":
			pol._ally("union", 15, c.dept, lines)
		"cams":
			c.dept.bodycams = true
		"tactical":
			var cand: Array = _force(c).filter(func(r): return not r.get("tactical", false) and Equipment.who_of_record(r) != "tactical")
			cand.sort_custom(func(a, b): return float(a.get("years", 0.0)) > float(b.get("years", 0.0)))
			for r2 in cand.slice(0, 3):
				r2["tactical"] = true
				r2["file"].append({"week": c.week(), "text": "Tactically certified (the cadre you inherited)."})
	_log(c.week(), lines[0])
	return lines


# ================================================================== offers and events
func _who_name(who: String) -> String:
	if Politics.ALLIES.has(who):
		return "%s (%s)" % [Politics.ALLIES[who]["name"], Politics.ALLIES[who]["title"]]
	if Politics.CANDIDATES.has(who):
		return "%s (%s)" % [Politics.CANDIDATES[who]["name"], Politics.CANDIDATES[who]["ticket"]]
	if PEOPLE.has(who):
		return "%s (%s)" % [PEOPLE[who]["name"], PEOPLE[who]["title"]]
	return who


func _needs_ok(c, need: String) -> bool:
	match need:
		"":
			return true
		"pending_story":
			return c.politics.pending.any(func(p): return p is Dictionary and p.get("kind", "") == "story")
		"low_morale":
			return int(c.dept.morale) < 55
		"officer_killed":
			return int(c.politics.record.get("officers_killed", 0)) > 0
		"no_bodycams":
			return not c.dept.bodycams
	return true


func _deal_offer(c) -> Dictionary:
	var pool: Array = []
	for o0 in OFFERS:
		if seen.has(o0["id"]) or c.week() < int(o0.get("min", 1)) or not _needs_ok(c, String(o0.get("needs", ""))):
			continue
		if Politics.ALLIES.has(o0["who"]) and c.politics.lost(o0["who"]):
			continue
		pool.append(o0)
	if pool.is_empty():
		return {}
	var o: Dictionary = (pool[rng.randi() % pool.size()] as Dictionary).duplicate(true)
	seen[o["id"]] = true
	o["week"] = c.week()
	o["who_name"] = _who_name(o["who"])
	return o


func _deal_event(c) -> Dictionary:
	var pool: Array = []
	for e0 in EVENTS:
		if seen.has(e0["id"]) or c.week() < int(e0.get("min", 1)) or not _needs_ok(c, String(e0.get("needs", ""))):
			continue
		pool.append(e0)
	if pool.is_empty():
		return {}
	var e: Dictionary = (pool[rng.randi() % pool.size()] as Dictionary).duplicate(true)
	seen[e["id"]] = true
	e["week"] = c.week()
	var cand: Array = c.dept.available()
	if cand.is_empty():
		cand = _force(c)
	if not cand.is_empty():
		var r: Dictionary = cand[rng.randi() % cand.size()]
		e["officer_id"] = r["id"]
		e["officer_name"] = "%s %s" % [r["rank"], r["name"]]
	else:
		e["officer_id"] = ""
		e["officer_name"] = "an officer"
	return e


static func fill(text: String, e: Dictionary) -> String:
	return text.replace("{officer}", String(e.get("officer_name", "an officer")))


func choice_blocked(c, ch: Dictionary) -> String:
	var cost: int = int(ch.get("cost", 0))
	if cost > 0 and int(c.dept.balance) < cost:
		return "the account is short ($%s needed)" % c.dept.money(cost)
	return ""


func answer_event(c, ei: int, k: int) -> Array:
	if ei < 0 or ei >= events.size():
		return []
	var e: Dictionary = events[ei]
	var chs: Array = e["choices"]
	if k < 0 or k >= chs.size():
		return []
	var ch: Dictionary = chs[k]
	var why := choice_blocked(c, ch)
	if why != "":
		return ["Not possible: %s." % why]
	events.remove_at(ei)
	var lines: Array = ["%s: %s." % [e["title"], fill(String(ch["label"]), e)]]
	lines.append_array(apply(c, ch["effects"], e))
	_log(c.week(), lines[0])
	c.dept.note("Desk: %s" % " ".join(lines))
	return lines


func answer_offer(c, oi: int, accept: bool) -> Array:
	if oi < 0 or oi >= offers.size():
		return []
	var o: Dictionary = offers[oi]
	offers.remove_at(oi)
	var lines: Array = ["%s %s's offer." % ["Accepted" if accept else "Declined", o["who_name"]]]
	var eff: Dictionary = o["accept"] if accept else o.get("decline", {})
	# P1.E2 / P1.D2: an offer may be paid into the council's overdraft, but not past its limit.
	if accept and int(eff.get("money", 0)) < 0 and int(c.dept.balance) + int(eff["money"]) < c.dept.OVERDRAFT_LIMIT:
		offers.insert(oi, o)
		return ["The account cannot cover it ($%s): past that, the overdraft limit (-$%s) holds." % [
			c.dept.money(-int(eff["money"])), c.dept.money(-c.dept.OVERDRAFT_LIMIT)]]
	lines.append_array(apply(c, eff, o))
	_log(c.week(), lines[0])
	c.dept.note("Desk: %s" % " ".join(lines))
	return lines


## A plain-words summary of what an effects block will do (shown on the choice). What
## comes later stays a line about the future, not a number.
func describe(eff: Dictionary) -> String:
	var parts: Array = []
	var m: int = int(eff.get("money", 0))
	if m != 0:
		parts.append("%s$%s" % ["+" if m > 0 else "-", _money(absi(m))])
	for a in eff.get("ally", {}):
		parts.append("%s %+d" % [Politics.ALLIES[a]["name"], int(eff["ally"][a])])
	for p in eff.get("poll", {}):
		parts.append("%s %+.1f" % [Politics.CANDIDATES[p]["name"], float(eff["poll"][p])])
	if int(eff.get("trust", 0)) != 0:
		parts.append("trust %+d in every ward" % int(eff["trust"]))
	if eff.has("trust_ward"):
		parts.append("trust %+d in %s" % [int(eff["trust_ward"][1]), Situations.WARDS[int(eff["trust_ward"][0])]["name"]])
	if int(eff.get("morale", 0)) != 0:
		parts.append("morale %+d" % int(eff["morale"]))
	if eff.has("contract"):
		var cc: String = String(eff["contract"])
		parts.append("a military contract, free" if cc == "military" else "%s, free" % CONTRACTS.get(cc, {}).get("name", cc))
	if int(eff.get("intel_weeks", 0)) > 0:
		parts.append("a free tip on every file for %d weeks" % int(eff["intel_weeks"]))
	if int(eff.get("quiet_weeks", 0)) > 0:
		parts.append("no gang raids for %d weeks" % int(eff["quiet_weeks"]))
	if int(eff.get("delay_stories", 0)) > 0:
		parts.append("pending stories held %d weeks" % int(eff["delay_stories"]))
	if int(eff.get("recruits", 0)) > 0:
		parts.append("%d free academy places" % int(eff["recruits"]))
	if eff.get("bodycams", false):
		parts.append("body cameras for everyone")
	var of: Dictionary = eff.get("officer", {})
	if not of.is_empty():
		var bits: Array = []
		if of.get("fire", false):
			bits.append("dismissed")
		if of.get("resign", false):
			bits.append("leaves the force")
		if int(of.get("suspend", 0)) > 0:
			bits.append("suspended %d weeks" % int(of["suspend"]))
		if int(of.get("commit", 0)) > 0 or int(of.get("out", 0)) > 0:
			bits.append("off the board %d week%s" % [maxi(int(of.get("commit", 0)), int(of.get("out", 0))), "" if maxi(int(of.get("commit", 0)), int(of.get("out", 0))) == 1 else "s"])
		if int(of.get("judgment", 0)) != 0:
			bits.append("judgment %+d" % int(of["judgment"]))
		if float(of.get("trauma", 0)) != 0.0:
			bits.append("trauma %+d" % int(of["trauma"]))
		if int(of.get("drill", 0)) > 0:
			bits.append("a firearms qualification")
		if not bits.is_empty():
			parts.append("the officer: " + ", ".join(bits))
	if eff.has("chance"):
		parts.append("a gamble on %s (about %d in 10)" % [eff["chance"].get("text", "it"), int(round(float(eff["chance"]["p"]) * 10.0))])
	if eff.has("later"):
		parts.append("something will come of this")
	if eff.has("headline"):
		parts.append("the Ledger runs it")
	return ", ".join(parts) if not parts.is_empty() else "nothing, for now"


static func _money(n: int) -> String:
	var s := str(n)
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out


## Carry out an effects block. ctx is the offer or event (for its named officer).
func apply(c, eff: Dictionary, ctx: Dictionary) -> Array:
	var lines: Array = []
	var d = c.dept
	var pol = c.politics
	var week: int = c.week()
	var m: int = int(eff.get("money", 0))
	if m > 0:
		d.income("Desk: %s" % ctx.get("title", ctx.get("who_name", "the city")), m)
	elif m < 0:
		d.spend("Desk: %s" % ctx.get("title", ctx.get("who_name", "the city")), -m)
	for a in eff.get("ally", {}):
		pol._ally(a, int(eff["ally"][a]), d, lines)
	for p in eff.get("poll", {}):
		pol._poll(p, float(eff["poll"][p]))
	if int(eff.get("trust", 0)) != 0:
		for i in pol.trust.size():
			pol._trust(i, int(eff["trust"]))
	if eff.has("trust_ward"):
		pol._trust(int(eff["trust_ward"][0]), int(eff["trust_ward"][1]))
	if int(eff.get("morale", 0)) != 0:
		d.shift_morale(int(eff["morale"]))
	if eff.has("contract"):
		var cid: String = String(eff["contract"])
		if cid == "military":
			var mil: Array = _open_contracts(maxi(week, 13), "military")
			cid = String(mil[rng.randi() % mil.size()]) if not mil.is_empty() else ""
		if cid != "" and CONTRACTS.has(cid) and not contracts.has(cid):
			lines.append_array(_sign(c, cid, false))
		# A free contract mid-week stocks the armoury the same way a signed one does.
		lines.append_array(_revalidate_drafts())
	intel_weeks += int(eff.get("intel_weeks", 0))
	quiet_weeks += int(eff.get("quiet_weeks", 0))
	if int(eff.get("delay_stories", 0)) > 0:
		for pnd in pol.pending:
			if pnd is Dictionary and pnd.get("kind", "") == "story":
				pnd["due"] = int(pnd.get("due", week)) + int(eff["delay_stories"])
	for k in int(eff.get("recruits", 0)):
		var r: Dictionary = d.hire("Officer", 0)
		r["status"] = "academy"
		r["out_until"] = week + Courses.RECRUIT_WEEKS
		r["issued"] = Equipment.cost(r["kit"])
		r["file"].append({"week": week, "text": "Academy place paid by a federal grant (Councillor Diaz)."})
		lines.append("%s joins the academy (a grant place)." % r["name"])
	if eff.get("bodycams", false):
		d.bodycams = true
	if eff.get("range", false) and not d.has_range:
		d.has_range = true
		lines.append("The department now has its own training range: courses cost a quarter less and finish a week sooner.")
		_log(week, "Training range built.")
	if int(eff.get("morale_floor", 0)) > 0:
		d.morale_home = mini(100, int(d.morale_home) + int(eff["morale_floor"]))
		lines.append("The union contract raises the morale floor to %d for good." % int(d.morale_home))
		_log(week, "Union contract: morale floor %d." % int(d.morale_home))
	if eff.has("reconcile"):
		var ra: String = String(eff["reconcile"])
		# enough to cross the regain line even from the floor, plus the agreed standing
		var need: int = maxi(Politics.REGAINED + 5 - pol.standing(ra), 0)
		pol._ally(ra, maxi(RECONCILE_STANDING, need), d, lines, "a reconciliation accepted ($%s)" % _money(RECONCILE_COST))
		if not pol.lost(ra):
			lines.append("%s is back: the standing is %d, past the line." % [Politics.ALLIES[ra]["name"], pol.standing(ra)])
	if eff.has("officer"):
		lines.append_array(_officer_effect(c, eff["officer"], ctx))
	if eff.has("headline"):
		pol._headline(week, String(eff["headline"][0]), String(eff["headline"][1]), "politics")
	if eff.has("later"):
		var lt: Dictionary = eff["later"]
		later.append({"due": week + int(lt.get("weeks", 2)), "text": String(lt.get("text", "")), "effects": lt.get("effects", {})})
	if eff.has("chance"):
		var ch: Dictionary = eff["chance"]
		var won := rng.randf() < float(ch.get("p", 0.5))
		lines.append("%s: %s." % [String(ch.get("text", "it")).capitalize(), "it goes your way" if won else "it does not"])
		lines.append_array(apply(c, ch.get("win", {}) if won else ch.get("lose", {}), ctx))
	return lines


func _officer_effect(c, of: Dictionary, ctx: Dictionary) -> Array:
	var lines: Array = []
	var d = c.dept
	var week: int = c.week()
	var r: Dictionary = {}
	if of.get("pick", "") == "best":
		var av: Array = d.available()
		av.sort_custom(func(a, b): return int(a["xp"]) > int(b["xp"]))
		if not av.is_empty():
			r = av[0]
	else:
		r = d.get_officer(String(ctx.get("officer_id", "")))
	if r.is_empty() or String(r.get("status", "")) in ["dead", "fired", "resigned"]:
		return lines
	var nm: String = "%s %s" % [r["rank"], r["name"]]
	if of.get("fire", false):
		d.fire(r, "dismissed from the desk")
		lines.append("%s is dismissed." % nm)
		return lines
	if of.get("resign", false):
		r["status"] = "resigned"
		r["file"].append({"week": week, "text": "Resigned (accepted)."})
		lines.append("%s leaves the force." % nm)
		return lines
	if int(of.get("judgment", 0)) != 0:
		r["judgment"] = clampi(int(r["judgment"]) + int(of["judgment"]), 10, 90)
	if float(of.get("trauma", 0)) != 0.0:
		r["trauma"] = maxf(0.0, float(r["trauma"]) + float(of["trauma"]))
	if int(of.get("drill", 0)) > 0 and int(r.get("drill", 0)) < 4:
		r["drill"] = int(r.get("drill", 0)) + 1
		r["ech"] = _drilled(r["ech"])
	var away: int = maxi(int(of.get("commit", 0)), int(of.get("out", 0)))
	if int(of.get("suspend", 0)) > 0 and r["status"] == "active":
		r["status"] = "suspended"
		r["out_until"] = week + int(of["suspend"])
		lines.append("%s is suspended until week %d." % [nm, int(r["out_until"])])
	elif away > 0 and r["status"] == "active":
		r["status"] = "training"
		r["out_until"] = week + away
		lines.append("%s is off the board until week %d." % [nm, int(r["out_until"])])
	if of.has("morale_file"):
		r["file"].append({"week": week, "text": String(of["morale_file"])})
	return lines


func _log(week: int, text: String) -> void:
	desk_log.append({"week": week, "text": text})
	if desk_log.size() > 300:
		desk_log = desk_log.slice(desk_log.size() - 300)


# ================================================================== headless play
## Answer everything on the desk at random (the harnesses; a chief who reads nothing).
func auto_resolve(c) -> Array:
	var lines: Array = []
	var guard := 0
	while not drafts.is_empty() and guard < 10:
		guard += 1
		var cards: Array = drafts[0]["cards"]
		var choice: String = ""
		if drafts[0]["kind"] == "doctrine" or rng.randf() < 0.8:
			choice = String(cards[rng.randi() % cards.size()]) if not cards.is_empty() else ""
		var out: Array = pick(c, 0, choice)
		if not drafts.is_empty() and drafts[0]["cards"] == cards:
			out = pick(c, 0, "")   # could not afford it: pass
		lines.append_array(out)
	while not offers.is_empty():
		lines.append_array(answer_offer(c, 0, rng.randf() < 0.5))
	guard = 0
	while not events.is_empty() and guard < 10:
		guard += 1
		var chs: Array = events[0]["choices"]
		var ok: Array = []
		for k in chs.size():
			if choice_blocked(c, chs[k]) == "":
				ok.append(k)
		lines.append_array(answer_event(c, 0, int(ok[rng.randi() % ok.size()]) if not ok.is_empty() else chs.size() - 1))
	return lines


# ================================================================== the score and the legacy
## One number for the run: what the city's record says, plus the election.
static func run_score(c) -> Dictionary:
	var rec: Dictionary = c.politics.record
	var parts := {
		"successes": 10 * int(rec.get("successes", 0)),
		"arrests": 3 * int(rec.get("arrests", 0)),
		"failures": -8 * int(rec.get("failures", 0)),
		"officers killed": -25 * int(rec.get("officers_killed", 0)),
		"civilians killed": -40 * int(rec.get("civ_killed", 0)) - 30 * int(rec.get("crowd_killed", 0)),
		"civilians hit": -12 * int(rec.get("civ_hit", 0)),
		"suspects killed": -6 * int(rec.get("suspects_killed", 0)),
		"excessive force": -10 * int(rec.get("excessive", 0)),
		"unattended": -3 * int(rec.get("unattended", 0)),
	}
	var res: Dictionary = c.politics.result
	var kept: bool = bool((res.get("ending", {}) as Dictionary).get("keep", false)) if res.get("ending", {}) is Dictionary else false
	# EA_TASKS P1.F2: Carrick's victory pays +60 only when the record is clean — few
	# officers killed and few force findings against the department; a violent record
	# still wins the seat, but for +20.
	var officers_killed: int = int(rec.get("officers_killed", 0))
	var civ_killed: int = int(rec.get("civ_killed", 0)) + int(rec.get("crowd_killed", 0))
	var findings: int = int(rec.get("excessive", 0)) + int(rec.get("civ_hit", 0)) + int(rec.get("unattended", 0))
	var clean := officers_killed <= 2 and civ_killed <= 6 and findings <= 6
	parts["the election"] = (60 if clean else 20) if kept else 0
	var total := 0
	for k in parts:
		total += int(parts[k])
	# EA_TASKS P1.F3: the arithmetic travels with the number, so election night can show
	# why the score is what it is rather than a single grey line of plus and minus.
	return {"total": total, "parts": parts, "kept": kept, "clean": clean,
		"clean_line": {"officers_killed": officers_killed, "civilians_killed": civ_killed, "findings": findings,
			"needs": {"officers_killed": 2, "civilians_killed": 6, "findings": 6}}}


static func load_legacy(path := LEGACY_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"runs": []}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"runs": []}
	var d = JSON.parse_string(f.get_as_text())
	f.close()
	if not (d is Dictionary) or not (d.get("runs", []) is Array):
		return {"runs": []}
	return d


static func save_legacy(d: Dictionary, path := LEGACY_PATH) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(d, "\t"))
		f.close()


static func unlocked_doctrines(legacy: Dictionary) -> Array:
	var runs: Array = legacy.get("runs", []) if legacy.get("runs", []) is Array else []
	var n: int = DOCTRINE_BASE
	for r in runs:
		if r is Dictionary:
			n += 2 if bool(r.get("kept", false)) else 1
	return DOCTRINE_ORDER.slice(0, mini(n, DOCTRINE_ORDER.size()))


## Write a finished run into the legacy file (once). Returns the doctrines it unlocked.
func record_run(c, path := LEGACY_PATH) -> Array:
	if seen.has("_recorded"):
		return []
	seen["_recorded"] = true
	var lg: Dictionary = load_legacy(path)
	var before: Array = unlocked_doctrines(lg)
	var sc: Dictionary = run_score(c)
	(lg["runs"] as Array).append({"seed": c.seed_val, "weeks": c.week(), "score": int(sc["total"]), "kept": bool(sc["kept"]),
		"winner": String(c.politics.result.get("winner", "")), "doctrine": doctrine, "contracts": contracts.duplicate(),
		"programs": programs_done.duplicate()})
	save_legacy(lg, path)
	var after: Array = unlocked_doctrines(lg)
	return after.filter(func(x): return not before.has(x))


# ================================================================== saving
func to_data() -> Dictionary:
	return {"version": VERSION, "rng_state": str(rng.state), "draft_rng_state": str(draft_rng.state),
		"armory": armory.duplicate(), "contracts": contracts.duplicate(),
		"programs_done": programs_done.duplicate(), "program": program.duplicate(true), "drafts": drafts.duplicate(true),
		"offers": offers.duplicate(true), "events": events.duplicate(true), "later": later.duplicate(true),
		"intel_weeks": intel_weeks, "quiet_weeks": quiet_weeks, "log": desk_log.duplicate(true), "seen": seen.duplicate(true),
		"doctrine": doctrine, "unlocked": unlocked.duplicate(),
		"last_reconcile": last_reconcile, "reconciled": reconciled.duplicate()}


func from_data(d: Dictionary, seed_v: int) -> void:
	_seed_streams(seed_v)
	rng.state = String(d.get("rng_state", "0")).to_int()
	# A save written before P0.C2 has no replacement state: the stream restarts from
	# its seed, which only affects which alternative card a stale draft is re-dealt.
	if d.has("draft_rng_state"):
		draft_rng.state = String(d["draft_rng_state"]).to_int()
	armory = _arr(d, "armory", BASE_STOCK)
	contracts = _arr(d, "contracts", [])
	programs_done = _arr(d, "programs_done", [])
	program = d.get("program", {}) if d.get("program", {}) is Dictionary else {}
	if not program.is_empty():
		program["weeks_left"] = int(program.get("weeks_left", 1))
	drafts = _dicts(d, "drafts")
	offers = _dicts(d, "offers")
	events = _dicts(d, "events")
	later = _dicts(d, "later")
	for l in later:
		l["due"] = int(l.get("due", 0))
	intel_weeks = int(d.get("intel_weeks", 0))
	quiet_weeks = int(d.get("quiet_weeks", 0))
	desk_log = _dicts(d, "log")
	seen = d.get("seen", {}) if d.get("seen", {}) is Dictionary else {}
	doctrine = String(d.get("doctrine", ""))
	unlocked = _arr(d, "unlocked", DOCTRINE_ORDER.slice(0, DOCTRINE_BASE))
	last_reconcile = int(d.get("last_reconcile", -99))
	reconciled = d.get("reconciled", {}) if d.get("reconciled", {}) is Dictionary else {}
	Equipment.armory = armory_set()
	# A draft saved before the fix may still hold a card the armoury already covers
	# (a run saved between picking the inheritance and signing a contract).
	_revalidate_drafts()


static func _arr(d: Dictionary, k: String, dflt: Array) -> Array:
	var v = d.get(k, null)
	if not (v is Array):
		return dflt.duplicate()
	var out: Array = []
	for x in v:
		if x is String:
			out.append(x)
	return out


static func _dicts(d: Dictionary, k: String) -> Array:
	var v = d.get(k, null)
	if not (v is Array):
		return []
	var out: Array = []
	for x in v:
		if x is Dictionary:
			out.append(x)
	return out
