// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???

BP.freeAll;
(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
    1.wait;
    BP(\sponge).play;
    2.wait;
    "prep/fm.scd".loadRelative;
    1.wait;
    4.do({|i|
        PR(\fm).chuck(BP(i), parms:(
			interpolatorPath: ("presets/fm"++i++"*").pathMatch.sort.last.resolveRelative,
			// path: ("fm7_2013-07-14_" ++ i ++ ".pri").resolveRelative,
			notes: ([ \en1, \en2, \bn2].keynum.mirror2.clump(3)).flat + (i * 12),
			numNotes: 2
		));
    });
	("prep/feu.scd").loadRelative;
	1.wait;
	PR(\granule).chuck(BP(\feu), parms:(
		interpolatorPath: ("presets/feu0*").pathMatch.sort.last.resolveRelative,
		// interpolatorPath: ("feu_2013-07-15.pri").resolveRelative,
		// Date.getDate.format(
		// 	"feu_%Y-%m-%d.pri").resolveRelative,
		audioFilePath: "samples/feuHuards.aiff".resolveRelative
	));
	5.wait;
	// BP(\feu).play;
    \ready.postln;
}.fork;
)

( // Save all four interpolators.
4.do({|i|
	BP(i).interpolator.newSave(
		Date.getDate.format("fm"++i++"_%Y-%m-%d.pri").resolveRelative
	);
});
BP(\feu).interpolator.newSave(
	Date.getDate.format("feu0_%Y-%m-%d.pri").resolveRelative
);
)


BP(0).interpolator.gui;
BP(\feu).interpolator.gui;
ChuckableBrowser()
BP(\sponge).sponge.gui;

y = InterpolatorServer();
x = PresetInterpolatorServer(y);
x.free
