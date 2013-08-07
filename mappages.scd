// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???
// Changer côté des boutons.
// Ajouter pression -> damping.
// Changer add pour store dans les synthdefs d'interpolation.
// Ajouter des "done signal".
// 

BP.freeAll;
(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
	s.sync;
    BP(\sponge).play;
    "prep/fm.scd".loadRelative;
	s.sync;
    4.do({|i|
        PR(\fm).chuck(BP(i), parms:(
			interpolatorPath: ("presets/fm"++i++"*").pathMatch.sort.last.resolveRelative,
			notes: ([ \en1, \en2, \en3].keynum.mirror2.clump(3)).flat + (i * 12),
			numNotes: 2
		));
		s.sync;
		("ready"++i).postln;
    });
	("prep/feu.scd").loadRelative;
	s.sync;
	PR(\granule).chuck(BP(\feu), parms:(
		interpolatorPath: ("presets/feu0*").pathMatch.sort.last.resolveRelative,
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


BP(3).interpolator.gui;
BP(2).notes = BP(2).notes -24
BP(\feu).interpolator.gui;
ChuckableBrowser()
BP(\sponge).sponge.gui;


y = InterpolatorServer();
x = PresetInterpolatorServer(y);
x.free
