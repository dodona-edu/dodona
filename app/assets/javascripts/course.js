/* globals ga, I18n, dodona, ace, MathJax, initStrip, Strip, showNotification */
function init_course_show(seriesShown, seriesTotal, autoLoad) {

    var seriesShown = seriesShown,
        perBatch = seriesShown,
        seriesTotal = seriesTotal,
        autoLoad = autoLoad,
        loading = false;

    function init() {
        $(".load-more-series").click(loadMoreSeries);
        $(window).scroll(scroll);
    }

    function loadMoreSeries() {
        loading = true;
        autoLoad = true;
        $.get("?format=js&offset=" + seriesShown)
        .done(function () {
            seriesShown += perBatch;
            if (seriesShown >= seriesTotal) {
                $(".load-more-series").hide();
            }
        })
        .always(function () {
            loading = false;
        });
    }

    // TODO: throttle this
    function scroll() {
        if (loading) { return; }
        if (seriesShown >= seriesTotal) { return; }
        if (!autoLoad) { return; }

        var top_of_element = $(".load-more-series").offset().top;
        var bottom_of_screen = $(window).scrollTop() + $(window).height();
        if(top_of_element < bottom_of_screen) {
            loadMoreSeries();
        }
    }

    init();
}
