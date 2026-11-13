// S03 · THE PLAN. Eight seconds between the last order and RUN: the sheet, the route in
// red, the squads on it, and the signature that makes it yours.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, At, Scene, Slam, Draw, Wall, Step, PlanFigure, Sfx, Kicker} from './kit.jsx';

const P = {x0: 470, x1: 1490, y0: 250, y1: 770};

// walls, as pen strokes; doorways are the gaps
const WALLS = [
  [P.x0, P.y0, P.x1, P.y0],
  [P.x1, P.y0, P.x1, P.y1],
  [P.x0, P.y1, 700, P.y1], [790, P.y1, P.x1, P.y1],
  [P.x0, P.y0, P.x0, 610], [P.x0, 700, P.x0, P.y1],
  [860, P.y0, 860, 430], [860, 520, 860, 660], [860, 740, 860, P.y1],
  [P.x0, 600, 520, 600], [600, 600, 860, 600],
  [860, 600, 1150, 600], [1230, 600, 1340, 600], [1420, 600, P.x1, 600],
  [1290, P.y0, 1290, 280], [1290, 370, 1290, 600],
];
const EXTRA = {6: [[1290, 380, P.x1, 380]], 7: [[1080, 600, 1080, P.y1]], 8: [[600, 250, 600, 600]]};

const ROUTE_A = [[300, 655], [470, 655], [700, 655], [700, 470], [1000, 470], [1000, 320], [1300, 320], [1440, 320]];
const ROUTE_B = [[300, 655], [470, 655], [700, 655], [1080, 655], [1380, 655], [1380, 540]];

const pathOf = (pts) => pts.map(([x, y], i) => `${i ? 'L' : 'M'}${x},${y}`).join(' ');
const lenOf = (pts) => pts.reduce((s, p, i) => (i ? s + Math.hypot(p[0] - pts[i - 1][0], p[1] - pts[i - 1][1]) : 0), 0);
const along = (pts, t) => {
  const segs = [];
  let total = 0;
  for (let i = 1; i < pts.length; i++) { const l = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]); segs.push(l); total += l; }
  let d = Math.max(0, Math.min(1, t)) * total;
  for (let i = 0; i < segs.length; i++) {
    if (d <= segs[i] || i === segs.length - 1) {
      const k = segs[i] ? Math.min(1, d / segs[i]) : 0;
      const a = pts[i], b = pts[i + 1];
      return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, (Math.atan2(b[1] - a[1], b[0] - a[0]) * 180) / Math.PI];
    }
    d -= segs[i];
  }
  return [pts[0][0], pts[0][1], 0];
};

const DOORS = [
  'M470,700 A90,90 0 0,0 560,610',
  'M700,770 A90,90 0 0,1 790,680',
  'M860,520 A90,90 0 0,1 950,430',
  'M860,740 A80,80 0 0,1 940,660',
  'M1290,370 A90,90 0 0,0 1200,280',
  'M1150,600 A80,80 0 0,1 1230,680',
  'M520,600 A80,80 0 0,1 600,680',
  'M1340,600 A80,80 0 0,1 1420,680',
];

const ROWS = (entry, squads, officers, objective) => [
  ['ENTRY', entry],
  ['SQUADS', String(squads)],
  ['OFFICERS', String(officers)],
  ['OBJECTIVE', objective],
];

export const S03_Plan = ({entry = 'FRONT DOOR', squads = 2, officers = 6, objective = 'CLEAR THE HOUSE', rooms = 5, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const nOff = Math.max(1, Math.min(30, officers));
  const rows = ROWS(String(entry).toUpperCase(), squads, nOff, String(objective).toUpperCase());

  const extras = [];
  if (rooms >= 6) extras.push(...EXTRA[6]);
  if (rooms >= 7) extras.push(...EXTRA[7]);
  if (rooms >= 8) extras.push(...EXTRA[8]);

  // officers split between the two routes
  const figs = Array.from({length: nOff}, (_, i) => i);
  const laneA = figs.filter((i) => i % 2 === 0);
  const laneB = figs.filter((i) => i % 2 === 1);

  return (
    <Scene len={240} note="THE PLAN" right="BEFORE RUN" bed="amb_office" bedVol={0.28} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 84, width: 380}}>SHEET 1 OF 1</Kicker>
      <At at={10} from="left" style={{left: 96, top: 130, width: 340}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 78, lineHeight: 0.94, letterSpacing: 2, color: C.ink}}>
          THE<br />PLAN
        </div>
      </At>
      <At at={28} from="none" style={{left: 98, top: 306, width: 300}}>
        <div style={{fontFamily: FONT.type, fontSize: 21, lineHeight: 1.45, color: C.dark}}>
          Drawn in the office.<br />Settled in the room.
        </div>
      </At>

      {/* the legend: red is only ever the route */}
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <g opacity={prog(f, 46, 58)}>
          <line x1={98} y1={404} x2={158} y2={404} stroke={C.red} strokeWidth={5} />
          <text x={172} y={411} fontFamily={FONT.caps} fontSize={17} letterSpacing={3} fill={C.ink}>ROUTE</text>
          <g transform="translate(98,462)">
            <PlanFigure x={0} y={0} rot={0} scale={0.62} />
            <text x={44} y={7} fontFamily={FONT.caps} fontSize={17} letterSpacing={3} fill={C.ink}>OFFICER</text>
          </g>
          <g transform="translate(98,520)">
            <circle cx={0} cy={0} r={15} fill={C.paper} stroke={C.ink} strokeWidth={2.5} />
            <text x={0} y={6} textAnchor="middle" fontFamily={FONT.caps} fontSize={16} fill={C.ink}>1</text>
            <text x={30} y={7} fontFamily={FONT.caps} fontSize={17} letterSpacing={3} fill={C.ink}>CHECK</text>
          </g>
        </g>

        {/* the floor */}
        <rect x={P.x0} y={P.y0} width={P.x1 - P.x0} height={P.y1 - P.y0} fill={C.floor} opacity={prog(f, 10, 26)} />
        <rect x={P.x0} y={600} width={P.x1 - P.x0} height={P.y1 - 600} fill={C.light} opacity={0.45 * prog(f, 18, 34)} />

        {/* walls */}
        {WALLS.map(([x1, y1, x2, y2], i) => (
          <Wall key={i} x1={x1} y1={y1} x2={x2} y2={y2} at={12 + i * 3} dur={14} w={i < 2 ? 13 : 9} />
        ))}
        {extras.map(([x1, y1, x2, y2], i) => (
          <Wall key={'x' + i} x1={x1} y1={y1} x2={x2} y2={y2} at={54 + i * 5} dur={12} w={7} />
        ))}

        {/* door leaves, so the gaps read as doors */}
        {DOORS.map((d, i) => (
          <path key={i} d={d} fill="none" stroke={C.mid} strokeWidth={2.2} opacity={0.8 * prog(f, 58, 70)} />
        ))}

        {/* room labels, as the sheet writes them */}
        {[['LIVING', 660, 730], ['HALL', 760, 380], ['KITCHEN', 1090, 700], ['BEDROOM', 1150, 400], ['BEDROOM', 1390, 440], ['BATH', 1120, 320]].map(([t, x, y], i) => (
          <text key={i} x={x} y={y} textAnchor="middle" fontFamily={FONT.caps} fontSize={17} letterSpacing={4} fill={C.dark} opacity={0.85 * prog(f, 66 + i * 3, 74 + i * 3)}>{t}</text>
        ))}

        {/* the routes */}
        <Draw d={pathOf(ROUTE_A)} a={84} b={132} width={5} stroke={C.red} len={lenOf(ROUTE_A)} />
        <Draw d={pathOf(ROUTE_B)} a={100} b={146} width={5} stroke={C.red} len={lenOf(ROUTE_B)} opacity={0.85} />
        <Step x={700} y={470} n={1} at={128} />
        <Step x={1000} y={320} n={2} at={138} />
        <Step x={1080} y={655} n={3} at={148} />
        <text x={1380} y={286} textAnchor="middle" fontFamily={FONT.caps} fontSize={16} letterSpacing={3} fill={C.red} opacity={prog(f, 150, 160)}>CLEAR</text>

        {/* the squad: stacked outside, then on the route */}
        {figs.map((i) => {
          const onA = i % 2 === 0;
          const idx = onA ? laneA.indexOf(i) : laneB.indexOf(i);
          const start = 64 + i * 5;
          const t = Math.min(1, Math.max(0, (f - start - 34) / 76)) * (onA ? 0.92 : 0.88);
          const pts = onA ? ROUTE_A : ROUTE_B;
          const [x, y, rot] = t > 0 ? along(pts, Math.min(t, 0.99)) : [300 - (i % 4) * 26, 655 + (i % 3) * 26, 0];
          const o = prog(f, start, start + 12);
          return <PlanFigure key={i} x={x} y={y + (i % 3) * 6} rot={rot} scale={1.05} opacity={o} />;
        })}
      </svg>

      {/* the right rail: what the sheet says, in numbers */}
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <line x1={1560} y1={150} x2={1560} y2={660} stroke={C.ink} strokeWidth={2} opacity={0.35} />
        {rows.map(([k, v], i) => (
          <g key={k} opacity={prog(f, 116 + i * 12, 124 + i * 12)}>
            <text x={1600} y={176 + i * 96} fontFamily={FONT.caps} fontSize={17} letterSpacing={5} fill={C.mid}>{k}</text>
            <text x={1600} y={222 + i * 96} fontFamily={FONT.caps} fontWeight={600} fontSize={i === 3 ? 30 : 38} letterSpacing={2} fill={C.ink}>{v}</text>
            {i < 3 ? <line x1={1600} y1={244 + i * 96} x2={1850} y2={244 + i * 96} stroke={C.ink} strokeWidth={1} opacity={0.2} /> : null}
          </g>
        ))}
        <text x={1600} y={640} fontFamily={FONT.type} fontSize={17} fill={C.dark} opacity={prog(f, 170, 182)}>Every door is a decision.</text>
      </svg>

      <Slam lines={['SIGNED', 'CHIEF OF POLICE']} at={182} x={1080} y={836} rot={-3} size={30} vol={0.62} />
      <Sfx name="click" at={84} volume={0.35} />
      <Sfx name="click" at={100} volume={0.3} />
      <Sfx name="door" at={132} volume={0.35} />
      <Sfx name="click" at={116} volume={0.25} />
      <Sfx name="toll" at={216} volume={0.4} />
    </Scene>
  );
};
