PR(\abstractProcess).v.clone({
	// ~path = "../fm7_2013-07-09.pri".resolveRelative.postln;
	~path = nil;
	~notes = ([ \en1, \en2, \bn2].keynum.mirror2.clump(3)).flat;

	~prep = {
		~path.postln;
		~sponge = BP(\sponge).sponge;
		~interpolator = PresetInterpolatorServer.newLoad(
			~path
		);

		SynthDef(\fm, {
			arg out = 0, in0 = 0, gate=1, att=0.3, amp=0.1;
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
			in = In.ar(in0, 2);
			Out.ar(
				out,
				Splay.ar(
					sig * EnvGen.kr(
						Env.asr(att,amp),gate, doneAction:2
					)
				)
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
			interpol = NamedControl.kr(\interpol, [0,0,0,0,0,0]);

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
	};

	~asPattern = {
		// ~inputs = Pn([
		// 	\acc1xHP, \acc1yHP, \acc1zHP,
		// 	\acc2xHP, \acc2yHP, \acc2zHP
		// ].collect({|i| ~sponge[i].bus.asMap}));

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
			\out, 0,
			\amp, 0.1
		]);
		
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

		6.do({ |i|
			~interpolator.connect(i, ~sponge.features[i]);
		});

		1.asPattern;
	};

	~stopCleanup = {
		~pitcher.free;
		~fm.release(3);
		6.do({ |i|
			try { ~interpolator.disconnect(i) };
		});
	};

	~freeCleanup = {
		~bus.free;
		~pargroup.free;
		~interpolator.free;
	};

}) => PR(\fm);