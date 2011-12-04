(
//Variables
~directory  = "sounds/";

~sandbox    = "emi_professor_green";
~track      = "emi_professor_green_EVN24279-mp4-high.mp4";

~data       = CSVFileReader.read(~directory ++ ~track ++ ".ena");

~bpm        = ~data[0][0].asFloat;
~clock      = TempoClock(~bpm/60);
~beatLength = (1 / (~bpm/60)); 
~barCtr     = 0;
~beatCtr    = 0;
~targetBpm = [~data[2][~barCtr].split($:)[0].asFloat,~data[3][~beatCtr].split($:)[0].asFloat];
~startTime  = Main.elapsedTime;
~playingBreaks = false;
~cutting = false;


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

    SynthDef(\hackHPFilter,{arg outBus,inBus,freq=1500,q=10,mix=0.5,time=0;
    	var sound,dry,wet;
    	dry=InFeedback.ar(inBus,2);
    	wet=RHPF.ar(dry,freq.lag(time),q);
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
    
}.fork
};

//Responders
~movieResponder = OSCresponderNode(s.addr, 'glitch', {|t, r, msg| }).add;
~movieResponder.action_({|t, r, msg|
	~setMovieTime.value(msg[3]/44100);    
});

// Functions

~playRate = {arg newRate=(-1),dur=1;
	~playSynth.set(\amp,0);
	{
		~newSynth=Synth(\hackPlay,[\bufnum,~audioBuffer,\startPos,~targetTime[1]*~audioBuffer.sampleRate]);
		dur.wait;
		~newSynth.free;
	}.fork(~clock);
};

~filterSweep = {arg dur=1;
	{
		~filterSynth.set(\freq,5000);
		dur.wait;
		~filterSynth.set(\freq,10);
	}.fork(~clock);
};

~setFilter2D = {arg x,y;
  	~filterSynth.set(\freq,(x*5000)+10,\q,y*3);	
};

~setRev2D = {arg x,y;
	~revSynth.set(\mix,x,\room,y);
};

~setMovieTime = {arg pos;
    {
	    ~moviePlayer.currentTime_(pos);
    }.fork(AppClock);
};

~newBar = {
	if(~playingBreaks,{~breakSynth = Synth(\hackPlay, [\bufnum, ~breakBuffers[7.rand], \rate, (~bpm / 96)])});
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
	if((0.35.coin) && (~cutting),{~startTrig.value});
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
};

~stopFunction = {
    ~syncRoutine.stop;
    {~moviePlayer.stop}.fork(AppClock);
    ~trigFunc.stop;
};
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
    }};


// GUI

~sbounds = Window.screenBounds;
~width = ~sbounds.height;
~height = ~width - 30;
~win = Window("REEEEMIX", Rect(0, 0, ~width, ~height)).front;
~imagePaths = (~directory ++ ~sandbox ++ "*.jpg").pathMatch;

~backgroundImage = SCImage.new(~imagePaths.choose).scalesWhenResized_(true);
~imageBounds = ~backgroundImage.bounds;
~ratio = ~imageBounds.width / ~imageBounds.height;
~backgroundImage.setSize(~width, ~width / ~ratio);
~win.view.backgroundImage_(~backgroundImage);

~movieHeight    = ~sbounds.height/2;
~movieWidth     = ~sbounds.width/2;
~movieTop       = 0 + (~movieHeight/2);
~moviePlayer    = SCMovieView(~win, Rect((~width-~movieWidth)/2, ~movieTop, ~movieWidth, ~movieHeight));
~moviePlayer.path_(~directory ++ ~track ++ "mp4"); // this might need to be different?
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.visible = false;
~moviePlayer.background_(Color.clear);

~numCornerElements = 4;
~cornerElements = Array.newClear(~numCornerElements);

~numCornerElements.do { |i|
    var corner, bounds;
    var width, height;
    var view;
    
    corner = i;
    
    width = ~width /2;
    height = (~height - ~movieHeight)/2;
    switch (corner)
        {0}  {
            bounds = Rect(0,0, width, height);
        }
        {1}  {
            bounds = Rect(width, 0, width, height);
        }
        {2}  {
            bounds = Rect(0, ~height-height, width, height);            
        }
        {3}  {
            bounds = Rect(width, ~height-height, width, height);            
            
        };
    
    view = CompositeView(~win, bounds);
    // view.background_(Color.rand);
    ~cornerElements[i] = view;

};

~guiControls = Dictionary[];
~guiControlStates = Dictionary[];
~guiControlFunctions = Dictionary[];

~cornerElements.do { |item, i|
    var bounds;
    var mult;
    var height;
    var width;
    var dimension;
    var image;
    var alpha;
    var buttonIsHold;
    var index;
    var symbol;
    
    mult = 0.75;
    
    height = item.bounds.height;
    width = item.bounds.width;
    dimension = height * mult;
    
    bounds = Rect((width - dimension)/2, (height - dimension)/2, dimension, dimension);
    
    image = SCImage.new(~imagePaths.choose).scalesWhenResized_(true);
    image.setSize(bounds.width, bounds.height);
    
    symbol = i.asSymbol;
    
    if(0.5.coin) {
        if(0.5.coin) {
            buttonIsHold = true;
            alpha = 0.5;
        } {
            buttonIsHold = false;
            alpha = 0.5;
        };
        
        ~guiControls[symbol] = UserView(item, bounds);
        ~guiControlStates[symbol] = false;
        ~guiControlFunctions[symbol] = {};
        ~guiControls[symbol].background_(Color.black);
        ~guiControls[symbol].backgroundImage_(image, alpha:alpha);
        
        if(buttonIsHold.not) {
            // Sticky buttons
            ~guiControls[symbol].mouseDownAction_({
                if(~guiControlStates[symbol]) {
                    ~guiControls[symbol].backgroundImage_(image, alpha:0.5);
                    ~guiControlFunctions[symbol].(0);
                } {
                    ~guiControls[symbol].backgroundImage_(image, alpha:1);
                    ~guiControlFunctions[symbol].(1);
                };
                ~guiControlStates[symbol] = ~guiControlStates[symbol].not;
            });
        } {
            // Hold down buttons
            ~guiControls[symbol].mouseDownAction_({
                ~guiControls[symbol].backgroundImage_(image, alpha:1);
                ~guiControlFunctions[symbol].(1);
                ~guiControlStates[~guiControlStates.size-1] = ~guiControlStates[symbol].not;
            });
            ~guiControls[symbol].mouseUpAction_({
                ~guiControls[symbol].backgroundImage_(image, alpha:0.5);
                ~guiControlFunctions[symbol].(0);
                ~guiControlStates[~guiControlStates.size-1] = ~guiControlStates[symbol].not;
            });
            
        };
        
    } {
        //2D sliders
        ~guiControls[symbol] = Slider2D(item, bounds);
        ~guiControls[symbol].backgroundImage_(image, alpha:0.4);
        ~guiControlFunctions[symbol] = {};
        ~guiControls[symbol].action_({|slider|
            ~guiControlFunctions[symbol].(slider.x, slider,y);
            ~guiControls[symbol].backgroundImage_(image, alpha:[slider.x, slider.y].mean.linlin(0, 1, 0.4, 1));
        });
    };
};

//Play Button
~playWidth = 300;
~playButton = Button(~win, Rect((~width-~playWidth)/2, 975, ~playWidth, 100))
    .font_(Font("Santa Fe LET", 70))
    .states_([
        ["Play", Color.black, Color.white],
        ["Stop", Color.white, Color.black]
    ])
    .action_({|butt|
        if(butt.state == 1) {
            ~moviePlayer.visible = true;
            ~startFunction.();
        } {
            ~moviePlayer.visible = false;
            ~stopFunction.();
        };
    });
  )
// Functions to call from buttons
//      ~buttonRetrigStart on mouse down
//      ~buttonRetrigStop on mouse up
//      revMix=0,room=0,damp=0,mix=0.5
//      filter freq
// Wobble?

//w = Window("window title", Rect(100, 100, 400, 300)).front;
//b = Button(w, Rect(0,0,20,20))
//    .states_([
//        ["State 0", Color.black, Color.white],
//        ["State 1", Color.black, Color.white]
//    ])
//    .action_({|butt|
//        butt.value.postln;  
//    });
