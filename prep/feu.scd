PR(\abstractProcess).v.clone({
	~audioFilePath = "../samples/feuHuards.aiff".resolveRelative;
	// ~interpolatorPath = Date.getDate.format("feu_%Y-%m-%d_" ++ i ++ ".pri").resolveRelative;
	~interpolatorPath = nil;
	~sponge = BP(\sponge).sponge;
	~numCoeff = 6;
	// ~onsetSens = 0.5;
	// ~onsetType = \rcomplex;
	~onsetSens = 2.0;
	~onsetType = \power;
	~onsetDur = 6000;
	~out = 0;
	
	~prep = {
		// ~scmirAudioFile = SCMIRAudioFile(~audioFilePath,[[\MFCC, ~numCoeff]]);
		~scmirAudioFile = SCMIRAudioFile(~audioFilePath,[[\SpecCentroid]]);
		~scmirAudioFile.extractFeatures(normalize:false); 
		~scmirAudioFile.extractOnsets(~onsetSens, ~onsetType);
		~scmirAudioFile.gatherFeaturesByOnsets(dur: ~onsetDur);
		~centroids = ~scmirAudioFile.featuredata;
		~onsets = ~scmirAudioFile.onsetdata;
		
		// Sort onsets according to centroids.  Store in a buffer.
		~indicesBuf = Buffer.loadCollection(
			Server.default,
			~onsets.at(~centroids.order)
		);

		// ~position = Array.fill(~numCoeff,{0});
		// ~ranges = ~centroids.flop.collect({|i| [i.minItem, i.maxItem]});
		~range = [~centroids.minItem, ~centroids.maxItem];

		~interpolator = PresetInterpolatorServer.newLoad(
			~interpolatorPath
		);

		SynthDef(\granuleur, {
			arg out=0,trigger=1.0, dur=0.1, bufnum = #[0,1],
			rate=1.0, pos=0, gate=1, envbufnum;
			// var trigger, sig;
			var sig;
			// trigger = Impulse.ar(triggerFreq);
			sig = GrainBuf.ar(
				numChannels:1,
				trigger:trigger,
				dur:dur,
				sndbuf:bufnum,
				rate:rate,
				pos:pos,
				interp:2,
				pan:0,
				envbufnum:envbufnum,
				maxGrains:512
			);
			Out.ar(out, sig);
		}).add;

		// Maps a value between 0 and 1 to a position in the buffer.  The
		// buffer indicesBuf contains time indices sorted according to the
		// centroid of the segment.
		SynthDef(\posMapper, {
			arg out=0, in=0.5, sampleBufnum=0, indicesBufnum=1;
			Out.kr(
				out,
				BufRd.kr(
					1, 
					indicesBufnum,
					in * BufFrames.kr(indicesBufnum)
				) / BufDur.kr(sampleBufnum)
			);
		}).add;

		~indexBus = Bus.control();

		~buf = Array.fill(2,{|i|
			Buffer.readChannel(Server.default, ~audioFilePath,0,-1, [i]);
		});
		~envBuf = Buffer.sendCollection(Server.default, Env.perc().asSignal(4096));

		~bus = Bus.audio(Server.default, 2);
		~group = ParGroup();

		{
			~sponge.activateFeature(\acc1xHP);
			Server.default.sync;
			~sponge.activateFeature(\acc1xTrig);
		}.fork;
	};

	~asPattern = {
		~granuleur = Synth.tail(~group, \granuleur, [
			\out, ~out,
			\bufnum, [~buf[0].bufnum, ~buf[1].bufnum],
			\envbufnum, ~envBuf.bufnum
		]);

		~posMapper = Synth.before(~granuleur, \posMapper, [
			\out, ~indexBus, 			// Bus holding the index in sampleBuf
			\sampleBufnum, ~buf[0],
			\indicesBufnum, ~indicesBuf
		]).map(
			\in, ~interpolator.cursor.parameters[3].bus
		);

		~granuleur.map(
			\trigger, ~sponge[\acc1xTrig].bus,
			\dur, ~interpolator.cursor.parameters[0].bus,
			\rate, ~interpolator.cursor.parameters[1].bus,
			\pos, ~indexBus
		);

		6.do({ |i|
			~interpolator.connect(i, ~sponge.features[i]);
		});

	};

	~stopCleanup = {
		~sponge.action = ~sponge.action.removeFunc(~func);
		~granuleur.free;
		~posMapper.free;
		6.do({ |i|
			try { ~interpolator.disconnect(i) };
		});
	};

	~freeCleanup = {
		~bus.free;
		~group.free;
		~buf.free;
		~envBuf.free;
		~indicesBuf.free;	
		~indexBus.free;
	};

}) => PR(\granule);

