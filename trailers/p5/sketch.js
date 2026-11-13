// p5.js creative-coding treatment: a fictional dispatch console, not gameplay UI.
// The renderer calls drawTrailer(frame) deterministically; p5 handles every visual.
const sketch = p => {
  const W=1280,H=720, RED='#bf3d3e', PAPER='#eee8d8', DIM='#bcb7a8', AMBER='#caa16d';
  let city, board, election;
  p.preload=()=>{city=p.loadImage('../media/city-art.jpg');board=p.loadImage('../media/game-board.jpg');election=p.loadImage('../media/election-prototype.jpg');};
  p.setup=()=>{p.createCanvas(W,H);p.pixelDensity(1);p.noLoop();window.drawTrailer=drawTrailer;window.p5Ready=true;};
  const rect=(x,y,w,h,c)=>{p.noStroke();p.fill(c);p.rect(x,y,w,h);};
  const rule=(x1,y1,x2,y2,c=RED,weight=2)=>{p.stroke(c);p.strokeWeight(weight);p.line(x1,y1,x2,y2);p.noStroke();};
  const text=(s,x,y,size,c=PAPER,font='CarrickType',align=p.LEFT)=>{p.fill(c);p.noStroke();p.textFont(font);p.textSize(size);p.textAlign(align,p.BASELINE);p.text(s,x,y);};
  const back=(img,dark=.65)=>{p.image(img,0,0,W,H);rect(0,0,W,H,`rgba(11,15,14,${dark})`);};
  const grid=()=>{p.stroke('rgba(222,218,195,.08)');p.strokeWeight(1);for(let x=80;x<W;x+=64)p.line(x,78,x,650);for(let y=90;y<650;y+=64)p.line(60,y,1220,y);p.noStroke();};
  const chrome=(t,label)=>{
    text('P.C.P.D.  /  DISPATCH',62,48,16,PAPER);text(label,1218,48,15,DIM,'CarrickType',p.RIGHT);rule(62,65,1218,65,'rgba(238,232,216,.45)',1);
    text('THE VIOLENCE  /  RADIO SILENCE',62,684,15,DIM);text(`00:${String(Math.floor(t)).padStart(2,'0')}  /  00:20`,1218,684,15,DIM,'CarrickType',p.RIGHT);rule(62,654,1218,654,'rgba(238,232,216,.35)',1);rect(62,653,1156*Math.min(t/20,1),3,RED);
  };
  const pulse=(t,x,y,w,h)=>{
    rule(x,y,x+w,y,'rgba(238,232,216,.18)',1);
    for(let i=0;i<54;i++){
      let signal=Math.abs(Math.sin(i*.34+t*5.4)*Math.cos(i*.11-t*2.4));
      let bar=5+signal*(.18+.82*Math.abs(Math.sin(t*1.7)))*h;
      rect(x+i*(w/54),y-bar/2,3,bar,i%8===0?RED:AMBER);
    }
  };
  const fade=(t,start)=>Math.min(1,Math.max(0,(t-start)/.4));
  const withFade=(v,fn)=>{p.push();p.tint(255,255*v);p.drawingContext.globalAlpha=v;fn();p.pop();};
  function drawTrailer(frame){
    const t=frame/24;
    p.background('#171c19');p.noStroke();
    if(t<3.4){
      back(city,.8);grid();chrome(t,'CONCEPT ART  /  DISPATCH GRAPHIC');
      withFade(fade(t,0),()=>{
        text('INCOMING TRANSMISSION',76,151,18,AMBER);text('THE RADIO',72,253,92,PAPER,'CarrickOswald');text("DOESN'T STOP.",72,351,92,PAPER,'CarrickOswald');
        rule(76,379,450,379,RED,5);text('A CALL COMES IN. THE CLOCK KEEPS MOVING.',76,424,18,PAPER);
        rect(793,158,383,300,'rgba(15,20,18,.75)');p.noFill();p.stroke('rgba(238,232,216,.55)');p.rect(793,158,383,300);p.noStroke();
        text('CH 01  /  PORT CARRICK',821,200,17,PAPER);pulse(t,821,303,320,105);text('SIGNAL ACTIVE',821,408,16,AMBER);p.fill(RED);p.circle(1139,193,12);
      });
    } else if(t<6.8){
      back(board,.73);grid();chrome(t,'IN-GAME CAMPAIGN BOARD');
      withFade(fade(t,3.4),()=>{
        rect(58,139,555,345,'rgba(16,20,18,.9)');text('THE BOARD',81,184,18,AMBER);text('THE CALL',76,276,86,PAPER,'CarrickOswald');text('IS YOURS.',76,365,86,PAPER,'CarrickOswald');
        rule(80,391,393,391,RED,5);text('CHOOSE WHICH SITUATIONS TO ANSWER.',80,437,18,PAPER);
        p.noFill();p.stroke(RED);p.strokeWeight(3);p.circle(919,388,42+Math.sin(t*6)*10);p.circle(919,388,8);p.noStroke();
      });
    } else if(t<10.6){
      rect(0,0,W,H,'#191e1b');grid();chrome(t,'ILLUSTRATIVE TACTICAL GRAPHIC');
      withFade(fade(t,6.8),()=>{
        text('THE BRIEFING',78,154,18,AMBER);text('GIVE THE',75,249,88,PAPER,'CarrickOswald');text('ORDERS.',75,342,88,PAPER,'CarrickOswald');rule(78,372,365,372,RED,5);
        text('ASSIGN OFFICERS. SET THE ROUTE.',78,425,18,PAPER);text('THEN WATCH IT PLAY OUT.',78,457,18,PAPER);
        p.noFill();p.stroke('#d8d2bf');p.strokeWeight(5);p.rect(680,174,458,284);p.line(848,174,848,300);p.line(848,351,848,458);p.line(848,311,958,311);p.line(1010,311,1138,311);p.line(996,174,996,265);p.noStroke();
        text('ENTRY',700,429,15,DIM);text('HALL',904,405,15,DIM);text('ROOM',1040,238,15,DIM);
        const k=Math.min(1,Math.max(0,(t-7.0)/2.8));const pts=[[616,412],[750,412],[750,278],[918,278],[918,225],[1068,225]];
        let lengths=[];let len=0;for(let i=1;i<pts.length;i++){let d=p.dist(...pts[i-1],...pts[i]);lengths.push(d);len+=d;}let remaining=k*len;p.stroke(RED);p.strokeWeight(5);p.noFill();for(let i=1;i<pts.length;i++){let d=lengths[i-1],n=Math.min(1,Math.max(0,remaining/d));p.line(pts[i-1][0],pts[i-1][1],p.lerp(pts[i-1][0],pts[i][0],n),p.lerp(pts[i-1][1],pts[i][1],n));remaining-=d;if(n<1)break;}p.noStroke();
        p.fill(PAPER);p.circle(616,412,19);p.fill(RED);p.circle(616,412,9);
      });
    } else if(t<15.8){
      back(election,.7);grid();chrome(t,'VISUAL PROTOTYPE  /  ELECTION NIGHT');
      withFade(fade(t,10.6),()=>{
        text('AFTER THE OPERATION',76,155,18,AMBER);text('THE CITY',72,252,88,PAPER,'CarrickOswald');text('LIVES WITH IT.',72,346,88,PAPER,'CarrickOswald');rule(76,375,446,375,RED,5);
        text('TRUST. SCRUTINY. AN ELECTION.',76,421,19,PAPER);text('FORTY WEEKS TO MAKE YOUR MARK.',76,453,19,PAPER);
        rect(795,504,370,76,'rgba(12,16,14,.8)');pulse(t,820,543,318,44);
      });
    } else {
      back(city,.84);grid();chrome(t,'CONCEPT ART  /  TRAILER PROTOTYPE');
      withFade(fade(t,15.8),()=>{
        text('PORT CARRICK   /   FORTY WEEKS',640,215,18,AMBER,'CarrickType',p.CENTER);
        text('THE VIOLENCE',640,364,127,PAPER,'CarrickHand',p.CENTER);rule(286,395,994,390,RED,7);
        text('A TACTICAL COMMAND AUTOBATTLER',640,448,26,PAPER,'CarrickOswald',p.CENTER);
        text('EARLY ACCESS  •  WORK IN PROGRESS',640,516,17,DIM,'CarrickType',p.CENTER);
      });
    }
  }
};
new p5(sketch);
