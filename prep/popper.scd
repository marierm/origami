PR(\withChordsFeu).clone({ //popper
	~out = 0;
	~tetra = false;
	~prepList = ~prepList.deepCopy.addFunc({
		~tetra.if({ // Quad
			SynthDef(\manualPops, {
				|out=0, outBus=30, dust=0, amp=1.0, rq=0.35, delRange=0.0017, fltMin=100, fltMax=8000|
				var posFront, posRear;
				posFront = WhiteNoise.kr(1.0);
				posRear = WhiteNoise.kr(1.0);
				dust = DelayN.ar(
					dust,
					0.2, // Random position in space with delays.
					[
						posFront.clip(0,1.0) * delRange,
						posFront.clip(-1.0,0).abs * delRange,
						posRear.clip(-1.0,0).abs * delRange,
						posRear.clip(0,1.0) * delRange
					],
					amp
				);
				// dust = BPF.ar(dust, WhiteNoise.kr().range(fltMin,fltMax), rq );
				dust = BPF.ar(PinkNoise.ar(Decay.ar(dust,0.001)), WhiteNoise.kr().range(80,4000));
				dust = GVerb.ar(
					in:dust,
					roomsize:50,
					revtime:0.5,
					damping: 0.5,
					inputbw: 0.5,
					spread: 100,
					drylevel: 1,
					earlyreflevel: 0.005,
					taillevel:0.1
				);
				dust = LeakDC.ar(dust);
				Out.ar( outBus, dust);
				Out.ar( out, dust );
			}).add;
			~popBus = Bus.audio(Server.default, 4);
		}, { // Stereo
			SynthDef(\manualPops, {
				|out=0, outBus=30, dust=0, amp=1.0, rq=0.35, delRange=0.0017, fltMin=100, fltMax=8000|
				var pos;
				pos = WhiteNoise.kr(1.0);
				dust = DelayN.ar(
					dust,
					0.2, // Random position in space with delays.
					[pos.clip(0,1.0) * delRange, pos.clip(-1.0,0).abs * delRange],
					amp
				);
				// dust = BPF.ar(dust, WhiteNoise.kr().range(fltMin,fltMax), rq );
				dust = BPF.ar(PinkNoise.ar(Decay.ar(dust,0.001)), WhiteNoise.kr().range(80,4000));
				dust = GVerb.ar(
					in:dust,
					roomsize:50,
					revtime:0.5,
					damping: 0.5,
					inputbw: 0.5,
					spread: 100,
					drylevel: 1,
					earlyreflevel: 0.005,
					taillevel:0.1
				);
				dust = LeakDC.ar(dust);
				Out.ar( outBus, dust);
				Out.ar( out, dust );
			}).add;

			~popBus = Bus.audio(Server.default, 2);
		});
		
		{
			~sponge.activateFeature(\acc1xHP);
			Server.default.sync;
			~sponge.activateFeature(\acc1xTrig);
		}.fork;
	});

	~asPatternList = ~asPatternList.deepCopy.addFunc({
		~manualPops = Synth.after(~pitcher, \manualPops, [
			\out, ~out,
			\outBus, ~popBus
		]);

		~manualPops.map(
			\dust, ~sponge[\acc1xTrig].bus
			// \dur, ~interpolator.cursor.parameters[0].bus,
			// \rate, ~interpolator.cursor.parameters[1].bus,
			// \pos, ~indexBus
		);

		1.asPattern;
	});

	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		{
			~manualPops.free;
		}.try;
	});

	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~popBus.free;
	});

}).chuck(PR(\popper));