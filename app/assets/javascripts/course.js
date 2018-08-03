/* globals ga, I18n, ace, MathJax, initStrip, Strip */
import {initFilter} from "./index.js";

function loadUsers(_baseUrl, _status) {
    const baseUrl = _baseUrl || $("#user-tabs").data("baseurl");
    const status = _status || window.location.hash.substr(1);
    initFilter(baseUrl + "?status=" + status, true);
}

function initUserTabs(){
  const $userTabs = $("#user-tabs")
  if($userTabs.length > 0){
    const baseUrl = $userTabs.data("baseurl");

    // Select tab and load users
    const selectTab = ($tab) => {
      if($tab.parent().hasClass("active")){
        // The current tab is already loaded, nothing to do
        return;
      }
      const $kebab = $("#kebab-menu");
      const status = $tab.attr("href").substr(1);
      if(status == 'pending'){
        $kebab.show();
      }
      else {
        $kebab.hide();
      }
      loadUsers(baseUrl, status);
      $("#user-tabs li.active").removeClass("active");
      $tab.parent().addClass("active");
    }

    // Switch to clicked tab
    $("#user-tabs li a").click(function(){
      selectTab($(this));
    });

    // Determine which tab to show first
    const hash = window.location.hash;
    let $tab = $("a[href='" + hash + "']");
    if ($tab.length === 0){
      // Default to enrolled (subscribed)
      $tab = $("a[href='#enrolled']")
    }
    selectTab($tab);
  }
}

function initCourseMembers(){
  $("#kebab-menu").hide();
  initUserTabs();
}

function initCourseShow(_seriesShown, _seriesTotal) {
    const perBatch = _seriesShown,
          seriesTotal = _seriesTotal;

    let seriesShown = _seriesShown,
        loading = false;


    function init() {
        $(".load-more-series").click(loadMoreSeries);
        $(window).scroll(scroll);
        gotoHashSeries();
        window.addEventListener("hashchange", gotoHashSeries);
    }

    function gotoHashSeries() {
      const hash = window.location.hash;

      if($(hash).length > 0){
        // The current series is already loaded
        // and we should have scrolled to it
        return;
      }

      const hashSplit = hash.split('-');
      const seriesId = +hashSplit[1];

      if (hashSplit[0] === '#series' && !isNaN(seriesId)){
        loading = true;
        $(".load-more-series").button("loading");
        $.get(`?format=js&offset=${seriesShown}&series=${seriesId}`)
          .done(() => {
            seriesShown = $(".series").length;
            $(hash)[0].scrollIntoView();
          })
          .always(() => {
            loading = false;
            $(".load-more-series").button("reset");
          });
      }
    }

    function loadMoreSeries() {
        if(loading){
          return;
        }
        loading = true;
        $(".load-more-series").button("loading");
        $.get(`?format=js&offset=${seriesShown}`)
            .done(() => {
                seriesShown += perBatch;
                if (seriesShown >= seriesTotal) {
                    $(".load-more-series").hide();
                }
            })
            .always(() => {
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

        const topOfElement = $(".load-more-series").offset().top;
        const bottomOfScreen = $(window).scrollTop() + $(window).height();
        if (topOfElement < bottomOfScreen) {
            loadMoreSeries();
        }
    }

    init();
}

export {initCourseShow, initCourseMembers, loadUsers};
