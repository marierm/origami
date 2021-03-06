// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???
// Permettre d'enregistrer les gestes du partenaire?
// Debugger pitcher not understood
// mettre le double-clique plus long
// Régler message pitcher not understood sur pbOn.
// Trouver une facon de jouer legato
v = {SinOsc.ar([\a2,\c3].collect({|i| i.asNote.freq}),0,[0.1,0.1])}.play;
v.free;



// pour Martin
("jack_netsource -n1 -H 10.10.10.2 -N spongaboon").unixCmd;


// pour spongaboon (Marc) (si avec Martin)
~jack = ("jackd -R -d netone -n1").unixCmd;
s.boot;
("jack_connect SuperCollider:out_1 system:playback_1
jack_connect SuperCollider:out_2 system:playback_2").unixCmd;



("kill" + ~jack).unixCmd;

// pour spongaboon (Marc) (si seul)
("jackd -R -dalsa -dhw:0 -r48000 -p128 -n2").unixCmd;
s.boot;
("jack_connect SuperCollider:out_1 system:playback_1
jack_connect SuperCollider:out_2 system:playback_2").unixCmd;

// ("jack_connect spongaboon:capture_1 ebumeter:in.L
// jack_connect spongaboon:capture_2 ebumeter:in.R").unixCmd;

//PERFORMANCE MODE!!!!!!!!!!!!!!
// Sound check:
// Myriam: 8 barres
// Martin: 100%
// Forme
//
// 5 + 7
// 3 cycles de E B G C F
// 1 cycle en 6:4
// 2 cycles sur 5+7 build up

//todo

// faire muter
// préparer changement de mapping

(
// Server.program = "/usr/local/bin/scsynth";
{
	var i;
    s.bootSync;
    "prep/sponge.scd".loadRelative;
	1.wait;
	s.sync;
    BP(\sponge).play;
	"prep/parents.scd".loadRelative;
    "prep/fm.scd".loadRelative;
	"prep/granSin.scd".loadRelative;
	s.sync;
    3.do({|i|
    // 4.do({|i|
        PR(\fm).chuck(BP(i), parms:(
			interpolatorPath: ("fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
			notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
			numNotes: 2,
			fsrMuteThreshold: 0.85 // larger number = muting is easier
		));
		// 4.wait;
		s.sync;
		("ready"++i).postln;
    });
	i = 3;
	PR(\fm).chuck(BP(i), parms:(
		interpolatorPath: ("fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
		notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
		numNotes: 6
	));
	// 4.wait;
	s.sync;
	("ready"++i).postln;


	// PR(\granSin).chuck(BP(0) , parms:(
	// 	interpolatorPath: ("granSin"++0++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
	// 	notes: [ \en1 ].keynum,
	// 	numNotes: 1
	// ));

	// ("prep/feu.scd").loadRelative;
	s.sync;
	// PR(\granule).chuck(BP(\feu), parms:(
	// 	interpolatorPath: ("presets/feu0*").resolveRelative.pathMatch.sort.last.resolveRelative,
	// 	// interpolatorPath: ("feu_2013-07-15.pri").resolveRelative,
	// 	// Date.getDate.format(
	// 	// 	"feu_%Y-%m-%d.pri").resolveRelative,
	// 	audioFilePath: "samples/feuHuards.aiff".resolveRelative
	// ));
	// 5.wait;
	// \readyFeu.postln;
}.fork;
)

// adjust mute threshold
BP(0).ampExtractor.set(\threshold, 0.85);


// Pour Marc (pour répéter): exécuter cette parenthèse.
(
// Il est possible d'ajouter des sections (et des boutons).
// en ajoutant des items dans les arrays ci-dessous.
// Les temps sont en samples (48000 samples par seconde).
// Les noms sont arbitraires.
var sections = ["01-intro", "02-transition", "03-duel", "04-5+7", "05-harmonies"];
var times = [107112,6743072,11363750,15326004,24751658];
var parties = ["Martin", "Marc"];
var window, buttons, synth, buffs, synths;
var fileNames, pause;

fileNames = ["01-martin-150714_1856.wav", "02-marc-150714_1907.wav"];
{
	buffs = fileNames.collect({ |i|
		Buffer.read(s, ("origamiReaper" +/+ i).resolveRelative)
	});

	SynthDef(\bufReader, {|out=0, startPos=0, rate=0, bufnum=0, t_trig=0, amp=0|
		Out.ar(
			out,
			PlayBuf.ar(2, bufnum, rate, t_trig, startPos) * amp
		);
	}).add;

	s.sync;

	synths = buffs.collect({ |i|
		Synth(\bufReader, [\bufnum, i.bufnum ]);
	});
}.fork;

window = Window("Pratique pour Marc.", 1000@200).front;

pause = [
	Button().states_(
		[
			["Pause"],
			["Paused"]
		]
	).action_({ |butt|
		synths.do({ |i|
			i.set(\rate, (butt.value * -1) + 1);
		});
	})
];
buttons = [
	Array.fill(times.size, {|j|
		Button().states_(
			[[sections[j]]]
		).action_({ |butt|
			synths.do({ |i|
				i.set(\rate, 1, \startPos, times[j], \t_trig, 1);
			});
			pause[0].value_(0);
		})
	}),
	Array.fill(2, {|j|
		Button().states_(
			[
				[parties[j], Color.gray(0.7)],
				[parties[j], Color.gray(0.1)]
			]
		).action_({ |butt|
			synths[j].set(\amp, butt.value);
		})
	}) ++ pause
];

window.layout_( GridLayout.rows(*buttons) ).front;
window.onClose_({
	synths.do(_.free);
	buffs.do(_.free);
});
)


BP(3).chords = ([
	BP(3).notes.deepCopy,
	[ \en2, \en3, \gn3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \dn3, \fs3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \cn3, \gn3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \bn2, \an3, \dn4, \fs4, \bn4].keynum,

	[ \en2, \en3, \cn4, \dn4, \fs4, \bn4].keynum,
	[ \en2, \dn3, \gn3, \cn4, \fs4, \bn4].keynum,
	[ \en2, \cn3, \gn3, \bn3, \fs4, \bn4].keynum,
	[ \en2, \dn3, \fs3, \bn3, \en4, \an4].keynum
	// [ \en1, \bn1, \cn3, \dn4, \fs4, \bn4].keynum,
]);


BP(0).interpolator.gui;
BP(0).interpolator.newSave(Date.getDate.format("granSin"++0++"_%Y-%m-%d.pri").resolveRelative)

BP(\sponge).sponge.gui


x.gui

( // Save all interpolators.
4.do({|i|
	BP(i).interpolator.newSave(
		Date.getDate.format("fm"++i++"_%Y-%m-%d.pri").resolveRelative
	);
});
)
BP(\feu).interpolator.newSave(
	Date.getDate.format("feu0_%Y-%m-%d.pri").resolveRelative
);
)


BP(0).damper.set(\max, 900);
BP(0).damper.set(\min, 100);
BP(0).damper.set(\curve, 5);


BP(0).interpolator.gui;
BP(2).notes = BP(2).notes -24
BP(\feu).interpolator.gui;
ChuckableBrowser()
BP(\sponge).sponge.gui;


(2r1111111111 & 2r1).asBinaryDigits(10)
(2r1100000000 & 2r1000000000).asBinaryDigits(10)


PR(\fm).chuck(BP(0), parms:(
	interpolatorPath: ("fm"++0++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
	notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (0 * 12),
	numNotes: 2
));

BP(0).interpolator.newSave(
	Date.getDate.format("fm"++0++"_%Y-%m-%d.pri").resolveRelative
);

Server.program = "/usr/local/bin/scsynth";

BP(3).chords = ([
	BP(3).notes.deepCopy,
	[ \en2, \en3, \gn3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \dn3, \fs3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \cn3, \gn3, \dn4, \fs4, \bn4].keynum,
	[ \en2, \bn2, \an3, \dn4, \fs4, \bn4].keynum,

	[ \en2, \en3, \cn4, \dn4, \fs4, \bn4].keynum,
	[ \en2, \dn3, \gn3, \cn4, \fs4, \bn4].keynum,
	[ \en2, \cn3, \gn3, \bn3, \fs4, \bn4].keynum,
	[ \en2, \dn3, \fs3, \bn3, \en4, \an4].keynum
	// [ \en1, \bn1, \cn3, \dn4, \fs4, \bn4].keynum,
]);

x =  Pbind(
	\tempo, 120/60, // à 120 bpm
	\db, Pwrand([
		Pseq([0,-15,0,-15,-15,0,-15,0,-15,0,-15,-15] - 20, 1), // pattern 2+3+2+2+3
		Pseq([0,-15,0,-15, 0,-15,0,-15,0,-15,0,-15] - 20, 1),  // noires
		Pseq([0,-15,-15,0,-15,-15,0,-15,-15,0,-15,-15] - 20, 1), // noires pointées
		Pseq([-20] ++ (Rest ! 11), 1) // rien jouer
	],[
		1, // 50% des chances de jouer le pattern 2+3+2+2+3
		0, // 20% des chances de jouer des noires
		0, // 20% des chances de jouer des noires pointées
		0 // 10% des chances de jouer rien
	], inf),
	\midinote, 64, // jouer un mi
	\dur, 0.5, // toutes des croches
	\legato, 0.1 // jouer des notes assez courtes
).play;
x.stop;// arrêter le métronome.

BP.freeAll;



BP(\sponge).butts.modes[1].buttonFunctions[0].functions


BP(\sponge).sponge.values.dump

~sponge = SpongePD(baudRate:115200);


(
~old = 0;
~sponge.action_({|data|
	var ids;
	ids = (	data[8] bitXor: ~old);
	// If at least one bit changed:
	ids.asBoolean.if({
		data[8].postln;
		ids.postln;
	});
	~old = data[8];
});
)
Int16Array

~sponge = SpongeOSC();
~sponge.gui;


Int8Array.newFrom([1,2,256])

Integer

~values = Int16Array.newClear(9);
OSCdef(\moo, {|data|
	data[1].pairsDo({|msb, lsb, i|
		~values[i/2] = ((msb << 3) | (lsb & 7));
	});
	// ~values.postln;
}, "/sponge/mm", nil, 0x6D6D);

OSCdef(\sponge).dump