// S01 · THE BOARD REFILLS. Six seconds at the top of a week: the number, the calendar,
// and this week's situations dealt out of the drawer.
import React from 'react';
import {useCurrentFrame, spring, useVideoConfig} from 'remotion';
import {C, FONT, prog, At, Scene, Sheet, Kicker, Slam, Sfx} from './kit.jsx';

export const S01_WeekCard = ({week = 12, of = 40, ward = 'Ironworks', cards = [], note = '', stamp = ['WEEK 12'], showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const {fps} = useVideoConfig();
  const cells = Math.max(1, Math.min(52, of));

  // the numeral lands like a stamp: overshoot then settle
  const num = spring({frame: f - 12, fps, config: {damping: 16, mass: 0.6, stiffness: 140}});

  return (
    <Scene len={180} note="WEEK" right={`${week} / ${of}`} bed="amb_office" bedVol={0.3} showSlots={showSlots} slots={slots}>
      <Kicker at={8} style={{left: 96, top: 120, width: 560}}>PORT CARRICK · OPERATIONS BOARD</Kicker>

      {/* the numeral, cropped at the edge like a title card */}
      <div style={{position: 'absolute', left: 70, top: 176, display: 'flex', alignItems: 'flex-end', opacity: Math.min(1, num * 1.4),
        transform: `scale(${0.94 + 0.06 * num})`, transformOrigin: 'left bottom'}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 430, lineHeight: 0.82, letterSpacing: -14, color: C.ink}}>
          {String(week).padStart(2, '0')}
        </div>
        <div style={{fontFamily: FONT.caps, fontSize: 64, color: C.mid, marginLeft: 20, marginBottom: 40, letterSpacing: 2}}>/{of}</div>
      </div>

      {/* the ward, and the line under it */}
      <At at={34} from="left" style={{left: 100, top: 570, width: 640}}>
        <div style={{fontFamily: FONT.caps, fontSize: 52, fontWeight: 600, letterSpacing: 10, color: C.ink}}>{String(ward).toUpperCase()}</div>
      </At>
      <At at={44} from="none" style={{left: 102, top: 638, width: 700}}>
        <div style={{fontFamily: FONT.type, fontSize: 24, color: C.dark, letterSpacing: 1}}>
          The board is filled at the start of the week. Nothing on it waits.
        </div>
      </At>

      {/* this week's situations, dealt from the drawer */}
      {cards.slice(0, 3).map((c, i) => {
        const at = 58 + i * 18;
        return (
          <Sheet key={i} x={1010} y={196 + i * 148} w={760} h={124} at={at} from={i % 2 ? 'right' : 'down'} rot={i % 2 ? 0.9 : -1.1} border={5} shadow={10}>
            <div style={{display: 'flex', alignItems: 'center', height: '100%', padding: '0 26px', boxSizing: 'border-box'}}>
              <div style={{fontFamily: FONT.caps, fontSize: 18, letterSpacing: 3, color: C.mid, width: 54}}>0{i + 1}</div>
              <div style={{flex: 1}}>
                <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 38, letterSpacing: 1, color: C.ink, textTransform: 'uppercase'}}>{c.kind}</div>
                <div style={{fontFamily: FONT.type, fontSize: 22, color: C.dark, marginTop: 2}}>{c.ward}</div>
              </div>
              <div style={{width: 44, height: 44, border: `3px solid ${C.ink}`, position: 'relative'}}>
                <div style={{position: 'absolute', left: 18, top: 8, width: 4, height: 22, background: C.ink, transform: 'rotate(45deg)'}} />
                <div style={{position: 'absolute', left: 18, top: 8, width: 4, height: 22, background: C.ink, transform: 'rotate(-45deg)'}} />
              </div>
            </div>
          </Sheet>
        );
      })}
      <At at={116} from="none" style={{left: 1014, top: 640, width: 760}}>
        <div style={{fontFamily: FONT.type, fontSize: 26, color: C.ink, letterSpacing: 0.5}}>— {note || 'ONE OF THESE IS THE WEEK.'}</div>
      </At>

      {/* the calendar: forty weeks, each one a box you do not get back */}
      <div style={{position: 'absolute', left: 96, top: 792, fontFamily: FONT.caps, fontSize: 17, letterSpacing: 6, color: C.mid}}>
        {`${of} WEEKS · THE ELECTION IS THE LAST BOX`}
      </div>
      <svg width={1920} height={1080} style={{position: 'absolute'}}>
        {Array.from({length: cells}, (_, i) => {
          const x = 96 + i * 42.5;
          const at = 22 + i * 1.6;
          const p = prog(f, at, at + 6);
          const done = i < week - 1;
          const now = i === week - 1;
          const election = i === cells - 1;
          return (
            <g key={i} opacity={p}>
              <rect x={x} y={828} width={34} height={54} fill={done || now ? C.ink : C.paper} stroke={C.ink} strokeWidth={done || now ? 2 : 2.2} />
              {now ? (
                <>
                  <rect x={x - 5} y={823} width={44} height={64} fill="none" stroke={C.ink} strokeWidth={4} />
                  <rect x={x} y={816} width={34} height={6} fill={C.red} />
                </>
              ) : null}
              {election ? <text x={x + 17} y={864} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={20} fill={now ? C.paper : C.red}>E</text> : null}
              {done && i % 5 === 4 ? <line x1={x + 6} y1={855} x2={x + 28} y2={855} stroke={C.paper} strokeWidth={2} opacity={0.7} /> : null}
            </g>
          );
        })}
      </svg>

      <Slam lines={stamp} at={96} x={1470} y={92} rot={-6} color={C.ink} size={44} vol={0.7} />
      {cards.slice(0, 3).map((_, i) => <Sfx key={i} name="click" at={58 + i * 18} volume={0.42} />)}
      <Sfx name="click" at={22} volume={0.3} />
      <Sfx name="toll" at={150} volume={0.45} />
    </Scene>
  );
};
