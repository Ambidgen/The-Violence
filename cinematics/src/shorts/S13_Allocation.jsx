// S13 · THE ALLOCATION. Six seconds of the city's money: the week's figure counted onto the
// ledger, the delta, and the committee's stamp.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, At, Scene, Slam, Sfx, Kicker, Rule, Meter} from './kit.jsx';

const money = (n) => `$${Math.round(n).toLocaleString('en-US')}`;

const ITEMS = [
  ['PATROL PAYROLL', 0.52],
  ['KIT AND PLATES', 0.18],
  ['TRAINING', 0.09],
  ['HOSPITAL AND RECOVERY', 0.07],
  ['THE CASES', 0.14],
];

export const S13_Allocation = ({amount = 28400, delta = -8, verdict = 'CUT', week = 12, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const down = delta < 0;
  const count = amount * prog(f, 34, 96);
  const tone = verdict === 'CUT' ? C.red : C.ink;

  return (
    <Scene len={180} note="THE ACCOUNT" right="THE COUNCIL'S WEEKLY ALLOCATION" bed="amb_office" bedVol={0.28} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 92, width: 640}}>WEEK {week} · BUDGET COMMITTEE</Kicker>
      <At at={10} from="left" style={{left: 96, top: 136, width: 820}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 58, letterSpacing: 3, color: C.ink}}>THE ALLOCATION</div>
      </At>

      <At at={18} from="none" style={{left: 96, top: 216, width: 900}}>
        <div style={{fontFamily: FONT.caps, fontSize: 17, letterSpacing: 6, color: C.mid}}>ALLOCATED THIS WEEK</div>
      </At>
      <At at={26} from="none" style={{left: 90, top: 246, width: 1000}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 172, lineHeight: 1, letterSpacing: 2, color: C.ink}}>
          {money(count)}
        </div>
      </At>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <Rule x={96} y={430} w={1728} at={30} h={3} opacity={0.7} />

        {/* the delta, as an arrow and a number */}
        <g opacity={prog(f, 104, 118)}>
          <text x={96} y={492} fontFamily={FONT.caps} fontSize={17} letterSpacing={6} fill={C.mid}>AGAINST LAST WEEK</text>
          <g transform="translate(420,478)">
            <path d={down ? 'M0,16 L-24,-12 L24,-12 Z' : 'M0,-16 L-24,12 L24,12 Z'} fill={down ? C.red : C.ink} />
          </g>
          <text x={464} y={492} fontFamily={FONT.caps} fontWeight={600} fontSize={48} fill={down ? C.red : C.ink}>
            {down ? '−' : '+'}{Math.abs(Math.round(delta))}%
          </text>
        </g>

        {/* where it goes */}
        <g opacity={prog(f, 60, 72)}>
          <text x={96} y={566} fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.mid}>WHERE IT GOES</text>
          {ITEMS.map(([k, share], i) => (
            <g key={k} opacity={prog(f, 66 + i * 8, 76 + i * 8)}>
              <text x={96} y={608 + i * 56} fontFamily={FONT.type} fontSize={22} fill={C.dark}>{k}</text>
              <rect x={520} y={590 + i * 56} width={760} height={22} fill={C.paper} stroke={C.ink} strokeWidth={2} />
              <rect x={520} y={590 + i * 56} width={760 * share * prog(f, 70 + i * 8, 92 + i * 8)} height={22} fill={C.ink} />
              <text x={1310} y={610 + i * 56} fontFamily={FONT.caps} fontSize={22} fill={C.ink}>{Math.round(share * 100)}%</text>
            </g>
          ))}
        </g>

        {/* the ledger's own line */}
        <text x={96} y={948} fontFamily={FONT.type} fontSize={24} fill={C.dark} opacity={prog(f, 128, 140)}>
          {down ? 'The shortfall is met by not replacing two posts.' : 'The committee finds the money. Somewhere.'}
        </text>
      </svg>

      <Slam lines={[String(verdict).toUpperCase(), 'M. DUFF, CHAIR']} at={118} x={1430} y={196} rot={-4} size={34} color={tone} vol={0.7} />
      <Sfx name="click" at={10} volume={0.35} />
      {[0, 1, 2, 3, 4].map((i) => <Sfx key={i} name="click" at={66 + i * 8} volume={0.22} />)}
      <Sfx name="stamp" at={118} volume={0.7} />
      <Sfx name="toll" at={158} volume={0.35} />
    </Scene>
  );
};
