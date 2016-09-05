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
            $.post("/series/" + seriesId + "/add_exercise.js", {
                    exercise_id: exerciseId
                })
                .done(function () {
                    exerciseAdded(exerciseName, exerciseId, seriesId);
                })
                .fail(function () {
                    addingExerciseFailed(exerciseName, exerciseId);
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
        $.post("/series/" + seriesId + "/remove_exercise.js", {
                exercise_id: exerciseId
            })
            .done(function () {
                exerciseRemoved(exerciseName, exerciseId, seriesId);
            })
            .fail(function () {
                removingExerciseFailed(exerciseName, exerciseId);
            });
        $(this).parents("div.exercise").remove();
        return false;
    }

    function exerciseAdded(name, id, seriesId) {
        showNotification(I18n.t("js.exercise-added-success"));
        var $row = $("<div class='col-xs-12 row exercise'><div class='col-xs-10'><a href='/exercises/" + id + "'>" + name + "</a></div><div class='actions col-xs-2'><a href='#' class='btn btn-icon remove-exercise' data-exercise_id='" + id + "' data-exercise_name='" + name + "' data-series_id='" + seriesId +"'><span class='glyphicon glyphicon-trash'></span></a></div></div>");
        $(".series-exercise-list").append($row);
        $row.find("a.remove-exercise").click(removeExercise);
    }

    function addingExerciseFailed(name, id) {
        showNotification(I18n.t("js.exercise-added-failed"));
    }

    function exerciseRemoved(name, id, seriesId) {
        showNotification(I18n.t("js.exercise-removed-success"));
        $(".pagination .active a").click();
    }

    function removingExerciseFailed(name, id) {
        showNotification(I18n.t("js.exercise-removed-failed"));
    }

    init();
}
