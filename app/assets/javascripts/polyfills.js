/*
 * add an object called fullScreenApi until the fullscreen API gets finalized
 * from: http://johndyer.name/native-fullscreen-javascript-api-plus-jquery-plugin/
 *
 * heavily adapted to support IE11 and the new specs
 */
(function () {
    const fullScreenApi = {
        supportsFullScreen: false,
        isFullScreen: function () {
            return false;
        },
        requestFullScreen: function () {
        },
        cancelFullScreen: function () {
        },
        fullScreenEventName: "",
        prefix: "",
    };
    const browserPrefixes = "webkit moz o ms khtml".split(" ");
    let i;
    let il;

    // check for native support
    if (typeof document.exitFullScreen !== "undefined") {
        fullScreenApi.supportsFullScreen = true;
    } else {
        // check for fullscreen support by vendor prefix
        for (i = 0, il = browserPrefixes.length; i < il; i++) {
            fullScreenApi.prefix = browserPrefixes[i];

            if (typeof document[fullScreenApi.prefix + "CancelFullScreen"] !== "undefined") {
                fullScreenApi.supportsFullScreen = true;
                break;
            }
            if (typeof document[fullScreenApi.prefix + "ExitFullscreen"] !== "undefined") {
                fullScreenApi.supportsFullScreen = true;
                break;
            }
        }
    }

    // update methods to do something useful
    if (fullScreenApi.supportsFullScreen) {
        fullScreenApi.fullScreenEventName = fullScreenApi.prefix + "fullscreenchange";
        if (fullScreenApi.prefix === "ms") {
            fullScreenApi.fullScreenEventName = "MSFullscreenChange";
        }

        fullScreenApi.isFullScreen = function () {
            switch (this.prefix) {
            case "":
                return document.fullscreenElement !== null;
            case "moz":
                return document.mozFullScreenElement !== null;
            default:
                return document[this.prefix + "FullscreenElement"] !== null;
            }
        };
        fullScreenApi.requestFullScreen = function (el) {
            switch (this.prefix) {
            case "":
                return el.requestFullscreen();
            case "webkit":
                return el.webkitRequestFullscreen();
            case "ms":
                return el.msRequestFullscreen();
            case "moz":
                return el.mozRequestFullScreen();
            case "default":
                return el[this.prefix + "RequestFullscreen"]();
            }
        };
        fullScreenApi.cancelFullScreen = function (el) {
            switch (this.prefix) {
            case "":
                return document.exitFullscreen();
            case "webkit":
                return document.webkitExitFullscreen();
            case "ms":
                return document.msExitFullscreen();
            case "moz":
                return document.mozCancelFullScreen();
            case "default":
                return document[this.prefix + "ExitFullscreen"]();
            }
        };
    }

    // jQuery plugin
    if (typeof jQuery !== "undefined") {
        jQuery.fn.requestFullScreen = function () {
            return this.each(function () {
                if (fullScreenApi.supportsFullScreen) {
                    fullScreenApi.requestFullScreen(this);
                }
            });
        };
    }

    // export api
    window.fullScreenApi = fullScreenApi;
})();

