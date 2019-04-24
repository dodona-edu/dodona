/* globals ga, I18n, ace, MathJax, initStrip, Strip */
import {setBaseUrl} from "./index.js";
import dragula from "dragula";

function loadUsers(_baseUrl, _status) {
    const baseUrl = _baseUrl || $("#user-tabs").data("baseurl");
    const status = _status || window.location.hash.substr(1);
    setBaseUrl(baseUrl + "?status=" + status);
}

function initCourseMembers() {
    function init() {
        initUserTabs();
        initLabelsEditModal();
    }

    function initUserTabs() {
        const $userTabs = $("#user-tabs");
        if ($userTabs.length > 0) {
            const baseUrl = $userTabs.data("baseurl");

            // Select tab and load users
            const selectTab = $tab => {
                const $kebab = $("#kebab-menu");
                const status = $tab.attr("href").substr(1);
                const $kebabItems = $kebab.find("li a.action");
                let anyShown = false;
                for (const item of $kebabItems) {
                    const $item = $(item);
                    if ($item.data("type") && $item.data("type") !== status) {
                        $item.hide();
                    } else {
                        $item.show();
                        anyShown = true;
                    }
                }
                if (anyShown) {
                    $kebab.show();
                } else {
                    $kebab.hide();
                }
                if ($tab.parent().hasClass("active")) {
                    // The current tab is already loaded, nothing to do
                    return;
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

    function initLabelsEditModal() {
        $("#labelsUploadButton").click(() => {
            const $modal = $("#labelsUploadModal");
            const $input = $("#newCsvFileInput")[0];
            const formData = new FormData();
            formData.append("file", $input.files[0]);
            $.post({
                url: `/courses/${$modal.data("course_id")}/members/upload_labels_csv`,
                contentType: false,
                processData: false,
                data: formData,
                success: function () {
                    loadUsers();
                },
            });
        });
    }

    init();
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

function initCourseNew() {
    function init() {
        initPanelLogic();
        window.dodona.courseFormLoaded = courseFormLoaded;
        window.dodona.copyCoursesLoaded = copyCoursesLoaded;

        // Bootstrap's automatic collapsing of other elements in the parent breaks
        // when doing manual shows and hides, so we have to do this.
        $typePanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $choosePanel.find(".panel-collapse").collapse("hide");
            $formPanel.find(".panel-collapse").collapse("hide");
        });
        $choosePanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $typePanel.find(".panel-collapse").collapse("hide");
            $formPanel.find(".panel-collapse").collapse("hide");
        });
        $formPanel.find(".panel-collapse").on("show.bs.collapse", function () {
            $typePanel.find(".panel-collapse").collapse("hide");
            $choosePanel.find(".panel-collapse").collapse("hide");
        });
    }

    const $typePanel = $("#type-panel");
    const $choosePanel = $("#choose-panel");
    const $formPanel = $("#form-panel");

    function initPanelLogic() {
        $("#new-course").click(function () {
            $choosePanel.addClass("hidden");
            $formPanel.find(".step-circle").html("2");
            fetch("/courses/new.js", {
                headers: {
                    "accept": "text/javascript",
                    "x-csrf-token": $("meta[name=\"csrf-token\"]").attr("content"),
                    "x-requested-with": "XMLHttpRequest",
                },
                credentials: "same-origin",
            })
                .then(req => req.text())
                .then(resp => eval(resp));
        });

        $("#copy-course").click(function () {
            $choosePanel.removeClass("hidden");
            $choosePanel.find(".panel-collapse").collapse("show");
            $choosePanel.find("input[type=\"radio\"]").prop("checked", false);
            $formPanel.addClass("hidden");
            $formPanel.find(".step-circle").html("3");
        });
    }

    function copyCoursesLoaded() {
        $("[data-course_id]").click(function () {
            $(this).find("input[type=\"radio\"]").prop("checked", true);
            fetch(`/courses/new.js?copy_options[base_id]=${$(this).data("course_id")}`, {
                headers: {
                    "accept": "text/javascript",
                    "x-csrf-token": $("meta[name=\"csrf-token\"]").attr("content"),
                    "x-requested-with": "XMLHttpRequest",
                },
                credentials: "same-origin",
            })
                .then(req => req.text())
                .then(resp => eval(resp));
        });

        $("[data-course_id] a").click(function (e) {
            e.stopPropagation();
        });
    }

    function courseFormLoaded() {
        $formPanel.removeClass("hidden");
        $formPanel.find(".panel-collapse").collapse("show");
    }

    init();
}

export {initCourseEdit, initCourseNew, initCourseShow, initCourseMembers, loadUsers};
