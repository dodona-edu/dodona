function init_exercise_show(tests) {
    var editor;

    function init() {
        initEditor();
        initLightboxes();

        centerImagesAndTables();

        // create feedback table
        var feedbackTable = new FeedbackTable(tests);
        $("#feedback-loading").hide();

        // test source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            // test submitted source code
            feedbackTable.test({
                "source": editor.getValue()
            });
            $('#exercise-feedback-link').tab('show');
        });

        MathJax.Hub.Typeset();

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

    function centerImagesAndTables() {
        $(".exercise-description p > img").parent().wrapInner("<center></center>");
        $(".exercise-description table").wrap("<center></center>");
    }

    init();
}
