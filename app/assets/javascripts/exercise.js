function init_exercise_show(tests) {
    // create feedback table
    var feedbackTable = new FeedbackTable(tests);

    // test source code if button is clicked on editor panel
    $("#editor-process-btn").click(function () {
        // test submitted source code
        feedbackTable.test({
            "source": $("#editor-text").val()
        });
    });

    // hide/show correct test cases if button is clicked in menu on feedback
    // panel
    $("#feedback-menu-toggle-correct").click(function () {
        if ($("a", this).html() === "hide correct") {
            // hide correct test cases
            $("a", this).html("show correct");
            $(".AC").hide();
        } else {
            // show correct test cases
            $("a", this).html("hide correct");
            $(".AC").show();
        }
        $(this).dropdown('toggle');
        return false;
    });
}
