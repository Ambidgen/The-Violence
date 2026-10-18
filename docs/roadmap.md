# The Violence — roadmap & work queue

This is the ordered queue of what to build next, and why. It supersedes the
to-do lists at the end of `docs/analysis-v0.4.md` (§7) and `docs/tiers-0-2.md`
("Deferred" / "Next"), both of which are now either done or queued here.

Read `docs/analysis-v0.5.md` first for the state of the systems and the
measurements this queue is built on.

**The principle is unchanged:** the game direction (autobattler / squad
commander / crime city, analysis v0.4 §8) is still undetermined, so the queue
front-loads work every candidate game needs and gates the work that commits.

---

## Milestone v0.5 — measure, then choose (in progress)

The harness suite exists to turn arguments into numbers. This milestone runs it
and acts on what it says.

| # | Item | Status |
|---|------|--------|
| 1 | Compile-and-run the whole tree; fix what only the engine can find | **done** — two latent parse-level bugs (analysis v0.5 §2) |
| 2 | Determinism fixture (`tests/fixtures/determinism.json`) | **done** — 27 digests, verified reproducible |
| 3 | Habit coverage `--strict` green | **done** — BH17 reclassified as pure suspension |
| 4 | Stall watchdogs clean on all 11 maps | run per release |
| 5 | H1–H5 measurements (analysis v0.4 §5.3) | see below |
| 6 | Balance pass driven by H1/H2 (Experience vs plates vs habits) | **queued as Q1** |

### Q1 — the measurement campaign and the balance pass

The first campaign ran (analysis v0.5 §6); these are the follow-through items.

1. **Re-run at scale on a release-speed engine** (`n≥40`, `city_sim --min=30`).
   v0.5's numbers come from a `-O0` build at n=20-30: shapes hold, digits are soft.
2. **Experience: tune the 1→2 step, not the 4→5 one.** The sweep refuted the
   strong form of H1: exp is a threshold (1 is bad, 2-3 fine, 4-5 never bind
   at 5v5). Decide whether tier-1 operators should stay that helpless against
   a pair of simultaneous contacts, or flatten `PRESET_EXP` toward 2-3 and let
   the stat carry elsewhere.
3. **Habits vs the echelon package (H2).** Habits alone are worth ~3:1 (good),
   the full package is 10:1-150:1 (too lopsided to be a fight). Flatten the
   echelon stat spread and/or raise `m_h` (0.5 % per good habit) so the ladder
   is a gradient, not an erasure. The SOF-vs-militia cell should be a hard
   fight, not 150:1.
4. **Posture asymmetry:** assault beats hold ~83-100% at every size measured
   here, regardless of quality. Find out why (defender posts too exposed?
   attackers get free windows entries? hold never repositions?) and make the
   defence a choice. This is at least as large as H1-H3 and was not on the
   original list.
5. **Blend the 10 m cliff (H3 confirmed):** the move fraction doubles across
   the P1/P4 boundary. Give the ladder a gradient over ~8-12 m.
6. **City: decide the territory question (H5 measured).** Territory is
   scheduled (mix vs sof: near-identical maps at very different fight
   intensities) and all-untrained gangs flatline the city entirely (no
   expansion-eligible soldiers). Pair this with Q3 #10-11: either make who-wins
   move the map, or embrace the clock deliberately — and either way give the
   bottom of the quality range something to do.
7. **Element phase polish:** `entry` phases sat past 60 s on map 10 and
   `approach` routinely ran to its 45 s force-go on maps 09/10 (door
   congestion). Not deadlocks (0 stall matches), but slow.

## Q2 — architecture (every game needs this)

5. **Split the `ticker` bag** (v0.4 §4.1, deferred from Tier 2 #9 in full).
   The 65 keys are declared in `Op.TICKER_KEYS` and enforced by `gdlint`; the
   remaining work is the mechanical split into `o.aim / o.move / o.eyes /
   o.cover / o.comms / o.task` with per-owner `clear_for(oid)`. The determinism
   fixture (Milestone #2) now makes this refactor safe to attempt and honest to
   verify.
6. **Replay files from the intent boundary** (Tier 2 #12 completion).
   `w.commands` records `move_to / stop / start_action / engage` when
   `w.record` is set; nothing reads it back yet. Serialize `{seed, cfgs,
   commands}` to `.tvreplay`, add `world.replay(path)`, and a `tests/replay_test.gd`
   that re-executes one and diffs the terminal digest against the fixture
   format. Unlocks decision-level tests and the player-command path.
7. **Outcome attribution** (the missing piece of game shape A). The JSON dump
   already carries the timeline; add a post-pass that answers "why did A lose":
   first contact winner, fatal funnel deaths (downed within 2 m of a door),
   room-by-room clear times vs deaths, attention-boost usage. Ship it as
   `tools/attribute.py` over `--dump-json` output plus a ledger line in-game.
8. **CI gate.** `tools/gdlint.py` + `tools/verify_attention.py` +
   `habits_test --strict` + `determinism_test` on every PR (Godot 4.4.1 headless
   from the engine's GitHub releases). Two of the three bugs fixed in
   milestone v0.5 were found by running the engine exactly once.

## Q3 — the city (game shape C's substrate)

9. **`FactionPolicy` extraction** (Tier 4 #17). Pull `hostile()`,
   `potential()`, dormancy and the `if city` branches out of `sim/` into a
   strategy object the match shell satisfies with a trivial default. Before
   anything else is added to the director.
10. **Per-pair disposition + heat** (Tier 4 #18) in place of "holding gangs
    don't shoot at each other": a calm baseline with incident-driven feuds.
    This is where the city's stories come from.
11. **Territory economy** (Tier 4 #19): income by buildings held, spending on
    recruits / echelon upgrades, so `PUSH_EVERY` stops being the only clock.

## Q4 — gated on the game-direction decision (v0.4 §8)

Pick A (resolver/autobattler), B (squad commander) or C (crime city) using the
Q1 data — v0.4 §8's rule still holds: habit-deltas legible → A; failure modes
interesting → B; only the city churn interesting → C. Then, and only then:

| If | Then |
|----|------|
| A | campaign/ladder, progression over habits & quirks, attribution UX (Q2 #7) |
| B | pause-and-plan, waypoints over the intent boundary (Q2 #6), undo/replan; only then revisit a real BT (Tier 2 #11b) |
| C | civilians, a player role, city-zoom legibility; Q3 first |
| any | Tier 3 fidelity (verticality, grenades, penetration) only as the chosen shape demands |

## Rules of engagement

- Every behavioural change lands with a determinism-fixture update in the same
  commit, and the diff of `tests/fixtures/determinism.json` is read, not
  shrugged at.
- Balance claims are made from `--dump-json` aggregates
  (`tools/aggregate_playtest.py`), not impressions.
- New habits must register `Habits.EFFECTS` hooks and a call site;
  `habits_test --strict` is the gate.
- Nothing in Q4 is started before the direction call.
