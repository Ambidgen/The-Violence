import React from 'react';
import {Composition} from 'remotion';
import {C1_PortCarrick, C1_LEN} from './C1_PortCarrick.jsx';
import {C2_OutgoingChief, C2_LEN} from './C2_OutgoingChief.jsx';
import {C3_ThePlan, C3_LEN} from './C3_ThePlan.jsx';
import {C4_FortyWeeks, C4_LEN} from './C4_FortyWeeks.jsx';
import {ShortsRoot} from './shorts/index.jsx';

const common = {fps: 30, width: 1920, height: 1080};

// The opening, in order: the city, the office you inherit, how an operation goes, the forty weeks.
// Then the shorts: five-to-ten second interstitials the campaign can call on at any beat.
export const RemotionRoot = () => (
  <>
    <Composition id="C1-PortCarrick" component={C1_PortCarrick} durationInFrames={C1_LEN} {...common} />
    <Composition id="C2-OutgoingChief" component={C2_OutgoingChief} durationInFrames={C2_LEN} {...common} />
    <Composition id="C3-ThePlan" component={C3_ThePlan} durationInFrames={C3_LEN} {...common} />
    <Composition id="C4-FortyWeeks" component={C4_FortyWeeks} durationInFrames={C4_LEN} {...common} />
    <ShortsRoot />
  </>
);
