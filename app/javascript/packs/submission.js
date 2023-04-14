import { initSubmissionShow, initCorrectSubmissionToNextLink, initSubmissionHistory } from "submission.ts";
import { initMathJax } from "exercise.ts";
import { attachClipboard } from "copy";
import { evaluationState } from "state/Evaluations";
import codeListing from "code_listing";

window.dodona.initSubmissionShow = initSubmissionShow;
window.dodona.codeListing = codeListing;
window.dodona.attachClipboard = attachClipboard;
window.dodona.initMathJax = initMathJax;
window.dodona.initCorrectSubmissionToNextLink = initCorrectSubmissionToNextLink;
window.dodona.initSubmissionHistory = initSubmissionHistory;
window.dodona.setEvaluationId = id => evaluationState.id = id;
