// Fix removepoint; Ajouter contrôle de seuil et de durée dans l'interpolateur
// feu.  Seuil sur capteur de pression???

Coucou

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
			// path: ("fm7_2013-07-14_" ++ i ++ ".pri").resolveRelative,
			path: Date.getDate.format("fm7_%Y-%m-%d_" ++ i ++ ".pri").resolveRelative,
			notes: ([ \en1, \en2, \bn2].keynum.mirror2.clump(3)).flat
		));
    });
	("prep/feu.scd").loadRelative;
	1.wait;
	PR(\granule).chuck(BP(\feu), parms:(
		interpolatorPath: Date.getDate.format(
			"feu_%Y-%m-%d.pri").resolveRelative,
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
		Date.getDate.format("fm7_%Y-%m-%d_" ++ i ++".pri").resolveRelative
	);
});
BP(\feu).interpolator.newSave(
	Date.getDate.format("feu_%Y-%m-%d.pri").resolveRelative
);
)

BP(0).interpolator.gui;
BP(\feu).interpolator.gui;
ChuckableBrowser()
BP(\sponge).sponge.gui;

