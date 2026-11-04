// S11 · ELECTION NIGHT. Ten seconds: forty weeks, three names, six wards reporting, one
// winner. The only red on the page is the line that closes the campaign.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Slam, Rule, Sfx, Kicker} from './kit.jsx';

const WARDS = ['NORTHGATE', 'RIVERSIDE', 'OLD TOWN', 'IRONWORKS', 'EASTPORT', 'KILBRIDE'];
const ROW_Y = [300, 470, 640];

export const S11_Election = ({shares = [38, 33, 29], winner = 0, names = ['ROYCE KETTERING', 'DANA OKONJO-VALE', 'GORDON PELL'],
  tickets = ['SAFE STREETS', 'CARRICK TOGETHER', 'INDEPENDENT'], showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const total = shares.reduce((a, b) => a + b, 0) || 1;
  const w = Math.max(0, Math.min(2, winner));
  const winName = String(names[w] || names[0]);

  return (
    <Scene len={300} note="ELECTION NIGHT" right="WEEK 40 OF 40" bed="amb_city" bedVol={0.36} showSlots={showSlots} slots={slots}>
      <Kicker at={8} style={{left: 96, top: 92, width: 700}}>THE CITY DECIDES WHAT HAPPENS TO YOU</Kicker>
      <At at={12} from="left" style={{left: 96, top: 134, width: 900}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 64, letterSpacing: 4, color: C.ink}}>ELECTION NIGHT</div>
      </At>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {[0, 1, 2].map((i) => {
          const share = (shares[i] / total) * 100;
          const grow = prog(f, 60 + i * 14, 116 + i * 14);
          const isWin = i === w;
          const barW = (1420 * share * grow) / 100;
          return (
            <g key={i}>
              {/* the row's rule; the winner's is red */}
              {isWin && f > 176 ? <rect x={96} y={ROW_Y[i] - 60} width={1728} height={6} fill={C.red} opacity={prog(f, 176, 188)} /> : null}
              <text x={96} y={ROW_Y[i] - 6} fontFamily={FONT.caps} fontWeight={600} fontSize={46} letterSpacing={2} fill={C.ink}
                opacity={prog(f, 30 + i * 10, 42 + i * 10)}>{String(names[i]).toUpperCase()}</text>
              <text x={98} y={ROW_Y[i] + 30} fontFamily={FONT.type} fontSize={21} letterSpacing={3} fill={C.dark}
                opacity={prog(f, 36 + i * 10, 46 + i * 10)}>{String(tickets[i]).toUpperCase()}</text>

              <rect x={96} y={ROW_Y[i] + 54} width={1420} height={44} fill={C.paper} stroke={C.ink} strokeWidth={3}
                opacity={prog(f, 48, 58)} />
              <rect x={96} y={ROW_Y[i] + 54} width={barW} height={44} fill={C.ink} opacity={prog(f, 48, 58)} />
              <text x={1544} y={ROW_Y[i] + 90} fontFamily={FONT.caps} fontWeight={600} fontSize={52} fill={C.ink}
                opacity={prog(f, 60 + i * 14, 70 + i * 14)}>{Math.round(share * grow)}%</text>
              {isWin && f > 196 ? (
                <text x={790} y={ROW_Y[i] + 30} fontFamily={FONT.caps} fontWeight={600} fontSize={30} letterSpacing={10} fill={C.red}
                  opacity={prog(f, 196, 208)}>WINS</text>
              ) : null}
            </g>
          );
        })}

        {/* the wards, reporting one at a time */}
        <g opacity={prog(f, 84, 96)}>
          <text x={96} y={790} fontFamily={FONT.caps} fontSize={16} letterSpacing={6} fill={C.mid}>SIX WARDS REPORTING</text>
          {WARDS.map((wd, i) => {
            const at = 92 + i * 12;
            const done = f >= at;
            return (
              <g key={wd} opacity={prog(f, at, at + 8)}>
                <rect x={96 + i * 288} y={812} width={264} height={54} fill={done ? C.paper : C.floor} stroke={C.ink} strokeWidth={2.4} />
                <text x={112 + i * 288} y={845} fontFamily={FONT.caps} fontSize={18} letterSpacing={2} fill={C.ink}>{wd}</text>
                {i % 3 === 0 || i === 2 ? <rect x={318 + i * 288} y={826} width={26} height={26} fill={C.ink} /> : <rect x={318 + i * 288} y={826} width={26} height={26} fill="none" stroke={C.ink} strokeWidth={2} />}
              </g>
            );
          })}
        </g>

        {/* the close: the winner's name, taken off the board */}
        <g opacity={prog(f, 232, 248)}>
          <line x1={96} y1={918} x2={1824} y2={918} stroke={C.ink} strokeWidth={2} opacity={0.4} />
          <text x={96} y={982} fontFamily={FONT.caps} fontWeight={600} fontSize={54} letterSpacing={4} fill={C.ink}>
            {winName} IS MAYOR.
          </text>
        </g>
      </svg>

      <Slam lines={['CALLED', 'AT 23:40']} at={216} x={1330} y={150} rot={-4} size={26} vol={0.6} />
      {[0, 1, 2, 3, 4, 5].map((i) => <Sfx key={i} name="click" at={92 + i * 12} volume={0.28} />)}
      <Sfx name="radio" at={60} volume={0.4} />
      <Sfx name="radio" at={176} volume={0.45} />
      <Sfx name="click" at={196} volume={0.5} />
      <Sfx name="toll" at={240} volume={0.8} />
      <Sfx name="stamp" at={216} volume={0.6} />
    </Scene>
  );
};
