// Cutscene 4: FORTY WEEKS. The calendar, the three candidates, the four allies, the first
// front page, and the title.
import React from 'react';
import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {C, FONT, clamp, prog, Paper, Panel, Caption, Stamp, Draw, Fades, Sfx, Bed, Silhouette, Halftone} from './ink.jsx';

export const C4_LEN = 1170;

const CANDIDATES = [
  ['ROYCE KETTERING', 'SAFE STREETS', 'A councilman who asks for more police, a bigger budget, fewer questions. His brother-in-law builds armoured vehicles.', 34],
  ['DANA OKONJO-VALE', 'CARRICK TOGETHER', 'She wants to repair the city. She has not forgiven your signature on the Bridge Street eviction order.', 31],
  ['GORDON PELL', 'INDEPENDENT', 'Tireless, difficult to hurry. His answer to a failed review is another review, with a better filing system.', 35],
];
const ALLIES = [
  ['MARGUERITE DUFF', 'Councillor, chair of the budget committee', 55, 'Holds the weekly allocation.'],
  ['TOMMY ROURKE', 'President, Police Benevolent Association', 60, "Holds the officers' goodwill."],
  ['REV. ALMA MBEKI-SHAW', 'Carrick Community Coalition', 45, "Holds the community groups' tips."],
  ['PAUL VARGA', 'District Attorney', 55, 'Holds the benefit of the doubt.'],
];

const Calendar = ({f}) => {
  // forty weeks flicker past, then the calendar goes back to the first
  const run = interpolate(f, [60, 170], [0, 40], clamp);
  const reset = f >= 190;
  return (
    <svg width={1920} height={1080} style={{position: 'absolute'}}>
      {Array.from({length: 40}, (_, i) => {
        const x = 260 + (i % 10) * 142, y = 300 + Math.floor(i / 10) * 142;
        const crossed = !reset && i < run;
        return (
          <g key={i} opacity={prog(f, 4 + i * 1.2, 14 + i * 1.2)}>
            <rect x={x} y={y} width={124} height={124} fill={C.paper} stroke={C.ink} strokeWidth={3} />
            <text x={x + 12} y={y + 34} fontFamily={FONT.caps} fontSize={26} fill={C.ink}>{i + 1}</text>
            {crossed && <path d={`M${x + 18},${y + 18} L${x + 106},${y + 106} M${x + 106},${y + 18} L${x + 18},${y + 106}`} stroke={C.ink} strokeWidth={4} opacity={0.75} />}
            {i === 39 && <text x={x + 62} y={y + 90} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={20} letterSpacing={2} fill={C.ink}>ELECTION</text>}
          </g>
        );
      })}
      {reset && <Draw d="M322,362 m-70,0 a70,64 0 1,0 140,0 a70,64 0 1,0 -140,0" a={194} b={214} width={6} stroke={C.red} len={600} />}
    </svg>
  );
};

const Poster = ({c, i}) => (
  <svg width={556} height={606}>
    <defs><Halftone id={'ph' + i} step={10} r={2.4} opacity={0.3} /></defs>
    <rect width={556} height={606} fill={C.light} />
    <rect width={556} height={420} fill={`url(#ph${i})`} />
    <Silhouette x={278} y={430} h={[380, 360, 390][i]} coat fill={C.ink} />
    <rect x={0} y={420} width={556} height={186} fill={C.paper} />
    <text x={278} y={474} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={40} letterSpacing={3} fill={C.ink}>{c[0]}</text>
    <text x={278} y={512} textAnchor="middle" fontFamily={FONT.caps} fontSize={26} letterSpacing={8} fill={C.dark}>{c[1]}</text>
    <foreignObject x={30} y={526} width={496} height={80}>
      <div style={{fontFamily: FONT.type, fontSize: 19, color: C.dark, textAlign: 'center', lineHeight: 1.3}}>{c[2]}</div>
    </foreignObject>
  </svg>
);

export const C4_FortyWeeks = () => {
  const f = useCurrentFrame();
  const P0 = 250, A0 = 590, N0 = 850, T0 = 1000;
  return (
    <AbsoluteFill style={{background: C.paper}}>
      <Bed name="amb_office" volume={0.55} total={C4_LEN} />
      {f < P0 + 10 && (
        <Paper>
          <Calendar f={f} />
          <Caption at={14} until={P0 + 4} x={110} y={70} w={900} size={38} text={'FORTY WEEKS\nTO THE ELECTION.'} />
          {f >= 196 && <Stamp lines={['WEEK 1']} at={214} x={1440} y={110} rot={-5} size={48} />}
        </Paper>
      )}
      {f >= P0 && f < A0 + 10 && (
        <Paper>
          {CANDIDATES.map((c, i) => (
            <Panel key={i} x={70 + i * 600} y={70} w={570} h={620} at={P0 + 4 + i * 26} from={['left', 'up', 'right'][i]}><Poster c={c} i={i} /></Panel>
          ))}
          {/* the opening polls */}
          <svg width={1920} height={1080} style={{position: 'absolute'}}>
            {CANDIDATES.map((c, i) => {
              const w = interpolate(f, [P0 + 100, P0 + 150], [0, c[3] * 12], clamp);
              return (
                <g key={i} opacity={prog(f, P0 + 96, P0 + 106)}>
                  <rect x={90 + i * 600} y={712} width={444} height={30} fill="none" stroke={C.ink} strokeWidth={2.5} />
                  <rect x={90 + i * 600} y={712} width={w} height={30} fill={C.ink} />
                  <text x={546 + i * 600} y={737} fontFamily={FONT.caps} fontWeight={600} fontSize={26} fill={C.ink}>{Math.round(w / 12)}%</text>
                </g>
              );
            })}
          </svg>
          <Caption at={P0 + 140} until={A0 + 6} x={110} y={790} w={1400} size={36}
            text={'THREE CANDIDATES FOR MAYOR.\nONLY ONE DECIDES WHETHER YOU STAY.'} red="STAY" />
        </Paper>
      )}
      {f >= A0 && f < N0 + 10 && (
        <Paper>
          {ALLIES.map((a, i) => {
            const at = A0 + 6 + i * 18;
            const w = interpolate(f, [at + 20, at + 60], [0, a[2] * 9], clamp);
            return (
              <Panel key={i} x={120} y={90 + i * 160} w={1180} h={140} at={at} from="left">
                <div style={{padding: '14px 24px', fontFamily: FONT.caps, color: C.ink}}>
                  <div style={{fontSize: 34, fontWeight: 600, letterSpacing: 3}}>{a[0]} <span style={{fontWeight: 400, fontSize: 24, letterSpacing: 1, color: C.dark}}>· {a[1]}</span></div>
                  <div style={{position: 'relative', marginTop: 12, width: 900, height: 26, border: `2.5px solid ${C.ink}`}}>
                    <div style={{width: w, height: '100%', background: C.ink}} />
                    {/* below the red line an ally is lost, and what they hold goes with them */}
                    <div style={{position: 'absolute', left: 25 * 9, top: -8, width: 4, height: 42, background: C.red}} />
                  </div>
                  <div style={{position: 'absolute', right: 26, top: 20, fontFamily: FONT.type, fontSize: 22, color: C.dark, width: 230, textAlign: 'right'}}>{a[3]}</div>
                </div>
              </Panel>
            );
          })}
          <Caption at={A0 + 100} until={N0 + 6} x={1340} y={260} w={520} size={34}
            text={'FOUR PEOPLE WHO CAN\nMAKE YOUR WEEK EASIER.\n\nFOR NOW.'} />
        </Paper>
      )}
      {f >= N0 && f < T0 + 10 && (
        <Paper>
          {(() => {
            const s = interpolate(f, [N0, N0 + 14], [0, 1], clamp);
            const rot = interpolate(f, [N0, N0 + 14], [-26, -3], clamp);
            return (
              <div style={{position: 'absolute', left: 300, top: 140, width: 1320, height: 800, background: C.paper, border: `6px solid ${C.ink}`,
                transform: `scale(${0.3 + 0.7 * s}) rotate(${rot}deg)`, opacity: s, boxShadow: '14px 14px 0 rgba(18,18,18,0.25)', padding: '30px 50px', boxSizing: 'border-box'}}>
                <div style={{fontFamily: FONT.caps, fontSize: 58, letterSpacing: 18, textAlign: 'center', color: C.ink}}>THE CARRICK LEDGER</div>
                <div style={{borderTop: `4px solid ${C.ink}`, borderBottom: `1px solid ${C.ink}`, height: 4, margin: '10px 0 6px'}} />
                <div style={{fontFamily: FONT.caps, fontSize: 24, letterSpacing: 4, color: C.dark, display: 'flex', justifyContent: 'space-between'}}><span>WEEK 1</span><span>PORT CARRICK</span><span>50 CENTS</span></div>
                <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 92, lineHeight: 1.05, color: C.ink, marginTop: 30}}>NEW CHIEF INHERITS BRIDGE STREET FILE</div>
                <div style={{fontFamily: FONT.type, fontSize: 32, color: C.dark, marginTop: 24, lineHeight: 1.35}}>
                  The deputy chief signed the eviction order. His predecessor gave the briefing. The election is forty weeks away.
                </div>
                <div style={{display: 'flex', gap: 30, marginTop: 30}}>
                  {[0, 1, 2].map((k) => <div key={k} style={{flex: 1}}>{Array.from({length: 6}, (_, j) => <div key={j} style={{height: 8, background: C.light, marginBottom: 12, width: j === 5 ? '60%' : '100%'}} />)}</div>)}
                </div>
              </div>
            );
          })()}
        </Paper>
      )}
      {f >= T0 && (
        <Paper>
          <div style={{position: 'absolute', left: 0, width: 1920, top: 330, textAlign: 'center', fontFamily: FONT.body, fontSize: 28, letterSpacing: 2,
            color: C.mid, opacity: prog(f, T0 + 6, T0 + 20)}}>PORT CARRICK POLICE DEPARTMENT · OFFICE OF THE CHIEF</div>
          <div style={{position: 'absolute', left: 0, width: 1920, top: 380, textAlign: 'center', fontFamily: FONT.body, fontWeight: 600, fontSize: 150,
            letterSpacing: 34, color: C.ink, opacity: prog(f, T0 + 10, T0 + 30)}}>THE VIOLENCE</div>
          <svg width={1920} height={1080} style={{position: 'absolute'}}>
            <Draw d="M300,600 H1640" a={T0 + 24} b={T0 + 60} width={12} stroke={C.red} cap="butt" len={1400} />
          </svg>
          <div style={{position: 'absolute', left: 0, width: 1920, top: 640, textAlign: 'center', fontFamily: FONT.body, fontSize: 40, color: C.dark,
            opacity: prog(f, T0 + 50, T0 + 70)}}>Every operation is a plan until it meets a room.</div>
        </Paper>
      )}
      <Fades total={C4_LEN} outF={24} />
      <Sfx name="click" at={10} volume={0.4} />
      {Array.from({length: 20}, (_, k) => <Sfx key={k} name="click" at={60 + k * 5.5} volume={0.25} rate={0.9 + (k % 5) * 0.05} />)}
      <Sfx name="stamp" at={214} volume={0.75} />
      {[0, 1, 2].map((i) => <Sfx key={'p' + i} name="kick" at={P0 + 8 + i * 26} volume={0.35} />)}
      {[0, 1, 2, 3].map((i) => <Sfx key={'a' + i} name="click" at={A0 + 10 + i * 18} volume={0.45} />)}
      <Sfx name="radio" at={A0 + 100} volume={0.4} />
      <Sfx name="ram" at={N0 + 10} volume={0.6} />
      <Sfx name="stamp" at={N0 + 14} volume={0.6} />
      <Sfx name="toll" at={T0 + 24} volume={0.8} />
    </AbsoluteFill>
  );
};
