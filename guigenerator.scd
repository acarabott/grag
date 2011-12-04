if(~window.notNil) {
    if(~window.isClosed.not) {
        ~window.close;
    };
};
~sandbox = "emi_professor_green";

~sbounds = Window.screenBounds;
~width = ~sbounds.height;
~height = ~width - 30;
~win = Window("REEEEMIX", Rect(0, 0, ~width, ~height)).front;
~userView = UserView(~win, Rect(0,0, ~width, ~height));

~imagePaths = ("/Users/arthurc/Documents/programming/computerMusic/grag/" ++ ~sandbox ++ "*.jpg").pathMatch;

~image = SCImage.new(~imagePaths.choose)
    .scalesWhenResized_(true);
~imageBounds = ~image.bounds;
~ratio = ~imageBounds.width / ~imageBounds.height;
~image.setSize(~width, ~width / ~ratio);
~win.view.backgroundImage_(~image);


~movieHeight = ~sbounds.height/2;
~movieWidth = ~sbounds.width/2;
~movieTop = 0 + (~movieHeight/2);
~moviePlayer = SCMovieView(~win, Rect((~width-~movieWidth)/2, ~movieTop, ~movieWidth, ~movieHeight));
~moviePlayer.path_("sounds/song.m4v");
~moviePlayer.showControllerAndAdjustSize(false,false);
~moviePlayer.visible = false;
~moviePlayer.background_(Color.clear);
// ~moviePlayer.start;
// ~moviePlayer.stop;

~userView.mouseMoveAction_({|view, x, y, mod|

    if(x < (~width/2) && (y > (~height/2)) ) {
        // bottom left
        "bottom left".postln;
    };
    if(x > (~width/2) && (y > (~height/2))) {
        // bottom right
        "bottom right".postln;
    };
    if(x < (~width/2) && (y < (~height/2)) ) {
        // top left
        "top left".postln;
    };
    if(x > (~width/2) && (y < (~height/2))) {
        // top right
        "top right".postln;
    };

});

// ~numCornerElements = rrand(0, 4);
~numCornerElements = 4;
~cornerElements = Array.newClear(~numCornerElements);
if(~numCornerElements > 0) {
    ~availableCorners = (0..3);
};

~numCornerElements.do { |i|
    var corner, bounds;
    var width, height;
    var view;
    
    corner = ~availableCorners.pop;
    
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

// (~cornerElements[0].bounds.height - (~cornerElements[0].bounds.height * 0.75)) / 2
// ~guiControls = List[];
// ~guiControlStates = List[];
// ~guiControlFunctions = List[];

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

~playWidth = 300;
~playButton = Button(~win, Rect((~width-~playWidth)/2, 975, ~playWidth, 100))
    .font_(Font("Santa Fe LET", 70))
    .states_([
        ["Play", Color.black, Color.white],
        ["Stop", Color.white, Color.black]
    ])
    .action_({|butt|
        ~moviePlayer.visible = true;
        // Play Action
    });

