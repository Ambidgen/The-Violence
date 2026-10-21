# The Violence: the opening cutscenes

Four short scenes made with [Remotion](https://www.remotion.dev), played before a new
campaign (and from the title's Prologue). Drawn in the game's red-ink hand: paper, ink,
stepped greys and one red that only marks where a plan touched a real room. Every sound
is one of the game's own synthesised effects (public/sfx), plus a phone ring made for
scene 2.

| # | Scene | Length | What it shows |
|---|-------|--------|---------------|
| 1 | Port Carrick | 42 s | the skyline and the closing mill, the twelve wards and four crews, gunfire on the map, headquarters |
| 2 | The Outgoing Chief | 41 s | the desk from above, the note the last chief left, what you inherit, the phone |
| 3 | The Plan | 43 s | a briefing drawn with total confidence, then the same house when the plan meets the room |
| 4 | Forty Weeks | 39 s | the calendar, the three candidates, the four allies, the first front page, the title |

```
npm install
npm run studio                 # Remotion Studio, to preview and edit
npm run render                 # all four to out/*.mp4 (1920x1080, 30 fps)
node scripts/render.mjs C3-ThePlan --still=600     # one frame
sh scripts/to_game.sh          # loudness-normalised MP4s in out/final, Ogg Theora for the game in ../assets/cutscenes
```

Rendering uses `CHROME_PATH` if set, otherwise a Playwright headless shell if present,
otherwise Remotion's own browser download.

src/ink.jsx is the kit (paper, panels, captions, stamps, pen-drawn paths, rain, the plan
figure, a comic silhouette, sounds); each scene is one file.
