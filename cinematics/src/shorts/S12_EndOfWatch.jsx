// S12 · END OF WATCH. Eight seconds on the desk the department leaves empty: the badge,
// the folded flag, the notice, one red rule. No music. One bell.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {AbsoluteFill} from 'remotion';
import {C, FONT, prog, At, Scene, Slam, Sfx, Kicker, Typer} from './kit.jsx';

const INK = '#0d0d0d';
const PAPER = '#EDEDE8';

const Badge = ({x, y, badge}) => (
  <g transform={`translate(${x},${y})`}>
    <path d="M0,-96 L74,-66 L74,20 Q74,74 0,104 Q-74,74 -74,20 L-74,-66 Z" fill={PAPER} stroke={PAPER} strokeWidth={3} />
    <path d="M0,-76 L56,-52 L56,16 Q56,58 0,82 Q-56,58 -56,16 L-56,-52 Z" fill="none" stroke={INK} strokeWidth={3} />
    <text y={-30} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={26} letterSpacing={4} fill={INK}>PCPD</text>
    <text y={26} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={30} letterSpacing={2} fill={INK}>{badge}</text>
    <line x1={-34} y1={44} x2={34} y2={44} stroke={INK} strokeWidth={2} />
  </g>
);

const Flag = ({x, y}) => (
  <g transform={`translate(${x},${y})`}>
    {/* a flag folded into a triangle: three visible bands, the canton's stars in one corner */}
    <path d="M-150,44 L150,44 L0,-104 Z" fill={PAPER} />
    <path d="M-150,44 L150,44 L0,-104 Z" fill="none" stroke={PAPER} strokeWidth={3} />
    <path d="M-96,20 L96,20 L0,-62 Z" fill="none" stroke={INK} strokeWidth={2.4} opacity={0.7} />
    <path d="M-46,20 L46,20 L0,-18 Z" fill="none" stroke={INK} strokeWidth={2} opacity={0.5} />
    <path d="M-150,44 L-72,44 L-96,6 Z" fill={INK} opacity={0.16} />
    {Array.from({ length: 9 }, (_, i) => (
      <circle key={i} cx={-132 + (i % 3) * 20 + Math.floor(i / 3) * 6} cy={30 - Math.floor(i / 3) * 16} r={2.2} fill={INK} opacity={0.7} />
    ))}
  </g>
);

export const S12_EndOfWatch = ({name = 'J. OKAFOR', badge = '4417', week = 23, years = 9, showSlots = false, slots = []}) => {
  const f = useCurrentFrame();

  return (
    <Scene len={240} note="LINE OF DUTY" right="" slugColor="#8b8b86" bed="amb_office" bedVol={0.16}
      tone={INK} fadeTone={INK} grid={false} showSlots={showSlots} slots={slots}>
      <AbsoluteFill style={{background: 'transparent'}}>
        <svg width={1920} height={1080} style={{position: 'absolute'}}>
          {/* the desk's edge, printed as two pale rules */}
          <line x1={0} y1={128} x2={1920} y2={128} stroke={PAPER} strokeWidth={1.4} opacity={0.18} />
          <line x1={0} y1={940} x2={1920} y2={940} stroke={PAPER} strokeWidth={1.4} opacity={0.18} />

          <text x={960} y={196} textAnchor="middle" fontFamily={FONT.caps} fontSize={20} letterSpacing={16} fill={PAPER} opacity={0.6}>
            PORT CARRICK POLICE DEPARTMENT
          </text>

          {/* the notice, typed on a card */}
          <g opacity={prog(f, 20, 40)}>
            <rect x={600} y={260} width={720} height={420} fill={PAPER} stroke={PAPER} strokeWidth={2} transform="rotate(-0.6 960 470)" />
            <text x={960} y={330} textAnchor="middle" fontFamily={FONT.caps} fontSize={19} letterSpacing={10} fill={INK} opacity={0.75}>
              NOTICE OF THE CHIEF
            </text>
            <line x1={650} y1={352} x2={1270} y2={352} stroke={INK} strokeWidth={2} opacity={0.5} />
            <text x={960} y={430} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={30} letterSpacing={12} fill={INK}>
              END OF WATCH
            </text>
            <text x={960} y={504} textAnchor="middle" fontFamily={FONT.caps} fontWeight={600} fontSize={64} letterSpacing={3} fill={INK}>
              {String(name).toUpperCase()}
            </text>
            <text x={960} y={558} textAnchor="middle" fontFamily={FONT.type} fontSize={26} fill={INK}>
              BADGE {badge} · {years} YEARS OF SERVICE
            </text>
            <line x1={650} y1={590} x2={1270} y2={590} stroke={INK} strokeWidth={2} opacity={0.5} />
            <text x={960} y={630} textAnchor="middle" fontFamily={FONT.type} fontSize={22} fill={INK} opacity={0.8}>
              WEEK {week} · THE DEPARTMENT WILL NOT FORGET THE SHIFT
            </text>
            {/* the one red rule on the page */}
            <rect x={650} y={648} width={Math.max(0, 620 * prog(f, 150, 190))} height={6} fill={C.red} />
          </g>

          {/* the badge, on the desk beside the notice */}
          <g opacity={prog(f, 56, 76)} transform={`translate(${(1 - prog(f, 56, 76)) * 40},0)`}>
            <Badge x={430} y={590} badge={badge} />
          </g>
          {/* the flag */}
          <g opacity={prog(f, 74, 94)}>
            <Flag x={1490} y={620} />
          </g>

          {/* the roster line: the name in the order it now sits */}
          <g opacity={prog(f, 168, 184)}>
            <text x={960} y={882} textAnchor="middle" fontFamily={FONT.type} fontSize={20} fill={PAPER} opacity={0.5}>
              {`WEEK ${week} · ${String(name).toUpperCase()} · BADGE ${badge} · STRUCK FROM THE ROSTER`}
            </text>
          </g>
        </svg>
      </AbsoluteFill>

      <Sfx name="toll" at={16} volume={0.75} />
      <Sfx name="toll" at={150} volume={0.6} />
      <Sfx name="click" at={56} volume={0.25} />
      <Sfx name="click" at={74} volume={0.25} />
      <Sfx name="stamp" at={168} volume={0.45} />
    </Scene>
  );
};
