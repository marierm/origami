// withLists
// -> withSponge
//    -> withInterpolator
//       -> withAmp
//          -> fm
//          -> granule

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
