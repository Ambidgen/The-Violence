# Cutscene capture — the repo-only review loop

The crayon cutscene stack (`docs/CUTSCENE_TOOLING_RESEARCH_2026-10-29.md` §10) is
actuated entirely through GitHub: an agent writes cutscene code in the repo, pushes,
CI renders stills under a virtual display, and a human reviews a contact sheet on the
run/PR. Nobody needs to open the Godot editor to produce or check a beat. This file
is the operating manual for that loop; the pieces are:

| Piece | What it does |
|---|---|
| `tests/cutscene_capture.gd` | Displayed (not `--headless`) capture harness: loads a prototype or manifest-configured short, runs it at fixed fps, saves PNG stills plus a `capture.json`; exits 1 on blank output or no stills |
| `tools/cutscene_capture.sh` | One command locally or in CI: import, capture, contact sheet (`GODOT=`, `XVFB=1`, `--scene=`, `--short=`, `--stills=`, `--dry-run`) |
| `tools/make_contact_sheet.py` | Pillow contact sheet: labelled tiles (capture time per still) on paper stock |
| `.github/workflows/cutscene-capture.yml` | The actuator: downloads Godot 4.7.2 from GitHub Releases (cached), installs Xvfb + Pillow, runs `tools/cutscene_capture.sh`, uploads stills + sheet as an artifact and summarises the run |

## Run it

**In CI (the normal way):** Actions → *cutscene-capture* → Run workflow. Inputs pick
a prototype view (`cutscene` = the election-night proto in
`scripts/view/proto/cutscene_view.gd`, `menu`, `topdown`), an explicit
`--scene=res://…gd`, or a native short key (the keys in `assets/cutscenes/shorts/shorts.json`), plus
run length and still times. A push to an `arena/*` branch that touches the crayon/proto view files
also triggers it. Download the `cutscene-capture-*` artifact: it contains the stills,
`capture.json`, and `contact-sheet.png`. That sheet is the review surface — judge it
against the reference plates in `docs/overhaul/`; if it isn't the same hand, the beat
isn't done, however green CI is.

**Locally (needs a desktop/display):**

```sh
GODOT=/path/to/godot tools/cutscene_capture.sh --which=cutscene --stills=1,4,8,11.5
GODOT=/path/to/godot tools/cutscene_capture.sh --short=s11_election --stills=1,5,9
# or: tools/cutscene_capture.sh --scene=res://scripts/view/proto/cutscene_view.gd
tools/cutscene_capture.sh --dry-run   # print what would run
```

**First CI run (2026-10-29, run 40956363686): green end-to-end** — every step succeeded, artifact `cutscene-capture-cutscene-40956363686` (11.4 MB: stills + `capture.json` + `contact-sheet.png`). Note the workflow file pushed without complaint, so the automation token does carry `workflow` scope in this repo after all.

Output lands in `build/cutscene-captures/<name>/` (git-ignored via `build/`). To keep
a reviewed sheet as permanent evidence, commit it by hand under `tests/results/` —
the workflow deliberately does not auto-commit captures.

## Why Xvfb, and why a new harness?

Godot's `--headless` mode uses a dummy RenderingServer: the game logic runs, but the
viewport texture is never drawn, so frame capture silently yields nothing.
`tests/proto_capture.gd` already captured frames ("needs a display");
`tests/cutscene_capture.gd` is its CI-grade sibling — same idea, but it refuses to
succeed on blank frames or zero stills, and writes the manifest the sheet step reads.
In CI, Xvfb provides the display; locally, your desktop does.

## Opening replacement status

The four opening entries are now native, capturable crayon views rather than videos:
`opening_view.gd` (Port Carrick), `presser_view.gd` (The Press Conference),
`jeremy_view.gd` (Jeremy Berry), and `fettick_view.gd` (This Machine Kills Tyrants). The game
sequences them from `scripts/ui/cutscene.gd`; their durations come from the view timelines,
and Space/Enter/click and Esc retain the old skip behavior. Capture any one directly with
`--scene=res://scripts/view/proto/<view>.gd` and choose still times appropriate to its
full-length timeline. The fourteen campaign shorts are now native, data-driven crayon views
in `scripts/view/crayon_short.gd`; capture one with `--short=s01_week` (or another key from
the manifest). The capture harness gets the view props and duration from the same manifest
used at runtime. The old Remotion videos remain archived but are no longer loaded.

## Conventions for new cutscene beats

- A capturable beat is a `Node2D`/`Control` script loadable on its own (as
  `proto/*_view.gd` are), driven by time so `--fixed-fps 30` makes it deterministic.
- Keep the presentation-only rule: no simulation state is touched (VISUAL_OVERHAUL).
- Pick stills at narrative beats (draw-on complete, mid-camera-move, caption up,
  stamp down) — default `1,4,8,11.5` for a 12 s beat.
- When a beat ships, say so in the PR with its contact sheet; "CI passed" alone
  says nothing about the drawing.

## Troubleshooting

- **`viewport texture is empty`** — you ran `--headless` or without a display/Xvfb.
- **No Godot binary locally** — set `GODOT=`; in this project's agent sandbox the
  GitHub release asset's redirect host is unreachable, which is exactly why CI
  (GitHub-hosted runners) is the actuator. Don't fight it locally there; push.
- **Workflow file can't be pushed by the automation account** — repo history records
  a token without `workflow` scope; land `.github/workflows/cutscene-capture.yml`
  via the owner if a push is rejected, everything else is ordinary repo content.
- **Sheet step finds nothing** — the capture step failed upstream; check its log and
  `capture.json` before blaming Pillow.
