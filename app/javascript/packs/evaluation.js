import { initDeadlinePicker } from "series.js";
import { initCheckboxes, initCheckbox, initEvaluationStepper } from "evaluation.ts";
import FeedbackActions from "feedback/actions";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.initCheckbox = initCheckbox;
window.dodona.initCheckboxes = initCheckboxes;
window.dodona.FeedbackActions = FeedbackActions;
window.dodona.initEvaluationStepper = initEvaluationStepper;
