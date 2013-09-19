PR(\withDamp).clone({
	~out = 0;
	~prepList = ~prepList.deepCopy.addFunc({

		~envBuffers = [
			Env.sine(),
			Env.triangle(),
			Env.perc(0.01, 1, 1, -4),
			Env.perc(0.001, 1, 1, -4),
			Env.perc(0.01, 1, 1, -8),
			Env.perc(0.001, 1, 1, -8),
			Env.perc(1, 0.01, 1, 4)		// reverse
		].collect({|i|
			Buffer.sendCollection(Server.default, i.asSignal(4096))
		});

		SynthDef(\granSin, {|out=0|
			Out.ar(
				out,
				GrainSin.ar(
					numChannels: 2, 
					trigger: \trigger.ar(0.0),
					dur: \dur.kr(0.01),
					freq: TExpRand.ar(
						lo: \freqLo.kr(220),
						hi: \freqHi.kr(440),
						trig: trig
					),
					pan: \pan.kr(0.0),
					envbufnum: \bufnum.kr(~envBuffers[0].bufnum),
					maxGrains: 4096,
					mul: \amp.kr(0.1)
				)
			);
		}).add;

		SynthDef(\trigGenerator, {|out=100|
			Out.ar(
				out,
				XFade2.ar(
					Dust.ar(\density.kr(100)),
					LFPulse.ar(\freq.kr(220)),
					\balance.kr(0)
				)
			)
		});

		~trigBus = Bus.audio(Server.default, 1);
		~bus = Bus.audio(Server.default, 2);
		~group = ParGroup();

	});

	~asPatternList = ~asPatternList.deepCopy.addFunc({
		~granSin = Synth.tail(~group, \granSin, [
			\out, ~out
		]);

		~trigGenerator = Synth.before(~granSin, \trigGenerator, [
			\out, ~trigBus
		]).map(
			\density, ~interpolator.cursor.parameters[0].bus,
			\freq, ~interpolator.cursor.parameters[1].bus,
			\balance, ~interpolator.cursor.parameters[2].bus
		);

		~granSin.map(
			\trigger, ~trigBus,
			\dur, ~interpolator.cursor.parameters[3].bus,
			\freqLo, ~interpolator.cursor.parameters[4].bus,
			\freqHi, ~interpolator.cursor.parameters[5].bus,
			\pan, ~interpolator.cursor.parameters[6].bus,
			\amp, ~interpolator.cursor.parameters[7].bus,
			\pos, ~indexBus
		);

		// Map envBuffers

		1.asPattern;
	});

	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		{
			~granSin.free;
			~trigGenerator.free;
		}.try;
	});

	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~bus.free;
		~group.free;
		~envBuffers.do(_.free);
	});

}).chuck(PR(\granSin));

