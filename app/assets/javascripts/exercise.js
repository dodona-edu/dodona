function init_exercise_show(exerciseId, loggedIn) {
    var editor;

    function init() {
        initEditor();
        initLightboxes();

        centerImagesAndTables();

        // create feedback table
        $("#feedback-loading").hide();

        // test source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            // test submitted source code
            var source = editor.getValue();
            if (loggedIn) {
                submitSolution(source, "", "");
            }
            $('#exercise-feedback-link').tab('show');
        });

        // configure mathjax
        MathJax.Hub.Config({
          tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}
        });
        MathJax.Hub.Queue(function() {
            /* MathJax has not been run yet*/
            if ($('span.MathJax').length === 0) {
                MathJax.Hub.Queue(["Typeset",MathJax.Hub]);
            }
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

        var index = 1;
        var images = [];
        $(".exercise-description img").each(function() {
            var imagesrc = $(this).attr('src');
            var alttext = $(this).attr('alt');
            alttext = alttext ? alttext : imagesrc.split("/").pop();
            image_object = {
                url: imagesrc,
                caption: alttext
            }
            images.push(image_object)

            $(this).data('image_index', index++)

        });

        $(".exercise-description img").click(function () {
            Strip.show(images, {
                side: 'top'
            }, $(this).data('image_index'));
        });
    }

    function centerImagesAndTables() {
        $(".exercise-description p > img").parent().wrapInner("<center></center>");
        $(".exercise-description table").wrap("<center></center>");
        $(".exercise-description iframe").wrap("<center></center>");
    }

    function submitSolution(code, result, status) {
        $.post("/submissions.json", {
                submission: {
                    code: code,
                    result: result,
                    status: status,
                    exercise_id: exerciseId
                }
            }).done(function () {
                showNotification("Oplossing opgeslagen");
                $.get("submissions.js");
            })
            .fail(function () {
                $('<div style="display:none" class="alert alert-danger alert-dismissible"> <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button><strong>Opgepast!</strong> Er ging iets fout bij het opslaan van je oplossing. Herlaad de pagina, probeer opnieuw, of contacteer de assistent.</div>').insertAfter("#feedback-menu").show("fast");
            });
    }

    init();
}
