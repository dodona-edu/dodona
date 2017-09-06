import {showNotification} from "./notifications.js";
import {delay, updateURLParameter, getURLParameter} from "./util.js";

function initFilterIndex(baseUrl, eager, actions) {
    let PARAM = "filter";
    let $filter;

    function init() {
        initFilter();
        if (actions) {
            initActions();
        }
        if (eager) {
            search();
        }
    }

    function initFilter() {
        $filter = $("#filter-query");
        $filter.keyup(function () {
            delay(search, 300);
        });
        let param = getURLParameter(PARAM);
        if (param !== "") {
            $filter.val(param);
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
                            search();
                        }
                    });
                }
                return false;
            });
        });
    }

    function search() {
        let val = $filter.val();
        let url = updateURLParameter(getUrl(), PARAM, val);
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

    function getUrl() {
        return baseUrl || window.location.href;
    }

    init();
}

export {initFilterIndex};
