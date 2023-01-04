import { Toast } from "./toast";
import { initDragAndDrop } from "./drag_and_drop";
import { initDatePicker, fetch } from "./util.js";

import { ViolinGraph } from "visualisations/violin";
import { StackedStatusGraph } from "visualisations/stacked_status";
import { TimeseriesGraph } from "visualisations/timeseries";
import { CTimeseriesGraph } from "visualisations/cumulative_timeseries";

const DRAG_AND_DROP_ARGS = {
    table_selector: ".series-activity-list tbody",
    item_selector: ".series-activity-list a.remove-activity",
    item_data_selector: "series_id",
    order_selector: ".series-activity-list a.remove-activity",
    order_data_selector: "activity_id",
    url_from_id: (seriesId: string) => {
        return `/series/${seriesId}/reorder_activities.js`;
    },
};

function initSeriesEdit(): void {
    function init(): void {
        initAddButtons();
        initRemoveButtons();
        initDragAndDrop(DRAG_AND_DROP_ARGS);
        // export function
        dodona.seriesEditActivitiesLoaded = () => {
            initAddButtons();
        };
    }

    function initAddButtons(): void {
        document.querySelectorAll("a.add-activity").forEach(b => {
            b.addEventListener("click", e => {
                // prevent automatic scrolling to top of the page
                e.preventDefault();

                const addButton = e.currentTarget;
                const activityId = addButton.dataset.activity_id;
                const activityName = addButton.dataset.activity_name;
                const seriesId = addButton.dataset.series_id;
                const scopedUrl = addButton.dataset.scoped_url;
                const confirmMessage = addButton.dataset.confirm;
                if (confirmMessage && !confirm(confirmMessage)) {
                    return;
                }

                addButton.classList.add("hidden");
                const row = addButton.parentElement.closest("tr").cloneNode(true);
                row.classList.add("new");
                row.getElementsByTagName("td")[0].innerHTML = "<div class='drag-handle'><i class='mdi mdi-reorder-horizontal mdi-18'></i></div>";
                row.querySelector("td.link").querySelector("span.ellipsis-overflow").innerHTML = `<a target='_blank' href='${scopedUrl}'>${activityName}</a>`;
                row.querySelector("td.popularity-icon").remove();
                row.querySelector("td.actions").innerHTML = `<a href='#' class='btn btn-icon remove-activity' data-activity_id='${activityId}' data-activity_name='${activityName}' data-series_id='${seriesId}'><i class='mdi mdi-delete'></i></a>`;
                document.querySelector(".series-activity-list tbody").append(row);
                row.classList.remove("new");
                row.classList.add("pending");
                fetch("/series/" + seriesId + "/add_activity.js", {
                    method: "POST",
                    body: JSON.stringify({ activity_id: activityId }),
                    headers: { "Content-type": "application/json" },
                })
                    .then( response => {
                        if (response.ok) {
                            const noActivities = document.querySelector("#no-activities");
                            if (noActivities) {
                                noActivities.remove();
                            }
                            activityAdded(row);
                        } else {
                            addingActivityFailed(row, addButton);
                        }
                    });
            });
        });
    }

    function initRemoveButtons(): void {
        document.querySelectorAll("a.remove-activity").forEach( b => {
            b.addEventListener("click", e => {
                removeActivity(e);
            });
        });
    }

    function removeActivity(e: Event): void {
        // prevent automatic scrolling to top of the page
        e.preventDefault();

        const removeButton = e.currentTarget as HTMLButtonElement;
        const activityId = removeButton.dataset.activity_id;
        const seriesId = removeButton.dataset.series_id;
        const row = removeButton.parentElement.closest("tr");

        removeButton.classList.add("hidden");
        row.classList.add("pending");
        fetch("/series/" + seriesId + "/remove_activity.js", {
            method: "POST",
            body: JSON.stringify({ activity_id: activityId }),
            headers: { "Content-type": "application/json" },
        })
            .then( response => {
                if (response.ok) {
                    activityRemoved(row);
                } else {
                    removingActivityFailed(row, removeButton);
                }
            });
    }

    function activityAdded(row: HTMLTableRowElement): void {
        new Toast(I18n.t("js.activity-added-success"));
        row.querySelector("a.remove-activity").addEventListener("click", e => {
            removeActivity(e);
        });
        row.classList.remove("pending");
    }

    function addingActivityFailed(row: HTMLTableRowElement, addButton: HTMLButtonElement): void {
        new Toast(I18n.t("js.activity-added-failed"));
        row.classList.add("new");
        row.classList.remove("pending");
        addButton.classList.remove("hidden");
        setTimeout( () => {
            row.remove();
        }, 500);
    }

    function activityRemoved(row: HTMLTableRowElement): void {
        row.classList.add("new");
        row.classList.remove("pending");
        setTimeout( () => {
            row.remove();
        }, 500);
        new Toast(I18n.t("js.activity-removed-success"));
        const addButton = document.querySelector(`a.add-activity[data-activity_id="${(row.querySelector("a.remove-activity") as HTMLElement).dataset.activity_id}"`);
        if (addButton) {
            addButton.classList.remove("hidden");
        }
    }

    function removingActivityFailed(row: HTMLTableRowElement, removeButton: HTMLButtonElement): void {
        row.classList.remove("pending");
        removeButton.classList.remove("hidden");
        new Toast(I18n.t("js.activity-removed-failed"));
    }

    init();
}

function initSeriesShow(id: string): void {
    const graphMapping = {
        violin: ViolinGraph,
        stacked: StackedStatusGraph,
        timeseries: TimeseriesGraph,
        ctimeseries: CTimeseriesGraph
    };
    document.querySelectorAll(`#series-view-${id} .btn.graph-toggle`).forEach(btn => {
        btn.addEventListener("shown.bs.tab", e => {
            const type = e.target.dataset.type;
            const seriesId = e.target.dataset.seriesId;

            const graph = new (graphMapping[type])(seriesId, `#stats-container-${seriesId}`);
            document.getElementById(`daterange-${seriesId}`).hidden = true;
            graph.init();

            const card = document.getElementById(`series-card-${seriesId}`);
            card.querySelector(".graph-title span").textContent = I18n.t(`js.${type}_title`);
            const info = card.querySelector(".graph-info");
            info.setAttribute("title", I18n.t(`js.${type}_desc`));
            new window.bootstrap.Tooltip(info);
        });
    });
}

export { initDatePicker as initDeadlinePicker, initSeriesEdit, initSeriesShow };
