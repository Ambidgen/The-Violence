import React from 'react';
import {AbsoluteFill, Composition, Img, OffthreadVideo, interpolate, registerRoot, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import './fonts.css';

const C = {ink:'#151615', paper:'#eee9d9', red:'#bc3637', muted:'#c3bcac'};
const clamp = {extrapolateLeft:'clamp', extrapolateRight:'clamp'};
const ramp = (x, a, b) => interpolate(x, [a,b], [0,1], clamp);

function ImageLayer({src, frame, position='center', dark=.25}) {
  return <AbsoluteFill style={{overflow:'hidden', background:'#181817'}}>
    <Img src={staticFile(src)} style={{position:'absolute',width:'100%',height:'100%',objectFit:'cover',objectPosition:position,transform:`scale(${1.04 + frame*.00045}) translateX(${frame*.025}px)`}} />
    <AbsoluteFill style={{background:`linear-gradient(90deg,rgba(15,15,14,${dark+.35}) 0%,rgba(15,15,14,${dark}) 58%,rgba(15,15,14,${dark*.7}) 100%)`}} />
  </AbsoluteFill>;
}
function VideoLayer({src, startFrom=0, frame, dark=.28}) {
  return <AbsoluteFill style={{overflow:'hidden',background:'#151515'}}>
    <OffthreadVideo src={staticFile(src)} muted startFrom={startFrom} style={{width:'100%',height:'100%',objectFit:'cover',transform:`scale(${1.03 + frame*.00018})`}} />
    <AbsoluteFill style={{background:`linear-gradient(90deg,rgba(13,14,13,${dark+.48}),rgba(13,14,13,${dark*.6}) 82%)`}} />
  </AbsoluteFill>;
}
function Header({section, label, f}) {
  return <>
    <div style={{position:'absolute',left:58,right:58,top:37,display:'flex',justifyContent:'space-between',alignItems:'center',fontFamily:'CarrickType',fontSize:15,letterSpacing:2,color:C.paper}}>
      <span>THE VIOLENCE <span style={{color:C.red}}> / </span> {section}</span><span>{label}</span>
    </div>
    <div style={{position:'absolute',left:58,right:58,top:68,height:1,background:'rgba(238,233,217,.45)'}} />
    <div style={{position:'absolute',left:58,bottom:38,width:1164,height:2,background:'rgba(238,233,217,.25)'}}><div style={{width:`${(f/479)*100}%`,height:2,background:C.red}} /></div>
  </>;
}
function ShotCopy({overline, lines, detail, time, y=190, size=86}) {
  const appear = ramp(time, 3, 16);
  return <div style={{position:'absolute',left:73,top:y,opacity:appear,transform:`translateY(${(1-appear)*28}px)`}}>
    <div style={{font:'600 20px CarrickOswald',letterSpacing:5,color:C.paper,marginBottom:20}}><span style={{display:'inline-block',width:35,height:4,background:C.red,verticalAlign:'middle',marginRight:14}} />{overline}</div>
    <div style={{font:`600 ${size}px/.99 CarrickOswald`,letterSpacing:-.8,color:C.paper,textShadow:'0 3px 18px rgba(0,0,0,.38)'}}>{lines.map((line,i)=><div key={i}>{line}</div>)}</div>
    <div style={{marginTop:25,font:'20px CarrickType',letterSpacing:1.5,color:C.paper}}>{detail}</div>
  </div>;
}
function EntryCard() {
  const f=useCurrentFrame();
  const appear=ramp(f, 8, 25);
  const line=ramp(f, 23, 50);
  return <AbsoluteFill>
    <ImageLayer src="city-art.jpg" frame={f} dark={.48}/>
    <div style={{position:'absolute',inset:0,background:'rgba(12,12,12,.25)'}} />
    <div style={{position:'absolute',left:0,right:0,top:132,textAlign:'center',opacity:appear,transform:`translateY(${(1-appear)*18}px)`}}>
      <div style={{font:'18px CarrickType',letterSpacing:5,color:'#e0d9c9',marginBottom:19}}>PORT CARRICK POLICE DEPARTMENT</div>
      <div style={{font:'130px/.95 CarrickHand',letterSpacing:2,color:C.paper,textShadow:'0 4px 16px #000'}}>THE VIOLENCE</div>
      <div style={{margin:'19px auto 24px',width:Math.floor(700*line),height:5,background:C.red,transform:'rotate(-.4deg)'}} />
      <div style={{font:'600 24px CarrickOswald',letterSpacing:5,color:C.paper}}>FORTY WEEKS TO THE ELECTION</div>
      <div style={{marginTop:20,font:'16px CarrickType',letterSpacing:2,color:'#d8d0bd'}}>TACTICAL COMMAND AUTOBATTLER</div>
    </div>
    <div style={{position:'absolute',bottom:78,left:0,right:0,textAlign:'center',font:'15px CarrickType',letterSpacing:2,color:'#e5decd',opacity:appear}}>EARLY ACCESS &nbsp; • &nbsp; TRAILER PROTOTYPE</div>
  </AbsoluteFill>;
}
function Trailer() {
  const f=useCurrentFrame();
  const {fps}=useVideoConfig();
  let scene;
  if(f < 92) {
    scene=<><ImageLayer src="city-art.jpg" frame={f} dark={.22}/><ShotCopy time={f} overline="A CITY UNDER PRESSURE" lines={['PORT','CARRICK.']} detail="ONE DEPARTMENT. ONE ELECTION." size={100}/><Header section="01 / THE CITY" label="CONCEPT ART" f={f}/></>;
  } else if(f < 182) {
    const t=f-92;
    scene=<><ImageLayer src="game-board.jpg" frame={t} dark={.38}/><ShotCopy time={t} overline="YOU ARE THE CHIEF" lines={['CHOOSE','THE CALL.']} detail="SIX WARDS. LIMITED RESOURCES." size={88}/><Header section="02 / THE BOARD" label="IN-GAME CAPTURE" f={f}/></>;
  } else if(f < 278) {
    const t=f-182;
    scene=<><VideoLayer src="tactical.mp4" startFrom={3*fps} frame={t} dark={.24}/><ShotCopy time={t} overline="TACTICAL COMMAND" lines={['MAKE','THE PLAN.']} detail="ASSIGN OFFICERS. WRITE ORDERS." size={88}/><Header section="03 / THE OPERATION" label="VISUAL PROTOTYPE" f={f}/></>;
  } else if(f < 376) {
    const t=f-278;
    scene=<><VideoLayer src="election.mp4" startFrom={1*fps} frame={t} dark={.31}/><ShotCopy time={t} overline="THEN FACE THE CONSEQUENCES" lines={['THE CITY','REMEMBERS.']} detail="FORCE. TRUST. ELECTION NIGHT." size={82}/><Header section="04 / THE AFTERMATH" label="VISUAL PROTOTYPE" f={f}/></>;
  } else {
    scene=<EntryCard/>;
  }
  return <AbsoluteFill style={{background:'#111',overflow:'hidden'}}>{scene}</AbsoluteFill>;
}
const Root=()=> <Composition id="TheChief" component={Trailer} durationInFrames={480} fps={24} width={1280} height={720}/>;
registerRoot(Root);
