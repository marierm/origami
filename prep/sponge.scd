PR(\abstractProcess).v.clone({
	// This table is used to invert the bit order of the buttons.  This is
	// useful when controling pitch with the buttons.
	~numBits = 5;
	~conversionTable = (0..(2.pow(~numBits) - 1)).collect({|i|
		i.asInteger.asBinaryDigits(~numBits).reverse.convertDigits(2)
	});
	~asPattern = {
	};
	~prep = {
		// This damper synth conditions the fsr data to make it suitable for
		// damping the rods.
		Server.default.waitForBoot({
			// open sponge port
			~sponge = SpongeSLIP(baudRate:115200);
			// activate the features needed
			[
				\acc1xHP, \acc1yHP, \acc1zHP,
				\acc2xHP, \acc2yHP, \acc2zHP, 
				\bend
			].do{|i,j|
				~sponge.activateFeature(i);
			};
			// create button bank
			~butts = ButtonBank(ButtonInput.sponge(~sponge));
			// Buttons 9 to 5 are used to make operations on corresponding voices.
			// Modifier keys will change their behavior.
			// Level 0 stops the voice.
			// Level 1 starts the voice.
			// Level 16 (bit 4) changes to "pitch control" mode.
			// ~butts.modes[0].buttonFunctions[0..4].do{|i,j|
			~butts.modes[0].buttonFunctions[9..5].do{|i,j|
				i.functions_(
					Dictionary.newFrom([
						1, Array.newClear(32).putEach([0,1,2,4],[
							{			// 0
								\stop.post; j.postln;
								BP(j).stop(0);
							},
							{ 			// 1
								\play.post; j.postln;
								BP(j).play(0,doReset: true);
							},
							{ 			// 2
								\pbOn.post; j.postln;
								BP(j).pitcher.map(\bend, ~sponge[\bend].bus);
							},
							{			// 4
								\freeze.post; j.postln;
								BP(j).freezeMe;
							}
						]),
						0, Array.newClear(32).putEach([2, 16],[
							{ 			// 2
								\pbOff.post; j.postln;
								BP(j).pitcher.set(\bend, 0);
							},
							{
								("mode:" + (j + 1)).postln;
								BP(\sponge).butts.mode_(j + 1);
							},
						])
					]);
				)
			};
			~butts.modes[0].addFunc(
				button:5,
				function:{
					\stop.post;	\feu.postln;
					BP(\feu).stop(0);
				},
				levels: [0],
				buttState: 1
			);
			~butts.modes[0].addFunc(
				button:5,
				function:{
					\play.post; \feu.postln;
					BP(\feu).play(0,doReset: true);
				},
				levels: [1],
				buttState: 1
			);

			// buttons 0 to 5 are made modifier keys.
			~butts.modes[0].buttonFunctions[4..0].do{|i,j| i.makeModifier(j)};
			// In modes 1 to 4, buttons 0 to 4 sets the pitch of the corresponding
			// voice.  
			(1..4).do{|g,h|
				// make new modes
				~butts.newMode;
				// buttons 0 to 4 are not really modifiers.  They set the level
				// and then, the level is used to set the pitch.
				~butts.modes[g].buttonFunctions[0..4].do{|i,j| i.makeModifier(j)};

				// Enable double clicks for buttons 6..9.
				(6..9).do({|i|
					~butts.modes[g].buttonFunctions[i].enableNclick;
				});
				// for each button(0 to 4), add function to level 0.
				(0..4).do{|i,j|
					~butts.modes[g].buttonFunctions[i].functions[1][0] = (
						~butts.modes[g].buttonFunctions[i].functions[1][0]
					).addFunc({
						// This func offsets the pitch of the voice.
						BP(h).pitchOsBus.set(
							~conversionTable[ ~butts.modes[g].level ]
						);
					});
					~butts.modes[g].buttonFunctions[i].functions[0][0] = (
						~butts.modes[g].buttonFunctions[i].functions[0][0]
					).addFunc({
						// do it when button is released too
						BP(h).pitchOsBus.set(
							~conversionTable[ ~butts.modes[g].level ]
						);
					});
				};

				// ~butts.modes[g].buttonFunctions[0..4].do{|i,j| i.makeModifier(j)};

				// button 5 switch back to mode 0 (any level works).
				~butts.modes[g].addFunc(
					button: 5,
					function: {
						BP(\sponge).butts.mode_(0);
						("mode:" + 0).postln; 
						BP(\sponge).butts.mode.level_(0);
					},
					levels: (0..31),
					buttState: 1
				);

				// button 6 freezes the voice.
				// Double click stops it.
				~butts.modes[g].addFunc(
					button: 6,
					function: {
						\freeze.post; h.postln;
						BP(h).freezeMe;
					},
					levels: (0..31),
					buttState: 1
				);
				~butts.modes[g].addFunc(
					button: 6,
					function: {
						\stop.post; h.postln;
						BP(h).stop(0);
					},
					levels: (0..31),
					buttState: 2
				);

				// button 7 starts the voice.
				// Double click unfreezes it.
				~butts.modes[g].addFunc(
					button: 7,
					function: {
						\play.post; h.postln;
						BP(h).play(0,doReset: true);
					},
					levels: (0..31),
					buttState: 1
				);
				~butts.modes[g].addFunc(
					button: 7,
					function: {
						\unfreeze.post; h.postln;
						BP(h).unfreezeMe;
					},
					levels: (0..31),
					buttState: 2
				);

				// button 8 8vb
				// Double click sticks it.
				~butts.modes[g].addFunc(
					button: 8,
					function: {
						\octVbTmp.post; h.postln;
						BP(h).octTmp(-1);
					},
					levels: (0..31),
					buttState: 1
				);
				~butts.modes[g].addFunc(
					button: 8,
					function: {
						\octReset.post; h.postln;
						BP(h).octReset;
					},
					levels: (0..31),
					buttState: 0
				);
				~butts.modes[g].addFunc(
					button: 8,
					function: {
						\octVbStuck.post; h.postln;
						BP(h).octVb;
					},
					levels: (0..31),
					buttState: 2
				);

				// button 9 = 8va
				// Double click sticks it.
				~butts.modes[g].addFunc(
					button: 9,
					function: {
						\octVaTmp.post; h.postln;
						BP(h).octTmp(1);
					},
					levels: (0..31),
					buttState: 1
				);
				~butts.modes[g].addFunc(
					button: 9,
					function: {
						\octReset.post; h.postln;
						BP(h).octReset;
					},
					levels: (0..31),
					buttState: 0
				);
				~butts.modes[g].addFunc(
					button: 9,
					function: {
						\octVaStuck.post; h.postln;
						BP(h).octVa;
					},
					levels: (0..31),
					buttState: 2
				);

				// button 8 + 9 = pitch bend
				~butts.modes[g].addCombo(
					comboBits: 2r1100000000,
					function: {
						\pbOn.post; h.postln;
						BP(h).octReset;
						BP(h).pitcher.map(\bend, ~sponge[\bend].bus);
					},
					buttState: 1
				);
				~butts.modes[g].addCombo(
					comboBits: 2r1100000000,
					function: {
						\pbOff.post; h.postln;
						BP(h).pitcher.set(\bend, 0);
					},
					buttState: 0
				);
			};

		});
	};

	~freeCleanup = {
		{ ~sponge.close; }.try;
		~damper.free;
		~damperBus.free;
	};
}) => BP(\sponge);



// BP(\sponge).free

