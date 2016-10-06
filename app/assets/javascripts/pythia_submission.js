function init_pythia_submission_show(submissionCode) {
    var vars;

    function init() {
        
        //add disabled to tutorlinks that are not valid
        $('.tutorlink').each(function() {
            var $element = $(this).parents(".group");
            if ($element.data('statements') === undefined && $element.data('stdin') == undefined) {
                $(this).addClass('disabled');
            }
        });

        $('.tutorlink').not('.disabled').click(function () {
            var $element = $(this).parents(".group");
            var stdin = $element.data('stdin').slice(0, -1);
            var statements = $element.data('statements');
            loadTutor(submissionCode, statements, JSON.stringify(stdin.split('\n')));
            return false;
        });


        $('#tutor .fullscreen').click(function() {
            return false; /* Disabled for now */
            var elem = document.getElementById("tutor");
            if (fullScreenApi.isFullScreen()) {
                fullScreenApi.cancelFullScreen(elem);
            } else {
                fullScreenApi.requestFullScreen(elem);
            }
        });
    }

    function loadTutor(studentCode, statements, stdin) {
        var lines = studentCode.split('\n');
        //find and remove main
        var i = 0;
        var remove = false;
        var source_array = [];
        while (i < lines.length) {
            if (remove && !(lines[i].match(/\s+.*/g))) {
                remove = false;
            }

            if (lines[i].match(/if\s+__name__\s*==\s*(['"])__main__\s*\1:\s*/g)) {
                remove = true;
            }
            if (!remove) {
                source_array.push(lines[i]);
            }
            i += 1;
        }

        source_array.push(statements);

        var source_code = source_array.join('\n');

        $.ajax({
            type: 'POST',
            url: '/tutor/cgi-bin/build_trace.py',
            dataType: 'json',
            data: {
                code: source_code,
                input: stdin
            },
            success: function (data) {
                createTutor(data);
            },
            error: function (data) {
                $('<div style="display:none" class="alert alert-danger alert-dismissible"> <button type="button" class="close" data-dismiss="alert"><span>&times;</span></button>' + I18n.t("js.tutor-failed") + '</div>').insertBefore(".feedback-table").show("fast");
            }
        });

        var createTutor = function (codeTrace) {
            showInfoModal("Python Tutor", '<div id="tutorcontent"><div class="progress"><div class="progress-bar progress-bar-striped progress-bar-info active" role="progressbar" aria-valuenow="45" aria-valuemin="0" aria-valuemax="100" style="width: 100%">Loading</div></div></div>');
            
            $("#tutor #info-modal").on("shown.bs.modal", function (e) {
                $("#tutorcontent").html('<iframe id="tutorviz" width="100%" frameBorder="0" src="/tutorviz/tutorviz.html"></iframe>');
                $('#tutorviz').load(function () {
                    var content = $("#tutorviz").get(0).contentWindow;
                    content.load(codeTrace);
                    $("#tutorviz").height(content.document.body.scrollHeight);
                });

            });
        };
    }

    init();
}
