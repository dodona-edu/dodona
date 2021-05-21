import flatpickr from "flatpickr";
import { Dutch } from "flatpickr/dist/l10n/nl.js";

import { Toast } from "./toast";
import { initDragAndDrop } from "./drag_and_drop.js";
import { initTokenClickables } from "./util.js";

const DRAG_AND_DROP_ARGS = {
    table_selector: ".series-activity-list tbody",
    item_selector: ".series-activity-list a.remove-activity",
    item_data_selector: "series_id",
    order_selector: ".series-activity-list a.remove-activity",
    order_data_selector: "activity_id",
    url_from_id: function (seriesId) {
        return `/series/${seriesId}/reorder_activities.js`;
    },
};

function initSeriesEdit() {
    function init() {
        initAddButtons();
        initTokenClickables();
        initRemoveButtons();
        initDragAndDrop(DRAG_AND_DROP_ARGS);
        // export function
        dodona.seriesEditActivitiesLoaded = () => {
            initAddButtons();
            initTokenClickables();
        };
    }

    function initAddButtons() {
        $("a.add-activity").click(function () {
            const $addButton = $(this);
            const activityId = $addButton.data("activity_id");
            const activityName = $addButton.data("activity_name");
            const seriesId = $addButton.data("series_id");
            const scopedUrl = $addButton.data("scoped_url");
            const confirmMessage = $addButton.data("confirm");
            if (confirmMessage && !confirm(confirmMessage)) {
                return false;
            }
            const $row = $addButton.parents("tr").clone();
            $row.addClass("new");
            $row.children("td:first").html("<div class='drag-handle'><i class='mdi mdi-reorder-horizontal mdi-18'></i></div>");
            $row.children("td.link").children("span.ellipsis-overflow").html(`<a target='_blank' href='${scopedUrl}'>${activityName}</a>`);
            $row.children("td.actions").html(`<a href='#' class='btn btn-icon remove-activity' data-activity_id='${activityId}' data-activity_name='${activityName}' data-series_id='${seriesId}'><i class='mdi mdi-delete mdi-18'></i></a>`);
            $(".series-activity-list tbody").append($row);
            $row.css("opacity"); // trigger paint
            $row.removeClass("new").addClass("pending");
            $.post("/series/" + seriesId + "/add_activity.js", {
                activity_id: activityId,
            })
                .done(function () {
                    $("#no-activities").remove();
                    activityAdded($row, $addButton);
                })
                .fail(function () {
                    addingActivityFailed($row);
                });
            return false;
        });
    }

    function initRemoveButtons() {
        $("a.remove-activity").click(removeActivity);
    }

    function removeActivity() {
        const activityId = $(this).data("activity_id");
        const seriesId = $(this).data("series_id");
        const $row = $(this).parents("tr").addClass("pending");
        $.post("/series/" + seriesId + "/remove_activity.js", {
            activity_id: activityId,
        })
            .done(function () {
                activityRemoved($row);
            })
            .fail(function () {
                removingActivityFailed($row);
            });
        return false;
    }

    function activityAdded($row, $addButton) {
        new Toast(I18n.t("js.activity-added-success"));
        $row.find("a.remove-activity").click(removeActivity);
        $row.removeClass("pending");
        $addButton.addClass("hidden");
    }

    function addingActivityFailed($row) {
        new Toast(I18n.t("js.activity-added-failed"));
        $row.addClass("new").removeClass("pending");
        setTimeout(function () {
            $row.remove();
        }, 500);
    }

    function activityRemoved($row) {
        $row.addClass("new").removeClass("pending");
        setTimeout(function () {
            $row.remove();
        }, 500);
        new Toast(I18n.t("js.activity-removed-success"));
        $(`a.add-activity[data-activity_id="${$row.find("a.remove-activity").data("activity_id")}"]`).removeClass("hidden");
    }

    function removingActivityFailed($row) {
        $row.removeClass("pending");
        new Toast(I18n.t("js.activity-removed-failed"));
    }

    init();
}

function initDeadlinePicker(selector) {
    function init() {
        const options = {};
        if (I18n.locale === "nl") {
            options.locale = Dutch;
        }
        flatpickr(selector, options);
    }

    init();
}

export { initSeriesEdit, initDeadlinePicker };
