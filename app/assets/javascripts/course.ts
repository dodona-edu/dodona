import { initDragAndDrop } from "./drag_and_drop";
import { fetch, getURLParameter } from "./util.js";
import { ScrollSpy } from "./scrollspy";
import { searchQuery } from "./search";
import { html, render } from "lit";
import { Modal } from "bootstrap";

function loadUsers(_status = undefined): void {
    const status = _status || getURLParameter("status");
    searchQuery.queryParams.updateParam("status", status);
}

function initCourseMembers(): void {
    function init(): void {
        initUserTabs();
        initLabelsEditModal();
    }

    function initUserTabs(): void {
        const userTabs = document.getElementById("user-tabs");
        if (userTabs === null) {
            return;
        }

        const baseUrl = userTabs.dataset.baseurl;
        // Select tab and load users
        const selectTab = (tab): HTMLElement => {
            const kebab = document.getElementById("kebab-menu");
            const status = tab.dataset.status;
            const kebabItems = kebab.querySelectorAll<HTMLElement>("li a.action");
            let anyShown = false;
            for (const item of kebabItems) {
                const dataType = item.dataset.type;
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

            loadUsers(status);
            document.querySelector("#user-tabs li.active").classList.remove("active");
            tab.parentNode.classList.add("active");
        };

        // Switch to clicked tab
        document.querySelectorAll("#user-tabs li a")
            .forEach(el => {
                el.addEventListener("click", function (e) {
                    selectTab(el);
                    e.preventDefault();
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

    function initLabelsEditModal(): void {
        document.getElementById("labelsUploadButton").addEventListener("click", () => {
            const modal = document.getElementById("labelsUploadModal");
            const input = document.getElementById("newCsvFileInput") as HTMLInputElement;
            const formData = new FormData();
            formData.append("file", input.files[0]);
            fetch(`/courses/${modal.dataset.course_id}/members/upload_labels_csv`, {
                method: "POST",
                body: formData,
            }).then(async response => {
                if (!response.ok) {
                    const error = await response.json();
                    const alert = html`
                        <div class="alert alert-danger alert-dismissible">
                        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>${error.message}</div>
                    `;
                    const modalBody = modal.getElementsByClassName("modal-body")[0] as HTMLElement;
                    render(alert, modalBody, { renderBefore: modalBody.firstChild } );
                } else {
                    loadUsers();
                    Modal.getOrCreateInstance(modal).hide();
                }
            });
        });
    }

    function hideElement(element: HTMLElement): void {
        element.style.display = "none";
    }

    function showElement(element: HTMLElement): void {
        element.style.display = "block";
    }

    init();
}

const TABLE_WRAPPER_SELECTOR = ".series-activities-table-wrapper";
const SKELETON_TABLE_SELECTOR = ".skeleton-table";

class Series {
    private readonly id: number;
    private url: string;
    private loaded: boolean;
    private loading: boolean;
    private _top: number;
    private _bottom: number;

    get top(): number {
        return this._top;
    }

    get bottom(): number {
        return this._bottom;
    }

    static findAll(cardsSelector = ".series.card"): Array<Series> {
        const cards = document.querySelectorAll(cardsSelector);
        return Array.from(cards, card => new Series(card));
    }

    constructor(card) {
        this.id = +card.id.split("series-card-")[1];

        this.reselect(card);
    }

    reselect(card: HTMLElement): void {
        this.url = card.dataset.seriesUrl;
        const tableWrapper: HTMLElement | null = card.querySelector(TABLE_WRAPPER_SELECTOR);
        const skeleton = tableWrapper?.querySelector(SKELETON_TABLE_SELECTOR);
        // if tableWrapper is null the series is empty (no activities) => series is always loaded
        this.loaded = skeleton === null || tableWrapper === null;
        this.loading = false;
        this._top = card.getBoundingClientRect().top + window.scrollY;
        this._bottom = this.top + card.getBoundingClientRect().height;
    }

    needsLoading(): boolean {
        return !this.loaded && !this.loading;
    }

    load(): void {
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
    }
}

function initCourseShow(): void {
    const series = Series.findAll().sort((s1, s2) => s1.top - s2.bottom);

    function init(): void {
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

    function scroll(): void {
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

function initCourseForm(): void {
    function init(): void {
        initInstitutionRelatedSelects();
    }

    function initInstitutionRelatedSelects(): void {
        const institutionSelect = document.getElementById("course_institution_id") as HTMLInputElement;
        const visibleForAll = document.getElementById("course_visibility_visible_for_all") as HTMLInputElement;
        const visibleForInstitution = document.getElementById("course_visibility_visible_for_institution") as HTMLInputElement;
        const registrationForAll = document.getElementById("course_registration_open_for_all") as HTMLInputElement;
        const registrationForInstitution = document.getElementById("course_registration_open_for_institution") as HTMLInputElement;

        function changeListener(): void {
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

function initSeriesReorder(): void {
    initDragAndDrop(DRAG_AND_DROP_ARGS);
}

function initCourseNew(): void {
    function init(): void {
        initPanelLogic();
        window.dodona.courseFormLoaded = courseFormLoaded;
        window.dodona.copyCoursesLoaded = copyCoursesLoaded;

        // Bootstrap's automatic collapsing of other elements in the parent breaks
        // when doing manual shows and hides, so we have to do this.
        typeCollapseElement.addEventListener("show.bs.collapse", () => {
            chooseCollapse.hide();
            formCollapse.hide();
        });
        chooseCollapseElement.addEventListener("show.bs.collapse", () => {
            typeCollapse.hide();
            formCollapse.hide();
        });
        formCollapseElement.addEventListener("show.bs.collapse", () =>{
            typeCollapse.hide();
            chooseCollapse.hide();
        });
    }

    const typePanel = document.getElementById("type-panel");
    const typeCollapseElement = typePanel.querySelector(".panel-collapse");
    const typeCollapse = new bootstrap.Collapse(typeCollapseElement, { toggle: false });

    const choosePanel = document.getElementById("choose-panel");
    const chooseCollapseElement = choosePanel.querySelector(".panel-collapse");
    const chooseCollapse = new bootstrap.Collapse(chooseCollapseElement, { toggle: false });

    const formPanel = document.getElementById("form-panel");
    const formCollapseElement = formPanel.querySelector(".panel-collapse");
    const formCollapse = new bootstrap.Collapse(formCollapseElement, { toggle: false });

    function initPanelLogic(): void {
        document.getElementById("new-course").addEventListener("click", function () {
            choosePanel.classList.add("hidden");
            formPanel.querySelector(".step-circle").innerHTML = "2";
            this.closest(".panel")
                .querySelector(".answer")
                .textContent = this.dataset.answer;
            fetch("/courses/new.js")
                .then(req => req.text())
                .then(resp => eval(resp));
        });

        document.getElementById("copy-course").addEventListener("click", function () {
            choosePanel.classList.remove("hidden");
            chooseCollapse.show();
            choosePanel.querySelectorAll<HTMLInputElement>(`input[type="radio"]`).forEach(el => {
                el.checked = false;
            });
            formPanel.classList.add("hidden");
            formPanel.querySelector(".step-circle").innerHTML = "3";
            this.closest(".panel")
                .querySelector(".answer")
                .textContent = this.dataset.answer;
        });
    }

    function copyCoursesLoaded(): void {
        document.querySelectorAll("[data-course_id]").forEach(el => {
            el.addEventListener("click", function () {
                this.querySelector(`input[type="radio"]`).checked = true;
                this.closest(".panel")
                    .querySelector(".answer")
                    .textContent = this.dataset.answer;
                fetch(`/courses/new.js?copy_options[base_id]=${this.dataset.course_id}`)
                    .then(req => req.text())
                    .then(resp => eval(resp));
            });
        });

        document.querySelectorAll(".copy-course-row .nested-link").forEach(el => {
            el.addEventListener("click", event => {
                event.stopPropagation();
            });
        });
    }

    function courseFormLoaded(): void {
        formPanel.classList.remove("hidden");
        formCollapse.show();
        window.scrollTo(0, 0);
    }

    init();
}

export {
    initSeriesReorder,
    initCourseForm,
    initCourseNew,
    initCourseShow,
    initCourseMembers,
    loadUsers,
};
