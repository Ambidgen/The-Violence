import fs from 'node:fs';
import path from 'node:path';
import {bundle} from '@remotion/bundler';
import {renderMedia, renderStill, selectComposition} from '@remotion/renderer';
import {root, repo, work, setup, master} from './env.mjs';

const browser = await setup();
const pub = path.join(work, 'public');
for (const name of ['city-art.jpg','game-board.jpg','election-prototype.jpg']) {
  fs.copyFileSync(path.join(root, 'media', name), path.join(pub, name));
}
for (const [target, source] of [['tactical.mp4','docs/overhaul/1_ingame_topdown.mp4'], ['election.mp4','docs/overhaul/3_cutscene.mp4']]) {
  const dest = path.join(pub, target);
  if (!fs.existsSync(dest)) fs.copyFileSync(path.join(repo, source), dest);
}
const serveUrl = await bundle({entryPoint:path.join(root,'remotion/index.jsx'), publicDir:pub});
const chromiumOptions = {headless:true, enableMultiProcessOnLinux:false, gl:'swangle'};
const composition = await selectComposition({serveUrl,id:'TheChief',browserExecutable:browser.executablePath,chromiumOptions});
const still = process.argv.find(arg => arg.startsWith('--still='));
if (still) {
  for (const frame of still.slice(8).split(',').map(Number)) {
    const output = path.join(work, `remotion-${frame}.png`);
    await renderStill({serveUrl,composition,frame,output,browserExecutable:browser.executablePath,chromiumOptions,overwrite:true});
    console.log('Still:', output);
  }
} else {
  const raw = path.join(work,'raw/01-remotion.mp4');
  let last=-10;
  await renderMedia({serveUrl,composition,codec:'h264',crf:20,imageFormat:'jpeg',jpegQuality:90,outputLocation:raw,
    browserExecutable:browser.executablePath,chromiumOptions,overwrite:true,concurrency:1,
    onProgress:({progress})=>{const p=Math.floor(progress*10)*10;if(p>last){last=p;console.log(`Remotion ${p}%`);}}
  });
  master(raw,1,'01-the-chief-remotion.mp4');
}
