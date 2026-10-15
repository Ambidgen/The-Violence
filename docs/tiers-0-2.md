# Tiers 0–2: what changed

The work order followed `docs/analysis-v0.4.md` §7. Everything here is
**option-preserving**: no change commits the project to a game direction.

---

## Tier 0 — instrumentation

| # | Item | Where |
|---|---|---|
| 1 | JSON dump per match | `tests/playtest.gd -- --dump-json=<dir>` |
| 2 | Habit coverage report | `tests/habits_test.gd` (`--strict`, `--csv`) |
| 3 | Deadlock / stall watchdogs | `tests/stall_test.gd` |
| 4 | Determinism regression | `tests/determinism_test.gd` (`--write`, `--verbose`) |

**The habit report** cross-checks the registry against the call sites and prints
three groups: habits with no call site and no hooks (pure suspension habits — fine),
habits with hooks declared but no call site (not implemented — a failure), and habits
with exactly one call site (check they are not inert outside one branch). It also
reports hook points nothing claims.

**The determinism test** runs 27 seeded matches (9 matchups × 3 seeds) and hashes the
terminal world state — positions, wounds, plates, alert, stress, suppression, blood,
kills, plus the shot/hit accounting. Digests live in `tests/fixtures/determinism.json`.
A refactor of `op.gd` that quietly changes a number now fails here instead of showing
up as a mystery balance swing later.

**The watchdogs** catch frozen states rather than slow ones: an operator aimed and
wanting to fire but not firing for 10 s (H4 in §5.3), moving with no progress for 5 s,
pinned under 0.9 suppression for 20 s, a memory dict that never lets go, and elements
stuck in `approach` / `sweep` / `breach` past their own internal timeouts.

**A linter** (`tools/gdlint.py`) exists because this workspace has no Godot binary. It
checks tab indentation, bracket balance, that every `ticker` key used anywhere is
declared in `op.gd`, that every habit id referenced exists, and that every declared
habit has a call site. On the first run it found `claimed_by` in `city/director.gd` —
a key that had never been declared and was invisible to every reader for a year of
development. That is the class of bug the declared namespace exists to prevent.

---

## Tier 1 — making the simulation honest

**5. Sound, both directions.** `brain.on_heard` no longer returns for everyone who is
not holding. Hold still re-posts to cover the nearest opening; hunt and the Aggression
bad habits go after the noise; an assault element halts, covers the bearing and does
not walk past a room it has just heard someone in. Every heard event also writes an
attention entry. The other half — *being* heard — is now declared in one table
(`Habits.MODE_SOUND`), so sprinting and running are heard, creeping, slicing the pie
and a lateral sidestep are silent, and the choice between them has a cost.

**6. Suppression.** `o.suppress` rises from near misses (scaled by how close the round
passed) and from rounds into cover within 2 m, and decays at 0.55/s. It widens the
group, slows recognition, costs movement speed, resets `settle` every time a burst
lands, and past 0.55 produces stray shots unless the operator has WD09. Resisted by
the echelon's composure only. GD05, GD08 and WD07 now have something to be *for*.

**7. Wounds bleed.** `Habits.BLEED_RATE` per zone; accumulated `blood` is a clock of
its own (1.0 = down), pain gathers stress, a wounded operator cannot sprint, and a
downed operator with blood already gone has less than the five minutes.

**8. Doors are state.** Open / closed / locked, on one map (01 Lone Cabin) as a
vertical slice. A shut leaf is a *dynamic* obstacle in `geom` — outside the CSR index,
tested with a short linear scan that is skipped entirely while every door is open, so
maps that don't use it pay nothing. Shutting one blocks sight, bullets and movement at
once, and `nav` gets reversible cell blocking (`reset_blocks` / `block_rect` /
`sync_doors`) that is safe against the static nav cache. The element gained a `breach`
phase: number one works the door, the rest cover it, and a failed breach retries.

---

## Tier 2 — architecture

**9. The `ticker` bag.** Two things happened. The namespace is now *declared*
(`Op.TICKER_KEYS`, grouped by owning system) and enforced by both the linter and the
coverage test. And the six id-prefixed per-enemy keys (`confirm_`, `tot_`, `froze_`,
`pf07_`, `assessed_`, `callout_`) moved out of it entirely into the new memory
records, where they are pruned with the memory they belong to. `remove_op` no longer
carries a hardcoded prefix list that has to be kept in sync by hand.

**10. Habit effect registry.** `Habits.HOOKS` (13 hook points) and `Habits.EFFECTS`
(habit → hooks). It drives the coverage report, gives the UI a generated description
of what a habit touches, and makes a generic ablation sweep possible. It is data, not
a rewrite: the call sites still read `o.has("PF07")`, because replacing ~55 call sites
with a dispatch table is a large, risky change with no behavioural payoff. What the
registry *does* buy is that a habit can no longer be silently unimplemented. It found
three immediately: BH08 (comms blackout) never ignored sector reassignment, BH18
(relaxed carry) never actually put the eyes on the direction of travel, and PF07 only
fired inside Rule 1 — see below.

**11. Named interrupt classes.** `Brain.Ix` labels every branch of the ladder
(INVOLUNTARY / RULE / WEAPON / ENGAGE / REACT / MAINTAIN / TASK / EYES). The ladder is
still evaluated top to bottom — that is the right call at this size, and a real BT
stays a trap unless the game becomes a command game. But a branch now declares what it
is, so a caller can ask "is this operator available?" without parsing `o.dbg`.

**12. Intent boundary.** Every decision that changes the world already went through
`move_to` / `stop` / `start_action` / `engage`, so those four now record into
`w.commands` when `w.record` is set. Nothing replays them yet — this is the substrate
for replay files, decision-level unit tests, and a player-issued command path, not the
whole thing.

**Inert habits fixed while wiring the registry:**

| Habit | Was | Now |
|---|---|---|
| PF07 get off the X | only inside Rule 1 (≤10 m) — inert at every range that matters | also sidesteps in `_engage_far` |
| WD01 ammo count awareness | only removed the empty-click pause | also tops up in a lull below 30% |
| GD03 respect lines of fire | only stopped you walking *into* a lane | also steps you out of one you are standing in |
| GD10 mutual support | only when the goal was behind the mate | unchanged — the geometry is right, this one is fine |
| ED09 rear security | a lone operator counted as "rear" and looked backwards at nothing | returns false with no mates |
| BH08 comms blackout | suspended GD04/08/09 but never ignored sector reassignment | GD09 re-sectoring skips BH08 carriers |
| BH18 relaxed carry | suspended ED01/02/09 but never moved the eyes | eyes follow the direction of travel out of contact |

---

## The cone of attention

`scripts/sim/memory.gd`. See the README for the player-facing rules. Three design
decisions worth recording:

1. **Attention is only for threats you cannot currently see.** A `seen` entry is
   written when contact is *broken* on a figure the operator never watched die — not
   while they are visible. Writing it continuously would have made the boost a flat
   permanent 35% for anyone looking at anyone.
2. **"Watched die" is tracked explicitly.** `world._down` marks every operator with
   sight of the fall; those operators drop the memory at once (`Memory.forget`).
   Everyone else keeps a cone of attention on a man who is already dead. That
   asymmetry is the interesting part of the mechanic.
3. **The boost applies at the moment of the shot, not the moment of recognition.**
   The parallel set-up at recognition is stored as a *duration* (`ready_dur` /
   `ready_at`) rather than an absolute time, so the boost you get when you switch onto
   an acquired target is the one your attention deserves *now*.

**One judgement call to check.** The 35% / 7.5% figures are applied in full to time on
target (Fitts acquisition), which is what "target acquisition" names in this codebase.
Recognition also gets the boost, at half strength, because §5.3 H1 argues recognition
is the dominant term and a mechanic that only moves the sub-second term would be
invisible. If you disagree, set `Habits.ATT_REC_SHARE = 0.0` — one number, no other
change.

---

## Deferred, and why

- **Tier 2 #9 in full** — the remaining 60 ticker keys are declared and enforced but
  still live in one bag. Splitting them into typed sub-structures is mechanical and
  safe now that the keys are declared, and is the obvious next refactor.
- **Tier 2 #11(b)**, a real BT — still a trap unless the game becomes a command game.
- **Tier 3** (civilians, verticality, grenades, penetration) — all gated on a
  direction.
- **Tier 4** (city) — untouched.

---

## Next: run the harnesses

Everything in §5.3 of the analysis is now answerable. In order:

```bash
python3 tools/gdlint.py
godot --headless --path . -s res://tests/determinism_test.gd -- --write   # baseline
godot --headless --path . -s res://tests/habits_test.gd -- --strict
godot --headless --path . -s res://tests/stall_test.gd                    # watchdogs
godot --headless --path . -s res://tests/playtest.gd -- --n=40 --cells=all  # H2
```
