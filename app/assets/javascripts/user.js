function init_user_index() {
    var $filter;

    function init() {
        initFilter();
    }

    function initFilter() {
        $filter = $("#user-filter-name");
        $filter.keyup(function () {
            delay(search, 500);
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
