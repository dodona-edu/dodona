import { initExerciseShow, afterResize, onFrameScroll } from "exercise.js";
import { onFrameMessage } from "light_box";

window.dodona.initExerciseShow = initExerciseShow;
window.dodona.afterResize = afterResize;
window.dodona.onFrameMessage = onFrameMessage;
window.dodona.onFrameScroll = onFrameScroll;

// will automatically bind to window.iFrameResize()
require("iframe-resizer"); // eslint-disable-line no-undef
