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

        // Select tab and load users
        var selectTab = function($tab){
          var $kebab = $("#kebab-menu");
          var status = $tab.attr("href").substr(1);
          if(status == 'pending'){
            $kebab.show();
          }
          else {
            $kebab.hide();
          }
          init_filter_index(baseUrl + "?status=" + status, true);
          $("#user-tabs li.active").removeClass("active");
          $tab.parent().addClass("active");
        }

        // Switch to clicked tab
        $("#user-tabs li a").click(function(){
            selectTab($(this));
        });

        // Determine which tab to show first
        var hash = window.location.hash;
        var $tab = $("a[href='" + hash + "']");
        if ($tab.length === 0){
          // Default to enrolled (subscribed)
          $tab = $("a[href='#enrolled']")
        }
        selectTab($tab);
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
