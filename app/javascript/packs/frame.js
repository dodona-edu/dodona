import jQuery from "jquery";
import { datadogRum } from "@datadog/browser-rum";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import "polyfills.js";
import { initTooltips } from "util.js";
import { initClipboard } from "copy";

// Use a global dodona object to prevent polluting the global na
const dodona = window.dodona || {};
dodona.initTooltips = initTooltips;
window.dodona = dodona;

// Initialize clipboard.js
initClipboard();

$(initTooltips);

datadogRum.init({
    applicationId: "477d9a7b-e9be-42eb-9caa-f4e92286eb32",
    clientToken: "pub9b24c5cc957941661162cd98406925ad",
    datacenter: "us",
    sampleRate: 100,
});
