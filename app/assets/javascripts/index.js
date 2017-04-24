/* globals delay, getURLParameter, updateURLParameter */
function init_filter_index(baseUrl, eager, actions) {
    var PARAM = "filter";
    var $filter;

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
        var param = getURLParameter(PARAM);
        if (param !== "") {
            $filter.val(param);
        }
    }

    function initActions() {
        var $actions = $(".table-toolbar-tools .actions");
        $actions.removeClass("hidden");
        actions.forEach(function (action) {
            var $link = $("<a href='#'><span class='glyphicon glyphicon-" + action.icon + "'></span> " + action.text + "</a>");
            $link.appendTo($actions.find("ul"));
            $link.wrap("<li></li>");
            $link.click(function () {
                if (confirm(action.confirm)) {
                    var val = $filter.val();
                    var url = updateURLParameter(action.action, PARAM, val);
                    $.post(url, {
                        format: "js"
                    }, function (data) {
                        showNotification(data.message);
                        search();
                    });
                }
                return false;
            });
        });
    }

    function search() {
        var val = $filter.val();
        var url = updateURLParameter(getUrl(), PARAM, val);
        url = updateURLParameter(url, "page", 1);
        if (!baseUrl) {
            window.history.replaceState(null, "Dodona", url);
        }
        $("#progress-filter").css("visibility", "visible");
        $.get(url, {
            format: "js"
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
