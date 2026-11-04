// S04 · STAGING. Seven seconds in the street before the door: two vans, a wet road from
// above, a squad hugging the wall, and the radio call that starts it.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {AbsoluteFill} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, PlanFigure, Sfx} from './kit.jsx';

const P = {x0: 40, y0: 40, x1: 1880, y1: 986};
const B = {x0: 110, x1: 1810, y0: 60, y1: 556};     // the building
const DOOR = {x0: 902, x1: 980};                     // a gap in its south wall
const WALK = 578;                                    // the sidewalk, where the squad stacks

const Van = ({x, y, w = 320, h = 146, label = 'POLICE'}) => (
  <g transform={`translate(${x},${y})`}>
    <rect x={0} y={0} width={w} height={h} fill={C.ink} stroke={C.paper} strokeWidth={2.5} />
    <rect x={16} y={14} width={w - 96} height={h - 28} fill="none" stroke={C.paper} strokeWidth={1.4} opacity={0.4} />
    <rect x={w - 66} y={18} width={46} height={h - 36} fill={C.paper} opacity={0.14} />
    <text x={26} y={h - 26} fontFamily={FONT.caps} fontSize={17} letterSpacing={5} fill={C.paper} opacity={0.75}>{label}</text>
    {[0, 1].map((k) => (
      <rect key={k} x={46 + k * 160} y={h} width={46} height={15} fill={C.ink} stroke={C.paper} strokeWidth={1.4} />
    ))}
  </g>
);

const Lamp = ({x, y, pool = 260}) => (
  <g>
    <circle cx={x} cy={y} r={pool} fill={C.paper} opacity={0.045} />
    <circle cx={x} cy={y} r={pool * 0.55} fill={C.paper} opacity={0.05} />
    <circle cx={x} cy={y} r={13} fill={C.paper} opacity={0.8} />
    <circle cx={x} cy={y} r={26} fill="none" stroke={C.paper} strokeWidth={1.4} opacity={0.4} />
  </g>
);

export const S04_Staging = ({callsign = 'A-2', time = '02:14', officers = 6, street = 'FOUNDRY ST', showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const n = Math.max(2, Math.min(16, officers));
  const breach = 152;

  const figs = Array.from({length: n}, (_, i) => {
    const stackX = 860 - i * 56;
    const stackY = WALK + 4 - (i % 3) * 10;
    const t = Math.max(0, Math.min(1, (f - (breach - 16) - i * 3) / 48));
    const inDoor = i < 5;
    const x = stackX + (inDoor ? 30 : 6) * t + (i % 2 ? 8 : -8) * t;
    const y = stackY - t * (inDoor ? 220 + i * 8 : 34);
    return {x, y, o: prog(f, 46 + i * 6, 58 + i * 6), t, inDoor};
  });

  const rain = [];
  for (let i = 0; i < 170; i++) {
    const x0 = rnd(i) * 1960 + P.x0 - 40;
    const yy = ((rnd(i + 99) * 1100 + f * 46 * (0.8 + rnd(i + 7) * 0.4)) % 1000) + 30;
    const xx = x0 + yy * 0.16;
    rain.push(<line key={i} x1={xx} y1={yy} x2={xx + 4} y2={yy + 26} stroke={C.paper} strokeWidth={1.2} opacity={0.1 + rnd(i + 3) * 0.14} />);
  }

  return (
    <Scene len={210} note="PRE-RUN" right="NO AUDIO RECORDING" bed="amb_city" bedVol={0.42} showSlots={showSlots} slots={slots}>
      <AbsoluteFill style={{background: C.paper}}>
        <svg width={1920} height={1080} style={{position: 'absolute'}}>
          <defs>
            <pattern id="nb" width={15} height={15} patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
              <line x1={0} y1={0} x2={0} y2={15} stroke={C.paper} strokeWidth={1} />
            </pattern>
            <pattern id="road" width={22} height={22} patternUnits="userSpaceOnUse">
              <circle cx={4} cy={4} r={1.2} fill={C.paper} />
            </pattern>
          </defs>

          {/* the plate: one full-frame still from the street, printed on the page */}
          <rect x={P.x0} y={P.y0} width={P.x1 - P.x0} height={P.y1 - P.y0} fill={C.ink} />
          <g opacity={prog(f, 8, 24)}>
            <rect x={B.x0} y={B.y0} width={B.x1 - B.x0} height={B.y1 - B.y0} fill="#1a1a1a" stroke={C.paper} strokeWidth={2.6} />
            <rect x={B.x0} y={B.y0} width={B.x1 - B.x0} height={B.y1 - B.y0} fill="url(#nb)" opacity={0.3} />
            {/* windows: a few lit, most not */}
            {Array.from({length: 8}, (_, k) => (
              <rect key={k} x={190 + k * 206} y={118} width={118} height={66} fill={C.paper}
                opacity={rnd(k + 2) > 0.66 ? 0.14 : 0.035} stroke={C.paper} strokeWidth={1} />
            ))}
            {/* the south wall, with the door gap */}
            <rect x={B.x0} y={B.y1 - 7} width={DOOR.x0 - B.x0} height={7} fill={C.paper} />
            <rect x={DOOR.x1} y={B.y1 - 7} width={B.x1 - DOOR.x1} height={7} fill={C.paper} />
            {/* the door leaf, swung in, and its arc */}
            <path d={`M${DOOR.x1},${B.y1 - 7} L${DOOR.x1 + 26},${B.y1 - 96}`} stroke={C.paper} strokeWidth={3} />
            <path d={`M${DOOR.x1},${B.y1 - 7} A88,88 0 0,0 ${DOOR.x1 + 88},${B.y1 - 95}`} fill="none" stroke={C.paper} strokeWidth={1.2} opacity={0.45} />
          </g>

          {/* sidewalk */}
          <rect x={P.x0} y={B.y1} width={P.x1 - P.x0} height={20} fill={C.light} />
          <rect x={P.x0} y={B.y1 + 20} width={P.x1 - P.x0} height={8} fill={C.paper} opacity={0.5} />
          {/* road */}
          <rect x={P.x0} y={B.y1 + 28} width={P.x1 - P.x0} height={P.y1 - B.y1 - 28} fill="#0d0d0d" />
          <rect x={P.x0} y={B.y1 + 28} width={P.x1 - P.x0} height={P.y1 - B.y1 - 28} fill="url(#road)" opacity={0.08} />
          {[0, 1].map((k) => (
            <line key={k} x1={P.x0} y1={B.y1 + 150 + k * 160} x2={P.x1} y2={B.y1 + 150 + k * 160} stroke={C.paper} strokeWidth={6}
              strokeDasharray="76 96" opacity={0.09} />
          ))}
          <Lamp x={330} y={B.y1 + 70} pool={300} />
          <Lamp x={1510} y={B.y1 + 70} pool={300} />

          {/* vans: one at each kerb */}
          <g opacity={prog(f, 26, 38)}><Van x={180} y={B.y1 + 34} w={360} h={160} /></g>
          <g opacity={prog(f, 36, 48)}><Van x={1330} y={B.y1 + 218} w={390} h={172} label="P C P D" /></g>

          {/* the squad on the wall, then through the door */}
          {figs.map((p, i) => (
            <g key={i} opacity={p.o}>
              <PlanFigure x={p.x} y={p.y} rot={-90 + (p.t > 0.6 && p.inDoor ? 90 : 0)} scale={1.12} hollow gun={false} />
            </g>
          ))}

          {/* rain, on the near side of everything */}
          <g>{rain}</g>

          {/* the radio, in the corner of the frame */}
          <g opacity={prog(f, 92, 102)}>
            <rect x={1462} y={96} width={382} height={176} fill={C.paper} stroke={C.ink} strokeWidth={4} />
            <text x={1488} y={150} fontFamily={FONT.caps} fontWeight={600} fontSize={48} letterSpacing={4} fill={C.ink}>{String(callsign).toUpperCase()}</text>
            <text x={1488} y={188} fontFamily={FONT.type} fontSize={21} fill={C.dark}>{time} · {String(street).toUpperCase()}</text>
            {Array.from({length: 28}, (_, k) => {
              const amp = 0.16 + 0.84 * Math.abs(Math.sin(k * 1.7 + f * 0.42)) * (k < 22 ? 1 : 0.35);
              return <rect key={k} x={1488 + k * 12} y={250 - amp * 22} width={5} height={amp * 44} fill={C.ink} opacity={0.85} />;
            })}
          </g>

          <text x={132} y={118} fontFamily={FONT.caps} fontSize={22} letterSpacing={10} fill={C.paper} opacity={0.9}>STAGING</text>
          <text x={132} y={150} fontFamily={FONT.type} fontSize={19} fill={C.paper} opacity={0.5}>Seen from directly above, as the plan will show it.</text>
          <text x={132} y={932} fontFamily={FONT.caps} fontSize={19} letterSpacing={8} fill={C.paper} opacity={0.65}>
            {`STAGED · ${String(street).toUpperCase()} · ${time} · ${n} OFFICERS`}
          </text>

          {/* the call, and the threshold in red */}
          <At at={breach - 6} from="none" style={{left: 1030, top: 620, width: 520}}>
            <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 104, letterSpacing: 14, color: C.paper}}>GO</div>
          </At>
          <g opacity={prog(f, breach, breach + 6)}>
            <line x1={DOOR.x0} y1={B.y1 - 4} x2={DOOR.x1} y2={B.y1 - 4} stroke={C.red} strokeWidth={9} />
            <line x1={DOOR.x0} y1={B.y1 - 18} x2={DOOR.x0} y2={B.y1 + 10} stroke={C.red} strokeWidth={4} />
            <line x1={DOOR.x1} y1={B.y1 - 18} x2={DOOR.x1} y2={B.y1 + 10} stroke={C.red} strokeWidth={4} />
            <line x1={DOOR.x0} y1={B.y1 + 120} x2={DOOR.x1} y2={B.y1 + 120} stroke={C.red} strokeWidth={2} strokeDasharray="6 6" opacity={0.7} />
          </g>
        </svg>
      </AbsoluteFill>

      <Sfx name="door" at={30} volume={0.5} />
      <Sfx name="radio" at={92} volume={0.55} />
      <Sfx name="radio" at={144} volume={0.7} rate={1.06} />
      <Sfx name="kick" at={breach} volume={0.7} />
      <Sfx name="ram" at={breach + 2} volume={0.9} />
      <Sfx name="radio" at={172} volume={0.4} />
    </Scene>
  );
};
