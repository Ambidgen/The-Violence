// The Violence: the red-ink kit for the cutscenes. Paper, ink, stepped greys and one red,
// which only ever marks where a plan touched a real room (routes, alarms, consequence).
// Everything is deterministic: no Math.random, positions come from seeded arithmetic.
import React from 'react';
import {AbsoluteFill, Audio, Sequence, interpolate, spring, staticFile, useCurrentFrame, useVideoConfig, Easing} from 'remotion';
import '@fontsource/courier-prime/400.css';
import '@fontsource/courier-prime/700.css';
import '@fontsource/oswald/400.css';
import '@fontsource/oswald/600.css';
import '@fontsource/open-sans/400.css';
import '@fontsource/open-sans/600.css';

export const C = {
  paper: '#EDEDE8',
  floor: '#D4D4CF',
  light: '#BFBFBA',
  mid: '#737370',
  dark: '#2B2B2B',
  ink: '#121212',
  red: '#B31F26',
};
export const FONT = {
  type: "'Courier Prime', 'Courier New', monospace",   // the typewriter: notes, captions
  caps: "'Oswald', 'Arial Narrow', sans-serif",          // institutional capitals: labels, stamps
  body: "'Open Sans', sans-serif",                       // the game's own face: the title
};

export const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};
export const ease = Easing.bezier(0.33, 0, 0.2, 1);

/** 0..1 over [a, b] frames, eased. */
export const prog = (f, a, b, e = ease) => interpolate(f, [a, b], [0, 1], {...clamp, easing: e});

/** A deterministic pseudo-random number in [0, 1) from an integer. */
export const rnd = (i) => {
  const x = Math.sin(i * 127.1 + 311.7) * 43758.5453;
  return x - Math.floor(x);
};

// ------------------------------------------------------------------ the page
/** The paper: flat stock with sparse grain and a faint 1 m grid (the plan's sheet). */
export const Paper = ({grid = true, tone = C.paper, grain = 260, children}) => {
  const dots = [];
  for (let i = 0; i < grain; i++) {
    dots.push(<rect key={i} x={(i * 733) % 1920} y={(i * 389) % 1080} width={1.4 + (i % 3)} height={1.2} fill={C.ink} opacity={0.05 + (i % 5) * 0.012} />);
  }
  const lines = [];
  if (grid) {
    for (let x = 0; x <= 1920; x += 48) lines.push(<line key={'x' + x} x1={x} y1={0} x2={x} y2={1080} stroke={C.ink} strokeOpacity={0.045} strokeWidth={1} />);
    for (let y = 0; y <= 1080; y += 48) lines.push(<line key={'y' + y} x1={0} y1={y} x2={1920} y2={y} stroke={C.ink} strokeOpacity={0.045} strokeWidth={1} />);
  }
  return (
    <AbsoluteFill style={{backgroundColor: tone}}>
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {lines}
        {dots}
      </svg>
      {children}
    </AbsoluteFill>
  );
};

/** Halftone dots, for shading in the comic panels. */
export const Halftone = ({id, step = 9, r = 1.8, color = C.ink, opacity = 0.35}) => (
  <pattern id={id} width={step} height={step} patternUnits="userSpaceOnUse" patternTransform="rotate(30)">
    <circle cx={step / 2} cy={step / 2} r={r} fill={color} opacity={opacity} />
  </pattern>
);

/** Diagonal hatching, for undersides and dark corners. */
export const Hatch = ({id, step = 8, w = 1.4, color = C.ink, opacity = 0.5, angle = 45}) => (
  <pattern id={id} width={step} height={step} patternUnits="userSpaceOnUse" patternTransform={`rotate(${angle})`}>
    <line x1={0} y1={0} x2={0} y2={step} stroke={color} strokeWidth={w} opacity={opacity} />
  </pattern>
);

// ------------------------------------------------------------------ comic furniture
/** A comic panel: a white page cut-out with a heavy ink border, sliding in from `from`. */
export const Panel = ({x, y, w, h, at = 0, from = 'up', fill = C.paper, children, border = 7}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = spring({frame: f - at, fps, config: {damping: 200, mass: 0.7}});
  const d = {up: [0, 60], down: [0, -60], left: [80, 0], right: [-80, 0]}[from];
  if (f < at) return null;
  return (
    <div style={{position: 'absolute', left: x + d[0] * (1 - s), top: y + d[1] * (1 - s), width: w, height: h, opacity: s,
      background: fill, border: `${border}px solid ${C.ink}`, overflow: 'hidden', boxSizing: 'border-box',
      boxShadow: `8px 8px 0 rgba(18,18,18,0.18)`}}>
      {children}
    </div>
  );
};

/** Typewriter text: characters appear at `cps` from frame `at`. */
export const typed = (text, f, at, cps = 38, fps = 30) => {
  const n = Math.max(0, Math.floor(((f - at) / fps) * cps));
  return text.slice(0, n);
};

/** A narration caption: a paper box with an ink rule, typed out. */
export const Caption = ({text, at, x = 120, y = 90, w = 900, size = 34, cps = 34, until = 1e9, red = null}) => {
  const f = useCurrentFrame();
  if (f < at || f > until) return null;
  const s = interpolate(f, [at, at + 8, until - 8, until], [0, 1, 1, 0], clamp);
  const shown = typed(text, f, at + 4, cps);
  // a word set in red when it is fully typed (the only colour on the page)
  let body = shown;
  if (red && shown.includes(red)) {
    const i = shown.indexOf(red);
    body = (<>{shown.slice(0, i)}<span style={{color: C.red}}>{red}</span>{shown.slice(i + red.length)}</>);
  }
  return (
    <div style={{position: 'absolute', left: x, top: y, width: w, opacity: s, background: C.paper,
      border: `4px solid ${C.ink}`, padding: '20px 28px', boxShadow: '6px 6px 0 rgba(18,18,18,0.2)',
      fontFamily: FONT.type, fontSize: size, lineHeight: 1.35, color: C.ink, letterSpacing: 0.5, whiteSpace: 'pre-wrap'}}>
      {body}
      <span style={{opacity: shown.length < text.length && Math.floor(f / 8) % 2 === 0 ? 1 : 0}}>▌</span>
    </div>
  );
};

/** A rubber stamp: thumped onto the page at `at`, slightly rotated, red or ink. */
export const Stamp = ({lines, at, x, y, rot = -4, color = C.red, size = 40, w = null}) => {
  const f = useCurrentFrame();
  if (f < at) return null;
  const k = interpolate(f, [at, at + 5, at + 9], [1.6, 0.94, 1], clamp);
  const o = interpolate(f, [at, at + 3], [0, 0.92], clamp);
  return (
    <div style={{position: 'absolute', left: x, top: y, transform: `rotate(${rot}deg) scale(${k})`, transformOrigin: 'center',
      opacity: o, border: `5px solid ${color}`, outline: `2px solid ${color}`, outlineOffset: -12, padding: '14px 26px',
      fontFamily: FONT.caps, fontWeight: 600, fontSize: size, lineHeight: 1.1, color, letterSpacing: 3, width: w,
      textAlign: 'left', mixBlendMode: 'multiply'}}>
      {lines.map((l) => <div key={l}>{l}</div>)}
    </div>
  );
};

/** A path drawn on like a pen stroke from frame a to b. */
export const Draw = ({d, a, b, stroke = C.ink, width = 4, fill = 'none', fillAt = null, len = 3000, cap = 'round', dash = null, opacity = 1}) => {
  const f = useCurrentFrame();
  const p = prog(f, a, b);
  const fo = fillAt === null ? 0 : prog(f, fillAt, fillAt + 12);
  return (
    <path d={d} stroke={stroke} strokeWidth={width} fill={fill} fillOpacity={fo} strokeLinecap={cap} strokeLinejoin="round"
      strokeDasharray={dash ? dash : `${len} ${len}`} strokeDashoffset={dash ? 0 : len * (1 - p)} opacity={dash ? opacity * p : opacity} />
  );
};

/** Rain: thin ink strokes, deterministic, falling at an angle. */
export const Rain = ({n = 140, opacity = 0.22, speed = 38, len = 26}) => {
  const f = useCurrentFrame();
  const drops = [];
  for (let i = 0; i < n; i++) {
    const x0 = rnd(i) * 2200 - 140;
    const y = ((rnd(i + 99) * 1180 + f * speed * (0.8 + rnd(i + 7) * 0.4)) % 1180) - 60;
    const x = x0 + y * 0.18;
    drops.push(<line key={i} x1={x} y1={y} x2={x + len * 0.18} y2={y + len} stroke={C.ink} strokeWidth={1.3} opacity={opacity * (0.5 + rnd(i + 3) * 0.5)} />);
  }
  return <svg width={1920} height={1080} style={{position: 'absolute'}}>{drops}</svg>;
};

/** Fade the whole scene from and to paper. */
export const Fades = ({total, inF = 12, outF = 18}) => {
  const f = useCurrentFrame();
  const o = interpolate(f, [0, inF, total - outF, total], [1, 0, 0, 1], clamp);
  return <AbsoluteFill style={{background: C.paper, opacity: o, pointerEvents: 'none'}} />;
};

/** A sound from the game's own synthesised set (public/sfx), at frame `at`. */
export const Sfx = ({name, at, volume = 0.8, rate = 1}) => (
  <Sequence from={at} layout="none">
    <Audio src={staticFile(`sfx/${name}.wav`)} volume={volume} playbackRate={rate} />
  </Sequence>
);

/** The ambience bed, looping under a whole scene. */
export const Bed = ({name, volume = 0.35, total}) => {
  return (
    <Audio src={staticFile(`sfx/${name}.wav`)} loop
      volume={(f) => volume * interpolate(f, [0, 20, total - 30, total], [0, 1, 1, 0], clamp)} />
  );
};

// ------------------------------------------------------------------ figures
/** A person from directly above, as in the game: torso block, head, a pale mark. */
export const PlanFigure = ({x, y, rot = 0, scale = 1, hollow = false, mark = 'bar', down = false, gun = true, opacity = 1}) => {
  const fill = hollow ? C.paper : C.ink;
  const st = hollow ? C.ink : 'none';
  if (down) {
    return (
      <g transform={`translate(${x},${y}) rotate(${rot}) scale(${scale})`} opacity={opacity}>
        <g transform="translate(3,3)" opacity={0.2}><rect x={-20} y={-14} width={56} height={28} rx={10} fill={C.dark} /></g>
        <path d="M-44,-6 L-14,-5 M-44,6 L-14,5" stroke={C.ink} strokeWidth={6} strokeLinecap="round" />
        <rect x={-18} y={-14} width={42} height={28} rx={9} fill={fill} stroke={st} strokeWidth={2.4} />
        <circle cx={34} cy={-1} r={8} fill={fill} stroke={st} strokeWidth={2.4} />
        {!hollow && mark === 'bar' && <rect x={-8} y={-3} width={24} height={5} rx={2} fill={C.light} />}
      </g>
    );
  }
  return (
    <g transform={`translate(${x},${y}) rotate(${rot}) scale(${scale})`} opacity={opacity}>
      <g transform="translate(3,3)" opacity={0.2}>
        <rect x={-13} y={-22} width={17} height={44} rx={8} fill={C.dark} />
        <circle cx={5} cy={0} r={8} fill={C.dark} />
      </g>
      {gun && !hollow && <rect x={8} y={-2.5} width={34} height={5} rx={1.5} fill={C.dark} stroke={C.ink} strokeWidth={1} />}
      <path d={gun && !hollow ? 'M-2,-17 Q10,-14 22,-2' : 'M-2,-17 Q4,-20 8,-20'} stroke={C.ink} strokeWidth={hollow ? 3 : 5} fill="none" strokeLinecap="round" />
      <path d={gun && !hollow ? 'M-2,17 Q8,12 16,2' : 'M-2,17 Q4,20 8,20'} stroke={C.ink} strokeWidth={hollow ? 3 : 5} fill="none" strokeLinecap="round" />
      <rect x={-13} y={-22} width={17} height={44} rx={8} fill={fill} stroke={st} strokeWidth={2.6} />
      {!hollow && mark === 'bar' && <rect x={-9} y={-17} width={5} height={34} rx={2} fill={C.light} />}
      {!hollow && mark === 'hatch' && [-1, 0, 1].map((k) => <line key={k} x1={-11} y1={k * 11 - 4} x2={-2} y2={k * 11 + 4} stroke={C.light} strokeWidth={2} />)}
      <circle cx={5} cy={0} r={8} fill={fill} stroke={hollow ? C.ink : C.paper} strokeWidth={2} />
      <line x1={13} y1={0} x2={16} y2={0} stroke={C.ink} strokeWidth={2.4} strokeLinecap="round" />
    </g>
  );
};

/** A person in profile, for the comic panels: a flat ink cut-out, hat optional, no face. */
export const Silhouette = ({x, y, h = 300, coat = true, hat = false, flip = false, opacity = 1, fill = C.ink}) => {
  const s = h / 300;
  return (
    <g transform={`translate(${x},${y}) scale(${flip ? -s : s},${s})`} opacity={opacity}>
      <ellipse cx={0} cy={-262} rx={22} ry={26} fill={fill} />
      {hat && <path d="M-40,-268 L40,-268 L30,-276 L20,-300 L-22,-300 L-30,-276 Z" fill={fill} />}
      <path d="M-12,-238 L12,-238 L16,-226 L-16,-226 Z" fill={fill} />
      <path d={coat ? 'M-46,-226 Q0,-236 46,-226 L58,-80 Q40,-60 36,-40 L-36,-40 Q-40,-60 -58,-80 Z' : 'M-40,-226 Q0,-234 40,-226 L46,-110 L-46,-110 Z'} fill={fill} />
      <path d="M-30,-44 L-24,0 L-8,0 L-4,-44 Z M4,-44 L8,0 L24,0 L30,-44 Z" fill={fill} />
    </g>
  );
};
