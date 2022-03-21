import { initSubmissionShow, initSubmissionHistory } from "submission.js";
import { initMathJax } from "exercise.js";
import { CodeListing } from "code_listing/code_listing.ts";
import { attachClipboard } from "copy";

window.dodona.initSubmissionShow = initSubmissionShow;
window.dodona.codeListingClass = CodeListing;
window.dodona.attachClipboard = attachClipboard;
window.dodona.initMathJax = initMathJax;
window.dodona.initSubmissionHistory = initSubmissionHistory;
