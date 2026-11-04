// Shared local renderer setup. Nothing here changes the game or requires a browser download.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {fileURLToPath} from 'node:url';
import {execFileSync} from 'node:child_process';
import zlib from 'node:zlib';
import chromium from '@sparticuz/chromium';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
export const repo = path.resolve(root, '..');
export const work = path.join(root, '.cache');
export const ffmpeg = path.join(root, 'node_modules/@ffmpeg-installer/linux-x64/ffmpeg');
export const ffprobe = path.join(root, 'node_modules/@ffprobe-installer/linux-x64/ffprobe');

export async function setup() {
  for (const dir of ['bin', 'audio', 'raw', 'public']) fs.mkdirSync(path.join(work, dir), {recursive: true});
  fs.mkdirSync(path.join(root, 'renders'), {recursive: true});
  for (const [name, target] of [['ffmpeg', ffmpeg], ['ffprobe', ffprobe]]) {
    const link = path.join(work, 'bin', name);
    if (!fs.existsSync(link)) fs.symlinkSync(target, link);
  }
  process.env.PATH = `${path.join(work, 'bin')}${path.delimiter}${process.env.PATH}`;
  const executablePath = process.env.CHROME_PATH || await chromium.executablePath();
  // Sparticuz ships the NSS libraries for its Linux build. Unpack them on Linux
  // even outside AWS Lambda; the provided sandbox is otherwise too minimal.
  if (!process.env.CHROME_PATH && process.platform === 'linux') {
    const libRoot = path.join(os.tmpdir(), 'the-violence-chromium-libs');
    const marker = path.join(libRoot, 'lib/libnss3.so');
    if (!fs.existsSync(marker)) {
      fs.mkdirSync(libRoot, {recursive: true});
      const archive = path.join(root, 'node_modules/@sparticuz/chromium/bin/al2023.tar.br');
      const tarFile = path.join(libRoot, 'libs.tar');
      fs.writeFileSync(tarFile, zlib.brotliDecompressSync(fs.readFileSync(archive)));
      execFileSync('tar', ['xf', tarFile, '-C', libRoot]);
      fs.unlinkSync(tarFile);
    }
    process.env.LD_LIBRARY_PATH = `${path.join(libRoot, 'lib')}${path.delimiter}${process.env.LD_LIBRARY_PATH || ''}`;
  }
  return {executablePath, args: chromium.args};
}

export function ensureAudio() {
  if ([1, 2, 3, 4, 5].some(n => !fs.existsSync(path.join(work, 'audio', `${String(n).padStart(2, '0')}.wav`)))) {
    execFileSync('python3', [path.join(root, 'scripts/soundtrack.py')], {stdio: 'inherit'});
  }
}

export function master(rawPath, number, outputName) {
  ensureAudio();
  const output = path.join(root, 'renders', outputName);
  const soundtrack = path.join(work, 'audio', `${String(number).padStart(2, '0')}.wav`);
  execFileSync(ffmpeg, [
    '-hide_banner', '-loglevel', 'error', '-y', '-i', rawPath, '-i', soundtrack,
    '-map', '0:v:0', '-map', '1:a:0', '-c:v', 'copy', '-af', 'volume=2.2', '-c:a', 'aac', '-b:a', '160k',
    '-t', '20', '-movflags', '+faststart', output,
  ], {stdio: 'inherit'});
  console.log(`Mastered ${output}`);
}
