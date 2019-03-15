/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


import Rails from "rails-ujs";
import "actiontext";

Rails.start();

import jQuery from "jquery";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import "polyfills.js";
import "drawer";
import {showNotification} from "notifications.js";
import {checkTimeZone, initClipboard, initCSRF, initTooltips} from "util.js";

// Initialize clipboard.js
initClipboard();

// Adds the CSRF token to each ajax request
initCSRF();

initTooltips();

// Use a global dodona object to prevent polluting the global na
let dodona = {};
dodona.checkTimeZone = checkTimeZone;
dodona.showNotification = showNotification;
window.dodona = dodona;
