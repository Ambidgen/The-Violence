// S14 · THE COURSE. Six seconds at the end of a training week: the certificate, the names
// ticked off, and the two things the course actually changed.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Sheet, Slam, Sfx, Kicker, Meter, RedRule} from './kit.jsx';

const SURNAMES = ['OKAFOR', 'BRENNAN', 'HALVORSEN', 'DIAZ', 'MCRAE', 'ADEYEMI', 'KOVAC', 'PELLETIER', 'VOSS', 'TANAKA', 'WRIGHT', 'ALVAREZ'];

const Seal = ({f}) => {
  const p = prog(f, 96, 108);
  return (
    <g transform="translate(1530,300)" opacity={p}>
      <circle r={86} fill="none" stroke={C.ink} strokeWidth={4} />
      <circle r={72} fill="none" stroke={C.ink} strokeWidth={1.6} strokeDasharray="4 5" />
      <text y={-8} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={18} letterSpacing={2} fill={C.ink}>PCPD</text>
      <text y={18} textAnchor="middle" fontFamily={FONT.caps} fontSize={12} letterSpacing={2} fill={C.dark}>TRAINING</text>
      <text y={38} textAnchor="middle" fontFamily={FONT.caps} fontSize={12} letterSpacing={2} fill={C.dark}>DIVISION</text>
    </g>
  );
};

export const S14_Course = ({course = 'CLOSE-QUARTERS DRILL', graduates = 4, week = 12, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const n = Math.max(1, Math.min(12, graduates));

  return (
    <Scene len={180} note="TRAINING" right="THE WEEK THE ROSTER CHANGED" bed="amb_office" bedVol={0.28} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 90, width: 560}}>DEPARTMENT · WEEK {week}</Kicker>

      {/* the certificate */}
      <Sheet x={170} y={150} w={1180} h={470} at={8} from="down" rot={-0.7} border={5} shadow={14} pad={0}>
        <div style={{position: 'relative', width: '100%', height: '100%', padding: '42px 54px', boxSizing: 'border-box'}}>
          <div style={{border: `2px solid ${C.ink}`, position: 'absolute', left: 22, top: 22, right: 22, bottom: 22, pointerEvents: 'none'}} />
          <div style={{fontFamily: FONT.caps, fontSize: 18, letterSpacing: 9, color: C.mid, textAlign: 'center'}}>
            PORT CARRICK POLICE DEPARTMENT
          </div>
          <div style={{fontFamily: FONT.caps, fontSize: 13, letterSpacing: 7, color: C.mid, textAlign: 'center', marginTop: 8}}>
            TRAINING DIVISION · CERTIFICATE OF COMPLETION
          </div>
          <svg width={1060} height={40} style={{position: 'absolute', left: 54, top: 128}}>
            <line x1={0} y1={20} x2={1060 * prog(f, 26, 54)} y2={20} stroke={C.ink} strokeWidth={2} opacity={0.65} />
          </svg>
          <div style={{marginTop: 74, textAlign: 'center', fontFamily: FONT.caps, fontWeight: 600, fontSize: 58, letterSpacing: 3, color: C.ink,
            opacity: prog(f, 32, 46)}}>
            {String(course).toUpperCase()}
          </div>
          <div style={{marginTop: 16, textAlign: 'center', fontFamily: FONT.type, fontSize: 23, color: C.dark, opacity: prog(f, 40, 54)}}>
            {n} officer{n === 1 ? '' : 's'} completed the course. The roster reflects it from Monday.
          </div>

          <div style={{position: 'absolute', left: 54, bottom: 42, fontFamily: FONT.type, fontSize: 19, color: C.mid, opacity: prog(f, 60, 74)}}>
            SIGNED · THE CHIEF OF POLICE
          </div>
          <div style={{position: 'absolute', right: 54, bottom: 42, fontFamily: FONT.type, fontSize: 19, color: C.mid, opacity: prog(f, 60, 74)}}>
            WEEK {week}
          </div>
        </div>
      </Sheet>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <Seal f={f} />

        {/* the roster, ticked off one at a time */}
        <g opacity={prog(f, 60, 74)}>
          <text x={1420} y={436} fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.mid}>ATTENDANCE</text>
          {Array.from({length: n}, (_, i) => {
            const at = 66 + i * 8;
            const nm = SURNAMES[i % SURNAMES.length];
            return (
              <g key={i} opacity={prog(f, at, at + 6)}>
                <text x={1420} y={472 + i * 40} fontFamily={FONT.type} fontSize={21} fill={C.ink}>{nm}</text>
                <path d={`M1746,${466 + i * 40} l7,8 l14,-18`} fill="none" stroke={C.ink} strokeWidth={3}
                  strokeDasharray="40" strokeDashoffset={40 * (1 - prog(f, at + 3, at + 9))} />
              </g>
            );
          })}
        </g>

        {/* the two things the course moved */}
        <g opacity={prog(f, 120, 134)}>
          <text x={170} y={790} fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.mid}>WHAT CHANGED</text>
          {[['RECOGNITION', 74], ['NERVE', 61]].map(([k, v], i) => (
            <g key={k}>
              <text x={170} y={828 + i * 64} fontFamily={FONT.caps} fontSize={22} letterSpacing={2} fill={C.ink}>{k}</text>
              <Meter x={400} y={806 + i * 64} w={560} h={24} value={v} of={100} at={124 + i * 8} dur={22} ticks={4} />
              <text x={980} y={828 + i * 64} fontFamily={FONT.caps} fontSize={22} fill={C.dark}>+{i === 0 ? 6 : 4}</text>
            </g>
          ))}
          <RedRule x={170} y={930} w={0} at={0} />
        </g>
      </svg>

      <At at={52} from="none" style={{left: 170, top: 664, width: 1180}}>
        <div style={{fontFamily: FONT.caps, fontSize: 18, letterSpacing: 6, color: C.mid}}>
          WHAT A COURSE CHANGES IS WHAT AN OFFICER DOES BEFORE HE DECIDES
        </div>
      </At>
      <Slam lines={['CERTIFIED', `${n} OFFICER${n === 1 ? '' : 'S'}`]} at={100} x={1390} y={722} rot={-6} size={26} vol={0.6} />
      <Sfx name="door" at={8} volume={0.4} />
      {Array.from({length: 4}, (_, i) => <Sfx key={i} name="click" at={66 + i * 8} volume={0.25} />)}
      <Sfx name="stamp" at={100} volume={0.65} />
      <Sfx name="toll" at={158} volume={0.35} />
    </Scene>
  );
};
