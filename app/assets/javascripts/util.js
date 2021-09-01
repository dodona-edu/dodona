/* globals ga */

import { isInIframe } from "iframe";

/*
 * Function to delay some other function until it isn't
 * called for "ms" ms
 */
const delay = (function () {
    let timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();

function updateURLParameter(_url, param, paramVal) {
    const url = new URL(_url, window.location.origin);
    if (paramVal) {
        url.searchParams.set(param, paramVal);
    } else {
        url.searchParams.delete(param);
    }
    return url.toString();
}

function updateArrayURLParameter(_url, param, _paramVals) {
    const paramVals = new Set(_paramVals); // remove duplicate items
    // convert "%5B%5D" back to "[]"
    const url = new URL(_url.split("%5B%5D").join("[]"), window.location.origin);
    url.searchParams.delete(`${param}[]`);
    paramVals.forEach(paramVal => {
        url.searchParams.append(`${param}[]`, paramVal);
    });
    return url.toString();
}

function getURLParameter(name, _url) {
    const url = new URL(_url ?? window.location.href, window.location.origin);
    return url.searchParams.get(name);
}

function getArrayURLParameter(name, _url) {
    const url = new URL(_url ?? window.location.href, window.location.origin);
    return url.searchParams.getAll(`${name}[]`);
}

/*
 * Logs data to Google Analytics. Category and action are mandatory.
 */
function logToGoogle(category, action, label, value) {
    if (typeof (ga) !== "undefined") {
        ga("send", "event", category, action, label, value);
    }
}

function checkTimeZone(offset) {
    if (offset !== new Date().getTimezoneOffset()) {
        $("#time-zone-warning").removeClass("hidden");
    }
}

function checkIframe() {
    if (isInIframe()) {
        $("#iframe-warning").removeClass("hidden");
    }
}

// add CSRF token to each ajax-request
function initCSRF() {
    $(() => {
        $.ajaxSetup({
            "headers": {
                "X-CSRF-Token": $("meta[name='csrf-token']").attr("content"),
            },
        });
    });
}

function initTooltips() {
    $("[data-bs-toggle=\"tooltip\"]").tooltip({ container: "body" });
}

function tooltip(target, message, disappearAfter=1000) {
    const $target = $(target);
    const originalTitle = $target.attr("data-original-title");
    $target.attr("data-original-title", message).tooltip("show");
    $target.attr("title", message).tooltip("show");
    setTimeout(() => {
        $target.attr("title", originalTitle).attr("data-original-title", originalTitle).tooltip();
    }, disappearAfter);
}

function fetch(url, options = {}) {
    const headers = options.headers || {};
    headers["x-csrf-token"] = headers["x-csrf-token"] || document.querySelector("meta[name=\"csrf-token\"]").content;
    headers["x-requested-with"] = headers["x-requested-with"] || "XMLHttpRequest";
    options["headers"] = headers;
    return window.fetch(url, options);
}

/**
 * Initializes any element with the clickable-token class to use its data for searching
 */
function initTokenClickables() {
    const $clickableTokens = $(".clickable-token");
    $clickableTokens.off("click");
    $clickableTokens.on("click", function () {
        const $htmlElement = $(this);
        const type = $htmlElement.data("type");
        const name = $htmlElement.data("name");
        if (dodona.addTokenToSearch) {
            dodona.addTokenToSearch(type, name);
        }
    });
}

/**
 * Make an element invisible by applying "visibility: hidden".
 *
 * @param {HTMLElement} element The element to hide.
 */
function makeInvisible(element) {
    element.style.visibility = "hidden";
}

/**
 * Make an element visible by applying "visibility: visible".
 *
 * @param {HTMLElement} element The element to show.
 */
function makeVisible(element) {
    element.style.visibility = "visible";
}

/**
 * Set the title of the webpage.
 *
 * @param {string} title The new title.
 */
function setDocumentTitle(title) {
    document.title = title;
}

export {
    delay,
    fetch,
    updateURLParameter,
    updateArrayURLParameter,
    getURLParameter,
    getArrayURLParameter,
    logToGoogle,
    checkTimeZone,
    checkIframe,
    initCSRF,
    tooltip,
    initTooltips,
    initTokenClickables,
    makeInvisible,
    makeVisible,
    setDocumentTitle
};
