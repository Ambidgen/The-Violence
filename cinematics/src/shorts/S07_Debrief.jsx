// S07 · THE FOG LIFTS. Seven seconds after an operation: the plan as it was drawn, then the
// same sheet as it actually went — the route that wobbled, the rounds, the markers.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Slam, Draw, Wall, Marker, PlanFigure, Meter, Sfx, Kicker} from './kit.jsx';

const P = {x0: 420, y0: 236, x1: 1330, y1: 760};
const ROUTE = [[330, 690], [420, 690], [700, 690], [700, 470], [1040, 470], [1040, 320], [1290, 320]];
const pathOf = (pts, wob = 0, seed = 0) => pts.map(([x, y], i) => {
  const dx = wob ? (rnd(i + seed) - 0.5) * wob : 0;
  const dy = wob ? (rnd(i + seed + 9) - 0.5) * wob : 0;
  return `${i ? 'L' : 'M'}${x + dx},${y + dy}`;
}).join(' ');

export const S07_Debrief = ({rounds = 9, findings = 3, minutes = 41, civilians = 1, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const truth = prog(f, 62, 120);          // the sheet stops being a plan
  const markers = Math.max(0, Math.min(12, findings));

  const count = (target, at) => Math.round(target * prog(f, at, at + 26));
  const grit = Array.from({length: 80}, (_, i) => (
    <rect key={i} x={P.x0 + rnd(i) * (P.x1 - P.x0)} y={P.y0 + rnd(i + 31) * (P.y1 - P.y0)} width={2 + (i % 3)} height={1.6} fill={C.ink} opacity={0.22 * truth} />
  ));

  return (
    <Scene len={210} note="DEBRIEF" right="THE FOG LIFTS" bed="amb_office" bedVol={0.26} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 88, width: 420}}>THE INCIDENT RECORD</Kicker>
      <At at={10} from="left" style={{left: 96, top: 132, width: 660}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 56, lineHeight: 1.02, letterSpacing: 2, color: C.ink}}>
          WHAT THE ROOM<br />ACTUALLY DID
        </div>
      </At>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {/* the sheet */}
        <rect x={P.x0} y={P.y0} width={P.x1 - P.x0} height={P.y1 - P.y0} fill={C.floor} opacity={prog(f, 10, 26)} />
        <g opacity={prog(f, 14, 30)}>{grit}</g>
        <Wall x1={P.x0} y1={P.y0} x2={P.x1} y2={P.y0} at={12} w={13} />
        <Wall x1={P.x1} y1={P.y0} x2={P.x1} y2={P.y1} at={14} w={13} />
        <Wall x1={P.x1} y1={P.y1} x2={P.x0} y2={P.y1} at={16} w={13} />
        <Wall x1={P.x0} y1={P.y1} x2={P.x0} y2={P.y0} at={18} w={13} />
        <Wall x1={P.x0} y1={560} x2={640} y2={560} at={22} w={9} />
        <Wall x1={720} y1={560} x2={P.x1} y2={560} at={24} w={9} />
        <Wall x1={1040} y1={P.y0} x2={1040} y2={430} at={26} w={9} />
        <Wall x1={1040} y1={510} x2={1040} y2={560} at={28} w={9} />

        {/* the plan's route, clean, with its numbered confidence */}
        <g opacity={1 - 0.75 * truth}>
          <Draw d={pathOf(ROUTE)} a={34} b={70} width={5} stroke={C.red} len={1500} />
          {[0, 1, 2].map((i) => (
            <g key={i} opacity={prog(f, 44 + i * 8, 52 + i * 8)}>
              <circle cx={ROUTE[i + 1][0]} cy={ROUTE[i + 1][1]} r={19} fill={C.paper} stroke={C.ink} strokeWidth={2.6} />
              <text x={ROUTE[i + 1][0]} y={ROUTE[i + 1][1] + 7} textAnchor="middle" fontFamily={FONT.caps} fontSize={19} fill={C.ink}>{i + 1}</text>
            </g>
          ))}
        </g>

        {/* what happened: the route that leaned, the officers where they finished */}
        <g opacity={truth}>
          <path d={pathOf(ROUTE, 46, 7)} fill="none" stroke={C.red} strokeWidth={6} strokeLinejoin="round" opacity={0.75} />
          <path d={pathOf(ROUTE, 62, 19)} fill="none" stroke={C.red} strokeWidth={2} strokeLinejoin="round" opacity={0.35} transform="translate(6,5)" />
          {[[700, 500, -90], [760, 560, 0], [900, 470, -40], [1180, 360, -30]].map(([x, y, rot], i) => (
            <g key={i} opacity={prog(f, 96 + i * 8, 106 + i * 8)}><PlanFigure x={x} y={y} rot={rot} scale={1.0} /></g>
          ))}
          {/* the one place the plan touched */}
          <circle cx={1180} cy={330} r={46} fill="none" stroke={C.red} strokeWidth={3} strokeDasharray="7 6" opacity={prog(f, 120, 132)} />
          <path d="M1148,352 l26,-26 l26,26" fill="none" stroke={C.red} strokeWidth={3.5} opacity={prog(f, 120, 132)} />
          <text x={1180} y={292} textAnchor="middle" fontFamily={FONT.caps} fontSize={15} letterSpacing={3} fill={C.red} opacity={prog(f, 126, 136)}>HERE</text>

          {/* evidence markers, laid where the paperwork will point */}
          {Array.from({length: markers}, (_, i) => {
            const spots = [[930, 600], [1050, 520], [700, 660], [1240, 500], [860, 400], [620, 620], [1120, 640], [780, 300], [1290, 640], [560, 480], [1000, 700], [1240, 380]];
            const [x, y] = spots[i % spots.length];
            return <Marker key={i} x={x} y={y} n={i + 1} at={130 + i * 5} size={28} />;
          })}
        </g>

        <text x={P.x1} y={P.y0 - 20} textAnchor="end" fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.mid} opacity={prog(f, 30, 40) * (1 - truth)}>
          THE PLAN, AS DRAWN
        </text>
        <text x={P.x1} y={P.y0 - 20} textAnchor="end" fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.dark} opacity={truth}>
          THE PLAN, AS IT WENT
        </text>
      </svg>

      {/* the counters */}
      <g />
      <At at={140} from="right" style={{left: 1380, top: 236, width: 440}}>
        <div style={{border: `5px solid ${C.ink}`, background: C.paper, padding: '24px 26px', boxShadow: '10px 10px 0 rgba(18,18,18,0.16)'}}>
          {[['ROUNDS FIRED', count(rounds, 140)], ['FINDINGS', count(markers, 146)], ['MINUTES', count(minutes, 152)], ['CIVILIANS INSIDE', count(civilians, 158)]].map(([k, v], i) => (
            <div key={k} style={{display: 'flex', justifyContent: 'space-between', alignItems: 'baseline',
              borderBottom: i < 3 ? `1px solid rgba(18,18,18,0.22)` : 'none', padding: '10px 0'}}>
              <span style={{fontFamily: FONT.caps, fontSize: 16, letterSpacing: 4, color: C.mid}}>{k}</span>
              <span style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 46, color: C.ink}}>{v}</span>
            </div>
          ))}
        </div>
      </At>

      <At at={168} from="none" style={{left: 96, top: 820, width: 1100}}>
        <div style={{fontFamily: FONT.type, fontSize: 25, lineHeight: 1.4, color: C.ink}}>
          Every officer saw a different room.<br />
          The record is the only one that was in all of them.
        </div>
      </At>

      <Slam lines={['FILED', 'NOT RESOLVED']} at={178} x={1400} y={700} rot={-4.5} size={30} vol={0.65} />
      <Sfx name="click" at={62} volume={0.4} />
      <Sfx name="radio" at={96} volume={0.4} />
      <Sfx name="click" at={130} volume={0.3} />
      <Sfx name="stamp" at={178} volume={0.6} />
      <Sfx name="toll" at={196} volume={0.4} />
    </Scene>
  );
};
