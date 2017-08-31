/* globals ga, I18n, ace, MathJax, initStrip, Strip */

function initCourseShow(seriesShown, seriesTotal, autoLoad) {
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
        $(".load-more-series").button("loading");
        $.get("?format=js&offset=" + seriesShown)
            .done(function () {
                seriesShown += perBatch;
                if (seriesShown >= seriesTotal) {
                    $(".load-more-series").hide();
                }
            })
            .always(function () {
                loading = false;
                $(".load-more-series").button("reset");
            });
    }

    function scroll() {
        if (loading) {
            return;
        }
        if (seriesShown >= seriesTotal) {
            return;
        }
        if (!autoLoad) {
            return;
        }

        let topOfElement = $(".load-more-series").offset().top;
        let bottomOfScreen = $(window).scrollTop() + $(window).height();
        if (topOfElement < bottomOfScreen) {
            loadMoreSeries();
        }
    }

    init();
}

export {initCourseShow};
