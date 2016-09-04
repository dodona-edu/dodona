function init_series_edit() {

    function init() {
        initAddButtons();
        // export function
        dodona.seriesEditExercisesLoaded = initAddButtons;
    }

    function initAddButtons() {
        $("a.add-exercise").click(function () {
            var exerciseId = $(this).data("exercise_id");
            var exerciseName = $(this).data("exercise_name")
            var seriesId = $(this).data("series_id");
            $.post("/series/" + seriesId + "/add_exercise.js", {
                    exercise_id: exerciseId
                })
                .done(function () {
                    exerciseAdded(exerciseName, exerciseId);
                })
                .fail(function () {
                    addingExerciseFailed(exerciseName, exerciseId);
                });
            return false;
        });
    }

    function exerciseAdded(name, id) {
        showNotification(I18n.t("js.exercise-added-success"));
        $(".series-exercise-list").append("<li>" + name + "</li>");
        $(".pagination .active a").click();
    }

    function addingExerciseFailed(name, id) {
        showNotification(I18n.t("js.exercise-added-failed"));

    }

    init();
}
