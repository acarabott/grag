//Variables
~directory  = "path/toshit/";
~track      = "trackname";
~data       = CSVFileReader.read(~directory ++ "sounds/" ++ ~track ++ ".ena");
~bpm        = ~data[0][0].asFloat;
~clock      = TempoClock(~bpm/60);
~beatLength = (1 / (~bpm/60)); 
~barCtr     = 0;
~beatCtr    = 0;
~targetTime = [~data[2][~barCtr].split($:)[0].asFloat,~data[3][~beatCtr].split($:)[0].asFloat];
~startTime  = Main.elapsedTime;


s.waitForBoot {
{
    //SynthDefs
    SynthDef(\mouse,{
    	SendReply.kr(Impulse.kr(20),'mouse',
    	values:[MouseX.kr(0,1),MouseY.kr(0,1)]
    	)
    }).add;

    SynthDef(\hackOut,{arg inBus;
    	var sound;
    	sound=InFeedback.ar(inBus,2);
    	Out.ar([0,1],sound)
    }).add;

    SynthDef(\hackHPFilter,{arg outBus,inBus,freq=1500,q=10,mix=0.5;
    	var sound,dry,wet;
    	dry=InFeedback.ar(inBus,2);
    	wet=HPF.ar(dry,freq);
    	sound=Mix([dry*(1-mix),mix*wet]);
    	Out.ar(outBus,sound);
    }).add;

    SynthDef(\hackPlay,{arg bufnum,amp=1,t_trig,rate=1,length=1,loop=1,startPos,outBus;
    	var sound,env;
    	env=EnvGen.ar(Env([1,1,0],[(BufFrames.kr(bufnum)/44100)*length,0]), doneAction:2);
    	sound=PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*rate, t_trig, startPos,loop);
    	SendReply.kr(t_trig,'glitch',startPos);
    	Out.ar(outBus,sound*env*amp)
    }).add;

    SynthDef(\hackRev,{arg inBus,outBus,revMix=0,room=0,damp=0,mix=0.5;
    	var sound,dry,wet;
    	dry=InFeedback.ar(inBus,2);
    	wet=FreeVerb.ar(dry,revMix,room,damp);
    	sound=Mix([dry*(1-mix),mix*wet]);
    	Out.ar(outBus,sound);
    }).add;
    
    s.sync;
    //Buffers
    ~audioBuffer    = MP3.readToBuffer(s,"sounds/"++~track++".mp3");
    ~breakBuffers   = Array.fill(8, {arg i; Buffer.read(s,"sounds/breaks/BREAK"++(i+1)++".aif")});
    s.sync;
    //Busses
    ~busses = Array.fill(3, {Bus.audio(s,2)});
    
    s.sync;
    //Synths
    ~playSynth      = Synth(\hackPlay, [\bufnum, ~audioBuffer, \outBus, ~busses[0]]);
    ~filterSynth    = Synth.after(~playSynth, \hackHPFilter, [\outBus, ~busses[1], \inBus, ~busses[0], \mix, 0]);
    ~revSynth       = Synth.after(~filterSynth, \hackRev,[\outBus, ~busses[2], \inBus, ~busses[1], \mix, 0, \room, 1, \damp, 1, \revMix, 1]);
    ~outSynth       = Synth.after(~revSynth, \hackOut,[\inBus, ~busses[2]]);
    
}.fork;
}

//Responders
~movieResponder = OSCresponderNode(s.addr, 'glitch', {|t, r, msg| }).add;
~movieResponder.action_({|t, r, msg|
	~setMovieTime.value(msg[3]/44100);    
});

// Functions

~setMovieTime = {arg pos;
    {
	    ~moviePlayer.currentTime_(pos);
    }.fork(AppClock);
};

~newBar = {
	~breakSynth = Synth(\hackPlay, [\bufnum, ~breakBuffers[7.rand], \rate, (~bpm / 96)]);
};

~startTrig={
	if(0.5.coin, {
    	~retrigRate.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),[2,-2,-0.5].choose,~playSynth);
	},{
    	~retrig.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),~playSynth);
	});
};

~stopTrig={
	~trigFunc.stop;
};

~newBeat = {
	~stopTrig.value;
	~playSynth.set(\rate,1,\t_trig,1,\startPos,~targetTime[1]*44100);
	~revSynth.set(\mix,0);
	~filterSynth.set(\mix,0);
	if(~beatCtr%4==0,{~newBar.value});
	if(0.35.coin,{~startTrig.value});
	if(0.2.coin,{~revSynth.set(\mix,1)});
	//~breakcore.value;
	//if(0.1.coin,{~filterSynth.set(\mix,1)});
};

~breakcore = {
    if(0.6.coin,{
    	if(0.5.coin,{
        	~retrigRate.value([2,4,8,16,32].choose,[2,-2,-0.5].choose,~breakSynth);
    	},{
        	~retrig.value([2,4,8,16,32].choose,[1,2,3,4].choose,~breakSynth);
    	});
    });
};

~retrig={arg rate,trackBuffer;
	~trigFunc={inf.do{
		//["retrig",~audioBuffer.sampleRate*beatLength*(beatPos+randPos)].postln;
		trackBuffer.set(\t_trig,1,\startPos,~audioBuffer.sampleRate*~beatLength*(~beatCtr));
		(1/rate).wait;
	}}.fork(~clock);
};

~retrigRate={arg rate,target,trackBuffer;
	var increment;
	increment=target/rate;
	~trigFunc={inf.do{arg i;
		//["retrig",~audioBuffer.sampleRate*beatLength*(beatPos+randPos)].postln;
		trackBuffer.set(\t_trig,1,\startPos,~audioBuffer.sampleRate*~beatLength*(~beatCtr),\rate,1+(increment*i));
		(1/rate).wait;
	}}.fork(~clock);
};

~buttonRetrigStart = {
	if(0.5.coin,{
		~retrigRate.value([2,4,8,16,32].choose,(rrand(0,4)),[2,-2,-0.5].choose);
	},{
		~retrig.value([2,4,8,16,32].choose,(rrand(0,4)));
	});
};

~buttonRetrigStop = {
	~playSynth.set(\rate,1);
	~trigFunc.stop;
};

~startFunction = {
    {
        ~syncRoutine.play;
        {~moviePlayer.start}.fork(AppClock);
        ~data[3][0].split($:)[0].asFloat.wait;        
    }.fork
}

//Routines 

~syncRoutine = Routine {
    inf.do{
    	if((Main.elapsedTime-~startTime)>~targetTime[0],{
    		//"BAR".postln;
    		//Synth(\bleep);
    		//~newBar.value;
    		~barCtr = ~barCtr+1;
    		~targetTime[0] = ~data[2][~barCtr].split($:)[0].asFloat;
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
};

// Functions to call from buttons
//      ~buttonRetrigStart on mouse down
//      ~buttonRetrigStop on mouse up
//      revMix=0,room=0,damp=0,mix=0.5
//      filter freq
// Wobble?