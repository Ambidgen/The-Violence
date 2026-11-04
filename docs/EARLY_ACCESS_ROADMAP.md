# The Violence — roadmap to Steam Early Access

Written 2026-10-28 from a fresh playtest of the 27 Oct tree (`The-Violence-27-Oct-26-main`, runtime still reads 1.2.1) on Godot 4.7.2. Evidence, logs and screenshots: [`PLAYTEST_2026-10-28_CAMPAIGN.md`](PLAYTEST_2026-10-28_CAMPAIGN.md). This replaces the "ten recommendations" list in `PLAYTEST_2026-10-27.md` as the working plan; that list's items are carried in here and marked.

---

## 1. Verdict

**Viable, but not yet shippable — roughly two milestones of work away.** The part that is hard to build is built: a deterministic CQB simulation, a hands-off planning loop that reads clearly (briefing with confidence-tagged facts → force → orders → live run → debrief with the score arithmetic), a campaign layer with a real evidence chain, and a distinctive look. The part Valve's Early Access bar and a paying player will test first — *does a forty-week run hold together?* — does not hold yet:

| Seed (40 weeks, desk answered at random by the harness) | Chief at the election | Fit officers (of 20) | Week-end account | Allies at the end | Officers killed | Calls left unattended |
|---|---|---|---|---|---|---|
| 1001, hire + train | **fired** (Okonjo-Vale, 54%) | 12–15 mid-run, **5** at the end | **below $0 in 24 of 40 weeks**, −$491K at the end | 0 of 4 | 16 | 48 |
| 2002, no hiring | kept (Kettering, 35%) | **4–8 from week 7 on** | never below $0; **$369K unspent** | 0 of 4 | 13 | 80 |
| 3003, hire | kept (Kettering, 41%) | **2** at the worst (week 22) | **below $0 in 24 of 40 weeks** | 0 of 4 | 13 | 69 |

Three seeds is a small sample, but all three fail the same four ways, and they are the same four ways the 27 Oct playtest found. None of its ten recommendations has landed in the simulation or the economy; the money, roster and ally curves are unchanged. That is the critical path.

Three further findings are blockers on their own: the **crowd-escalation cascade** (still in the sim), the **duplicate contract charge** (6 of 12 seeds deal it), and **Steam plumbing that does not exist yet** (no Steamworks, no achievements, no cloud saves, no controller input handling (none found in `scripts/`) or Deck path, no signed Windows build ever run on Windows).

What to protect while fixing: the briefing/debrief clarity, the ward-map board, the evidence chain, determinism as a product feature, and the crayon look. Everything below is arranged so those survive.

---

## 2. The bar (what Valve and the market require)

**Valve's Early Access rules** ([Steamworks: Early Access](https://partner.steamgames.com/doc/store/earlyaccess)):
- Must be a **playable alpha/beta worth its current price** — "a tech demo or early concept isn't enough." At minimum a **gameplay trailer**; a closed test first is advised for unfinished loops.
- You must be **planning to keep developing** it, and may not use Early Access as crowdfunding.
- **No specific promises** about dates, completion or planned features. Disclose known issues up front (for example "updates may break saves").
- No permanent discounts; Early Access price may not exceed any other store; Steam can't be later than anywhere else.
- Complete the **Early Access Q&A** (goals, duration, current state, differences from 1.0, pricing plans, community plans). Keep it current; Steam shows a notice if **12 months** pass without a build or update post.
- Cannot go back to Coming Soon, and cannot return to Early Access after release.

**Review timing** ([Steamworks: review process](https://partner.steamgames.com/doc/store/review_process)): store page review 3–5 business days (submit ≥7 business days before you want it live); build review 3–5 business days (plan ≥7). Screenshots must be gameplay only; the build must launch on every OS the page lists; everything the page lists must exist in the build.

**Disclosure**: Valve's January 2026 rewrite asks for disclosure of AI used to create *content* (art, audio, text) shipped in the game, on the page or in marketing, and AI that generates content at runtime; AI *dev tools* such as code assistants are explicitly not the focus ([VGC summary](https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use)). Decide honestly which of the game's text and art that touches, and fill in the survey accordingly.

**Market benchmarks** (survey of the February 2026 Next Fest, [How To Market A Game](https://howtomarketagame.com/2025/03/26/benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/)): wishlists *before* the fest are the best predictor of fest results; the author suggests ≥2,000 going in; median fest gain is ~1,000 for games entering with 1,000–9,999; demo-to-wishlist conversion medians ~16%; demos launched well before the fest earned ~2.5× the wishlists. The source has no wishlist→sales conversion; treat any sales forecast as unknown.

**Next Fest dates that matter** (Steamworks): **Feb 22 – Mar 1, 2027** (register by **Jan 10**, submit demo and page by **Jan 18** for the press preview) and **June 14–21, 2027** (register by **Apr 25**, submit by **May 10**, everything by **May 24**). A game can appear in only one Next Fest. [Feb 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027) · [Jun 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/june_2027)

---

## 3. Where the game stands against the bar

| Bar | Status | Evidence |
|---|---|---|
| Playable and coherent | **Amber** | Loop plays end to end headless and rendered; a first operation, debrief and week 2 worked in the rendered click-through. |
| "Worth its price" over a run | **Red** | Economy, roster and ally curves collapse in 3/3 runs (§1). |
| Not a tech demo | **Green** | 12 maps, 8 doctrines, 16 contracts, 20 events, 14 offers, politics, IA, press. |
| Content that survives replays | **Amber** | Run layer exists; untested for dominance (no balance harness yet). |
| Gameplay trailer + clean screenshots | **Amber** | `tools/make_ads.py` and in-engine screenshot hooks exist; nothing cut yet; some screens currently show a stale map. |
| Stable and honest build | **Amber** (as of cycle 0.D, 2026-10-28) | The harnesses exit honestly and CI is active on 4.7.2 and 4.4.1; the version line is **1.3.0 Early Access**; `LICENSE` and `THIRD_PARTY_NOTICES` exist and ship in every export; Remotion is settled under its free licence; the user directory is fixed. Still red inside this row: 22 of 35 determinism cases changed (the fixture is stale, not platform noise) and the unsigned exe has never run on Windows. |
| Steam integration | **Red** | No Steamworks SDK/GodotSteam, achievements, cloud saves, rich presence, Steam Input; settings offer fullscreen only (no resolution, UI scale, rebinding, language). |
| Legibility on target hardware | **Amber** | Management text is 10–12 px at 1600×900; hover-only reasons for disabled buttons; Steam Deck (1280×800) untested. |
| Audio/finish | **Amber** | No music; 10 of 14 shorts never play; sfx and ambience present. |

---

## 4. The roadmap

Sizes: **S** ≤ 1 day · **M** 2–4 days · **L** 1–2 weeks · **XL** > 2 weeks. Each phase ends in a **gate** — a command that passes or fails — so "done" is measured, not felt. Order matters: phases 0–1 change the simulation and economy, so everything that records numbers (fixtures, trailer footage, balance bands) waits until they land.

### Phase 0 — Make the build tell the truth *(≈ 1 week)*

| # | Work | Size |
|---|---|---|
| 0.1 | Fix the **duplicate procurement** charge: re-validate drafts after the inheritance pick and again at purchase; replace or disable a now-redundant card; never charge for an item already in the armoury (`rogue.gd` `pick()`). Probe: 6 of 12 seeds deal plates in both drafts. | S |
| 0.2 | Give every harness an exit code; make `run_tests.sh` timeouts scale with `nproc`; move `tools/ci/ci.yml` to `.github/workflows/`. (`_check.gd` already exits 1 on failure — keep.) | S–M |
| 0.3 | **Do not rebaseline determinism yet.** Re-run after Phase 1, review the diffs, then `--write` deliberately and say why in the changelog. | — |
| 0.4 | Repo hygiene: `LICENSE`, `THIRD_PARTY_NOTICES` (Godot MIT, Patrick Hand OFL, others), settle the **Remotion** commercial licence for the rendered videos. | S |
| 0.5 | Version: choose an EA numbering (suggest **1.3.x** = Early Access, 2.0 = release; going down to 0.9 risks confusing save/legacy migrations), set `scripts/version.gd`, run `tools/sync_version.py`. See `EA_TASKS.md` P0.D1. | S |

**Gate 0:** `tools/run_tests.sh --quick` green with honest exit codes; the 12-seed duplicate probe reports 0 wasted purchases.

### Phase 1 — Make a forty-week run hold together *(the critical path, ≈ 3–5 weeks)*

This is where the product is won or lost. Build `tests/rogue_balance_test.gd` **first** (it was recommendation 8): ≥ 20 seeds × 40 weeks × four fixed desk/chief policies — *cautious* (hire, train, restraint contracts), *minimal*, *military-first*, *always-accept* — recording lowest fit roster, weeks below $0, unattended calls, deaths, allies lost/won back, election result, run score. Then tune against its numbers.

| # | Problem (evidence in the playtest doc) | Direction | Size |
|---|---|---|---|
| 1.1 | **Crowd cliff.** At trauma 14, 8 of 8 quiet rallies (no attack) killed civilians: **52 killed** total. At the roster's *natural* trauma, 3 of 8 still did (6 killed). | Fix it in the simulation (`world.gd` `misjudge_p` / `add_stress`): bound the stress feedback after a misjudged civilian engagement, stop panic compounding, force a rally reset for that squad. Keep real attacks answered. Extend `event_probe.gd` to count *distinct* civilians. | L |
| 1.2 | **Roster bleed.** 0.21–0.25 officers killed per operation; fit officers fall to 2–8 and stay there; 48–80 calls go unattended. | Lower avoidable lethality or raise recovery; make hiring bite (same-week laterals at a premium); show a **next-week strip** on the board (fit vs what the open calls want) with a warning below 12. | L |
| 1.3 | **Money curve.** Runs with hiring go negative by week 5–8 and stay there (freezing the very hiring/training/kit that fixes it); the run without hiring ends with $369K and nothing to buy. | Early reserve/credit with a visible cost; stop a hire or course the forecast says will go negative (warn first); charge kit through overtime rather than at assignment; add real late-game sinks (capital items, union contract, tier-3 programs at higher price). | L |
| 1.4 | **Allies are a one-way door.** All four lost in 3/3 runs (first loss between weeks 3 and 12; three of four lost by weeks 13–25); none ever won back. | Reconciliation offers from a lost ally (large cost, standing +20; at most one every four weeks); tune loss rate so a bad run loses 1–2, a good run 0–1. | M |
| 1.5 | **Outcome ignores performance.** Two wrecked departments (13 dead, 69–80 calls dropped) *kept* their chief under Kettering. | Couple the election to the record (restraint, harm, neglect) so cautious play wins the office more often than neglect; say plainly in the Ledger why. | M |
| 1.6 | **Rally pacing.** Every public event is a 900-simulated-second run; at the default 2× that is ~7.5 minutes watching "nothing happened"; 17–23 of them per run. `adaptive_speed` exists and is off. | Fast-forward through quiet by default; or resolve quiet rallies headless and show the report. Measure CPU on a min-spec laptop (a rally cost 30–50 s of CPU in this 2-core sandbox). | M |
| 1.7 | Prove planning matters. | `op_test --chief=manual` vs `sensible` across the 20 seeds: an informed chief should beat the one-click suggestion, or the "skill is planning" thesis is not demonstrable. | M |

**Gate 1 (proposed thresholds — agree them with the designer):**
- `event_probe --trauma=14` over 20 seeds: ≤ 1 distinct civilian struck per quiet event; `--trauma=0` unchanged or better; a real attack is still answered.
- *Cautious* policy, 20 seeds: ≥ 12 fit officers in ≥ 90% of week-end snapshots; no week below $0 in weeks 1–12; ≤ 25 unattended calls over the run.
- No single policy dominates all of score/deaths/allies/money; *minimal* does **not** end with an unspent six-figure account.
- ≥ 1 ally lost *and* won back in ≥ 5 of 20 runs.
- *Cautious* keeps the office in clearly more seeds than *minimal*.
- Re-run determinism; review each diff against Phase 1 changes; **now** rebaseline with `--write`.

### Phase 2 — Make it Steam-shaped *(≈ 2–3 weeks, can overlap late Phase 1)*

| # | Work | Size |
|---|---|---|
| 2.1 | **Steamworks app + depots**; create the app, pay the app fee, set up the Windows depot, a `beta` branch for testers. | S |
| 2.2 | **GodotSteam** (verify a release for the engine you ship; the project supports 4.4.1–4.7.2 — pick one and pin it). Initialise, overlay, **achievements** (run outcomes, the "no civilian harm" style goals, doctrines unlocked), **cloud saves** (`user://campaign.json`, `legacy.json`, `settings.cfg`), rich presence ("Week 17 of 40"). | L |
| 2.3 | Settings: window mode + **resolution**, **UI scale**, reduced motion (boil already toggles), key **rebinding**, text-size, colourblind-safe red-ink alternative. | M |
| 2.4 | **Controller / Steam Deck**: at minimum make every management screen keyboard- and controller-navigable and the text legible at 1280×800; aim for Deck "Playable" first, "Verified" later. (Valve's thresholds change; check before promising.) | L |
| 2.5 | Windows release pipeline: official export templates (`tools/build_windows_exe.sh` compiles Godot from source today — drop it), code signing or a clear first-run note, SHA-256, and — the one that has never happened — **a real Windows 10/11 run**: boot, a week, save, reload, alt-tab, resize, quit. Fix `tools/inspect_pck.py` (it only reads pack format 2; 4.7 writes 4). Optionally a Linux build (Godot exports it; `play.sh` exists). | M–L |
| 2.6 | Save robustness for a live product: save-version migration test, corrupt-save fallback test (the `.bak` path exists), "your save will not survive this update" notice mechanism, in-game *Open logs folder* button and a one-click bug-report text. | M |
| 2.7 | Localization scaffolding: ~1,500 inline strings today, zero `tr()`. Not a launch blocker; a cheap regret-avoider *now*, costly later. At least wrap new strings. | M (scaffold) |

**Gate 2:** a signed (or clearly flagged) build installed **through Steam** on a clean Windows machine completes a full week and survives save/quit/reload; achievements fire; cloud save round-trips between two machines.

### Phase 3 — Make the first hour clear *(≈ 1–2 weeks)*

Everything here was seen in the rendered click-through at 1600×900.

| # | Finding | Fix | Size |
|---|---|---|---|
| 3.1 | **Stale tactical map behind management screens.** The board draws the Port Carrick ward map, but the inheritance/procurement/program drafts, Roster, Budget, Internal Affairs and City Hall all sit over the *previous operation's* map (a Test Range house in week 1). It also shows red "FILED / NOT RESOLVED" stamps from a finished op. | Keep the city map (or a person/portrait/ledger panel) on the left for every management screen; remove the test-range map. | M |
| 3.2 | First week's first action is **disabled with a hover-only reason** ("Choose your inheritance on the desk first"). | Make the next required action and the reason visible text; scroll/focus the desk. | S |
| 3.3 | Text is 10–12 px in the briefing, debrief, roster. | UI scale + larger defaults; test at 1280×720 and 1280×800. | M |
| 3.4 | The guide walks one call. Ending week 1 as a new player might (one call done, two open) leaves two unattended, and the week-2 board only says a call "is due to reach the papers". | Warn at End week when open calls will be recorded as unattended, and say what that costs. | S |
| 3.5 | Debrief is excellent but dense. | Add a three-line summary above the arithmetic; keep the timeline replay. | S–M |

**Gate 3:** two people who have never seen the game reach a debrief without help; note where they stall, fix the top three stalls, repeat once.

### Phase 4 — Content floor and finish *(≈ 3–4 weeks)*

| # | Work | Size |
|---|---|---|
| 4.1 | **Music**: one bed per screen family (title, board, operation, debrief). Even four loops change the perceived production value. | M |
| 4.2 | Wire the **ten unplayed shorts** at the beats `cinematics/SHORTS.md` names, or drop them from the export (8.6 MB). Half-wired is the worst option. | M |
| 4.3 | Decide the cutscene look: they are still in the older red-ink hand while the game is crayon. For EA it is fine to ship the openers as-is *and say so*; re-rendering is post-EA. | S (decision) |
| 4.4 | **More variety per run**: with 20 events, 14 offers, 16 contracts, expect repetition by the third run. Target for EA: ~35 events, ~24 offers, a second tier of doctrines unlocked by the legacy file. Add content *after* Phase 1, since new content multiplies balance work. | L |
| 4.5 | **Port Carrick binding**: sites already pull addresses from `city.json`; that is enough for EA. Defer deeper city mechanics (bridge closures etc.). | — |
| 4.6 | Recover or consciously drop the **1.5 command layer** (zones, squads-as-placement, maps 12–15). Per the README it was built in another session and never reached this tree. Decision: re-integrate before EA, or ship with 12 maps and list the rest as plans. | decision, then L–XL |

### Phase 5 — Store, demo, testers *(starts as soon as Gate 1 passes; runs in parallel with 2–4)*

- **Store page & capsule**: readable title/logo capsule, gameplay-only screenshots, a gameplay trailer cut with `tools/make_ads.py` (it records the game itself). Put the page up as **Coming Soon** once it can be reviewed; wishlists start accumulating the day it is public.
- **Demo**: the first ~10 weeks of a run (inheritance, first procurement and program, a first event and election-news beat), clearly ending on a card. Its own store page is recommended below ~10k wishlists (benchmark source above). Ship it **well before** the festival.
- **Closed test**: Steam Playtest (or a small invite list) of 20–50 players on a *beta* branch **after Gate 1**; watch for dominant strategies and for people dropping out in weeks 6–12.
- **Content survey**: violence and gore (the gore toggle is a strength — say so), police-violence themes; AI-content disclosure per §2.
- **Early Access Q&A (draft now, so the roadmap is honest)**: *why EA* — balance and content breadth benefit from player data; *planned length* — a range, not a date; *what's in now* — 12 maps, the full 40-week run, run layer, politics; *what changes* — more events/offers/doctrines, controller support, localization, re-rendered cutscenes; *price* — below the intended 1.0 price; *community* — Discord/Steam forum, patch notes with every build. Per Valve, phrase future items as plans, not promises.

### Phase 6 — Launch checklist

- [ ] Gates 0–3 green; the full tier and the soak (`balance_matrix`, `rogue_balance`) pass on the release commit.
- [ ] Release build uploaded to the default branch; **submit build review ≥ 7 business days** before launch; store page + EA Q&A approved.
- [ ] Price set below the intended 1.0 price (my judgement: a low-teens-dollar ceiling for a 4–8 hour roguelike run with replayability; adjust once the demo's wishlist conversion is known). No permanent discounts allowed; no discount within 30 days of a base-price increase.
- [ ] Known issues listed on the page; save-compatibility policy stated.
- [ ] Launch-day patch notes drafted; community hub and forum open; a crash/bug path that does not require GitHub literacy.
- [ ] Press/streamer keys to a short list a week ahead; the trailer and demo already public.

### After launch (plans, not promises)

Patch every 2–3 weeks for the first two months, then monthly. Watch: run completion rate (weeks reached), election outcome distribution, most-picked doctrines/contracts, ally-loss timing. A **1.0** definition worth stating: full music and shorts, controller/Deck verified, localization for 2–3 languages, a post-launch event/offer pool double the EA size, re-rendered cutscenes, and the 1.5 map/command layer if it returns. Steam shows a notice if 12 months pass without an update; plan around it.

---

## 5. Calendar options (anchored on real Steam dates)

Assumes focused full-time effort; **double the durations if you are working evenings and weekends.** Today is 28 Oct 2026.

**Option A — June 2027 Next Fest, summer Early Access (recommended).**
- Nov 2026 – Jan 2027: Phase 0 and Phase 1 (+ Phase 3 UX fixes). Gate 1 by mid-January.
- Jan – Feb 2027: Phase 2 (Steam plumbing) and Phase 5 store page + trailer; page review submitted; **Coming Soon** live by end of February; closed playtest on a beta branch.
- Mar – Apr 2027: Phase 4 content/music; demo built and tested; demo public in **April** (well before the fest). **Register for Next Fest by Apr 25.**
- **May 10** submit demo + page; **May 24** all items; **June 14–21** Next Fest.
- **EA launch late June – July 2027**, while fest wishlists are fresh; build review submitted ≥ 7 business days before.

**Option B — February 2027 Next Fest (aggressive, not recommended).** Needs registration by **Jan 10** and a reviewed page + demo by **Jan 18**: eleven weeks to close Phase 1, build the Steam page and trailer, and have a stable demo. It can be done only if Phase 1 lands in about five weeks and everything else slips to after the fest. A weak or buggy demo in the single Next Fest a game is allowed is a costly way to learn the balance is off.

**Option C — skip Next Fest, soft launch.** Public demo plus Steam Playtest, EA launch when Gate 3 passes. Lowest risk, lowest visibility; reasonable if wishlists stay under ~1,000.

---

## 6. What not to do before Early Access

- Don't re-render all cutscenes in the crayon look.
- Don't bind deeper Port Carrick mechanics (bridge closures) or add new maps before the run is balanced; new content multiplies balance work.
- Don't build multiplayer, mod support or a level editor.
- Don't rebaseline determinism until Phase 1 is finished.
- Don't make date or feature promises on the store page.

## 7. Risks

| Risk | Mitigation |
|---|---|
| Phase 1 balance takes longer than planned (the sim is deterministic but the economy and politics are tangled). | Build the balance harness first; keep changes small and gate-tested; if a gate won't close, reduce scope (fewer allies, simpler money) rather than slip the schedule. |
| Rally runs are slow on modest hardware. | Fast-forward or headless resolve for quiet events; measure on a min-spec laptop in Phase 2. |
| Never run on real Windows hardware. | Do it in Phase 2 before any store submission; add the Steam client path to the test. |
| Content tone (police violence) draws moderation or press scrutiny. | Ratings survey honestly, keep the gore toggle prominent, and let the game's restraint-versus-militarisation design carry the framing. |
| Single-person bandwidth. | Phase order is strict; Phases 2 and 5 can be done in short bursts alongside Phase 1 waiting on harness runs. |

## 8. Decisions only you can make

1. EA price and the 1.0 price you intend.
2. Whether to recover the 1.5 command layer and maps 12–15 before EA, or ship 12 maps and plan the rest.
3. Next Fest A, B or C (§5).
4. The threshold numbers in Gate 1 (they encode how hard you want the game to be).
5. Which text and art should be listed under the AI-content disclosure.

## Status of the 27 Oct ten recommendations

| # | Recommendation | Status in this tree |
|---|---|---|
| 1 | Remove the trauma cliff in the sim | **Open** (reproduced: 52 civilians killed in 8 quiet rallies at trauma 14) |
| 2 | Roster as a live constraint + emergency lateral | **Open** (budget has a four-week forecast; no roster strip, no emergency lateral) |
| 3 | Fix the money curve | **Open** (reproduced both failure modes) |
| 4 | Give lost allies a way back | **Open** (0 recoveries in 3 runs) |
| 5 | Use the left side of management screens | **Partial** (board has the city map; drafts, roster, budget, IA, City Hall do not) |
| 6 | First operation must not spend on its own | **Fixed** (opening a briefing changed the account by $0; the $805 is overtime) |
| 7 | Make harnesses fail honestly | **Partial** (`_check.gd` exits 1 on failure; many diagnostics still always exit 0; CI inactive) |
| 8 | Balance the run layer with numbers | **Open** (no `rogue_balance_test.gd`) |
| 9 | Finish content / music | **Open** |
| 10 | Ship it properly | **Open** (still 1.2.1, no LICENSE, never run on Windows) |

*Sources: Valve [Early Access](https://partner.steamgames.com/doc/store/earlyaccess) and [review process](https://partner.steamgames.com/doc/store/review_process) docs; Next Fest [Feb 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027) and [Jun 2027](https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/june_2027); [How To Market A Game benchmarks](https://howtomarketagame.com/2025/03/26/benchmarks-how-many-wishlists-can-i-get-from-steam-next-fest/); [VGC on the Steam AI disclosure rewrite](https://www.videogameschronicle.com/news/valve-has-significantly-rewritten-steams-rules-for-how-developers-much-disclose-ai-use). Price guidance, effort sizes and gate thresholds are my judgement, not Valve's.*
