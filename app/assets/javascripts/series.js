import dragula from "dragula";

import {showNotification} from "./notifications.js";

function initSeriesEdit() {
    function init() {
        initAddButtons();
        initRemoveButtons();
        initDragAndDrop();
        // export function
        dodona.seriesEditExercisesLoaded = initAddButtons;
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            let exerciseId = $(this).data("exercise_id");
            let exerciseName = $(this).data("exercise_name");
            let seriesId = $(this).data("series_id");
            let confirmMessage = $(this).data("confirm");
            if (confirmMessage && !confirm(confirmMessage)) {
                return false;
            }
            let $row = $("<div class='col-xs-12 row exercise new'><div class='col-xs-1 drag-handle'><i class='material-icons'>format-align-justify</i></div><div class='col-xs-9'><a href='/exercises/" + exerciseId + "'>" + exerciseName + "</a></div><div class='actions col-xs-2'><a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + exerciseId + "' data-exercise_name='" + exerciseName + "' data-series_id='" + seriesId + "'><i class='material-icons'>delete</i></a></div></div>");
            $(".series-exercise-list").append($row);
            $row.css("opacity"); // trigger paint
            $row.removeClass("new").addClass("pending");
            $.post("/series/" + seriesId + "/add_exercise.js", {
                exercise_id: exerciseId,
            })
                .done(function () {
                    exerciseAdded($row);
                })
                .fail(function () {
                    addingExerciseFailed($row);
                });
            $(this).remove();
            return false;
        });
    }

    function initRemoveButtons() {
        $("a.remove-exercise").click(removeExercise);
    }

    function initDragAndDrop() {
        dragula([$(".series-exercise-list").get(0)], {
            moves: function (el, source, handle, sibling) {
                return $(handle).hasClass("drag-handle") || $(handle).parents(".drag-handle").length;
            },
        }).on("drop", function () {
            let seriesId = $(".series-exercise-list a.remove-exercise").data("series_id");
            let order = $(".series-exercise-list a.remove-exercise").map(function () {
                return $(this).data("exercise_id");
            }).get();
            $.post("/series/" + seriesId + "/reorder_exercises.js", {
                order: JSON.stringify(order),
            });
        });
    }

    function removeExercise() {
        let exerciseId = $(this).data("exercise_id");
        let exerciseName = $(this).data("exercise_name");
        let seriesId = $(this).data("series_id");
        let $row = $(this).parents("div.exercise").addClass("pending");
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

    function exerciseAdded($row) {
        showNotification(I18n.t("js.exercise-added-success"));
        $row.find("a.remove-exercise").click(removeExercise);
        $row.removeClass("pending");
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
        $(".pagination .active a").get(0).click();
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
            let Dutch = {
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

export {initSeriesEdit, initSeriesForm};
