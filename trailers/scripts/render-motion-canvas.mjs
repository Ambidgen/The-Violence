import path from 'node:path';
import {createServer} from 'vite';
import puppeteer from 'puppeteer-core';
import motionModule from '@motion-canvas/vite-plugin';
import ffmpegModule from '@motion-canvas/ffmpeg';
import {root, work, setup, master} from './env.mjs';
const motion=motionModule.default || motionModule;
const ffmpegPlugin=ffmpegModule.default || ffmpegModule;
const browserConfig=await setup();
const test=process.argv.includes('--test');
const server=await createServer({root,configFile:false,logLevel:'warn',plugins:[
  motion({project:path.join(root,'motion-canvas/project.ts'),output:path.join(work,'raw')}),ffmpegPlugin(),
],server:{host:'0.0.0.0',port:9827,strictPort:false,allowedHosts:true}});
let browser;
try {
  await server.listen();
  const address=server.httpServer.address();
  browser=await puppeteer.launch({executablePath:browserConfig.executablePath,args:browserConfig.args,headless:true,protocolTimeout:600000});
  const page=await browser.newPage();
  page.on('console',msg=>console.log('Motion Canvas:',msg.text()));
  page.on('pageerror',err=>console.error('Motion Canvas page error:',err.message));
  await page.goto(`http://127.0.0.1:${address.port}/motion-canvas/render.html`,{waitUntil:'domcontentloaded',timeout:30000});
  await page.waitForFunction(()=>typeof window.renderTrailer==='function',{timeout:30000});
  const status=await page.evaluate(duration=>window.renderTrailer(duration),test?1.5:20);
  if(status!==0) throw new Error(`Motion Canvas render failed (status ${status})`);
  if(test) console.log('Test:',path.join(work,'raw/motion-test.mp4'));
  else master(path.join(work,'raw/04-motion-canvas.mp4'),4,'04-forty-weeks-motion-canvas.mp4');
} finally {
  if(browser) await browser.close();
  await server.close();
}
