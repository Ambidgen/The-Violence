// Render the opening cutscenes to out/*.mp4 (1920x1080, 30 fps, h264 + aac).
//   node scripts/render.mjs [Cutscene1 Cutscene2 ...] [--frames=0-90] [--still=frame]
// Chromium: CHROME_PATH, else the Playwright build if present, else Remotion's own download.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {bundle} from '@remotion/bundler';
import {renderMedia, renderStill, selectComposition} from '@remotion/renderer';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const args = process.argv.slice(2);
const ids = args.filter((a) => !a.startsWith('--'));
const opt = Object.fromEntries(args.filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('=')));
const all = ['C1-PortCarrick', 'C2-OutgoingChief', 'C3-ThePlan', 'C4-FortyWeeks'];
const pw = '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell';
const browserExecutable = process.env.CHROME_PATH || (fs.existsSync(pw) ? pw : null);
const chromiumOptions = {enableMultiProcessOnLinux: true, headless: true, gl: 'swangle'};

fs.mkdirSync(path.join(root, 'out'), {recursive: true});
const serveUrl = await bundle({entryPoint: path.join(root, 'src', 'index.jsx'), publicDir: path.join(root, 'public')});
for (const id of ids.length ? ids : all) {
  const composition = await selectComposition({serveUrl, id, browserExecutable, chromiumOptions});
  if (opt.still !== undefined) {
    for (const f of opt.still.split(',')) {
      const output = path.join(root, 'out', `${id}-${f}.png`);
      await renderStill({composition, serveUrl, output, frame: Number(f), browserExecutable, chromiumOptions, overwrite: true});
      console.log('still', output);
    }
    continue;
  }
  const outputLocation = path.join(root, 'out', `${id}.mp4`);
  const frameRange = opt.frames ? opt.frames.split('-').map(Number) : null;
  let last = -10;
  await renderMedia({
    composition, serveUrl, codec: 'h264', crf: 18, overwrite: true, outputLocation,
    browserExecutable, chromiumOptions, concurrency: Number(opt.concurrency || 2), frameRange,
    onProgress: ({progress}) => {
      const pct = Math.round(progress * 100);
      if (pct >= last + 10 || pct === 100) {
        last = pct;
        console.log(`${id} ${pct}%`);
      }
    },
  });
  console.log('rendered', outputLocation);
}
