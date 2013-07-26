// Changer le rôle des boutons (simplifier le déclenchement)

// Instructions git pour Clara:
// Si les fichiers locaux ne sont pas changés:
// git pull
// 
// Si les fichiers locaux ont changé, il faut exécuté:
// git reset --hard
// avant de faire git pull

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
    // 4.do({|i|
        // PR(\fm).chuck(BP(i), parms:(
        PR(\fm).chuck(BP(0), parms:(
			interpolatorPath: ("fm7_2013-07-15_" ++ 0 ++ ".pri").resolveRelative,
			// path: ("fm7_2013-07-15_" ++ i ++ ".pri").resolveRelative,
			// path: Date.getDate.format("fm7_%Y-%m-%d_" ++ i ++ ".pri").resolveRelative,
			notes: ([ \en2, \en3, \bn3].keynum.mirror2.clump(3)).flat
		));
    // });
	// ("prep/feu.scd").loadRelative;
	// 1.wait;
	// PR(\granule).chuck(BP(\feu), parms:(
	// 	// interpolatorPath: Date.getDate.format(
	// 	// 	"feu_%Y-%m-%d.pri").resolveRelative,
	// 	interpolatorPath: "feu_2013-07-15.pri".resolveRelative,
	// 	audioFilePath: "samples/feuHuards.aiff".resolveRelative
	// ));
	// 5.wait;
	// BP(\feu).play;
    \ready.postln;
}.fork;
~win = Window("Sensibilité", 600@20);
~spec = ControlSpec(0.7,0.999999,-10);
~slider = Slider(~win, 600@20);
~val = ~spec.map(~slider.value);
~slider.action_({|sl|
	BP(0).ampExtractor.set(\decayCoef, ~spec.map(sl.value));
	~val = ~spec.map(~slider.value);
});
~win.front;
~win.onClose_({|w|
	("echo" + ~val + ">" +
	Date.getDate.format("resultats/%Y-%m-%d_%H-%M-%S_sens")).unixCmd;
	BP.freeAll;
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

BP(0).ampExtractor.get(\decayCoef, {|i| i.postln})

(
w = Window();
~spec = ControlSpec(0.8,0.999999,-10);
y = Slider(w, 400@20).action_({|sl|
	BP(0).ampExtractor.set(\decayCoef, ~spec.map(sl.value))
});
w.front;
)
Warp


EZSlider(w, 400@20, "", , {|ex| ex.value.postln} );
BusPlot(BP(0).ampBus.subBus(0))



