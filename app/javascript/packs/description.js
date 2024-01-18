import { iframeResizerContentWindow } from "iframe-resizer";
import { initExerciseDescription, initMathJax } from "exercise.ts";

import { i18n } from "i18n/i18n";

window.iframeResizerContentWindow = iframeResizerContentWindow;
window.dodona.initMathJax = initMathJax;
window.dodona.initDescription = initExerciseDescription;
window.dodona.i18n = i18n;
