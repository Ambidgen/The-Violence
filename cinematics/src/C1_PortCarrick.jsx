// Cutscene 1: PORT CARRICK. The city, the mill that is closing, the wards and the crews,
// the gunfire on the map, and the empty office on the third floor of headquarters.
import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, clamp, prog, rnd, Paper, Panel, Caption, Stamp, Draw, Rain, Fades, Sfx, Bed, Halftone, Hatch, Silhouette} from './ink.jsx';

export const C1_LEN = 1260;

// ------------------------------------------------------------------ the skyline
const BASE = 780;
const BLOCKS = [[0, 140, 120], [130, 90, 190], [215, 160, 150], [370, 70, 240], [430, 180, 130], [1180, 120, 210], [1290, 150, 160],
  [1430, 90, 260], [1510, 170, 140], [1670, 110, 200], [1770, 160, 120]];
const STACKS = [[700, 330], [770, 360], [840, 300], [910, 340]];

function skylinePath() {
  let d = '';
  for (const [x, w, h] of BLOCKS) d += `M${x},${BASE} L${x},${BASE - h} L${x + w},${BASE - h} L${x + w},${BASE} `;
  // the mill shed: a long saw-tooth roof
  d += `M640,${BASE} L640,${BASE - 150} `;
  for (let i = 0; i < 9; i++) d += `L${660 + i * 50},${BASE - 190} L${690 + i * 50},${BASE - 150} `;
  d += `L1100,${BASE - 150} L1100,${BASE} `;
  for (const [x, h] of STACKS) d += `M${x},${BASE - 150} L${x + 6},${BASE - h} L${x + 30},${BASE - h} L${x + 36},${BASE - 150} `;
  // a gantry crane over the river
  d += `M1110,${BASE} L1130,${BASE - 300} L1150,${BASE} M1130,${BASE - 300} L1330,${BASE - 300} M1130,${BASE - 290} L1300,${BASE - 300} M1300,${BASE - 300} L1300,${BASE - 220}`;
  return d;
}

const Skyline = ({f}) => {
  const fillO = prog(f, 70, 100);
  const smoke = [];
  // only one stack still smokes, and it is thinning
  for (let i = 0; i < 14; i++) {
    const t = ((f * 0.6 + i * 18) % 250) / 250;
    smoke.push(<circle key={i} cx={776 + 18 + t * 160 + Math.sin(i + t * 6) * 14} cy={BASE - 360 - t * 260} r={14 + t * 60}
      fill={C.mid} opacity={(1 - t) * 0.22 * (1 - prog(f, 0, 1200) * 0.6)} />);
  }
  return (
    <svg width={1920} height={1080} style={{position: 'absolute'}}>
      <defs>
        <Hatch id="sky" step={10} w={1.2} opacity={0.18} angle={60} />
        <Halftone id="ht" step={10} r={2.2} opacity={0.4} />
      </defs>
      <rect x={0} y={0} width={1920} height={BASE} fill="url(#sky)" />
      {smoke}
      <Draw d={skylinePath()} a={4} b={80} width={4} fill={C.ink} fillAt={70} len={9000} />
      {/* the windows that are still lit */}
      {BLOCKS.map(([x, w, h], i) => [0, 1, 2].map((k) => (rnd(i * 7 + k) > 0.55 ? (
        <rect key={i + '-' + k} x={x + 14 + k * 30} y={BASE - h + 24 + (k % 2) * 40} width={12} height={18} fill={C.paper} opacity={fillO * 0.85} />
      ) : null)))}
      {/* the river: plan-like lines under the city */}
      <rect x={0} y={BASE} width={1920} height={300} fill={C.dark} opacity={0.92 * fillO} />
      {[0, 1, 2, 3, 4, 5].map((k) => (
        <line key={k} x1={(k * 311 + f * 1.4) % 2100 - 200} y1={BASE + 40 + k * 42} x2={(k * 311 + f * 1.4) % 2100 + 60} y2={BASE + 40 + k * 42}
          stroke={C.light} strokeWidth={2} opacity={0.35 * fillO} />
      ))}
      {/* the bridge */}
      <Draw d={`M1180,${BASE + 10} L1920,${BASE + 10} M1180,${BASE - 40} L1920,${BASE - 40} ${Array.from({length: 15}, (_, i) => `M${1180 + i * 50},${BASE + 10} L${1205 + i * 50},${BASE - 40} L${1230 + i * 50},${BASE + 10}`).join(' ')}`}
        a={40} b={110} width={3} len={6000} stroke={C.paper} />
    </svg>
  );
};

// ------------------------------------------------------------------ the three panels
const MillGate = () => (
  <svg width={576} height={406}>
    <defs><Hatch id="g1" step={9} opacity={0.25} /></defs>
    <rect width={576} height={406} fill="url(#g1)" />
    <rect x={40} y={60} width={40} height={346} fill={C.ink} />
    <rect x={496} y={60} width={40} height={346} fill={C.ink} />
    {Array.from({length: 18}, (_, i) => <rect key={i} x={92 + i * 22} y={110} width={7} height={296} fill={C.ink} />)}
    <rect x={80} y={150} width={416} height={10} fill={C.ink} />
    <rect x={80} y={330} width={416} height={10} fill={C.ink} />
    {/* the chain */}
    {Array.from({length: 7}, (_, i) => <ellipse key={i} cx={232 + i * 18} cy={246 + (i % 2) * 4} rx={11} ry={7} fill="none" stroke={C.mid} strokeWidth={4} />)}
    <rect x={292} y={252} width={26} height={30} rx={4} fill={C.mid} stroke={C.ink} strokeWidth={2} />
    {/* the notice */}
    <rect x={170} y={170} width={236} height={112} fill={C.paper} stroke={C.ink} strokeWidth={3} transform="rotate(-3 288 226)" />
    <text x={288} y={222} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={46} fill={C.ink} transform="rotate(-3 288 226)">CLOSED</text>
    <text x={288} y={258} textAnchor="middle" fontFamily={FONT.type} fontSize={15} fill={C.ink} transform="rotate(-3 288 226)">BY ORDER OF THE RECEIVER</text>
    <text x={30} y={40} fontFamily={FONT.caps} fontSize={22} letterSpacing={4} fill={C.ink}>CARRICK IRONWORKS · GATE 3</text>
  </svg>
);

const Street = ({f}) => {
  const flick = 0.85 + 0.15 * Math.sin(f * 0.9) * Math.sin(f * 0.37);
  return (
    <svg width={576} height={406}>
      <rect width={576} height={406} fill={C.ink} />
      <polygon points="310,70 160,406 470,406" fill={C.paper} opacity={0.82 * flick} />
      <rect x={300} y={40} width={8} height={366} fill={C.dark} />
      <path d="M300,44 Q280,40 270,60 L330,60 Q330,44 300,44 Z" fill={C.dark} />
      <ellipse cx={300} cy={64} rx={22} ry={6} fill={C.paper} opacity={flick} />
      <Silhouette x={340} y={392} h={250} hat coat />
      {/* puddle reflections */}
      {[0, 1, 2].map((k) => <line key={k} x1={180 + k * 40} y1={395 - k * 3} x2={260 + k * 50} y2={395 - k * 3} stroke={C.ink} strokeWidth={2} opacity={0.4} />)}
      <text x={20} y={34} fontFamily={FONT.caps} fontSize={22} letterSpacing={4} fill={C.paper}>CANAL STREET · 2:10 A.M.</text>
    </svg>
  );
};

const Ledger = () => (
  <svg width={566} height={406}>
    <rect width={566} height={406} fill={C.paper} />
    <text x={283} y={52} textAnchor="middle" fontFamily={FONT.caps} fontSize={34} letterSpacing={9} fill={C.ink}>THE CARRICK LEDGER</text>
    <line x1={24} y1={66} x2={542} y2={66} stroke={C.ink} strokeWidth={3} />
    <line x1={24} y1={72} x2={542} y2={72} stroke={C.ink} strokeWidth={1} />
    <text x={24} y={124} fontFamily={FONT.caps} fontWeight={600} fontSize={40} fill={C.ink}>IRONWORKS PLANT CLOSES:</text>
    <text x={24} y={170} fontFamily={FONT.caps} fontWeight={600} fontSize={40} fill={C.ink}>300 SHIFTS CUT</text>
    <text x={24} y={204} fontFamily={FONT.type} fontSize={17} fill={C.dark}>Workers left the east gate with lockers in boxes.</text>
    {Array.from({length: 9}, (_, i) => <rect key={i} x={24} y={226 + i * 18} width={i % 4 === 3 ? 180 : 250} height={6} fill={C.light} />)}
    {Array.from({length: 9}, (_, i) => <rect key={'b' + i} x={296} y={226 + i * 18} width={i % 3 === 2 ? 150 : 246} height={6} fill={C.light} />)}
  </svg>
);

// ------------------------------------------------------------------ the map
const WARDS = ['RIVERSIDE', 'EASTPORT', 'MILL HILL', 'WESTFIELD', 'GREENPARK', 'DOCKLANDS', 'IRONWORKS', 'OLD TOWN',
  'MARKET SQUARE', 'NORTHGATE', 'SOUTHEND', 'CHAPEL HILL'];
const MX = 110, MY = 150, MW = 1000, MH = 780;
const ward = (i) => {
  const cx = i % 4, cy = Math.floor(i / 4);
  return {x: MX + cx * (MW / 4) + 10, y: MY + cy * (MH / 3) + 10, w: MW / 4 - 20, h: MH / 3 - 20};
};
const CREWS = {1: 'dots', 4: 'bands', 6: 'hatchA', 9: 'check', 10: 'hatchB', 2: 'dots'};
const PRECINCTS = [[0, 0.3, 0.7], [3, 0.6, 0.4], [5, 0.5, 0.5], [7, 0.3, 0.6], [8, 0.7, 0.3], [11, 0.4, 0.5]];
const SHOTS = [[9, 0.62, 0.35, 'SHOTS FIRED · 02:14 · NORTHGATE', 'far_rifle'], [4, 0.3, 0.7, 'SHOTS FIRED · 02:21 · GREENPARK', 'far_pistol'],
  [10, 0.55, 0.6, 'SHOTS FIRED · 02:31 · SOUTHEND', 'far_smg'], [1, 0.7, 0.4, 'SHOTS FIRED · 02:40 · EASTPORT', 'far_shotgun']];

const CityMap = ({f, t0}) => {
  const lf = f - t0;
  const zoom = interpolate(lf, [560, 700], [1, 3.4], {...clamp, easing: (x) => x * x * (3 - 2 * x)});
  const hq = ward(5);
  const hx = hq.x + hq.w * 0.5, hy = hq.y + hq.h * 0.5;
  return (
    <svg width={1920} height={1080} style={{position: 'absolute'}}>
      <defs>
        <Halftone id="dots" step={12} r={2.2} opacity={0.35} />
        <Hatch id="bands" step={14} w={3} opacity={0.22} angle={0} />
        <Hatch id="hatchA" step={9} w={1.4} opacity={0.3} angle={45} />
        <Hatch id="hatchB" step={9} w={1.4} opacity={0.3} angle={-45} />
        <pattern id="check" width={14} height={14} patternUnits="userSpaceOnUse">
          <rect width={7} height={7} fill={C.ink} opacity={0.14} /><rect x={7} y={7} width={7} height={7} fill={C.ink} opacity={0.14} />
        </pattern>
      </defs>
      <g transform={`translate(${hx},${hy}) scale(${zoom}) translate(${-hx},${-hy})`} opacity={interpolate(lf, [640, 700], [1, 0], clamp)}>
        {/* the river cutting the city */}
        <Draw d={`M${MX - 40},${MY + 300} C${MX + 300},${MY + 220} ${MX + 520},${MY + 520} ${MX + MW + 60},${MY + 430}`} a={t0 + 2} b={t0 + 40} width={34} stroke={C.floor} len={2200} />
        {Array.from({length: 12}, (_, i) => {
          const r = ward(i);
          const a = t0 + 10 + i * 5;
          const crew = CREWS[i];
          return (
            <g key={i}>
              <Draw d={`M${r.x},${r.y} h${r.w} v${r.h} h${-r.w} Z`} a={a} b={a + 30} width={3} len={1400} />
              {Array.from({length: 6}, (_, k) => (
                <rect key={k} x={r.x + 18 + (k % 3) * (r.w / 3 - 6)} y={r.y + 70 + Math.floor(k / 3) * 70} width={r.w / 3 - 30} height={48}
                  fill="none" stroke={C.mid} strokeWidth={1.4} opacity={prog(f, a + 20, a + 40)} />
              ))}
              {crew && <rect x={r.x} y={r.y} width={r.w} height={r.h} fill={`url(#${crew})`} opacity={prog(f, t0 + 150 + i * 4, t0 + 175 + i * 4)} />}
              <text x={r.x + r.w / 2} y={r.y + 42} textAnchor="middle" fontFamily={FONT.caps} fontSize={22} letterSpacing={5} fill={C.ink}
                opacity={prog(f, t0 + 50 + i * 6, t0 + 62 + i * 6)}>{WARDS[i]}</text>
            </g>
          );
        })}
        {/* the six precincts */}
        {PRECINCTS.map(([w, px, py], i) => {
          const r = ward(w);
          const o = prog(f, t0 + 330 + i * 6, t0 + 340 + i * 6);
          return (
            <g key={i} opacity={o}>
              <rect x={r.x + r.w * px - 16} y={r.y + r.h * py - 16} width={32} height={32} fill={C.paper} stroke={C.ink} strokeWidth={3} />
              <text x={r.x + r.w * px} y={r.y + r.h * py + 7} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={18} fill={C.ink}>{i === 2 ? 'HQ' : 'P' + (i + 1)}</text>
            </g>
          );
        })}
        {/* gunfire, as the radio hears it */}
        {SHOTS.map(([w, px, py, label], i) => {
          const at = t0 + 380 + i * 42;
          if (f < at) return null;
          const r = ward(w);
          const cx = r.x + r.w * px, cy = r.y + r.h * py;
          const k = ((f - at) % 30) / 30;
          return (
            <g key={i}>
              <circle cx={cx} cy={cy} r={8} fill={C.red} />
              <circle cx={cx} cy={cy} r={10 + k * 40} fill="none" stroke={C.red} strokeWidth={3} opacity={1 - k} />
              <circle cx={cx} cy={cy} r={18} fill="none" stroke={C.red} strokeWidth={1.5} strokeDasharray="4 4" />
              <text x={cx + 26} y={cy - 14} fontFamily={FONT.caps} fontSize={18} letterSpacing={2} fill={C.ink}>{label}</text>
            </g>
          );
        })}
      </g>
    </svg>
  );
};

// ------------------------------------------------------------------ headquarters
const HQ = ({f, t0}) => {
  const lf = f - t0;
  const o = prog(f, t0, t0 + 20);
  const lit = interpolate(lf, [40, 44, 46, 50], [0, 1, 0.4, 1], clamp);
  return (
    <AbsoluteFill style={{opacity: o}}>
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <defs><Hatch id="sky2" step={10} w={1.2} opacity={0.2} angle={60} /></defs>
        <rect width={1920} height={1080} fill={C.mid} />
        <rect width={1920} height={1080} fill="url(#sky2)" />
        <g transform={`translate(0,${interpolate(lf, [0, 230], [30, -10], clamp)})`}>
          <rect x={560} y={210} width={800} height={900} fill={C.ink} />
          <rect x={540} y={190} width={840} height={30} fill={C.ink} />
          {[0, 1, 2, 3].map((row) => Array.from({length: 8}, (_, c) => {
            const isOffice = row === 1 && c === 5;
            return (
              <rect key={row + '-' + c} x={612 + c * 92} y={260 + row * 150} width={50} height={92}
                fill={isOffice ? C.paper : C.dark} opacity={isOffice ? lit : 1} />
            );
          }))}
          <rect x={860} y={880} width={200} height={230} fill={C.dark} />
          <rect x={800} y={830} width={320} height={40} fill={C.paper} />
          <text x={960} y={862} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={32} letterSpacing={10} fill={C.ink}>POLICE</text>
          {[0, 1, 2, 3, 4].map((k) => <rect key={k} x={820 + k * 64} y={1060 - k * 8} width={280 - k * 0} height={8} fill={C.dark} />)}
        </g>
      </svg>
    </AbsoluteFill>
  );
};

export const C1_PortCarrick = () => {
  const f = useCurrentFrame();
  const MAP0 = 470;
  const HQ0 = MAP0 + 640;
  return (
    <AbsoluteFill style={{background: C.paper}}>
      <Bed name="amb_city" volume={0.55} total={C1_LEN} />
      {/* 1. the skyline */}
      {f < 230 && (
        <Paper grid={false}>
          <Skyline f={f} />
          <Rain />
          <Caption at={16} until={226} x={110} y={70} w={980} size={36} text={'PORT CARRICK.\nA RIVER, A RAILWAY, AND A MILL\nTHAT MADE STEEL FOR NINETY YEARS.'} />
        </Paper>
      )}
      {/* 2. three panels */}
      {f >= 210 && f < MAP0 + 10 && (
        <Paper>
          <Panel x={60} y={110} w={590} h={420} at={214} from="left"><MillGate /></Panel>
          <Panel x={670} y={110} w={590} h={420} at={244} from="up"><Street f={f} /></Panel>
          <Panel x={1280} y={110} w={580} h={420} at={274} from="right"><Ledger /></Panel>
          <Caption at={310} until={MAP0 + 6} x={110} y={600} w={1100} size={40} text={'THE MILL IS CLOSING.\nTHE CITY IS NOT.'} />
        </Paper>
      )}
      {/* 3-4. the map: wards, crews, precincts, gunfire */}
      {f >= MAP0 && f < HQ0 + 10 && (
        <Paper>
          <CityMap f={f} t0={MAP0} />
          <Caption at={MAP0 + 40} until={MAP0 + 320} x={1190} y={150} w={650} size={36} text={'TWELVE NEIGHBOURHOODS.\nFOUR CREWS\nWHO WANT THEM.'} />
          <Caption at={MAP0 + 330} until={MAP0 + 600} x={1190} y={150} w={650} size={36} text={'SIX PRECINCTS.\nONE BUDGET THAT\nDOES NOT COVER THEM.'} />
        </Paper>
      )}
      {/* 5. headquarters */}
      {f >= HQ0 && (
        <>
          <HQ f={f} t0={HQ0} />
          <Rain opacity={0.3} />
          <Caption at={HQ0 + 30} until={C1_LEN} x={110} y={70} w={760} size={34}
            text={"PORT CARRICK POLICE DEPARTMENT.\nTHE CHIEF'S OFFICE IS ON\nTHE THIRD FLOOR. IT HAS BEEN\nEMPTY FOR A WEEK."} />
        </>
      )}
      <Fades total={C1_LEN} />
      {/* sound */}
      <Sfx name="toll" at={8} volume={0.7} />
      <Sfx name="kick" at={220} volume={0.4} />
      <Sfx name="kick" at={250} volume={0.4} />
      <Sfx name="stamp" at={280} volume={0.6} />
      <Sfx name="click" at={330} volume={0.5} />
      {SHOTS.map((s, i) => [
        <Sfx key={'r' + i} name="radio" at={MAP0 + 374 + i * 42} volume={0.45} />,
        <Sfx key={'s' + i} name={s[4]} at={MAP0 + 380 + i * 42} volume={0.8} />,
        <Sfx key={'t' + i} name={s[4]} at={MAP0 + 392 + i * 42} volume={0.55} rate={1.05} />,
      ])}
      <Sfx name="door" at={HQ0 + 40} volume={0.5} />
      <Sfx name="toll" at={C1_LEN - 60} volume={0.6} />
    </AbsoluteFill>
  );
};
