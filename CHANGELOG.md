# The Violence: changelog

Newest first. The README covers the game as it stands; this file keeps the history.


## Unreleased — one trunk: the map UI, field orders and the cutscenes join the balance line (2026-11-11)

Stage A of the roadmap to release (v4). Three lines of work in three repositories are one
tree again; nothing from any of them was dropped.

- **Merged by content.** The balance line (crew houses, body armour by calibre, the patrol
  radio, Week Closed, 4–5 Nov) is the base. The map-UI line (`campaign-map-ui-2026-11-03`:
  no side menu, popups on the city map, 67 crayon icons, orders in the field, the
  bright-crayon pass) is merged three ways against the Stage 0 branch: 671 files taken as
  they were, 15 merged, four conflicts resolved by keeping both sides. The cutscene line
  brings **Hero** and **The Mayor**, and Jeremy and Fettick re-dated to 2001.
- **The patrol radio has its own card.** A radio on the HUD shows how many calls are still
  to come this week and opens it; so does a row on the week's card. An answer comes straight
  back to the radio with the next day's call. The week's report folds the calls nobody
  answered and nothing came of into one line; a call where someone was hurt keeps its own.
- **The operation camera.** The wheel, a middle- or right-drag and Home always moved the
  plan; nothing on screen said so. The run bar now has zoom out, zoom in, fit and *follow
  the action*, each squad's row has an eye that keeps the view on that squad (it closes in
  to twice the fitted view), W A S D move the view, and moving it yourself lets go.
  `scripts/view/op_camera.gd` holds the arithmetic; `tests/op_camera_test.gd` checks it.
- **Names**: George Carrick, **Julia Noussan** and **Bob Stevens**, as the story canon has
  them. Display text only; the ids and the election are unchanged until the Stage B recast.
- **Week Closed** is drawn in the bright crayon like the other shorts (it came with the
  merge), and the rendered walk now waits for it instead of clicking through it.
- **Tests**: `op_camera_test` joins the quick tier; `ops_ui_test` covers the radio card, the
  folded report and election night in the map UI; `ui_walk` follows a squad, zooms, fits,
  and opens the radio.

## Unreleased — Patrol encounters, the .22 and warrant helmets (2026-11-05)

- **Patrol encounters (owner request)**: one a day, seven a week, on a new Patrol radio card
  on the board. A pair of officers radios in what they are responding to, and the chief
  picks one of three: **Proceed** (no backup), **Proceed, backup en route** ($150 overtime) or
  **Wait for backup** ($200, safest for officers, but slow on urgent calls). Sixteen kinds:
  ten routine ones (traffic stops, noise, welfare checks, lost children...), three quarters
  of the draw, where proceeding alone is the right call; and six dangerous ones (bar fights,
  domestics, robberies, shots fired, a man in crisis with a knife, a man seen with a gun),
  where backup is. Officers can be hurt or killed, civilians hurt while police waited, a
  complaint can open an internal-affairs case, and the ward's trust moves. Unanswered calls
  are handled by the pair alone at the week's end. Patrols take nobody off the week's
  operations.
- **Armed encounters play out in the sim**: about 0.6 a week the suspect has a gun, and the
  encounter becomes a small hands-off operation: the pair; the backup arriving 75 s later on
  a phase line (en route) or alongside them (waited).
- **The .45 is medium calibre**: a soft vest reduces its harm instead of stopping it.
- **New: the .22 light pistol**, the least lethal handgun, low calibre, $300. Street
  suspects now carry it (two in ten), and it is in the pistols contract.
- **Helmets on every warrant**: officers serving a warrant wear a ballistic helmet,
  issued from the station whatever the armoury stocks.
- **Tests**: `patrol_test` (quick tier); `equip_test` gains the .22 gate and the .45 vest
  rule.
- **CI**: the Godot import step runs a second time if the importer crashes (it did on 4.7.2,
  failing a docs-only run).
- **Measured** on the 8-seed matrix: about 26 armed patrols a campaign go to the sim,
  0.08 officers killed each. Warrants fell to 0.06 killed per op, with the helmets. Gate 1
  misses 30 of 52. Patrol arrests inflate the run score by about 260, and patrol injuries add
  3–10 weeks a run under 12 fit officers. See EA_TASKS.


## Unreleased — Crew houses less deadly (2026-11-05)

- **Crew houses (owner decision)**: crews have 2–6 members instead of 3–8, and fewer carry
  rifles. Members now give up more often when officers outnumber them nearby.
- **Measured on 8 seeds × 4 policies**: officers killed per crew-house raid fell from 0.81
  to 0.49. Every policy loses fewer officers, keeps more of its roster fit and scores
  better; cautious went from −795 to −410. Gate 1 still misses 37 of 52 bands. Deaths and
  lethality are still about twice their bands. Details in `docs/EA_TASKS.md`, "option 1
  applied".
- **Body armour by calibre (owner decision)**: every officer wears a soft vest under any
  plates. Handgun and SMG rounds to the torso only stagger; most rifles and shotguns do 40%
  of their usual harm to a vested torso; battle and marksman rifles kill through the torso
  unless two plates take the round, and destroy both. Head and limb hits are unchanged.
  Measured: hostage and warrant operations lose slightly fewer officers, but crew houses
  lose more (0.49 → 0.65 per raid), because nearly all crew-house deaths are head shots and
  vested officers stay up long enough to take one. Gate 1 misses 35 of 52.
- **Deaths and lethality bands**: briefly re-set to 22 and 0.45, then restored to 8 and
  0.15 when the owner chose body armour instead.
- **Balance harness**: allies won back are now counted from week-end ally states. Before,
  allies regained through a desk reconciliation were never counted, so every matrix
  showed 0.

## Unreleased — Phase 1 diagnosis: the money miss is a death bill (2026-11-04)

- **The balance harness writes `money.csv`**: each week's ledger summed by kind of item
  (payroll, academy places, death benefits, courses, settlements, sweeps).
- **Finding**: on the CL3 matrix, crew-house raids kill 0.81 officers per raid, 70% of all
  officer deaths. Replacing the dead costs cautious about $306K a run, which is the whole of
  its deficit. Options for the owner in `docs/EA_TASKS.md`, "Stage 1: what the CL3
  reference says".
- **Gate R0**: the quick tier passes 25/25 on official Godot 4.4.1 too.

## Unreleased — CL3: a balance reference for the merged tree (2026-11-04)

- **New reference matrix**: 8 seeds × 4 policies on the merged tree, run in CI, in
  `tests/results/cl3-2026-11-04/balance/`; `balance_bands.json` points at it. It is the first
  measurement of P1.D–P1.H: the chief now survives the election on every run, military-first's
  worst debt is cut by about 60%, and 36 of 52 Gate 1 bands still miss (39 before). Roster,
  deaths and lethality have not moved. Every changed determinism case is tagged to a cause.
- **CI can run the shell scripts again**: the Windows copy had lost their executable bit.

## Unreleased — Week Closed: a recap when the week ends (2026-11-04)

- **Week Closed (S15)**: ending a week now plays a five-second crayon sheet before the new
  board: the week stamped CLOSED (ON THE RECORD if an officer or a civilian died), what
  the force answered and left, who was taken alive, who died or was hurt, how the account
  moved, and the Ledger's headline. A click skips it; Settings has its own switch.
- **The next-week strip counts the overdraft (B9)**: queued courses start anywhere above
  the overdraft limit, and the strip now says so, interest included.

## Unreleased — the Phase 1 and Stage 0 copies merged; the game starts again (2026-11-04)

- **One tree again.** The Phase 1 copy (money, allies, election, pacing, bands) and the
  Stage 0 copy (both engines, CL2, the bug fixes) are merged. Where both fixed the same bug,
  both fixes are kept: the wolf dwells in cover *and* its gate runs on 32 seeds; the shield
  no longer pins its carrier and its gate counts rounds through per round fired; a beanbag
  knockdown can be cuffed where he lies *and* giving up no longer licenses the shot. The
  Stage 0 copy's B5 and B6 are now B7 and B8. Table: `docs/EA_TASKS.md`, "Merge".
- **`ops_ui.gd` parses (B6)**: the hire button's red-ink confirmation was a multi-line lambda
  inside the button call, which Godot 4.7 refuses; nothing that loads the game's UI could
  start. Built as locals now. With it loading, the P1.D–P1.H screens run for the first time.

## Unreleased — Stage 0: both engines, and entries that wait for the stack (2026-11-03)

- **Verified on Godot 4.7.2 and 4.4.1** (official builds): the quick tier passes on both and
  the gates give identical numbers on the two engines.
- **A squad no longer goes in before it has stacked** (CL2): the 45 s fallback waits while
  anyone is still making progress towards the door (two-minute hard limit). Civic Plaza clears
  5–10% slower; gang raids lose fewer officers (0.30 → 0.25 per raid in the lethality test).
- **A room nobody can reach is reported as not cleared** instead of the squad waiting for ever.

## Unreleased — Stage 0: every open bug fixed (2026-11-03)

Every gate in the quick and full tiers passes on Godot 4.7.2. Details and numbers:
`docs/EA_TASKS.md`, "Stage 0 bug fixes".

- **Giving up no longer gets a man shot** (B3): the short "late shot" window after a
  surrender now belongs only to an officer whose trigger was already moving, not to every
  officer covering him.
- **A man who has given up is no longer treated as an enemy**: officers stop holding him
  as a target (one used to stare at a kneeling man while an armed one stood beside him),
  re-judge him as someone giving up, and go and cuff him even when he is out of sight.
- **Hand-to-hand is a struggle, not a killing** (B8): an officer who gets hold of an unarmed
  man he may not shoot wrestles him (12 s, better odds with help, either may be hurt) and
  the force goes on the record. An unarmed man who gets hold of an officer knocks him back
  instead of killing him. Armed fighters at contact range are unchanged.
- **No line, no less-lethal shot** (B7): beanbags and 40 mm rounds are not fired into walls;
  a round is held if he ducks out of the line; an officer finds a spot with a line, including
  stepping round when a 4 m minimum leaves no room straight back. Beanbag wind-up 0.4 s,
  the same as the 40 mm.
- **The shield no longer pins its carrier** (B2), and its gate measures rounds through per
  round fired at him.
- **The wolf gate runs on at least 32 seeds** (B1): it was under-sampled, not backwards.
- Side effect in gang raids: officers killed per operation 0.45 → 0.30.
- Test-range determinism: the shield case refreshed (same winner).

## Unreleased — orders in the field (2026-11-03)

A new live order while an operation runs: **move a squad to a room.**

- On the run card each squad has a row (state, and Resume when it holds on an order).
  Pick a squad, click a room on the plan.
- The squad (never a single officer) breaks off, goes there by the ordinary paths (doors,
  locked doors and whoever it meets on the way are handled as they always are),
  **consolidates** (posts on the room's doors and windows) and **holds**. It does not
  give the room up (HD15 fall-back is off while it holds on an order).
- It holds until you press **Resume** (it goes back to its own objective from where it
  stands, clearing from the nearest room still to clear) or pick **another room**.
- A held room counts as cleared. The room is ringed in red on the plan (dashed on the
  way, solid once held, tagged SQ1). Every order goes on the radio and the debrief
  timeline ("Chief: Squad 1 to the kitchen, consolidate and hold").
- Orders also override a phase line, are refused for rooms outside, and are given live
  only (an order from the rewind view goes live first).
- `tests/field_orders_test.gd` (quick tier): reach, hold, move again, resume, refusals,
  timeline, and the same orders at the same tick replay the same operation. `ui_walk`
  gives an order through the run card and a click on the plan.

## Unreleased — fewer words, more pictures (2026-11-03)

- **Crayon icons** (`scripts/ui/icons.gd`): 67 small hand-drawn SVGs in the opening's
  palette, rasterised at runtime. Every campaign button gets one from its wording, and
  shows one or two words (or none: Map, Open, Live, Pause, Menu); the full wording is the
  tooltip.
- **Chips instead of sentences**: the HUD (week, account, fit officers, IA cases), the
  week (fit, injured, committed, account), a call (type, ward trust, visibility, time
  pressure, status), the briefing, the station's account line (account, allocation,
  payroll, morale, cases) and next week's roster outlook are icon-and-number chips with
  the explanation in the tooltip.
- **The ? on every card** shows or hides the explanation lines (tips, notes, the outgoing
  chief's advice). They start hidden.
- **Police HQ** is five picture doors. The desk and the call list are one row per item:
  a picture, a few words, an arrow.
- Hire and Sign read `Hire  $7,640  ·  +$1,200/wk`; the run's Skip reads `Skip 27/60 s`.

## Unreleased — the map is the campaign (2026-11-03)

The right-hand side menu is gone. The campaign is played on the city map, and every choice
comes up as a card on top of it.

- **Calls open from their pins.** Click a red pin for that call's card (site, ward, threat,
  who is free) and *Brief and plan* from there; the card steps to the next call.
- **Landmarks are the department's doors**, drawn on the map at their canonical buildings:
  **Police HQ** (Carrick Street Station) opens roster, budget, internal affairs, armoury
  and programs, and the campaign file; **City Hall** opens the politics; **the Ledger**
  opens the week.
- **The week** (desk, results, story, front page, a list of the calls) opens by itself
  when a week starts or something comes back, and again from the Ledger or the HUD.
- **A crayon HUD** (top right): week, account (red when frozen), End week (disabled with
  its reason while the desk is unsettled), The week, Menu.
- **Operations have no side panel either.** The floor plan fills the screen. A bar along
  the bottom carries *Map*, the three steps (Briefing, Force, Orders), *Suggest* and *RUN*;
  each step opens as a popup above the bar, at most about half the window, and pressing
  the step again folds it away. The live run's controls (pause, speed, rewind, skip,
  abort) are the same bar, the radio and squads a popup; the debrief is a popup with
  *Back to the map* in the bar.
- **Every card** can be dragged by its title bar, folded to the bar (– or double-click)
  and closed (×, a step back). It sizes to its content and remembers where you put it.
- `ui_walk` now clicks pins and landmarks through the map's own hit test.

## Unreleased — one look, all the way through (2026-11-03)

The game had three visual languages: the bright child's crayon of the opening scenes, the
grey technical stock of the campaign shorts, and a muted mix in the game itself. Everything
now follows the opening, as your 29 Oct direction asked (brighter, more childish).

- **Shorts**: cream paper, sky and sun, notebook-paper panels, the opening's palette. Two
  shorts (officer down, the allocation) had never drawn: `String(int)` aborted every frame.
- **Title**: Port Carrick at night in a child's colours (the opening's last frame) instead
  of grey-and-orange smog; the footer has its own paper scrap so it can be read.
- **Board**: the city map is crayon (each ward its own wax, a scribbled river, red pins).
- **Management screens sit over the city**, not the last operation's map (P3.A1; now a
  failing check in `ui_walk` and `ops_ui_test` if it regresses).
- **Operations**: indigo crayon fog and a lilac night page instead of near-black and grey;
  plans in pastel rooms on green by day, saturated rooms by night.
- **People and props**: police in the opening's royal blue, suspects in bright earth
  colours, peach skin; brick, umber and moss brightened; sprites regenerated and re-baked.
- **UI and the ledger of the dead**: cream and white notebook paper, sun-yellow selection,
  crayon-lettered header.
- **Names**: George Carrick and Alicia Beddrow (Port Carrick Together), as the story canon
  and the opening's posters have them; Gordon Pell unchanged. Display text only.
- Before/after screenshots: `tests/results/visual-2026-11-03/`.

## Unreleased — EA_TASKS Phase 1 close-out: the three known bugs, the pace, the chief, the bands (2026-11-02)

- **Wolf brain holds cover (B1)**: a lone fighter now dwells in the cover it has
  (`WOLF_DWELL`, 2.5 s) and only bounds where the route itself is hidden
  (`WOLF_MAX_EXPOSURE`, one of four samples), instead of re-planning every tick and
  walking open ground. The 0.A full tier's finding — 0.19 of an unseen fight hidden with
  the brain on against 0.28 with it off — was the brain being worse than nothing.
- **The shield gate measures the ratio, not the tally (B2)**: `equip_test` counted rounds
  that reached the officer, so the unshielded officer was killed early and the shielded
  one survived the window and accrued more (1.02 vs 0.69). It now measures the share of
  rounds arriving at his body that got through, the shield's stops being the other half
  of the denominator.
- **A beanbag knockdown can be cuffed where he lies (B3)**: `world.cuffable()` accepts a
  downed suspect, the operation waits up to 30 s for the arrest under police rules, and
  the arrest counts. Before, a beanbag round ended the operation with nobody arrested,
  which is why the tool measured the less-lethal order as slower (224 s against 208).
- **Election night says why (P1.F3)**: the ending lists the run score as rows — each
  movement, its size and its reason — and the election row states the clean-record test
  it passed or missed, instead of one grey line of plus and minus.
- **Contact-aware fast-forward by default (P1.G1)**, **“Skip to the report” (P1.G2)** and
  **wall time per operation (P1.G3)**: quiet stretches run at three times the speed asked
  for (capped at 8×), contact returns to 1×, and 1× asked for stays 1×; after 60 simulated
  seconds of quiet the run can step headless to the end and open the debrief, still
  deterministic. `op_test` prints a `TIMING` line and carries the numbers in `--json`; the
  game prints `RUNCLOCK` under `--perf`.
- **The chief test (P1.H1)**: `tools/chief_compare.py` plays `--chief=sensible` against
  `--chief=manual` on matched seeds and gates on the manual chief being ahead on the run
  score in 70% of seeds; CI grew `tier=chief`, shardable with `--first` and joined with
  `--merge`. `op_test`'s JSON carries `run_score` for any campaign, not just the balance
  harness's.
- **Determinism rebaselined in the open (P1.I1)** and **the balance bands assert (P1.I2)**:
  CI `tier=determinism` reruns every seeded case, annotates each change, writes the fixture
  and commits it; `tests/balance_bands.json` is `"enforce": true`, so a full matrix fails
  the tier on a missed band, the quick tier's two-week smoke is never judged, and
  `--report-only` reproduces an experiment without judging it.
- **Fixed: `politics.gd` did not load at all.** Nine constants the R1.D–P1.F code used
  (`SURPLUS_AMOUNT`, `SURPLUS_COOLDOWN`, `SURPLUS_STANDING`, `OVERDRAFT_STANDING_COST`,
  `FROZEN_STANDING_COST`, `SWEEP_EVERY`, `SWEEP_FLOOR`, `SWEEP_SHARE`, `SWEEP_CAP`) were
  never declared, and `_poll()` took two arguments while ten call sites passed three. Both
  are parse errors, so every campaign run in CI came back without its record and the
  balance matrix reported “Invalid access to property or key 'ops'” rather than the real
  fault. The numbers are the ones the P1.D/P1.F entries below and `tests/politics_test.gd`
  describe. Two more faults of the same shape were found in the crayon shorts (a bare
  `SLATE`, a bare `MOSS`); neither script is loaded by a headless test, so nothing had said
  so before.
- **`tools/gd_arity_check.py`**, new and wired into the static CI job: the call-arity and
  undeclared-name check that `gd47_check` (structure) and `gdparse` (syntax) cannot do, and
  that would have caught all of the above. 147 files, no findings.

## Unreleased — native crayon campaign shorts (2026-11-02)

- Replaced all fourteen runtime Remotion short videos with native Godot drawings in `scripts/view/crayon_short.gd`: week card, situation file, route plan, staging, threshold, officer down, debrief, press, case, ally standing, election, end of watch, allocation, and course. Each keeps its distinct composition, animation beats, and campaign meaning in the crayon line language.
- The existing shorts manifest remains the source for duration, defaults, prop values, and slot text. `scripts/ui/shorts.gd` now sequences native scenes, preserves callbacks/skips, and cues the game's ambience and synthesised effects. Legacy `.ogv` files are retained as source artifacts but no longer loaded at runtime; Windows and Linux export presets omit them from shipped builds.
- Added short-key capture to the displayed cutscene harness and CI workflow, plus `tools/import_godot_project.sh` and `docs/GODOT_SETUP.md` for the primary Godot 4.7.2 setup.

## Unreleased — EA_TASKS P1.D–P1.F: money curve, allies that come back, the election (2026-11-02)

- **Council overdraft (P1.D2)**: the account may go to −$25,000 before anything freezes. Below
  $0 it pays 2% weekly interest (department) and costs the budget chair standing every week
  (politics); only below the limit are hiring, training and new kit frozen. Contracts,
  programs and offers may be bought into the overdraft, but not past the limit.
- **Lawsuits settle in four weekly instalments** (P1.D3), each costing the council 3 standing
  with its cause logged; the four-week forecast shows each instalment in its own week.
- **Hire, course and contract buttons price themselves into the four-week forecast**
  ("week 6 goes to −$2,100") and ask for confirmation before a negative week (P1.D1).
- **Late-game sinks (P1.D4)**: an armoured rescue vehicle (a capital item with the military
  tag; on a gang raid it carries the first officer downed out alive), a training-range offer
  (courses 25% cheaper, a week faster), a union contract (morale floor +10 for good), tier-3
  training programs repriced ×1.5 from week 20, a "return $5,000 of surplus" offer (+6 Duff
  standing, 4-week cooldown), and an automatic quarterly council sweep of half of everything
  above $25,000 (capped at $30,000).
- **The starting reserve is a tuning constant** (P1.D5): `Courses.reserve`, shipped $25,000,
  overridable per run by the balance harness ($25K vs $35K A/B).
- **Every ally and poll movement carries a cause** (P1.E1, P1.F1): `politics.ally_log` /
  `poll_log`, saved with the campaign, read back on the Carrick Ledger's week page ("what
  moved the numbers this week"). The balance harness now also writes `allies.csv`, and
  `tools/roster_report.py` charts allies lost at week 40 and won back, per policy.
- **Reconciliation offers (P1.E2)**: a lost ally will take the department back for $15,000 and
  enough standing to cross the regain line — at most one offer every 4 weeks, once per ally
  per run; affordability runs to the overdraft limit.
- **Drift tuning (P1.E3)**: a quiet week holds every non-lost ally's standing (+1); crowd
  kills cost the council 8 (was 10), story coalitions 3 (was 4); a deficit costs more below
  the overdraft limit than above it. Being out of sight never drifts an ally down by itself.
- **The election bonus is conditional on the record (P1.F2)**: keeping office pays +60 only
  on a clean record (≤2 officers killed, ≤6 civilians killed, ≤6 force findings), else +20.
- Tests: `dept_test` (overdraft boundaries, weekly interest, reserve override, forecast_after),
  `politics_test` (instalments, sweep + hand surplus return, cause log, quiet-week hold),
  `rogue_test` P1.D4.e (an effect assertion per new sink, the reconcile offer, F2),
  `rogue_balance_test` (writes `allies.csv`; flags a minimal run ending ≥$100K unspent).
  Validation in this session was static only — no engine in the sandbox: `gd47_check` clean
  on 143 files, `gdparse` clean on all of `scripts/ tests/ tools/` (including pre-existing
  parse damage in `ui.gd` and `orders_test.gd`, now repaired). Engine harness runs are CI-only.
  *Corrected 2026-11-02:* `gdparse` parses; it does not resolve names, and `politics.gd` was
  unloadable in this whole batch (undeclared constants, a three-argument call to a two-argument
  `_poll`). See the Phase 1 close-out entry above; `tools/gd_arity_check.py` now checks it.

## Unreleased — EA_TASKS cycle 1.C: the roster bleed (2026-10-29)

- **Where officers die**: the balance harness now logs every operation and week
  (`ops.csv`, `weeks.csv`); `tools/roster_report.py`. Gang raids are three quarters of
  officer deaths, and one in two of all deaths is a gang raid at the Warehouse.
- **The board shows next week's fit officers** against what this week's calls want, red below 12.
- **Emergency lateral**: an experienced officer on duty this week, at twice a lateral's
  signing cost, one a week. Hire buttons say what they add to the weekly payroll.
- **Standing order "keep N on the books"** on the Roster: the academy takes recruits
  towards N while the forecast, counting recent overtime, stays in the black.
- **Suggest a plan proposes the Entry kit on a gang raid**, priced on the Force tab and
  bought when the operation starts; "keep their current kit" declines it. In tested
  raids it costs about four officers in ten fewer lives than patrol kit.
- **CI**: a cancelled balance run never commits; result commits survive a moved or
  deleted branch; each shard reports what it left as annotations.
- **Trailer prototypes** (Arena) merged in: `trailers/`, excluded from the game.
## Unreleased — UI fix: the test range panel scrolls (2026-10-30)

The test range's setup panel is 1,100 px tall against a 900 px layout, so the last third
(seed, civilians, police rules, doors, Team A department, body cameras and the RUN button) sat
off the bottom of the screen with no way to reach it. The whole right-hand panel now lives in a
scroll container, so it scrolls at any window size. The scrollbars across the game (theme-wide)
also get a visible track and a thicker grabber; before they were nearly invisible.

## Unreleased — EA_TASKS cycle 1.B: the crowd cliff (2026-10-29)

At a public event, a department with traumatised officers used to shoot its way through
the crowd: in 60 quiet events at trauma 14, police struck 413 people and killed 358. Now
they strike 1 and kill none. Measured by the new CI crowd tier; tables in
`tests/results/cycle-1B/`, the full account in `docs/EA_TASKS.md` §1.B.

- **Calm is measured from the officer's own floor** (P1.B2). Trauma and low morale set a
  stress floor; above trauma ≈ 13 an officer could never count as calm, so he re-judged
  every face he had already cleared, and the first mistake started the cascade.
- **Check fire** (P1.B3): a police round that strikes a bystander stops that team for
  20 s — every wrong verdict on a bystander is dropped and nobody in the crowd can be
  newly misjudged while it lasts.
- **Police at events start relaxed** and **don't raise a weapon at people they have not
  judged a threat** (found with `tests/crowd_trace.gd`, P1.B4): the crowd used to see
  guns pointed at face after face, run, and running people get misjudged.
- **The attack response**: bystanders who see an attacker's gun cue nearby officers; an
  officer who has judged the attacker a threat keeps him over bystanders running past;
  and officers on post go to the gunfire instead of holding their posts for the rest of
  the event while he shoots out of their sight. Attackers are stopped as often as before
  and hit about as many people (within noise), but a median 3–5 s later — the price of the
  relaxed posture. The posture is now an owner's decision (P1.B6).
- **Briefing**: Suggest a plan still prefers officers under trauma 12 for crowd duty, and
  now says so and why (P1.B5).
- **Tools**: `event_probe.gd` counts distinct people struck and attacker outcomes
  (`--attack`, `--json`); `tools/crowd_sweep.py`; the `crowd` dispatch tier (18 jobs,
  ~12 minutes). A balance dispatch can name its results folder (`results=`).
- **The 1.A baseline has run**: 20 seeds × 4 policies, five shards, 0 broken runs,
  committed to `tests/results/cycle-1A/baseline/` on branch `baseline-1A`.
- **B4 named and fixed**: `ui_walk` runs with `--verbose`, so a resource leaked at exit is
  named in the annotation; the first recurrence named the office ambience
  (`amb_office.wav`), still playing when the walk freed the game. The walk now stops
  every audio player and waits a few frames before freeing.

## Unreleased — the 1.A baseline can finish; the walk's exit (2026-10-29)

- **The 20-seed balance baseline is sharded** (EA_TASKS P1.A4). A GitHub-hosted job stops at 6 hours, and twenty seeds in one job is 7–11 h, so the dispatched baseline would always have been killed. `balance-plan` → `balance` (one job per four seeds) → `balance-merge`. `rogue_balance_test.gd --merge=DIR1,DIR2 --seeds=N --first=1001` combines shard directories into the same `report.md` and `summary.json` a single process writes, and reports any seed × policy no shard produced, and anything a shard's own summary lists, as broken. Verified: merged two one-seed shards = the two-seed report apart from the wall clock; a missing shard exits 1. `actionlint` clean.
- **`ui_walk` releases the game's static caches before quitting** (EA_TASKS B4): an intermittent `resources still in use at exit` failed the suite once each on two CI runs and never locally. Unproven fix; the annotations will name a recurrence.

## Unreleased — EA_TASKS cycle 1.A: the balance harness (2026-10-28)

The measurement every later Phase 1 cycle is judged by. Four policies play whole
campaigns, one process per run, and the result is a table, a JSON summary and the Gate 1
bands — report-only until P1.I.

- **`tests/policies.gd`** (P1.A1): the four policies as code — **cautious**, **minimal**,
  **military-first**, **accept-all**. Each sets the inheritance, the contracts and
  programs it signs (by tag), how it answers offers and events, whom it hires, which
  courses it sends officers on, how it decides internal-affairs cases, whether a plan may
  buy kit, and which calls it takes. Every answer comes from the desk it was dealt, never
  from a random number, and the desk is settled **before the first operation** in the
  interface's own order — the two things `op_test` did differently (random desk, answered
  after the week's operations, suggested kit always issued). Policies run on current kit
  unless they are the ones that buy it.
- **`tests/rogue_balance_test.gd`** (P1.A2): `--seeds=20 --policy=all --weeks=40
  --jobs=4`. One process per seed × policy, each with its own `XDG_DATA_HOME` so no run
  can see another's save or legacy file; a per-run timeout and kill; `report.md`,
  `summary.json` and one `run-<seed>-<policy>.json` per run (same shape as
  `op_test --json`, so `tools/campaign_report.py` reads them too). Exit 1 for a hung
  operation, a run that never held its election, a missing or unreadable JSON, or — with
  `--enforce` — a missed band. `--smoke` is the quick-tier shakedown.
- **`tests/balance_bands.json`** (P1.A3): the Gate 1 thresholds, thirteen of them, each
  with its aggregation and a written reason, and each compared against every policy over
  the whole matrix. **`"status": "report-only"`, `"enforce": false`** — a miss is printed,
  not enforced, until P1.I. The numbers are provisional and are the owner's call
  (roadmap §8.4); the file starts from the 28 Oct playtest's own figures.
- **`tests/policies_test.gd`** (quick tier): the policy layer without the simulation —
  determinism under a fixed seed, desk-before-operations, no blocking draft left, the
  policies differing where they should (minimal signs nothing, cautious never signs
  military hardware), the call plan's cap and priority, kit issue, a short account, and
  the bands file's shape.
- **CI**: `rogue_balance_test --smoke` joins the quick tier, and a new **balance** job
  runs the matrix — on demand (`tier=balance`, `seeds=N`), weekly (8 seeds), and as a
  two-seed pilot on every push to an `arena/*` branch, uploading `build/balance/` as an
  artifact and **committing `report.md` + `summary.json` to `tests/results/cycle-1A/`**
  (`pilot/` for a pilot, `baseline/` for a dispatch) so the evidence outlives the run.
- **First measurement** (2 seeds × 4 policies, 8 runs, 2246–4069 s across four pilots, 0
  broken every time): the shape is
  the playtest's. Fit collapses on every policy (lowest 0–8, floor 10); `accept-all`
  bankrupts itself (−$302k at the low, 20–33 civilians killed); `military-first` has the
  best lethality (0.18 killed per operation on average, 0.21 at its worst) against a band of
  0.15; no policy wins an ally back; every pilot's table matched the others to the decimal. 36 of 52 band checks miss, and none is enforced — report-only until P1.I.
  A 40-week run is 21–34 minutes, so the 20-seed baseline is 7–11 h.
- The 20-seed baseline (P1.A4) is ~7 h of CPU and is one dispatch away; the two-seed
  pilot in `tests/results/cycle-1A/pilot/` is labelled as a pilot, not a baseline.

## Unreleased — EA_TASKS cycle 0.D: version, licence, hygiene (2026-10-28)

Gate 0 closed. The three things it was waiting on, decided and implemented.

- **The version line is 1.3.x = Early Access, 2.0 = the 1.0 release** (P0.D1). `Version.VALUE`
  is **1.3.0** and a new `Version.CHANNEL` says "Early Access"; `tools/sync_version.py`
  wrote 1.3.0 / Windows 1.3.0.0 into `project.godot` and `export_presets.cfg`. The title
  plate now carries a red **EARLY ACCESS** stamp with `V1.3.0` beside it, drawn from
  `Version.CHANNEL` rather than a literal, so the label moves with the version. The Windows
  resource fallback in `tools/patch_rc.py` is gone: a build that cannot read
  `scripts/version.gd` stops instead of shipping an exe stamped with a stale number.
- **`LICENSE`: proprietary, all rights reserved** (P0.D2). Reading, forking for review and
  quoting in reviews, criticism and reporting are allowed; redistribution, commercial use,
  derivative works and reuse of the art, audio, text or city data are not. Contributions
  sent as pull requests are licensed to the project.
- **`THIRD_PARTY_NOTICES`** (P0.D2): the Godot Engine MIT text, the Patrick Hand OFL 1.1
  pointer and text file, Remotion and its render-time fonts (Courier Prime, Oswald, Open
  Sans — OFL) and React (MIT), and the Python asset tools (numpy/scipy BSD, Pillow
  MIT-CMU). Both files are added to `include_filter` in **every** export preset, so a
  shipped build carries them, and the credits screen now names the channel and the
  development state, the cutscene tooling, the licence line and the notices.
- **Remotion: the free licence applies** (P0.D3). It is free for an individual, a team of
  up to three people, or a non-profit; the project qualifies, so no company licence is
  required and the openers and shorts are **not** re-rendered (P4.C1 keeps them as they
  are). The decision and the version (4.0.537) are recorded in the notices, together with
  the trigger for revisiting it: more than three people on the project, a publisher, or a
  company formed around it.
- **The user directory is fixed** (P0.D4): `application/config/use_custom_user_dir=true`
  with `custom_user_dir_name="TheViolence"`, decided before any cloud-save path exists, so
  renaming the game can never move a save. `Settings.migrate()` now carries files from
  both folders earlier builds wrote (`The Violence - Vertical Slice`, then `The Violence`)
  into the fixed one, never over an existing file, and now carries `legacy.json` too — the
  unlocked doctrines used to stay behind in the old folder.
- **The Windows and Linux preset metadata says who made it**: company "Ambidgen",
  copyright "Copyright (c) 2026 Ambidgen. All rights reserved."
- **`improvements_test` guards all of it**: the version is on the 1.3 line and `CHANNEL`
  names it, the title and credits still print the channel, the notices and the licence;
  `project.godot`'s user-directory key matches `Settings.USER_DIR`; the legacy folders are
  still listed and `legacy.json` still carried; both licence files exist and **every**
  export preset ships them.
- Evidence: `tests/results/cycle-0D/`.

## Unreleased — EA_TASKS cycle 0.C: duplicate procurement charge (2026-10-28)

- **A contract can no longer be signed for kit the armoury already holds** (P0.C1–C3).
  The 28 Oct playtest reproduced the charge: the week-1 procurement draft is dealt
  before the inheritance is chosen, so *Plate carriers on day one* plus the plate
  contract charged **$6,000** and added nothing (`contracts` became
  `["plates", "plates"]`). Six of twelve seeds dealt it. The deal-time filter that
  skips a contract whose every item is stocked already existed, but it runs before the
  stocking that makes the card redundant.
- **`contract_stocked()`** is the one predicate now: `_open_contracts()` uses it (C1),
  `pick()` refuses with a line and no charge while leaving the draft open (C3), and
  `_revalidate_drafts()` uses it.
- **Drafts are re-validated after every stocking change** (C2): a doctrine pick that
  stocks the armoury, a signed contract, or a free contract arriving from an offer or
  event. A redundant card is replaced from the **same tier**; if nothing is left to
  offer the card is dropped, and a draft with no cards is dropped too. The desk says so
  in the answer's lines and in the campaign file.
- **The replacement has its own RNG stream** (`draft_rng`, seeded from the run seed and
  saved as `draft_rng_state`). The desk's `rng` does not move, so a seed deals the same
  offers, events and later drafts whether or not a card was re-dealt. A save written
  before this change restores with the replacement stream restarted from its seed, which
  only affects which alternative a stale draft receives.
- **Load repairs old saves**: `from_data()` re-validates the drafts it restores, so a run
  saved between the inheritance and the contract no longer shows a redundant card.
- **`rogue_test` covers it** (C4): seeds 1–12 × every inheritance × every contract offered
  afterwards must produce **0 wasted purchases** and charge exactly the contract's cost;
  plus the guard, the mid-week free military contract, and an assertion that a re-dealt
  card consumes only the replacement stream while the desk's rng is untouched. The 28 Oct
  `dup_probe.gd` is folded in (it lives in `tests/results/playtest-2026-10-28-campaign/`).
- The board's procurement line reads its card count instead of saying "three contracts",
  and a card the armoury already covers no longer appears there at all.
- Evidence: `tests/results/cycle-0C/`.

## Unreleased — EA_TASKS cycle 0.B: playtest tooling in the tree (2026-10-28)

- **`tools/playtest.sh`: one command for a campaign playtest.** With no arguments it repeats the 28 Oct playtest: three 40-week roguelike runs (seed 1001 `--hire --train`, 2002 minimal, 3003 `--hire`) in parallel, each with its own `user://`, then the rendered walk, then the table. `--weeks=`, `--runs="SEED:opts ..."`, `--no-walk`, `--resolution=WxH`, `--out=`. Writes `campaign-seed<N>.json/.log`, `walk/`, `report.md`, `report.csv`; exits 1 if a run or the walk failed (P0.B).
- **`tests/ui_walk.gd`: the rendered walk as a harness** (P0.B1). Drives the real buttons from the title through the desk, a briefing, a live operation at 20×, the debrief, End week and six management screens, with 30-odd checks (a needed button missing or disabled, a briefing that spends money, an operation that never ends, a week that does not advance, a screen that will not close, a control off the viewport). `--steps=`, `--seed=`, `--out=`. Without a display it runs every step and check and skips the screenshots, so it joins the **quick tier**. Known problems for later cycles are reported as `KNOWN` (today: the first call's disabled button explains itself only in a tooltip, P3.B1; management screens sit over the last tactical map, P3.A1). It records the window size, the layout size and the scale the text is drawn at: the project stretches canvas items, so at 1280×720 nothing overflows but every word is drawn at ×0.80.
- **`op_test.gd --json=path`** (P0.B3): every week's snapshot (account, morale, fit, academy, injured, dead, trust, each ally's standing and loss, polls), every operation (result, score, sim seconds, officers killed and down, civilians hit and killed, misjudgments, findings), the run's totals, the political record, the election and the run score. The printed log is unchanged apart from the next item; the seeded results are identical (weeks 1–12 of seed 1001 match the 28 Oct run).
- **op_test showed only the ally losses that happened at the end of a week.** A loss caused by an operation's aftermath or a desk answer was real in the game but never printed, so the 28 Oct report said Tommy Rourke was "at 0 by week 27" when the union was lost in **week 10** (seed 1001). Both paths now print their `LOST:` and `Won back:` lines and record them in the JSON.
- **`tools/campaign_report.py`** (P0.B2): the playtest table from JSON runs or plain op_test logs, plus figures the 28 Oct table lacked (weeks with fewer than 12 fit, weeks below $0 in weeks 1–12, first loss per ally including silent ones). `--csv`, `--check` (exit 1 if a run hung or never held its election). Run on the three 28 Oct logs it reproduces every number in that report.
- Rendered walks pass Godot `--audio-driver Dummy` (a machine without a sound card otherwise logs an engine `ERROR:`); the walk frees the game before quitting (a held texture otherwise logged "resources still in use").

## Unreleased — EA_TASKS cycle 0.A: harnesses that fail honestly (2026-10-28)

- **Every harness sets an exit code** (P0.A1). Gates exit 1 on a failed gate: `civ_test` (patrol vs tactical), `equip_test` (any item), `maps_test`/`nav_door_test` (any problem). Diagnostics exit 1 on a broken invariant: `op_test` (an operation that hits the step guard, a 40-week run that never holds its election, or no operation at all), `stall_test` (any stalled match), `fuzz_test` (a bad habit never exercised). `lethality`, `hold`, `sim`, `perf`, `duel_probe`, `trace` and `playtest` exit 1 only if they measured nothing.
- **Runner** (`tools/run_tests.sh`): trusts exit codes and no longer scans logs for the word FAIL; the engine-error scan now covers every suite, including the former "note" probes that could never fail. `TIMEOUT_SCALE` defaults to 2 on two cores or fewer (P0.A2); `orders_test` gets 900 s. New `xfail` mark: `determinism_test` reports `KNOWN` with its reason (fixture predates the 1.3 simulation changes, 22 of 35 cases differ) and an unexpected pass reports `XPASS` and fails the tier (P0.A4). A leading `~` in `GODOT` is expanded.
- **CI activated** (P0.A3): `tools/ci/ci.yml` moved to `.github/workflows/ci.yml`. It passed `GODOT=~/godot/godot`, which the runner never expanded, so every headless job would have stopped at "no Godot binary"; it now passes `$HOME`. The static job also runs the runner's own tests.
- `tests/test_runner.py`: six new cases (exit code over log text, former note suites failing on exit code and on script errors, xfail, xpass serial and parallel, `~` expansion); all six fail against the previous runner.
- **A known failure must fail the known way.** `KNOWN` now requires the suite's signature in the log (for `determinism_test`, `FAIL: N case(s) changed`) and no engine error; a crash, a missing fixture or a script error in that suite is an ordinary `FAIL`. New runner test `test_xfail_crash_is_not_the_known_failure` (fails, 4 subtests, with the signature check removed).
- `perf.gd` and `trace.gd` now dispose their `World`. Undisposed, they ended with `ERROR: 9 resources still in use at exit`; harmless while they were "note" suites, but the engine-error scan now covers every suite and would have failed both on every soak run.
- **Playtest of the cycle:** every one of the 14 changed harnesses was run as-is and with its check deliberately broken (`tests/results/cycle-0A/mutation.log`): all 14 exit 1 when broken. Quick tier on Godot 4.7.2: 16/16 pass.

## Unreleased (1.3 candidate) — story mode as a roguelike; Endless Battle removed

**The run layer** (`scripts/campaign/rogue.gd`, plan in `docs/ROGUELIKE_PLAN.md`). Every
story begun from the title is a run: one seed, forty weeks, one ironman file. A **Desk**
card on the board holds what the run asks of the chief:

- **Inheritance** (week 1): three starting doctrines from eight; finished runs unlock more
  (`user://legacy.json`).
- **Procurement** (weeks 1, 5, 9…): the armoury starts with patrol stock; three contracts
  from sixteen, tiered by week, sign one or pass for $2,000. `Equipment.armory` gates
  `validate()`, so locked items fall back to stocked ones in the kit editor, squad kits
  and Suggest a plan alike; the kit editor marks them "(locked)". Military contracts move
  Kettering up and the coalition down; restraint contracts the reverse.
- **Training programs** (weeks 2, 8, 14…): three on offer, weighted towards the habits the
  department's IA findings say it lacks; one habit for the whole force when it ends, then
  in `Department.curriculum` for every hire. Three special programs (crisis intervention,
  peer support, firearms in-service).
- **Offers** (~40% of weeks, 14 in all) from the candidates, the allies, two reporters and
  community leaders; accept or let them lapse.
- **Events** (~55% of weeks, 20 in all) with two to four responses, some gambles, some
  landing weeks later, most naming an officer from the roster. End week is disabled until
  drafts and events are settled.
- **Run score** on election night, written to the legacy file.

The classic campaign (`Campaign.start(seed)`) is untouched and is what the determinism and
balance harnesses replay; `Campaign.start(seed, true)` is a run. New harness
`tests/rogue_test.gd` (quick tier); `op_test.gd --rogue` plays a 40-week run with the desk
answered at random.

**Endless Battle removed**: `scripts/city/`, `scripts/city_main.gd`, `scenes/city.tscn`, the
six city-only views, the four city harnesses, the title and test-range entries, and the
ward-pressure link (`Campaign.pressure*`, the `pressure` paths in `Situations`). Boards
without a watched city were already the unlinked ones, so determinism is unchanged.

**Fixed from the 2026-10-26 engine playtest**

- A civilian struck by three police rounds was counted as three civilians hit — in the
  city's record ("3 civilians hit"), the Ledger ("Bystanders shot"), the run of polls and
  the lawsuit (three times $10,000). `Politics.on_operation` now counts people.
- Scrolling the side panel past its end also zoomed the map behind it.
- A first launch saved a stand-in campaign, so the title offered to "continue" a story
  nobody had begun. The stand-in is no longer saved.
- An arrest objective whose suspect had given up but was never cuffed read "still at
  large"; it now says so.
- The IA "Review" button was disabled without saying why (the officer was committed to an
  operation that week); the tooltip now gives the reason.
- The kit editor's drop-downs sized themselves to their longest item and pushed the side
  panel off the screen.
- **Officers past trauma 12 misjudged crowds.** On post at a quiet rally, two officers at
  trauma 10 hit nobody in four events; at trauma 14 they killed nineteen
  (`tests/event_probe.gd`). Suggest a plan now keeps them off crowd duty while anyone
  else is free, and the Force screen flags them. The cliff itself is still in the
  simulation (see `docs/PLAYTEST_2026-10-27.md`, recommendation 1). A 40-week run of the
  same seed went from 11 rallies with crowd deaths to none.
- Brief and plan is held until the week-1 inheritance is chosen, so the first operation
  runs with the armoury the player picked.

## Unreleased — a general debug pass

A tree-wide sweep for the classes of fault this project has already been bitten by,
run without an engine (the 4.7.2 build in this sandbox had not finished linking when
the pass ended): a cross-script symbol and arity check over all 118 GDScript files
(654 `Alias.func(...)` calls and every preload, no missing member and no wrong
argument count), duplicate dictionary keys, orphaned `res://` paths, duplicate
`class_name`s, doubled words in player text, `to_data`/`from_data` key symmetry, and
a re-audit of the 89 habit ids and every equipment id the code names. The asset pipeline was re-run:
`tools/make_placeholders.py` reproduces all 123 SVGs byte-for-byte.

What it found:

- **`Politics.from_data` was the last save reader that could still throw on a save
  that parses but lost a key** — `d["allies"][a]["standing"]`, `press[i]["week"]`,
  `polls[c]` and `record[k]` all indexed straight into file data, and a trust list
  with a junk entry ran `int({})`. It runs on the boot path, one layer under the
  `Department.from_data` the 4.7.2 pass hardened, so an incomplete save took the
  game down before the title screen instead of falling back to the `.bak`. Every read
  is now typed and defaulted, `standing()`/`lost()` answer for an ally the save does
  not mention, `week_press()` skips malformed entries, and a short trust list is
  filled from the ward table so City Hall cannot index nothing. `godot472_test`
  covers seven damaged saves plus the campaign wrapper that reaches it.
- **`tests/godot472_test.gd` never called `_test_nav_without_build()`.** The file's
  own header, the README and `RELEASE_READINESS.md` all cite the navigator's unbuilt
  fallback as one of the three things that regression locks down; the function was
  defined and never invoked. It is in `_init()` now.
- **`tests/_check.gd` printed `FAILED` and exited 0**, so the cheapest gate in the
  tree could not fail a build (the release-readiness pass counted it among the 18
  harnesses that cannot). It now counts failures, exits 1, prints how many scripts
  it scanned, reports a directory it cannot open, and scans `tests/` and `tools/`
  as well as `scripts/` — the tier claims to load *every* script.
- **`tools/patch_rc.py` wrote a file named after any argument it did not recognise.**
  `patch_rc.py --help` created a file called `--help` in the working directory (it
  did, in this session), and the release script's typo would have become a stray
  resource script. It now parses arguments, has `--help`, refuses a path that is not
  a `godot_res.rc`, and refuses a `detect.py` that is not the Windows one. Its
  version was also a hardcoded `1.2.1.0` next to the canonical
  `scripts/version.gd`; it is read from there now, and the four-part conversion no
  longer eats a real zero (`rstrip(",0")` turned a 1.2.10.0 build into 1,2,1,0).
- **`scripts/ui/shorts.gd` laid its slot text out against the viewport's visible
  rect**, which is in window pixels, while the slots are normalised to the canvas
  grid the overlay is anchored to — the two disagree at any `content_scale_factor`
  other than 1.0 (`--ui-scale`) and after a window resize, which also never
  re-laid the plates out. It now measures the overlay itself and re-lays out on
  `resized`.
- **`front.show_manual()` indexed `MANUAL[manual_page]` unclamped**, so the
  `--front=manual --page=N` screenshot hook crashed the game on a page that does not
  exist (and on a crafted `--page=abc`, which reads as 0 only by luck of Godot's
  String-to-int conversion). One clamp, at the top of the function.
- **`cinematics/package-lock.json` was still at 1.0.0** while `package.json` is
  1.2.0: a lockfile that had not been regenerated since the rename, which is what
  `npm install` rewrites on any fresh checkout. Committed in sync.
- **`tools/requirements.txt`** — `make_sounds.py`, `mix_soundtrack.py` and
  `make_ads.py` import numpy and scipy and nothing said so; the README's "the game
  has no package dependencies" is true and stays true, but the asset tools do.

Still open, and deliberately not touched here: the soak tier (the 11 balance cells
are still "pending first run"), the ten unwired shorts, `geom._stops`,
`level._room_post`, `roads._nxy` and `doors_view._cover` are dead code left from
superseded implementations, and `tests/godot472_test.gd` is the one script in the
tree without a `.uid` (Godot writes it on first import).

## Unreleased — the first engine run, and what it found

For the first time since the playtest pass landed, the tree was **executed**:
Godot 4.7.2-stable was compiled from source on a two-core box (the engine's
release downloads are outside this sandbox's network allow-list) and the headless
suites were run against it. `RELEASE_READINESS.md` has the full picture; this
entry is the changelog's part of it.

**Green on 4.7.2:** the project imports (158 asset steps), all 118 scripts load,
and the quick tier passes — `improvements`, `city_improvements`, `ops_ui`, `dept`,
`orders`, `save`, `story`, `politics`, `city_link`, `godot472`. Beyond the quick
tier: `determinism` (35 cases), `maps`, `nav_door` (175 doors, 0 problems),
`city_test`, `habits --strict`, `brains --n=8`, `civ --n=40`, and a full 40-week
`op_test --chief=sensible` campaign through to its election.

- **The determinism fixture did not need resetting.** The playtest-pass note
  below expected `--write` after Q1/Q6/Q4. Every one of the 35 seeded cases
  reproduces byte-identically. Those orders and the rally reset simply never fire
  in the fixture's first-week operations — so the net does not yet cover them,
  and a case that does is worth adding.
- **A save with `"kit": null` still raised on the boot path.**
  `_fix_record()` called `Equipment.normalize(r.get("kit", default))`; `get()`
  returns the null *value* when the key is present and null, so the call ran with
  `null` and logged `Cannot convert argument 1 from Nil to Dictionary` before the
  fallback one line later could help. The argument is now chosen before the call.
- **`payroll()` indexed `status` on records that had lost it**, raising
  `Invalid access to property or key 'status'` during the same load. `_fix_record`
  now restores the identity fields a damaged record can be missing (`status`,
  `name`, `rank`, `ech`, the habit arrays, the course queue) and payroll reads the
  key with a default.
- **The end-of-campaign summary doubled its nouns**: "7 stories stories reached
  the papers; 3 lawsuits lawsuits settled". `_n()` already carries the noun. Only
  a week-40 run reaches that line, which is why nothing had ever seen it.
- **The story archive read Dana Okonjo-Vale's poll share as 0.0%**, and logged
  `Invalid access to property or key 'dana'` every time the page opened:
  `contact_status()` passed the archive's contact id to `politics.share()`, whose
  keys are the candidate ids (`"okonjo"`). The ids are mapped now, and `share()`
  reads with a default so an unknown id is 0.0 rather than an engine error.
  `story_test` passed throughout — only the log showed it, which is why the runner
  now reports a suite that logs a script error.
- **One assertion in `godot472_test` was inverted**: a campaign save with no
  department block is refused (`from_data` → false) rather than loaded as an empty
  department — which is the safe behaviour, since the next save would otherwise
  overwrite the `.bak`. The test now asserts the refusal and says why.

**Not yet run:** the soak tier — `balance_test --gate`, `balance_matrix_test`,
`scale_playtest --gate` (the balance table below is still "pending"), `equip`,
`stall`, `fuzz`, `city_sim`, `perf`, and `op_test --chief=manual` (about 1,000 s
for 40 weeks; it did not fit in this session).

### New tooling

- **`tools/run_tests.sh`** — one command for the suites, in tiers
  (`--check`, `--quick`, `--full`, `--soak`, `--list`), with per-suite timeouts,
  a log per suite in `build/test-logs/`, and log scanning for the 18 harnesses
  that cannot fail a build on their own.
- **`tools/ci/ci.yml`** — the static audit and version-sync check, the quick
  tier on 4.7.2 and on 4.4.1 (the release engine), the full tier on `main`. It
  sits one directory over from `.github/workflows/` because the automation
  account that pushed this branch may not create workflow files; moving it there
  is the whole activation.
- **`tools/sync_version.py --check`** — reports drift between
  `scripts/version.gd`, `project.godot` and `export_presets.cfg` without
  rewriting them, so CI can refuse a half-done version bump.

## Unreleased — the Godot 4.7.2 debug pass

A whole-tree pass with **Godot 4.7.2 as the primary engine** (4.4.1 stays
supported). The engine is the same one 1.2.1 targeted, so this is not a port:
it is the class of fault 4.7's stricter analyzer and stricter runtime turn from
a warning into a stop, plus the crash-on-boot paths reachable with data the
code assumed could never arrive.

**Caveat on verification.** No Godot binary could be run here — the engine's
release downloads sit outside this environment's network allow-list. Every
finding below is from static analysis, and every fix is written so that a
correct file takes exactly the same path it did before. Run the harnesses to
confirm (see the README's headless checks).

- **One more `:=` that 4.7 rejects.** `city_main.gd` read `var payload :=
  director.pressure_data()`; `director` is declared `var director`, so the
  result has no static type. This is the same construct that broke
  `decals.gd`'s `d.pool_points()` in 1.2.1, and it was introduced by the
  pressure-write hardening in this very pass — now `var payload: Dictionary`.
  The other 627 `:=` sites were checked by resolving each callee's declared
  return type; all of them infer.
- **The save-loading path could throw before the title screen.** `Campaign.
  from_data()` and `Department.from_data()` read required keys as `d["seed"]`,
  `d["officers"]`, `d["department"]` and so on. `SaveFile` only falls back to
  the `.bak` when a file fails to *parse* — a file that parses but lost a
  record, or holds a `null` or a non-dictionary entry, threw instead, and this
  runs while the game is starting. Both now read through `.get()` with the
  version-appropriate defaults, and `_fix_record()` guards the kit sub-keys and
  the `file` list. Behaviour on a save the game wrote is unchanged.
- **`_find_path()` indexed an empty `grids` array.** `nav.gd` assumed `build()`
  had run; it now returns the direct `a -> b` line instead, so a navigator that
  was never built degrades instead of crashing.
- **Division and normalisation guards** in the hot loops: `o.ech["tr"] == 0`
  made `exp()` divide by zero in `_passive()`; `DT` is now checked before the
  velocity divide; `o.wpn()` may be absent in `_green_carry()`; a zero-length
  away vector in `director._retreat()` and the ambulance `fetch` job now fall
  back instead of normalising a null vector.
- **`get_window()` / `get_viewport()` / viewport textures** are null-checked in
  both scenes' startup, screenshot and camera-fit paths, so a headless or
  pre-first-frame call logs a warning and continues rather than throwing.
- **Both camera fits could write an `INF` into `cam.position`.** `main._fit_
  camera()` and `city_main.fit_camera()` divide by the computed zoom `z` to
  offset for the side panel, and `city_main` divides by a raw `--zoom`
  argument. A degenerate viewport or a zero/negative `--zoom` made that a
  divide by zero; both now bail out before the divide instead of after it, and
  `--zoom` is validated like `--ui-scale` is.
- **`--ui-scale` is validated.** A malformed value used to be cast and assigned
  straight to `content_scale_factor`; it is now range-checked.
- **Settings writes report failures.** `ConfigFile.save()` and the audio-bus
  indexes are guarded, so a read-only `user://` degrades to a warning.
- **`money()` no longer loops on a pathological input**, and `absi()`'s
  `INT64_MIN` overflow is handled.
- **The project declares both engines.** `config/features` is now
  `PackedStringArray("4.4", "4.7")`, and the GDScript `untyped_declaration` /
  `inferred_declaration` / `unsafe_void_return` warnings are switched on so the
  remaining `var level` / `var world` members stay visible.

### New tooling

- **`tools/gd47_check.py`** — the static audit used for this pass, runnable with
  no Godot binary (`python3 tools/gd47_check.py`). Six checks: bracket balance
  with strings and comments stripped, duplicate class members, tab-only
  indentation, `:=` inference from an untyped receiver, the GDScript-breaking
  APIs from 4.4 to 4.7, and statements that escaped into class scope. It is a
  linter, not a parser: confirm with `tests/_check.gd`.
- **`tests/godot472_test.gd`** — headless regression for the fixes above
  (`godot --headless --path . -s res://tests/godot472_test.gd`). It feeds the
  save path deliberately malformed-but-parseable data, checks the unbuilt
  navigator, and re-checks the version metadata sync.

**Also checked and found clean:** every GDScript-breaking API change from
4.4 through 4.7 (the removed `RenderingServer.instance_set_interpolated` /
`instance_reset_physics_interpolation`, `get_rpc_config`, `UPDATE_WIDTH_IN_
PERCENT`, `accessibility_live`, `type_exists`) has zero uses in the tree;
`draw_string`'s new `oversampling` parameter is appended last, so all ~90
existing calls are unaffected; no duplicate members, no mixed indentation, and
all 118 scripts balance.

## v1.2.1 — Godot 4.7 compatibility

The project now parses and runs on **Godot 4.7.2** as well as 4.4.1. Four faults
were found, all of them in `main` rather than in the engine: three were damage
from a bad merge, one was a construct the newer parser rejects.

- **`scripts/ui/ops_ui.gd` was unparseable.** The merge that brought the story
  and archive work together duplicated four member declarations (`_sliding`,
  `kit_open`, `roster_open`, `flash`) and then spliced a function's statements
  into class scope, between two copies of `const STATUS_WORDS`. Every merge
  conflict was re-resolved by hand: the reformatted side plus the newer
  features (IA triage filters, the first-operation guide, the risk card, the
  pacing readout), with the leftover compact copies removed.
- **`scripts/sim/world.gd` lost an indented block.** In `_update_dormancy()`
  the body of `if not o.hot:` sat at the same level as the `if`, so the
  proximity scan that decides an operator is hot was outside the branch and the
  file would not parse. Restored the nesting.
- **Two `:=` inferences from untyped values**, which 4.7 reports as parse
  errors: `d.pool_points()` in `scripts/view/decals.gd` (`d` is untyped, so the
  result has no static type) and the precinct comparison in
  `scripts/city/director.gd`. Both now declare their type explicitly.
- **`d . cases . filter(...)` chains** written across lines by the reformatter
  are rejected by 4.7's parser; both sites are plain single expressions again.
- **`tests/op_test.gd`**: `Outcome.evaluate()` returns `findings` as a count,
  not an array, so the totals line now adds the int. The test had never run,
  because `world.gd` could not parse. `tests/improvements_test.gd` expected two
  grave cases where its own fixture has three.
- Verified with a 4.7.2-stable build from source: all 117 scripts `--check-only`
  clean, the game boots headless without script errors, and the test suite
  passes (`determinism`, `ops_ui`, `dept`, `improvements`, `city_link`,
  `city_improvements`, `op`, `habits`, `equip`, `politics`, `brains`, `civ`,
  `lethality`, `hold`, `nav_door`, `fuzz`).

The same sources also build and boot on 4.4.1-stable from source, so the
version bump costs nothing on the engine the release uses.

### The release exe, rebuilt

The 107 MiB `release/TheViolence.exe` shipped by #9 embedded *unparseable*
scripts — it could not have started. It is rebuilt from these sources:
112,611,488 bytes, Godot 4.4.1, 508 files / 42.8 MiB of pack, every file
matching its stored MD5, `The Violence` + `1.2.1.0` in the version resource.
Two faults in `tools/build_windows_exe.sh` came out of that rebuild:

- It never created `x86_64-w64-mingw32-gcc-ar`, which 4.4.1's `detect.py`
  probes first; `env.Detect()` returned `None`, the engine stringified it, and
  the final static-library link died with `sh: 1: None: not found`.
- A source build reports `4.4.1.stable.custom_build`, but the editor looks for
  templates under `4.4.1.stable`, so the template was installed where the
  export step would never find it.
- `application/modify_resources` is now `false`: the icon and version block are
  compiled into the branded template, so the export no longer demands rcedit.

## v1.2.1 — the Windows build

A single-file Windows release, built from source in an environment with no access
to the engine's download archives.

- **`release/TheViolence.exe`** — 107 MiB, x86-64, GUI subsystem: Godot 4.4.1
  runtime + the whole game pack (498 files, 42.8 MiB: 124 textures, 34 sounds,
  18 cutscene videos, 76 compiled scripts) in one executable. No installer, no
  DLLs, no side-car `.pck`; every imported library is a stock Windows DLL.
- **Branding is compiled into the template**, not patched on afterwards: the
  game's seven-size icon and a `The Violence 1.2.1.0` version block are written
  into the Windows resource script before the engine is linked, so the build
  does not need rcedit.
- **`tools/build_windows_exe.sh`** rebuilds it end to end: a headless Linux
  editor for the export step and a Windows release template cross-compiled with
  zig's bundled clang + mingw-w64 sysroot, both from the Godot 4.4.1-stable
  source. `tools/patch_rc.py` applies the two source edits this needs.
- **`tools/inspect_exe.py`** and **`tools/inspect_pck.py`** audit a release
  afterwards without Godot: PE machine/subsystem/imports/resources, and every
  file inside the embedded pack checked against its MD5.
- `Play.bat` and `play.sh` now also look in `release/`.
- `project.godot` and the export preset report version 1.2.1.

## Unreleased: doors, and the path through them

A pass over the two systems that meet at a doorway: the 0.25 m navigation lattice and the
shut-door leaves. Both had faults that only show at an opening — a door is the narrowest
thing anyone walks through, so it is where a smoothing leg that is a few centimetres wrong
becomes an officer inside the frame.

- **The navigator smoothed paths through walls.** `line_ok()` — the test that decides
  whether a leg from one waypoint to another can replace the stair-step cell path —
  sampled one grid cell every 0.25 m and asked whether that cell was walkable. A leg could
  cross the *corner* of a blocked cell between two samples and still be accepted. Since
  the walkable mask is already inflated by the 0.30 m body, that put the body inside a
  wall, a door jamb or a wardrobe: measured over the twelve maps, up to 11 cm of a 0.30 m
  body (p95 9 cm), and 59 of the 175 door crossings in the suite clipped geometry. The
  leg is now tested against the obstacles themselves: `Geom.path_clear_leg()` grows each
  obstacle by the body's radius and asks whether the segment reaches it (`seg_rect_dist()`
  is the exact segment-to-rectangle distance; `path_clear()` is the same test with no
  endpoint allowance, and is what the gate uses). Measured after: 0 crossings clip and the
  worst overlap anywhere is 1 cm, with the paths all but unchanged — 2 cm longer on
  average (one 22 cm, a few shorter), a third of a waypoint more, which is the price of
  not cutting the corner. Smoothing costs more per accepted leg — the clearance test asks
  nine buckets instead of one — but it only runs when a goal changes, or once every 1.5 s
  for an officer who is stuck. `candidates()` gained a halo: a bucket's edge is where an
  obstacle is filed, not where it is, so a query that has to be sure it holds every
  obstacle within 0.3 m of a line cannot trust the DDA walk alone (it missed three legs in
  3,300 across three maps). City lots walk through the same navigator, one lattice per
  building template, so they get this with no further work.
- **Officers stopped to open doors they were only walking past.** A shut door's leaf was
  grown by the body's radius on every side — including out along the opening, past the
  jamb — and the probe asked only whether that grown box lay ahead. In a 2 m hall, walking
  along the wall side, or round a corner past a closed bathroom door, the officer was
  caught 0.10-0.28 m off the door's face, stopped dead and set to opening it. 152 of the
  175 doors did it. `Geom.leaf_in_way()` now wants the move to close on the leaf's face or
  cross it: walking along a shut door leaves it alone, walking into it still stops the
  officer 0.25 m short and works the door.
- **A squad queued at a locked door searched the building again every 1.5 s.** `move_to()`
  calls a path bad when an officer has not moved in 1.5 s; standing at a shut door he is
  not moving either, so every officer in the stack re-ran A* — and re-pathing cannot help,
  because the door is the problem. `world.door_ahead()` excuses it: the search now happens
  when the goal changes, not forty times a minute per officer.
- **New gate:** `tests/nav_door_test.gd` walks every door on every map from the floor of
  one room to the floor of the other (from a corner of the room, so the approach turns into
  the doorway), and fails if the body does not fit along the path, if the door is not
  joined to its rooms, or if a shut leaf stops someone walking past it. It is the
  regression for both faults above. Run over the twelve maps through the raster probe in
  `tools/` — `nav_probe.py` and `level_port.py`, a throwaway port of the level builder
  kept for measuring the lattice without Godot, diagnostic and not part of the build — it
  reports 175 doors, 59 clipping crossings before the fix and 0 after, and 152 doors whose
  shut leaf stopped someone walking past it, 0 after.

## Unreleased: the short cutscenes

Fourteen in-game interstitials, 5-10 s each, in the same Remotion project as the opening
(`cinematics/`). They are drawn on the same page — paper, ink, stepped greys, one red that
only marks where a plan touched a real room — and they exist for the beats that used to be
a cut between panels:

| id | length | beat |
|----|--------|------|
| `S01-Week` | 6 s | a week starts: the numeral, the calendar, this week's slips dealt out |
| `S02-Situation` | 7 s | a situation picked off the board: the file, its visibility, its pressure |
| `S03-Plan` | 8 s | the plan signed: the route in red, the squads on it, the rail of numbers |
| `S04-Staging` | 7 s | RUN: two vans, a wet street from above, the squad on the wall, GO |
| `S05-Threshold` | 7 s | the first door: the cone, the recognition bar, `clear` or `contact` |
| `S06-OfficerDown` | 8 s | an officer downed: the room stops, the radio tries, the notice |
| `S07-Debrief` | 7 s | the fog lifts: the route as drawn, then as it went, markers and counters |
| `S08-Press` | 8 s | the Ledger lands, sets its headline, and a `bad` week gets the red rule |
| `S09-Case` | 8 s | internal affairs: the exhibit, the redactions, `CLEARED` / `SUSTAINED` |
| `S10-Ally` | 7 s | one ally's standing walks to the red line at 25, and holds or goes |
| `S11-Election` | 10 s | election night: three bars, six wards reporting, the name |
| `S12-EndOfWatch` | 8 s | a killed officer: badge, folded flag, one bell, one red rule |
| `S13-Allocation` | 6 s | the council's money counted onto the ledger, `APPROVED` / `CUT` |
| `S14-Course` | 6 s | a course ends: the certificate, the ticks, what actually changed |

- **Props, not scripts, and slots.** Each short is a pure function of its props, kept in
  `cinematics/src/shorts/registry.js` with types, defaults and docs; `npm run manifest`
  writes `shorts.json` (also into `assets/cutscenes/shorts/` for the engine) and
  `cinematics/SHORTS.md`. Where a short leaves a plate empty on purpose — a name, a badge,
  a ward, a headline — the registry publishes it as a **slot**, so one video serves every
  campaign event without a re-render: `play_short("s06_officer_down", {"name": ...,
  "badge": ...})`.
- **Two files already carry a variant** rather than a second composition: `S05-Threshold`
  is `clear` or `contact`, `S06-OfficerDown` is `down` or `killed`, and both are separate
  renders because the picture changes, not only the words.
- **In the game:** `scripts/ui/shorts.gd` (a `CanvasLayer` beside the opening's
  `cutscene.gd`) reads the manifest, plays the Theora, paints slot text scaled to the
  panel, and skips on Space/Enter/click; it never blocks and always calls back, including
  when the file is missing. `main.play_short(key, text, after)` is the one call site shape,
  it honours the existing **opening cutscenes** setting, and `--short=s01_week
  [--short-shot=path --short-at=frames]` plays one from the command line for a recording.
- **Pipeline:** `npm run shorts` renders to `out/shorts/*.mp4` (1920x1080, 30 fps, h264 +
  aac); `sh scripts/to_game-shorts.sh` loudness-normalises and writes 1280x720 Ogg Theora
  into `assets/cutscenes/shorts/`. That step needs an ffmpeg with libtheora and libvorbis
  (the compositor's own ffmpeg has neither), so the script takes `FFMPEG=/path/to/ffmpeg`.
- **Nothing in the campaign calls them yet.** The call sites are picked and named in
  `cinematics/SHORTS.md` (`trigger`), and the beats they belong to are the ones the panels
  already report; wiring each one is a `play_short(...)` in the beat's handler, not a new
  screen.

## Unreleased: the playtest pass (Q1–Q10)

From the ten-question playtest survey (`PLAYTEST_REPORT.md`), taken in the
report's own order: Q1+Q6, then Q2+Q3, then the Q5 measurement matrix, then
Q4/Q10/Q8/Q9, Q7 last. Q1 and Q6 touch the simulation, and Q4 changes what
"Suggest a plan" produces for the fixture's first-week operations, so this entry
expected the determinism fixture to need a one-time
`godot --headless --path . -s res://tests/determinism_test.gd -- --write`. **The
first engine run (above) showed it does not** — all 35 cases reproduce unchanged;
the balance table still wants its actuals from a soak run.

- **Stress now has a rally reset.** Stress decayed at 0.1/s only in quiet seconds,
  which in a room-to-room raid was almost never (a near miss, a hit or a sighting
  resets the one-second window), so stress habits effectively stayed on for the whole
  operation. After 12 s with neither a stress event nor an enemy sighting, an element
  now calms at 0.25/s (`RALLY_DECAY`, `RALLY_QUIET` in `world.gd`); the slow 0.1/s
  rate and the trauma/morale `stress0` floor are unchanged. Consolidation in a cleared
  room is now an actual way to settle the squad.
- **New constraint: Less-lethal first (1 point).** Inside 4 m, a recognized suspect
  who is neither firing nor pointing a weapon gets one challenge and then OC, a taser
  or a baton instead of a round. Raising a weapon or opening fire lifts the rule at
  once; civilians, surrenders and the BH09 startle shot are outside it, so the
  misjudge and bad-habit paths still do their work. The standing two-challenge rule
  for less-lethal tools drops to one under this order (`World.less_challenges_needed`).
- **Weapons tight now costs 1 order point, not 2.** It shares the constraint row with
  the new order; `Orders.cost` and the planning panel's point math read the same data.
- **Test:** `tests/orders_test.gd` gains the `less` gate (pre-attack police rounds at
  an armed man who has not raised the weapon, n_min 16). The stress change is covered
  by the existing lethality and habits suites.

- **Hiring is a choice now (Q2).** The blind Recruit/Lateral buttons are gone:
  each week brings a pool of two to four applicants with their files open —
  echelon, judgment, temper, integrity, traits and bad habits, expected pay.
  Pick one and the rest walk; nobody is "the average recruit" any more. The
  pool is saved; department save version 6 carries it.
- **Integrity does work (Q3).** Every officer named in a finding gives a
  statement that can disagree with the bodycam (`(65-integrity)/120`, at most
  55%), the highest-integrity squadmate standing gives testimony that can firm
  thin evidence or shake it (video never slips), and being caught out costs 5
  integrity. The leak after a cleared case is no longer a flat 55%/25%: it
  scales with the named officer's integrity and statement (x(1.6 - integrity/100),
  x1.3 if caught, x0.8 if the statement held), and the DA's price for clearing
  a contradicted statement is the steepest on the table.
- **The asserted balance matrix (Q5).** `tests/balance_matrix_test.gd`: 5v5
  assault on hold across all twelve maps, pooled by map family (houses,
  commercial, multi-room, plaza) at n>=30 with the equipment gate's pooled
  estimator, equal regulars/police/SOF plus the three cross-echelon pairs, and
  the SOF-vs-SOF hold-habit regression the survey named (HD16 alone worth
  11 points, the set cancelling itself, open since v0.8): the matrix asserts
  neither HD16-alone nor the full set sits more than 10 points of attacker
  share below no hold habits at all. `scale_playtest.gd --gate` turns its CSV
  into pooled non-degeneracy asserts. Expected bands; actuals are filled in
  from the first engine run:

  | cell (5v5 assault, attacker wins) | expected band | actual |
  |---|---|---|
  | regulars, houses | 30–50% | pending first run |
  | regulars, commercial | 25–60% | pending first run |
  | regulars, multi-room | 20–60% | pending first run |
  | regulars, plaza | 20–70% | pending first run |
  | police, houses | 40–70% | pending first run |
  | police, other families | 30–75% | pending first run |
  | SOF, all families | 30–70% | pending first run |
  | SOF attacking regulars (all maps) | >=55% | pending first run |
  | regulars attacking SOF (all maps) | <=45% | pending first run |
  | police attacking regulars (all maps) | >=50% | pending first run |
  | SOF v SOF, HD16-only / all hold habits vs none | no more than 10 pts worse | pending first run |

- **Reading the briefing is worth something, measurably (Q4).** Suggest a
  plan now consumes only the call type, the geometry, the ranks, a *confirmed*
  hostage room and the rally chatter; the estimated rooms, the lookout, the
  door locks, the civilian count and the flight risk are reserved to the
  human, and it never picks your entry door. The debrief gains YOUR EDITS:
  per squad, what you changed, closed with what that squad met and whether it
  broke an order. Settings gains veteran chief: no Suggest button, plans open
  blank. `op_test.gd --chief=manual` plays matched seeds with an
  intel-reading scripted chief (far door on a lookout, less-lethal with
  civilians inside, the estimated Rescue room, no knock on a watched runner)
  and both runs close with comparable totals — the gap is the measured value
  of the briefing. Barricade plans also spend the 1 point Weapons tight
  actually costs since Q6, where they used to hold out for 2.
- **Training is a pipeline, not twenty clicks (Q9).** Courses queue per
  officer (up to three) and start themselves the week the officer can take
  them; the classroom courses — judgment and the use-of-force review — can be
  taken from a hospital bed, retraining after a finding included, because
  course and wound now run on separate clocks. A queued course that stops
  making sense drops unspent. Three or more on the close-quarters refresher
  together pay three quarters each and come back bonded. The judgment button
  prices itself ("base misjudge 18% -> 13%"), and every debrief reports the
  department's training state. `op_test.gd --train` measures courses/officer
  and residual bad habits over 40 weeks.
- **The budget can be read forward, and once, raised (Q8).** The account
  screen shows the next four weeks on today's numbers — allocation, payroll,
  lawsuits already filed, queued courses as a memo — and calls out the week
  the account goes red, if it does. Overtime is priced by the commitment:
  $100 callout plus $15 a commenced minute (a 40-second raid $115 a head,
  three minutes $145 against the old flat $160), half rate for static
  post/patrol duty, the $60 night premium untouched. And there is one way to
  bring money in: a $10,000 city grant while the budget chair's standing is
  60+, costing 5 of it and an eight-week wait between askings. Still no hard
  game over: red freezes hire/train/kit, as before.
- **Rallies are priced bets (Q10).** The threat briefing carries its numbers:
  chatter level, odds ("about 1 in 6"), and confidence that firms with each
  tip (30% to 60%), with the cry-wolf rate stated. On lowered chatter the
  suggestion sends six officers, not ten; static duty bills half overtime
  (ten quiet minutes $125 a head, not $250). The catastrophic tail is
  untouched; what changed is that the quiet outcome, the common one, no
  longer costs like a raid. Compare `op_test.gd` with and without
  `--no-events` on matched seeds.
- **The endless battle leans on the board (Q7).** The city's six precincts
  are the campaign's six wards, and now the one writes to the other:
  per-precinct incidents, reports, captures, gang-held ground and bodies go
  to `user://city_pressure.json`; a campaign starting, and every week roll,
  normalises them to gang/hot/quiet weights that lean on type frequency,
  ward placement and one point of visibility where it has been loud. The
  board and the week-end lines say where the city stands. Campaign save
  version 3 keeps the reading; `tests/city_link_test.gd` gates the mapping,
  the bias and the iron rule that with no city read, not one roll on the
  board differs — the determinism fixture explicitly declines to inherit a
  played machine's city.

## Unreleased: a debugging pass

Every headless suite was run on a clean 4.4.1 build and the game itself was booted through each of its command-line hooks (the title, the test range, the board, the endless city) with no script errors. The simulation is untouched: the determinism fixture still matches all 35 cases to the last decimal, and the balance, stall, fuzz, brains, city and campaign gates all still pass. What the pass turned up:

- **The weapon light's equipment gate was noise, not a measurement.** `--only=light` failed at the README's own sample sizes and passed at others: an operation records only some ten night recognitions, so a mean of the per-run means swung across the 0.05 s margin from seed to seed. The gate now pools the recognition seconds against the number of recognitions over four times the seeds (the same pooled estimator the heavy pistol and battle rifle use), and its margin is what the design can reach: the light only helps inside its 30 deg, 25 m beam, which is about half the recognitions, so a squad's mean falls by 0.05-0.08 s rather than by the whole 1.25x night penalty. Measured 0.48 against 0.52 at `--n=8`, 0.49 against 0.54 at `--n=12` and 0.48 against 0.54 at `--n=16`; a light that does nothing measures 0.55 against 0.52, still a FAIL. Daylight shows no difference either way, as it should.
- **Four locals no longer shadow the state they sit next to.** `_director()` in main.gd kept the camera command in a local `mode`, one name away from the game's own `mode` ("setup", "run"); the PF02 exposure pass in nav.gd used a local `reach` beside the class's `reach` byte array of cells in the connected region. Both are renamed (`cam_mode`, `reach_m`). The city director loses two locals nothing read, one of which (`lv.bldgs[bi]`) was the only thing a reader had to explain why `_send_squad` never used the building it looked up.
- **Twelve maps, not eleven.** The README (four places) and the project description still said eleven; the table beside them lists map 11, Civic Plaza, and the registry ships twelve.

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

