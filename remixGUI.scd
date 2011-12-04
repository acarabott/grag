(
var window,track,width,height,bGround,imageUrl,mouse,xSegs,ySegs,view,x,y,drawLoop,glitch=2,clock,playSynth;
~track="Japanese";
//View
~data=CSVFileReader.read("sounds/"++~track++".ena");
~bpm=~data[0][0].asFloat;
[~bpm.postln,~bpm.class].postln;
height=Window.screenBounds.height;
width=Window.screenBounds.width;
window= SCWindow.new("Louis and Arthurs Remix of "++~track,Rect(200,0,width,height)).front;
view=window.view;
view.enabled_(true);
view.visible_(true);
//Movie Player
~moviePlayer=SCMovieView(window,Rect(width/4,height/4,width/2,height/2));
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.path_("sounds/"++~track++".mp4").muted_(true).editable_(true);
//Mouse Interaction
xSegs=8;
ySegs=8;
mouse=Synth(\mouse);
OSCresponder(s.addr,'mouse',{arg time,responder,msg;
	x=(msg[3]*xSegs).floor;
	y=(msg[4]*ySegs).floor;
	//[x,y].postln;
	}).add;

//Movie Glitch	
OSCresponder(s.addr,'glitch',{arg time,responder,msg;
	//msg.postln;
	~setMovieTime.value(msg[3]/44100);
}).add;

~setMovieTime={arg pos;
{
	~moviePlayer.currentTime_(pos);
}.fork(AppClock);
};
//Music!!!
clock=TempoClock(~bpm/60);
~beatLength=(1/(~bpm/60)); 
{
~buf=MP3.readToBuffer(s,"sounds/"++~track++".mp3");
~buses=Array.fill(4,{Bus.audio(s,2)});
~buffer=Array.fill(8,{arg i;Buffer.read(s,"sounds/breaks/BREAK"++(i+1)++".aif")});
1.wait;
s.latency=0;
//Layer effects
~playSynth=Synth(\hackPlay,[\bufnum,~buf,\outBus,~buses[0]]);
~filterSynth=Synth.after(~playSynth, \hackHPFilter,[\outBus,~buses[1],\inBus,~buses[0],\mix,0]);
//~filterSynth.set(\mix,0,\freq,1000);
~revSynth=Synth(\hackRev,[\outBus,~buses[2],\inBus,~buses[1],\mix,0,\room,1,\damp,1,\revMix,1]);
//~revSynth.set(\mix,1)
~outSynth=Synth(\hackOut,[\inBus,~buses[2]]);
~moviePlayer.start;
~data[3][0].split($:)[0].asFloat.wait;

~newBar={
	~break=Synth(\hackPlay,[\bufnum,~buffer[7.0.rand.floor],\rate,(~bpm/96)]);
};

~startTrig={
	if(0.5.coin,{
	~retrigRate.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),[2,-2,-0.5].choose,~playSynth);
	},{
	~retrig.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),~playSynth);
	});
};
~stopTrig={
	~trigFunc.stop;
};

~newBeat={
	~stopTrig.value;
	//~break.set(\t_trig,1,\startPos,((~beatCtr%4))*~beatLength*44100);
	~playSynth.set(\rate,1,\t_trig,1,\startPos,~targetTime[1]*44100);
	~revSynth.set(\mix,0);
	~filterSynth.set(\mix,0);
	if(~beatCtr%4==0,{~newBar.value});
	if(0.35.coin,{~startTrig.value});
	if(0.2.coin,{~revSynth.set(\mix,1)});
	//~breakcore.value;
	//if(0.1.coin,{~filterSynth.set(\mix,1)});
};

~breakcore={
if(0.6.coin,{
	if(0.5.coin,{
	~retrigRate.value([2,4,8,16,32].choose,[2,-2,-0.5].choose,~break);
	},{
	~retrig.value([2,4,8,16,32].choose,[1,2,3,4].choose,~break);
	});
});
};

//Timing
~barCtr=0;
~beatCtr=0;
~targetTime=[~data[2][~barCtr].split($:)[0].asFloat,~data[3][~beatCtr].split($:)[0].asFloat];
~startTime=Main.elapsedTime;
{inf.do{
	if((Main.elapsedTime-~startTime)>~targetTime[0],{
		//"BAR".postln;
		//Synth(\bleep);
		//~newBar.value;
		~barCtr=~barCtr+1;
		~targetTime[0]=~data[2][~barCtr].split($:)[0].asFloat;
	});
	if((Main.elapsedTime-~startTime)>~targetTime[1],{
		//"BEAT".postln;
		//Synth(\bleep);
		~newBeat.value;
		~beatCtr=~beatCtr+1;
		~targetTime[1]=~data[3][~beatCtr].split($:)[0].asFloat;
	});
	//[~targetTime,(Main.elapsedTime-~startTime)].postln;
	(0.01).wait;
}}.fork;

}.fork(AppClock);

//Effect Functions

~retrig={arg rate,trackBuffer;
	~trigFunc={inf.do{
		//["retrig",~buf.sampleRate*beatLength*(beatPos+randPos)].postln;
		trackBuffer.set(\t_trig,1,\startPos,~buf.sampleRate*~beatLength*(~beatCtr));
		(1/rate).wait;
	}}.fork(clock);
};
~retrigRate={arg rate,target,trackBuffer;
	var increment;
	increment=target/rate;
	~trigFunc={inf.do{arg i;
		//["retrig",~buf.sampleRate*beatLength*(beatPos+randPos)].postln;
		trackBuffer.set(\t_trig,1,\startPos,~buf.sampleRate*~beatLength*(~beatCtr),\rate,1+(increment*i));
		(1/rate).wait;
	}}.fork(clock);
};

//Buttons!
~buttons=List.new(0);

~buttons.add(SCUserView(window,Rect(0,0,50,50)));
~buttons[0].background_(Color.green);
~buttons[0].mouseDownAction_({
	"mouse down".postln;
	if(0.5.coin,{
		~retrigRate.value([2,4,8,16,32].choose,(rrand(0,4)),[2,-2,-0.5].choose);
		},{
		~retrig.value([2,4,8,16,32].choose,(rrand(0,4)));
		});
});
~buttons[0].mouseUpAction_({
	"mouse up".postln;
	~playSynth.set(\rate,1);
	~trigFunc.stop;
	});
	
~buttons.add(SCUserView(window,Rect(50,50,50,50)));
~buttons[1].background_(Color.blue);
~buttons[1].mouseDownAction_({
	"mouse down".postln;
	~note=[50,60,70,80,90].choose;
	~wobble=Synth(\hackWobble,[\freq,~note,\bpm,~bpm]);
	~wobble2=Synth(\hackWobble,[\freq,~note*2,\bpm,~bpm]);
	~playSynth.set(\amp,0.2);
	~break.set(\amp,0.2);
});
~buttons[1].mouseUpAction_({
	"mouse up".postln;
	~wobble.free;
	~wobble2.free;
	~playSynth.set(\amp,1);
	});
	
)



~retrigBreak={arg rate,randPos,dur;
	~trigFunc={rate.do{
		~break.set(\t_trig,1,\startPos,0);
		(dur/rate).wait;
	}}.fork(clock);
};
~retrigRateBreak={arg rate,randPos,target,dur;
	var increment;
	"trig".postln;
	increment=target/rate;
	~trigFunc={rate.do{arg i;
		~break.set(\t_trig,1,\startPos,0,\rate,1+(increment*i));
		(dur/rate).wait;
	}}.fork(clock);
};

(
//Effect Functions
~retrig={arg rate,randPos,dur;
	~trigFunc={rate.do{
		~break.set(\t_trig,1,\startPos,0);
		(dur/rate).wait;
	}}.fork(~clock);
};
~retrigRate={arg rate,randPos,target,dur;
	var increment;
	"trig".postln;
	increment=target/rate;
	~trigFunc={rate.do{arg i;
		~break.set(\t_trig,1,\startPos,0,\rate,1+(increment*i));
		(dur/rate).wait;
	}}.fork(~clock);
};
//BreakCOORRRE	
~buffer=Array.fill(8,{arg i;Buffer.read(s,"sounds/breaks/BREAK"++(i+1)++".aif")});
~clock=TempoClock(192/60);
{inf.do{
	~break=Synth(\hackPlay,[\bufnum,~buffer[7.0.rand.floor],\rate,2]);
	{4.do{
		if(0.6.coin,{
			if(0.5.coin,{
			~retrigRate.value([2,4,8,16,32].choose,(rrand(0,4)),[2,-2,-0.5].choose,[1,2,3,4].choose);
			},{
			~retrig.value([2,4,8,16,32].choose,(rrand(0,4)),[1,2,3,4].choose);
			});
		});
		1.wait;
	}}.fork(~clock);
	4.wait;
}}.fork(~clock)
)
)
Synth
Warp
Quarks.gui

//;
(
SynthDef(\mouse,{
	SendReply.kr(Impulse.kr(20),'mouse',
	values:[MouseX.kr(0,1),MouseY.kr(0,1)]
	)
	}).load(s);

SynthDef(\hackOut,{arg inBus;
	var sound;
	sound=InFeedback.ar(inBus,2);
	Out.ar([0,1],sound)
}).store;

SynthDef(\hackHPFilter,{arg outBus,inBus,freq=1500,q=10,mix=0.5;
	var sound,dry,wet;
	dry=InFeedback.ar(inBus,2);
	wet=HPF.ar(dry,freq);
	sound=Mix([dry*(1-mix),mix*wet]);
	Out.ar(outBus,sound);
}).store;

SynthDef(\hackPlay,{arg bufnum,amp=1,t_trig,rate=1,length=1,loop=1,startPos,outBus;
	var sound,env;
	env=EnvGen.ar(Env([1,1,0],[(BufFrames.kr(bufnum)/44100)*length,0]), doneAction:2);
	sound=PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*rate, t_trig, startPos,loop);
	SendReply.kr(t_trig,'glitch',startPos);
	Out.ar(outBus,sound*env*amp)
}).store;

SynthDef(\hackRev,{arg inBus,outBus,revMix=0,room=0,damp=0,mix=0.5;
	var sound,dry,wet;
	dry=InFeedback.ar(inBus,2);
	wet=FreeVerb.ar(dry,revMix,room,damp);
	sound=Mix([dry*(1-mix),mix*wet]);
	Out.ar(outBus,sound);
}).store;

)
SynthDef(\bleep,{
	Out.ar(0,SinOsc.ar(440)*Line.ar(1,1,0.1,doneAction:2));
}).store
LBuf.ar

Synth(

Pen
b=SCImage.new("http://images.zap2it.com/images/celeb-78725/bing-crosby-1.jpg");
b.plot("bing",0)
(
w = Window("", Rect(0, 0, 480, 380)).front;
{inf.do{
w.view.background_(Color.red(rrand(0.0, 1), rrand(0.0, 0.5)));
0.1.wait;
}}.fork(AppClock);
)
w.view.mouseMove();
m = SCMovieView(w, Rect(0,0,480, 360)); Ê Ê
m.showControllerAndAdjustSize(false, false);
m.path_("sounds/scale.mp4");
//drawLoop=
//{inf.do{
//	//window.drawHook_({
//		//bGround.drawInRect(Rect(0,0,width,height));
//		window.view.background_(Color.red(rrand(0.0, 1), rrand(0.0, 0.5)));
//		//Pen.color=Color(255,0,0,100);
////		//Pen.addRect(Rect(width/xSegs,height/ySegs,x*(width/xSegs),y*(width/ySegs)));
////		Pen.addRect(Rect(100,100,x*(width/xSegs),y*(width/ySegs)));
////		Pen.perform([\stroke, \fill].choose);
//	//});
//	0.1.wait;
//}}.fork(AppClock);