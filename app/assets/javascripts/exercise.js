function init_exercise_show(tests) {
    // init editor
    var editor = ace.edit("editor-text");
    editor.getSession().setMode("ace/mode/javascript");
    editor.setOptions({
        showPrintMargin: false,
        enableBasicAutocompletion: true
    });
    editor.getSession().setUseWrapMode(true);
    editor.$blockScrolling = Infinity; // disable warning
    editor.gotoLine(2);
    editor.focus();

    // create feedback table
    var feedbackTable = new FeedbackTable(tests);

    // test source code if button is clicked on editor panel
    $("#editor-process-btn").click(function () {
        // test submitted source code
        feedbackTable.test({
            "source": editor.getValue()
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
