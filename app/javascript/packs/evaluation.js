import { initDeadlinePicker } from "series.js";
import {
    initScoreForms,
    interceptAddMultiUserClicks,
    interceptFeedbackActionClicks
} from "evaluation.ts";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.interceptFeedbackActionClicks = interceptFeedbackActionClicks;
window.dodona.interceptAddMultiUserClicks = interceptAddMultiUserClicks;
window.dodona.initScoreForms = initScoreForms;
