// withLists
// -> withSponge
//  -> withInterpolator
//   -> withAmp
//    -> withDamp
//     -> withPitch
//      -> granulotron

PR(\withChords).clone({ 					// granulotron
	~audioFilePath = "../samples/granulotron/*.wav".resolveRelative;
	~fileNames = List[];
	~currentBuf = 4;
	~numLiveRecBuf = 10;
	~liveRecBufLen = 48000 * 10.0; // 10 seconds.
	~liveRecBufNumChan = 2;
	~prevBuf = {
		~currentBuf = (~currentBuf - 1) % ~numPreRecBuf;
		~buffers[~currentBuf][0].path.postln;
		~granulotron.isPlaying.if({
			~granulotron.set(\bufL, ~buffers[~currentBuf][0]);
			~granulotron.set(\bufR, ~buffers[~currentBuf][1]);
		});
	};
	~nextBuf = {
		~currentBuf = (~currentBuf + 1) % ~numPreRecBuf;
		~buffers[~currentBuf][0].path.postln;
		~granulotron.isPlaying.if({
			~granulotron.set(\bufL, ~buffers[~currentBuf][0]);
			~granulotron.set(\bufR, ~buffers[~currentBuf][1]);
		});
	};

	
	~prepList = ~prepList.deepCopy.addFunc({
		~buffers = ~audioFilePath.pathMatch.collect({ |path|
			~fileNames.add(path.basename);
			// On assume que ce sont des fichiers 2 canaux (stéréo).
			[
				Buffer.readChannel(Server.default, path, channels: [0]),
				Buffer.readChannel(Server.default, path, channels: [1])
			]
		});
		~numPreRecBuf = ~buffers.size;
		
		SynthDef(\granulotron, {
			arg out=0, gate=1, att=0.2, rel=0.01;
			var trig;
			trig = Impulse.ar(\freq.kr(110));
			Out.ar(out,
				TGrains.ar(
					numChannels: 2,
					trigger: trig,
					bufnum: [\bufL.kr(0), \bufR.kr(1)],		// multichannel expansion!
					rate: \rate.kr(1),
					centerPos: \centerPos.kr(0.5),
					dur: \granDur.kr(0.1),
					pan: [-1,1] * \pan.kr(1),
					amp: \amp.kr(0.1),
					interp: 4
				) * EnvGen.kr(Env.asr(att, 1, rel), gate, doneAction:2);
			)
		}).add;
		~bus = Bus.audio(s, 2);
	});

	~asPatternList = ~asPatternList.deepCopy.addFunc({
		//Make sure everything is clean.
		~granulotron.isPlaying.if({
			~granulotron.free;
			~pitcher.free;
		});

		~server.makeBundle(nil,{

			~granulotron = Synth.after(~pitcher, \granulotron, [
				// \out, ~bus.index,
				\out, 0,
				\bufL, ~buffers[~currentBuf][0],
				\bufR, ~buffers[~currentBuf][1]
				// \amp, 0.1
			]);

			~granulotron.map( \amp, ~ampBus);

			~granulotron.map( \freq, ~freqBuses.subBus(0));
			
			// Map interpolator
			[\rate, \centerPos, \granDur].do({|i,j|
				~granulotron.map(i, ~interpolator.cursor.parameters[j+12].bus)
			});

			~pitcher.map( *
				~notes.size.collect({|i|
					[~interpolId + i , ~interpolator.cursor.parameters[i*2].bus]
				}).flat;			
			);
			NodeWatcher.register(~granulotron);
		});
		1.asPattern;
	});

	~stopCleanupList = ~stopCleanupList.deepCopy.addFunc({
		~granulotron.isPlaying.if({
			~granulotron.release(~relTime);
		});
	});

	~freeCleanupList = ~freeCleanupList.deepCopy.addFunc({
		~bus.free;
		~buffers.do(_.free);
	});
}).chuck(PR(\granulotron));