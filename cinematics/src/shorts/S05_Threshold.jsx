// S05 · THE THRESHOLD. Seven seconds in a doorway: the cone sweeps the room, recognition
// fills, and the room either is empty or is not. Two variants from one file.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Slam, Draw, Wall, PlanFigure, Meter, Sfx, Kicker} from './kit.jsx';

const D = {x: 960, y: 592};                       // the door, in the wall
const ROOM = {x0: 470, y0: 250, x1: 1450, y1: 592};
const IN = {x: 1180, y: 396};                     // where the room's occupant stands

export const S05_Threshold = ({variant = 'contact', room = 'LIVING ROOM', seconds = 1.4, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const contact = variant === 'contact';
  const sweep = Math.sin(Math.min(1, (f - 26) / 118) * Math.PI * 1.1) * 34;   // degrees either side of straight in
  const rec = contact ? Math.max(0, Math.min(1, (f - 74) / 46)) : 0;
  const shots = [166, 174, 182];
  const hit = f >= shots[1] + 3;

  // deterministic room noise: a few specks of grit on the floor
  const grit = Array.from({length: 70}, (_, i) => (
    <rect key={i} x={ROOM.x0 + rnd(i) * (ROOM.x1 - ROOM.x0)} y={ROOM.y0 + rnd(i + 40) * (ROOM.y1 - ROOM.y0)}
      width={2 + (i % 3)} height={1.6} fill={C.ink} opacity={0.16} />
  ));

  const coneLen = 620;
  const a = ((sweep - 90) * Math.PI) / 180;
  const spread = (54 * Math.PI) / 180;

  return (
    <Scene len={210} note="IN THE RUN" right="SEEN · HEARD · JUDGED" bed="amb_office" bedVol={0.26} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 88, width: 420}}>{contact ? 'CONTACT' : 'FIRST ROOM'}</Kicker>
      <At at={10} from="left" style={{left: 96, top: 132, width: 620}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 62, lineHeight: 1.0, letterSpacing: 2, color: C.ink}}>
          THE THRESHOLD
        </div>
      </At>

      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {/* outside: the approach */}
        <rect x={ROOM.x0} y={ROOM.y1} width={ROOM.x1 - ROOM.x0} height={240} fill={C.light} opacity={prog(f, 10, 26)} />
        <text x={D.x - 190} y={ROOM.y1 + 96} fontFamily={FONT.caps} fontSize={17} letterSpacing={6} fill={C.dark} opacity={0.7 * prog(f, 24, 34)}>HALL</text>

        {/* outside the room: paper, so the sheet stays a sheet */}
        <rect x={ROOM.x0} y={ROOM.y0} width={ROOM.x1 - ROOM.x0} height={0} fill="none" />
        {/* the room: an inner plate, one step darker than the page */}
        <rect x={ROOM.x0} y={ROOM.y0} width={ROOM.x1 - ROOM.x0} height={ROOM.y1 - ROOM.y0} fill={C.floor} opacity={prog(f, 12, 28)} />
        <rect x={ROOM.x0} y={ROOM.y0} width={ROOM.x1 - ROOM.x0} height={ROOM.y1 - ROOM.y0} fill="url(#rmzone)" opacity={0.5 * prog(f, 16, 30)} />
        <defs>
          <pattern id="rmzone" width={48} height={48} patternUnits="userSpaceOnUse">
            <line x1={0} y1={0} x2={48} y2={0} stroke={C.ink} strokeWidth={1} opacity={0.09} />
            <line x1={0} y1={0} x2={0} y2={48} stroke={C.ink} strokeWidth={1} opacity={0.09} />
          </pattern>
          <clipPath id="roomclip"><rect x={ROOM.x0} y={ROOM.y0} width={ROOM.x1 - ROOM.x0} height={ROOM.y1 - ROOM.y0} /></clipPath>
        </defs>
        <g opacity={prog(f, 20, 34)} clipPath="url(#roomclip)">{grit}</g>
        {/* furniture: a sofa, a table, a shelf */}
        <g fill="none" stroke={C.ink} strokeWidth={2.6} opacity={prog(f, 26, 40)}>
          <rect x={560} y={300} width={210} height={74} rx={8} />
          <rect x={600} y={440} width={130} height={90} />
          <rect x={1270} y={470} width={150} height={70} />
        </g>

        {/* walls */}
        <Wall x1={ROOM.x0} y1={ROOM.y0} x2={ROOM.x1} y2={ROOM.y0} at={14} w={14} />
        <Wall x1={ROOM.x0} y1={ROOM.y0} x2={ROOM.x0} y2={ROOM.y1} at={16} w={14} />
        <Wall x1={ROOM.x1} y1={ROOM.y0} x2={ROOM.x1} y2={ROOM.y1} at={18} w={14} />
        <Wall x1={ROOM.x0} y1={ROOM.y1} x2={D.x - 62} y2={ROOM.y1} at={20} w={14} />
        <Wall x1={D.x + 62} y1={ROOM.y1} x2={ROOM.x1} y2={ROOM.y1} at={22} w={14} />

        {/* the vision cone: the room, as much of it as one man can see */}
        <g opacity={prog(f, 34, 46)}>
          {(() => {
          const ox = D.x, oy = D.y + 14;
          const d = `M${ox},${oy} L${ox + Math.cos(a - spread) * coneLen},${oy + Math.sin(a - spread) * coneLen} A${coneLen},${coneLen} 0 0,1 ${ox + Math.cos(a + spread) * coneLen},${oy + Math.sin(a + spread) * coneLen} Z`;
          return (
            <>
              <path d={d} fill={C.paper} opacity={0.35} clipPath="url(#roomclip)" />
              <path d={d} fill="none" stroke={C.ink} strokeWidth={1.6} opacity={0.28} strokeDasharray="10 8" clipPath="url(#roomclip)" />
            </>
          );
        })()}
        </g>

        {/* the occupant: only there if the variant says so */}
        {contact && f >= 70 ? (
          <g>
            <PlanFigure x={IN.x} y={IN.y} rot={-120} mark="hatch" opacity={Math.min(1, (f - 70) / 6)} />
            {/* recognition: a bracket closing in, the way the game marks an estimate becoming a man */}
            <g opacity={prog(f, 76, 84)} stroke={C.ink} strokeWidth={2.6} fill="none">
              {[[-1, -1], [1, -1], [-1, 1], [1, 1]].map(([sx, sy], i) => (
                <path key={i} d={`M${IN.x + sx * (60 - rec * 22)},${IN.y + sy * 46} L${IN.x + sx * (38 - rec * 14)},${IN.y + sy * 46} M${IN.x + sx * (60 - rec * 22)},${IN.y + sy * 46} L${IN.x + sx * (60 - rec * 22)},${IN.y + sy * (26 - rec * 4)}`} />
              ))}
            </g>
          </g>
        ) : null}

        {/* the officer in the door */}
        <PlanFigure x={D.x} y={D.y + 42} rot={-90} scale={1.1} opacity={prog(f, 30, 42)} />

        {/* rounds: only after recognition, only in the contact variant */}
        {contact && shots.map((s, i) => (f >= s && f < s + 5 ? (
          <g key={i}>
            <line x1={D.x + 4} y1={D.y + 26} x2={IN.x} y2={IN.y} stroke={C.ink} strokeWidth={1.7} opacity={0.75} />
            <circle cx={D.x + 4} cy={D.y + 26} r={13} fill={C.paper} stroke={C.ink} strokeWidth={1.5} />
          </g>
        ) : null))}

        {/* the consequence: one stain, smaller than the paperwork it will make */}
        {contact && hit ? (
          <g>
            <g transform={`translate(${IN.x},${IN.y}) scale(0.62) translate(${-IN.x},${-IN.y})`}>
              <path d={`M${IN.x - 34},${IN.y + 22} l24,-18 l30,4 l16,20 l-6,24 l-28,10 l-26,-8 Z`} fill={C.red} opacity={0.7 * prog(f, shots[1] + 6, shots[1] + 40)} />
            </g>
            <PlanFigure x={IN.x} y={IN.y} rot={-120} mark="hatch" down opacity={prog(f, shots[1] + 4, shots[1] + 10)} />
          </g>
        ) : null}

        {/* the HUD the game would draw over it */}
        <g opacity={prog(f, 48, 60)}>
          <line x1={96} y1={930} x2={1824} y2={930} stroke={C.ink} strokeWidth={1.4} opacity={0.3} />
          <text x={96} y={972} fontFamily={FONT.caps} fontSize={17} letterSpacing={5} fill={C.mid}>RECOGNITION</text>
          <Meter x={300} y={950} w={560} h={26} value={rec * 100} of={100} at={48} dur={2} ticks={9} />
          <text x={890} y={974} fontFamily={FONT.caps} fontWeight={600} fontSize={26} fill={C.ink}>
            {contact ? (rec >= 1 ? 'RECOGNISED' : `${(rec * Number(seconds)).toFixed(2)} s`) : 'CLEAR'}
          </text>
          <text x={96} y={1012} fontFamily={FONT.type} fontSize={19} fill={C.dark}>Recognition slows with eccentricity, then Fitts-law time on target.</text>
          <text x={1824} y={972} textAnchor="end" fontFamily={FONT.caps} fontSize={17} letterSpacing={4} fill={C.mid}>
            {String(room).toUpperCase()} · 120° CONE
          </text>
          <text x={1824} y={1004} textAnchor="end" fontFamily={FONT.type} fontSize={19} fill={C.dark}>
            {contact ? 'One man, one decision, 0.' + String(Math.round((shots[0] - 74) / 30 * 100)).padStart(2, '0') + ' s of it.' : 'Nothing here. The next room is not this room.'}
          </text>
        </g>
      </svg>

      {contact ? <Slam lines={['CONTAINED', 'AFTER THE FACT']} at={188} x={1480} y={112} rot={-3} size={26} vol={0.6} /> : (
        <Slam lines={['ROOM', 'CLEAR']} at={150} x={1500} y={112} rot={-3.4} size={30} color={C.ink} vol={0.5} />
      )}
      <Sfx name="door" at={30} volume={0.45} />
      <Sfx name="radio" at={70} volume={0.4} />
      {contact ? <Sfx name="shot_pistol_1" at={shots[0]} volume={0.9} /> : <Sfx name="click" at={150} volume={0.35} />}
      {contact ? <Sfx name="shot_pistol_2" at={shots[1]} volume={0.9} /> : null}
      {contact ? <Sfx name="shot_pistol_1" at={shots[2]} volume={0.8} rate={1.04} /> : null}
      {contact ? <Sfx name="shot_pistol_1" at={shots[0] - 8} volume={0.35} rate={1.08} /> : null}
      <Sfx name="radio" at={150} volume={0.45} />
      <Sfx name="stamp" at={contact ? 188 : 150} volume={0.5} />
    </Scene>
  );
};
