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


import * as firebase from "firebase/app";
import "firebase/performance";

let firebaseConfig = {
    apiKey: "AIzaSyA9thyrC9D8q5CdnZG3p25BDTQQ9AeFndI",
    authDomain: "dodona-cea23.firebaseapp.com",
    databaseURL: "https://dodona-cea23.firebaseio.com",
    projectId: "dodona-cea23",
    storageBucket: "dodona-cea23.appspot.com",
    messagingSenderId: "640604109353",
    appId: "1:640604109353:web:eb3aa7f16a7cf1a0",
};
firebase.initializeApp(firebaseConfig);
firebase.performance();

// Initialize clipboard.js
initClipboard();

// Adds the CSRF token to each ajax request
initCSRF();

$(initTooltips);

// Use a global dodona object to prevent polluting the global na
let dodona = {};
dodona.checkTimeZone = checkTimeZone;
dodona.showNotification = showNotification;
dodona.initTooltips = initTooltips;
window.dodona = dodona;
