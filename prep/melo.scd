// withLists
// -> withSponge
//  -> withInterpolator
//   -> withAmp
//    -> withDamp
//     -> withPitch
//      -> withChords
//       -> popper
//        -> melo

PR(\popper).clone({
	~prepList = ~prepList.deepCopy.addFunc({
		~tetra.if({
			SynthDef(\rzn, {
				arg out=0, in=0, gate=1, att=0.3, coef=0.4, decay=5, freq0=440, amp=0.2;
				var sig, freq;
				freq = freq0.reciprocal;
				freq = [freq, freq * 1.001];
				coef = [coef, coef * 1.1];
				sig = Pluck.ar(
					in:In.ar(in, 4),
					trig:In.ar(in, 4),
					maxdelaytime:0.5,
					delaytime:freq,
					decaytime:decay,
					coef: coef,
					mul: amp
				);
				// sig = sig * \amps.kr( 0.1!6 );
				Out.ar(	out, LeakDC.ar(sig) );
			}).add;
		},{
			SynthDef(\rzn, {
				arg out=0, in=0, gate=1, att=0.3, coef=0.4, decay=5, freq0=440, amp=0.2;
				var sig, freq;
				freq = freq0.reciprocal;
				freq = [freq, freq * 1.001];
				coef = [coef, coef * 1.1];
				sig = Pluck.ar(
					in:In.ar(in, 2),
					trig:In.ar(in, 2),
					maxdelaytime:0.5,
					delaytime:freq,
					decaytime:decay,
					coef: coef,
					mul: amp
				);
				// sig = sig * \amps.kr( 0.1!6 );
				Out.ar(	out, LeakDC.ar(sig) );
			}).add;
		});
	});

	~asPatternList = ~asPatternList.deepCopy.addFunc({
		//Make sure everything is clean.
		~rzn.isPlaying.if({
			~rzn.free;
			~pitcher.free;
		});

		~server.makeBundle(nil,{

			~rzn = Synth.after(~manualPops, \rzn, [
				// \out, ~bus.index,
				\out, 0,
				\in, ~popBus
				// \amp, 0.1
			]);

			// ~rzn.map( \amp, ~globalAmpBus);
			
			// Map output of pitcher to rzn freq.
			~rzn.map( *
				~notes.size.collect({|i|
					[ (\freq ++ i).asSymbol, ~freqBuses.subBus(i) ]
				}).flat;
			);

			// Map decay and coef from interpolator to rzn
			~rzn.map( *
				~interpolator.cursor.parameters.select({|i|
					i.name.beginsWith("decay");
				}).collect({|param|
					[param.name.asSymbol, param.bus]
				}).flat;
			);
			~rzn.map( *
				~interpolator.cursor.parameters.select({|i|
					i.name.beginsWith("coef");
				}).collect({ |param|
					[param.name.asSymbol, param.bus]
				}).flat;
			);

			// ~pitcher.map( *
			// 	~notes.size.collect({|i|
			// 		[~interpolId + i , ~interpolator.cursor.parameters[i*2].bus]
			// 	}).flat;			
			// );
			NodeWatcher.register(~rzn);
		});
		1.asPattern;
	});

	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		~rzn.isPlaying.if({
			~rzn.free;
		});
	});

	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		// ~bus.free;
	});
}).chuck(PR(\melo));