
import Clipboard from "clipboard";

function initClipboard() {
    $(() => {
        const selector = ".btn[data-clipboard-target]";
        const tooltip = I18n.t("js.copy-to-clipboard");
        const $el = $(selector)
            .attr("title", tooltip)
            .tooltip();
        const clip = new Clipboard(selector);
        clip.on("success", e => {
            $(e.trigger).attr("title", I18n.t("js.copy-success"))
                .tooltip("fixTitle")
                .tooltip("show")
                .attr("title", tooltip)
                .tooltip("fixTitle");
        });
        clip.on("error", e => {
            $(e.trigger).attr("title", I18n.t("js.copy-fail"))
                .tooltip("fixTitle")
                .tooltip("show")
                .attr("title", tooltip)
                .tooltip("fixTitle");
        });
    });
}

/*
 * Function to delay some other function until it isn't
 * called for "ms" ms
 */
let delay = (function () {
    let timer = 0;
    return function (callback, ms) {
        clearTimeout(timer);
        timer = setTimeout(callback, ms);
    };
})();

let updateURLParameter = function updateURLParameter(url, param, paramVal) {
    let TheAnchor = null;
    let newAdditionalURL = "";
    let tempArray = url.split("?");
    let baseURL = tempArray[0];
    let additionalURL = tempArray[1];
    let temp = "";
    let i;

    if (additionalURL) {
        var tmpAnchor = additionalURL.split("#");
        var TheParams = tmpAnchor[0];
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
        var tmpAnchor = baseURL.split("#");
        var TheParams = tmpAnchor[0];
        TheAnchor = tmpAnchor[1];

        if (TheParams) {
            baseURL = TheParams;
        }
    }
    if (TheAnchor) {
        paramVal += "#" + TheAnchor;
    }
    let rows_txt = temp + "" + param + "=" + paramVal;
    return baseURL + "?" + newAdditionalURL + rows_txt;
};

function getURLParameter(name, url) {
    if (!url) {
        url = window.location.href;
    }
    name = name.replace(/[\[\]]/g, "\\$&");
    let regex = new RegExp("[?&]" + name + "(=([^&#]*)|&|#|$)"),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return "";
    return decodeURIComponent(results[2].replace(/\+/g, " "));
}

/**
 * requestAnimationFrame shim
 * source: http://www.paulirish.com/2011/requestanimationframe-for-smart-animating/
 */
window.requestAnimFrame = (function () {
    return window.requestAnimationFrame ||
        window.webkitRequestAnimationFrame ||
        window.mozRequestAnimationFrame ||
        function (callback) {
            window.setTimeout(callback, 1000 / 60);
        };
})();

/*
 * Logs data to Google Analytics
 */
function logToGoogle(category, action, label, value) {
    if (typeof(ga) !== "undefined") {
        ga("send", "event", category, action, label, value);
    }
}

function checkTimeZone(offset) {
    if (offset !== new Date().getTimezoneOffset()) {
        $("#time-zone-warning").removeClass("hidden");
    }
}

export {initClipboard, delay, updateURLParameter, getURLParameter, logToGoogle, checkTimeZone};
