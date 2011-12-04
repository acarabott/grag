~songTitle = "Frisky";
~sbounds = Window.screenBounds;
~win = Window(~songTitle + "Remix", Rect(0, 0, ~sbounds.width/2, ~sbounds.height)).front;
~moviePlayer = MovieView(~win, Rect(0,0,~sbounds.width/2, ~sbounds.height/2));
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.path_("sounds/song.m4v")

.muted_(true).editable_(true);

~moviePlayer.start
~moviePlayer.currentTime_(40)

Trig

b = Buffer.read(s, "sounds/amen.wav");
b = MP3.readToBuffer(s, "/Users/arthurc/Documents/programming/computerMusic/grag/song.mp3");
b = Buffer.read(s, "sounds/amen.wav");

~data = CSVFileReader.read("/Users/arthurc/Documents/programming/computerMusic/grag/analysis.ena");
~frames = ~data[2].collect { |item, i|
    (item.split($:)[0].asFloat * b.sampleRate).asInteger;
};

~frames = [0] ++ ~frames

~dataBuf = Buffer.loadCollection(s, ~frames);

~dataBuf.get(0, {|val| val.postln;})

SynthDef(\PhaseTest) { |out=0, buf=0, t_trig=1, t_reset=0, array=0, dataBuf=1, dmod=0, rate=100|
    var frames, phase, env, times, ser, trig, duty, mod;
    var dataPhase;
    
    frames = BufFrames.kr(buf);
    phase = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
    env = EnvGen.ar(Env.linen(0, BufDur.kr(buf), 0), doneAction: 2);
    // times = [ 0, 19283, 38566, 57849, 77133 ];
    // ser = Dser(times, times.size);
    // mod = Demand.kr(t_trig, t_reset, ser);
    
    // dataPhase = Stepper.kr(t_trig, t_reset, 0, BufFrames.kr(dataBuf));
    
    // dataPhase.poll;
    // mod = BufRd.kr(1, dataBuf, dataPhase);
    // dmod.poll;
    // mod.poll;
    // trig = Trig.ar(phase % mod);
    
    // (phase % mod).poll;
    // mod.poll;
    // SendTrig.ar(Trig.kr(A2K.kr(phase%mod)), 0, phase);
    
    // SendTrig.ar(Trig.ar(phase%mod), 0, mod);
    SendTrig.kr(Impulse.kr(rate), 0, phase);
    
    Out.ar(out,
        BufRd.ar(1, buf, phase).dup;
    );
}.add;


SynthDef(\PitchShift) { |in=0, out=0, ratio=1|
    var sig = In.ar(in, 2);
    var shift = PitchShift.ar(sig, 0.1, ratio, 0, 0.004);
    
    Out.ar(out,
        shift.dup;    
    );
}.add;

~shiftBus = Bus.audio(s, 2);
~shiftSynth = Synth(\PitchShift, [\in, ~shiftBus]);

x.set(\out, ~shiftBus);

~times = (0..3).collect { |item, i| ((b.duration/4) * b.sampleRate * (item+1)).floor };


~times = [22050, 44100, 66150];
~index = 0;

x = Synth.before(~shiftSynth, \PhaseTest, [\buf, b]);
x.free
o = OSCresponderNode(s.addr, '/tr', {|t, r, msg| }).add;

~index = 0;

x.free;
o.action_({|t, r, msg|
    // Synth(\beep, [\freq, 880, \amp, 0.2, \pan, 0, \out, 0]);
    if(msg[3] > ~frames[~index]) {
        Synth(\beep, [\freq, 880, \amp, 0.2, \pan, 0, \out, 0]);
        ~shiftSynth.set(\ratio, [0.5, 1].choose);
        ~index = ~index + 1;
    };
    // ~index = ~index + 1;
    // x.set(\t_trig, 1);
    // x.set(\mod, ~times[~index]);
    // Synth(\beep, [\freq, 440, \amp, 0.2, \pan, 0, \out, 0]);
});

