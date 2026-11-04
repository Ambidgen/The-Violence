import fs from 'node:fs';
import path from 'node:path';
import http from 'node:http';
import {once} from 'node:events';
import {spawn} from 'node:child_process';
import puppeteer from 'puppeteer-core';
import {root, work, ffmpeg, setup, master} from './env.mjs';

const browserConfig=await setup();
const types={'.html':'text/html','.js':'application/javascript','.jpg':'image/jpeg','.woff2':'font/woff2'};
const server=http.createServer((req,res)=>{
  const name=decodeURIComponent(new URL(req.url,'http://local').pathname);
  const file=path.resolve(root,`.${name}`);
  if(!file.startsWith(root+path.sep) || !fs.existsSync(file) || fs.statSync(file).isDirectory()){res.writeHead(404).end();return;}
  res.setHeader('Content-Type',types[path.extname(file)]||'application/octet-stream');
  fs.createReadStream(file).pipe(res);
});
await new Promise(resolve=>server.listen(0,'0.0.0.0',resolve));
let browser,encoder;
try {
  browser=await puppeteer.launch({executablePath:browserConfig.executablePath,args:browserConfig.args,headless:true,protocolTimeout:600000});
  const page=await browser.newPage();await page.setViewport({width:1280,height:720,deviceScaleFactor:1});
  page.on('pageerror',err=>console.error('p5 error:',err.message));
  await page.goto(`http://127.0.0.1:${server.address().port}/p5/index.html`,{waitUntil:'domcontentloaded'});
  await page.waitForFunction(()=>window.p5Ready===true,{timeout:30000});
  await page.evaluate(async()=>{await Promise.all(['CarrickHand','CarrickOswald','CarrickType'].map(f=>document.fonts.load(`24px ${f}`)));return true;});
  const still=process.argv.find(a=>a.startsWith('--still='));
  if(still){
    for(const frame of still.slice(8).split(',').map(Number)){
      await page.evaluate(f=>window.drawTrailer(f),frame);
      const out=path.join(work,`p5-${frame}.png`);await page.screenshot({path:out});console.log('Still:',out);
    }
  } else {
    const raw=path.join(work,'raw/05-p5.mp4');
    encoder=spawn(ffmpeg,['-hide_banner','-loglevel','error','-y','-f','image2pipe','-vcodec','mjpeg','-framerate','24','-i','pipe:0','-c:v','libx264','-preset','veryfast','-crf','20','-pix_fmt','yuv420p','-movflags','+faststart',raw],{stdio:['pipe','inherit','inherit']});
    const ended=new Promise((resolve,reject)=>{encoder.once('error',reject);encoder.once('close',code=>code===0?resolve():reject(new Error(`FFmpeg exited ${code}`)));});
    for(let frame=0;frame<480;frame++){
      const data=await page.evaluate(f=>{window.drawTrailer(f);return document.querySelector('canvas').toDataURL('image/jpeg',.9);},frame);
      if(!encoder.stdin.write(Buffer.from(data.split(',')[1],'base64'))) await once(encoder.stdin,'drain');
      if(frame%96===0)console.log(`p5 ${Math.round(frame/480*100)}%`);
    }
    encoder.stdin.end();await ended;encoder=undefined;
    master(raw,5,'05-radio-silence-p5.mp4');
  }
} finally {
  if(encoder) encoder.kill('SIGTERM');
  if(browser) await browser.close();
  await new Promise(resolve=>server.close(resolve));
}
