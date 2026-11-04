// Cutscene 3: THE PLAN. The game's thesis: a briefing drawn with total confidence, then the
// same house when the plan meets the room. Same walls; everything else changes.
import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, clamp, prog, rnd, Paper, Caption, Stamp, Draw, Fades, Sfx, Bed, PlanFigure} from './ink.jsx';

export const C3_LEN = 1290;

// the shotgun house, in screen pixels
const H = {x0: 360, x1: 1560, y0: 330, y1: 750};
const WALLS = [
  // outer shell (gaps for doors are drawn as door leaves over the wall)
  `M${H.x0},${H.y0} H${H.x1} V${H.y1} H${H.x0} Z`,
  // porch | living
  `M500,${H.y0} V600 M500,690 V${H.y1}`,
  // living | bath+kitchen
  `M900,${H.y0} V640 M900,730 V${H.y1}`,
  // bath | kitchen
  `M900,540 H970 M1050,540 H1130`,
  // kitchen+bath | bedroom
  `M1130,${H.y0} V550 M1130,640 V${H.y1}`,
];
const ROOMS = [['PORCH', 430, 360, true], ['LIVING  &  GUEST  RM', 700, 380], ['BATH', 1015, 380], ['KITCHEN', 1015, 720], ['BEDROOM', 1345, 380]];
// the plan's route, and where the squad actually went
const ROUTE = [[190, 645], [430, 645], [700, 645], [1015, 680], [1250, 600], [1360, 560]];
const RINGS = [[190, 645, '1'], [430, 645, '2'], [1015, 680, '3']];
const pathOf = (pts, wob = 0, f = 0) => pts.map(([x, y], i) => {
  const dx = wob ? Math.sin(i * 1.7 + f * 0.02) * wob + (rnd(i + 3) - 0.5) * wob : 0;
  const dy = wob ? Math.cos(i * 2.3) * wob + (rnd(i + 11) - 0.5) * wob : 0;
  return `${i ? 'L' : 'M'}${x + dx},${y + dy}`;
}).join(' ');

/** A point `t` (0..1) of the way along a polyline. */
const along = (pts, t) => {
  const seg = [];
  let total = 0;
  for (let i = 1; i < pts.length; i++) {
    const l = Math.hypot(pts[i][0] - pts[i - 1][0], pts[i][1] - pts[i - 1][1]);
    seg.push(l);
    total += l;
  }
  let d = t * total;
  for (let i = 0; i < seg.length; i++) {
    if (d <= seg[i]) {
      const k = d / seg[i];
      const a = pts[i], b = pts[i + 1];
      return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, Math.atan2(b[1] - a[1], b[0] - a[0])];
    }
    d -= seg[i];
  }
  const a = pts[pts.length - 2], b = pts[pts.length - 1];
  return [b[0], b[1], Math.atan2(b[1] - a[1], b[0] - a[0])];
};

const Label = ({x, y, tx, ty, text, at, f, struck = null}) => {
  const o = prog(f, at, at + 10);
  const s = struck === null ? 0 : prog(f, struck, struck + 12);
  return (
    <g opacity={o}>
      <line x1={x} y1={y} x2={tx} y2={ty} stroke={C.ink} strokeWidth={1.6} />
      <circle cx={x} cy={y} r={4} fill={C.ink} />
      <rect x={tx - 6} y={ty - 30} width={text.length * 14.4 + 18} height={42} fill={C.paper} stroke={C.ink} strokeWidth={2.5} />
      <text x={tx + 4} y={ty} fontFamily={FONT.caps} fontSize={24} letterSpacing={2} fill={C.ink}>{text}</text>
      {s > 0 && <line x1={tx} y1={ty - 9} x2={tx + (text.length * 14.4 + 8) * s} y2={ty - 9} stroke={C.red} strokeWidth={4} />}
    </g>
  );
};

export const C3_ThePlan = () => {
  const f = useCurrentFrame();
  const RUN = 500;            // the operation starts
  const END = RUN + 380;      // the aftermath
  const app = prog(f, RUN + 40, RUN + 200);          // theory -> application
  // the squad: four officers along the route, spaced out, advancing from RUN
  const squadT = (k) => interpolate(f, [RUN + 10 + k * 14, RUN + 300 + k * 14], [0, 0.86 - k * 0.07], {...clamp, easing: (x) => x});
  const ram = f >= RUN + 30 && f < RUN + 70;
  const bang = f - (RUN + 120);
  const civ = f >= RUN + 150;
  const shot1 = RUN + 236, shot2 = RUN + 244, shot3 = RUN + 252;
  const sus_down = f >= shot2 + 4;
  const grit = [];
  for (let i = 0; i < 90; i++) grit.push(<rect key={i} x={H.x0 + rnd(i) * (H.x1 - H.x0)} y={H.y0 + rnd(i + 50) * (H.y1 - H.y0)} width={2 + (i % 3)} height={1.5} fill={C.ink} opacity={0.25 * app} />);
  return (
    <AbsoluteFill style={{background: C.paper}}>
      <Bed name={f < RUN ? 'amb_office' : 'amb_city'} volume={0.5} total={C3_LEN} />
      <Paper>
        <svg width={1920} height={1080} style={{position: 'absolute'}}>
          {/* the floors, and the room tones the run leaves behind */}
          <rect x={H.x0} y={H.y0} width={H.x1 - H.x0} height={H.y1 - H.y0} fill={C.floor} opacity={prog(f, 30, 60)} />
          <rect x={H.x0} y={H.y0} width={140} height={H.y1 - H.y0} fill={C.light} opacity={0.5 * prog(f, 30, 60)} />
          {/* application: offset shadows, grit, scuffed paper */}
          <g opacity={app}>
            <rect x={H.x0 + 8} y={H.y0 + 8} width={H.x1 - H.x0} height={H.y1 - H.y0} fill="none" stroke={C.dark} strokeOpacity={0.25} strokeWidth={10} />
            {grit}
          </g>
          {/* walls */}
          {WALLS.map((d, i) => <Draw key={i} d={d} a={4 + i * 8} b={50 + i * 8} width={i === 0 ? 14 : 10} len={4000} />)}
          {/* doors: the front door rammed open during the run */}
          <Draw d={`M500,600 A90,90 0 0,1 590,690`} a={50} b={70} width={2} stroke={C.mid} len={300} />
          <line x1={500} y1={600} x2={500 + 90 * Math.sin(interpolate(f, [RUN + 40, RUN + 52], [0, 1.4], clamp))} y2={600 + 90 * Math.cos(interpolate(f, [RUN + 40, RUN + 52], [0, 1.4], clamp))}
            stroke={C.ink} strokeWidth={5} opacity={prog(f, 50, 70)} />
          <Draw d={`M1130,550 A90,90 0 0,0 1220,640`} a={56} b={76} width={2} stroke={C.mid} len={300} />
          {/* furniture, sparse */}
          <g opacity={prog(f, 60, 80)} fill="none" stroke={C.ink} strokeWidth={2.5}>
            <rect x={560} y={360} width={170} height={60} rx={6} /><rect x={760} y={460} width={90} height={60} />
            <rect x={1360} y={360} width={150} height={190} rx={4} /><rect x={930} y={350} width={100} height={60} rx={24} />
            <rect x={940} y={660} width={60} height={50} /><rect x={1050} y={600} width={60} height={110} />
          </g>
          {ROOMS.map(([t, x, y, v]) => (
            <text key={t} x={x} y={y + 20} textAnchor="middle" fontFamily={FONT.caps} fontSize={22} letterSpacing={6} fill={C.dark} opacity={prog(f, 70, 90)}
              transform={v ? `rotate(-90 ${x} ${y + 140})` : ''}>{t}</text>
          ))}
          {/* the plan's route: one clean red line, numbered rings, an arrowhead */}
          <g opacity={1 - 0.55 * app}>
            <Draw d={pathOf(ROUTE)} a={90} b={150} width={4} stroke={C.red} len={1600} />
            {RINGS.map(([x, y, n], i) => (
              <g key={n} opacity={prog(f, 100 + i * 12, 110 + i * 12)}>
                <circle cx={x} cy={y} r={20} fill={C.paper} stroke={C.red} strokeWidth={3} />
                <text x={x} y={y + 8} textAnchor="middle" fontFamily={FONT.caps} fontSize={22} fill={C.ink}>{n}</text>
              </g>
            ))}
            <polygon points="1360,560 1334,560 1352,540" fill={C.red} opacity={prog(f, 146, 152)} transform="rotate(-20 1360 560)" />
          </g>
          {/* what actually happened: the wobbling route and its offset ghost */}
          <path d={pathOf(ROUTE.slice(0, 5), 16, 0)} stroke={C.red} strokeWidth={6} fill="none" opacity={0.6 * app} strokeLinejoin="round" />
          <path d={pathOf(ROUTE.slice(0, 5), 22, 40)} stroke={C.red} strokeWidth={2} fill="none" opacity={0.3 * app} transform="translate(5,4)" />
          {/* the suspect: where the drawing said, roughly */}
          {f >= RUN + 100 && !sus_down && <PlanFigure x={1300} y={470} rot={150} mark="hatch" />}
          {sus_down && (
            <g>
              {/* consequence: one pool, one short trail, a few flecks; smaller than the paperwork */}
              <path d="M1268,486 l26,-14 l30,6 l18,22 l-8,24 l-30,10 l-28,-8 l-12,-20 Z" fill={C.red} opacity={0.68 * prog(f, shot2 + 10, shot2 + 70)} />
              <path d="M1284,492 l16,-8 l18,4 l8,14 l-6,14 l-18,4 l-14,-8 Z" fill={C.red} opacity={0.9 * prog(f, shot2 + 20, shot2 + 80)} />
              <PlanFigure x={1300} y={470} rot={150} mark="hatch" down />
            </g>
          )}
          {/* the civilian the briefing said was not there */}
          {civ && <PlanFigure x={1050} y={640} rot={-90} hollow scale={interpolate(f, [RUN + 150, RUN + 160], [0.6, 1], clamp)} />}
          {civ && f < END && (
            <g opacity={prog(f, RUN + 156, RUN + 162)}>
              {[-1, 1].map((s) => <circle key={s} cx={1048 + s * 11} cy={630} r={4} fill={C.paper} stroke={C.ink} strokeWidth={1.4} />)}
              <text x={1080} y={612} fontFamily={FONT.caps} fontSize={20} letterSpacing={2} fill={C.ink}>HANDS UP</text>
            </g>
          )}
          {/* the squad */}
          {[0, 1, 2, 3].map((k) => {
            const [x, y, a] = f < RUN ? [180 - k * 34, 645 + (k % 2 ? 22 : -22), 0] : along(ROUTE, squadT(k));
            const dx = f < RUN ? 0 : (k % 2 ? 12 : -12) * Math.sin(a + Math.PI / 2);
            const dy = f < RUN ? 0 : (k % 2 ? 12 : -12) * Math.cos(a + Math.PI / 2);
            return <PlanFigure key={k} x={x + dx} y={y - dy} rot={(a * 180) / Math.PI} opacity={prog(f, 120, 140)} />;
          })}
          {/* rounds: ink tracers for a fraction of a second, a paper flash at the muzzle */}
          {[shot1, shot2, shot3].map((s, i) => (f >= s && f < s + 5 ? (
            <g key={i}>
              <line x1={1150 + i * 6} y1={600 - i * 4} x2={1296} y2={476} stroke={C.ink} strokeWidth={1.6} opacity={0.7} />
              <circle cx={1150 + i * 6} cy={600 - i * 4} r={12} fill={C.paper} stroke={C.ink} strokeWidth={1.4} />
            </g>
          ) : null))}
          {/* the flashbang in the living room */}
          {bang >= 0 && bang < 18 && (
            <g>
              <circle cx={760} cy={560} r={40 + bang * 9} fill={C.paper} opacity={0.9 * (1 - bang / 18)} />
              <circle cx={760} cy={560} r={40 + bang * 9} fill="none" stroke={C.ink} strokeWidth={2} opacity={0.7 * (1 - bang / 18)} />
              {Array.from({length: 12}, (_, k) => {
                const a = (k / 12) * Math.PI * 2;
                const r = 40 + bang * 9;
                return <line key={k} x1={760 + Math.cos(a) * r * 0.6} y1={560 + Math.sin(a) * r * 0.6} x2={760 + Math.cos(a) * r * 1.25} y2={560 + Math.sin(a) * r * 1.25} stroke={C.ink} strokeWidth={1.4} opacity={0.6 * (1 - bang / 18)} />;
              })}
            </g>
          )}
          {/* evidence markers, larger than the stain */}
          {[[1240, 520, '1'], [1170, 600, '2'], [1080, 600, '3']].map(([x, y, n], i) => (
            <g key={n} opacity={prog(f, END + 10 + i * 8, END + 16 + i * 8)}>
              <rect x={x - 14} y={y - 14} width={28} height={28} fill={C.paper} stroke={C.ink} strokeWidth={2.5} />
              <text x={x} y={y + 8} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={20} fill={C.ink}>{n}</text>
            </g>
          ))}
          {/* the briefing's confident notes */}
          <Label f={f} at={290} x={1330} y={470} tx={1400} ty={250} text="SUSPECT: BEDROOM (EST. 50%)" />
          <Label f={f} at={318} x={1015} y={660} tx={960} ty={850} text="OTHERS INSIDE: NONE (EST. 40%)" struck={RUN + 166} />
          <Label f={f} at={346} x={500} y={640} tx={300} ty={850} text="DOORS: LOCKED (EST. 40%)" />
          {f >= RUN + 176 && (
            <text x={1480} y={850} fontFamily={FONT.type} fontWeight={700} fontSize={30} fill={C.red} transform="rotate(-4 1480 850)"
              opacity={prog(f, RUN + 176, RUN + 186)}>1 CIVILIAN</text>
          )}
        </svg>
        {/* theory's stamp, replaced by application's */}
        {f < RUN + 40 && <Stamp lines={['MODEL: COMPLETE', 'UNKNOWN: NONE']} at={180} x={90} y={900} color={C.ink} rot={-3} size={30} />}
        {f < RUN + 40 && <Stamp lines={['RISK: APPROVED', 'OWNER: NOT LISTED']} at={196} x={470} y={900} color={C.ink} rot={2} size={30} />}
        <Stamp lines={['ACTUAL: 00:41', 'FRICTION: ALL']} at={END + 40} x={90} y={900} rot={-3} size={30} />
        <Stamp lines={['PAPERWORK: 07 FORMS', 'MOP: REQUESTED']} at={END + 62} x={430} y={900} color={C.ink} rot={2} size={30} />
        <Stamp lines={['FILED', 'NOT RESOLVED']} at={END + 84} x={870} y={890} rot={-5} size={34} />
        <Caption at={20} until={260} x={110} y={60} w={900} size={36} text={'EVERY OPERATION\nBEGINS AS A DRAWING.'} />
        <Caption at={268} until={RUN - 4} x={110} y={60} w={900} size={36} text={'THE DRAWING IS\nALWAYS CONFIDENT.'} />
        <Caption at={RUN + 4} until={END} x={110} y={60} w={900} size={36} text={'THE ROOM IS NOT.'} red="NOT" />
        <Caption at={END + 120} until={C3_LEN} x={110} y={60} w={900} size={36} text={'YOU WILL NOT BE IN THE ROOM.\nYOU WILL SIGN FOR IT.'} />
      </Paper>
      <Fades total={C3_LEN} />
      <Sfx name="click" at={92} volume={0.4} />
      <Sfx name="stamp" at={180} volume={0.6} />
      <Sfx name="stamp" at={196} volume={0.6} />
      <Sfx name="radio" at={RUN - 6} volume={0.6} />
      <Sfx name="ram" at={RUN + 34} volume={0.8} />
      <Sfx name="ram" at={RUN + 46} volume={0.9} />
      <Sfx name="flashbang" at={RUN + 120} volume={0.85} />
      <Sfx name="radio" at={RUN + 158} volume={0.5} />
      <Sfx name="shot_rifle_1" at={shot1} volume={0.9} />
      <Sfx name="shot_rifle_2" at={shot2} volume={0.9} />
      <Sfx name="shot_rifle_1" at={shot3} volume={0.85} rate={1.03} />
      <Sfx name="far_pistol" at={shot1 - 12} volume={0.7} />
      <Sfx name="radio" at={RUN + 290} volume={0.55} />
      <Sfx name="stamp" at={END + 40} volume={0.7} />
      <Sfx name="stamp" at={END + 62} volume={0.7} />
      <Sfx name="stamp" at={END + 84} volume={0.8} />
      <Sfx name="toll" at={C3_LEN - 80} volume={0.6} />
    </AbsoluteFill>
  );
};
