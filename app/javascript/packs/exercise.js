import { initExerciseShow, initLabelsEdit, afterResize, onFrameMessage } from "exercise.js";

window.dodona.initExerciseShow = initExerciseShow;
window.dodona.initLabelsEdit = initLabelsEdit;
window.dodona.afterResize = afterResize;
window.dodona.onFrameMessage = onFrameMessage;

// will automaticaly bind to window.iFrameResize()
import { iframeResizer } from "iframe-resizer"; // eslint-disable-line no-unused-vars
