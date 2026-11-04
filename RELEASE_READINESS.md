# The Violence — release readiness

**Analysis date:** 2026-10-24 · **Branch:** `arena/b54212be-theviolence-v1-2-1` · **Base commit:** `5a98a65` ("Godot 4.7.2 debug pass (#11)") · **Version in tree:** 1.2.1

This document is an assessment, not a changelog entry: what state the game is
actually in, what stands between it and a release, and the order to do the work
in. Everything asserted here is cited to a file or was measured on this branch.

---

## 0. The one-paragraph answer

The game itself is in unusually good shape for a one-person project — 34,458
lines of deterministic simulation, campaign and UI code behind 36 headless
harnesses, safe saves, a data-driven tuning layer, and an evidence chain from
muzzle flash to election. What blocks a release is not design, it is
**verification and packaging**. Since the 1.2.1 executable shipped, three whole
passes have landed in the tree — the Godot 4.7.2 debug pass, the doorway/nav
pass, and the ten-item playtest pass (Q1–Q10) — and until this pass **none of them had been
run on an engine**. The changelog says so in its own words: *"pending first run"*,
*"no Godot binary could run here"*. For this assessment I compiled Godot 4.7.2
from source in the sandbox and ran them: the quick tier is green, the determinism
fixture is intact, and **three boot-path defects, a text bug and a wrong statistic fell out
immediately** (§7) — which is the argument for doing this before
shipping. There was no CI and no test runner, roughly half the
harnesses cannot fail a build even when they fail, and the only Windows binary is
107 MiB, unsigned, and built from older sources on a different engine than the
project now declares. The path to releasable is short and unglamorous: **run the suites,
fix what they find, put that in CI, then rebuild and sign the thing.**

---

## 1. Where the game is

### Scope, measured from the tree

| | |
| --- | --- |
| Game code | 34,458 lines of GDScript in `scripts/` (118 files) |
| Test code | 5,069 lines across 36 files in `tests/` (34 runnable harnesses) |
| Tooling | 3,781 lines in `tools/` (static audit, PCK/PE inspectors, asset generators, ad cutter) |
| Maps | 12 (`scripts/maps/registry.gd`) |
| Content | 89 habit IDs, 34 equipment items, 7 courses, 6 echelons, 6 situation types, 6 wards, 4 allies, 3 candidates |
| Rooms per map | 175 doors across the 12 maps (`tests/nav_door_test.gd` reports the count) |
| Campaign | 40 weeks, then an election (`scripts/campaign/politics.gd`) |
| Video | 18 Ogg Theora files: 4 opening films + 14 shorts, 42.6 MB — 96% of the shipped payload |

### What has shipped and what is sitting on the branch

| Layer | In the 1.2.1 exe | In this tree | Verified on an engine? |
| --- | --- | --- | --- |
| Simulation, campaign, UI | yes | yes + Q1–Q10 pass | **partly** — quick tier, determinism, civ, brains, habits, a 40-week campaign |
| Godot 4.7.2 compatibility fixes | no | yes | **yes** — imported, loaded and ran on 4.7.2 here |
| Nav/door fixes (`line_ok`, `leaf_in_way`, `door_ahead`) | no | yes | **yes** — `nav_door_test`: 175 doors, 0 problems |
| 14 short cutscenes | no | yes (4 of 14 wired) | no |
| Balance matrix + asserted bands | no | yes (bands empty) | no |
| CI, test runner | no | **added by this pass** | workflow untested |

### Engine and version skew

- `scripts/version.gd`, `project.godot` and `export_presets.cfg` all say 1.2.1 — consistent, and the `--check` mode added here keeps them that way.
- The project now declares **4.4 and 4.7** as its engines (`project.godot: config/features`), and 4.7.2 is called primary. The shipped exe is **4.4.1** and predates every fix listed above.
- The changelog documents a 4.7.2 build **from source** (`tests/godot472_test.gd`, `tools/gd47_check.py`), so 4.7.2 support is real but has never been exercised through the export path.

**Consequence:** a release built from this tree is not a 1.2.1 patch. It is
1.3.0, with a different engine claim, different physics-adjacent code paths
(nav, doors), and a decade of untested features. Present it as such.

---

## 2. What is genuinely strong (don't break it)

1. **Determinism as a product feature.** 35 seeded fights hashed to the decimal in `tests/fixtures/determinism.json`; the city's pressure write explicitly declines to inherit a played machine's city. Very few indie sims can replay a bug.
2. **The evidence chain is real.** Muzzle flash → incident finding → IA case → statement vs bodycam → delayed press story → lawsuit → election is mechanically connected end to end (`scripts/sim/incident.gd`, `campaign/politics.gd`, `ui/ops_ui.gd`). Nothing in it is cosmetic.
3. **Save safety.** Temp file, parse-back check, swap, `.bak` fallback, and a load path hardened against parseable-but-sick data (`campaign/save_file.gd`, `godot472_test.gd`).
4. **Tuning is data, not code.** `data/habits.gd`, `data/equipment.gd`, `data/courses.gd` are single sources of truth, which is why the balance gates can be cheap to run.
5. **Documentation that tells the truth**, including about its own limits (`RELEASE.md` says plainly what was and was not verified). That is rare and it is why this assessment can be specific.

---

## 3. Release blockers

### P0-1 — The branch had never been executed (mostly closed by this pass)

Three feature passes are stacked on top of each other with static checks only.
The concrete, known-stale artifact is `tests/fixtures/determinism.json`: Q1
(stress decay), Q6 (less-lethal order, Weapons-tight cost) and Q4 (what Suggest
a Plan consumes) all change simulation or plan output, so the fixture will fail
on all 35 cases until it is regenerated deliberately. The changelog admits this
and the balance table has 11 cells reading *"pending first run"*.

**This was the first thing to do, and it is one afternoon of work, not a project.**
I did it: the quick tier passes, `determinism_test` reproduces all 35 cases
unchanged (so no fixture reset was needed after all), and the failures it did
find are the ones in §7. What remains unexecuted is the soak tier — the balance
matrix, equipment, stall, fuzz and the manual-chief campaign comparison.

### P0-2 — No CI, no single runner, and half the harnesses cannot fail a build

- **16 of the 34 runnable harnesses can fail a build** (15 with a conditional `quit()`, plus `determinism_test.gd`'s bare `quit(1)` branches). The other **18 always exit 0**, whatever they find: `civ`, `equip`, `hold`, `lethality`, `maps`, `nav_door`, `op`, `city_test`, `city_sim`, `fuzz`, `perf`, `playtest`, `sim`, `stall`, `trace`, `duel_probe`, `rig_gallery`, and the compile check itself. A regression in any of them is invisible to an automated build.
- `tests/_check.gd` — the compile check — prints `FAILED` and then exits **0**.
- There was no runner: the README asked a human to retype nine commands with their arguments, and no workflow ran them.

Fixed in this pass (§6): `tools/run_tests.sh` (`--check/--quick/--full/--soak`,
per-suite logs, log scanning for the harnesses that cannot exit) and
`tools/ci/ci.yml` (4.7.2 + 4.4.1, activate by moving it under `.github/workflows/`). **The right long-term fix is still to
give every harness an exit code** — the log scan is a net, not a fix.

### P0-3 — The Windows binary is unsigned and older than the source

- 107 MiB, x86-64, GUI subsystem, no installer, no DLLs, no side-car `.pck` (`RELEASE.md`).
- **Unsigned**: SmartScreen shows "Windows protected your PC" on first run. For a paid product that is a conversion killer; for an itch.io demo it is survivable but should be explained on the page.
- It embeds a pack that predates the 4.7.2 pass *and* the earlier unparseable-script incident described in the changelog. It must be rebuilt regardless.
- The build path is heavy: `tools/build_windows_exe.sh` compiles Godot 4.4.1 and the Windows export template from source (~90 minutes on two cores) because the build environment could not reach GitHub releases. On a normal machine, use the official export templates and cut the build to minutes.

### P0-4 — There is no licence and no third-party notice

There is no `LICENSE`, no `THIRD_PARTY_NOTICES`, and no statement of what a buyer
or player may do with the build. In-game credits (`ui/front.gd: show_credits`)
credit Godot (MIT) and claim every sprite and sound is generated in-repo — true,
they come from `tools/make_placeholders.py` and `tools/make_sounds.py` — but:

- **Remotion** (`cinematics/package.json`, 4.0.537) is not MIT; its licence requires a paid company licence for teams above its free threshold. The rendered `.ogv` files ship inside the game. Confirm the licence situation before selling it.
- **@fontsource** fonts (Open Sans, Oswald, Courier Prime) are SIL OFL and used only to render the videos; OFL does not restrict the resulting video, but keep the attribution with the Remotion sources.
- GitHub's `LICENSE` for the game itself is a decision only you can make (all rights reserved, or a source-available licence).

### P0-5 — Player-visible text was corrupted by a merge, and I fixed it

`scripts/ui/front.gd` shipped a manual with **two pages both titled
"Afterwards"**, one of them ending in a paragraph of controls pasted from a
different page, and a "Planning an operation" page whose first paragraph existed
twice in two drafts (`[Briefing] separates…` immediately followed by `Briefing:
what is known…`). This is the same class of damage as the 1.2.1 `ops_ui.gd`
merge, and it is the one screen every new player reads. Fixed on this branch; the
manual is now 8 clean pages and mentions the new Less-lethal-first order.

---

## 4. High-value gaps (P1 — fix before or at release)

| # | Gap | Evidence | Why it matters |
|---|---|---|---|
| 1 | **10 of 14 interstitial videos are never played** | `play_short`/`play_consequence_short` are called only for `s06`, `s09`, `s11`, `s12` (`main.gd:1001-1014`, `ops_ui.gd:278`); the other ten ship **8.6 MB** that no player can reach | Either wire the remaining ten (the beats are named in `cinematics/SHORTS.md`) or drop them from the export for a smaller download. Half-shipped is the worst option. |
| 2 | **No music** | `view/sound.gd` has ambience beds and 34 synthesised SFX, no score | A grid of 40 weeks with no score reads as unfinished; even one loop per screen changes the perceived production value. |
| 3 | **Balance is asserted for one matchup only** | `balance_test.gd` gates equal regulars 5v5 on 4 houses; the 11-cell matrix in `balance_matrix_test.gd` has empty actuals | The game ships 12 maps and 6 echelons. Until the matrix runs, "the balance is measured" covers ~⅓ of the surface. |
| 4 | **Onboarding rests on a suggestion button** | `campaign/autoplan.gd` can play a full 40 weeks (`op_test.gd --chief=sensible`); Veteran mode removes it | The player's only expression is planning. The Q4 reservation work narrows what the suggestion knows — prove it with the `--chief=manual` comparison before shipping the claim. |
| 5 | **No accessibility beyond red-ink and gore toggles** | `ui/settings.gd` | No font scaling, no key rebinding, no reduced-motion. Cheap to add, and a demo page usually gets asked. |
| 5b | **The display baseline is 1600×900 and Settings only offers fullscreen** | `project.godot` `[display]`; `ui/settings.gd` | On a 1366×768 laptop panel the UI is scaled down or clipped; test it there before shipping, and consider a window-size choice next to fullscreen. |
| 6 | **English strings are inline in `.gd`** | ~1,500 literals across `scripts/ui`, `campaign`, `data` | Not a launch blocker; a launch *regret*. `tr()` keys are far cheaper to introduce now than after 1.3.0. |
| 7 | **No measured performance budget** | `tests/perf.gd` prints where time goes; nothing asserts | Largest map is 20v20 in the city sim. Capture the numbers at release so 1.4.0 can be held to them. |
| 8 | **Repo hygiene** | 21 noir-prose `.md` files, `series.json`, `style_lint.py`, `test_style_lint.py`, `README (1).md`, `README (2).md` from an unrelated writing project sit in the game root; `download` is a stray file containing two `.gitignore` lines; three READMEs compete | Anyone arriving at the repo — a player, a journalist, a collaborator — reads this as a lost-merge dump. Move the prose corpus out (it even documents `tools/style_lint.py`, which lives at the root). |

---

## 5. The order to do the work

### Phase 0 — Make the branch true (days, not weeks) — *partly done, §7*

```sh
tools/run_tests.sh --check                 # every script loads
tools/run_tests.sh --quick                 # 11 gates
godot --headless --path . -s res://tests/determinism_test.gd -- --verbose
godot --headless --path . -s res://tests/determinism_test.gd -- --write   # only after reviewing each mismatch
tools/run_tests.sh --full
tools/run_tests.sh --soak                  # fills the 11 balance cells
```

Rules for this phase: fix forward, do not regenerate the fixture to hide a
difference — each changed digest should be explained by Q1/Q6/Q4 and nothing
else. Record the filled balance table in `CHANGELOG.md`, then delete the
"pending first run" language from every file that carries it.

### Phase 1 — Make the branch stay true (one week)

1. Give the 15 diagnostics an exit code (`quit(1 if failures > 0 else 0)`); then delete the log-scanning fallback from the runner.
2. Move `tools/ci/ci.yml` to `.github/workflows/ci.yml` (or reconnect GitHub with workflow scope) and get it green on both engines; make the full tier required on `main`.
3. Bump to **1.3.0** in `scripts/version.gd`, run `python3 tools/sync_version.py`, commit all three files.
4. Add `LICENSE`, `THIRD_PARTY_NOTICES`, and confirm the Remotion position.
5. Move the prose corpus and the duplicate READMEs out of the game root; delete `download`.
6. Decide the cutscene question: wire the ten unwired shorts, or exclude `assets/cutscenes/shorts` from the export preset.

### Phase 2 — Make it shippable (two to three weeks)

7. Rebuild the Windows exe from this tree with official templates; verify the pack with `tools/inspect_pck.py --verify` and the PE with `tools/inspect_exe.py`.
8. **Test on real Windows hardware.** This has never been done — `RELEASE.md` is explicit about it. Boot, play a week, save, reload, alt-tab, resize, quit.
9. Code-sign, or publish through a storefront that carries the warning for you, and say on the page what SmartScreen will show.
10. Produce store assets from what already exists: `tools/make_ads.py` cuts deterministic trailers from the game itself with `--soundlog` + `tools/mix_soundtrack.py`; `tools/ad_card.gd` draws title cards in the game's own hand. Screenshot hooks already exist (`--front=manual|settings|credits|pause`, `--shot=`, `--ops`).
11. Decide the price/positioning. The project calls itself a *vertical slice* in `project.godot`; a free or low-cost demo on itch.io is the honest framing for 12 maps and 40 weeks, with 1.4.0 aimed at the paid release.

### Phase 3 — Release mechanics

12. Release notes from `CHANGELOG.md`; publish SHA-256; attach the exe to a GitHub Release (it cannot live in the tree — `release/*` is ignored for exactly this reason).
13. Post-release: a crash/bug path that does not require GitHub literacy (a `user://logs/godot.log` note on the credits page is enough for v1).
14. Keep the soak tier running on `main` weekly so the balance bands cannot rot unnoticed.

---

## 6. What this pass changed

| File | Change |
| --- | --- |
| `scripts/ui/front.gd` | Manual repaired: two duplicate "Afterwards" pages merged into one, the doubled "Planning an operation" paragraph de-duplicated, the order list now names all nine constraints including **Less-lethal first**, and the contact-aware fast-forward note moved to the debrief page where it belongs. 9 pages → 8. |
| `tools/run_tests.sh` | New. Tiered headless runner (`--check/--quick/--full/--soak/--list`), per-suite logs in `build/test-logs/`, timeouts, exit codes, and log scanning for the harnesses that cannot fail a build. |
| `tools/ci/ci.yml` | New. Static audit + version-sync check, quick tier on Godot 4.7.2 **and** 4.4.1, full tier on `main` and on demand, logs uploaded on failure. This working session's GitHub app cannot create files under `.github/workflows/`, so it ships one directory over: `mkdir -p .github/workflows && git mv tools/ci/ci.yml .github/workflows/ci.yml` activates it, and nothing inside refers to the path. |
| `tools/sync_version.py` | New `--check` mode: reports version drift between `scripts/version.gd`, `project.godot` and `export_presets.cfg` and exits 1, without rewriting. Rejects unknown arguments. |
| `README.md` | Headless-checks section now leads with the runner and the tiers; the individual commands stay for debugging. |
| `scripts/campaign/department.gd` | Two boot-path defects found by the first engine run and fixed: `Equipment.normalize()` was handed `null` for a save with `"kit": null`; `payroll()` indexed `status` on records that had lost it. `_fix_record` now fills the identity fields a damaged record can lack. |
| `scripts/campaign/politics.gd` | The end-of-campaign summary no longer doubles its nouns ("7 stories stories"); `share()` reads an unknown candidate id as 0.0 instead of raising. |
| `scripts/campaign/story_archive.gd` | Contact ids mapped to candidate ids: Dana Okonjo-Vale's poll share was 0.0% and logged an engine error on every archive page. |
| `tests/godot472_test.gd` | One inverted assertion corrected: a campaign save with no department block is *refused*, not loaded as an empty department. |

Verification of these changes:

- `python3 tools/gd47_check.py` → `118 GDScript files scanned / clean`.
- `bash -n tools/run_tests.sh` → clean; `--list` and `--help` behave; the failure path was exercised by breaking `project.godot`'s version on purpose (`--check` → exit 1, restored).
- Cross-reference audit (a check no tool in the repo performs): all **89 habit IDs** defined in `data/habits.gd` were matched against every `"XXnn"` literal in `scripts/`, and there is **no reference to a habit that does not exist**. The 7 course IDs and the 18 equipment keys used by `Equipment.default_kit()` likewise resolve.
- Everything engine-backed is reported in §7.

---

## 7. Measured on this branch

### The engine was built for this pass

No Godot binary ships in this sandbox and `release-assets.githubusercontent.com`
is outside its network allow-list, so **Godot 4.7.2-stable was compiled from
source here** (codeload tarball; scons; `x11=no wayland=no alsa=no pulseaudio=no
dbus=no udev=no speechd=no fontconfig=no lto=none -j2`; ~46 minutes on two cores,
158 MB, `4.7.2.stable.custom_build`). That makes the rest of this section
measured rather than argued. The build is in `/tmp`, not in the repo.

A real Godot 4.7.2 binary also means the 4.7.2 compatibility pass is now more
than a static claim: the project imports (158 asset steps, 6 s), every script
loads, and the game's headless harnesses run.

### Results

| Suite | Result | Notes |
| --- | --- | --- |
| `_check.gd` | **PASS** | all 118 scripts load on 4.7.2 |
| `improvements_test` | **PASS** | |
| `city_improvements_test` | **PASS** | 6 s |
| `ops_ui_test` | **PASS** | |
| `dept_test` | **PASS** | |
| `save_test` | **PASS** | |
| `story_test` | **PASS** | |
| `politics_test` | **PASS** | |
| `city_link_test` | **PASS** | |
| `godot472_test` | **FAIL → PASS** | 2 real defects, fixed below |
| `orders_test` | **PASS** | 275 s — the `less` gate (n_min 16) is 90% of the quick tier |
| `determinism_test --verbose` | **PASS** | **35 cases, 0 changed, 118 s** |
| `maps_test` | **PASS** | 12 maps, 0 problems |
| `nav_door_test` | **PASS** | **175 doors across 12 maps, 0 problems** — the doorway claims hold on the engine, not just in the Python port |
| `city_test` | **PASS** | 1,903 room paths, 60 cross-city paths, 0 problems |
| `habits_test --strict` | **PASS** | 0 failures |
| `brains_test --n=8` | **PASS** | 0 failures, 82 s |
| `civ_test --n=40` | **PASS** | gate: civilians hit by police, patrol 30 vs police tactical 20 |
| `lethality_test --n=6` | ran | 0.67 officers down, 0.00 killed per operation; 0 police rounds hit police |
| `op_test --weeks=40 --chief=sensible` | ran | 1,000 s: election held (Pell 35%), kept with exactly 4 deficit weeks, 47 operations succeeded / 4 failed / 56 situations unattended, 11 officers killed |

**Two claims in the changelog are now confirmed, and one is refuted:**

- Confirmed: the doorway pass (`line_ok`, `leaf_in_way`, `door_ahead`) is real — `nav_door_test` reports 175 doors and 0 problems on a genuine engine.
- Confirmed: the 4.7.2 source only needed the static audit's conclusions — the tree imports and boots headless.
- **Refuted:** *"the determinism fixture needs a one-time `--write` before the suite is green again."* It does not. All 35 seeded cases reproduce **byte-identically** under the Q1/Q6/Q4 changes. That is worth knowing on its own: the rally reset and the less-lethal order never fire in the fixture's first-week operations, so the new behaviour is currently untested by the determinism net — which is an argument for adding a fixture case that *does* exercise them, not for resetting anything.

### Four defects the run found (all fixed on this branch)

1. **The boot path still threw on a null kit.** `_fix_record` did
   `Equipment.normalize(r.get("kit", default))`; `get()` returns the *null value*
   when the key exists with null, not the default, so a save with `"kit": null`
   raised `Cannot convert argument 1 from Nil to Dictionary` while the game was
   starting (`department.gd:1121`). The fallback immediately after the call was
   correct but too late. Now the argument is checked before the call.
2. **`payroll()` indexed `r["status"]` on records that had lost it**, raising
   `Invalid access to property or key 'status'` on the same boot path
   (`department.gd:293`). `_fix_record` now fills the identity fields a damaged
   record can be missing — `status`, `name`, `rank`, `ech`, the habit arrays, the
   course queue — and payroll reads `status` with a default.
3. **The end-of-campaign summary printed the noun twice**: *"7 stories stories
   reached the papers; 3 lawsuits lawsuits settled; 0 cases cases leaked."* The
   `_n()` helper already pluralises (`"7 stories"`), and the sentence appended
   `" stories"` again (`politics.gd:619`). Only a full 40-week run reaches that
   line, which is why no unit test had ever seen it. Fixed and verified by
   calling `Politics.ending()` directly.

4. **The story archive printed Dana Okonjo-Vale's poll share as 0.0% and logged
   an engine error every time the page opened.** `story_archive.contact_status()`
   passed the archive's contact id `"dana"` straight to `politics.share()`, whose
   poll keys are the candidate ids (`"okonjo"`); the read raised `Invalid access to
   property or key 'dana'` (`story_test` exits 0, so only the log showed it). The
   ids are now mapped, and `share()` reads with a default so an unknown id is 0.0
   rather than an error.

**One test assertion was inverted.** The last failure of `godot472_test` was
`check(ok2, "campaign loads a save with no department block (no throw)")`.
`Campaign.from_data()` returns false there, because `Department.from_data({})`
hits the version guard and refuses. Returning false is the *right* behaviour —
loading a department-less save as an empty department would let the next save
write over the `.bak` and lose the campaign — so the assertion, not the code, was
wrong. It now asserts refusal, with the reasoning written next to it.

### What was not run (the soak tier)

`balance_test --gate`, `balance_matrix_test`, `scale_playtest --gate` (the
11 balance cells are therefore **still** "pending first run"), `equip_test`,
`stall_test`, `fuzz_test`, `city_sim --min=10`, `perf`, and
`op_test --chief=manual` (it needs ~1,000 s and the wall clock here ran out).
Those are what `tools/run_tests.sh --soak` exists for; run it on a machine with
more than two cores.

### One thing to watch in the gates

`civ_test --n=8` **fails** the civilian gate (patrol 1, police 5) and
`civ_test --n=40` **passes** it (patrol 30, police 20). The gate is a pooled
comparison of small counts and is sample-size sensitive; 8 seeded operations is
noise. The default of 40 is the documented size and the runner uses it, but
nobody should lower it to make CI faster without changing what the gate means.


---

## 8. Open questions for the owner

1. **What is the release?** Free itch.io vertical slice, paid Steam launch, or a portfolio build? The answer changes Phases 2–3 more than it changes the code.
2. **Code signing?** ~$100–400/year for an OV certificate (or an EV one to skip SmartScreen reputation), or accept the warning and explain it.
3. **Is the score a design choice or a gap?** "No music" reads one way in a noir piece and another way in a store page.
4. **Do the ten unwired shorts get wired, or cut?** Both are defensible; shipping neither is not.
5. **How much of the Q4/Q1/Q6 behaviour does a player have to perceive?** Some of it (rally reset, statement integrity) is currently invisible; a debrief line each would double its value.
