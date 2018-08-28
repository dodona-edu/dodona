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
    function init() {
        if (doInitFilter) {
            initFilter(baseUrl, eager);
        }
        if (actions) {
            initActions();
        }
    }

    function performAction(action, $filter) {
        if (action.confirm === undefined || window.confirm(action.confirm)) {
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
    }

    function performSearch(action, $filter) {
        let url = baseUrl;
        let searchParams = Object.entries(action.search);
        console.log(searchParams);
        for (let i = 0; i < searchParams.length; i++) {
            let key = searchParams[i][0];
            let value = searchParams[i][1];
            console.log(key);
            console.log(value);
            url = updateURLParameter(url, key.toString(), value.toString());
        }
        search(url, "");
    }

    function initActions() {
        let $actions = $(".table-toolbar-tools .actions");
        let $filter = $(FILTER_ID);
        let searchOptions = actions.filter(action => action.search);
        let searchActions = actions.filter(action => action.action);
        $actions.removeClass("hidden");
        if (searchOptions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.filter-options") + "</li>");
            searchOptions.forEach(function (action) {
                let $link = $(`<a class="action" href='#'><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                $link.click(() => {
                    performSearch(action, $filter);
                    return false;
                });
            });
        }
        if (searchActions.length > 0) {
            $actions.find("ul").append("<li class='dropdown-header'>" + I18n.t("js.actions") + "</li>");
            searchActions.forEach(function (action) {
                let $link = $(`<a class="action" href='#'><i class='material-icons md-18'>${action.icon}</i>${action.text}</a>`);
                $link.appendTo($actions.find("ul"));
                $link.wrap("<li></li>");
                $link.click(() => {
                    performAction(action, $filter);
                    return false;
                });
            });
        }
    }

    init();
}

export {initFilterIndex, initFilter, search};
