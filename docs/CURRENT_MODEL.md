# The Violence — current model of the game

Merged 2026-10-26 from the 1.21 source tree (`The-Violence-1.21-main`, version 1.2.1) and the earlier design notes. Revised 2026-11-07 from `Status 2026-11-04` and the `Story Redesign Roadmap`. **Revised 2026-11-12 for the trunk** (Stage A of `Roadmap to Release v4`). Where the 1.21 tree and the early notes disagreed, the 1.21 tree wins *(1.21 supersedes)*.

**Tags used below**
- *(1.3)*: the roguelike run layer; Endless Battle removed.
- *(P1)*: built in Phase 1 or the 4–5 Nov balance work.
- *(trunk)*: joined on 11–12 Nov, when the balance line, the map-UI line and the cutscene line were merged into one tree. It is branch `arena/m8-trunk-2026-11-11` of `Ambidgen/The-Violence`, open as **pull request #18** into `main`. Until that is merged, GitHub `main` is still the 21 Oct tree.
- *(planned)*: from the story redesign or from `Roadmap to Release v4`. **Not code yet.**

## Premise

You are Chief **Thomas Grendel** of the **Port Carrick** police department (Pennsylvania), a rust-belt river-and-railway city on the edge of collapse. He is 42, married to Mary, and his daughter Alice was killed in a pileup on the central bridge, which is why the game is drawn in crayon. You inherit the Bridge Street eviction file and twenty officers.

- **In the code today:** forty weeks later the city holds a contested election, and the winner decides whether you keep the office. Nothing ends a run earlier. There is no clean run.
- *(planned)* **The story is set in 2001.** Week 1 is the week of the Valentine's Day shooting (Feb 14, 2001); election night is Tuesday Nov 6, 2001 (week 39); week 40 is the aftermath. You can steer Thomas but not customize him. **Whoever you stick with wins the election.** You lose the office only by failing: budget collapse, Internal Affairs, preventable officer deaths, or public outrage. Full design: `Story Redesign Roadmap`.

## Structure

- **Story mode is a roguelike run** *(1.3)*: one seed, forty weeks, one ironman save, ending on election night with a run score written to a legacy file. Each run deals a different desk (inheritance, procurement contracts, training programs, offers and events) on top of the seeded weekly board.
- **Test range**: a sandbox for two teams, habits, kit and doors on any of 12 maps.
- **Endless Battle is removed** *(1.3)*.
- *(trunk)* **Six crayon cutscene prototypes** are in `scripts/view/proto/`: the opening monologue, the press conference, Jeremy Berry, the Mayor, Hero and Fettick. They render through `tests/proto_capture.gd`; nothing plays them in a run yet.
- *(planned)* A **Paisley Tower tutorial mission** with a first choice, the cutscenes wired into a run, and dialogue choices throughout.

## The weekly loop

The whole campaign is played on the city map *(trunk)*: there is no side menu. Calls are red pins you click; Police HQ, City Hall and the Ledger are landmarks that open the department, the politics and the week; a small HUD shows the week, the account, officers fit, open cases, the patrol radio, End week and the menu. Every screen is a card over the map that can be dragged, folded or closed.

1. **Board**: two or three situations a week (warrant service, crew house raid, barricaded suspect, hostage taking, and, more often as the election nears, a public event at Civic Plaza). Each has a ward, ward trust, visibility (1–5) and time pressure. Officers committed to one situation (or canvassing) cannot answer another; unattended situations are recorded and have consequences. *(planned)* A crime track per ward, so a call left alone comes back worse; a seven-day strip on which each operation is placed; delegation of operations to a squad leader.
   - *(P1)* **Patrol radio:** one call a day. A named pair responds and the chief chooses *Proceed*, *Proceed with backup en route* ($150) or *Wait for backup* ($200). 16 kinds of call; routine calls (75%) are best handled alone, bar fights, domestics, robberies and shots fired want backup en route, a man in crisis or a man seen with a gun wants waiting. Most resolve on the desk; armed calls (about 0.65 a week) play out in the sim.
   - *(trunk)* The radio is **its own card**, opened from the radio on the HUD (which shows how many calls are still to come this week) or from a row on the week's card. An answer comes straight back to it with the next day's call. The week's report folds unanswered calls where nothing happened into one line.
2. **The desk** *(1.3)*: drafts and events must be settled before the week can end; offers lapse at week's end.
3. **Brief → Force → Orders → Run → Debrief** for each situation taken. *(trunk)* The floor plan fills the screen; a bar along the bottom holds the steps, and each opens as a card above it.
   - Briefing separates confirmed facts from estimates with confidence; tips come from community groups (if the coalition is still an ally), neighbours, and canvassing (two tips, costs an officer for the week). The readiness range is a planning index, not a win chance. *(planned)* The plan screen shows the **recommended force and kit** in its place, and whether the plan is under it.
   - Force: up to **5 squads of 6** *(1.21 supersedes "no cap on officers per mission")*; the highest rank leads; kit is bought from the account; a locked item cannot be issued *(1.3 armoury)*. *(planned)* The player picks only team leaders; the rest auto-populate.
   - Orders: objectives (clear, arrest, rescue, contain, post, patrol) and constraints (avoid, consolidate, phase line, entry point, pace, weapons tight, less-lethal first, knock and announce, pistols only). Order points come from the squad leader's experience. *(planned)* Contain and call out, for barricades and crew houses.
   - Run: the operation plays itself under fog of war and body-camera view, with pause, speed (0.25×–20×) and a rewind slider that is a way of looking, never a simulation rollback. *(P1)* Adaptive speed and a "skip to the report" button after 60 s of quiet. Abort = failure, but a failure with everyone alive scores better than deaths.
   - *(trunk)* **Orders in the field. The run is no longer purely hands-off.** Pick a squad on the run card and click a room: the squad breaks off, goes there by its normal paths, and holds it. *Resume* sends it back to its own orders from where it stands. Orders go to whole squads, to rooms inside only, and are logged on the radio and in the debrief. They are free today; *(planned)* they will be paid for from order points left unspent at RUN.
   - *(trunk)* **The camera.** The wheel zooms, a middle- or right-drag or W A S D moves the view, Home fits the plan. The run bar has zoom out, zoom in, fit and follow-the-action; the eye on a squad's row keeps the view on that squad. Moving the view by hand lets go.
   - Debrief: itemized score arithmetic, officer and civilian outcomes, findings, your edits versus the suggestion, a clickable timeline and a fog-lifted replay.
4. **Internal affairs**: findings open cases (clear, review, suspend, dismiss); cases lapse after three weeks. Statements are checked against body-cam and witness evidence; officer integrity matters.
5. **End week**: payroll out, allocation in, wounds heal, courses finish, delayed consequences land (stories, lawsuits, leaks), the Carrick Ledger prints. *(P1)* A ~5 s crayon **Week Closed** recap plays first (stamped CLOSED, or ON THE RECORD if anyone died); a click skips it and Settings has a `week_recap` toggle. *(trunk)* It is drawn in the same bright crayon as the other shorts.

## The department

- Officers start at **Patrol** echelon (midway between militia and regulars) and improve with experience, courses and *(1.3)* department-wide programs.
- **Habits** *(1.21 supersedes "40 good / 20 bad")*: 40 base good habits in four groups (pathfinding, group, eye, weapon discipline), each +0.5% reaction; 20 hold habits (HD01–HD20) that work while posted or containing; 27 bad habits (stress-triggered BH01–BH10 and BH21/24/26, personality-trait BH11–BH20 and BH22/23/25/27) that override the good habits they contradict. Hearing traits (tinnitus, sharp ears) exist.
- Records carry judgment, temper, integrity, trauma, personality, pair bonds.
- *(planned)* **Customisation and progression:** officers are customisable only past Sergeant, by speccing into archetypes. Natural experience caps at 85% of good habits and at most two bad habits. Squads move differently depending on their acting commander.
- **Budget**: weekly allocation (payroll +16% at handover), $25,000 reserve (a tuning constant under test: $25K vs $35K), kit bought at cost and sold back at half, overtime by time on target (half rate for static duty), academy recruits ($3,500) and laterals ($6,500), severance, lawsuits, a council grant.
  - *(P1)* **Forecast and overdraft instead of a hard freeze:** hire, course and kit buttons show the four-week forecast and ask before a week goes below $0; the council allows an overdraft with interest and a political cost, and only freezes hiring, training and kit below its limit. Lawsuits settle in four instalments. Late-game money sinks exist (an armoured rescue vehicle, a training range, a union contract).
  - **Deaths drive the bill.** In one 40-week run the death bill (academy replacements, death benefits, medical) was about $306K.
- **Hiring**: a weekly applicant pool of 2–4 complete records; pick one.
- **Courses**: CQB refresher, firearms qualification, de-escalation and judgment, stress inoculation, behaviour coaching, tactical certification, use-of-force review; per-officer queues; classroom courses while injured; cohort discount. *(planned)* Training programs become one-time, department-wide on/off habit switches, offered only if fewer than half the officers would benefit.

## The city

- **Six wards**: Northgate, Riverside, Old Town, Ironworks, Eastport, Kilbride, each with trust in police (0–100) that sets tips and moves with what you do there. *(planned)* Port Carrick has more than 1,000 homeless residents, mostly squatting in abandoned houses (city data to be added).
- **Four allies**, each holding something; lost below 25, won back above 40: Marguerite Duff (budget chair — the allocation), Tommy Rourke (union — morale), Rev. Alma Mbeki-Shaw (community coalition — tips), Paul Varga (DA — whether cleared cases stay cleared). *(P1)* A lost ally can now be won back through a reconciliation offer (big cost, +20 standing, once per ally per run). *(planned)* Each ally gains a preferred candidate, so path choices move allies.
- **Three candidates.** *(trunk)* The game now shows the canon names. Only the display text changed: the ids (`kettering`, `okonjo`, `pell`), the tickets, the polls and the way the election is decided are as before.

| Shown in the game *(trunk)* | Id and ticket in code | Still to come *(planned, R1 and R2)* |
|---|---|---|
| **George Carrick** | `kettering`, Safe Streets; corrupt, very pro-police | The populist right: rule of law, infrastructure, police funding; his tips escalate from warrant intel to PCE vandalism, then encampments and protests |
| **Julia Noussan** | `okonjo`, Port Carrick Together; democratic socialist, openly critical of police and of you | Grew up homeless in Port Carrick, Yale; zero tolerance for excessive force (suspend, then fire); the hardest path and the only redemption |
| **Bob Stevens** | `pell`, Independent; aggressively boring, competent | The **incumbent mayor**: balanced budget, raises taxes when needed; also the "mayor" ally. In code he is still a challenger |

- Consequences land late: a story in a week where people were watching, in months (or never) where they were not; lawsuits six to ten weeks on; cleared cases can leak.

## The run layer *(1.3)*

- **Inheritance** (week 1): pick one of three starting doctrines; finished runs unlock more (eight in all).
- **Procurement** (weeks 1, 5, 9…): three contracts from sixteen (tiered by week); sign one or pass for $2,000. Patrol stock to start; plates, helmets, shotguns, gas, flashbangs, SMGs, short rifles, shields, launchers and the rest must be drafted. Military contracts move Carrick up and the coalition down.
- **Training programs** (weeks 2, 8, 14…): three on offer, one habit for the whole force when it ends, then in the academy curriculum for every hire.
- **Offers** (~40% of weeks): 14 from candidates, allies, two journalists (Nadia Ferrante of the Ledger, Hollis Crane of Channel 6) and community leaders.
- **Events** (~55% of weeks): 20 multiple-choice events, some gambles, some with delayed consequences, often naming an officer from the roster.
- **Run score** on election night: successes and arrests up; failures, deaths, civilian hits, excessive force and neglect down; +60 for keeping the office with a clean record, +20 otherwise. *(P1)* The election night screen shows the breakdown. **Known problems:** patrol desk arrests (about 88 a campaign at 3 points each) add roughly 260; and answering a call is a worse bet than leaving it, so the do-nothing policy scores as well as any. *(planned)* Score against par: the same seed under an absent chief.

## Simulation

Deterministic, seeded CQB autobattler on 0.25 m navigation, 12 maps, doors (open, shut, locked; rammed, kicked, breached), penetration through walls and armour, judgment before force under police rules (capability, opportunity, intent; misjudgment probability from stress, night, distance, filming, hands), surrender and cuffing, less-lethal tools, civilians with personalities, stress that rises in contact and resets after a rally in quiet, and an incident record that feeds IA, the press and the election. A head hit from any gun can kill; equipment helps.

**Changed 4–5 Nov** *(P1)*, to cut officer deaths (crew-house raids were 70% of them):
- **Crew houses:** 2–6 members (was 3–8), rifle chance 0.3 (was 0.5); members surrender more readily when armed officers nearby outnumber them.
- **Body armour by calibre.** Every officer wears a soft vest under any plates. *Low* (pistols, SMG, the new .22 light pistol): torso hits only stagger, at most once a second. *Medium* (carbines, assault rifles, shotguns, the .45): 40% of the usual harm to a vested torso. *High* (battle and marksman rifles): two plates stop the round and are destroyed; with fewer, a torso hit kills. Head and limb hits are unchanged.
- **Warrants:** every officer serving one wears a helmet.
- **Street suspects:** two in ten carry a .22.
- **Decided 11 Nov:** head protection is settled through recommended kit, not a global rule *(planned, Stage B)*.

**Latest measures** (patrol matrix, 8 seeds × 4 policies, 5 Nov): officers killed per operation: crew house 0.44, hostage 0.13, barricade 0.10, warrant 0.06; patrols about 0.08 each. Total deaths remain about double the ≤ 8 band. A fresh 8-seed matrix on the trunk was started on 12 Nov; its report lands in `tests/results/arena/m8-trunk-2026-11-11/balance`.

## Look and sound *(1.21 supersedes the halftone comic-panel reference; the crayon overhaul supersedes the floor-plan look)*

A pencil-and-crayon world drawn as a child would draw it (Alice's hand), over grim subject matter, with the crayon baked to `assets/crayon/` and a "Line boil" setting. Red stays for blood and the VOTE crosses, and other colours join it. Details: `Visual Overhaul`. *(trunk)* One look all the way through: the opening's bright crayon on cream, for the map, the shorts and Week Closed. The campaign UI uses 67 crayon icons with short labels; explanations sit behind a "?" on each card. The F2 red-ink toggle (all-grey proof) and F3 gore toggle still exist. Synthesised weapon, door and radio effects; office and city ambience; no music yet.

## Engine and build

Godot 4.7.2 primary (4.4.1 supported), compatibility renderer, 1600×900 base. Version 1.3.0 "Early Access". CI runs the static audit and the quick tier on both engines for every push to `main` or an `arena/` branch, and for pull requests. Ships as **one self-contained Windows executable** with the game pack embedded (no installer, no DLLs beside it), exported with the official 4.7.2 templates. The formal Windows checklist (P2.A1: save, reload, alt-tab, resize, a second low-end machine) has not been done. Headless harnesses in tiers via `tools/run_tests.sh`; the quick tier is 27 suites on the trunk.
