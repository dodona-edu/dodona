function init_series_edit() {

    function init() {
        initAddButtons();
        // export function
        dodona.seriesEditExercisesLoaded = initAddButtons;
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            $(this).remove();
            var exerciseId = $(this).data("exercise_id");
            var exerciseName = $(this).data("exercise_name")
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
            return false;
        });
    }

    function exerciseAdded(name, id, seriesId) {
        showNotification(I18n.t("js.exercise-added-success"));
        $(".series-exercise-list").append("<div class='col-xs-12 row exercise'><div class='col-xs-10'><a href='/exercises/" + id + "'>" + name + "</a></div><div class='actions col-xs-2'><a href='#' class='btn btn-icon' data-exercise_id='" + id + "' data-series_id='" + seriesId +"'><span class='glyphicon glyphicon-trash'></span></a></div></div>");
    }

    function addingExerciseFailed(name, id) {
        showNotification(I18n.t("js.exercise-added-failed"));

    }

    init();
}
