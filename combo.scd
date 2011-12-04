(
//Variables
~directory  = "/Users/arthurc/Documents/programming/computerMusic/grag/";

// ~sandbox    = "emi_tinie_tempah";
// ~track      = "emi_tinie_tempah_EVN19323-mp4-high.mp4";
~sandbox    = "emi_professor_green";
// ~track      = "emi_professor_green_EVN24279-mp4-high.mp4"
~track = "emi_professor_green_EVN21533-mp4-high.mp4";

~data       = CSVFileReader.read(~directory ++ ~track ++ ".ena");

~bpm        = ~data[0][0].asFloat;
~clock      = TempoClock(~bpm/60);
~beatLength = (1 / (~bpm/60)); 
~barCtr     = 0;
~beatCtr    = 0;
~targetTime = [~data[2][~barCtr].split($:)[0].asFloat,~data[3][0].split($:)[0].asFloat];
~playingBreaks = false;
~cutting = true;
~scale=[0,2,4,5,7,9,11]+1;
~cutChance = 0;
s.latency = 0;
s.waitForBoot {
{
    //SynthDefs
    SynthDef(\mouse,{
    	SendReply.kr(Impulse.kr(20),'mouse',
    	values:[MouseX.kr(0,1),MouseY.kr(0,1)]
    	)
    }).add;

	SynthDef(\hackWobble,{arg freq=100,modFreq=2,filterFreq=100,depth=100,bpm,amp=1;
	var son,sweep,trig;
    	   trig = CoinGate.kr(0.5,(Impulse.kr(bpm/60))); 
    	   sweep = LFSaw.ar(Demand.kr(trig, 0, Drand([1, 2, 2, 3, 4, 5, 6, 8, 16], inf))).exprange(40, 5000); 	 
    	   son = LFSaw.ar(freq * [0.99, 1, 1.01]).sum; 
    	   son = LPF.ar(son, sweep); 
    	   son = Normalizer.ar(son); 
    	   son = son + BPF.ar(son, 2000, 2); 
    	   son = son + GVerb.ar(son, 10, 0.1, 0.7, mul: 0.3); 	
    	Out.ar([0,1],son*0.2*amp);
    }).store;

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
    	env=EnvGen.ar(Env([1,1,0],[(BufFrames.kr(bufnum)/BufSampleRate.kr(bufnum))*length,0]), doneAction:2);
    	sound=PlayBuf.ar(2, bufnum, BufRateScale.kr(bufnum)*rate, t_trig, startPos,loop);
    	SendReply.kr(t_trig,'glitch',startPos);
    	
    	Out.ar(outBus,
    	    Pan2.ar(sound*env*amp, 0);
    	)
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
    ~audioBuffer    = MP3.readToBuffer(s,~directory++~track++".mp3");
    ~breakBuffers   = Array.fill(8, {arg i; Buffer.read(s, ~directory ++ "breaks/BREAK"++(i+1)++".aif")});
    s.sync;
    //Busses
    ~busses = Array.fill(3, {Bus.audio(s,2)});
    
    s.sync;
    //Synths
    ~playSynth      = Synth(\hackPlay, [\bufnum, ~audioBuffer, \outBus, ~busses[0], \rate, 0]);
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

~updateWobble={arg x,y;
    ~wobbleSynth.set(\amp,x,\freq,~scale[(y*7).floor]*50);
~playSynth.set(\amp,(1-x));	
};

~playRate = {arg newRate=(-1),dur=1;
    "PLAYYYYYYRATE".postln;
	{
    	~playSynth.set(\amp,0);
		~newSynth=Synth(\hackPlay,[\bufnum,~audioBuffer,\startPos,~targetTime[1]*~audioBuffer.sampleRate, \amp, 1]);
		dur.wait;
		~newSynth.free;
		~playSynth.set(\amp, 1);
    	
	}.fork(~clock);
	
};

~filterSweep = {arg dur=1;
	{
	    "filter sweeping".postln;
        // ~filterSynth.set(\mix,0.7);
	    
		~filterSynth.set(\freq,5000);
		dur.wait;
		~filterSynth.set(\freq, 10);
		"stopped filter sweeping".postln;
	}.fork(~clock);
};

~setFilter2D = {arg x,y;
    "filter".postln;
    // [x,y].postln;
    ~filterSynth.set(\mix, 0.7, \freq,x.linlin(0, 1, 10, 5000) ,\q, y.linlin(0, 1, 0.1, 2));  
};

~setRev2D = {arg x,y;
    "reverb!".postln;
    // [x, y].postln;
    ~revSynth.set(\mix, x, \room, y);
};

~buttonRetrigStart = {
    "buttontrigStart".postln;
	if(0.5.coin,{
        // ~retrigRate.value([2,4,8,16,32].choose, [2,-2,-0.5].choose,~playSynth);
        ~retrigRate.value([1,2,4,8,16].wchoose([3,4,4,2,1].normalizeSum), [1.5,-1.5,-0.5].choose,~playSynth);
		
	},{
		~retrig.value([1,2,4,8,16].wchoose([3,4,4,2,1].normalizeSum), ~playSynth);
	});
};

~buttonRetrigStop = {
    "buttonRetrigStop".postln;
	~playSynth.set(\rate,1);
	~trigFunc.stop;
};

~startTrig={
    "start trig".postln;
	if(0.5.coin, {
        // ~retrigRate.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),[1.5,-1.5,-0.5].choose,~playSynth);
        ~retrigRate.value([1,2,4, 8].wchoose([0.3,0.3,0.2,0.1]),[1.5,-1.5,-0.5].choose,~playSynth);
	},{
        // ~retrig.value([2,4,8,16].wchoose([0.3,0.3,0.2,0.1]),~playSynth);
        ~retrig.value([1,2,4, 8].wchoose([0.3,0.3,0.2,0.1]),~playSynth);
    	
	});
};

~setMovieTime = {arg pos;
    {
	    ~moviePlayer.currentTime_(pos);
    }.fork(AppClock);
};


~setBreaks = {|val|
    if(val == 1) {
    	~playingBreaks=true;
        "breaks On".postln;
    } {
        "breaks off".postln;
        
        ~playingBreaks = false;
    };
};


~barcount = 0;
~newBar = {
    ~barcount = ~barcount + 1;
    // Synth(\beep, [\freq, 1000, \amp, 0.5, \pan, 0, \out, 0]);
	if(~playingBreaks,{~breakSynth = Synth(\hackPlay, [\bufnum, ~breakBuffers[7.rand], \rate, (~bpm / 96), \amp, 0.5, \startPos, 0])});
};


~stopTrig={
	~trigFunc.stop;
};

~newBeat = {
    // ~stopTrig.value;
	~playSynth.set(\rate, 1, \t_trig,1, \startPos, ~targetTime[1]*44100);
    // Synth(\beep, [\freq, 2000, \amp, 0.2, \pan, 0, \out, 0]);
    // ~revSynth.set(\mix,0);
    // ~filterSynth.set(\mix,0);
	if(~beatCtr%4==0,{~newBar.value});
	{
	    if((~cutChance.coin) && (~cutting),{ 
	        ~stopTrig.();
	        ~startTrig.();
    	    [1,2,0.5].choose.wait;
            // ~cutting = false;
    	    ~stopTrig.();
	        
        });
	}.fork;
    // if(0.2.coin,{~revSynth.set(\mix,1)});
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
		"trig!".postln;
		(1/rate).wait;
	}}.fork(~clock);
};

~retrigRate={arg rate,target,trackBuffer;
	var increment;
	increment=target/rate;
	~trigFunc={inf.do{arg i;
	    "trigRate".postln;
		//["retrig",~audioBuffer.sampleRate*beatLength*(beatPos+randPos)].postln;
		trackBuffer.set(\t_trig,1,\startPos,~audioBuffer.sampleRate*~beatLength*(~beatCtr),\rate,1+(increment*i));
		(1/rate).wait;
	}}.fork(~clock);
};

~startFunction = {
    {
        
        s.makeBundle(0.2, {
            ~playSynth.set(\rate, 1);
        });
        ~syncRoutine.play;            
        {~moviePlayer.start}.fork(AppClock);
        // ~data[3][0].split($:)[0].asFloat.wait; 
        // ~wobbleSynth=Synth(\hackWobble,[\freq,50,\bpm,140,\amp,0]);       
    }.fork
};

~stopFunction = {
    ~playSynth.free;
    ~syncRoutine.stop;
    {~moviePlayer.stop}.fork(AppClock);
    ~trigFunc.stop;
};
//Routines 

~syncRoutine = Routine {
    ~startTime  = Main.elapsedTime;
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
            // Synth(\beep, [\freq, 2000, \amp, 0.2, \pan, 0, \out, 0]);
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

~backgroundImage = SCImage.new(~directory ++ "emi_professor_green_5099964806754-cover.jpg").scalesWhenResized_(true);
~imageBounds = ~backgroundImage.bounds;
~ratio = ~imageBounds.width / ~imageBounds.height;
~backgroundImage.setSize(~width, ~width / ~ratio);
~win.view.backgroundImage_(~backgroundImage);

~movieHeight    = ~sbounds.height/2;
~movieWidth     = ~sbounds.width/2;
~movieTop       = 0 + (~movieHeight/2);
~moviePlayer    = SCMovieView(~win, Rect((~width-~movieWidth)/2, ~movieTop, ~movieWidth, ~movieHeight));
~moviePlayer.path_(~directory ++ ~track); // this might need to be different?
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.visible = false;
~moviePlayer.background_(Color.clear);
~moviePlayer.muted_(true);

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


~actionFunctions = Dictionary[];
~actionFunctions['hit'] = [~playrate, ~setBreaks];
~actionFunctions['2D'] = [~setFilter2D, ~setRev2D];
~actionFunctions['toggle'] = [[~buttonRetrigStart, ~buttonRetrigStop]];

~chosenFunctions = Array.newClear(~numCornerElements);


~numCornerElements.do { |i|
    var key;
    ~getFunctionKey = {
        key = ~actionFunctions.keys.choose;
        if(~actionFunctions[key].size != 0) {
            ~chosenFunctions[i] = [key, ~actionFunctions[key].pop];
        } {
            ~actionFunctions.removeAt(key);
            
            if(~actionFunctions.values.flatten.size != 0) {
                ~getFunctionKey.();
            };
        };        
    };
    ~getFunctionKey.();
};

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

    if(['hit', 'toggle'].includes(~chosenFunctions[i][0])) {
        
        if(~chosenFunctions[i][0] == 'toggle') {
            buttonIsHold = true;
            alpha = 0.5;
        } {
            buttonIsHold = false;
            alpha = 0.5;
        };
        
        ~guiControls[symbol] = UserView(item, bounds);
        ~guiControlStates[symbol] = false;
        ~guiControlFunctions[symbol] = ~chosenFunctions[i][1];
        ~guiControls[symbol].background_(Color.black);
        ~guiControls[symbol].backgroundImage_(image, alpha:alpha);
        
        if(buttonIsHold.not) {
            // Sticky buttons
            "sticky button".postln;
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
            // Toggle down buttons
            "toggle button".postln;
            ~guiControls[symbol].mouseDownAction_({
                ~guiControls[symbol].backgroundImage_(image, alpha:1);
                ~guiControlFunctions[symbol][0].();
                ~guiControlStates[~guiControlStates.size-1] = ~guiControlStates[symbol].not;
            });
            ~guiControls[symbol].mouseUpAction_({
                ~guiControls[symbol].backgroundImage_(image, alpha:0.5);
                ~guiControlFunctions[symbol][1].();
                ~guiControlStates[~guiControlStates.size-1] = ~guiControlStates[symbol].not;
            });
            
        };
        
    } {
        if(~chosenFunctions[i][0] == '2D') {
            "2d slider".postln;
            //2D sliders
            ~guiControls[symbol] = Slider2D(item, bounds);
            ~guiControls[symbol].backgroundImage_(image, alpha:0.4);
            ~guiControlFunctions[symbol] = ~chosenFunctions[i][1];
            ~guiControls[symbol].action_({|slider|
                ~guiControlFunctions[symbol].(slider.x, slider.y);
                ~guiControls[symbol].backgroundImage_(image, alpha:[slider.x, slider.y].mean.linlin(0, 1, 0.4, 1));
            });
        }
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
        if(butt.value == 1) {
            ~moviePlayer.visible = true;
            ~startFunction.();
        } {
            ~moviePlayer.visible = false;
            ~stopFunction.();
        };
    });
    
~cutSlider = Slider(~win, Rect(40, (~height-~movieHeight)/2, 40, ~movieHeight))
    .action_({|slider| ~cutChance = slider.value.linlin(0, 1, 0.1, 1);})
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