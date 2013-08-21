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
						true, Array.newClear(32).putEach([0,1,2,4,16],[
							{			// 0
								\stop.post; j.postln;
								BP( ("forms" ++ j).asSymbol ).stop(0);
								BP(j).stop(0);
								BP(("disto" ++ j).asSymbol).stop(0);
							},
							{ 			// 1
								\play.post; j.postln;
								BP(j).play(0,doReset: true);
								BP( ("forms" ++ j).asSymbol ).play(0);
								BP(("disto" ++ j).asSymbol).play(0);
							},
							{ 			// 2
								\pbOn.post; j.postln;
								BP(j).pitcher.map(\bend, ~sponge[\bend].bus);
							},
							{			// 4
								\freeze.post; j.postln;
								BP(j).freezeMe;
							},
							{			// 16
								("mode:" + (j + 1)).postln;
								BP(\sponge).butts.mode_(j + 1);
							}
						]),
						false, Array.newClear(32).putEach([2],[
							{ 			// 2
								\pbOff.post; j.postln;
								BP(j).pitcher.set(\bend, 0);
							},
						])
					]);
				)
			};

			~butts.modes[0].buttonFunctions[5].do{|i,j|
				i.functions_(
					Dictionary.newFrom([
						true, Array.newClear(32).putEach([0,1,2,4,16],[
							{			// 0
								\stop.post;
								\feu.postln;
								BP(\feu).stop(0);
							},
							{ 			// 1
								\play.post; \feu.postln;
								BP(\feu).play(0,doReset: true);
							},
							{ 			// 2
								\pbOn.post; \feu.postln;
							},
							{			// 4
								// \freeze.post; \clari.postln;
								// BP(\clari).freezeMe;
							},
							{			// 16
								("mode:" + "clari").postln;
								BP(\sponge).butts.mode_(5);
							}
						]),
						false, Array.newClear(32).putEach([2],[
							{ 			// 2
								\pbOff.post; \feu.postln;
							},
						])
					]);
				)
			};

			// buttons 0 to 5 are made modifier keys.
			~butts.modes[0].buttonFunctions[4..0].do{|i,j| i.makeModifier(j)};
			// In modes 1 to 5, buttons 5 to 9 sets the pitch of the corresponding
			// voice.  
			(1..4).do{|g,h|
				// make new modes
				~butts.newMode;
				// buttons 0 to 4 are not really modifiers.  They set the level
				// and then, the level is used to set the pitch.
				~butts.modes[g].buttonFunctions[0..4].do{|i,j| i.makeModifier(j)};
				// for each button(0 to 4), add function to level 0.
				(0..4).do{|i,j|
					~butts.modes[g].buttonFunctions[i].functions[true][0] = (
						~butts.modes[g].buttonFunctions[i].functions[true][0]
					).addFunc({
						// This func offsets the pitch of the voice.
						BP(h).pitchOsBus.set(
							~conversionTable[ ~butts.modes[g].level ]
						);
					});
					~butts.modes[g].buttonFunctions[i].functions[false][0] = (
						~butts.modes[g].buttonFunctions[i].functions[false][0]
					).addFunc({
						// do it when button is released too
						BP(h).pitchOsBus.set(
							~conversionTable[ ~butts.modes[g].level ]
						);
					});
				};

				// ~butts.modes[g].buttonFunctions[0..4].do{|i,j| i.makeModifier(j)};

				// button 5 switch back to mode 0 (any level works).
				~butts.modes[g].buttonFunctions[5].functions[true] =
				Array.fill(32, {{
					BP(\sponge).butts.mode_(0);
					("mode:" + 0).postln; 
					BP(\sponge).butts.mode.level_(0);
				}});
				
				// button 6 turns pitch bend on (any level works).
				~butts.modes[g].buttonFunctions[6].functions[true] =
				Array.fill(32, {{
					\pbOn.post; h.postln;
					BP(h).pitcher.map(\bend, ~sponge[\bend].bus);
				}});

				~butts.modes[g].buttonFunctions[6].functions[false] =
				Array.fill(32, {{
					\pbOff.post; h.postln;
					BP(h).pitcher.set(\bend, 0);
				}});

				// button 8 stops the voice (any level works).
				~butts.modes[g].buttonFunctions[8].functions[true] =
				Array.fill(32, {{
					\stop.post; h.postln;
					BP(h).stop;
				}});

				// button 9 plays the voice (any level works).
				~butts.modes[g].buttonFunctions[9].functions[true] =
				Array.fill(32, {{
					\play.post; h.postln;
					BP(h).play(0,doReset: true);
				}});

			};

			/*
			// Clarinet mode
			~butts.newMode;//Clari mode
			~butts.modes[5].buttonFunctions[0].functions[true] =
			Array.fill(32, {{
				BP(\sponge).butts.mode_(0);
				("mode:" + 0).postln; 
				BP(\sponge).butts.mode.level_(0);
			}});
			*/
		});
	};

	~freeCleanup = {
		{ ~sponge.close; }.try;
		~damper.free;
		~damperBus.free;
	};
}) => BP(\sponge);



// BP(\sponge).free

