// S02 · THE FILE. Seven seconds when a situation is picked off the board: the kind, the
// ward, how many are watching, how long you have, and the one room the briefing is sure of.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, At, Scene, Sheet, Kicker, Typer, Slam, RedCross, Marker, Wall, Sfx} from './kit.jsx';

const titleSize = (t) => (t.length > 44 ? 50 : t.length > 30 ? 58 : 68);

export const S02_Situation = ({kind = 'Hostage', title = '', ward = 'Eastport', visibility = 4, pressure = 'HIGH: A DEADLINE',
  room = 'BEDROOM (EST. 50%)', showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const vis = Math.max(1, Math.min(5, visibility));

  return (
    <Scene len={210} note="BRIEFING" right="ESTIMATES ONLY" bed="amb_office" bedVol={0.3} showSlots={showSlots} slots={slots}>
      {/* the folder's tab */}
      <At at={4} from="up" style={{left: 96, top: 96, width: 340, height: 44}}>
        <div style={{width: 340, height: 44, background: C.ink, color: C.paper, fontFamily: FONT.caps, fontSize: 19,
          letterSpacing: 7, display: 'flex', alignItems: 'center', paddingLeft: 20, boxSizing: 'border-box'}}>
          SITUATION FILE
        </div>
      </At>

      <Sheet x={96} y={132} w={1120} h={800} at={6} from="left" rot={-1.1} border={6} shadow={14}>
        <div style={{position: 'relative', width: '100%', height: '100%', padding: '38px 46px', boxSizing: 'border-box'}}>
          <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', borderBottom: `2px solid ${C.ink}`, paddingBottom: 12}}>
            <div style={{fontFamily: FONT.caps, fontSize: 19, letterSpacing: 7, color: C.mid}}>THE BOARD · WEEK 12</div>
            <div style={{fontFamily: FONT.caps, fontSize: 26, fontWeight: 600, letterSpacing: 2, border: `2.5px solid ${C.ink}`, padding: '2px 12px'}}>
              {String(kind).toUpperCase()}
            </div>
          </div>

          <At at={22} from="none" style={{left: 46, top: 146, width: 1010}}>
            <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: titleSize(title), lineHeight: 1.02, letterSpacing: 0.5, color: C.ink}}>
              {String(title).toUpperCase()}
            </div>
          </At>

          <At at={40} from="none" style={{left: 48, top: 330, width: 900}}>
            <div style={{fontFamily: FONT.type, fontSize: 27, color: C.dark, letterSpacing: 0.6}}>
              {String(ward).toUpperCase()} · A WARD AT {vis >= 4 ? 'FIVE' : vis === 3 ? 'THREE' : 'LOW'} ONLOOKERS
            </div>
          </At>

          <svg width={1040} height={430} style={{position: 'absolute', left: 40, top: 386}}>
            <line x1={0} y1={0} x2={1040} y2={0} stroke={C.ink} strokeWidth={1.4} opacity={0.35} />

            {/* visibility: five boxes, the filled ones are how many are watching */}
            <text x={0} y={44} fontFamily={FONT.caps} fontSize={18} letterSpacing={4} fill={C.mid}>VISIBILITY</text>
            {[0, 1, 2, 3, 4].map((i) => {
              const on = i < vis;
              const p = prog(f, 66 + i * 7, 70 + i * 7);
              return (
                <g key={i} opacity={p}>
                  <rect x={190 + i * 54} y={22} width={44} height={30} fill={on ? C.ink : C.paper} stroke={C.ink} strokeWidth={2.4} />
                  {on && i === vis - 1 ? <rect x={186 + i * 54} y={18} width={52} height={38} fill="none" stroke={C.ink} strokeWidth={1.2} /> : null}
                </g>
              );
            })}
            <text x={190 + 5 * 54 + 22} y={45} fontFamily={FONT.caps} fontSize={22} fill={C.dark}>{vis} / 5</text>

            {/* pressure */}
            <text x={0} y={116} fontFamily={FONT.caps} fontSize={18} letterSpacing={4} fill={C.mid}>PRESSURE</text>
            <text x={190} y={116} fontFamily={FONT.caps} fontWeight={600} fontSize={23} letterSpacing={2} fill={C.ink}
              opacity={prog(f, 92, 102)}>{String(pressure).toUpperCase()}</text>
            <line x1={0} y1={150} x2={1040} y2={150} stroke={C.ink} strokeWidth={1} opacity={0.25} />

            {/* what the briefing claims to know */}
            <text x={0} y={204} fontFamily={FONT.caps} fontSize={18} letterSpacing={4} fill={C.mid}>KNOWN</text>
            {[['THE ROOM', room], ['DOORS', 'LOCKED (EST. 40%)'], ['OTHERS INSIDE', 'NONE (EST. 40%)']].map(([k, v], i) => (
              <g key={k} opacity={prog(f, 104 + i * 12, 112 + i * 12)}>
                <text x={190} y={204 + i * 46} fontFamily={FONT.type} fontSize={22} fill={C.dark} letterSpacing={1}>{k}</text>
                <text x={470} y={204 + i * 46} fontFamily={FONT.type} fontWeight={700} fontSize={22} fill={C.ink} letterSpacing={1}>{v}</text>
              </g>
            ))}
            <line x1={0} y1={230} x2={1040} y2={230} stroke={C.ink} strokeWidth={1} opacity={0.25} />
          </svg>

          {/* the file's own note */}
          <At at={132} from="none" style={{left: 48, top: 706, width: 1020}}>
            <div style={{fontFamily: FONT.type, fontSize: 21, lineHeight: 1.4, color: C.dark, borderLeft: `5px solid ${C.ink}`, paddingLeft: 18}}>
              The briefing is always confident and never complete.<br />Tips are what the ward believes, not what is true.
            </div>
          </At>
        </div>
      </Sheet>

      {/* the photo of the plan, with the one room the file will commit to */}
      <Sheet x={1268} y={170} w={556} h={648} at={26} from="right" rot={1.6} border={6} shadow={12} pad={0}>
        <svg width={544} height={636} style={{position: 'absolute', left: 0, top: 0}}>
          <rect width={544} height={636} fill={C.floor} />
          <rect x={0} y={0} width={544} height={636} fill={C.paper} opacity={0.35} />
          <g opacity={prog(f, 40, 60)}>
            <Wall x1={54} y1={70} x2={490} y2={70} at={42} w={14} />
            <Wall x1={490} y1={70} x2={490} y2={470} at={46} w={14} />
            <Wall x1={490} y1={470} x2={54} y2={470} at={50} w={14} />
            <Wall x1={54} y1={470} x2={54} y2={70} at={54} w={14} />
            <Wall x1={54} y1={270} x2={300} y2={270} at={60} w={11} />
            <Wall x1={430} y1={70} x2={430} y2={270} at={66} w={11} />
            <Wall x1={300} y1={270} x2={300} y2={470} at={72} w={11} />
            {/* door swings */}
            <path d="M54,340 A78,78 0 0,1 132,270" fill="none" stroke={C.mid} strokeWidth={2} />
          </g>
          <RedCross x={196} y={396} r={40} at={112} dur={9} width={6} />
          <g opacity={prog(f, 122, 132)}>
            <Marker x={300} y={560} n={1} at={124} size={34} />
            <text x={330} y={572} fontFamily={FONT.caps} fontSize={17} letterSpacing={3} fill={C.ink}>KNOWN ROOM</text>
          </g>
          <text x={54} y={554} fontFamily={FONT.caps} fontSize={15} letterSpacing={4} fill={C.mid}>PLAN · NOT TO SCALE</text>
        </svg>
      </Sheet>

      <At at={146} from="none" style={{left: 1276, top: 840, width: 560}}>
        <div style={{fontFamily: FONT.type, fontSize: 23, color: C.ink, letterSpacing: 0.4}}>{String(room).toUpperCase()}</div>
      </At>

      <Slam lines={['BRIEFING', 'NOT INTELLIGENCE']} at={158} x={1246} y={884} rot={-3.4} size={24} vol={0.55} />
      <Sfx name="door" at={6} volume={0.5} />
      <Sfx name="click" at={26} volume={0.4} />
      <Sfx name="click" at={66} volume={0.3} />
      <Sfx name="radio" at={112} volume={0.35} />
    </Scene>
  );
};
