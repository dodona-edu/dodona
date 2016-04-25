function init_exercise_show(exerciseId, loggedIn, tests) {
    var editor;

    function init() {
        initEditor();
        initLightboxes();

        // create feedback table
        var feedbackTable = new FeedbackTable(tests);
        $("#feedback-loading").hide();

        // test source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            // test submitted source code
            var source = editor.getValue();
            feedbackTable.test({
                "source": source
            }).then(function (data) {
                var result = "";
                var status = "";
                if (loggedIn) {
                    if (data.status === "timeout") {
                        status = "timeout";
                        result = "timeout";
                    } else {
                        result = data.correct + " correct, " + data.wrong + " verkeerd";
                        status = data.wrong === 0 ? "correct" : "wrong";
                    }
                    submitSolution(source, result, status);
                }
            });
            $('#exercise-feedback-link').tab('show');
        });

        MathJax.Hub.Typeset();

        // hide/show correct test cases if button is clicked in menu on feedback
        // panel
        $("#feedback-menu-toggle-correct").click(function () {
            if ($("a", this).html() === "verberg correct") {
                // hide correct test cases
                $("a", this).html("toon correct");
                $(".AC").hide();
            } else {
                // show correct test cases
                $("a", this).html("verberg correct");
                $(".AC").show();
            }
            $(this).dropdown('toggle');
            return false;
        });
    }

    function initEditor() {
        // init editor
        editor = ace.edit("editor-text");
        editor.getSession().setMode("ace/mode/javascript");
        editor.setOptions({
            showPrintMargin: false,
            enableBasicAutocompletion: true
        });
        editor.getSession().setUseWrapMode(true);
        editor.$blockScrolling = Infinity; // disable warning
        editor.setValue("// voeg hier je oplossing in\n");
        editor.gotoLine(2);
        editor.focus();
    }

    function initLightboxes() {
        initStrip();
        $(".exercise-description img").click(function () {
            var imagesrc = $(this).attr('src');
            var alttext = $(this).attr('alt');
            alttext = alttext ? alttext : imagesrc.split("/").pop();
            Strip.show({
                url: imagesrc,
                caption: alttext,
                options: {
                    side: 'top',
                    maxHeight: 10
                },
            });
        });
    }

    function submitSolution(code, result, status) {
        $.post("/submissions.json", {
            submission: {
                code: code,
                result: result,
                status: status,
                exercise_id: exerciseId
            }
        });
    }

    init();
}
