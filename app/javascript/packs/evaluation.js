import { initDeadlinePicker } from "series.js";
import { interceptAddMultiUserClicks } from "evaluation.ts";
import FeedbackActions from "feedback/actions";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.interceptAddMultiUserClicks = interceptAddMultiUserClicks;
window.dodona.FeedbackActions = FeedbackActions;
