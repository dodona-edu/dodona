import { initDeadlinePicker } from "series.js";
import {
    interceptAddMultiUserClicks,
    FeedbackActions
} from "evaluation.ts";

window.dodona.initDeadlinePicker = initDeadlinePicker;
window.dodona.interceptAddMultiUserClicks = interceptAddMultiUserClicks;
window.dodona.FeedbackActions = FeedbackActions;
