import {Renderer, Vector2} from '@motion-canvas/core';
import project from './project?project';
import '../revideo/global.css';

declare global { interface Window { renderTrailer: (duration:number) => Promise<number>; } }
window.renderTrailer = async (duration:number) => {
  await Promise.all(['CarrickHand','CarrickOswald','CarrickType'].map(f=>document.fonts.load(`24px ${f}`)));
  const renderer = new Renderer(project);
  let result = -1;
  renderer.onFinished.subscribe(value=>{result=value;});
  renderer.onFrameChanged.subscribe(frame=>{if(frame>0&&frame%120===0) console.log(`Motion Canvas: frame ${frame}`);});
  await renderer.render({
    name: duration < 20 ? 'motion-test' : '04-motion-canvas',
    fps:24, range:[0, duration - 1/24], size:new Vector2(1280,720), resolutionScale:1,
    colorSpace:'srgb', background:'#eee9dc',
    exporter:{name:'@motion-canvas/ffmpeg',options:{fastStart:true,includeAudio:false}},
  });
  return result;
};
