// withLists
// -> withSponge
//    -> withInterpolator
//       -> withAmp
//          -> fm

PR(\abstractProcess).clone({   // withLists
	// Do this when cloning:
	// ~prepList = ~prepList.deepCopy.addFunc({ });
	~server = Server.default;
	~prep = { ~prepList.value; };
	~asPattern = { ~asPatternList.value.last; };
	~stopCleanup = { ~stopCleanupList.value; };
	~freeCleanup = { ~freeCleanupList.value; };
}).chuck(PR(\withLists));

PR(\withLists).clone({					// withSponge
	~sponge = BP(\sponge).sponge;
}).chuck(PR(\withSponge));

PR(\withSponge).clone({					// withInterpolator
	~interpolatorPath = nil;

	~prepList = ~prepList.deepCopy.addFunc({
		~interpolator = PresetInterpolatorServer.newLoad(
			~interpolatorPath
		);
	});
	~asPatternList = ~asPatternList.deepCopy.addFunc({
		6.do({ |i|
			~interpolator.connect(i, ~sponge.features[i]);
		});
		1.asPattern;
	});
	~freezeMe = {
		6.do({ |i| ~interpolator.disconnect(i);	});
	};
	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		6.do({ |i|
			try { ~interpolator.disconnect(i) };
		});
	});
	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~interpolator.free;
	});
}).chuck(PR(\withInterpolator));

PR(\withInterpolator).clone({ 			// withAmp
	~relTime = 3.0;
	~prepList = ~prepList.deepCopy.addFunc({
		SynthDef(\ampExtractor, {
			arg out=0, in = #[0,0,0,0,0,0];
			Out.kr(
				out,
				EnvFollow.kr(in * 0.005, \decayCoef.kr(0.999))
			);
		}).add;
		~ampBus = Bus.control(s, 6);
		~group = ParGroup.tail();
		// ~damp = ~sponge.damperBus.asMap;
	});
	~asPatternList = ~asPatternList.deepCopy.addFunc({
		~inputs = [
			\acc1xHP, \acc1yHP, \acc1zHP,
			\acc2xHP, \acc2yHP, \acc2zHP
		].collect({|i| ~sponge[i].bus});

		~ampExtractor = Synth.tail(Server.default, \ampExtractor, [
			\out, ~ampBus
		]).map( *
			6.collect({|i| [i+1, ~inputs[i]]}).flat;
		);
		1.asPattern;
	});
	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		// wait for ~relTime seconds before freeing ~ampExtractor.
		{
			~server.sendBundle(~relTime, ~ampExtractor.freeMsg );
		}.try; //try block avoids "freeMsg not understood";
	});
	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~ampExtractor.free;
		~ampBus.free;
		~pargroup.free;
	});
}).chuck(PR(\withAmp));

PR(\withAmp).clone({ 					// fm
	~notes = ([ \en1, \en2, \bn2].keynum.mirror2.clump(3)).flat;
	~numNotes = 6;
	~prepList = ~prepList.deepCopy.addFunc({
		SynthDef(\fm, {
			arg out = 0, gate=1, att=0.3;
			var ctls, mods, sig, in;
			ctls = Array.fill(6, {|i|
				[
					(\freq++i).asSymbol.kr(220),
					0,
					(\amp++i).asSymbol.kr(1)
				]
			});
			mods = Array.fill2D(6, 6, {|x,y|
				var name;
				name = ("mod" ++ x ++ "_" ++ y).asSymbol;
				NamedControl.kr(name, 0);
			});
			sig = FM7.ar(ctls, mods);
			sig = sig * \amps.kr( 0.1!6 );
			Out.ar(
				out,
				Splay.arFill( ~numNotes, { |i|
					sig[i] * EnvGen.kr(
						Env.asr(att,0.1),gate, doneAction:2
					)
				})				
			);
		}).add;

		// Four controls for the pitch are combined:
		//  1. Base pitch: ~notes (midi keynum)
		//  2. Offset from sponge buttons: ~pitchOsBus (in semitones)
		//  3. Pitch bend: ~pbBus (in semitones)
		//  4. Fine pitch variations from interpolator: ~interpolFreqs

		// ~freqBuses hold the resultant.  
		SynthDef(\pitcher, {
			arg out = 0, bendRange=2;
			var base, offset, bend, interpol, freqs;
			base = NamedControl.kr(\base, ~notes);
			offset = NamedControl.kr(\offset, 0);
			bend = NamedControl.kr(\bend, 0);
			bend = bend.linlin(-pi, pi, bendRange * -1, bendRange); 
			interpol = NamedControl.kr(
				\interpol, [0,0,0,0,0,0]
			) * NamedControl.kr(
				\coefImpactHauteur, 1.0 // adjust the impact of interpolator (for experiment);
			);

			freqs = (base + offset + bend + interpol).midicps;
			ReplaceOut.kr(out, freqs);
		}).add;

		~pitchOsBus = Bus.control(s, 1);
		~freqBuses = Bus.control(s, ~notes.size);
		~bus = Bus.audio(s, 2);
		~pargroup = ParGroup.tail();
		~damp = BP(\sponge).damperBus.asMap;

		// This stores out the index of the \interpol control input.
		// Is there a better way to do this?
		~interpolId = SynthDescLib.global[
			\pitcher
		].controls.collect(_.name).indexOf(\interpol);
	});

	~asPatternList = ~asPatternList.copy.addFunc({
		~pitcher = Synth.head(~pargroup,\pitcher, [
			\out, ~freqBuses.index,
			\bendRange, 2,
			\base, ~notes,
			\bend, 0
		]).map(
			// \bend, ~sponge[\bend].bus,
			\offset, ~pitchOsBus
		);

		// map freq interpolator to pitcher synth
		~pitcher.map( *
			6.collect({|i|
				[~interpolId + i , ~interpolator.cursor.parameters[i*2].bus]
			}).flat;			
		);

		~fm = Synth.after(~pitcher, \fm, [
			// \out, ~bus.index,
			\out, 0
			// \amp, 0.1
		]);

		~fm.map( \amps, ~ampBus);
		
		// Map output of pitcher to fm freqs.
		~fm.map( *
			~notes.size.collect({|i|
				[(\freq ++ i).asSymbol, ~freqBuses.subBus(i)]
			}).flat;
		);

		// Map interpolator amps to fm amps
		~fm.map( *
			~interpolator.cursor.parameters.select({|i|
				i.name.beginsWith("amp");
			}).collect({|param|
				[param.name.asSymbol, param.bus]
			}).flat;
		);

		// Map interpolator mods to fm mods
		~fm.map( *
			~interpolator.cursor.parameters.select({|i|
				i.name.beginsWith("mod");
			}).collect({ |param|
				[param.name.asSymbol, param.bus]
			}).flat;
		);

		1.asPattern;
	});

	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		~pitcher.free;
		~fm.release(~relTime);
	});

	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~bus.free;
		~pargroup.free;
	});
}).chuck(PR(\fm));