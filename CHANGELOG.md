# The Violence: changelog

Newest first. The README covers the game as it stands; this file keeps the history.

## v1.2.0: the opening

- **Four opening cutscenes**, made with Remotion (cinematics/), drawn in the red-ink hand and scored with the game's own sounds: *Port Carrick* (the city, the closing mill, the wards and crews, gunfire on the map, headquarters), *The Outgoing Chief* (the desk, his note, what you inherit, the phone), *The Plan* (a briefing drawn with total confidence, then the same house when the plan meets the room) and *Forty Weeks* (the calendar, the candidates, the allies, the first front page, the title). About two and a half minutes in all.
- They play before a new campaign; Space or a click skips one, Esc skips the rest. Settings > "The opening cutscenes before a new campaign" turns them off, and the title's **Prologue** plays them again.

## v1.1.0: figures that move

- **Animated figures.** The plan's figures are now a rig (scripts/view/rig.gd) instead of one still sprite: torso and mark, a head that turns on its own, and arms, hands and feet drawn in code. Walking and running step the feet and swing the free arms; stance changes ease in; aiming puts both hands on the weapon and follows its traverse; each round kicks it back with a paper-white muzzle flash (no colour: red stays for consequence). Actions have their own hands: reload (canted rifle, the support hand to the pouch and back with a magazine), stoppage (tap, rack), the swap to the sidearm, doors (open, ram, kick), throwing a bang, sting-ball or gas, cuffing, treating, OC spray, the baton. Hands up, cuffed, filming, frozen and hiding civilians, the stunned, blinded and gassed each have a pose. A hit staggers; a fall plays out over half a second; the wounded on the floor breathe and the dead do not. The replay drives the same rig from the recorder, with recoil for each round fired. City figures step their feet.
- **Performance:** figures off screen skip their animation; far out, limbs drop their shadows and paper edges. The simulation is unchanged (the determinism fixture holds).
- **Fixes:** the ambience beds now loop by their import settings; 1.0 set the loop point at run time from the compressed data's byte count, which put it about a fifth of the way in, so only the first few seconds of each bed repeated.
- **Tools:** tests/rig_gallery.gd shows every pose (and records them moving); a director's camera for recordings (--cam=action or follow:ID, --camzoom, --clean); --soundlog writes every sound the game plays, and tools/mix_soundtrack.py turns that log into a recording's soundtrack; tools/ad_card.gd draws title cards in the game's hand; tools/make_ads.py cuts the four trailers (The Plan, Forty Weeks, Hands Off, Port Carrick) from deterministic recordings of the game; --perf reports frame costs; --nofog, --hold, --ui-scale and --shot-wait for recordings; tests/op_test.gd --save keeps a played campaign.

## v1.0.0: the release

- **A front end.** The game opens on a title screen: Continue (with the week, fit officers and the account of the saved campaign), New campaign (it asks before it replaces a save), Test range, Endless battle, How to play, Settings, Credits and Quit. Every screen has a way back to the main menu.
- **A pause menu.** Esc during an operation or on the board opens it: Resume, How to play, Settings, and Abort the operation (during a run) or Main menu. In the test range Esc still goes back to setup.
- **Settings that persist** (user://settings.cfg): fullscreen, master, effects and ambience volume, red ink, gore, the speed an operation starts at, and the first-weeks tips. F2 and F3 now save their choice.
- **How to play:** an eight-page manual (the job, a week, planning, the operation, afterwards, the department, the city, controls), from the title or the pause menu.
- **Onboarding:** in weeks 1 and 2 the board shows a card from the outgoing chief, and each planning tab carries one line on what it does. Settings > Tips turns them off.
- **Sound.** The game had none. 34 effects are synthesised by tools/make_sounds.py (no samples): a shot and a far, muffled version for each of seven weapon classes, flashbang, sting-ball, ram, kick, door, gas, taser, the radio's squelch, an interface tick, the debrief's stamp, and two ambience beds (the city at night under a run, the chief's office under the board). A shot out of every officer's view, or far from the camera, plays its far version. At high speed shots are thinned to three a frame. Sound never touches the simulation.
- **Safe saves.** The campaign and the department are written to a temporary file, checked, then swapped in; the previous save is kept as .bak, and a missing or damaged save falls back to it (tests/save_test.gd).
- **Packaging:** the project is named "The Violence", version 1.0.0, in the window title, the exe's details and the title screen. The README is now written for players; the version history moved here.
- **Deferred past 1.0:** the city campaign map (v0.10): operations on the city's lots, civilians in the Endless Battle, and city police who judge and arrest.

## v0.9.1: debugging and balancing

A full pass over every suite, every screen and two new diagnostics. These were run on 20 suggested-plan operations per type, from fresh and all-rookie departments, and on 40-week campaigns:
- `tests/lethality_test.gd` takes apart every officer hit: who fired, at what range, whether the officer had recognised the shooter, what they were doing, and whether they bled out.
- `tests/duel_probe.gd` does the same for both sides of an assault on a held house.

**Friendly fire was killing officers (fixed).** Half of all officers hit in gang raids were hit by other officers: 21 of 43, and 30 of the 32 police rounds that hit police were aimed at a suspect with another officer in the way. The only rule that made anyone hold fire for a teammate in the lane was the WD10 habit, which no department officer under nine years had. So a rookie fired straight through the back of the colleague in front of him.
- Everyone now has the instinct not to fire with a friend squarely in the line (within 0.3 m of it, between the muzzle and the target).
- Police also hold fire with a colleague up to 4 m beyond the target: know your target and what is beyond it.
- WD10 keeps its wider lane and the step aside. A defender firing through the counter (BH26) still ignores it all.
- Officers killed per gang raid fell from 1.25 to 0.30, and police rounds hitting police from 32 to 2 in 20 raids.

**Defenders walked back to their posts mid-fight (fixed).** A defender knocked off his post walked straight back to it, in the open, while the fight went on. That was 22 of 163 defender deaths. Now, while his squad is in contact, he takes cover where he is, facing the threat, and goes back once it is quiet.

**What the friendly-fire fix changed elsewhere.**
- **A shot held for a friend is judged again** when the lane clears, in case the man went down or gave up meanwhile. Officers with the Overkill habit (BH03) still fire.
- **A fighter whose shot is blocked** by a friend in the lane, while someone unseen is shooting at him, now takes cover first (the Lizard) instead of standing there in Rule 1.
- **Longer fights mean more stress,** so stress habits show up more. Patrol officers' excessive-force findings rose from 7 to 39 in the civilian test's 40 operations; nearly all were overkill by BH03 under fire. Police tactical stayed at 0. Without friendly fire to end fights early, rookies stay under fire longer and some crack. That is what the habit models, so it is not tuned away. It feeds internal affairs and the press.
- **The Lizard's measured effect shrank.** Its cover reflex now cuts the time spent in an unseen shooter's line by about 15%, down from about 19%: more fighters are frozen by BH07 (flinch and turtle). The check leaves out BH07-frozen time, as it already left out Rule 1 time, and runs 20 seeds.

**The attack-defence balance.** With friendly fire gone, attacking stacks stopped shooting each other. Equal regulars' attackers went from 43% to 63%, then back to 48% with the defenders' fix (80 fights, inside the 30-50% gate). Equal police tactical attackers win 60%, an edge their kit gives them.

**Gang raids judged fairly.** One member hidden and never found no longer turns a raid with everyone else in custody into a failure. A raid is a partial success whenever no more than half the crew is unaccounted for.

**The campaign no longer collapses.** Before this pass, a 40-week campaign played with the suggested plans lost 23-30 officers, and by week 10 there was nobody left to send. Two campaigns with a sensible scripted chief now lose 14 and 17 (0.19 and 0.29 per operation), keep 8-13 officers fit, and end in close races (Kettering 40-44, Okonjo-Vale 32-34, Pell 22-28). The causes, in order of weight:
- **Morale fed a death spiral.** Low morale added up to 0.12 to every officer's starting stress, which pushed them into their stress habits sooner under fire. Gang raids killed 0.47 officers each at morale 10, against 0.17 at morale 60. The effect is now at most +0.05 (0.28 per raid at morale 10), and a death costs 3 morale instead of 5.
- **Wounds kept the department out.** A serious wound kept an officer out 8-14 weeks. At 0.6-0.9 officers down per operation, that held about 15 officers out at once. "Down" covers every incapacitating hit, limbs included, so it is now 4-8 weeks, and a lesser wound 1-3.
- **Staffing floor.** The suggested plan sends nobody rather than fewer than four officers through a door, or fewer than six into a crew house or a hostage taking. Four officers in a gang house lost 0.40 each raid, ten lost 0.27. The briefing says so, and you can still assign officers yourself.
- **A handgun-rated police helmet** ($650, open to anyone) is now in the entry, gas and shield kits and in the kit editor's new Helmet row. Until now the only helmet was the special-operations one. It stops handgun rounds and buckshot to the head, not rifle rounds: 82% of handgun rounds to the head are survived, about 60% from the front (the face is open) and 92% otherwise. A stopped round costs a quarter-second flinch. In gang raids it comes out about even (0.32 officers killed per raid with it, 0.31 without, over 80 raids), because officers mostly fall to hits it cannot stop. Its first version, with a one-second stagger and a large jolt of stress, made things worse and was cut back.
- **Who pays for casualties.** The pension board and workers' compensation carry most of a line-of-duty death or injury. The department pays $3,000 for the funeral and $500 or $1,500 in medical bills, instead of $8,000 and $1,200-4,000. Losses still cost you officers, morale, the union and the polls.
- **The politics.** About 50 situations a campaign go unattended whatever you do, and each one fed Kettering, so he won every run.
  - A quiet warrant left undone now barely registers. A crew house or a hostage taking left alone, or anything people were watching, still costs trust and feeds him.
  - Officers killed and failed operations feed him a little less.
  - Pell gains a little every week the books balance.
  - The polls drift slightly back towards where the city started, so no lead runs away on momentum alone.
  - The hands-off test campaign is now close through week 20 (Kettering 37, Pell 35). It goes to Kettering, 46 to 29, only after the union and the council are lost.

**Other bugs fixed.**
- **City mode:** a holding unit going back to its post called the city's pathfinder with an argument it did not take, and failed. That was 64,000 errors a minute in the Endless Battle, and those units never moved. It had been there since v0.7.
- **Equipment checks:** three of them (heavy pistol, battle rifle, iron sights) had been failing since before v0.7.9. Their margins were above what the design gives (a heavier round raises the outright kill on an unplated chest hit from 20% to 24%). They are now pooled over twelve times the seeds against margins the design reaches.

## v0.9.0: the city, the press and the election

The campaign now ends. At the end of week 40 Port Carrick elects a mayor, and whoever wins decides what happens to you. Until then the city remembers what the department does, and some of it comes back weeks later. All of it is in `City Hall` on the operations board, and in the Carrick Ledger's front page above the week's situations.

**Trust in police, ward by ward.** Each ward starts where it was (Ironworks 24, Old Town 62) and now moves:
- Clean successes raise it, failures lower it, and suspects killed where people were watching lower it.
- Situations nobody went to lower it.
- Stories about civilians hurt by police lower it most.
- Trust sets how many tips the ward's community group gives a briefing (none below 25).

**Four allies, each holding something.** Below 25 an ally is lost and what they hold goes with them; above 40 they can be won back.
- **Marguerite Duff, budget chair:** the allocation. Lost: the allocation is cut by 8%. She likes balanced accounts and clean results, and dislikes deficits, settlements and dead officers. Every eight weeks her committee reviews the allocation (+4% at 70 or more, -3% below 45).
- **Tommy Rourke, police union:** the officers' goodwill. Lost: morale settles at 45 instead of 60. He dislikes dismissals, suspensions, low morale and officers killed.
- **Rev. Alma Mbeki-Shaw, community coalition:** the community tips. Lost: no community tips in any ward. She watches civilians hurt, cases cleared, situations ignored and dismissals.
- **Paul Varga, district attorney:** the benefit of the doubt. Lost: every serious case you clear with video or witnesses behind it gets the officer charged (six weeks suspended, morale -4).

**Consequences that land later.**
- **Stories.** A civilian hit or killed by police, or excessive force, becomes a story. On video, or at visibility 4-5, it makes the next front page. At visibility 3 or with witnesses it takes a week or two. Out of sight it takes three to nine weeks, and at visibility 1 with no witnesses half of them never land. A story costs trust in its ward and standing with the coalition, the council and the DA, and it moves the polls.
- **Lawsuits.** Every civilian police hit brings a lawsuit that settles six to ten weeks later, out of the department's account: $10,000 for someone hurt, $40,000 for someone killed.
- **Leaks.** Clearing a serious case can leak (55% with video, 25% with witnesses).
- **Neglect.** An ignored gang house or hostage taking, or anything highly visible, comes back as a story about police who never came.

**Three candidates.** Their polls move with all of the above and drift a little each week, the trailing campaigns pushing harder.
- **Royce Kettering (Safe Streets).** A corrupt, very pro-police councilman. He gains from failures, ignored situations and officers killed.
- **Dana Okonjo-Vale (Carrick Together).** A democratic socialist who wants to help the city, is openly critical of the police and wants you gone over the Bridge Street evictions. She gains from every story of police harm and from deaths at rallies.
- **Gordon Pell (Independent).** Aggressively boring and competent. He gains from clean successes and loses from deficits and chaos.

**The election and its endings.** Election day adds a little noise to the final poll. Then:
- **Kettering** keeps you on. With a heavy force record he makes you Deputy Mayor for Public Safety.
- **Okonjo-Vale** fires you on her first morning, unless average trust is 60 or more, the coalition is still with you and your force record is nearly clean. Then she keeps you, in writing, for ninety days.
- **Pell** keeps you, subject to review, if the budget is balanced and you spent no more than four weeks in deficit. Otherwise your position is reviewed out of existence.

The election night screen shows the vote, your ending and the record behind it. The campaign is then over, and `New campaign` starts another.

**The Carrick Ledger.** Three headlines a week: what landed, then the campaign, then the city. The city is mostly closures, potholes and a bakery's prize-winning rye.

**Two fixes.** The suggested plan's squad kits are now paid for: any kit that changes outside the editor is settled at the same terms (bought at cost, handed back for half). And the past weeks' situations now keep their whole numbers through a save.

**Test.** `tests/politics_test.gd` checks the following:
- Stories land by visibility and evidence, and some never land.
- Lawsuits settle.
- Each ally's loss does what it says, and the council's return restores the allocation.
- The DA charges what you clear.
- The election ends the campaign.
- The city replays and saves exactly, and a v0.8 save loads.

`tests/op_test.gd` now plays the chief too (`--decide`, `--hire`, and from v0.9.1 `--chief=sensible`: the gravest situations first, at most two operations a week, quiet warrants left while short-handed) and prints the city each week and the ending at week 40.

## v0.8.5: running the department

The department now costs money, learns and answers for itself. Everything is on the operations board (`Roster`, `Budget`, `Internal affairs`), with the account, morale and open cases shown above the week's situations.

**The budget.** The city sets a weekly allocation at the handover: the inherited payroll plus 16% ($30,500 against $26,264 for the default department), with $25,000 in the account.
- At the end of each week the allocation comes in and the payroll goes out. Pay is by rank ($1,150 a week for an officer, $1,750 for a lieutenant) plus 1.5% a year of service.
- As they happen: overtime ($160 per officer per operation, $60 more at night), restocking spent gear at cost, new kit, hiring, training, medical bills ($500, or $1,500 for a serious wound; v0.9.1), a line-of-duty death ($3,000; v0.9.1) and severance (two weeks' pay).
- Kit goes through the budget: new kit is bought at cost, and kit handed back sells for half.
- In the red, hiring, training and new kit are frozen until the account is back above zero. Each week in deficit costs morale and is counted (the council's view of it arrives in v0.9).

**Hiring and dismissal.** A recruit costs $3,500 for an academy place plus their kit and reports two weeks later. A lateral hire (three to six years elsewhere) costs $6,500 plus kit and reports at once. Dismissing an officer costs two weeks' severance and 6 morale.

**Training.** Open an officer's file on the roster to send them on a course. They are off the board for its length (one week, two for the tactical certification), and it takes effect when they come back.
- Close-quarters refresher ($2,400): the next habit of a Regular's set they lack.
- Firearms qualification ($1,800): about a year's worth of on-the-job improvement in recognition, aim and reloads; up to four times.
- De-escalation and judgment ($3,000): Judgment +6, to 90 at most.
- Stress inoculation ($3,200): trauma -4 and a little more stress resistance.
- Behaviour coaching ($3,800): works one personality bad habit out of them.
- Tactical team certification ($8,500, two weeks): qualifies an officer without five years or Experience 3 for tactical kit, and teaches two tactical habits.

**Internal affairs.** Every officer the incident record ties to a finding (a civilian hit, excessive force, friendly fire, a misjudgment, shots without a threat), and every officer who broke an order, gets one case per operation, led by the gravest finding and carrying the strongest evidence. Each case is cleared, sent to a use-of-force review ($2,500, a week off the board, Judgment +5), suspended (two weeks without pay, morale -3) or dismissed. A case nobody decides lapses after three weeks. What the public makes of these decisions arrives in v0.9.

**Morale** (0-100) starts at 60 and drifts back towards it, faster the further down it is. Deaths, wounds, dismissals, suspensions and weeks in deficit lower it; courses and cleared cases raise it a little. Below 60, every officer brings more stress into every operation. Below 35, officers may resign, the lowest integrity first.

**The balance pass.** A new harness, `tests/balance_test.gd`, runs five-a-side assaults on a held house on maps 00, 04, 05 and 06, with each brain switched off in turn.
- Equal regulars: the attackers win 43% over 80 fights, inside the 30-50% gate and close to the 33-44% from before the brains. v0.7.9's "12 of 20" came from a narrower sample and does not hold across these maps.
- Equal police tactical: the attackers win 59-67%, but 72% with every brain off. The brains help the defence; the attackers' edge comes from the tactical kit (bangs especially), not the brains.
- No combat code changed in this version.

## v0.8.0: red ink

The whole game is now drawn in one palette: ink, a few stepped greys, paper, and one red (#B31F26). Red is never a team colour or a health bar. It marks where a plan touches a real room: routes, alarms, consequence, and blood, which is the same ink. Every red mark also has a second cue (a number, an outline, a dash or a label), so the screen still reads with red off.

- **Palette.** `scripts/view/ink.gd` holds the tokens and the one accent function. Every view, the side panels and the rich text route their red through it. The alert pips are shapes, not traffic lights.
- **Figures.** Officers, suspects and civilians are flat ink silhouettes from above: body block, head, limb strokes, a soft offset shadow and one pale mark. Police carry a bar, the other side three diagonals, gangs their territory pattern, and medics a cross. Civilians are the hollow outline. A downed figure is the same silhouette on its side. Figures are never marked by a hit; the floor carries the consequence.
- **Blood.** Each person leaves at most one flat pool (outer at 0.68 alpha, inner at 0.90), one broken drag trail, a handful of flecks and one smear where a hit met a wall. There are no sprays and no wounds. Blood draws under the walls and furniture, so it stops at a wall's face. Every fallen person gets a numbered evidence marker. With gore off (F3) the stains go and the markers stay.
- **Theory and application.** The briefing is theory: the selected squad's plan is one clean red line from the stage through the entry to its objectives, with numbered rings and an arrowhead. The stamps read `MODEL: COMPLETE / UNKNOWN: NONE` and `RISK: APPROVED / OWNER: NOT LISTED`. The live operation, the replay and the debrief are application: the same map with grit, scuffs and loose paper. Each squad leader's actual route is drawn as a wobbling red line with a faint offset duplicate. The stamps read `ACTUAL: mm:ss / FRICTION: ALL` and `PAPERWORK: NN FORMS / MOP: REQUESTED`, and `FILED / NOT RESOLVED` once it is over.
- **Print.** The plan has sparse paper grain, small halftone patches and corner hatching, all placed deterministically so the same map always prints the same.
- **Toggles.** F2 is the monochrome proof and F3 is gore. `--mono` and `--nogore` set them from the command line. Neither touches the simulation: the determinism suite is unchanged at 35/35.
- The blood sprites (`fx/pool`, `spray`, `splat`, `smear`, `drip`, `stain`) are gone. `tools/make_placeholders.py` quantises every grey it writes to the token ramp.

## v0.7.9: squads and the four brains

Every operator, on every side, now thinks through one hierarchy of four brains, and every side is broken into squads by one set of rules. The brains are hidden from the player; the radio carries the leaders' orders.

**Squads.**
- **Formation:** as many three-person squads as possible, at most five; whoever is left over joins them, and past five squads everyone is spread evenly. At most six to a squad, so 30 to a side. 4 makes one squad of 4, 5 one of 5, 7 is 4+3, 10 is 4+3+3, 20 is 4x5, 30 is 6x5.
- **Where it applies:**
  - On the test range, up to 30 a side (posts for 30 on every map).
  - Suspects and gangs form squads the same way.
  - In operations, `Suggest a plan` forms the squads, and the player can move officers between them (up to five squads of up to six). For a warrant, a barricade or hostages it splits off a two-officer containment team from a lone squad of four or more.
- **Changing squads:** an operator who joins another squad (the last of his own, or a pair regrouping) takes its orders at once, with no lag.

**The four brains**, checked top to bottom for each operator every tick:
1. **Lizard, immediate danger.**
   - Covers being hit or shot at, an enemy in sight or within 10 m, a stoppage, an empty weapon, a stun, gas or running for it. Acquisition and Rules 1-4 live here, as before, and override everything below.
   - **New:** shot at by someone it cannot see, an operator gets out of that line of fire to the nearest cover from it, breaking contact.
2. **Lion, the squad in a fight.** Enemies have been spotted and the threat is live (contact within 12 s), but this operator has no shot. The squad leader (the highest rank alive, then the most experienced) decides once a second:
   - **push** on with the task. An entry under way is always pushed.
   - **take cover facing the threat**, when more enemies are known near it than the squad has people.
   - **fall back** to the last cleared room, or to the start, when the squad has lost half its people.
   - The leader acts at once; the rest follow after a lag set by the squad's cohesion and their own experience: about 0.4-0.6 s in a tight veteran squad, 1.8-2.7 s in a green one of strangers.
   - When the leader falls, the next takes command after 1.5 s.
   - A holding squad's fight is the hold layer, as before.
3. **Ape, the squad out of a fight.** The drills of earlier versions: stacks, breaches, entries, clearing, sweeps, holding, sectors, bounding, objectives. It is guided by the squad's order and its leader.
4. **Wolf, alone.** An operator whose squad is gone and who has no squad to join fights on his own. Attacking, he goes cover to cover toward the threat (the next cover 3-9 m nearer, hidden from it); holding, he keeps the best cover he has, facing the threat. Out of a fight he carries on with the task alone.

**The environment decides group or individual movement.**
- **Pairs in tight interiors.** A squad of four or more breaks into pairs (a three when the count is odd: 4 is 2+2, 5 is 3+2, 6 is 2+2+2) when all of these hold:
  - It is between rooms, out of a fight and inside a building.
  - At least two small rooms (18 m2 or less) are open to it.
  - No open room is believed occupied, meaning the briefing names it or someone was seen or heard there lately. A room like that gets the whole squad and its kit.
  - Each pair clears rooms on its own, under the squad's orders. The squad regroups when the small rooms run out, a pair is down to one, or its objective changes.
- **Dispersal on the defence.** A squad picks its room as before. A room that holds it (about 6 m2 a defender) takes the whole squad. A smaller one takes what fits, and the rest spread into the rooms behind it (farthest from where the attack will come first), each covering the door back into the front room: a layered defence with somewhere to fall back to.

**Cohesion.**
- Each pair of department officers who come back alive from an operation in the same squad builds a bond; six operations make a full one.
- A squad's cohesion is its pairs' bonds plus its leader's experience: strangers about 0.25-0.5 (by the leader's experience), a squad that has served together about 0.9.
- Sides without a history (the test range, suspects) take cohesion from their echelons, from untrained 0.15 to special operations 0.9.
- The save is version 4. Older saves load with everyone as strangers.

**Also fixed.**
- **The v0.7.8 out-of-ammunition rule** counted someone who came in unarmed as out of rounds. That ended any fight whose suspects were all unarmed at the first tick, and every equipment test with unarmed targets. Now only those who came in with rounds run dry, and under police rules suspects out of rounds still have to be arrested.
- **The equipment gate.** On the range the targets are dummies (no reflexes). The SMG is now measured as the share of police rounds that met a wall and went through, since the old share of all rounds swung with how many rounds reached a wall at all.

**The gate** (`tests/brains_test.gd`): each part is switched on and off (`Brain.features`) in otherwise identical runs.

| Part | Measure | On | Off |
|---|---|---|---|
| Formation | squad sizes for 1-30 that break the rules | 0 | |
| Lizard | share of the time under unseen fire spent still in its line | 0.57 | 0.69 |
| Lion | s from the leader's order to a subordinate acting, cohesion 0.9 against 0.15 | 1.01 | 2.46 |
| Wolf | share of a lone fighter's unseen fight spent hidden from the threat | 0.40 | 0.24 |
| Pairs | rooms cleared a minute, four officers searching small-room buildings | 2.88 | 1.41 |
| Dispersal | rooms a squad of four holds: Shotgun House (20 m2 bedroom) / Bunkhouse (42 m2 hall) | 2 / 1 | 1 / 1 |
| Bonds | cohesion of four officers after six operations together / as strangers | 0.93 | 0.43 |

`TV_BRAIN_OFF=pairs,disperse` (an environment variable) switches parts off in any harness.

**What it changed.**
- Equal regulars attacking a held house (5v5) now win 12 of 20, up from 6. The brains together are worth about six wins in twenty to the attacker, mostly the Wolf: lone survivors keep fighting cover to cover instead of standing still, and in an assault they are mostly attackers.
- The defenders' hold habits still pay: police attackers win 55% against them, 58% without; regulars 35% against 68%.
- Police hit fewer civilians in the civilian test: patrol 32 (was 39), police tactical 21 (was 25).
- The campaign sweep is within its noise: 12 successes (5 at a cost), 11 partial, 5 failures, 2 quiet rallies.
- A balance pass for the attack-defence shift is queued with the rest of v0.8's balance work.
- All other gates pass, and the determinism baseline is rewritten.

## v0.7.8: from the parallel line

Main on GitHub (the parallel line from v0.4) was compared with this one. Four things came across.

- **Four habit fixes.** Each habit now does what its name says.
  - **PF07 get off the X** sidesteps toward cover on first engaging an enemy at any range, not only inside 10 m.
  - **WD01 ammo count awareness** tops up in a lull below 30%.
  - **GD03 respect lines of fire** also steps out of a lane it is standing in.
  - **BH18 relaxed carry** now puts the eyes on the direction of travel out of contact; it only suspended habits before.
  - BH08 comms blackout, flagged on the parallel line, was already right here: its suspension of GD09 is the fix.
- **Determinism test** (`tests/determinism_test.gd`, fixture `tests/fixtures/determinism.json`). It runs 35 cases, hashes the end state of each, and fails on any change. The cases are nine test-range matchups at three seeds, plus the first week's board of two campaign seeds with their suggested plans (police rules, civilians, doors, kit, orders, less-lethal). `--write` resets the baseline: do it in the same commit as a behaviour change and read the diff, which shows winner, time, shots and hits per case.
- **Habit coverage check** (`tests/habits_test.gd -- --strict`). Every good habit must be read somewhere in the simulation. Every bad habit must have its own code or be declared a pure suspension (BH08, BH17, BH21, BH26), with a reason. Every id in a suspension list or a preset must exist. Habits read in only one place are listed for review (38, mostly hold-mode drills that belong to one branch).
- **Folder launchers:** `Play.bat` and `play.sh` (see Run it).

**One fix the regression found.** A fight in which one side has nothing left to shoot now ends: no rounds in any weapon, no spare magazine, no cache top-up. The last attacker out of ammunition used to sit in cover until the 900 s limit; with more top-ups (WD01) that became reachable on the Civic Plaza.

Effect of the habit fixes: 9 of the 35 determinism cases changed, and no winner flipped. The hold test moved within its noise, and all other gates are unchanged. In the campaign sweep, 13 succeeded (6 at a cost), 11 were partial successes, 4 failed and 2 rallies passed quietly; before, 12, 11, 5 and 2.

## v0.7.7: the less-lethal suite

Seven new items, and the taser and 40 mm launcher reworked into one system with them.

**Who uses what, and when.** An officer reaches for a less-lethal tool only for someone covered, challenged twice, showing no weapon and still not complying. He takes the least harmful tool he carries that is in range, in this order: OC spray, taser, pepperball, 40 mm, beanbag, baton. If nothing he carries is in range, one officer moves to where something is while the others cover. He walks in for OC spray or the baton, and steps back for beanbags.

| Item | Range | On a hit | Gives up | Hurt |
|---|---|---|---|---|
| OC (pepper) spray | 3 m, six bursts | down 1-2 s, then 15 s nearly blind | 7 in 10 | no; the cloud reaches anyone within 1.2 m, officers too |
| Taser | 7 m, two cartridges | down 5 s | 9 in 10 | 1 in 100 (the fall) |
| Pepperball launcher (tactical) | 2-18 m, ten volleys | 8 s nearly blind | half | 1 in 100; cloud 1.5 m |
| 40 mm launcher (tactical) | 3-30 m, five rounds | down 3 s | 6 in 10 | 3 in 100; inside 5 m, 1 in 8 goes down |
| Beanbag rounds (pump shotgun) | 4-20 m, five rounds | down 2.5-3.5 s | a little over half | 1 in 20; inside 6 m, 1 in 5 goes down |
| Expandable baton | arm's reach | to a knee 1.5-2.5 s | nearly half | 1 in 12 a wound; 1 in 50 a head strike that puts him down |

Nearly blind means three times slower to recognize anyone and aim twice as loose. Someone blinded or gassed also gives up far more easily when covered.

**Thrown.**
- **Sting-ball grenade** (tactical): goes in before the entry in place of a flashbang, 1.5 s fuse. Everyone within 5 m with a line of sight is down on one knee for 1-2.5 s and in pain. Those who show no weapon often give up (about a third; a tenth of the armed). One in twenty-five within 2 m is hurt.
- **CS gas grenade** (tactical): fills the room it lands in for 90 s (in the open, a 4 m cloud for 20 s).
  - Anyone inside without a mask is doubled over for 1.5-3 s at the first breath, then gassed for as long as they stay and 6 s after: nearly blind and coughing.
  - Suspects who would give up run for clean air instead of fighting. Civilians run. The defiant stay and suffer.
  - The squad throws it from out of the room's line of fire and holds the door for 20 s, so whoever comes out meets them.
  - Gas goes only where the briefing puts the suspect or someone was seen or heard lately, and never where there are hostages.
- **Gas mask:** no effect from gas or a pepper cloud; the visor slows recognition by a tenth.

**In the record.** Every less-lethal use goes in the incident record, hit or miss. Anyone hurt by one is a finding (*less-lethal injury*), and so is a civilian or hostage caught in gas (*gassed civilian*).

**Kits.**
- Department officers are now issued OC spray and a baton with the taser. On the test range, the Patrol preset carries both and Police tactical carries OC.
- The Less-lethal squad kit:
  - Point man: pump shotgun with beanbags, the 40 mm, OC and a baton.
  - The rest: taser, pepperball, OC, baton.
- A new Gas squad kit:
  - Point man: two gas grenades, a ram, a mask.
  - The rest: masks, a sting-ball, taser and OC.
- `Suggest a plan` gives a barricade's entry squad the Gas kit; hostage rescues never get gas.

**On screen.** Gas is a halftone haze of dots over the room, thinning as it clears. Sting-balls burst into a ring of pellets, pepper sprays show as a dark-red stream, and baton strikes as an arc. Labels read GASSED, BLINDED, OC SPRAY, BATON, PEPPERBALL, BEANBAG, STING OUT and GAS OUT. A masked officer wears the mask on the plan, and the roster lists every consumable.

**The gate** (16 paired runs each):

| Item | Measure | With | Without |
|---|---|---|---|
| OC spray | s until an unarmed man who will not give up is cuffed (240 = never) | 122 | 228 |
| Baton | same | 194 | 228 |
| Pepperball | same | 110 | 228 |
| Beanbag | same | 217 | 228 |
| Sting-ball | barricaded suspects (two, with pistols) who end alive in cuffs | 1.12 | 0.06 |
| CS gas | same | 0.69 | 0.06 |
| Gas mask | officer-seconds spent gassed taking a gassed room | 0.0 | 5.5 |

The beanbag is the weakest indoors: a house rarely leaves room to step back 5 m with a clear line, which is why it is a standoff tool.

**Test range:** `--gear=gas:2,gas_mask:1` gives team A that gear too (as far as its training allows).

**Also.** The campaign sweep found one more rally shooting: a calm officer took a phone held up 26 m away for a gun, and the shooting set off a second officer. A phone now adds 0.5 points to a calm officer's chance of misjudging, down from 4; it stays 4 under stress or in a fight. All six rallies in the three-seed sweep are clean of police shootings.

## v0.7.6: playtest fixes

A playtest of every system (all tests, three campaign seeds over three weeks, the main screens) found five problems. All are fixed:

- **Rallies: police shot the crowd.** Officers posted at a rally re-judged every face every 10 s, each time with a fresh chance of mistaking a phone for a gun. Over ten minutes that made a police shooting near-certain (up to 16 in the crowd killed before any attack). Now a calm officer, out of a fight and unstressed, makes a tenth of the mistakes, makes no new mistake about a person already cleared who is still calm, and only rarely about one filming. First sight, running, the dark and fear still carry the full risk. Misjudgments in house operations also fell (civilian test: patrol 11 to 4, police tactical 2 to 0); the civilian gate still passes.
- **"Passed quietly" after police killed people.** A rally with no attack counted as quiet whatever the police did. Now deaths make it a failure and police hits a partial success.
- **The suggested plan took everyone.** The first situation opened took up to ten officers and later ones got none. The suggestion now shares the officers still free across the week's open situations, each in proportion to what it wants (at least three where possible).
- **Idling to the time limit.** A team without "Clear before passing" (PF10) skips small rooms, so a suspect hiding in a closet was never found and the squads stood for nine minutes. The skip is kept (it is what the habit is for), but the radio now says "rooms clear, N small rooms not checked". Once every searching squad is done and nobody has seen a suspect for 60 s, the commander stands the squads down; the debrief says the suspect was never found. Surrender needs an officer in sight, so standing down cannot cut one short.
- **Labels.** The label is the goal; the score also counts deaths and officers down. A goal met at a cost now reads "Success, at a cost", so "Success, 50" no longer looks like a contradiction. A squad with nobody left standing is no longer credited with rooms others cleared.

Campaign sweep (three seeds, three weeks, the suggested plans): before, 6 successes, 8 partial, 13 failures and 3 that ran empty or with nobody; after, 13 successes (7 at a cost), 13 partial, 2 failures, 2 quiet rallies.

## v0.7.5: equipment and doors

Every operator now carries a kit from the equipment database (`scripts/data/equipment.gd`). Each item is there because it changes the outcome; the gate below measures that.

**Who may carry what.** Each item is open to anyone, to the tactically trained, or to special operations only.
- Tactical training means the Police tactical or Special operations echelon. A department officer counts as trained with five years on the job or Experience tier 3.
- The special operations helmet is for Special operations only.

**Weapons.** Each weapon has its own draw time, sway, rate of fire, lethality, penetration and sound.

| Slot | Weapons |
|---|---|
| Primary | patrol carbine, short-barrel rifle, submachine gun, pump shotgun (buckshot), battle rifle, marksman rifle, assault rifle |
| Sidearm | service pistol, compact pistol, heavy pistol |

**Sights.** Iron sights are slower on target far off. A red dot is the v0.7 baseline. A magnified optic is a little slower close in and far steadier at range.

**Armour.**
- A soft vest stops pistol rounds and buckshot.
- A plate carrier takes 0-4 plates.

**The special operations helmet** stops the first round to the head. The wearer is stunned for 2.5-4 s (no recognition, no aim), deaf for 15 s and badly shaken. It never stops a second.

**Tools.**

| Tool | What it does |
|---|---|
| Flashbang | Thrown into a room before the entry, 1.2 s fuse. Within 6 m with a line of sight it stuns: 3-5 s if facing it, 1.5-2.5 s if not, plus 10 s of deafness. Stacks wait for a clear throw and look away. |
| Door ram | A locked door opens in one to three 1.2 s blows (six in ten land). Heavy: the carrier is slower. |
| Breaching rounds | Opens a locked door with one shotgun shot (0.8 s, nine times in ten). Needs the pump shotgun. |
| Ballistic shield | Stops rounds across 60 degrees either side of the front: the body, nine head hits in ten, half the leg hits. Half of battle-rifle rounds go through. The carrier walks, fights with the pistol and leads the stack. |
| Weapon light | At night, cancels the dark's penalty to recognition and judgment in its beam (30 degrees either side, 25 m). Anyone who sees the beam sees the carrier as if by day. |
| Medical kit | Once the area is quiet, an officer treats the downed: one in three of the untreated die after the operation, against fewer than one in ten of the treated. |
| Taser | Two cartridges, 7 m. For someone who will not give up and shows no weapon, after two challenges. |
| 40 mm launcher | Five sponge rounds, 30 m: the same job at range, less sure. |

**Doors.** Every door with a leaf can be open, shut or locked.
- A shut door blocks sight and is opened in 0.6 s. A locked one blocks movement too.
- Occupants (team B) carry keys and unlock in 1.6 s.
- Police need a ram or a breaching round, or kick: up to eight kicks of 1.3 s, each with a 15% chance.
- Bullets go through doors: a hollow inner door stops about as much as a partition, a solid outer door as much as a timber wall.
- On the plan, a shut door is a bold leaf across the opening and a locked one carries a black bolt. A forced door shows splinters at the latch.
- In operations, outer doors are usually locked, some inner doors are shut, and a barricaded suspect's room is often locked. The briefing gives an estimate of the doors.

**The assault with doors.** A squad stacks on the door. The breacher opens, unlocks, rams or kicks it. If anyone in the stack carries a flashbang, it goes in first when the room was behind a shut door, when someone was seen or heard in it lately, or when it is an objective room. The thrower waits until nobody of the squad would see the flash, and the entry follows 0.15 s after it goes off. The shield carrier, if there is one, is first in the stack.

**In operations.**
- Every officer has a kit, kept in the save (version 3; a v0.7 save loads and gives everyone the department's issue kit: carbine, pistol, soft vest, light, medical kit, taser).
- The Force tab has squad kits (Patrol, Entry, Shield, Less-lethal) and a `Kit` editor for each officer.
- `Suggest a plan` gives entry squads the Entry kit.
- The debrief lists each officer's kit and what they used.
- Suspects carry handguns (and, where the briefing says rifles, assault rifles or carbines), and a few wear vests.

**The equipment gate** (`tests/equip_test.gd`): 16 paired runs with and without each item, everything else the same.

| Item | Measure | With | Without |
|---|---|---|---|
| Compact pistol | s to the first shot from the holster | 0.98 | 1.14 |
| Heavy pistol | targets killed outright per hit, 6 m | 0.27 | 0.24 |
| Submachine gun | share of police rounds through a wall | 0.09 | 0.15 |
| Short-barrel rifle | s on target per acquisition, 6 m | 0.16 | 0.18 |
| Assault rifle | killed outright per hit, 15 m | 0.27 | 0.24 |
| Battle rifle | killed outright per hit, 15 m | 0.29 | 0.24 |
| Shotgun | hits per round, 12 m | 0.90 | 0.67 |
| Marksman rifle | hits per round, 38 m | 0.30 | 0.18 |
| Iron sights | s on target per acquisition, 18 m (slower) | 0.28 | 0.26 |
| Magnified optic | hits per round, 38 m | 0.34 | 0.18 |
| Flashbang | officers hit during the entry of a room held by 3 rifles | 0.81 | 1.75 |
| Door ram | s to the first officer inside, outer doors locked | 10.4 | 30.5 |
| Breaching rounds | s to the first officer inside, outer doors locked | 8.4 | 30.4 |
| Ballistic shield | rounds through to an officer facing 3 rifles, 10 m | 0.27 | 0.75 |
| Weapon light | s for police to recognize someone, at night | 0.53 | 0.61 |
| Medical kit | share of the downed who die after the operation | 0.09 | 0.30 |
| Taser | s until an unarmed man who will not give up is cuffed | 58 | 228 |
| 40 mm launcher | the same | 186 | 228 |
| SOF helmet | head hits survived, first and second | 20/20, 0/20 | - |

19 of 19 pass. One cost the table hides: across the whole flashbang scenario, officers took 2.0 hits with bangs against 1.5 without, because the stack stands at the door through the fuse. The entry itself is safer by half.

**Fixed.** A team starting Green never drew its weapons on going to Yellow or Red (the draw was skipped). It now draws, which costs Green ambushers a little time.

**Art.** New sprites for the ten weapons, the vest, plate carrier, helmet, shield and ram, all drawn on the figures. Door states on the plan, action labels for the new actions (RAMMING, BANG OUT, TASER, STUNNED), and the run roster shows each operator's weapon and the tools left. New app icon.

## v0.7: operations

Press `OPERATIONS` on the setup panel. The campaign is saved after every operation and every week (`user://campaign.json`, one slot). `New campaign` starts again from a new seed. The v0.6 department save is not carried over.

**The department you inherit.** Port Carrick PD starts with 20 officers: a lieutenant with 14 years on the job, two sergeants with 9 and 11, four corporals with 3-7, and 13 officers, 7 of them in their first year.
- A new hire is **Patrol**, between Militia (the irregulars) and Regular (the infantry) in every stat.
- Years on the job move an officer's stats from Patrol toward Regular. At ten years they are a Regular; beyond that they move a little toward Police tactical (at most 60% of the way).
- Each year also brings habits Regulars have and the academy doesn't teach (PF02, GD02, GD05, GD06, WD07, about three every five years). Officers with nine years or more also bring one to four tactical-team habits.
- They arrive with the experience their years earned: the lieutenant is at tier 4.
- Every officer's file opens with the years they had when you took command.

**The board.** Each week has two or three situations from five types, in six wards. Each ward has its own trust in police and its own isolation.

| Situation | Maps | Visibility | Time pressure | Success means |
|---|---|---|---|---|
| Warrant service | houses | 1-3 | none: you pick the hour (day or night) | the named suspect arrested or giving up |
| Gang house raid | the bigger buildings | 1-2 | low | every member arrested or down, nobody away |
| Barricaded suspect | houses, the store | 2-3 | low | the suspect arrested or giving up |
| Hostage | houses, the store | 3-4 | high: a deadline, then the captor shoots | every hostage out alive |
| Public event | Civic Plaza | 5 | set by the event | nothing happens, or an attack is stopped with nobody in the crowd killed |

Public events come more often as the election nears (35% of weeks at the start, about 80% by week 40). Almost always nothing happens. When something does, attackers hidden in the crowd show their weapons at a random moment.

The week ends with `End week`. Situations nobody went to are written down, wounds heal and a new board fills. The campaign runs 40 weeks to the election; the election at the end of week 40 ends the campaign (v0.9).

**1 Briefing.** The situation, the floor plan, visibility, time pressure and the ward. What is known about who is inside is listed fact by fact. Each fact is either a tip (confirmed) or an estimate with a confidence, and estimates can be wrong. Rooms named by the briefing are tagged on the plan.
- Tips come from the public (more at high visibility) and from the ward's community group (more where trust is high).
- `Canvass` sends one officer round the neighbourhood: two more tips, and that officer is gone for the week.
- Warrants let you choose night: everyone is at home, recognition and judgment are slower and civilians are misjudged more often.
- `Body cameras` decides whether what officers see is kept as evidence (below).

**2 Force.** Tick who goes. An officer is committed to one situation a week and can't go to another. The injured are listed but can't be picked.

**3 Orders.** Up to five squads of up to six (30 officers). Each squad's leader is its highest rank, ties going to the most experience. The leader's experience tier sets the squad's order points: 1, 2, 3, 5 or 7 for tiers 1-5.

Every squad gets one objective free; a second objective (done after the first) costs a point. Objectives:
- **Clear:** the whole building, or only the rooms you pick (plus the rooms on the way to them).
- **Arrest:** clear to the named suspect. Officers hold fire on them unless attacked, and challenge instead.
- **Rescue:** clear to the hostages and walk each one out to the casualty point by the vehicles.
- **Contain:** posts outside the doors and windows you pick. Anyone coming out is challenged.
- **Post:** stand at a point for the whole event, facing the way you set.
- **Patrol route:** walk a route you draw, again and again, and go to any contact.

Constraints, each for points:
- **Avoid** (1 per room): never go through the rooms you pick.
- **Consolidate** (1): hold the room you pick, covering every door off it, for 20 s before going on.
- **Phase line** (1): wait at the start until a time, or until another squad has met its first objective.
- **Entry point** (1): make the first entry through the door you pick.
- **Pace** (1): walk or creep only, unless in a fight.
- **Weapons tight** (2): fire only at someone firing or pointing a weapon at police; armed is not enough.
- **Knock and announce** (1): announce at the door and wait ten seconds.
- **Pistols only** (1): rifles stay in the car.

Rooms, doors, windows, posts and routes are picked by clicking the plan, which draws every squad's orders. `Suggest a plan` fills in a reasonable plan you can then change.

Bad habits can break orders. A rusher (BH11) won't wait out a consolidation. A chaser (BH12) or a lone wolf (BH15) moves at their own pace and through avoided rooms. Every broken order goes into the officer's file and the debrief.

**Run.** You watch; the officers carry out the plan as well as their habits, stress and experience allow.
- Pause, 0.25x to 20x, and a rewind slider. Rewinding only replays what was recorded; `Live` returns to the present. None of it changes the outcome.
- **Fog of war (v0.8.1).** You see what your officers see, live: each officer's actual view cone, where they are looking right now, out to 45 m and stopped by walls. A stressed officer's cone narrows, and a flashbanged one sees nothing until it wears off. The people shown are exactly the ones an officer has a line of sight to. Everyone else appears only at the radio's last-known positions, drawn as diamonds where they were called out. Blood, casings and bodies show only once someone has seen them. Body cameras no longer decide what you see; they decide what is kept as evidence.
- The radio log keeps to what a commander hears: contacts, shots, squads' progress, surrenders and casualties.
- **Abort (cut losses):** confirm once, and every squad withdraws to its vehicle at a run, fighting only if fired on. An abort is a failure, but it stops the losses.

**Debrief.** The result and its score, each squad's objectives (met or failed, and why), the timeline, every officer's rounds and hits, the civilians, and what the department gained or lost. Then the whole operation replays with the fog lifted, from 1x to 10x, with a slider.
- Score: success 100, partial 65, failure (an abort included) 30. Every death (officer, civilian or hostage) costs 15 and every officer down 5.
- Excessive force and civilians hit by police are not in this score. They are the department's other reputation, which the city remembers (v0.9: City Hall).

**New in the sim for operations.**
- **Suspects run.** A suspect who knows police are there (a knock, a radio call, a sound) and sees none of them may run for the edge of the lot; a knock makes it much more likely. Anyone who gets away is out of the operation.
- **Hostages.** Captors keep hostages close. A hostage is free once no captor is within 7 m and an officer is within 4 m. A Rescue squad walks them out.
- **Deadlines.** Once a hostage deadline passes, a captor with a hostage within 6 m and nobody to fight shoots one, then another every 90 s.
- **Attackers in a crowd** count as civilians until they draw.
- **Vehicles and a casualty point** by the stage area.

**Hold-mode habits (HD01-HD20, BH21-BH27).** A fifth habit group, Defence, and seven bad habits, all active only while an operator's squad is holding a position. They come from "Hold-mode habits: a draft for the bible" and are in the Hold tab of the habit editor.
- Regular gets HD01, HD02, HD05, HD08 and HD17.
- Police tactical and special operations get all of them except HD12 (police only), and except HD07 (both).
- The seven bad habits ride on stress or a personality trait like the others.

Measured over 120 assaults per matchup (five a side on maps 00, 04, 05 and 06), the attackers' wins with the defenders' layer off and on:
- Regular against Regular: 44% to 33%.
- Police tactical against Police tactical: 58% to 48%.
- Special operations against Special operations: 57% to 58%. Single habits help (the reserve, HD16, is worth 11 points), but together they cancel out; that interaction is the next thing to tune.

Two drafted habits made the defence worse and were changed: HD10's 50-80 degree angle is now 30-55 degrees, and HD07 is left out of every preset. Details are in section 5.8 of the NPC CQB Bible.

## v0.6: civilians, judgment, the department

**The Patrol echelon.** A new police hire sits at the midpoint of Militia and Regular in every stat: recognition 0.39 s, stress resistance 0.375, twelve habits (Militia's eight plus PF01, GD01, ED01, ED02), experience tier 1, and a soft vest that stops pistol rounds to the chest from any side but not rifle rounds.

**Civilians.** A parallel population with its own, much cheaper brain. Nobody targets a civilian on purpose (the paramedic rule), but every bullet can hit them.
- They start unaware. A gunshot heard, a drawn gun in sight, a near miss or someone falling alarms them.
- Then they act on their personality (panic, curiosity, defiance, mobility, a phone): flee to somewhere far and out of sight, hide, freeze, film the shooting from 7-26 m, or comply when an officer close by aims at them or shouts.
- Wounded civilians use the five-minute bleed-out like everyone else.

**Judgment (police rules).** An officer who has recognized a person must judge them before firing:
- threat (showing a weapon, or attacking): fire is allowed;
- unknown (no weapon in sight): the officer covers them and challenges, "Police! Show me your hands!", every 2.5 s;
- civilian, or someone who has given up: let go of, and not judged again for 10 s.

Judging takes about 0.3 s at Judgment 50, longer under stress and in the dark, much shorter when the person is pointing a gun at you. A civilian can be judged a threat by mistake, more often under stress, in the dark, with a phone in their hand, running, close, or with poor Judgment; raised hands make it rare. ED04 (threat discrimination) halves the chance and WD09 (trigger discipline) cuts it by 30%. Civilians use up attention too: an officer with Experience 1 who is looking at a civilian is not tracking the gunman behind them. Bad habit BH09 (Jumpy trigger) fires at half-recognized movement within 10 m before any judgment, civilians included.

Default Judgment by echelon: untrained 35, militia 40, Patrol 50, regular 50, police tactical 65, special operations 70.

**Surrender and arrest.** A suspect covered or challenged by police may give up: hands up, weapon dropped, kneeling. It is more likely when wounded, out of ammunition, under several officers' guns, untrained or stressed, and less likely with friends close by. An officer who was firing at them takes a moment to stop (reaction, plus Temper and stress; more with Overkill active). Those rounds are recorded as excessive force. The nearest free officer walks up and cuffs them (3 s). Under police rules the operation runs on until everyone who gave up is cuffed.

**Walls and rounds.** Rounds now go through some walls. Partitions (up to 0.15 m) are drywall, house exterior walls (up to 0.25 m) are timber frame, and yard fences are fences. A rifle round goes through all three, losing energy each time. A pistol round goes through drywall three times in four, timber one time in four. Anything thicker stops everything. A round slowed by walls is less likely to kill. This applies in the city too.

**The incident record.** Every operation records every round (who fired, at whom, what they had judged that person to be, who it hit, through how many walls), every person who went down, surrenders and arrests. Findings are the events that will become consequences in the campaign: a civilian killed or hit by police, excessive force, a misjudgment, friendly fire, an officer killed. Each finding carries its evidence:
- body cameras of officers within 30 m who were facing it;
- phone video from civilians filming it;
- eyewitnesses (civilians within 35 m with a line of sight);
- or only people who heard it.

**The department.** Port Carrick PD keeps persistent officers, saved after every operation (one save slot):
- Each officer is rolled once at hire (form, strengths and weaknesses, habits, personality, Judgment, Temper, Integrity) and keeps that roll for their whole career. (v0.6 started with twelve rookies; v0.7 starts with the 20 above.)
- Tick who goes on the next operation. Hover a name to read their file.
- After the operation, each officer gets experience: contact +2, under fire +2, +1 per hit on a threat (up to 3), +1 per arrest, +1 for coming back hurt. Tiers come at 6, 18, 40 and 80 xp.
- Wounded officers are out 2-5 weeks, or 8-14 if they went down. The dead stay in the roster as killed. Trauma from taking a life, being hit, losing a partner or hitting a civilian raises the stress they bring into later operations, and eases by half a point a week.
- Every finding that names an officer goes into their file.
- `Hire a recruit`, `Next week` (wounds heal) and `New department` (from a seed) are in the panel.

