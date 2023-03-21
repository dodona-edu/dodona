import { iframeResizerContentWindow } from "iframe-resizer";
import { initExerciseDescription, initMathJax } from "exercise.ts";

import { I18n } from "i18n/i18n";
window.I18n = new I18n();

window.iframeResizerContentWindow = iframeResizerContentWindow;
window.dodona.initMathJax = initMathJax;
window.dodona.initDescription = initExerciseDescription;
