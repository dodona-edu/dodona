import { iframeResizerContentWindow } from "iframe-resizer";
import { initExerciseDescription, initMathJax } from "exercise.ts";

window.iframeResizerContentWindow = iframeResizerContentWindow;
window.dodona.initMathJax = initMathJax;
window.dodona.initDescription = initExerciseDescription;
