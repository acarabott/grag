(
var window,track,width,height,bGround,imageUrl,mouse,xSegs,ySegs,view,x,y,drawLoop,glitch=2,clock,playSynth;
~track="Frisky";
//View
~data=CSVFileReader.read("sounds/"++~track++".ena");
height=Window.screenBounds.height;
width=Window.screenBounds.width;
window= SCWindow.new("Louis and Arthurs Remix of "++~track,Rect(200,0,width,height)).front;
view=window.view;
view.enabled_(true);
view.visible_(true);
//Movie Player
~moviePlayer=SCMovieView(window,Rect(width/4,height/4,width/2,height/2));
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.path_("sounds/"++~track++".m4v").muted_(true).editable_(true);
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
~data[3].postln;
~beatData=~data[3].collect({|item i|
var split=item.split($:);
split.postln;
if(split.size>1,{[split[0].asFloat/0.7,split[1].asFloat/0.7]});
});
~bpm=~data[0][0].asFloat*0.7;
clock=TempoClock(~bpm/60);
~beatLength=(1/(~bpm/60)); 
{
~buf=MP3.readToBuffer(s,"sounds/"++~track++".mp3");
~buses=Array.fill(4,{Bus.audio(s,2)});
~kick=Buffer.read(s,"sounds/single/kick.aif");
~snare=Buffer.read(s,"sounds/single/snare.WAV");
1.wait;
s.latency=0;
//Layer effects
~playSynth=Synth(\hackPlay,[\bufnum,~buf,\outBus,~buses[0],\rate,0.7]);
~filterSynth=Synth.after(~playSynth, \hackHPFilter,[\outBus,~buses[1],\inBus,~buses[0],\mix,0,]);
//~filterSynth.set(\mix,0,\freq,1000);
~revSynth=Synth(\hackRev,[\outBus,~buses[2],\inBus,~buses[1],\mix,0.6,\room,1,\damp,1,\revMix,1]);
//~revSynth.set(\mix,1)
~outSynth=Synth(\hackOut,[\inBus,~buses[2]]);
~moviePlayer.start.rate_(0.7);
~beatData[0].postln;
~stopTrig={
	~trigFunc.stop;
};

~newBeat={
	//if(~beatCtr%2==0,{~playSynth.set(\rate,0.7,\t_trig,1,\startPos,~targetTime*44100)});
	if(~beatCtr%4==0,{~kickSynth=Synth(\hackPlay,[\bufnum,~kick,\rate,0.85])});
	"BEAT".postln;
};
//Timing
~barCtr=0;
~beatCtr=0;
~startTime=Main.elapsedTime;
~targetTime=~beatData[0][0];
{inf.do{
	if((Main.elapsedTime-~startTime)>~targetTime,{
		~newBeat.value;
		~beatCtr=~beatCtr+1;
		~targetTime=~beatData[~beatCtr][0];
	});
	(0.01).wait;
}}.fork;

}.fork(AppClock);


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
	~wobble=Synth(\hackWobble,[\freq,[50,60,70,80,90].choose,\bpm,~bpm]);
	~playSynth.set(\amp,0.2);
});
~buttons[1].mouseUpAction_({
	"mouse up".postln;
	~wobble.free;
	~playSynth.set(\amp,1);
	});
)



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

SynthDef(\hackPlay,{arg bufnum,amp=1,t_trig,rate=1,length=1,loop=1,startPos,outBus=0;
	var sound,env;
	env=EnvGen.ar(Env([1,1,0],[(BufFrames.kr(bufnum)/44100)*length,0]), doneAction:2);
	sound=PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*rate, t_trig, startPos,loop);
	SendReply.kr(t_trig,'glitch',startPos);
	Out.ar(outBus,sound*env*amp)
}).store;

SynthDef(\hackMono,{arg bufnum,amp=1,t_trig,rate=1,length=1,loop=1,startPos,outBus=0;
	var sound,env;
	env=EnvGen.ar(Env([1,1,0],[(BufFrames.kr(bufnum)/44100)*length,0]), doneAction:2);
	sound=PlayBuf.ar(1, bufnum, BufRateScale.kr(bufnum)*rate, t_trig, startPos,loop);
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