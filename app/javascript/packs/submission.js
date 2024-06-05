import { initSubmissionShow, initCorrectSubmissionToNextLink, initSubmissionHistory, showLastTab } from "submission.ts";
import { initMathJax, onFrameMessage, onFrameScroll } from "exercise.ts";
import { evaluationState } from "state/Evaluations";
import codeListing from "code_listing";
import { annotationState } from "state/Annotations";
import { initTutor } from "tutor";
import { initFileViewers } from "file_viewer";

window.dodona.initSubmissionShow = initSubmissionShow;
window.dodona.codeListing = codeListing;
window.dodona.initMathJax = initMathJax;
window.dodona.initCorrectSubmissionToNextLink = initCorrectSubmissionToNextLink;
window.dodona.initSubmissionHistory = initSubmissionHistory;
window.dodona.setEvaluationId = id => evaluationState.id = id;
window.dodona.setAnnotationVisibility = visibility => annotationState.visibility = visibility;
window.dodona.showLastTab = showLastTab;
window.dodona.initTutor = initTutor;
window.dodona.initFileViewers = initFileViewers;

window.dodona.afterResize = () => {};
window.dodona.onFrameMessage = onFrameMessage;
window.dodona.onFrameScroll = onFrameScroll;
// will automatically bind to window.iFrameResize()
require("iframe-resizer"); // eslint-disable-line no-undef
