/* globals ga, I18n, dodona, ace, MathJax, initStrip, Strip, showNotification */
function init_course_show(seriesShown, seriesTotal, autoLoad) {

    var seriesShown = seriesShown,
        perBatch = seriesShown,
        seriesTotal = seriesTotal,
        autoLoad = autoLoad,
        loading = false;

    function init() {
        initUserTabs();
        $(".load-more-series").click(loadMoreSeries);
        $(window).scroll(scroll);
    }

    function initUserTabs(){
      $userTabs = $("#user-tabs")
      if($userTabs.length > 0){
        var baseUrl = $userTabs.data("baseurl");
        $("#user-tabs li a").click(function(){
            var status = $(this).attr("href").substr(1);
            init_filter_index(baseUrl + "?status=" + status, true);
            $("#user-tabs li.active").removeClass("active");
            $(this).parent().addClass("active");
        });
      }
    }

    function loadMoreSeries() {
        loading = true;
        autoLoad = true;
        $(".load-more-series").button('loading');
        $.get("?format=js&offset=" + seriesShown)
        .done(function () {
            seriesShown += perBatch;
            if (seriesShown >= seriesTotal) {
                $(".load-more-series").hide();
            }
        })
        .always(function () {
            loading = false;
            $(".load-more-series").button('reset');
        });
    }

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
