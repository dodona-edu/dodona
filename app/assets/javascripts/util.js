/* globals ga */

import { isInIframe } from "iframe";

/**
 * Create a function that will delay all subsequent calls on the same timer.
 * You don't necessarily have to call the delayer with the same function.
 *
 * In the first example, the typical usage is illustrated. The second example
 * illustrates what happens with multiple delayers, each with their own timer.
 *
 * There is also a pre-made delayer available with a global timer, see `delay`.
 * @example
 *  const delay = createDelayer();
 *  delay(() => console.log(1), 100);
 *  delay(() => console.log(2), 100);
 *  // prints 2, since the first invocation is cancelled
 *
 * @example
 *  const delay1 = createDelayer();
 *  const delay2 = createDelayer();
 *  delay1(() => console.log(1), 100);
 *  delay2(() => console.log(2), 100);
 *  // prints 1 and then 2, since both have their own timer.
 *
 *  @return {function(TimerHandler, number): void}
 */
function createDelayer() {
    let timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
}

/*
 * Function to delay some other function until it isn't
 * called for "ms" ms. This runs on a global timer, meaning
 * the actual function doesn't matter. If you want a delay
 * specifically for one function, you need to first create
 * your own "delayer" with `createDelayer`.
 */
const delay = createDelayer();

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
    const url = new URL(_url.replace(/%5B%5D/g, "[]"), window.location.origin);
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
    createDelayer,
    delay,
    fetch,
    updateURLParameter,
    updateArrayURLParameter,
    getURLParameter,
    getArrayURLParameter,
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
