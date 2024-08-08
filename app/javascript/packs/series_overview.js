import { initExerciseDescription, afterResize, onFrameMessage, onFrameScroll } from "exercise.ts";
import { initSeriesShow } from "series";

window.dodona.initExerciseDescription = initExerciseDescription;
window.dodona.initSeriesShow = initSeriesShow;

window.dodona.afterResize = afterResize;
window.dodona.onFrameMessage = onFrameMessage;
window.dodona.onFrameScroll = onFrameScroll;
// will automatically bind do window.iFrameResize()
require("iframe-resizer"); // eslint-disable-line no-undef,@typescript-eslint/no-require-imports
