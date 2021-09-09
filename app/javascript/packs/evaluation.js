import { initDeadlinePicker } from "series.js";
import { initCheckbox, initEvaluationStepper } from "evaluation.ts";
import FeedbackActions from "feedback/actions";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.initCheckbox = initCheckbox;
window.dodona.FeedbackActions = FeedbackActions;
window.dodona.initEvaluationStepper = initEvaluationStepper;
