# Cycle 0.D — version, licence, hygiene (2026-10-28)

Cycle 0.D of [`docs/EA_TASKS.md`](../../../docs/EA_TASKS.md), the last cycle of Phase 0
and the end of **Gate 0**. Three decisions were the owner's; everything else here follows
from them.

## The decisions

| ID | Decision | Consequences in the tree |
|---|---|---|
| P0.D1 | **1.3.x = Early Access, 2.0 = the 1.0 release**; the tree moves to **1.3.0** | `scripts/version.gd` (`VALUE`, `CHANNEL`); `project.godot`, `export_presets.cfg` via `tools/sync_version.py`; **EARLY ACCESS** stamp on the title plate; `patch_rc.py` fallback removed |
| P0.D2 | **Proprietary, all rights reserved**, with reading, review quoting and pull-request contributions allowed | `LICENSE` (new), `THIRD_PARTY_NOTICES` (new), credits screen, export `include_filter`, Windows company/copyright metadata |
| P0.D3 | **Remotion's free licence applies** (individual / ≤ 3 people / non-profit): no company licence, no re-render | recorded in `THIRD_PARTY_NOTICES` §3 with the trigger for revisiting; P4.C1 unchanged |
| P0.D4 | **Fixed user directory now**, before any cloud-save path exists | `project.godot` `use_custom_user_dir` + `custom_user_dir_name="TheViolence"`; `Settings.migrate()` carries both older folders and `legacy.json` |

## Files

| File | What changed |
|---|---|
| `LICENSE` | new: proprietary terms, third-party pointer, no-warranty, contact |
| `THIRD_PARTY_NOTICES` | new: Godot MIT, Patrick Hand OFL, Remotion + render fonts + React, Python asset tools |
| `scripts/version.gd` | `VALUE` 1.3.0, new `CHANNEL` |
| `project.godot`, `export_presets.cfg` | generated version metadata; user dir; notices in `include_filter`; company/copyright |
| `scripts/ui/front.gd` | title stamp from `Version.CHANNEL`; credits: channel, development state, cutscene fonts, licence and notices |
| `scripts/ui/settings.gd` | `USER_DIR`, `legacy_dirs()`, `migrate()` over both older folders, `legacy.json` carried |
| `tools/patch_rc.py` | no hardcoded version fallback — a build that cannot read `version.gd` stops |
| `tests/improvements_test.gd` | `_test_version_line`, `_test_user_dir`, `_test_notices` |
| `README.md`, `docs/GAME_README.md`, `docs/EARLY_ACCESS_ROADMAP.md`, `docs/EA_TASKS.md`, `CHANGELOG.md` | the version line, the licence, the user directory, cycle status, Gate 0 |

## Verification

| Check | Result |
|---|---|
| `python3 tools/gd47_check.py` | clean, 128 GDScript files |
| `python3 tools/sync_version.py --check` | in sync: **1.3.0** (Windows 1.3.0.0) |
| `python3 -c "import tools.patch_rc"` | Windows resource version reads **1.3.0.0** from `version.gd` |
| `gdparse` on the four changed scripts | parses |
| `improvements_test` in the quick tier | run by CI (see below) |

### What the new checks catch

- **Version drift**: `improvements_test._test_version_line` fails if the version leaves the
  1.3 line or `CHANNEL` stops naming it; the existing `_test_version` keeps the three
  metadata files matching `Version.VALUE`/`WINDOWS`.
- **Presentation drift**: the title still draws the channel from `Version.CHANNEL` (not a
  literal) and the credits still name the notices, the licence and the development state.
- **User-directory drift**: `project.godot`'s `custom_user_dir_name` must equal
  `Settings.USER_DIR`; the original slice folder and the project-name folder must both
  still be carried; `legacy.json` must be in `CARRY`.
- **Shipping drift**: both licence files must exist, `LICENSE` must state the licence and
  point at the notices, and **every** export preset must put both in `include_filter`.

## Engine run

CI run **40791685096** on PR #1 (commit `ac2fda7`), quick tier:

| Job | Result |
|---|---|
| static audit (`gd47_check`, runner tests, version check on 1.3.0) | **success** |
| headless (4.7.2-stable) — quick tier, `improvements_test` included | **success** |
| headless (4.4.1-stable) — quick tier, `improvements_test` included | **success** |

**The first run of this cycle failed, and the failure is worth keeping.** Run
40790768232 (commit `7bd51ca`) failed `_check` and `improvements_test` on 4.7.2 with

```
Parse Error: Cannot find member "filter" in base "PackedStringArray"
```

because the notice check called `filter()` on the result of `String.split()`. Neither
`tools/gd47_check.py` nor `gdtoolkit`'s `gdparse` type-checks, so both passed the file;
the engine refused to load the script. Fixed in `ac2fda7` by wrapping the split in
`Array(...)`, and the job went green on both engines. The static audit is a linter, not a
compiler — CI is the only place a type error is caught, which is the argument for keeping
this tier on every commit.

## Reproduce

```sh
python3 tools/gd47_check.py
python3 tools/sync_version.py --check
GODOT=/path/to/godot-4.7.2
$GODOT --headless --path . -s res://tests/improvements_test.gd
GODOT=$GODOT tools/run_tests.sh --quick
```

## Notes and open threads

- **The user directory moves saves.** Everything after this build reads
  `user://` = `TheViolence`, and `Settings.migrate()` runs at launch to copy the earlier
  folders across. A save made in a build from before this cycle is still found; a save
  made *after* it is invisible to a pre-0.D build. That is the intended direction, but it
  is the reason P0.D4 asked for the decision before any cloud path existed.
- **`tests/fixtures/determinism.json` still says `"version": "1.2.1"`.** It is a label
  written into the fixture, not a comparison, and the fixture is the known-stale one;
  rebaselining it is Phase 1's P1.I1, so it was deliberately not touched.
- **The Remotion position is a judgement on current facts** (one person, no company). It
  is recorded with its trigger — more than three people, a publisher, or an incorporated
  company — in `THIRD_PARTY_NOTICES`, because it is the kind of thing that changes
  quietly.
