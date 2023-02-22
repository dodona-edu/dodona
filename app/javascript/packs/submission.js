import { initSubmissionShow, initCorrectSubmissionToNextLink, initSubmissionHistory } from "submission.ts";
import { initMathJax } from "exercise.ts";
import { CodeListing } from "code_listing.ts";
import { attachClipboard } from "copy";

window.dodona.initSubmissionShow = initSubmissionShow;
window.dodona.codeListingClass = CodeListing;
window.dodona.attachClipboard = attachClipboard;
window.dodona.initMathJax = initMathJax;
window.dodona.initCorrectSubmissionToNextLink = initCorrectSubmissionToNextLink;
window.dodona.initSubmissionHistory = initSubmissionHistory;
