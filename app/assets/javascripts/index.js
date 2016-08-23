function init_filter_index() {
    var PARAM = "filter";
    var $filter;

    function init() {
        initFilter();
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

    function search() {
        var val = $filter.val();
        var url = updateURLParameter(window.location.href, PARAM, val);
        url = updateURLParameter(url, "page", 1)
        window.history.replaceState(null, "Dodona", url);
        $("#progress-filter").css("visibility", "visible");
        $.get(url, {
            format: "js"
        }, function (data) {
            eval(data);
            $("#progress-filter").css("visibility", "hidden");
        });
    }

    init();
}
