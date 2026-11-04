// S06 · OFFICER DOWN. Eight seconds: the plan stops moving, the radio tries, and the card
// with a name on it arrives. Two variants: down (wounded, evacuated) and killed.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Sheet, Slam, Wall, PlanFigure, Sfx} from './kit.jsx';

const R = {x0: 300, y0: 200, x1: 1300, y1: 800};
const HIT = {x: 900, y: 470};          // where the officer is standing when the round arrives
const FALL = 92;

export const S06_OfficerDown = ({name = 'J. OKAFOR', badge = '4417', week = 23, variant = 'down', showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const killed = variant === 'killed';
  const struck = f >= FALL;
  const radioT = killed ? 132 : 138;

  const wallGrit = Array.from({length: 80}, (_, i) => (
    <rect key={i} x={R.x0 + rnd(i) * (R.x1 - R.x0)} y={R.y0 + rnd(i + 21) * (R.y1 - R.y0)} width={2 + (i % 3)} height={1.6} fill={C.ink} opacity={0.18} />
  ));

  return (
    <Scene len={240} note="LINE OF DUTY" right={killed ? 'END OF WATCH' : 'EVACUATED'} bed="amb_office" bedVol={0.22} showSlots={showSlots} slots={slots}>
      {/* 1. the room, from above, at the moment it stops */}
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        <g opacity={1 - prog(f, 132, 156)}>
          <rect x={R.x0} y={R.y0} width={R.x1 - R.x0} height={R.y1 - R.y0} fill={C.floor} opacity={prog(f, 8, 24)} />
          <g opacity={prog(f, 16, 30)}>{wallGrit}</g>
          <Wall x1={R.x0} y1={R.y0} x2={R.x1} y2={R.y0} at={10} w={13} />
          <Wall x1={R.x1} y1={R.y0} x2={R.x1} y2={R.y1} at={12} w={13} />
          <Wall x1={R.x1} y1={R.y1} x2={R.x0} y2={R.y1} at={14} w={13} />
          <Wall x1={R.x0} y1={R.y1} x2={R.x0} y2={R.y0} at={16} w={13} />
          <Wall x1={860} y1={R.y0} x2={860} y2={470} at={20} w={9} />
          <Wall x1={860} y1={560} x2={860} y2={R.y1} at={22} w={9} />

          {/* the squad's last positions, and the ones still standing */}
          {[[700, 470, 0], [790, 560, -30], [980, 560, -50], [1060, 470, -10]].map(([x, y, rot], i) => (
            <PlanFigure key={i} x={x} y={y} rot={rot} scale={1.05} opacity={prog(f, 26 + i * 6, 38 + i * 6)} />
          ))}

          {/* the officer, and the round nobody saw */}
          {!struck ? <PlanFigure x={HIT.x} y={HIT.y} rot={6} scale={1.15} opacity={prog(f, 34, 46)} /> : (
            <g>
              <PlanFigure x={HIT.x} y={HIT.y} rot={6} scale={1.15} down opacity={prog(f, FALL, FALL + 8)} />
              <path d={`M${HIT.x - 40},${HIT.y + 26} l30,-20 l36,8 l14,26 l-10,26 l-34,8 l-30,-12 Z`} fill={C.red}
                opacity={0.72 * prog(f, FALL + 12, FALL + 56)} />
              <path d={`M${HIT.x - 26},${HIT.y + 30} l20,-12 l24,6 l8,18 l-8,18 l-24,4 l-20,-8 Z`} fill={C.red}
                opacity={0.9 * prog(f, FALL + 26, FALL + 70)} />
            </g>
          )}
          <line x1={R.x1 - 16} y1={HIT.y + 6} x2={HIT.x + 26} y2={HIT.y + 2} stroke={C.ink} strokeWidth={1.6}
            opacity={f >= FALL - 4 && f < FALL + 2 ? 0.75 : 0} />
          <circle cx={HIT.x} cy={HIT.y} r={26 + (struck ? Math.min(1, (f - FALL) / 8) * 40 : 0)} fill="none" stroke={C.red} strokeWidth={2.5}
            opacity={struck ? Math.max(0, 1 - (f - FALL) / 22) : 0} />

          {/* the radio, trying */}
          <g opacity={prog(f, radioT, radioT + 8)}>
            <rect x={R.x0 + 20} y={R.y0 + 20} width={300} height={118} fill={C.paper} stroke={C.ink} strokeWidth={3.5} />
            <text x={R.x0 + 38} y={R.y0 + 52} fontFamily={FONT.caps} fontSize={15} letterSpacing={4} fill={C.mid}>CHANNEL 2</text>
            {Array.from({length: 22}, (_, k) => {
              const amp = 0.2 + 0.8 * Math.abs(Math.sin(k * 1.9 + f * 0.7));
              return <rect key={k} x={R.x0 + 38 + k * 11.4} y={R.y0 + 96 - amp * 26} width={4.6} height={amp * 52} fill={C.ink} />;
            })}
          </g>
          <text x={R.x0 + 22} y={R.y1 - 26} fontFamily={FONT.caps} fontSize={17} letterSpacing={6} fill={C.dark} opacity={prog(f, 40, 52)}>
            OPERATION · WEEK {week}
          </text>
        </g>
        <text x={96} y={112} fontFamily={FONT.caps} fontWeight={600} fontSize={54} letterSpacing={3} fill={C.ink} opacity={prog(f, 12, 26)}>
          {killed ? 'OFFICER DOWN' : 'OFFICER OUT'}
        </text>
      </svg>

      {/* 2. the card */}
      <Sheet x={250} y={330} w={1420} h={520} at={128} from="down" rot={-0.8} border={7} shadow={18} pad={0}>
        <div style={{position: 'absolute', inset: 0, padding: '34px 54px', boxSizing: 'border-box'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start'}}>
            <div>
              <div style={{fontFamily: FONT.caps, fontSize: 18, letterSpacing: 8, color: C.mid}}>PORT CARRICK POLICE DEPARTMENT</div>
              <div style={{fontFamily: FONT.caps, fontSize: 17, letterSpacing: 6, color: C.mid, marginTop: 6}}>NOTICE TO THE DEPARTMENT</div>
            </div>
            <div style={{textAlign: 'right', fontFamily: FONT.caps, fontSize: 18, letterSpacing: 5, color: C.mid}}>
              WEEK {week}<br />{killed ? 'LINE OF DUTY' : 'INJURY ON DUTY'}
            </div>
          </div>

          <div style={{position: 'relative', marginTop: 24, borderTop: `3px solid ${C.ink}`, paddingTop: 20, height: 300}}>
            <At at={146} from="none" style={{left: 0, top: 6, width: 960}}>
              <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 104, letterSpacing: 6, lineHeight: 1, color: C.ink}}>
                {String(name).toUpperCase()}
              </div>
            </At>
            <At at={158} from="none" style={{left: 2, top: 146, width: 960}}>
              <div style={{fontFamily: FONT.type, fontSize: 28, color: C.dark, letterSpacing: 2}}>
                BADGE {badge} · {killed ? 'KILLED IN THE LINE OF DUTY' : 'WOUNDED · OUT FOR WEEKS'}
              </div>
            </At>
            <At at={176} from="none" style={{left: 2, top: 196, width: 1040}}>
              <div style={{fontFamily: FONT.type, fontSize: 23, lineHeight: 1.45, color: C.dark}}>
                {killed
                  ? "The department will pay for the funeral. The operation's findings will be filed in the usual way."
                  : "The department will pay the hospital. The officer's post is empty until they come back, if they do."}
              </div>
            </At>
            <div style={{position: 'absolute', left: 2, top: 282, height: 5, width: (killed ? 1120 : 820) * prog(f, 196, 214), background: C.red}} />
          </div>

          <div style={{position: 'absolute', right: 54, bottom: 26, textAlign: 'right'}}>
            <div style={{fontFamily: FONT.caps, fontSize: 16, letterSpacing: 5, color: C.mid}}>SIGNED</div>
            <div style={{fontFamily: FONT.type, fontSize: 24, color: C.ink, marginTop: 6, fontStyle: 'italic'}}>the chief of police</div>
          </div>
        </div>
      </Sheet>

      <Slam lines={killed ? ['KILLED', 'IN THE LINE'] : ['WOUNDED', 'TRANSPORTED']} at={killed ? 190 : 184} x={262} y={884} rot={-4} size={26} vol={0.7} />
      <Sfx name="shot_rifle_1" at={FALL} volume={0.95} />
      <Sfx name="far_rifle" at={FALL + 3} volume={0.5} />
      <Sfx name="radio" at={radioT} volume={0.6} />
      <Sfx name="door" at={128} volume={0.4} />
      <Sfx name="toll" at={killed ? 200 : 206} volume={0.7} />
    </Scene>
  );
};
