# The Violence — trailer prototypes

Five different 20-second creative directions for the same game. All are **prototypes for review**, not final store trailers. Each is an MP4 at 1280×720, 24 fps, with H.264 video and an AAC soundtrack.

| Cut | Framework | Direction | Watch or download |
| --- | --- | --- | --- |
| **01 · The Chief** | Remotion | Cinematic overview of Port Carrick, choosing a call, planning an operation, and its aftermath. | [MP4](renders/01-the-chief-remotion.mp4) |
| **02 · The Plan** | Revideo | Tactical dossier and animated route diagrams, built around the plan-versus-reality idea. | [MP4](renders/02-the-plan-revideo.mp4) |
| **03 · The Front Page** | HyperFrames | Newspaper-inspired editorial treatment about calls, consequences, and public scrutiny. | [MP4](renders/03-the-front-page-hyperframes.mp4) |
| **04 · Forty Weeks** | Motion Canvas | A campaign clock counting down to the election, with the game's board and briefing. | [MP4](renders/04-forty-weeks-motion-canvas.mp4) |
| **05 · Radio Silence** | p5.js | A darker dispatch-console treatment with signal graphics and a tactical route. | [MP4](renders/05-radio-silence-p5.mp4) |

[Open the screening room](index.html) to compare cuts in one player; select a cut and press play. The page uses relative paths and includes individual download links. It can be opened locally alongside `media/` and `renders/`, or served with:

```sh
cd trailers
python3 scripts/serve.py
# Open http://127.0.0.1:4173/ on your own machine, or use the Arena live preview.
```

The server supports byte-range requests for video seeking. It serves only this folder and does not require npm or the animation frameworks just to watch the already-rendered MP4s.

## Footage and sound

- The Port Carrick street scene is **AI-generated concept art** (`media/port-carrick-key-art.png`; the videos use its JPEG derivative). It is not a screenshot of the game.
- The board, briefing, and operation stills are captures from the existing game playtest in `tests/results/playtest-2026-10-28-campaign/screens/`.
- The tactical and election clips/stills from `docs/overhaul/` are **visual prototypes**, not verified gameplay footage. The corresponding shots are labelled accordingly. Route diagrams, the dispatch display, and newspaper pages are illustrative motion graphics.
- The five original music beds are synthesized deterministically by `scripts/soundtrack.py` and mixed with the game's synthesized effects from `assets/sfx/`. No voiceover or third-party music is used.
- Fonts: Courier Prime, Oswald, and Patrick Hand, all under SIL OFL 1.1. Their copyright and licence texts accompany the font files in `media/fonts/`. See the repository's [third-party notices](../THIRD_PARTY_NOTICES) for framework and tooling notes.

The work was produced in one Arena AI-agent session using **five different animation frameworks**. It was not produced using five separate AI coding apps. p5.js was used as the fifth framework; it was not one of the examples in the original request.

## Re-rendering

The scripts have been tested on Linux x86-64 with Node.js 22, npm, and Python 3.11. They rely on the npm-distributed x86-64 FFmpeg/ffprobe and Chromium binaries. A different OS or architecture will need appropriate binaries and renderer configuration; `CHROME_PATH` can point at an alternative compatible Chromium. The full repository is required because the sound effects and two visual-prototype source clips live outside this folder.

```sh
cd trailers
PUPPETEER_SKIP_DOWNLOAD=1 npm ci --no-audit --no-fund
npm run render       # all five, sequentially; overwrites renders/*.mp4
npm run verify       # inspect final files and fully decode them
```

Individual renders: `npm run render:remotion`, `npm run render:revideo`, `npm run render:hyperframes`, `npm run render:motion-canvas`, and `npm run render:p5`. A complete set can take several minutes on a small machine. Render intermediates, generated audio, local HyperFrames staging, and browser support files are kept in `.cache/` and ignored by Git. The five final MP4s in `renders/` are retained. `npm run verify` checks H.264/AAC, frame size/rate/count and duration, full decoding, three different sampled frames, and non-silent, non-clipping audio. It does not replace a human creative review.

Editable compositions are in `remotion/`, `revideo/`, `hyperframes/`, `motion-canvas/`, and `p5/`; their render entry points and soundtrack generator are in `scripts/`. Remotion uses the actual visual-prototype videos; the other cuts use stills and framework-generated graphics.

The repository's [proprietary licence](../LICENSE) applies to the game and its assets. Obtain Ambidgen's permission before public redistribution and review the applicable third-party tool and font licences for your use.
