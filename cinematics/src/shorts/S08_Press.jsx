// S08 · THE FRONT PAGE. Eight seconds at the end of a week: the Ledger lands on the desk,
// sets its headline, and gives the week a verdict in one deck line.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Slam, Sfx, Halftone} from './kit.jsx';
import {Silhouette as Sil} from '../ink.jsx';

const headSize = (t) => {
  const n = String(t).length;
  if (n <= 16) return 116;
  if (n <= 24) return 96;
  if (n <= 34) return 80;
  if (n <= 46) return 66;
  return 54;
};

const Photo = ({f, bad}) => (
  <svg width={520} height={330}>
    <defs>
      <Halftone id="led" step={8} r={1.9} opacity={0.42} />
      <pattern id="sky" width={10} height={10} patternUnits="userSpaceOnUse" patternTransform="rotate(65)">
        <line x1={0} y1={0} x2={0} y2={10} stroke={C.ink} strokeWidth={1.1} opacity={0.14} />
      </pattern>
    </defs>
    <rect width={520} height={330} fill={C.light} />
    <rect width={520} height={330} fill="url(#led)" />
    <rect width={520} height={330} fill="url(#sky)" />
    {/* the tape line, the curb, the two figures */}
    <rect x={0} y={252} width={520} height={78} fill={C.ink} opacity={0.88} />
    {Array.from({length: 9}, (_, i) => <rect key={i} x={i * 62} y={248} width={42} height={10} fill={C.paper} opacity={0.6} />)}
    <Sil x={190} y={262} h={186} coat hat />
    <Sil x={300} y={266} h={172} coat flip />
    {bad ? <rect x={0} y={0} width={520} height={330} fill={C.ink} opacity={0.1} /> : null}
    <rect x={0} y={0} width={520} height={330} fill="none" stroke={C.ink} strokeWidth={4} />
  </svg>
);

export const S08_Press = ({headline = '', deck = '', week = 12, tone = 'neutral', price = '50 CENTS', showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const bad = tone === 'bad';
  const good = tone === 'good';
  const size = headSize(headline);

  return (
    <Scene len={240} note="THE PRESS" right="PRINTED WHATEVER IT CAN PROVE" bed="amb_office" bedVol={0.3} showSlots={showSlots} slots={slots}>
      {/* the sheet lands */}
      <div style={{position: 'absolute', left: 210, top: 66, width: 1500, height: 940,
        transform: `translate(0, ${(1 - prog(f, 4, 22)) * -60}px) rotate(${-2 + prog(f, 4, 24) * 1.4}deg)`,
        opacity: prog(f, 4, 14), background: C.paper, border: `7px solid ${C.ink}`, boxSizing: 'border-box',
        boxShadow: '16px 18px 0 rgba(18,18,18,0.18)', padding: '34px 44px'}}>
        {/* masthead */}
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 92, letterSpacing: 14, textAlign: 'center', lineHeight: 1, color: C.ink}}>
          THE CARRICK LEDGER
        </div>
        <div style={{borderTop: `4px solid ${C.ink}`, borderBottom: `1.5px solid ${C.ink}`, margin: '12px 0 0', padding: '7px 0',
          display: 'flex', justifyContent: 'space-between', fontFamily: FONT.caps, fontSize: 19, letterSpacing: 4, color: C.dark}}>
          <span>WEEK {week}</span>
          <span>PORT CARRICK, ONTARIO</span>
          <span>{price}</span>
        </div>

        <At at={22} from="none" style={{left: 44, top: 232, width: 1420}}>
          <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: size, lineHeight: 1.0, letterSpacing: 1, color: C.ink,
            textTransform: 'uppercase'}}>
            {headline}
          </div>
        </At>

        {bad ? (
          <div style={{position: 'absolute', left: 44, top: 396, height: 7, width: 1120, background: C.red, transformOrigin: 'left center',
            transform: `scaleX(${prog(f, 44, 62)})`, opacity: prog(f, 44, 50)}} />
        ) : null}

        <At at={34} from="none" style={{left: 44, top: 420, width: 1420}}>
          <div style={{fontFamily: FONT.type, fontSize: 30, lineHeight: 1.35, color: C.dark, maxWidth: 1380}}>{deck}</div>
        </At>

        <div style={{position: 'absolute', left: 44, top: 530, opacity: prog(f, 40, 56)}}>
          <Photo f={f} bad={bad} />
          <div style={{fontFamily: FONT.type, fontSize: 17, color: C.mid, marginTop: 6}}>
            {good ? 'The scene on Foundry Street, the morning after.' : 'The scene on Foundry Street. Nobody has been charged.'}
          </div>
        </div>

        {/* two columns of the story nobody will read to the end */}
        <div style={{position: 'absolute', left: 604, top: 530, width: 380}}>
          {Array.from({length: 14}, (_, i) => (
            <div key={i} style={{height: 8, background: C.light, marginBottom: 11, width: i % 5 === 4 ? '64%' : '100%',
              opacity: prog(f, 46 + i * 2, 52 + i * 2)}} />
          ))}
        </div>
        <div style={{position: 'absolute', left: 1014, top: 530, width: 380}}>
          {Array.from({length: 14}, (_, i) => (
            <div key={i} style={{height: 8, background: C.light, marginBottom: 11, width: i % 4 === 3 ? '72%' : '100%',
              opacity: prog(f, 50 + i * 2, 56 + i * 2)}} />
          ))}
          {/* the box the editor runs when the week went badly */}
          {bad ? (
            <div style={{marginTop: 18, border: `3px solid ${C.ink}`, padding: '10px 12px', fontFamily: FONT.caps,
              fontSize: 17, letterSpacing: 2, lineHeight: 1.5, opacity: prog(f, 84, 96)}}>
              THE DEPARTMENT DECLINED TO COMMENT.<br />THE COALITION DID NOT.
            </div>
          ) : null}
        </div>

        {/* the fold */}
        <div style={{position: 'absolute', left: 0, top: 512, width: 1500, height: 2, background: C.paper, boxShadow: `0 -1px 0 rgba(18,18,18,0.22)`}} />
      </div>

      <Slam lines={['THE WEEK', 'IN PRINT']} at={104} x={1130} y={812} rot={-5} size={26} color={bad ? C.red : C.ink} vol={0.6} />
      <Sfx name="kick" at={6} volume={0.55} />
      <Sfx name="click" at={22} volume={0.4} />
      <Sfx name="radio" at={96} volume={0.35} />
      <Sfx name="stamp" at={104} volume={0.6} />
      <Sfx name="toll" at={214} volume={0.4} />
    </Scene>
  );
};
