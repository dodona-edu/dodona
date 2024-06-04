import { initExerciseDescription } from "exercise.ts";
import { initSeriesShow } from "series";

window.dodona.initExerciseDescription = initExerciseDescription;
window.dodona.initSeriesShow = initSeriesShow;

// will automatically bind do window.iFrameResize()
require("iframe-resizer"); // eslint-disable-line no-undef
