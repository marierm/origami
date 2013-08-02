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
	2.wait;
    BP(\sponge).play;
    "prep/fm.scd".loadRelative;
	4.wait;
	PR(\fm).chuck(BP(0), parms:(
		interpolatorPath: ("exp_2013-08-01.pri").resolveRelative,
		notes: [\en3, \en3, \en1, \en2, \bn3, \en4].keynum,
		numNotes: 2
	));
	2.wait;
	BP(0).play;
	BP(\sponge).butts.mode_(1);
	\ready.postln;
	~win.front;
	{
		~sliderSens.valueAction_(0);
		~sliderHaut.valueAction_(0);
	}.defer;
}.fork;
~resFile = CSVFileWriter(
	"resultats".resolveRelative +/+ Date.getDate.format("res-sujet_%Y-%m-%d_%H-%M-%S")
);
~resList = List();
(
~win = Window(
	"Contrôles", 
	Rect.aboutPoint( Window.screenBounds.center, 400, 20)
).layout_(
	HLayout(
	VLayout(
		HLayout(
			~sliderSens = Slider().orientation_(\horizontal).minWidth_(600),
			~noteSens = TextField()
		),
		HLayout(
			~sliderHaut = Slider().orientation_(\horizontal).minWidth_(600),
			~noteHaut = TextField()
		)
	),
		Button().states_([["Prout!"]]).minHeight_(40).action_({
			~resFile.writeLine(
				[
					Date.getDate.format("%Y-%m-%d %H:%M:%S"),
					~valSens,
					~noteSens,
					~valHaut,
					~valSens
				]
			);
		})
	)
).front;
)

~spec = ControlSpec(0.7,0.999999,-10);
~valSens = ~spec.map(~sliderSens.value);
~valHaut = ~sliderHaut.value;
~sliderSens.action_({|sl|
	BP(0).ampExtractor.set(\decayCoef, ~spec.map(sl.value));
	~valSens = ~spec.map(~sliderSens.value);
});
~sliderHaut.action_({|sl|
	BP(0).pitcher.set(\coefImpactHauteur, sl.value);
	~valHaut = ~sliderHaut.value;
});
~win.onClose_({|w|
	~resFile.writeLine(
		[
			Date.getDate.format("%Y-%m-%d %H:%M:%S"),
			~valSens,
			~noteSens,
			~valHaut,
			~valSens
		]
	);
	~resFile.close;
	BP(0).stop;
});
)

( // Save interpolator 1 (for experiment).
BP(0).interpolator.newSave(
	Date.getDate.format("exp_2013-08-01.pri").resolveRelative
);
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
