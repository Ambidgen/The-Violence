// S09 · THE CASE. Eight seconds of internal affairs: the folder opens, the exhibit is
// circled, the name is redacted, the finding is stamped.
import React from 'react';
import {useCurrentFrame} from 'remotion';
import {C, FONT, prog, rnd, At, Scene, Sheet, Slam, Redact, Rule, Sfx, Kicker, Typer} from './kit.jsx';

const FINDING_TONE = {CLEARED: C.ink, SUSTAINED: C.red, REFERRED: C.red};

export const S09_Case = ({caseNo = 'IA 26-114', officer = 'J. OKAFOR', finding = 'SUSTAINED',
  summary = 'Force used after the subject was restrained. Body camera corroborates.', showSlots = false, slots = []}) => {
  const f = useCurrentFrame();
  const tone = FINDING_TONE[String(finding).toUpperCase()] || C.ink;
  const open = prog(f, 8, 34);

  const lines = Array.from({length: 13}, (_, i) => i);

  return (
    <Scene len={240} note="INTERNAL AFFAIRS" right="NOT A COURT" bed="amb_office" bedVol={0.24} showSlots={showSlots} slots={slots}>
      <Kicker at={6} style={{left: 96, top: 84, width: 460}}>CASE FILE</Kicker>
      <At at={10} from="left" style={{left: 96, top: 128, width: 470}}>
        <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 48, lineHeight: 1.04, letterSpacing: 2, color: C.ink}}>
          THE CASE<br />YOU LEAVE<br />BEHIND
        </div>
      </At>

      {/* the folder */}
      <Sheet x={640} y={128} w={1180} h={830} at={6} from="right" rot={0.5} border={6} fill={C.light} shadow={16} pad={0}>
        <div style={{position: 'relative', width: '100%', height: '100%', overflow: 'hidden'}}>
          {/* the tab */}
          <div style={{position: 'absolute', left: 54, top: 0, width: 320, height: 54, background: C.ink, color: C.paper,
            fontFamily: FONT.caps, fontSize: 20, letterSpacing: 5, display: 'flex', alignItems: 'center', paddingLeft: 18, boxSizing: 'border-box'}}>
            {String(caseNo).toUpperCase()}
          </div>
          <div style={{position: 'absolute', left: 54, top: 82, right: 372, bottom: 30, background: C.paper,
            border: `3px solid ${C.ink}`, transform: `translateY(${(1 - open) * 26}px)`, opacity: open}}>
            <div style={{padding: '26px 30px'}}>
              <div style={{display: 'flex', justifyContent: 'space-between', fontFamily: FONT.caps, fontSize: 16, letterSpacing: 5, color: C.mid}}>
                <span>OFFICE OF PROFESSIONAL STANDARDS</span>
                <span>EXHIBIT A · BODY CAMERA</span>
              </div>
              <Rule x={30} y={96} w={1010} at={26} h={2} opacity={0.6} />

              {/* the officer's name, typed, then partly redacted */}
              <At at={32} from="none" style={{left: 30, top: 122, width: 900}}>
                <div style={{fontFamily: FONT.caps, fontSize: 17, letterSpacing: 5, color: C.mid}}>SUBJECT OFFICER</div>
              </At>
              <At at={36} from="none" style={{left: 30, top: 148, width: 900}}>
                <div style={{fontFamily: FONT.caps, fontWeight: 600, fontSize: 54, letterSpacing: 3, color: C.ink}}>
                  {String(officer).toUpperCase()}
                </div>
              </At>

              {/* the typed body, with the redactions over it */}
              <svg width={1060} height={420} style={{position: 'absolute', left: 0, top: 236}}>
                {lines.map((i) => {
                  const y = i * 26 + 6;
                  const w = 380 + ((i * 137) % 300);
                  return <rect key={i} x={30} y={y} width={w} height={7} fill={C.light}
                    opacity={prog(f, 46 + i * 2, 52 + i * 2)} />;
                })}
                <Redact x={30} y={58} w={286} h={20} at={78} />
                <Redact x={186} y={162} w={250} h={20} at={88} />
                <Redact x={30} y={240} w={330} h={20} at={96} />
                <Redact x={470} y={266} w={228} h={20} at={104} />
                <Redact x={30} y={344} w={196} h={20} at={112} />

              </svg>
            </div>
          </div>

          {/* the exhibit photograph: the plan, the room circled */}
          <div style={{position: 'absolute', right: 34, top: 130, width: 300, height: 300, border: `4px solid ${C.ink}`,
            background: C.floor, opacity: prog(f, 60, 74)}}>
            <svg width={292} height={292}>
              <g stroke={C.ink} strokeWidth={9} fill="none">
                <path d="M26,40 H266 V250 H26 Z" />
                <path d="M26,150 H140 M26,150 V250" strokeWidth={6} />
              </g>
              <circle cx={196} cy={196} r={46} fill="none" stroke={C.red} strokeWidth={4} opacity={prog(f, 128, 140)} />
              <text x={196} y={264} textAnchor="middle" fontFamily={FONT.caps} fontSize={13} letterSpacing={3} fill={C.red}
                opacity={prog(f, 132, 142)}>THE ROOM</text>
              <text x={26} y={20} fontFamily={FONT.caps} fontSize={12} letterSpacing={3} fill={C.mid}>EXHIBIT B</text>
            </svg>
          </div>
        </div>
      </Sheet>

      {/* the summary, typed under the folder */}
      <At at={148} from="none" style={{left: 96, top: 560, width: 470}}>
        <div style={{fontFamily: FONT.type, fontSize: 23, lineHeight: 1.45, color: C.ink}}>
          {summary}
        </div>
      </At>

      <Slam lines={[String(finding).toUpperCase(), 'BY THE CHIEF']} at={170} x={1404} y={700} rot={-4} size={38} color={tone} vol={0.7} />
      <Sfx name="door" at={6} volume={0.45} />
      <Sfx name="click" at={32} volume={0.35} />
      {[78, 88, 96, 104, 112].map((at, i) => <Sfx key={i} name="click" at={at} volume={0.28} rate={0.96 + i * 0.02} />)}
      <Sfx name="stamp" at={170} volume={0.7} />
      <Sfx name="toll" at={214} volume={0.35} />
    </Scene>
  );
};
