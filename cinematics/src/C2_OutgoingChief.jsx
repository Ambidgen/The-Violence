// Cutscene 2: THE OUTGOING CHIEF. The desk from above, the note he left, what you inherit,
// and the phone.
import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, clamp, prog, Paper, Panel, Caption, Stamp, Draw, Fades, Sfx, Bed, Hatch, typed} from './ink.jsx';

export const C2_LEN = 1230;

const NOTE = [
  'The Bridge Street briefing was mine. The eviction order was yours to sign.',
  'You will not answer everything. Pick what matters.',
  'A hostage call or a crew house left alone comes back. A quiet warrant can wait.',
  'Send four through a door. Plates and a helmet for anyone going in.',
  'The press may find what you clear. The union remembers discipline. Forty weeks to the election.',
];
const NOTE0 = 300;
const CPS = 46;
// when each line starts typing, in frames
const LINE_AT = (() => {
  const out = [];
  let t = NOTE0 + 40;
  for (const l of NOTE) {
    out.push(t);
    t += Math.ceil((l.length / CPS) * 30) + 16;
  }
  return out;
})();

// ------------------------------------------------------------------ the desk, from above
const Desk = ({f, ring}) => {
  const z = interpolate(f, [0, 300], [1.0, 1.12], clamp);
  const shake = ring ? Math.sin(f * 2.3) * 3 : 0;
  return (
    <svg width={1920} height={1080} style={{position: 'absolute'}}>
      <defs>
        <Hatch id="wood" step={12} w={1} opacity={0.12} angle={0} />
        <radialGradient id="lamp">
          <stop offset="0%" stopColor={C.paper} stopOpacity={0.95} />
          <stop offset="100%" stopColor={C.paper} stopOpacity={0} />
        </radialGradient>
      </defs>
      <g transform={`translate(960,540) scale(${z}) translate(-960,-540)`}>
        {/* the floor, darker than the desk */}
        <rect width={1920} height={1080} fill={C.floor} />
        {/* the chair */}
        <Draw d="M900,930 a70,70 0 1,0 140,0 a70,70 0 1,0 -140,0" a={10} b={40} width={5} fill={C.dark} fillAt={40} len={500} />
        <Draw d="M890,860 h160 v30 h-160 Z" a={14} b={40} width={5} fill={C.ink} fillAt={40} len={500} />
        {/* the desk */}
        <Draw d="M330,230 h1260 v600 h-1260 Z" a={0} b={50} width={7} fill={C.light} fillAt={44} len={4000} />
        <rect x={330} y={230} width={1260} height={600} fill="url(#wood)" opacity={prog(f, 44, 60)} />
        {/* the lamp's light */}
        <circle cx={520} cy={380} r={260} fill="url(#lamp)" opacity={prog(f, 50, 80)} />
        <Draw d="M470,380 a50,50 0 1,0 100,0 a50,50 0 1,0 -100,0" a={30} b={60} width={5} fill={C.dark} fillAt={60} len={400} />
        {/* the box of files */}
        <g opacity={prog(f, 60, 80)}>
          <rect x={1180} y={290} width={330} height={250} fill={C.paper} stroke={C.ink} strokeWidth={5} transform="rotate(6 1345 415)" />
          {['INTERNAL AFFAIRS', 'PAYROLL', 'BUDGET 2026', 'CANAL ST.'].map((t, i) => (
            <g key={t} transform={`rotate(6 1345 415) translate(${1196 + i * 4},${304 + i * 52})`}>
              <rect width={298} height={44} fill={i % 2 ? C.floor : C.paper} stroke={C.ink} strokeWidth={2} />
              <text x={14} y={30} fontFamily={FONT.caps} fontSize={22} letterSpacing={3} fill={C.ink}>{t}</text>
            </g>
          ))}
        </g>
        {/* coffee rings: the last chief's mornings */}
        {[[760, 330, 36], [800, 360, 36], [1080, 700, 38]].map(([x, y, r], i) => (
          <circle key={i} cx={x} cy={y} r={r} fill="none" stroke={C.mid} strokeWidth={4} opacity={0.4 * prog(f, 70, 90)} />
        ))}
        {/* the phone */}
        <g transform={`translate(${shake},0)`} opacity={prog(f, 80, 100)}>
          <rect x={1180} y={600} width={220} height={170} rx={24} fill={C.ink} />
          <rect x={1190} y={588} width={200} height={50} rx={22} fill={C.dark} stroke={C.ink} strokeWidth={4}
            transform={ring ? `rotate(${Math.sin(f * 2.1) * 4} 1290 612)` : ''} />
          {Array.from({length: 12}, (_, k) => <circle key={k} cx={1230 + (k % 4) * 46} cy={668 + Math.floor(k / 4) * 32} r={10} fill={C.paper} />)}
          <path d="M1290,770 C1300,820 1240,840 1180,830" stroke={C.ink} strokeWidth={5} fill="none" />
        </g>
        {ring && [0, 1, 2].map((k) => {
          const r = 130 + ((f * 4 + k * 40) % 120);
          return <circle key={k} cx={1290} cy={680} r={r} fill="none" stroke={C.ink} strokeWidth={3} opacity={(1 - (r - 130) / 120) * 0.6} />;
        })}
        {/* the nameplate, turned face down */}
        <g opacity={prog(f, 90, 110)}>
          <rect x={700} y={700} width={300} height={70} fill={C.dark} stroke={C.ink} strokeWidth={4} transform="rotate(-8 850 735)" />
          <text x={850} y={745} textAnchor="middle" fontFamily={FONT.caps} fontSize={24} letterSpacing={4} fill={C.mid} transform="rotate(-8 850 735)">OFFICE OF THE CHIEF</text>
        </g>
      </g>
    </svg>
  );
};

// ------------------------------------------------------------------ the note
const Note = ({f}) => {
  const s = prog(f, NOTE0, NOTE0 + 22);
  return (
    <div style={{position: 'absolute', left: 300, top: 120 + (1 - s) * 80, width: 1320, opacity: s, transform: `rotate(${-1.2 * s}deg)`,
      background: C.paper, border: `5px solid ${C.ink}`, padding: '44px 60px 40px', boxShadow: '12px 12px 0 rgba(18,18,18,0.25)'}}>
      <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 30, letterSpacing: 8, color: C.ink, marginBottom: 26}}>FROM THE OUTGOING CHIEF</div>
      {NOTE.map((l, i) => (
        <div key={i} style={{fontFamily: FONT.type, fontSize: 32, lineHeight: 1.4, color: C.ink, marginBottom: 14, minHeight: 44}}>
          {f >= LINE_AT[i] ? '· ' + typed(l, f, LINE_AT[i], CPS) : ''}
        </div>
      ))}
      <div style={{fontFamily: FONT.type, fontSize: 30, color: C.dark, marginTop: 18, opacity: prog(f, LINE_AT[4] + 100, LINE_AT[4] + 116)}}>
        Good luck. You will need less of it than money.
      </div>
    </div>
  );
};

// ------------------------------------------------------------------ what you inherit
const Badge = () => (
  <svg width={556} height={396}>
    <rect width={556} height={396} fill={C.light} />
    <rect width={556} height={396} fill="url(#wood2)" />
    <defs><Hatch id="wood2" step={12} w={1} opacity={0.12} angle={0} /></defs>
    <g transform="translate(278,200)">
      <path d="M0,-150 L110,-110 L100,40 Q60,120 0,150 Q-60,120 -100,40 L-110,-110 Z" fill={C.ink} />
      <path d="M0,-126 L88,-94 L80,34 Q48,100 0,124 Q-48,100 -80,34 L-88,-94 Z" fill={C.dark} stroke={C.paper} strokeWidth={3} />
      <polygon points="0,-70 16,-22 66,-22 26,8 42,56 0,26 -42,56 -26,8 -66,-22 -16,-22" fill={C.paper} />
      <text x={0} y={96} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={26} letterSpacing={6} fill={C.paper}>PCPD</text>
    </g>
  </svg>
);

const Sheet = ({title, rows}) => (
  <div style={{width: '100%', height: '100%', background: C.paper, padding: '26px 30px', boxSizing: 'border-box'}}>
    <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 30, letterSpacing: 5, color: C.ink, borderBottom: `3px solid ${C.ink}`, paddingBottom: 8, marginBottom: 16}}>{title}</div>
    {rows.map(([a, b], i) => (
      <div key={i} style={{display: 'flex', justifyContent: 'space-between', fontFamily: FONT.type, fontSize: 25, color: C.ink, lineHeight: 1.65,
        borderBottom: `1px dotted ${C.mid}`}}>
        <span>{a}</span><span>{b}</span>
      </div>
    ))}
  </div>
);

export const C2_OutgoingChief = () => {
  const f = useCurrentFrame();
  const P0 = LINE_AT[4] + 160;          // the inheritance panels
  const R0 = P0 + 250;                  // the phone
  const clicks = [];
  NOTE.forEach((l, i) => {
    const n = Math.ceil((l.length / CPS) * 30);
    for (let k = 0; k < n; k += 4) clicks.push(<Sfx key={i + '-' + k} name="click" at={LINE_AT[i] + k} volume={0.22 + ((k * 7) % 5) * 0.03} rate={0.9 + ((k * 13) % 7) * 0.03} />);
  });
  return (
    <AbsoluteFill style={{background: C.paper}}>
      <Bed name="amb_office" volume={0.6} total={C2_LEN} />
      {(f < P0 + 10 || f >= R0) && <Desk f={f >= R0 ? f - R0 + 300 : f} ring={f >= R0 + 30} />}
      {f < NOTE0 + 20 && (
        <Caption at={20} until={NOTE0 + 16} x={110} y={70} w={860} size={36} text={'THE LAST CHIEF LEFT THE DESK.\nTHE SIGNATURE DID NOT.'} />
      )}
      {f >= NOTE0 && f < P0 + 10 && <Note f={f} />}
      {f >= P0 && f < R0 + 10 && (
        <Paper>
          <Panel x={60} y={110} w={570} h={410} at={P0 + 4} from="left"><Badge /></Panel>
          <Panel x={675} y={110} w={570} h={410} at={P0 + 30} from="up">
            <Sheet title="ROSTER · WEEK 1" rows={[['Officers fit', '20'], ['Out injured', '0'], ['Lieutenants', '1'], ['Sergeants', '2'], ['Morale', '60']]} />
          </Panel>
          <Panel x={1290} y={110} w={570} h={410} at={P0 + 56} from="right">
            <Sheet title="BUDGET · WEEK 1" rows={[['Account', '$25,000'], ['Allocation', '$30,500 /wk'], ['Payroll', '$26,264 /wk'], ['Open IA cases', '2'], ['Body cameras', 'not issued']]} />
          </Panel>
          <Caption at={P0 + 80} until={R0 + 6} x={110} y={600} w={1300} size={38}
            text={'TWENTY OFFICERS. TWENTY-FIVE THOUSAND DOLLARS.\nTWO CASES ALREADY OPEN.'} />
          <Stamp lines={['INHERITED', 'AS FOUND']} at={P0 + 150} x={1380} y={760} rot={-6} color={C.ink} size={38} />
        </Paper>
      )}
      {f >= R0 && (
        <Caption at={R0 + 40} until={C2_LEN} x={110} y={70} w={860} size={36} text={'THE PHONE HAS NOT\nSTOPPED RINGING.'} />
      )}
      {f >= R0 + 150 && <Stamp lines={['WEEK 1', 'OF 40']} at={R0 + 150} x={160} y={800} rot={-5} size={46} />}
      <Fades total={C2_LEN} />
      <Sfx name="door" at={6} volume={0.5} />
      <Sfx name="click" at={NOTE0 + 4} volume={0.5} />
      {clicks}
      <Sfx name="kick" at={P0 + 8} volume={0.35} />
      <Sfx name="kick" at={P0 + 34} volume={0.35} />
      <Sfx name="kick" at={P0 + 60} volume={0.35} />
      <Sfx name="stamp" at={P0 + 150} volume={0.7} />
      <Sfx name="phone" at={R0 + 30} volume={0.55} />
      <Sfx name="phone" at={R0 + 96} volume={0.55} />
      <Sfx name="stamp" at={R0 + 150} volume={0.7} />
      <Sfx name="phone" at={R0 + 162} volume={0.45} />
    </AbsoluteFill>
  );
};
