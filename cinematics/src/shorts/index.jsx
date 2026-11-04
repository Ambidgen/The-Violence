// The short cutscenes, as Remotion compositions. Metadata lives in registry.js.
import React from 'react';
import {Composition} from 'remotion';
import {SHORTS} from './registry.js';
import {S01_WeekCard} from './S01_WeekCard.jsx';
import {S02_Situation} from './S02_Situation.jsx';
import {S03_Plan} from './S03_Plan.jsx';
import {S04_Staging} from './S04_Staging.jsx';
import {S05_Threshold} from './S05_Threshold.jsx';
import {S06_OfficerDown} from './S06_OfficerDown.jsx';
import {S07_Debrief} from './S07_Debrief.jsx';
import {S08_Press} from './S08_Press.jsx';
import {S09_Case} from './S09_Case.jsx';
import {S10_Ally} from './S10_Ally.jsx';
import {S11_Election} from './S11_Election.jsx';
import {S12_EndOfWatch} from './S12_EndOfWatch.jsx';
import {S13_Allocation} from './S13_Allocation.jsx';
import {S14_Course} from './S14_Course.jsx';

export const SHORT_COMPONENTS = {
  'S01-Week': S01_WeekCard,
  'S02-Situation': S02_Situation,
  'S03-Plan': S03_Plan,
  'S04-Staging': S04_Staging,
  'S05-Threshold': S05_Threshold,
  'S06-OfficerDown': S06_OfficerDown,
  'S07-Debrief': S07_Debrief,
  'S08-Press': S08_Press,
  'S09-Case': S09_Case,
  'S10-Ally': S10_Ally,
  'S11-Election': S11_Election,
  'S12-EndOfWatch': S12_EndOfWatch,
  'S13-Allocation': S13_Allocation,
  'S14-Course': S14_Course,
};

export const ShortsRoot = () => (
  <>
    {SHORTS.map((s) => {
      const C = SHORT_COMPONENTS[s.id];
      if (!C) return null;
      return (
        <Composition
          key={s.id}
          id={s.id}
          component={C}
          durationInFrames={s.frames}
          fps={30}
          width={1920}
          height={1080}
          defaultProps={s.defaultProps}
        />
      );
    })}
  </>
);
