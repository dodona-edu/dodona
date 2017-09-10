import {showNotification} from "./notifications.js";
import {delay, updateURLParameter, getURLParameter} from "./util.js";

let PARAM = "filter";
let FILTER_ID = "#filter-query";

function search(baseUrl, _query) {
    let getUrl = () => baseUrl || window.location.href;
    let query = _query || $(FILTER_ID).val();
    let url = updateURLParameter(getUrl(), PARAM, query);
    url = updateURLParameter(url, "page", 1);
    if (!baseUrl) {
        window.history.replaceState(null, "Dodona", url);
    }
    $("#progress-filter").css("visibility", "visible");
    $.get(url, {
        format: "js",
    }, function (data) {
        eval(data);
        $("#progress-filter").css("visibility", "hidden");
    });
}

function initFilter(baseUrl, eager) {
    let $filter = $(FILTER_ID);
    let doSearch = () => search(baseUrl, $filter.val());
    $filter.off("keyup"); // Remove previous handler
    $filter.on("keyup", function () {
        delay(doSearch, 300);
    });
    let param = getURLParameter(PARAM);
    if (param !== "") {
        $filter.val(param);
    }
    if (eager) {
        doSearch();
    }
}

function initFilterIndex(baseUrl, eager, actions, doInitFilter) {
    let $filter;

    function init() {
        if (doInitFilter) {
            initFilter(baseUrl, eager);
        }
        if (actions) {
            initActions();
        }
    }

    function initActions() {
        let $actions = $(".table-toolbar-tools .actions");
        $actions.removeClass("hidden");
        actions.forEach(function (action) {
            let $link = $("<a href='#'><span class='glyphicon glyphicon-" + action.icon + "'></span> " + action.text + "</a>");
            $link.appendTo($actions.find("ul"));
            $link.wrap("<li></li>");
            $link.click(function () {
                if (window.confirm(action.confirm)) {
                    let val = $filter.val();
                    let url = updateURLParameter(action.action, PARAM, val);
                    $.post(url, {
                        format: "json",
                    }, function (data) {
                        showNotification(data.message);
                        if (data.js) {
                            eval(data.js);
                        } else {
                            search(baseUrl, $filter.val());
                        }
                    });
                }
                return false;
            });
        });
    }

    init();
}

export {initFilterIndex, initFilter, search};
