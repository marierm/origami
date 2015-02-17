// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???
// Permettre d'enregistrer les gestes du partenaire?
// Debugger pitcher not understood
// mettre le double-clique plus long
// Régler message pitcher not understood sur pbOn.
// Trouver une facon de jouer legato
v = {SinOsc.ar(Array.series(16, 100, 100),0,[0.1,0.1])}.play;
v.free;

Server.program = "/usr/local/bin/scsynth";


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
Server.program = "/usr/local/bin/scsynth";
{
	var i;
    s.bootSync;
    "prep/sponge.scd".loadRelative;
	1.wait;
	s.sync;
    BP(\sponge).play;
	"prep/parents.scd".loadRelative;
	"prep/parentsFeu.scd".loadRelative;
    "prep/fm.scd".loadRelative;
	"prep/granSin.scd".loadRelative;
	"prep/feu.scd".loadRelative;
	"prep/popper.scd".loadRelative;
	"prep/melo.scd".loadRelative;
	s.sync;
    // 3.do({|i|
    // 4.do({|i|
	i = 0;
	PR(\fm).chuck(BP(i), parms:(
		interpolatorPath: ("fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
		notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
		numNotes: 2,
		fsrMuteThreshold: 0.85 // larger number = muting is easier
	));
	// 4.wait;
	s.sync;
	// PR(\player).chuck(BP(\feu), parms:(
	// 	audioFilePath: "samples/05-feu.wav".resolveRelative,	
	// 	attackTime: 15,
	// 	relTime: 12,
	// 	tetra: true
	// ));
	s.sync;
	// PR(\player).chuck(BP(3), parms:(
	// 	audioFilePath: "samples/01-flm.wav".resolveRelative,
	// 	attackTime: 5,
	// 	relTime: 1,
	// 	amp: -12.dbamp,
	// 	tetra: true,
	// 	ampCtl: true
	// ));
	("ready"++i).postln;
    // });
	i = 3;
	PR(\fm).chuck(BP(i), parms:(
		interpolatorPath: ("fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
		notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
		numNotes: 6
	));
	// 4.wait;
	s.sync;
	("ready"++i).postln;

}.fork;
)

(
PR(\melo).chuck(BP(1), parms:(
	interpolatorPath: ("popMelo"++1++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
	tetra: true
));
)
(
PR(\popper).chuck(BP(2), parms:(
	interpolatorPath: ("popMelo"++1++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
	tetra: true
));
)


// adjust mute threshold
BP(0).ampExtractor.set(\threshold, 0.85);


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