# Movement and clearance investigation — 2 November 2026

[Full per-map, per-size timing tables](CLEARANCE_TIMING_2026-11-02.md) · [Raw records and reproduction](../tests/results/clearance-2026-11-02/README.md)

## Bottom line

The comparison measures two different milestones: defenders no longer fighting, and every accessible interior room recorded as cleared or checked. Across 180 fights there were **149 attacker wins, 30 defender wins and one draw**; the defenders were defeated before the final room milestone in all 149 attacker wins. An ordinary match stops at victory, so the room times after victory deliberately continue the surviving attackers with the automatic end check disabled. Two losing fights reached the room milestone before the attackers later lost. The room and fight tables therefore have different completion counts.

The independent travel model is useful as a *reference*, not a forecast or a strict lower bound. A squad is not five independently routed solo operators: it stacks, bounds, checks, enters and sometimes treats casualties. For a non-splitting squad the same map's one-operator route gives a second, serial travel reference, shown in the timing table. Neither reference includes the tactical work or combat.

In the three-seed movement-only controls, five attackers took longer than one on **11 of 12 maps**. This is not evidence that the equipped walking-speed constant is too low. It reflects the behavior being measured as well as the defects below. For example, on the **43-room Apartment Block**, the five-person independent model is **92.8 s**, the serial one-person route reference is **282.9 s**, and the actual unopposed mean is **847.6 s**. The model totals **610.9 person-metres**, versus **2,231.9 measured person-metres**. Approximately **57%** of the measured attacker-operator time was in assault/approach and **31%** in assault/entry; **54%** had less than 1 mm of displacement in a tick. This includes intentional stacking, cover and other waits, not only pathfinding faults. In these controls all five stayed in the same assault element; the model assumed independent assignments.

The behavior is not monotonic: on Walled Compound, the unopposed mean was **344.5 s with three** and **183.5 s with four**, where the four-person squad split into smaller elements. Pair splitting is conditional on being in a suitable interior, at least four available members, no recent contact, and multiple eligible small rooms. These are three deterministic seeds per cell, not a population estimate.

## Reproduced defects and fixes

### A reachable check was abandoned after 12 seconds

The check-room timeout was measured from assignment rather than from lack of progress. On Civic Plaza with one attacker and seed 101, the KIOSK checkpoint required a route around the pavilion. Straight-line distance initially *increased* even as the remaining route shortened; the old code skipped the room at **126.8 s** while the checker was still walking. The corrected run checked it at **149.0 s**. On Center-Hall Bungalow, LAUNDRY was similarly skipped at **61.7 s** but checked at **64.2 s** after the fix.

The check phase now watches remaining route progress and still skips a genuinely motionless checker. It also reassigns a lost checker, invalidates interrupted check timers, and opens a shut check-room door before checking. The group-movement regression covers the long detour, a real stall, a closed door and reassignment after a casualty.

### Two operators oscillated at a doorway

At Duplex's W FRONT, the two-person SOF stack repeatedly moved a few centimetres toward and away from its waypoint while separation pushed it back. The old jam detector reset on every forward tick, so it never recognized the lack of **net** progress. For seed 816001, the first room was marked clear at **55.3 s** after the approach and entry timeouts even though neither attacker had entered. With the fix both enter and the room clears at **21.2 s**.

In the matched three-seed *unopposed* 2v2 controls, whole-map time fell from **222.0 s to 153.1 s** (about **31%**). The pre-fix records and a patch to reconstruct that intermediate state are retained separately; the pre-fix first-room flags must not be interpreted as verified physical entries. The new detector samples remaining path length during active movement; temporary body-separation relief still enforces swept wall and closed-door collision and the operator's speed cap. Regression tests check a real Duplex stack, closed-door group crossings, no wall clipping, speed limits and deterministic repeats.

### A long entry could clear a room from across the map

In a Civic Plaza 2v2 replay (seed 822001), a survivor treated a casualty and then travelled across the map. The 45-second approach fallback started the entry while the survivor was still distant, and the nine-second entry timeout advanced to a sweep. Previously the civic pavilion was marked clear at **102.5 s**, before any assigned survivor had entered it. The entry phase now requires an active designated entrant inside the target room before advancing, steps across the room boundary when an arrival tolerance would otherwise stop outside, and promotes a surviving rear guard when all initial entrants are lost. In the reproduced continuation the survivor entered before the pavilion was marked clear.

The 45-second approach fallback can still announce an entry before the squad reaches its stack; the correction prevents it from falsely *completing* the room. If an entry is truly unreachable, the new guard can wait rather than claim success; a progress-aware entry/approach timeout and explicit unchecked outcome would be a useful follow-up. None of the 180 movement-only controls hit the 1,200-second observation cap or skipped a room.

## How to use the remaining gap

- Prefer measuring **room order, time in each phase, person-metres, casualties and pair activation** before changing movement speeds. A smaller gap to the independent model is not automatically better tactics.
- Consider testing alternative squad/pair task allocation, stack spacing and waiting policies on the Apartment Block and Walled Compound. Compare against both serial and independent travel references and preserve collision and casualty regressions.
- The defender-post route is **not a predicted kill time**. Attackers can engage from range and defenders can move; the combat table reports only actual times for victories with no defending fighters remaining.
- Room completion is the game's bookkeeping milestone, not a physical sweep of every point. Ordinary clear events in the final data were audited for an assigned entrant; a PF10 check intentionally happens from the doorway. Default doors were open; the closed-door case is a separate regression, not part of the timing matrix. Three seeds, fixed presets/spawns, a 1,200-second room cap and post-victory continuation limit generalization.
