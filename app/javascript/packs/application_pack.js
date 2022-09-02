/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_include_tag 'application_pack' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

import "core-js/stable";
import "regenerator-runtime/runtime";

import { start as startRails } from "@rails/ujs";

startRails();

import jQuery from "jquery";

// jQuery aliases
window.jQuery = jQuery;
window.jquery = jQuery;
window.$ = jQuery;

import { I18n } from "i18n-js";
import translations from "i18n/translations.json";
window.I18n = new I18n(translations);

// bootstrap
import { Alert, Button, Collapse, Dropdown, Modal, Popover, Tab, Tooltip } from "bootstrap";
const bootstrap = { Alert, Button, Collapse, Dropdown, Modal, Popover, Tab, Tooltip };
window.bootstrap = bootstrap;

import { Drawer } from "drawer";
import { Toast } from "toast";
import { Notification } from "notification";
import { checkTimeZone, checkIframe, initCSRF, initTooltips, ready } from "util.js";
import { initClipboard } from "copy";
import { FaviconManager } from "favicon";

// Initialize clipboard.js
initClipboard();

// Don't show drawer if we don't want a drawer.
if (!window.dodona.hideDrawer) {
    ready.then(() => new Drawer());
}


// Adds the CSRF token to each ajax request
initCSRF();

ready.then(initTooltips);

// Use a global dodona object to prevent polluting the global na
const dodona = window.dodona || {};
dodona.dotManager = new FaviconManager(dodona.dotCount || []);
dodona.checkTimeZone = checkTimeZone;
dodona.Toast = Toast;
dodona.Notification = Notification;
dodona.initTooltips = initTooltips;
dodona.checkIframe = checkIframe;
dodona.ready = ready;
window.dodona = dodona;
