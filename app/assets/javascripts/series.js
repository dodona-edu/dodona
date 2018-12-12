/* globals dodona,flatpickr,I18n */
import dragula from "dragula";
import flatpickr from "flatpickr";

import {showNotification} from "./notifications.ts";

function initSeriesEdit() {
    function init() {
        initAddButtons();
        initTokenClickables();
        initRemoveButtons();
        initDragAndDrop();
        // export function
        dodona.seriesEditExercisesLoaded = () => {
            initAddButtons();
            initTokenClickables();
        };
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            const exerciseId = $(this).data("exercise_id");
            const exerciseName = $(this).data("exercise_name");
            const seriesId = $(this).data("series_id");
            const confirmMessage = $(this).data("confirm");
            if (confirmMessage && !confirm(confirmMessage)) {
                return false;
            }
            const $row = $(this).parents("tr").clone();
            $row.addClass("new");
            $row.children("td:first").html("<div class='drag-handle'><i class='material-icons md-18'>reorder</i></div>");
            $row.children("td.actions").html("<a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + exerciseId + "' data-exercise_name='" + exerciseName + "' data-series_id='" + seriesId + "'><i class='material-icons md-18'>delete</i></a>");
            $(".series-exercise-list tbody").append($row);
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

    function initDragAndDrop() {
        const tableBody = $(".series-exercise-list tbody").get(0);
        dragula([tableBody], {
            moves: function (el, source, handle, sibling) {
                return $(handle).hasClass("drag-handle") || $(handle).parents(".drag-handle").length;
            },
            mirrorContainer: tableBody,
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
        let $row = $(this).parents("tr").addClass("pending");
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
