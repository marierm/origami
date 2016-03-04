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
	~numLiveRecBuf = 4;
	~sr = Server.default.sampleRate;
	~liveRecBufLen = ~sr * 10.0; // 10 seconds.
	~liveRecBufNumChan = 2;
	~liveRecLength = 4.0;
	~destBuf = 0;
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
	OSCdef(\getLiveRecBufPos,{ |time, msg|
		var bufPos, id;
		
		bufPos = msg[3];
		id = msg[2];
		(id == 0).if({
			~liveRecBufNumChan.do({|i|
				~liveRecBuf[i].copyLoopTo(
					buffer: ~liveBuffers[~destBuf.asInteger][i],
					dstStartAt: 0,
					srcStratAt: bufPos,
					numSamples: ~liveRecLength * ~sr
				);
			});
		});
	}, "/tr", Server.default.addr);
	
	~copyLiveRecBuf = { |len=4.0|
		~destBuf = len - 2;
		~liveRecLength = len;
		~recorder[0].set(\t_trig, 1.0);
	};

	
	~prepList = ~prepList.deepCopy.addFunc({
		{
			~liveRecBuf = ~liveRecBufNumChan.collect({ |chan|
				Buffer.alloc(
					Server.default, ~liveRecBufLen, 1
				);
			});
			~buffers = ~audioFilePath.pathMatch.collect({ |path|
				~fileNames.add(path.basename);
				// On assume que ce sont des fichiers 2 canaux (pour l'instant).
				[
					Buffer.readChannel(Server.default, path, channels: [0]),
					Buffer.readChannel(Server.default, path, channels: [1])
				]
			});
			~liveBuffers = ~numLiveRecBuf.collect({ |i|
				~liveRecBufNumChan.collect({|chan|
					Buffer.alloc(
						Server.default, (i + 2) * ~sr , 1
					);
				});
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
			SynthDef(\record, {
				arg in=0, buf=0, t_trig, id=0;
				var phasor;
				phasor = Phasor.ar(0, 1, 0, BufFrames.kr(buf));
				BufWr.ar(
					SoundIn.ar(in),
					bufnum: buf,
					phase: phasor
				);
				SendTrig.kr(t_trig, id, phasor);
			}).add;

			Server.default.sync;
			// Always recording, looping over ~liveRecBufLen / 48000 seconds.
			~recorder = ~liveRecBufNumChan.collect({ |i|
				Synth.head(Server.default, \record, [
					\buf, ~liveRecBuf[i],
					\in, i,
					\id, i
				]);
			});
		}.fork;
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