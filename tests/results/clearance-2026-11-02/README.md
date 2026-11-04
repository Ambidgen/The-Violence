# Clearance timing evidence — 2 November 2026

[Per-map tables](../../../docs/CLEARANCE_TIMING_2026-11-02.md) · [Diagnosis and fixes](../../../docs/CLEARANCE_DIAGNOSIS_2026-11-02.md)

## Files

- `maps-00-07.jsonl` and `maps-08-11.jsonl`: the final study, schema 2. Together they contain 360 records: 12 maps × 5 equal squad sizes × 3 paired seeds × {fight, unopposed}. Each record includes route assignments, room events and methods, entrant evidence, movement snapshots, and the normal fight outcome where applicable.
- `before-jam-fix-duplex-2v2.jsonl`: six **schema 1** records from the earlier intermediate code, retained only as a before/after diagnostic. Do not mix these with the final files in the report analyzer. Pre-fix clearance flags were not necessarily backed by entry.
- `before-jam-brain.patch`: the check-room fixes applied on top of base commit `d1d16b2a5f3781a9d0b255ff3072fa496638bb71`, before the body-jam and entry-completion fixes. This reconstructs the earlier intermediate code for the six Duplex records.

## Reproduce the final study

Use a Godot 4 editor executable. Import the project once if its `.godot` cache is missing, then run the two independent shards and the audit from the repository root:

```sh
godot --headless --editor --path . --quit

godot --headless --path . -s res://tests/clearance_study.gd -- \
  --maps=0,1,2,3,4,5,6,7 --sizes=1,2,3,4,5 --n=3 \
  --seed=811001 --max-room-seconds=1200 \
  --out=res://tests/results/clearance-2026-11-02/maps-00-07.jsonl

godot --headless --path . -s res://tests/clearance_study.gd -- \
  --maps=8,9,10,11 --sizes=1,2,3,4,5 --n=3 \
  --seed=811001 --max-room-seconds=1200 \
  --out=res://tests/results/clearance-2026-11-02/maps-08-11.jsonl

python3 tools/analyze_clearance_study.py \
  tests/results/clearance-2026-11-02/maps-00-07.jsonl \
  tests/results/clearance-2026-11-02/maps-08-11.jsonl \
  --output docs/CLEARANCE_TIMING_2026-11-02.md
```

The analyzer requires exactly the expected map/size/seed/condition coverage, verifies matching control/fight conditions and target paths, checks entry evidence and event timing, rejects duplicate or invalid records, and censors incomplete room clears. The study forces one squad per side, defaults to open doors, and keeps the defending squad in hold/stay (it can still react to contact). A fight is continued past normal victory only if Team A has surviving fighters and no defenders are still fighting. Normal fight limits remain in effect; continuation and unopposed controls have a separate 1,200-second room-observation cap. A room checked from the doorway does not require an entrant; an ordinary clear requires evidence that an assigned member entered. These are simulation bookkeeping milestones rather than exhaustive physical coverage.

## Reproduce the pre-jam comparison

The raw before-fix subset was captured with the older schema. The following reconstructs its simulation code using a disposable archive, and uses the current schema-2 harness to reproduce the same fight outcomes, times, shot/hit counts and room-event order. Do not overwrite your working tree with the patch.

```sh
mkdir -p build/pre-jam
git archive d1d16b2a5f3781a9d0b255ff3072fa496638bb71 \
  project.godot scripts tests/teams.gd | tar -x -C build/pre-jam
patch -d build/pre-jam -p1 < tests/results/clearance-2026-11-02/before-jam-brain.patch
cp tests/clearance_model.gd tests/clearance_study.gd build/pre-jam/tests/
godot --headless --editor --path build/pre-jam --quit
godot --headless --path build/pre-jam -s res://tests/clearance_study.gd -- \
  --maps=5 --sizes=2 --n=3 --seed=811001 --max-room-seconds=1200 \
  --out=res://build/pre-jam-reproduced.jsonl
```

The reproduced six cases matched the saved earlier records in outcome, time, room order and event times, shots and hits. Event evidence fields differ because the final harness additionally audits entry.

## Engine provenance

The complete timing matrix was run headless with **Godot 4.4.1.stable.mono.official.49a5bc7b6**, using an export-template executable retrieved from GitHub blob `95901202bf46564be7b27c913a4bc822f9f9a059` in `code-forge-temple/local-llm-npc`. Its Git blob hash was verified and its executable SHA-256 was `92132ea9658ad4493ca3809b39fbc2d27d87869fbcfd17a1d8843fb0ec0ab047`. This is a third-party-hosted executable, not an independently verified official release download. A minimal local script-class cache was supplied because this export does not import the project's UI assets.

A separate **Godot 4.7.2.stable.official.ed1daf0bf** release-export executable from `VicenteGM123/dead-air` was used for cross-version checks. Its two-part archive matched the publisher's SHA-256 `97858201b82b81aaa99c3e4b5efed06c78ebc3e0532d9fcf16643a8e1bbbd1fd`; this does not independently verify it as an official distribution. A temporary V2 PCK with the current source and an equivalent Node test wrapper was embedded because this release export disables script/path overrides. Group movement, route-model, focused range regressions/replays and all eight tactical determinism cases passed under both engines. Eight study records (maps 00 and 05, sizes 1 and 2, seed 811001 plus map offset, both conditions) matched field-for-field across engines. The full matrix itself was run on 4.4.1, not 4.7.2.

## Validation

```sh
godot --headless --path . -s res://tests/group_movement_test.gd
godot --headless --path . -s res://tests/clearance_model_test.gd
godot --headless --path . -s res://tests/test_range_regression_test.gd
godot --headless --path . -s res://tests/test_range_replays_test.gd
godot --headless --path . -s res://tests/test_range_determinism_test.gd
python3 -m unittest discover -s tests -p 'test_*analysis.py' -v
python3 tools/gd47_check.py --quiet
```

All 360 final records were repeated on 4.4.1 and matched byte-for-byte. The final Godot 4.4.1 range tier passed **10/10 suites**. The test-range determinism fixture was deliberately refreshed after comparing the base commit, brain-only and movement-only variants and repeating the combined result on both engine versions; this is an intentional simulation behavior change, not a silent fixture update. The older campaign determinism fixture remains separately marked as a known failure.

An attempted full quick tier initially passed 17/22. Two tactical failures were subsequently corrected and their focused suites passed on both engine versions. The other three suites (`character_assets_test`, `ops_ui_test`, `ui_walk`) could not validate UI/assets in the export-only environment because imported `.ctex`, `.fontdata` and audio resources were unavailable. An official-editor import and a complete quick-tier rerun are still recommended.

## SHA-256

These hashes identify the measured source and raw data, rather than relying on an uncommitted-worktree commit name:

```text
f7b4dd98e7f31f8db358794428a9d9f5dfdb1e3c779a90cbca4a323d90d659f2  scripts/sim/brain.gd
bd61dcfb29457b9d32973a9a479bc12479f12b10081c3b3ef9f074c6974a3337  scripts/sim/world.gd
b54060ac628d158e1a667b75932c917998527dd2c6a8e1c6f4e14472219cef79  scripts/sim/nav.gd
e7f3122f3ef8c84872ede9830c536364136ff414ef07452d849600ce8e38ad8b  tests/clearance_model.gd
ef0fa3f3df4675aed255eab877817db37fcc18e593dfbd9b4003c5cadba33e9e  tests/clearance_study.gd
d54e62512286a8e4ba4a35eff8ae4f5ee9d865c4843e66590104223c96b900d7  tools/analyze_clearance_study.py
068537359c6189fe268a80a0f49ab620ae3a9cd07548cb407483dd112a674e8e  tests/results/clearance-2026-11-02/maps-00-07.jsonl
63a28307c59996b7c105ea808f8067760d2d29fe5deb47d2a59b733c5832fd51  tests/results/clearance-2026-11-02/maps-08-11.jsonl
86be03acba6b7328e79a446604ff424bc33e8c1608bccdfefeb472de9bcb9538  tests/results/clearance-2026-11-02/before-jam-fix-duplex-2v2.jsonl
a066efd5ac31847e88e7982197f38cf0897046afd3a04b9bc9efb179494a1234  tests/results/clearance-2026-11-02/before-jam-brain.patch
```
