/* globals ga */

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

function updateURLParameter(url, param, paramVal) {
    let TheAnchor = null;
    let newAdditionalURL = "";
    let tempArray = url.split("?");
    let baseURL = tempArray[0];
    let additionalURL = tempArray[1];
    let temp = "";
    let i;

    if (additionalURL) {
        const tmpAnchor = additionalURL.split("#");
        const TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];
        if (TheAnchor) {
            additionalURL = TheParams;
        }
        tempArray = additionalURL.split("&");
        for (i = 0; i < tempArray.length; i++) {
            if (tempArray[i].split("=")[0] != param) {
                newAdditionalURL += temp + tempArray[i];
                temp = "&";
            }
        }
    } else {
        const tmpAnchor = baseURL.split("#");
        const TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];

        if (TheParams) {
            baseURL = TheParams;
        }
    }
    let rowsTxt = "";
    if (paramVal) {
        rowsTxt += `${temp}${param}=${paramVal}`;
    }
    if (TheAnchor) {
        rowsTxt += "#" + TheAnchor;
    }
    return baseURL + "?" + newAdditionalURL + rowsTxt;
}

function updateArrayURLParameter(url, param, _paramVals) {
    const paramVals = _paramVals;
    let TheAnchor = null;
    let newAdditionalURL = "";
    let tempArray = url.split("?");
    let baseURL = tempArray[0];
    let additionalURL = tempArray[1];
    let temp = "";

    if (additionalURL) {
        const tmpAnchor = additionalURL.split("#");
        const TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];
        if (TheAnchor) {
            additionalURL = TheParams;
        }
        tempArray = additionalURL.split("&");
        for (let i = 0; i < tempArray.length; i++) {
            if (tempArray[i].split("=")[0] !== `${param}%5B%5D`) {
                newAdditionalURL += temp + tempArray[i];
                temp = "&";
            }
        }
    } else {
        const tmpAnchor = baseURL.split("#");
        const TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];

        if (TheParams) {
            baseURL = TheParams;
        }
    }
    let rowsTxt = "";
    for (const paramVal of paramVals) {
        rowsTxt += `${temp}${param}%5B%5D=${paramVal}`;
        temp = "&";
    }
    if (TheAnchor) {
        rowsTxt += "#" + TheAnchor;
    }
    return baseURL + "?" + newAdditionalURL + rowsTxt;
}

function getURLParameter(_name, _url) {
    const url = _url || window.location.href;
    const name = _name.replace(/[[\]]/g, "\\$&");
    const regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)");
    const results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return "";
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

function getArrayURLParameter(name, _url) {
    const url = _url || window.location.href;
    const result = [];
    for (const part of url.split(/[?&]/)) {
        const regResults = new RegExp(`${name}%5B%5D=([^#]+)`).exec(part);
        if (regResults && regResults[1]) {
            result.push(decodeURIComponent(regResults[1]));
        }
    }
    return result;
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
    $("[data-toggle=\"tooltip\"]").tooltip({ container: "body" });
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
    options["credentials"] = options["credentials"] || "same-origin";
    return window.fetch(url, options);
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
    initCSRF,
    tooltip,
    initTooltips,
};
