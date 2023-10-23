import { initSubmissionShow, initCorrectSubmissionToNextLink, initSubmissionHistory, showLastTab } from "submission.ts";
import { initMathJax } from "exercise.ts";
import { attachClipboard } from "copy";
import { evaluationState } from "state/Evaluations";
import codeListing from "code_listing";
import { annotationState } from "state/Annotations";
import { initTutor } from "tutor";
import { initFileViewers } from "file_viewer";

window.dodona.initSubmissionShow = initSubmissionShow;
window.dodona.codeListing = codeListing;
window.dodona.attachClipboard = attachClipboard;
window.dodona.initMathJax = initMathJax;
window.dodona.initCorrectSubmissionToNextLink = initCorrectSubmissionToNextLink;
window.dodona.initSubmissionHistory = initSubmissionHistory;
window.dodona.setEvaluationId = id => evaluationState.id = id;
window.dodona.setAnnotationVisibility = visibility => annotationState.visibility = visibility;
window.dodona.showLastTab = showLastTab;
window.dodona.initTutor = initTutor;
window.dodona.initFileViewers = initFileViewers;

// will automatically bind to window.iFrameResize()
require("iframe-resizer"); // eslint-disable-line no-undef
