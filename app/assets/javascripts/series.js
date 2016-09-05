function init_series_edit() {

    function init() {
        initAddButtons();
        initRemoveButtons();
        // export function
        dodona.seriesEditExercisesLoaded = initAddButtons;
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            var exerciseId = $(this).data("exercise_id");
            var exerciseName = $(this).data("exercise_name");
            var seriesId = $(this).data("series_id");
            var $row = $("<div class='col-xs-12 row exercise new'><div class='col-xs-10'><a href='/exercises/" + exerciseId + "'>" + exerciseName + "</a></div><div class='actions col-xs-2'><a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + exerciseId + "' data-exercise_name='" + exerciseName + "' data-series_id='" + seriesId + "'><span class='glyphicon glyphicon-trash'></span></a></div></div>");
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
