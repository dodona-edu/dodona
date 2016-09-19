function init_series_edit() {

    function init() {
        initAddButtons();
        initRemoveButtons();
        initDragAndDrop();
        // export function
        dodona.seriesEditExercisesLoaded = initAddButtons;
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            var exerciseId = $(this).data("exercise_id");
            var exerciseName = $(this).data("exercise_name");
            var seriesId = $(this).data("series_id");
            var $row = $("<div class='col-xs-12 row exercise new'><div class='col-xs-1 drag-handle'><span class='glyphicon glyphicon-align-justify'></span></div><div class='col-xs-9'><a href='/exercises/" + exerciseId + "'>" + exerciseName + "</a></div><div class='actions col-xs-2'><a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + exerciseId + "' data-exercise_name='" + exerciseName + "' data-series_id='" + seriesId + "'><span class='glyphicon glyphicon-trash'></span></a></div></div>");
            $(".series-exercise-list").append($row);
            $row.css("opacity"); // trigger paint
            $row.removeClass("new").addClass("pending");
            $.post("/series/" + seriesId + "/add_exercise.js", {
                    exercise_id: exerciseId
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
                return $(handle).hasClass("drag-handle") || $(handle).parents('.drag-handle').length;
            }
        }).on("drop", function () {
            var seriesId = $(".series-exercise-list a.remove-exercise").data("series_id");
            var order = $(".series-exercise-list a.remove-exercise").map(function () {
                return $(this).data("exercise_id");
            }).get();
            $.post("/series/" + seriesId + "/reorder_exercises.js", {
                order: JSON.stringify(order)
            });
        });
    }

    function removeExercise() {
        var exerciseId = $(this).data("exercise_id");
        var exerciseName = $(this).data("exercise_name");
        var seriesId = $(this).data("series_id");
        var $row = $(this).parents("div.exercise").addClass("pending");
        $.post("/series/" + seriesId + "/remove_exercise.js", {
                exercise_id: exerciseId
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
        $(".pagination .active a").click();
    }

    function removingExerciseFailed($row) {
        $row.removeClass("pending");
        showNotification(I18n.t("js.exercise-removed-failed"));
    }

    init();
}
function init_series_form() {

    function init() {
        if (I18n.locale === "nl") {
            Flatpickr = Flatpickr||{l10n: {}};

            Flatpickr.l10n.weekdays = {
                shorthand: ['Zo', 'Ma', 'Di', 'Wo', 'Do', 'Vr', 'Za'],
                longhand: ['Zondag', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrijdag', 'Zaterdag']
            };

            Flatpickr.l10n.months = {
                shorthand: ['Jan', 'Feb', 'Maa', 'Apr', 'Mei', 'Jun', 'Jul', 'Aug', 'Sept', 'Okt', 'Nov', 'Dec'],
                longhand: ['Januari', 'Februari', 'Maart', 'April', 'Mei', 'Juni', 'Juli', 'Augustus', 'September', 'Oktober', 'November', 'December']
            };

            Flatpickr.l10n.firstDayOfWeek = 1;

            Flatpickr.l10n.ordinal = nth => {
                if (nth === 1 || nth === 8 || nth >= 20) {
                    return "ste";
                }

                return "de";
            };
        }
        $("#deadline-group").flatpickr();
    }

    init();
}
