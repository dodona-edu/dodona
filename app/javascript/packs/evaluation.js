import { initCheckboxes, initCheckbox, initEvaluationStepper } from "evaluation.ts";
import FeedbackActions from "feedback/actions";
import { initDatePicker } from "util.js";

window.dodona.initDeadlinePicker = initDatePicker;
window.dodona.initCheckbox = initCheckbox;
window.dodona.initCheckboxes = initCheckboxes;
window.dodona.FeedbackActions = FeedbackActions;
window.dodona.initEvaluationStepper = initEvaluationStepper;
