// Render the short cutscenes to out/shorts/*.mp4 (1920x1080, 30 fps, h264 + aac).
//   node scripts/render-shorts.mjs                  # every short
//   node scripts/render-shorts.mjs S01-Week S05-Threshold
//   node scripts/render-shorts.mjs S01-Week --still=60,120
//   node scripts/render-shorts.mjs --crf=21 --concurrency=2
// Chromium: CHROME_PATH, else the Playwright build if present, else Remotion's download.
import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {bundle} from '@remotion/bundler';
import {renderMedia, renderStill, selectComposition} from '@remotion/renderer';
import {SHORTS} from '../src/shorts/registry.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const args = process.argv.slice(2);
const ids = args.filter((a) => !a.startsWith('--'));
const opt = Object.fromEntries(args.filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('=')));
const pw = '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell';
const browserExecutable = process.env.CHROME_PATH || (fs.existsSync(pw) ? pw : null);
const chromiumOptions = {enableMultiProcessOnLinux: true, headless: true, gl: 'swangle'};

fs.mkdirSync(path.join(root, 'out', 'shorts'), {recursive: true});
const serveUrl = await bundle({entryPoint: path.join(root, 'src', 'index.jsx'), publicDir: path.join(root, 'public')});
const list = (ids.length ? SHORTS.filter((s) => ids.includes(s.id) || ids.includes(s.key)) : SHORTS);
if (!list.length) {
  console.error('No such short. Known ids:', SHORTS.map((s) => s.id).join(', '));
  process.exit(1);
}
for (const short of list) {
  const composition = await selectComposition({serveUrl, id: short.id, browserExecutable, chromiumOptions});
  if (opt.still !== undefined) {
    for (const f of opt.still.split(',')) {
      const output = path.join(root, 'out', 'shorts', `${short.id}-${f}.png`);
      await renderStill({composition, serveUrl, output, frame: Number(f), browserExecutable, chromiumOptions, overwrite: true});
      console.log('still', output);
    }
    continue;
  }
  const outputLocation = path.join(root, 'out', 'shorts', `${short.id}.mp4`);
  let last = -10;
  await renderMedia({
    composition, serveUrl, codec: 'h264', crf: Number(opt.crf || 20), overwrite: true, outputLocation,
    browserExecutable, chromiumOptions, concurrency: Number(opt.concurrency || 2),
    audioCodec: 'aac', audioBitrate: '192k',
    onProgress: ({progress}) => {
      const pct = Math.round(progress * 100);
      if (pct >= last + 10 || pct === 100) {
        last = pct;
        console.log(`${short.id} ${pct}%`);
      }
    },
  });
  console.log('rendered', outputLocation);
}
