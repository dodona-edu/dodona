function init_filter_index(model) {
    var $filter;

    function init() {
        initFilter();
    }

    function initFilter() {
        $filter = $("#" + model + "-filter-name");
        $filter.keyup(function () {
            delay(search, 300);
        });
    }

    function search() {
        $("#progress-filter").css("visibility", "visible");
        $.get("", {
            by_name: $filter.val(),
            format: "js"
        }, function (data) {
            eval(data);
            $("#progress-filter").css("visibility", "hidden");
        });
    }

    init();
}
