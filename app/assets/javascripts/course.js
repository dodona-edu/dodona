/* globals ga, I18n, ace, MathJax, initStrip, Strip */
import {initFilter} from "./index.js";
import {delay} from "./util.js";

function loadUsers(_baseUrl, _status) {
    const baseUrl = _baseUrl || $("#user-tabs").data("baseurl");
    const status = _status || window.location.hash.substr(1);
    initFilter(baseUrl + "?status=" + status, true);
}

function initUserTabs() {
    const $userTabs = $("#user-tabs");
    if ($userTabs.length > 0) {
        const baseUrl = $userTabs.data("baseurl");

        // Select tab and load users
        const selectTab = $tab => {
            if ($tab.parent().hasClass("active")) {
                // The current tab is already loaded, nothing to do
                return;
            }
            const $kebab = $("#kebab-menu");
            const status = $tab.attr("href").substr(1);
            if (status == "pending") {
                $kebab.show();
            } else {
                $kebab.hide();
            }
            loadUsers(baseUrl, status);
            $("#user-tabs li.active").removeClass("active");
            $tab.parent().addClass("active");
        };

        // Switch to clicked tab
        $("#user-tabs li a").click(function () {
            selectTab($(this));
        });

        // Determine which tab to show first
        const hash = window.location.hash;
        let $tab = $("a[href='" + hash + "']");
        if ($tab.length === 0) {
            // Default to enrolled (subscribed)
            $tab = $("a[href='#enrolled']");
        }
        selectTab($tab);
    }
}

function initCourseMembers() {
    $("#kebab-menu").hide();
    initUserTabs();
}


const table_wrapper_selector = '.series-exercises-table-wrapper';
const skeleton_table_selector = '.exercise-table-skeleton';

class Series {
  static findAll(cards_selector='.series.card') {
    let $cards = $(cards_selector);
    return $.map($cards, card => new Series(card));
  }

  constructor(card,) {
    this.id = +card.id.split('series-card-')[1];

    this.reselect(card);
  }

  reselect(card_selector){
    this.$card = $(card_selector);
    this.url = this.$card.data("series-url");
    this.$table_wrapper = this.$card.find(table_wrapper_selector);
    this.$skeleton = this.$table_wrapper.find(skeleton_table_selector);
    this.loaded = this.$skeleton.length === 0;
    this.loading = false;
    this.position = this.$card.offset().top;
  }

  needsLoading(){
    return !this.loaded && !this.loading;
  }

  load(callback=()=>{}) {
    this.loading = true;
    $.get(this.url).done(() => {
      this.loading = false;
      this.reselect(`#series-card-${this.id}`);
    });
    callback();
  }
}

function initCourseShow() {
    let series = Series.findAll().sort((s1, s2) => s1.position - s2.position);

    function init() {
        $(window).scroll(scroll);
        gotoHashSeries();
        window.addEventListener("hashchange", gotoHashSeries);
        scroll(); // Also load series
    }

    function gotoHashSeries() {
        const hash = window.location.hash;

        if ($(hash).length > 0) {
            // The current series is already loaded
            // and we should have scrolled to it
            return;
        }

        const hashSplit = hash.split("-");
        const seriesId = +hashSplit[1];

        if (hashSplit[0] === "#series" && !isNaN(seriesId)) {
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

    function scroll() {
      const screen_bottom = $(window).scrollTop() + $(window).height();
      let i = 0;
      while(i < series.length && series[i].position < screen_bottom) {
        if (series[i].needsLoading()) {
          series[i].load();
        }
        i += 1;
      }
    }

    init();
}

function initCourseIndex() {
    let $filter = $("#filter-query").focus();
    $filter.on("keyup", function () {
        $("#progress-filter").css("visibility", "visible");
        delay(doSearch, 300);
    });

    function doSearch() {
        let q = $filter.val().toLowerCase();
        let $courseCards = $(".card.course");
        if (q === "") {
            $courseCards.parent().removeClass("hidden");
        } else {
            $courseCards.parent().addClass("hidden");
            $courseCards.filter(function () {
                return $(this).data("search").includes(q);
            }).parent().removeClass("hidden");
        }
        setTimeout(() => $("#progress-filter").css("visibility", "hidden"), 200);
    }
}

export {initCourseShow, initCourseMembers, loadUsers, initCourseIndex};
