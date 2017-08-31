/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import Rails from "rails-ujs";
Rails.start();

import jQuery from "jquery";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import dragula from "dragula";
window.dragula = dragula;

import "../../assets/javascripts/polyfills.js";

// TODO: Include me in each javascript file, if needed (instead of globally binding)
import {dodona, delay, updateURLParameter, getURLParameter, logToGoogle, checkTimeZone} from "../../assets/javascripts/util.js";

console.log("Warning: remove me");
window.dodona = dodona;
window.delay = delay;
window.updateURLParameter = updateURLParameter;
window.getURLParameter = getURLParameter;
window.logToGoogle = logToGoogle;
window.checkTimeZone = checkTimeZone;

import {showNotification} from "../../assets/javascripts/notifications.js";
window.showNotification = showNotification;


