import jQuery from "jquery";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import "polyfills.js";
import { initTooltips, initClipboard } from "util.js";

// Use a global dodona object to prevent polluting the global na
const dodona = window.dodona || {};
dodona.initTooltips = initTooltips;
window.dodona = dodona;

// Initialize clipboard.js
initClipboard();

$(initTooltips);

import * as firebase from "firebase/app";
import "firebase/performance";

if (window.location.hostname === "medusa.ugent.be") {
    const firebaseConfig = {
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
}
