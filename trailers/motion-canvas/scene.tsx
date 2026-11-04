/** @jsxImportSource @motion-canvas/2d/lib */
import {Img, Line, Node, Rect, Txt, makeScene2D} from '@motion-canvas/2d';
import {all, createRef, createSignal, waitFor} from '@motion-canvas/core';
import boardImage from '../media/game-board.jpg';
import briefingImage from '../media/game-briefing.jpg';
import cityImage from '../media/city-art.jpg';

const P='#eee9dc', INK='#1b1c19', RED='#b43133', MID='#8f8d84';
const Head=(props:any)=><Txt fontFamily="CarrickOswald" fontWeight={600} fill={INK} {...props}/>;
const Type=(props:any)=><Txt fontFamily="CarrickType" fill={INK} {...props}/>;

export default makeScene2D(function* (view) {
  view.fill(P);
  const intro=createRef<Node>(), desk=createRef<Node>(), plan=createRef<Node>(), cost=createRef<Node>(), end=createRef<Node>();
  const count=createSignal(0), bars=createSignal(0);
  const board=createRef<Img>(), briefing=createRef<Img>();
  view.add(<>
    <Node ref={intro} opacity={0}>
      <Rect width={1280} height={720} fill={P}/>
      <Type x={-560} y={-306} offsetX={-1} fontSize={16} text="THE VIOLENCE  /  PORT CARRICK"/>
      <Type x={560} y={-306} offsetX={1} fontSize={16} text="THE CAMPAIGN CLOCK"/>
      <Line points={[[-560,-281],[560,-281]]} stroke={INK} lineWidth={2}/>
      <Txt x={-376} y={-60} text={()=>String(Math.round(count())).padStart(2,'0')} fontFamily="CarrickOswald" fontWeight={600} fontSize={260} fill={RED}/>
      <Head x={-230} y={-110} offsetX={-1} fontSize={67} lineHeight={72} text={'WEEKS TO\nTHE ELECTION.'}/>
      <Type x={-225} y={37} offsetX={-1} fontSize={20} text={'One city. One department.\nA new decision every week.'}/>
      {Array.from({length:40},(_,i)=><Rect x={-530+(i%20)*56} y={164+Math.floor(i/20)*55} width={41} height={35} fill={()=>i<count()?RED:'#d4d0c5'} stroke={INK} lineWidth={1}/>)}
      <Type x={-560} y={302} offsetX={-1} fontSize={16} text="01  /  THE CLOCK STARTS NOW"/>
    </Node>
    <Node ref={desk} opacity={0}>
      <Rect width={1280} height={720} fill="#202421"/>
      <Img ref={board} src={boardImage} x={235} y={-5} width={760} height={428} rotation={1.2}/>
      <Rect x={235} y={-5} width={760} height={428} stroke={P} lineWidth={5} rotation={1.2}/>
      <Rect x={-381} width={478} height={720} fill="#202421"/>
      <Type x={-560} y={-251} offsetX={-1} fontSize={17} fill={P} text="02  /  THE DESK"/>
      <Head x={-560} y={-93} offsetX={-1} fontSize={77} lineHeight={82} fill={P} text={'RUN THE\nDEPARTMENT.'}/>
      <Line points={[[-560,39],[-282,39]]} stroke={RED} lineWidth={5}/>
      <Type x={-560} y={108} offsetX={-1} fontSize={20} fill={P} text={'Choose calls. Manage\nthe people and the budget.'}/>
      <Type x={-560} y={300} offsetX={-1} fontSize={15} fill={P} text="IN-GAME BOARD CAPTURE"/>
    </Node>
    <Node ref={plan} opacity={0}>
      <Rect width={1280} height={720} fill={P}/>
      <Type x={-560} y={-306} offsetX={-1} fontSize={16} text="03  /  THE OPERATION"/>
      <Type x={560} y={-306} offsetX={1} fontSize={16} text="IN-GAME BRIEFING CAPTURE"/>
      <Line points={[[-560,-281],[560,-281]]} stroke={INK} lineWidth={2}/>
      <Head x={-560} y={-102} offsetX={-1} fontSize={70} lineHeight={74} text={'MAKE A PLAN.\nTHEN LET GO.'}/>
      <Type x={-560} y={70} offsetX={-1} fontSize={20} text={'Give the orders.\nWatch the operation resolve.'}/>
      <Img ref={briefing} src={briefingImage} x={275} y={0} width={650} height={366} rotation={-1.4}/>
      <Rect x={275} y={0} width={650} height={366} stroke={INK} lineWidth={5} rotation={-1.4}/>
      <Line points={[[-560,155],[-355,155]]} stroke={RED} lineWidth={5}/>
      <Type x={-560} y={302} offsetX={-1} fontSize={16} text="ORDERS AREN'T GUARANTEES."/>
    </Node>
    <Node ref={cost} opacity={0}>
      <Img src={cityImage} width={1280} height={720}/>
      <Rect width={1280} height={720} fill="#101310" opacity={.82}/>
      <Type x={-560} y={-275} offsetX={-1} fontSize={17} fill={P} text="04  /  THE CONSEQUENCES"/>
      <Head x={-560} y={-130} offsetX={-1} fontSize={71} lineHeight={76} fill={P} text={'EVERY WEEK\nLEAVES A MARK.'}/>
      <Type x={-560} y={35} offsetX={-1} fontSize={20} fill={P} text="THE CITY REMEMBERS WHAT HAPPENED."/>
      {['COMMUNITY TRUST','THE DEPARTMENT','PUBLIC SCRUTINY'].map((label,i)=><Node y={123+i*53}>
        <Type x={-557} offsetX={-1} fontSize={17} fill={P} text={label}/>
        <Line points={[[ -290,0 ],[ 372,0 ]]} stroke="#b0afa2" lineWidth={3} opacity={.4}/>
        <Line points={()=>[[ -290,0 ],[ -290+(530-i*85)*bars(),0 ]]} stroke={RED} lineWidth={6}/>
      </Node>)}
      <Type x={-560} y={300} offsetX={-1} fontSize={15} fill={P} text="CONCEPT ART  /  ILLUSTRATIVE GRAPHIC"/>
    </Node>
    <Node ref={end} opacity={0}>
      <Rect width={1280} height={720} fill="#161916"/>
      <Type y={-190} fontSize={18} fill={P} text="FORTY WEEKS  /  PORT CARRICK"/>
      <Txt y={-41} fontFamily="CarrickHand" fontSize={134} text="THE VIOLENCE" fill={P}/>
      <Line points={[[-351,47],[350,41]]} stroke={RED} lineWidth={7}/>
      <Head y={105} fontSize={27} fill={P} text="A TACTICAL COMMAND AUTOBATTLER"/>
      <Type y={242} fontSize={17} fill="#c8c2b6" text="EARLY ACCESS  •  TRAILER PROTOTYPE"/>
    </Node>
  </>);
  yield* all(intro().opacity(1,.3),count(40,2.6));
  yield* waitFor(.65);
  yield* all(intro().opacity(0,.3),desk().opacity(1,.3));
  yield* all(board().scale(1.045,3.8));
  yield* all(desk().opacity(0,.3),plan().opacity(1,.3));
  yield* all(briefing().scale(1.035,3.8));
  yield* all(plan().opacity(0,.3),cost().opacity(1,.3));
  yield* all(bars(1,2.2));
  yield* waitFor(1.8);
  yield* all(cost().opacity(0,.35),end().opacity(1,.35));
  yield* waitFor(3.9);
});
