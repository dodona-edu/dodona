import { setBaseUrl } from "./index.js";
import { initDragAndDrop } from "./drag_and_drop.js";
import { getURLParameter } from "./util.js";
import { ScrollSpy } from "./scrollspy";

function loadUsers(_baseUrl, _status) {
    const baseUrl = _baseUrl || $("#user-tabs").data("baseurl");
    const status = _status || getURLParameter("status");
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

const TABLE_WRAPPER_SELECTOR = ".series-activities-table-wrapper";
const SKELETON_TABLE_SELECTOR = ".activity-table-skeleton";

class Series {
    static findAll(cards_selector = ".series.card") {
        const $cards = $(cards_selector);
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

    load(callback = () => { }) {
        this.loading = true;
        $.get(this.url).done(() => {
            this.loading = false;
            this.reselect(`#series-card-${this.id}`);
        });
        callback();
    }
}

function initCourseShow() {
    const series = Series.findAll().sort((s1, s2) => s1.top - s2.bottom);

    function init() {
        const nav = document.getElementById("scrollspy-nav");
        if (nav) {
            new ScrollSpy(nav, {
                sectionSelector: ".series .anchor",
                offset: 90,
            }).activate();
        }
        $(window).scroll(scroll);
        scroll(); // Load series visible on pageload
    }

    function scroll() {
        const screenTop = $(window).scrollTop();
        const screenBottom = screenTop + $(window).height();
        const firstVisible = series.findIndex(s => screenTop < s.bottom);
        const firstToLoad = firstVisible <= 0 ? 0 : firstVisible - 1;
        const lastVisibleIdx = series.findIndex(s => screenBottom < s.top);
        const lastToLoad = lastVisibleIdx == -1 ? series.length : lastVisibleIdx;

        series
            .slice(firstToLoad, lastToLoad + 1)
            .filter(s => s.needsLoading())
            .forEach(s => s.load());
    }

    init();
}

function initCourseForm() {
    function init() {
        initInstitutionRelatedSelects();
    }

    function initInstitutionRelatedSelects() {
        const institutionSelect = $("#course_institution_id");
        const visibleForAll = $("#course_visibility_visible_for_all");
        const visibleForInstitution = $("#course_visibility_visible_for_institution");
        const registrationForAll = $("#course_registration_open_for_all");
        const registrationForInstitution = $("#course_registration_open_for_institution");

        function changeListener() {
            if (!institutionSelect.val()) {
                if (visibleForInstitution.is(":checked")) {
                    visibleForAll.prop("checked", true);
                }

                if (registrationForInstitution.is(":checked")) {
                    registrationForAll.prop("checked", true);
                }

                visibleForInstitution.attr("disabled", true);
                registrationForInstitution.attr("disabled", true);
                $(".fill-institution").html(I18n.t("js.configured-institution"));
            } else {
                visibleForInstitution.removeAttr("disabled");
                registrationForInstitution.removeAttr("disabled");
                $(".fill-institution").html(institutionSelect.find("option:selected").html());
            }
        }

        setTimeout(changeListener);
        institutionSelect.on("change", changeListener);
    }

    init();
}

const DRAG_AND_DROP_ARGS = {
    table_selector: ".course-series-list tbody",
    item_selector: ".course-series-list",
    item_data_selector: "course_id",
    order_selector: ".course-series-list tbody .series-name",
    order_data_selector: "series_id",
    url_from_id: function (courseId) {
        return `/courses/${courseId}/reorder_series.js`;
    },
};

function initSeriesReorder() {
    initDragAndDrop(DRAG_AND_DROP_ARGS);
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
            $(this)
                .closest(".panel")
                .find(".answer")
                .html($(this).data("answer"));
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
            $(this)
                .closest(".panel")
                .find(".answer")
                .html($(this).data("answer"));
        });
    }

    function copyCoursesLoaded() {
        $("[data-course_id]").click(function () {
            $(this)
                .find("input[type=\"radio\"]")
                .prop("checked", true);
            $(this)
                .closest(".panel")
                .find(".answer")
                .html($(this).data("answer"));
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

        $(".copy-course-row .nested-link").click(function (e) {
            e.stopPropagation();
        });
    }

    function courseFormLoaded() {
        $formPanel.removeClass("hidden");
        $formPanel.find(".panel-collapse").collapse("show");
        window.scrollTo(0, 0);
    }

    init();
}

function initCoursesListing(firstTab) {
    let baseUrl = "";
    initCourseTabs(firstTab);

    function initCourseTabs(firstTab) {
        const courseTabs = document.getElementById("course-tabs");
        baseUrl = courseTabs.dataset.baseurl;

        // Switch to clicked tab
        document.querySelectorAll("#course-tabs li a").forEach(tab => {
            tab.addEventListener("click", () => selectTab(tab));
        });

        // Determine which tab to show first
        const hash = window.location.hash;
        let tab = document.querySelector(`a[href='${hash}']`);
        if (!tab) {
            tab = document.querySelector(`a[href='#${firstTab}']`);
        }
        selectTab(tab);
    }

    function selectTab(tab) {
        const state = tab.getAttribute("href").substr(1);
        if (tab.classList.contains("active")) {
            // The current tab is already loaded, nothing to do
            return;
        }
        loadCourses(state);
        document.querySelector("#course-tabs a.active")?.classList?.remove("active");
        tab.classList.add("active");
    }

    function loadCourses(tab) {
        const state = tab ?? getURLParameter("tab");
        setBaseUrl(`${baseUrl}?tab=${state}`);
    }
}

export {
    initSeriesReorder,
    initCourseForm,
    initCourseNew,
    initCourseShow,
    initCourseMembers,
    initCoursesListing,
    loadUsers,
};
