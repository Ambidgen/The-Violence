// S10 · THE STANDING. Seven seconds on one ally: a bar, a red line at 25, and the week the
// bar goes under it. Everything this person holds leaves with them.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, At, Scene, Slam, Meter, Sfx, Kicker, Typer} from './kit.jsx';

const X0 = 200, X1 = 1660, Y = 560, TH = 25;

export const S10_Ally = ({name = 'TOMMY ROURKE', title = 'President, Police Benevolent Association',
  holds = "the officers' goodwill", from = 60, to = 22, lost = true, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const v0 = Math.max(0, Math.min(100, from));
  const v1 = Math.max(0, Math.min(100, to));
  const move = prog(f, 74, 132);
  const v = v0 + (v1 - v0) * move;
  const x = X0 + ((X1 - X0) * v) / 100;
  const under = lost && v1 < TH;

  return (
    <Scene len={210} note="POLITICS" right="FOUR PEOPLE, FOUR THINGS THEY HOLD" bed="amb_office" bedVol={0.28} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 200, top: 110, width: 700}}>STANDING WITH THE DEPARTMENT</Kicker>

      <At at={12} from="left" style={{left: 196, top: 158, width: 1100}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 92, lineHeight: 1.0, letterSpacing: 3, color: C.ink}}>
          {String(name).toUpperCase()}
        </div>
      </At>
      <At at={22} from="none" style={{left: 200, top: 268, width: 1200}}>
        <div style={{fontFamily: FONT.type, fontSize: 30, color: C.dark, letterSpacing: 0.6}}>{title}</div>
      </At>
      <At at={34} from="none" style={{left: 200, top: 322, width: 1200}}>
        <div style={{fontFamily: FONT.caps, fontSize: 24, letterSpacing: 4, color: C.ink}}>
          HOLDS {String(holds).toUpperCase()}
        </div>
      </At>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {/* the scale: 0 to 100, in tens */}
        <g opacity={prog(f, 44, 56)}>
          <rect x={X0} y={Y - 34} width={X1 - X0} height={68} fill={C.paper} stroke={C.ink} strokeWidth={3} />
          {Array.from({length: 11}, (_, i) => {
            const xx = X0 + ((X1 - X0) * i) / 10;
            return (
              <g key={i}>
                <line x1={xx} y1={Y - 34} x2={xx} y2={Y + 34} stroke={C.ink} strokeWidth={i % 5 === 0 ? 2.4 : 1.2} opacity={i % 5 === 0 ? 0.7 : 0.3} />
                <text x={xx} y={Y + 64} textAnchor="middle" fontFamily={FONT.caps} fontSize={17} fill={C.mid}>{i * 10}</text>
              </g>
            );
          })}
          {/* the red line: below it, an ally is no longer an ally */}
          <line x1={X0 + ((X1 - X0) * TH) / 100} y1={Y - 84} x2={X0 + ((X1 - X0) * TH) / 100} y2={Y + 96} stroke={C.red} strokeWidth={4} />
          <text x={X0 + ((X1 - X0) * TH) / 100 + 14} y={Y + 96} fontFamily={FONT.caps} fontSize={17} letterSpacing={3} fill={C.red}>
            LOST BELOW 25
          </text>
        </g>

        {/* the fill: the standing itself */}
        <rect x={X0} y={Y - 34} width={Math.max(0, x - X0)} height={68} fill={C.ink} opacity={0.92 * prog(f, 52, 64)} />
        {/* the marker: a heavy pointer that walks the bar */}
        <g transform={`translate(${x},${Y})`} opacity={prog(f, 56, 66)}>
          <path d="M0,42 L-18,68 L18,68 Z" fill={C.ink} />
          <line x1={0} y1={68} x2={0} y2={112} stroke={C.ink} strokeWidth={4} />
          <rect x={-44} y={112} width={88} height={56} fill={C.paper} stroke={C.ink} strokeWidth={3} />
          <text x={0} y={152} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={38} fill={C.ink}>{Math.round(v)}</text>
        </g>

        {/* the change, if it went down */}
        {move > 0 ? (
          <g opacity={prog(f, 74, 86)}>
            <line x1={X0 + ((X1 - X0) * v0) / 100} y1={Y + 178} x2={X0 + ((X1 - X0) * v1) / 100} y2={Y + 178}
              stroke={v1 < v0 ? C.ink : C.ink} strokeWidth={2} strokeDasharray="8 7" />
            <text x={X0 + ((X1 - X0) * ((v0 + v1) / 2)) / 100} y={Y + 210} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600}
              fontSize={26} fill={under ? C.red : C.ink}>{v1 < v0 ? `−${v0 - v1}` : `+${v1 - v0}`}</text>
          </g>
        ) : null}

        {/* what the loss costs, in the campaign's own words */}
        <g opacity={prog(f, 150, 164)}>
          <text x={200} y={828} fontFamily={FONT.caps} fontSize={16} letterSpacing={5} fill={C.mid}>IF THEY WALK</text>
          <text x={200} y={884} fontFamily={FONT.type} fontSize={30} fill={C.ink}>
            {lost ? `Nobody with ${holds} is answering the phone.` : `They stay, for now. The line is at 25.`}
          </text>
        </g>
      </svg>

      <Slam lines={lost ? ['LOST', 'STANDING'] : ['HOLDS', 'STANDING']} at={150} x={1390} y={700} rot={-4} size={40} color={lost ? C.red : C.ink} vol={0.7} />
      <Sfx name="click" at={44} volume={0.35} />
      <Sfx name="radio" at={74} volume={0.35} />
      <Sfx name="stamp" at={150} volume={0.7} />
      <Sfx name="toll" at={186} volume={0.4} />
    </Scene>
  );
};
