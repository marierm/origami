// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???
// Ajouter des "done signal".

// Permettre d'enregistrer les gestes du partenaire?
// S'assurer que les voix "existent" pour éviter les erreurs au premier démarrage d'une voix.
// Debugger pitcher not understood
// Régler problème de démarrage de voix qui s'arrête.

BP.freeAll;
(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
	s.sync;
    BP(\sponge).play;
	"prep/parents.scd".loadRelative;
    "prep/fm.scd".loadRelative;
	s.sync;
    4.do({|i|
        PR(\fm).chuck(BP(i), parms:(
			interpolatorPath: ("presets/fm"++i++"*").resolveRelative.pathMatch.sort.last.resolveRelative,
			notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
			numNotes: 2
		));
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
BP(\feu).interpolator.newSave(
	Date.getDate.format("feu0_%Y-%m-%d.pri").resolveRelative
);
)


BP(0).damper.set(\max, 900);
BP(0).damper.set(\min, 100);
BP(0).damper.set(\curve, 5);


.interpolator.gui;
BP(2).notes = BP(2).notes -24
BP(\feu).interpolator.gui;
ChuckableBrowser()
BP(\sponge).sponge.gui;


(2r1111111111 & 2r1).asBinaryDigits(10)
(2r1100000000 & 2r1000000000).asBinaryDigits(10)
