// Verify the deliverables, not merely the composition settings.
import fs from 'node:fs';
import path from 'node:path';
import {execFileSync, spawnSync} from 'node:child_process';
import {root, ffmpeg, ffprobe} from './env.mjs';

const files=[
  '01-the-chief-remotion.mp4',
  '02-the-plan-revideo.mp4',
  '03-the-front-page-hyperframes.mp4',
  '04-forty-weeks-motion-canvas.mp4',
  '05-radio-silence-p5.mp4',
];
let failed=false;
for(const name of files){
  try{
    const file=path.join(root,'renders',name);
    if(!fs.existsSync(file)) throw new Error('missing file');
    const data=JSON.parse(execFileSync(ffprobe,['-v','error','-show_streams','-show_format','-of','json',file],{encoding:'utf8'}));
    const video=data.streams.find(s=>s.codec_type==='video');
    const audio=data.streams.find(s=>s.codec_type==='audio');
    if(!video || video.codec_name!=='h264' || video.width!==1280 || video.height!==720 || video.avg_frame_rate!=='24/1' || Number(video.nb_frames)!==480) throw new Error('expected 480 frames of 1280x720 H.264 at 24 fps');
    if(!audio || audio.codec_name!=='aac') throw new Error('missing AAC soundtrack');
    if(Math.abs(Number(data.format.duration)-20)>.001 || Math.abs(Number(video.duration)-20)>.001) throw new Error('duration is not exactly 20 seconds');
    // Decode the complete file to catch broken containers or damaged packets.
    execFileSync(ffmpeg,['-v','error','-i',file,'-f','null','-'],{stdio:'pipe'});
    const hashes=[2,9,18].map(second=>execFileSync(ffmpeg,['-v','error','-ss',String(second),'-i',file,'-frames:v','1','-f','md5','-'],{encoding:'utf8'}).trim());
    if(new Set(hashes).size!==3) throw new Error('sampled visuals did not change across the trailer');
    const stats=spawnSync(ffmpeg,['-hide_banner','-i',file,'-vn','-af','volumedetect','-f','null','-'],{encoding:'utf8'});
    const mean=Number(stats.stderr.match(/mean_volume:\s*(-?[\d.]+) dB/)?.[1]);
    const peak=Number(stats.stderr.match(/max_volume:\s*(-?[\d.]+) dB/)?.[1]);
    if(stats.status!==0 || !Number.isFinite(mean) || mean < -45 || !Number.isFinite(peak) || peak >= 0) throw new Error('soundtrack is silent or clipping');
    console.log(`PASS ${name}: 20.000s, 480 frames, H.264/AAC, full decode, 3 distinct visuals, audio peak ${peak} dB`);
  }catch(error){
    failed=true;
    console.error(`FAIL ${name}: ${error.message}`);
  }
}
if(failed)process.exitCode=1;
