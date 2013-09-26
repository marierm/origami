// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???
// Permettre d'enregistrer les gestes du partenaire?
// Debugger pitcher not understood
// mettre le double-clique plus long
// Server.program = "/usr/local/bin/scsynth";

BP.freeAll;
(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
	1.wait;
	s.sync;
    BP(\sponge).play;
	\moo.postln;
	"prep/parents.scd".loadRelative;
	\2.postln;
    "prep/fm.scd".loadRelative;
	\3.postln;
	s.sync;
    4.do({|i|
        PR(\fm).chuck(BP(i), parms:(
			interpolatorPath: ("fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
			notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
			numNotes: 2
		));
		// 4.wait;
		s.sync;
		("ready"++i).postln;
    });
	("prep/feu.scd").loadRelative;
	s.sync;
	PR(\granule).chuck(BP(\feu), parms:(
		interpolatorPath: ("presets/feu0*").resolveRelative.pathMatch.sort.last.resolveRelative,
		// interpolatorPath: ("feu_2013-07-15.pri").resolveRelative,
		// Date.getDate.format(
		// 	"feu_%Y-%m-%d.pri").resolveRelative,
		audioFilePath: "samples/feuHuards.aiff".resolveRelative
	));
	5.wait;
	\readyFeu.postln;
}.fork;
)




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