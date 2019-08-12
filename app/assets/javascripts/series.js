/* globals flatpickr */

import { showNotification } from "./notifications.js";
import { initDragAndDrop } from "./drag_and_drop.js";

const DRAG_AND_DROP_ARGS = {
    table_selector: ".series-exercise-list tbody",
    item_selector: ".series-exercise-list a.remove-exercise",
    item_data_selector: "series_id",
    order_selector: ".series-exercise-list a.remove-exercise",
    order_data_selector: "exercise_id",
    url_from_id: function (seriesId) {
        return `/series/${seriesId}/reorder_exercises.js`;
    },
};

function initSeriesEdit() {
    function init() {
        initAddButtons();
        initTokenClickables();
        initRemoveButtons();
        initDragAndDrop(DRAG_AND_DROP_ARGS);
        // export function
        dodona.seriesEditExercisesLoaded = () => {
            initAddButtons();
            initTokenClickables();
        };
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            const $addButton = $(this);
            const exerciseId = $addButton.data("exercise_id");
            const exerciseName = $addButton.data("exercise_name");
            const seriesId = $addButton.data("series_id");
            const confirmMessage = $addButton.data("confirm");
            if (confirmMessage && !confirm(confirmMessage)) {
                return false;
            }
            const $row = $addButton.parents("tr").clone();
            $row.addClass("new");
            $row.children("td:first").html("<div class='drag-handle'><i class='mdi mdi-reorder-horizontal mdi-18'></i></div>");
            $row.children("td.actions").html("<a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + exerciseId + "' data-exercise_name='" + exerciseName + "' data-series_id='" + seriesId + "'><i class='mdi mdi-delete mdi-18'></i></a>");
            $(".series-exercise-list tbody").append($row);
            $row.css("opacity"); // trigger paint
            $row.removeClass("new").addClass("pending");
            $.post("/series/" + seriesId + "/add_exercise.js", {
                exercise_id: exerciseId,
            })
                .done(function () {
                    $("#no-exercises").remove();
                    exerciseAdded($row, $addButton);
                })
                .fail(function () {
                    addingExerciseFailed($row);
                });
            return false;
        });
    }

    function initTokenClickables() {
        const $clickableTokens = $(".clickable-token");
        $clickableTokens.off("click");
        $clickableTokens.click(function () {
            const $htmlElement = $(this);
            const type = $htmlElement.data("type");
            const name = $htmlElement.data("name");
            if (dodona.addTokenToSearch) {
                dodona.addTokenToSearch(type, name);
            }
        });
    }

    function initRemoveButtons() {
        $("a.remove-exercise").click(removeExercise);
    }

    function removeExercise() {
        const exerciseId = $(this).data("exercise_id");
        const seriesId = $(this).data("series_id");
        const $row = $(this).parents("tr").addClass("pending");
        $.post("/series/" + seriesId + "/remove_exercise.js", {
            exercise_id: exerciseId,
        })
            .done(function () {
                exerciseRemoved($row);
            })
            .fail(function () {
                removingExerciseFailed($row);
            });
        return false;
    }

    function exerciseAdded($row, $addButton) {
        showNotification(I18n.t("js.exercise-added-success"));
        $row.find("a.remove-exercise").click(removeExercise);
        $row.removeClass("pending");
        $addButton.addClass("hidden");
    }

    function addingExerciseFailed($row) {
        showNotification(I18n.t("js.exercise-added-failed"));
        $row.addClass("new").removeClass("pending");
        setTimeout(function () {
            $row.remove();
        }, 500);
    }

    function exerciseRemoved($row) {
        $row.addClass("new").removeClass("pending");
        setTimeout(function () {
            $row.remove();
        }, 500);
        showNotification(I18n.t("js.exercise-removed-success"));
        $(`a.add-exercise[data-exercise_id="${$row.find("a.remove-exercise").data("exercise_id")}"]`).removeClass("hidden");
    }

    function removingExerciseFailed($row) {
        $row.removeClass("pending");
        showNotification(I18n.t("js.exercise-removed-failed"));
    }

    init();
}

function initSeriesForm() {
    function init() {
        if (I18n.locale === "nl") {
            const Dutch = {
                weekdays: {
                    shorthand: ["zo", "ma", "di", "wo", "do", "vr", "za"],
                    longhand: ["zondag", "maandag", "dinsdag", "woensdag", "donderdag", "vrijdag", "zaterdag"],
                },
                months: {
                    shorthand: ["jan", "feb", "mrt", "apr", "mei", "jun", "jul", "aug", "sept", "okt", "nov", "dec"],
                    longhand: ["januari", "februari", "maart", "april", "mei", "juni", "juli", "augustus", "september", "oktober", "november", "december"],
                },
                firstDayOfWeek: 1,
                weekAbbreviation: "wk",
                rangeSeparator: " tot ",
                scrollTitle: "Scroll voor volgende / vorige",
                toggleTitle: "Klik om te wisselen",
                ordinal: function ordinal(nth) {
                    if (nth === 1 || nth === 8 || nth >= 20) return "ste";
                    return "de";
                },
            };
            flatpickr.localize(Dutch);
        }
        $("#deadline-group").flatpickr();
    }

    init();
}

export { initSeriesEdit, initSeriesForm };
