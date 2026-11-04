// A contact sheet: one still per short, at the frame its registry entry calls its poster.
//   node scripts/sheet.mjs            # out/shorts/sheet/*.png, then sheet.png if ImageMagick is here
//   node scripts/sheet.mjs --scale=0.5
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import {SHORTS} from '../src/shorts/registry.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..');
const args = process.argv.slice(2);
const opt = Object.fromEntries(args.filter((a) => a.startsWith('--')).map((a) => a.slice(2).split('=')));
const dir = path.join(root, 'out', 'shorts', 'sheet');
fs.rmSync(dir, {recursive: true, force: true});
fs.mkdirSync(dir, {recursive: true});

const pw = '/opt/pw-browsers/chromium_headless_shell-1194/chrome-linux/headless_shell';
const browserExecutable = process.env.CHROME_PATH || (fs.existsSync(pw) ? pw : null);
const chromiumOptions = {enableMultiProcessOnLinux: true, headless: true, gl: 'swangle'};
const serveUrl = await bundle({entryPoint: path.join(root, 'src', 'index.jsx'), publicDir: path.join(root, 'public')});

const files = [];
for (const s of SHORTS) {
  const composition = await selectComposition({serveUrl, id: s.id, browserExecutable, chromiumOptions});
  const output = path.join(dir, `${s.id}.png`);
  await renderStill({composition, serveUrl, output, frame: s.poster ?? 100, browserExecutable, chromiumOptions, overwrite: true});
  files.push([output, `${s.id} · ${(s.frames / 30).toFixed(1)} s`]);
  console.log('still', output);
}

// montage, 4 across, each tile captioned in ink on paper
const sheet = path.join(root, 'out', 'shorts', 'sheet.png');
const font = process.env.SHEET_FONT || 'DejaVu-Sans-Mono';
try {
  const tiles = files.flatMap(([f, label]) => ['-label', label, f]);
  execFileSync('montage', [
    ...tiles, '-tile', '4x', '-geometry', `${opt.scale ? Math.round(960 * Number(opt.scale)) : 960}x+16+16`,
    '-background', '#EDEDE8', '-fill', '#121212', '-font', font, '-pointsize', '15',
    sheet,
  ], {stdio: 'inherit'});
  console.log('sheet', sheet);
} catch (e) {
  console.log('montage not available; stills are in', dir);
}
