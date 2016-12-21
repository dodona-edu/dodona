/* globals ga, I18n, dodona, ace, MathJax, initStrip, Strip, showNotification */
function init_course_show(seriesShown, seriesTotal) {

    var seriesShown = seriesShown,
        perBatch = seriesShown,
        seriesTotal = seriesTotal;

    function init() {
        $(".load-more-series").click(loadMoreSeries);
    }

    function loadMoreSeries() {
        $.get("?format=js&offset=" + seriesShown)
        .done(function () {
            seriesShown += perBatch;
            if (seriesShown >= seriesTotal) {
                $(".load-more-series").hide();
            }
        });
    }

    init();
}
