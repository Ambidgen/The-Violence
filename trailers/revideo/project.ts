import {makeProject} from '@revideo/core';
import plan from './scene';
import './global.css';

// Force the browser to request our local fonts before canvas drawing begins.
for (const family of ['CarrickHand','CarrickOswald','CarrickType']) {
  void document.fonts.load(`24px ${family}`);
}

export default makeProject({
  name:'the-plan',
  scenes:[plan],
  settings:{
    shared:{background:'#ece7d8',range:[0,20],size:{x:1280,y:720}},
    rendering:{fps:24,resolutionScale:1,colorSpace:'srgb',exporter:{name:'@revideo/core/ffmpeg',options:{format:'mp4'}}},
    preview:{fps:24,resolutionScale:1},
  },
});
