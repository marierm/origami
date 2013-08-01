// Changer le rôle des boutons (simplifier le déclenchement)

// Instructions git pour Clara:
// Si les fichiers locaux ne sont pas changés:
// git pull
// 
// Si les fichiers locaux ont changé, il faut exécuté:
// git reset --hard
// avant de faire git pull
// !!!!!ATTENTION!!!!!  Je crois que cette opération effacera les résultats!!
// Il faut donc les copier ailleurs après chaque expérience.

(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
    s.sync;
    BP(\sponge).play;
	s.sync;
    "prep/fm.scd".loadRelative;
	s.sync;
	PR(\fm).chuck(BP(0), parms:(
		interpolatorPath: ("fm7_2013-07-15_" ++ 0 ++ ".pri").resolveRelative,
		notes: ([ \en2, \en3, \bn3].keynum.mirror2.clump(3)).flat
	));
	s.sync;
	BP(0).play;
	BP(\sponge).butts.mode_(1);
	\ready.postln;
	~win.front;
	{~slider.valueAction_(0.5);}.defer;
}.fork;
~resPath = "resultats".resolveRelative +/+ Date.getDate.format("%Y-%m-%d_%H-%M-%S_sens");
~win = Window(
	"Sensibilité",
	Rect.aboutPoint( Window.screenBounds.center, 300, 10)
);
~spec = ControlSpec(0.7,0.999999,-10);
~slider = Slider(~win, 600@20);
~val = ~spec.map(~slider.value);
~slider.action_({|sl|
	BP(0).ampExtractor.set(\decayCoef, ~spec.map(sl.value));
	~val = ~spec.map(~slider.value);
});
~win.onClose_({|w|
	("Sensibilité:" + ~val).postln;
	BP.freeAll;
	(
		"echo" + ~val + ">" + ~resPath
	).unixCmd;
});
)

(
{
    s.bootSync;
    "prep/sponge.scd".loadRelative;
    s.sync;
    BP(\sponge).play;
	s.sync;
    "prep/fm.scd".loadRelative;
	s.sync;
	PR(\fm).chuck(BP(0), parms:(
		interpolatorPath: ("fm7_2013-07-15_" ++ 0 ++ ".pri").resolveRelative,
		notes: ([ \en2, \en3, \bn3].keynum.mirror2.clump(3)).flat
	));
	s.sync;
	BP(0).play;
	BP(\sponge).butts.mode_(1);
	\ready.postln;
	~win.front;
	{~slider.valueAction_(0.5);}.defer;
}.fork;
~resPath = "resultats".resolveRelative +/+ Date.getDate.format("%Y-%m-%d_%H-%M-%S_hauteur");
~win = Window(
	"Contrôle des hauteurs", 
	Rect.aboutPoint( Window.screenBounds.center, 300, 10)
);
~slider = Slider(~win, 600@20);
~val = ~slider.value;
~slider.action_({|sl|
	BP(0).pitcher.set(\coefImpactHauteur, sl.value);
	~val = ~slider.value;
});
~win.onClose_({|w|
	("Coef hauteur: " + ~val).postln;
	BP.freeAll;
	(
		"echo" + ~val + ">" + ~resPath
	).unixCmd;
});
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

