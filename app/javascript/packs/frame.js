import "core-js/stable";
import "regenerator-runtime/runtime";
import { initSentry } from "sentry";
initSentry();

// bootstrap
import { Alert, Button, Collapse, Dropdown, Modal, Popover, Tab, Tooltip } from "bootstrap";
const bootstrap = { Alert, Button, Collapse, Dropdown, Modal, Popover, Tab, Tooltip };
window.bootstrap = bootstrap;

import { initTooltips, ready, setHTMLExecuteScripts } from "utilities.ts";
import { themeState } from "state/Theme";

// Use a global dodona object to prevent polluting the global na
const dodona = window.dodona || {};
dodona.initTooltips = initTooltips;
dodona.ready = ready;
dodona.setTheme = theme => themeState.selectedTheme = theme;
dodona.setHTMLExecuteScripts = setHTMLExecuteScripts;
window.dodona = dodona;

ready.then(initTooltips);
