import path from 'node:path';
import {renderVideo} from '@revideo/renderer';
import {root, work, ffmpeg, ffprobe, setup, master} from './env.mjs';

process.chdir(root);
process.env.DISABLE_TELEMETRY = 'true';
const browser = await setup();
const test = process.argv.includes('--test');
const rawName = test ? 'revideo-test.mp4' : '02-revideo.mp4';
const result = await renderVideo({projectFile:'./revideo/project.ts', settings:{
  outDir:'.cache/raw',outFile:rawName,workers:1,logProgress:true,
  ffmpeg:{ffmpegPath:ffmpeg,ffprobePath:ffprobe,ffmpegLogLevel:'error'},
  puppeteer:{executablePath:browser.executablePath,args:browser.args,headless:true},
  projectSettings:{range:[0,test?1.5:20],size:{x:1280,y:720},exporter:{name:'@revideo/core/ffmpeg',options:{format:'mp4'}}},
}});
if (!test) master(path.join(root,result),2,'02-the-plan-revideo.mp4');
else console.log('Test:',path.join(root,result));
