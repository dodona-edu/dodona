import { isInIframe } from "iframe";
import { Dutch } from "flatpickr/dist/l10n/nl";
import { CustomLocale } from "flatpickr/dist/types/locale";
import flatpickr from "flatpickr";

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
function createDelayer(): (callback: () => void, ms?: number) => void {
    let timer = 0;
    return (callback, ms) => {
        clearTimeout(timer);
        timer = window.setTimeout(callback, ms);
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

function updateURLParameter(_url: string, param: string, paramVal: string): string {
    const url = new URL(_url, window.location.origin);
    if (paramVal) {
        url.searchParams.set(param, paramVal);
    } else {
        url.searchParams.delete(param);
    }
    return url.toString();
}

function updateArrayURLParameter(_url: string, param: string, _paramVals: string[]): string {
    const paramVals = new Set(_paramVals); // remove duplicate items
    // convert "%5B%5D" back to "[]"
    const url = new URL(_url.replace(/%5B%5D/g, "[]"), window.location.origin);
    url.searchParams.delete(`${param}[]`);
    paramVals.forEach(paramVal => {
        url.searchParams.append(`${param}[]`, paramVal);
    });
    return url.toString();
}

function getURLParameter(name: string, _url?: string): string {
    const url = new URL(_url ?? window.location.href, window.location.origin);
    return url.searchParams.get(name);
}

function getArrayURLParameter(name: string, _url: string): string[] {
    const url = new URL(_url ?? window.location.href, window.location.origin);
    return url.searchParams.getAll(`${name}[]`);
}

function checkTimeZone(offset: number): void {
    if (offset !== new Date().getTimezoneOffset()) {
        document.querySelector("#time-zone-warning").classList.remove("hidden");
    }
}

function checkIframe(): void {
    if (isInIframe()) {
        document.querySelector("#iframe-warning").classList.remove("hidden");
    }
}

// TODO: remove?
// add CSRF token to each ajax-request
async function initCSRF(): Promise<void> {
    await ready;
    $.ajaxSetup({
        "headers": {
            "X-CSRF-Token": $("meta[name='csrf-token']").attr("content"),
        },
    });
}

/**
 * @param {Document | Element} root
 */
function initTooltips(root: Document | Element = document): void {
    // First remove dead tooltips
    const tooltips = root.querySelectorAll(".tooltip");
    for (const tooltip of tooltips) {
        tooltip.remove();
    }

    // Then reinitialize tooltips
    const elements = root.querySelectorAll("[data-bs-toggle=\"tooltip\"]") as NodeListOf<HTMLElement>;
    for (const element of elements) {
        const tooltip = window.bootstrap.Tooltip.getOrCreateInstance(element);
        if (element.title) {
            tooltip.setContent({ ".tooltip-inner": element.title });
            element.removeAttribute("title");
        }
    }
}

function tooltip(target: Element | null, message: string, disappearAfter = 3000): void {
    if (target) {
        const originalTitle = target.getAttribute("data-original-title");
        target.setAttribute("data-original-title", message);
        target.setAttribute("title", message);
        setTimeout(() => {
            if (originalTitle) {
                target.setAttribute("title", originalTitle);
                target.setAttribute("data-original-title", originalTitle);
            } else {
                target.removeAttribute("title");
                target.removeAttribute("data-original-title");
            }
        }, disappearAfter);
    }
}

function fetch(url: URL | RequestInfo, options: RequestInit = {}): Promise<Response> {
    const headers = options.headers || {};
    headers["x-csrf-token"] = headers["x-csrf-token"] || (document.querySelector("meta[name=\"csrf-token\"]") as HTMLMetaElement).content;
    headers["x-requested-with"] = headers["x-requested-with"] || "XMLHttpRequest";
    options["headers"] = headers;
    return window.fetch(url, options);
}

/**
 * Make an element invisible by applying "visibility: hidden".
 *
 * @param {HTMLElement} element The element to hide.
 */
function makeInvisible(element: HTMLElement): void {
    element.style.visibility = "hidden";
}

/**
 * Make an element visible by applying "visibility: visible".
 *
 * @param {HTMLElement} element The element to show.
 */
function makeVisible(element: HTMLElement): void {
    element.style.visibility = "visible";
}

/**
 * Set the title of the webpage.
 *
 * @param {string} title The new title.
 */
function setDocumentTitle(title: string): void {
    document.title = title;
}

type DatePickerOptions = {
    wrap?: boolean,
    enableTime?: boolean,
    dateFormat?: string,
    altInput?: boolean,
    altFormat?: string,
    locale?: CustomLocale
};

/**
 * Initiates a datepicker using flatpicker
 * @param {string} selector - The selector of div containing the input field and buttons
 * @param {object} options - optional, Options object as should be provided to the flatpicker creation method
 * @return {flatpickr} the created flatpicker
 */
function initDatePicker(selector: string, options: DatePickerOptions = {}): object {
    function init(): object {
        if (I18n.locale === "nl") {
            options.locale = Dutch;
        }
        return flatpickr(selector, options);
    }

    return init();
}

/**
 * This promise will resolve when the dom content is fully loaded
 * This could mean immediately if the dom is already loaded
 */
const ready = new Promise<void>(resolve => {
    if (document.readyState !== "loading") {
        resolve();
    } else {
        document.addEventListener("DOMContentLoaded", () => resolve());
    }
});

// source https://github.com/janl/mustache.js/blob/master/mustache.js#L73
const entityMap = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    "\"": "&quot;",
    "'": "&#39;",
    "/": "&#x2F;",
    "`": "&#x60;",
    "=": "&#x3D;"
};

function htmlEncode(str: string): string {
    return String(str).replace(/[&<>"'`=/]/g, function (s) {
        return entityMap[s];
    });
}

/**
 * Returns the first parent of an element that has at least all of the given classes.
 * Returns null if no such parent exists.
 * @param {Element} element - Iterate over the parents of this element
 * @param {string} classNames - The class names to search for, separated by white space
 * @return {?Element} The parent containing the classes
 */
function getParentByClassName(element: Element, classNames: string): Element {
    let parent = element.parentElement;
    while (parent) {
        if (classNames.split(/\s+/).every(className => parent.classList.contains(className))) {
            return parent;
        }
        parent = parent.parentElement;
    }
    return null;
}

// insert `cached` function here after move to typescript
// the function is currently in `app/assets/javascripts/mark.ts`

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
    makeInvisible,
    makeVisible,
    setDocumentTitle,
    initDatePicker,
    ready,
    htmlEncode,
    getParentByClassName,
};
