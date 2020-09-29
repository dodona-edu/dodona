/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb


import { start as startRails } from "@rails/ujs";

startRails();

import jQuery from "jquery";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import "polyfills.js";
import { Drawer } from "drawer";
import { Toast } from "toast";
import { Notification, checkNotifications } from "notification";
import { checkTimeZone, checkIframe, initCSRF, initTooltips } from "util.js";
import { initClipboard } from "copy";
import { FaviconManager } from "favicon";

// Initialize clipboard.js
initClipboard();

// Don't show drawer if we don't want a drawer.
if (!window.dodona.hideDrawer) {
    $(() => new Drawer());
}


// Adds the CSRF token to each ajax request
initCSRF();

$(initTooltips);

// Use a global dodona object to prevent polluting the global na
const dodona = window.dodona || {};
dodona.dotManager = new FaviconManager(dodona.dotCount || []);
dodona.checkTimeZone = checkTimeZone;
dodona.Toast = Toast;
dodona.checkNotifications = checkNotifications;
dodona.Notification = Notification;
dodona.initTooltips = initTooltips;
dodona.checkIframe = checkIframe;
window.dodona = dodona;
