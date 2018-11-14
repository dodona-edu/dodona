/* globals ga, I18n, ace, MathJax, initStrip, Strip */
import {initFilter} from "./index.js";
import dragula from "dragula";

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
            if (status === "pending") {
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


const TABLE_WRAPPER_SELECTOR = ".series-exercises-table-wrapper";
const SKELETON_TABLE_SELECTOR = ".exercise-table-skeleton";

class Series {
    static findAll(cards_selector = ".series.card") {
        let $cards = $(cards_selector);
        return $.map($cards, card => new Series(card));
    }

    constructor(card) {
        this.id = +card.id.split("series-card-")[1];

        this.reselect(card);
    }

    reselect(cardSelector) {
        this.$card = $(cardSelector);
        this.url = this.$card.data("series-url");
        this.$table_wrapper = this.$card.find(TABLE_WRAPPER_SELECTOR);
        this.$skeleton = this.$table_wrapper.find(SKELETON_TABLE_SELECTOR);
        this.loaded = this.$skeleton.length === 0;
        this.loading = false;
        this.top = this.$card.offset().top;
        this.bottom = this.top + this.$card.height();
    }

    needsLoading() {
        return !this.loaded && !this.loading;
    }

    load(callback = () => {
    }) {
        this.loading = true;
        $.get(this.url).done(() => {
            this.loading = false;
            this.reselect(`#series-card-${this.id}`);
        });
        callback();
    }
}

function initCourseShow() {
    let series = Series.findAll().sort((s1, s2) => s1.top - s2.bottom);

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
            let loading = true;
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
        const screenTop = $(window).scrollTop();
        const screenBottom = screenTop + $(window).height();
        const firstVisible = series.findIndex(s => screenTop < s.bottom);
        const firstToLoad = firstVisible <= 0 ? 0 : firstVisible - 1;
        const lastVisibleIdx = series.findIndex(s => screenBottom < s.top);
        const lastToLoad = lastVisibleIdx == -1 ? series.length : lastVisibleIdx;

        series.slice(firstToLoad, lastToLoad + 1)
            .filter(s => s.needsLoading())
            .forEach(s => s.load());
    }

    init();
}

function initCourseEdit() {
    function init() {
        initDragAndDrop();
    }

    function initDragAndDrop() {
        const tableBody = $(".course-series-list tbody").get(0);
        dragula([tableBody], {
            moves: function (el, source, handle, sibling) {
                return $(handle).hasClass("drag-handle") || $(handle).parents(".drag-handle").length;
            },
            mirrorContainer: tableBody,
        }).on("drop", () => {
            let courseId = $(".course-series-list").data("course_id");
            let order = $(".course-series-list tbody .series-name").map(function () {
                return $(this).data("series_id");
            }).get();
            $.post(`/courses/${courseId}/reorder_series.js`, {
                order: JSON.stringify(order),
            });
        });
    }

    init();
}

export {initCourseEdit, initCourseShow, initCourseMembers, loadUsers};
