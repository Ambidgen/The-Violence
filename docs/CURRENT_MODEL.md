# The Violence — current model of the game

Merged 2026-10-26 from the 1.21 source tree (`The-Violence-1.21-main`, version 1.2.1)
and the earlier design notes. **Where the two disagreed, the 1.21 tree wins**; those
places are marked *(1.21 supersedes)*. The 1.3 run layer (roguelike story mode) and
the removal of Endless Battle are marked *(1.3)*.

## Premise

You are the new police chief of **Port Carrick**, a rust-belt river-and-railway city on
the edge of collapse. You inherit the Bridge Street eviction file and twenty officers.
Forty weeks later the city holds a contested election, and the winner decides whether you
keep the office. There is no clean run.

## Structure

- **Story mode is a roguelike run** *(1.3)*: one seed, forty weeks, one ironman save,
  ending on election night with a run score written to a legacy file. Each run deals a
  different desk — inheritance, procurement contracts, training programs, offers and
  events — on top of the seeded weekly board.
- **Test range**: a sandbox for two teams, habits, kit and doors on any of 12 maps.
- **Endless Battle is removed** *(1.3)* — it was a proof of concept for the sim, and its
  ward-pressure link into the campaign went with it.

## The weekly loop

1. **Board**: two or three situations a week (warrant service, gang house raid,
   barricaded suspect, hostage taking, and — more often as the election nears — a
   public event at Civic Plaza). Each has a ward, ward trust, visibility (1–5) and time
   pressure. Officers committed to one situation (or canvassing) cannot answer
   another; unattended situations are recorded and have consequences.
2. **The desk** *(1.3)*: drafts and events must be settled before the week can end;
   offers lapse at week's end.
3. **Brief → Force → Orders → Run → Debrief** for each situation taken:
   - Briefing separates confirmed facts from estimates with confidence; tips come
     from community groups (if the coalition is still an ally), neighbours, and
     canvassing (two tips, costs an officer for the week). The readiness range is a
     planning index, not a win chance.
   - Force: up to **5 squads of 6** *(1.21 supersedes "no cap on officers per
     mission")*; the highest rank leads; kit is bought from the account; a locked
     item cannot be issued *(1.3 armoury)*.
   - Orders: objectives (clear, arrest, rescue, contain, post, patrol) and
     constraints (avoid, consolidate, phase line, entry point, pace, weapons tight,
     less-lethal first, knock and announce, pistols only). Order points come from the
     squad leader's experience.
   - Run: hands-off, under fog of war and body-camera view; pause, speed (0.25×–20×)
     and a rewind slider that is a way of looking, never a simulation rollback.
     Abort = failure, but a failure with everyone alive scores better than deaths.
   - Debrief: itemized score arithmetic, officer and civilian outcomes, findings,
     your edits versus the suggestion, a clickable timeline and a fog-lifted replay.
4. **Internal affairs**: findings open cases (clear, review, suspend, dismiss); cases
   lapse after three weeks. Statements are checked against body-cam and witness
   evidence; officer integrity matters.
5. **End week**: payroll out, allocation in, wounds heal, courses finish, delayed
   consequences land (stories, lawsuits, leaks), the Carrick Ledger prints.

## The department

- Officers start at **Patrol** echelon (midway between militia and regulars) and
  improve with experience, courses and *(1.3)* department-wide programs.
- **Habits** *(1.21 supersedes "40 good / 20 bad")*: 40 base good habits in four
  groups (pathfinding, group, eye, weapon discipline), each +0.5% reaction; 20 hold
  habits (HD01–HD20) that work while posted or containing; 27 bad habits (stress-
  triggered BH01–BH10 and BH21/24/26, personality-trait BH11–BH20 and BH22/23/25/27)
  that override the good habits they contradict. Hearing traits (tinnitus, sharp
  ears) exist.
- Records carry judgment, temper, integrity, trauma, personality, pair bonds.
- **Budget**: weekly allocation (payroll +16% at handover), $25,000 reserve, kit
  bought at cost and sold back at half, overtime by time on target (half rate for
  static duty), academy recruits ($3,500) and laterals ($6,500), severance, lawsuits,
  a council grant. A negative account freezes hiring, training and kit.
- **Hiring**: a weekly applicant pool of 2–4 complete records; pick one.
- **Courses**: CQB refresher, firearms qualification, de-escalation and judgment,
  stress inoculation, behaviour coaching, tactical certification, use-of-force
  review; per-officer queues; classroom courses while injured; cohort discount.

## The city

- **Six wards**: Northgate, Riverside, Old Town, Ironworks, Eastport, Kilbride, each
  with trust in police (0–100) that sets tips and moves with what you do there.
- **Four allies**, each holding something; lost below 25, won back above 40:
  Marguerite Duff (budget chair — the allocation), Tommy Rourke (union — morale),
  Rev. Alma Mbeki-Shaw (community coalition — tips), Paul Varga (DA — whether cleared
  cases stay cleared).
- **Three candidates**: Royce Kettering (Safe Streets; corrupt, very pro-police, a
  brother-in-law in armoured vehicles), Dana Okonjo-Vale (Carrick Together; democratic
  socialist, wants to fix the city, openly critical of police and of you personally),
  Gordon Pell (Independent; aggressively boring, competent, reviews everything).
- Consequences land late: a story in a week where people were watching, in months
  (or never) where they were not; lawsuits six to ten weeks on; cleared cases can leak.

## The run layer *(1.3)*

- **Inheritance** (week 1): pick one of three starting doctrines; finished runs unlock
  more (eight in all).
- **Procurement** (weeks 1, 5, 9…): three contracts from sixteen (tiered by week);
  sign one or pass for $2,000. Patrol stock to start; plates, helmets, shotguns,
  gas, flashbangs, SMGs, short rifles, shields, launchers and the rest must be drafted.
  Military contracts move Kettering up and the coalition down.
- **Training programs** (weeks 2, 8, 14…): three on offer, one habit for the whole
  force when it ends, then in the academy curriculum for every hire.
- **Offers** (~40% of weeks): 14 from candidates, allies, two journalists (Nadia
  Ferrante of the Ledger, Hollis Crane of Channel 6) and community leaders.
- **Events** (~55% of weeks): 20 multiple-choice events, some gambles, some with
  delayed consequences, often naming an officer from the roster.
- **Run score** on election night: successes and arrests up; failures, deaths,
  civilian hits, excessive force and neglect down; +60 for keeping the office.

## Simulation (unchanged by 1.3)

Deterministic, seeded CQB autobattler on 0.25 m navigation, 12 maps, doors (open, shut,
locked; rammed, kicked, breached), penetration through walls and armour, judgment
before force under police rules (capability, opportunity, intent; misjudgment
probability from stress, night, distance, filming, hands), surrender and cuffing,
less-lethal tools, civilians with personalities, stress that rises in contact and
resets after a rally in quiet, and an incident record that feeds IA, the press and the
election. A head hit from any gun can kill; equipment helps.

## Look and sound *(1.21 supersedes the halftone comic-panel reference)*

Architectural floor-plan drafting on pale paper: plan-grey walls and furniture, title
blocks and stamps ("MODEL: COMPLETE / UNKNOWN: NONE"), and **one red ink** that marks
only where the plan touched a real room — blood, routes taken, findings. F2 turns red
ink off (all-grey proof), F3 turns gore off. The opening and fourteen shorts are drawn
in the same hand in Remotion (four ship wired in, ten are not yet called). Synthesised
weapon, door and radio effects; office and city ambience; no music yet.

## Engine and build

Godot 4.7.2 primary (4.4.1 supported), compatibility renderer, 1600×900 base. Ships as
**one self-contained Windows executable** with the game pack embedded (no installer,
no DLLs beside it). Headless harnesses in tiers via `tools/run_tests.sh`.
