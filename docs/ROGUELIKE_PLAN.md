# The Violence — story mode as a roguelike

Plan written 2026-10-26 against the 1.2.1 tree (`The-Violence-1.21-main`). The newer
tree is the source of truth wherever it disagrees with older design notes.

## What changes, in one paragraph

A campaign becomes a **run**: forty weeks, one seed, one ironman file, ending at the
election — that part already exists. What it lacks is the roguelike *build*: every run
currently starts with the same armoury, the same academy, and the same city that only
reacts. The run layer adds four sources of variety the player drafts or answers —
**procurement drafts** (what the armoury can issue), **department training programs**
(habits taught to the whole force), **offers** from the city's power brokers and
press, and **events** with multiple-choice responses — plus a light **legacy**
(meta-progression) that unlocks starting doctrines between runs. **Endless Battle is
removed**: it was a proof of concept for the systems, and its one link into the
campaign (the ward-pressure file) goes with it.

## Design rules

1. **Every pick is a trade-off, never a pure upgrade.** Hardware costs money and
   usually standing with someone; habits cost money and weeks; offers buy one ally at
   another's expense. No perfect run (project rule).
2. **The simulation stays honest.** Nothing in the run layer touches combat rolls
   directly. It changes *inputs*: what kit exists, which habits officers carry,
   money, allies, intel. The CQB sim keeps doing what it does.
3. **Doctrine over gear.** In line with *The Tactical Imperative* (training correlates
   with restraint; militarization of material and culture has political costs),
   military hardware moves the Safe Streets ticket up and the coalition down;
   restraint programs do the opposite.
4. **Seeded and saved.** The run layer has its own RNG stream, saved with the
   campaign, so a seed reproduces the same offers and drafts.
5. **Deterministic harnesses keep passing.** The run layer is a campaign flag
   (`rogue`). New stories from the menu are always roguelike; the headless harnesses
   that hash first-week operations keep the classic campaign.

## 1. Procurement drafts (the armoury)

- The armoury starts with **patrol stock**: service pistol, patrol carbine, red dot and
  iron sights, soft vest, weapon light, medical kit, OC spray, baton, taser, door ram.
  Everything else — plate carriers, helmets, shotguns and beanbags, SMGs, short rifles,
  flashbangs, sting-balls, gas and masks, the shield, breaching rounds, launchers,
  magnified optics, other pistols, battle and assault rifles — is **locked**.
- **Week 1, then every 4 weeks**: a draft of **3 procurement contracts**. Pick one
  (its contract fee is paid and its items enter the armoury) or **pass** for a
  $2,000 surplus refund.
- Contracts are tiered. Tier 1 from week 1, tier 2 from week 5, tier 3 from week 13.
- Each contract carries a **political tag**: `restraint` (+coalition), `neutral`, or
  `military` (+Kettering, −coalition, a Ledger headline).
- Locked items cannot be issued: the kit editor greys them out ("not in the
  armoury"), squad kits and Suggest-a-plan quietly fall back to stocked items.

## 2. Department training programs

- **Week 2, then every 6 weeks**: a draft of **3 programs**. Each teaches **one habit
  to every officer on the force** who lacks it — active, injured, suspended, at the
  academy — when it completes. New hires after completion get it from the academy
  (the curriculum keeps the habit).
- A program costs **a base fee plus a per-officer fee** and runs **2–4 weeks**. One
  program at a time; a running program can be abandoned (no refund).
- The pool is the 40 base good habits (minus what the academy already teaches) plus a
  handful of **hold** habits (HD) for post/contain work. Programs aimed at known
  department weaknesses (e.g. Respect lines of fire, Threat discrimination, Trigger
  discipline) are weighted up.
- Two **special programs** can appear: *Crisis intervention* (judgment +4 force-wide)
  and *Peer support* (trauma −3 force-wide) — restraint-tagged.
- **Pass** gives nothing but keeps the cash.

## 3. Offers

- Each week there is a chance (about 40%, never two weeks running without one after
  week 3) of an **offer** from one of: the three candidates (Kettering, Okonjo-Vale,
  Pell), the four allies (Duff, Rourke, Mbeki-Shaw, Varga), the press (Nadia Ferrante
  of the *Carrick Ledger*; Hollis Crane of Channel 6), or ward community leaders.
- An offer is **accept / decline** and **expires at the end of the week**. Accepting
  always has a cost; declining sometimes does (the offerer remembers).
- Examples: Kettering's armoured-vehicle money (cash + a free military contract, −15
  coalition, Kettering +3); Okonjo-Vale's civilian review board (+trust everywhere,
  −union, but cleared cases get audited); Ferrante's embargo deal (hold a pending story
  two more weeks in exchange for an exclusive interview); Rourke's overtime grievance;
  Mbeki-Shaw's ride-along program (+tips, an officer committed each week); Varga's
  joint task force (+intel on gang houses, −freedom to clear cases).

## 4. Events (multiple choice)

- At the end of most weeks (about 55%), an **event** lands and must be answered before
  the next week can end. Two to four responses; some have **uncertain outcomes** (a
  stated chance, rolled from the run RNG).
- Events name real officers from the roster where they can (the rookie who froze, the
  sergeant with the viral video), so the roster becomes the story.
- About twenty events at launch: viral video, ammunition recall, evidence-room theft,
  officer's social-media post, heat wave, gang truce offer, union sick-out, a witness
  asking for protection, an officer's off-duty arrest, a federal surplus offer, a
  journalist's records request, a councillor's nephew, a training accident, a
  memorial, a protest permit, a body-camera vendor, a hospital's request for an
  escort, a funding audit, a rookie's resignation letter, a tip line flood.

## 5. Legacy (between runs)

- `user://legacy.json` keeps every finished run: seed, weeks, ending, run score.
- A **run score** sums arrests and successes, subtracts deaths (officers, civilians
  and suspects), civilian hits and excessive-force findings, and adds a bonus for the
  election outcome — printed on election night.
- **Commendations** unlock by ending type and score; each unlocked commendation adds a
  **starting doctrine** to the week-1 inheritance draft (e.g. "Plate carriers on day
  one", "$10,000 reserve", "Academy teaches Slice the pie", "Ledger contact: one
  free embargo"). The first run offers the three base doctrines.

## 6. Removing Endless Battle

Delete `scripts/city/*`, `scripts/city_main.gd`, `scenes/city.tscn`, the city-only
views (`city_ground`, `city_labels`, `city_things`, `territory_view`, `lot_view`,
`crowd_view` if unused elsewhere), the city tests (`city_test`, `city_sim`,
`city_link_test`, `city_improvements_test`), the title-menu entry, `main.start_city`,
the city pressure file and every `pressure` path in `campaign.gd` and
`situations.gd`. The board's weights fall back to the unlinked numbers (which is
exactly what every campaign without a watched city already used), so determinism is
unaffected.

## 7. Build order and gates

1. Remove Endless Battle; quick tier green.
2. `rogue.gd` data + interpreter; `Equipment.armory` gate in `validate()`; armoury UI.
3. Programs, offers, events; the **Desk** card on the board; End week blocked by an
   unanswered event.
4. Legacy file, inheritance draft, run score on election night.
5. New harness `tests/rogue_test.gd`: seeded reproducibility, save round-trip,
   armoury gating, program completion teaches the habit to everyone, 40-week
   autoplayed run that answers every desk item at random without errors.
6. Rebuild the single-file Windows exe; second playtest.
