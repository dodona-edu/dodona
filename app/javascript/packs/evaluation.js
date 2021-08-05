import { initDeadlinePicker } from "series.js";
import { interceptAddMultiUserClicks, initCheckboxes, initCheckbox } from "evaluation.ts";
import FeedbackActions from "feedback/actions";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.initCheckboxes = initCheckboxes;
window.dodona.initCheckbox = initCheckbox;
window.dodona.interceptAddMultiUserClicks = interceptAddMultiUserClicks;
window.dodona.FeedbackActions = FeedbackActions;
