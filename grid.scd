~directory  = "/Users/arthurc/Documents/programming/computerMusic/grag/";

// ~sandbox    = "emi_tinie_tempah";
// ~track      = "emi_tinie_tempah_EVN19323-mp4-high.mp4";
~sandbox = "emi_professor_green";
~track = "emi_professor_green_EVN21533-mp4-high.mp4";
w = Window("window title", Rect(0, 0, Window.screenBounds.height-48, Window.screenBounds.height-48)).front;

n = 4;
~movieViews = nil!n!n;
~compViews = nil!n!n;
~buttons = nil!n!n;
~states = nil!n!n;
~startTimes = nil!n!n;

~data = CSVFileReader.read(~directory ++ ~track ++ ".ena");

n.do { |i|
    n.do { |j|
        var dimension, bounds, compview, movieview, button;
        dimension = (w.bounds.width/n);
        bounds = Rect(dimension*i, dimension*j, dimension, dimension);
        compview = CompositeView(w, bounds).background_(Color.rand);
        movieview = MovieView.new(compview, Rect(0,0, bounds.width, bounds.height*0.75))
            .path_(~directory ++ ~track)
            .showControllerAndAdjustSize(false,false)
            .background_(Color.clear)
            .muted_(false);
        
        button = Button(compview, Rect(0,bounds.height*0.75,dimension,bounds.height*0.25))
            .states_([
                ["Off", Color.white, Color.black],
                ["On", Color.black, Color.white]
            ])
            .action_({|butt|
                ~states[i][j] = butt.value;
            });
        
        ~movieViews[i][j] = movieview;
        ~compViews[i][j] = compview;
        ~buttons[i][j] = button;
        ~startTimes[i][j] = ~data[3][~data[3].size.rand].split($:)[0].asFloat;
        // view = CompositeView.new(w, Rect(200*i, 200*j, 200, 200)).background_(Color.rand);
        // SCStaticText.new(view, Rect(0,0, 200, 200)).string_("i: " + i + "j:" + j);
    };
};


~movieViews.do { |array|
    array.do { |item|
        item.currentTime_(60.rand)        
    };
};

~play = {|i, j|
    var view = ~movieViews[i][j];
    {
        view.currentTime_(~startTimes[i][j]);
        ~synth.free;
        ~synth = Synth(\player, [\buf, ~mp3, \start, ~startTimes[i][j] * ~mp3.sampleRate, \end, (~startTimes[i][j] + ~wait) * ~mp3.sampleRate]);
        view.start;
        (~wait*1).wait;
        view.stop;
    }.fork(AppClock);
};


~asciiNumbers = (97..122);
~actions = nil!(n*n);
~usedNumbers = nil!(n*n);

n.do { |i|
    n.do { |j|
        var num = ~asciiNumbers.choose;
        ~asciiNumbers.remove(num);
        ~actions[(i*n) + j] = {~play.(i, j)};
        ~usedNumbers[(i*n) + j] = num;
    };
};

~win2 = Window("blalala", Rect(100, 100, 400, 300)).front;

~win2.view.keyDownAction_({|view, char, mod, uni, key|
    var ascii;
    
    ascii = char.ascii;
    if(~usedNumbers.includes(ascii)) {
        ~actions[~usedNumbers.indexOf(ascii)].();
    };
    // ~actions[~actions.indexOf(char.ascii)].();
})

~wait = 0.5;
Tdef(\shiiit).stop
Tdef(\shiiit, {
    inf.do {
        var times, choice;
        
        times = [1,2].choose;
        choice = ~usedNumbers.choose.asAscii;
        times.do { |i|
            ~win2.view.keyDown(choice);            
        };
        (~wait/times).wait;
    }
}).play(quant:Quant(1));

~movieViews.flatten.do { |item, i|
    item.muted_(true)
};

~mp3 = MP3.readToBuffer(s, ~directory ++ "emi_professor_green_EVN24279-mp4-high.mp4.mp3");

SynthDef(\player) { |buf=0, start=0, end=0, out=0|
    var phase, sig, env;
    
    phase = Phasor.ar(0, BufRateScale.kr(buf), start, end);
    sig = BufRd.ar(2, buf, phase);
    env = EnvGen.ar(Env.linen(0.05, (end-start)/BufSampleRate.kr(buf) - 0.1, 0.05, 1), doneAction: 2);
    
    Out.ar(out,
        Pan2.ar(sig*env, 0);
    );
}.add;


