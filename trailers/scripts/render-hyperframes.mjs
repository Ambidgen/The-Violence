import fs from 'node:fs';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import {root, work, ffmpeg, setup, master} from './env.mjs';

process.chdir(root);
const browser=await setup();
process.env.HYPERFRAMES_BROWSER_PATH=browser.executablePath;
process.env.PRODUCER_HEADLESS_SHELL_PATH=browser.executablePath;
process.env.HYPERFRAMES_FFMPEG_PATH=ffmpeg;
process.env.DO_NOT_TRACK='1';
// Give HyperFrames its own project root, while keeping the authored HTML and
// shared game assets in their readable source locations. All staging is ignored.
const project=path.join(work,'hyperframes-project');
fs.mkdirSync(project,{recursive:true});
fs.cpSync(path.join(root,'media'),path.join(project,'media'),{recursive:true,force:true});
fs.copyFileSync(path.join(root,'node_modules/gsap/dist/gsap.min.js'),path.join(project,'gsap.min.js'));
const html=fs.readFileSync(path.join(root,'hyperframes/index.html'),'utf8')
  .replaceAll('../media/','./media/')
  .replace('../node_modules/gsap/dist/gsap.min.js','./gsap.min.js');
fs.writeFileSync(path.join(project,'index.html'),html);
const raw=path.join(work,'raw/03-hyperframes.mp4');
execFileSync(process.execPath,[path.join(root,'node_modules/hyperframes/dist/cli.js'),'render',project,
  '-o',raw,'--fps','24','--quality','standard','--workers','1','--no-browser-gpu','--quiet'],{stdio:'inherit',env:process.env});
master(raw,3,'03-the-front-page-hyperframes.mp4');
