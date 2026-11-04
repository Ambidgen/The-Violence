/** @jsxImportSource @revideo/2d/lib */
import {Circle, Img, Line, Node, Rect, Txt, makeScene2D} from '@revideo/2d';
import {all, createRef, waitFor} from '@revideo/core';
import city from '../media/city-art.jpg';
import operation from '../media/game-operation.jpg';

const P = '#eee9dc', INK = '#1c1d1a', RED = '#b43133', MUTED = '#787a72';
const Head = (props: any) => <Txt fontFamily="CarrickOswald" fontWeight={600} fill={INK} {...props}/>;
const Type = (props: any) => <Txt fontFamily="CarrickType" fill={INK} {...props}/>;

export default makeScene2D('plan', function* (view) {
  view.fill(P);
  const first = createRef<Node>();
  const firstCopy = createRef<Node>();
  const secondCopy = createRef<Node>();
  const action = createRef<Node>();
  const consequence = createRef<Node>();
  const end = createRef<Node>();
  const route1 = createRef<Line>();
  const route2 = createRef<Line>();
  const actor1 = createRef<Circle>();
  const actor2 = createRef<Circle>();

  view.add(<>
    <Node ref={first}>
      <Rect width={1280} height={720} fill={P}/>
      {Array.from({length:33}, (_, i) => <Line points={[[i*40-640,-360],[i*40-640,360]]} stroke="#d1cbbd" lineWidth={1} opacity={.4}/>)}
      {Array.from({length:19}, (_, i) => <Line points={[[-640,i*40-360],[640,i*40-360]]} stroke="#d1cbbd" lineWidth={1} opacity={.4}/>)}
      <Type x={-565} y={-313} offsetX={-1} fontSize={17} text="PORT CARRICK  /  OPERATIONS DIVISION"/>
      <Type x={565} y={-313} offsetX={1} fontSize={16} text="FILE 02  /  THE PLAN"/>
      <Line points={[[-565,-283],[565,-283]]} stroke={INK} lineWidth={2}/>
      <Node ref={firstCopy} opacity={0}>
        <Type x={-558} y={-197} offsetX={-1} fontSize={18} fill={RED} text="01  /  BEFORE THE DOOR"/>
        <Head x={-560} y={-70} offsetX={-1} fontSize={78} lineHeight={82} text={'YOU DRAW\nTHE PLAN.'}/>
        <Type x={-558} y={100} offsetX={-1} fontSize={20} text={'Information is imperfect.\nThe decision is yours.'}/>
      </Node>
      <Node ref={secondCopy} opacity={0}>
        <Type x={-558} y={-197} offsetX={-1} fontSize={18} fill={RED} text="02  /  YOUR ORDERS"/>
        <Head x={-560} y={-70} offsetX={-1} fontSize={78} lineHeight={82} text={'CHOOSE\nYOUR TEAM.'}/>
        <Type x={-558} y={100} offsetX={-1} fontSize={20} text={'Assign officers. Set the route.\nThen let it play out.'}/>
      </Node>
      <Rect x={235} y={24} width={584} height={376} fill="#d9d7ce" stroke={INK} lineWidth={7}/>
      <Rect x={235} y={123} width={576} height={168} fill="#c7c6bc"/>
      <Line points={[[28,-164],[28,-32]]} stroke={INK} lineWidth={8}/>
      <Line points={[[28,24],[28,108]]} stroke={INK} lineWidth={8}/>
      <Line points={[[28,153],[28,210]]} stroke={INK} lineWidth={8}/>
      <Line points={[[28,23],[154,23]]} stroke={INK} lineWidth={8}/>
      <Line points={[[208,23],[521,23]]} stroke={INK} lineWidth={8}/>
      <Line points={[[310,-164],[310,-102]]} stroke={INK} lineWidth={8}/>
      <Line points={[[310,-46],[310,23]]} stroke={INK} lineWidth={8}/>
      <Type x={-14} y={160} fontSize={16} fill={MUTED} text="ENTRY"/>
      <Type x={168} y={-92} fontSize={16} fill={MUTED} text="LIVING"/>
      <Type x={413} y={-92} fontSize={16} fill={MUTED} text="BEDROOM"/>
      <Type x={368} y={130} fontSize={16} fill={MUTED} text="HALL"/>
      <Line ref={route1} end={0} points={[[-105,146],[-23,146],[-23,-50],[169,-50],[169,-105],[387,-105]]} stroke={RED} lineWidth={5} endArrow arrowSize={12}/>
      <Line ref={route2} end={0} points={[[-105,146],[-23,146],[-23,111],[201,111],[373,111]]} stroke={RED} lineWidth={4} endArrow arrowSize={10}/>
      <Circle ref={actor1} x={-105} y={146} size={22} fill={INK} stroke={P} lineWidth={3}/>
      <Circle ref={actor2} x={-125} y={165} size={22} fill={INK} stroke={P} lineWidth={3}/>
      <Type x={-555} y={304} offsetX={-1} fontSize={16} text="THE VIOLENCE  /  A TACTICAL COMMAND AUTOBATTLER"/>
      <Rect x={439} y={303} width={240} height={42} stroke={RED} lineWidth={3}/>
      <Head x={439} y={303} fontSize={18} fill={RED} text="ORDERS ARE NOT OUTCOMES"/>
    </Node>
    <Node ref={action} opacity={0}>
      <Rect width={1280} height={720} fill="#242825"/>
      <Img src={operation} x={216} y={-4} width={800} height={450} rotation={-1}/>
      <Rect x={216} y={-4} width={800} height={450} stroke="#e6e0ce" lineWidth={4} rotation={-1}/>
      <Rect x={-381} y={-10} width={470} height={486} fill="#1a1c19"/>
      <Type x={-565} y={-202} offsetX={-1} fontSize={17} fill="#e6e0ce" text="03  /  HANDS OFF"/>
      <Head x={-565} y={-70} offsetX={-1} fontSize={71} lineHeight={78} fill={P} text={'WATCH IT\nUNFOLD.'}/>
      <Line points={[[-565,49],[-300,49]]} stroke={RED} lineWidth={5}/>
      <Type x={-565} y={119} offsetX={-1} fontSize={19} fill="#e6e0ce" text={'The simulation carries\nyour orders into the room.'}/>
      <Type x={-560} y={296} offsetX={-1} fontSize={15} fill="#e6e0ce" text="IN-GAME CAPTURE  /  WORK IN PROGRESS"/>
    </Node>
    <Node ref={consequence} opacity={0}>
      <Img src={city} width={1280} height={720}/>
      <Rect width={1280} height={720} fill="#121413" opacity={.75}/>
      <Type x={-560} y={-258} offsetX={-1} fontSize={18} fill="#e7e1d3" text="04  /  AFTER THE OPERATION"/>
      <Head x={-560} y={-65} offsetX={-1} fontSize={89} lineHeight={94} fill={P} text={'THE OUTCOME\nFOLLOWS YOU.'}/>
      <Line points={[[-560,89],[102,89]]} stroke={RED} lineWidth={5}/>
      <Type x={-558} y={152} offsetX={-1} fontSize={21} fill="#e7e1d3" text="THE DEPARTMENT  /  THE CITY  /  THE ELECTION"/>
      <Type x={-558} y={300} offsetX={-1} fontSize={15} fill="#e7e1d3" text="CONCEPT ART  /  TRAILER PROTOTYPE"/>
    </Node>
    <Node ref={end} opacity={0}>
      <Rect width={1280} height={720} fill={P}/>
      <Type y={-175} fontSize={19} text="PORT CARRICK  /  FORTY WEEKS"/>
      <Txt y={-40} text="THE VIOLENCE" fontFamily="CarrickHand" fontSize={135} fill={INK}/>
      <Line points={[[-352,43],[352,38]]} stroke={RED} lineWidth={7}/>
      <Head y={98} fontSize={26} text="A TACTICAL COMMAND AUTOBATTLER"/>
      <Type y={238} fontSize={17} fill={MUTED} text="EARLY ACCESS  •  TRAILER PROTOTYPE"/>
    </Node>
  </>);
  // Total duration is 20 seconds. Each scene is authored in Revideo's own timeline.
  yield* all(firstCopy().opacity(1,.35), route1().end(1,2.7), actor1().x(-23,2.7));
  yield* waitFor(.5);
  yield* all(firstCopy().opacity(0,.2), secondCopy().opacity(1,.2));
  yield* all(route2().end(1,2.0), actor2().x(150,2.0));
  yield* waitFor(1.55);
  yield* all(first().opacity(0,.3), action().opacity(1,.3));
  yield* waitFor(4.25);
  yield* all(action().opacity(0,.3), consequence().opacity(1,.3));
  yield* waitFor(3.9);
  yield* all(consequence().opacity(0,.35), end().opacity(1,.35));
  yield* waitFor(3.95);
});
