import { initDragAndDrop } from "./drag_and_drop.js";
import { fetch, getURLParameter } from "./util.js";
import { ScrollSpy } from "./scrollspy";
import { searchQuery } from "./search";

function loadUsers(_baseUrl, _status) {
    const status = _status || getURLParameter("status");
    searchQuery.queryParams.updateParam("status", status);
}

function initCourseMembers() {
    function init() {
        initUserTabs();
        initLabelsEditModal();
    }

    function initUserTabs() {
        const userTabs = document.getElementById("user-tabs");
        if (userTabs !== null) {
            const baseUrl = userTabs.getAttribute("data-baseurl");

            // Select tab and load users
            const selectTab = tab => {
                const kebab = document.getElementById("kebab-menu");
                const status = tab.getAttribute("data-status");
                const kebabItems = kebab.querySelectorAll("li a.action");
                let anyShown = false;
                for (const item of kebabItems) {
                    const dataType = item.getAttribute("data-type");
                    if (dataType && dataType !== status) {
                        hideElement(item);
                    } else {
                        showElement(item);
                        anyShown = true;
                    }
                }
                if (anyShown) {
                    showElement(kebab);
                } else {
                    hideElement(kebab);
                }
                if (tab.parentNode.classList.contains("active")) {
                    // The current tab is already loaded, nothing to do
                    return;
                }

                loadUsers(baseUrl, status);
                document.querySelector("#user-tabs li.active").classList.remove("active");
                tab.parentNode.classList.add("active");
            };

            // Switch to clicked tab
            document.querySelectorAll("#user-tabs li a")
                .forEach(el => {
                    el.addEventListener("click", function () {
                        selectTab(this);
                    });
                });

            // Determine which tab to show first
            const status = searchQuery.queryParams.params.get("status");
            let tab = document.querySelector("a[data-status='" + status + "']");
            if (tab === null) {
                tab = document.querySelector("a[data-status='enrolled']");
            }
            selectTab(tab);
        }
    }

    function initLabelsEditModal() {
        document.getElementById("labelsUploadButton").addEventListener("click", () => {
            const modal = document.getElementById("labelsUploadModal");
            const input = document.getElementById("newCsvFileInput");
            const formData = new FormData();
            formData.append("file", input.files[0]);
            fetch(`/courses/${modal.getAttribute("data-course_id")}/members/upload_labels_csv`, {
                method: "POST",
                body: formData,
            }).then(loadUsers);
        });
    }

    function hideElement(element) {
        element.style.display = "none";
    }

    function showElement(element) {
        element.style.display = "block";
    }

    init();
}

const TABLE_WRAPPER_SELECTOR = ".series-activities-table-wrapper";
const SKELETON_TABLE_SELECTOR = ".activity-table-skeleton";

class Series {
    static findAll(cardsSelector = ".series.card") {
        const cards = document.querySelectorAll(cardsSelector);
        return Array.from(cards, card => new Series(card));
    }

    constructor(card) {
        this.id = +card.id.split("series-card-")[1];

        this.reselect(card);
    }

    reselect(cardSelector) {
        this.card = cardSelector;
        this.url = this.card.getAttribute("data-series-url");
        this.table_wrapper = this.card.querySelector(TABLE_WRAPPER_SELECTOR);
        this.skeleton = this.table_wrapper.querySelector(SKELETON_TABLE_SELECTOR);
        this.loaded = this.skeleton === null;
        this.loading = false;
        this.top = this.card.getBoundingClientRect().top + window.pageYOffset;
        this.bottom = this.top + this.card.getBoundingClientRect().height;
    }

    needsLoading() {
        return !this.loaded && !this.loading;
    }

    load(callback = () => { }) {
        this.loading = true;
        fetch(this.url, {
            method: "GET"
        }).then(async response => {
            if (response.ok) {
                eval(await response.text());
                this.loading = false;
                this.reselect(document.getElementById(`series-card-${this.id}`));
            }
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
        window.addEventListener("scroll", scroll);
        scroll(); // Load series visible on pageload
    }

    function scroll() {
        const screenTop = document.scrollingElement.scrollTop;
        const screenBottom = screenTop + window.innerHeight;
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
        const institutionSelect = document.getElementById("course_institution_id");
        const visibleForAll = document.getElementById("course_visibility_visible_for_all");
        const visibleForInstitution = document.getElementById("course_visibility_visible_for_institution");
        const registrationForAll = document.getElementById("course_registration_open_for_all");
        const registrationForInstitution = document.getElementById("course_registration_open_for_institution");

        function changeListener() {
            if (!institutionSelect.value) {
                if (visibleForInstitution.checked) {
                    visibleForAll.checked = true;
                }

                if (registrationForInstitution.checked) {
                    registrationForAll.checked = true;
                }

                visibleForInstitution.disabled = true;
                registrationForInstitution.disabled = true;
                document.querySelectorAll(".fill-institution")
                    .forEach(el => {
                        el.innerHTML = I18n.t("js.configured-institution");
                    });
            } else {
                visibleForInstitution.removeAttribute("disabled");
                registrationForInstitution.removeAttribute("disabled");
                console.log("hereeee");
                document.querySelectorAll(".fill-institution")
                    .forEach(el => {
                        el.innerHTML = institutionSelect.querySelector("option:checked").innerHTML;
                    });
            }
        }

        setTimeout(changeListener);
        institutionSelect.addEventListener("change", changeListener);
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
        typePanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", function () {
            choosePanel.querySelector(".panel-collapse").classList.remove("show");
            formPanel.querySelector(".panel-collapse").classList.remove("show");
        });
        choosePanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", function () {
            typePanel.querySelector(".panel-collapse").classList.remove("show");
            formPanel.querySelector(".panel-collapse").classList.remove("show");
        });
        formPanel.querySelector(".panel-collapse").addEventListener("show.bs.collapse", function () {
            typePanel.querySelector(".panel-collapse").classList.remove("show");
            choosePanel.querySelector(".panel-collapse").classList.remove("show");
        });
    }

    const typePanel = document.getElementById("type-panel");
    const choosePanel = document.getElementById("choose-panel");
    const formPanel = document.getElementById("form-panel");

    function initPanelLogic() {
        document.getElementById("new-course").addEventListener("click", function () {
            choosePanel.classList.add("hidden");
            formPanel.querySelector(".step-circle").innerHTML = "2";
            this.closest(".panel")
                .querySelector(".answer")
                .innerHTML = this.getAttribute("data-answer");
            fetch("/courses/new.js")
                .then(req => req.text())
                .then(resp => eval(resp));
        });

        document.getElementById("copy-course").addEventListener("click", function () {
            choosePanel.classList.remove("hidden");
            choosePanel.querySelector(".panel-collapse").classList.add("show");
            choosePanel.querySelector("input[type=\"radio\"]").checked = false;
            formPanel.classList.add("hidden");
            formPanel.querySelector(".step-circle").innerHTML = "3";
            this.closest(".panel")
                .querySelector(".answer")
                .innerHTML = this.getAttribute("data-answer");
        });
    }

    function copyCoursesLoaded() {
        document.querySelectorAll("[data-course_id]").forEach(el => {
            el.addEventListener("click", function () {
                this.querySelector("input[type=\"radio\"]")
                    .checked = true;
                this.closest(".panel")
                    .querySelector(".answer")
                    .innerText = this.getAttribute("data-answer");
                fetch(`/courses/new.js?copy_options[base_id]=${this.getAttribute("data-course_id")}`)
                    .then(req => req.text())
                    .then(resp => eval(resp));
            });
        });

        document.querySelectorAll(".copy-course-row .nested-link").forEach(el => {
            el.addEventListener("click", function (e) {
                e.stopPropagation();
            });
        });
    }

    function courseFormLoaded() {
        formPanel.classList.remove("hidden");
        formPanel.querySelector(".panel-collapse").classList.add("show");
        window.scrollTo(0, 0);
    }

    init();
}

function initCoursesListing(firstTab) {
    initCourseTabs(firstTab);

    function initCourseTabs(firstTab) {
        document.querySelectorAll("#course-tabs li a").forEach(tab => {
            tab.addEventListener("click", event => {
                event.preventDefault(); // used to prevent popstate event from firing
                selectTab(tab);
            });
        });

        // If the url hash is a valid tab, use that, otherwise use the given tab
        const hash = searchQuery.queryParams.params.get("tab");
        const tab = document.querySelector(`a[data-tab='${hash}']`) ??
            document.querySelector(`a[data-tab='${firstTab}']`);
        selectTab(tab);
    }

    function selectTab(tab) {
        // If the current tab is already loaded or if it's blank, do nothing
        if (!tab || tab.classList.contains("active")) return;

        const state = tab.getAttribute("data-tab");
        loadCourses(state);
        document.querySelector("#course-tabs a.active")?.classList?.remove("active");
        tab.classList.add("active");
    }

    function loadCourses(tab) {
        searchQuery.queryParams.updateParam("tab", tab);
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
