import {showInfoModal} from "./modal.js";
import {logToGoogle} from "./util.js";

function initPythiaSubmissionShow(submissionCode) {
    function init() {
        initTutorLinks();
        initFileViewers();
        if ($(".tutormodal").length == 1) {
            initFullScreen();
        } else {
            $(".tutormodal:last").remove();
        }
    }

    function initTutorLinks() {
        // add disabled to tutorlinks that are not valid
        $(".tutorlink").each(function () {
            let $group = $(this).parents(".group");
            if (!($group.data("statements") || $group.data("stdin"))) {
                $(this).remove();
            }
        });

        $(".tutorlink").click(function () {
            logToGoogle("tutor", "start", document.title);
            let exercise_id = $(".feedback-table").data("exercise_id");
            let $group = $(this).parents(".group");
            let stdin = $group.data("stdin").slice(0, -1);
            let statements = $group.data("statements");
            let files = {"inline": {}, "href": {}};

            $group.find(".contains-file").each(function () {
                let content = $(this).data("files");

                for (let key in content) {
                    let value = content[key];
                    files[value["location"]][value["name"]] = value["content"];
                }
            });

            loadTutor(exercise_id, submissionCode, statements, stdin, files["inline"], files["href"]);
            return false;
        });
    }

    function initFileViewers() {
        $("a.file-link").click(function () {
            let fileName = $(this).text();
            let $tc = $(this).parents(".testcase.contains-file");
            if ($tc.length === 0) return;
            let file = $tc.data("files")[fileName];
            if (file.location === "inline") {
                showInlineFile(fileName, file.content);
            } else if (file.location === "href") {
                showRealFile(fileName, file.content);
            }
            return false;
        });
    }

    function showInlineFile(name, content) {
        showInfoModal(name, "<div class='code'>" + content + "</div>");
    }

    function showRealFile(name, path) {
        let random = Math.floor((Math.random() * 10000) + 1);
        showInfoModal(name + " <a href='" + path + "' title='Download' download><i class='material-icons'>save_alt</i></a>", "<div class='code' id='file-" + random + "'>Loading...</div>");
        $.get(path, function (data) {
            let lines = data.split("\n");
            let maxLines = 200;
            if (lines.length > maxLines) {
                data = lines.slice(0, maxLines).join("\n") + "\n...";
            }
            $("#file-" + random).html(data);
        });
    }

    function initFullScreen() {
        $(document).bind(fullScreenApi.fullScreenEventName, resizeFullScreen);

        $("#tutor #fullscreen-button").click(function () {
            let elem = $("#tutor").get(0);
            if (fullScreenApi.isFullScreen()) {
                fullScreenApi.cancelFullScreen(elem);
            } else {
                fullScreenApi.requestFullScreen(elem);
            }
        });
    }

    function resizeFullScreen() {
        let $tutor = $("#tutor");
        if (!fullScreenApi.isFullScreen()) {
            $tutor.removeClass("fullscreen");
            $("#tutorviz").height($("#tutorviz").data("standardheight"));
        } else {
            $tutor.addClass("fullscreen");
            $("#tutorviz").height("100%");
        }
    }

    function loadTutor(exercise_id, studentCode, statements, stdin, inlineFiles, hrefFiles) {
        let lines = studentCode.split("\n");
        // find and remove main
        let i = 0;
        let remove = false;
        let source_array = [];
        while (i < lines.length) {
            if (remove && !(lines[i].match(/^\s+.*/g))) {
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

        let source_code = source_array.join("\n");

        $.ajax({
            type: "POST",
            url: "https://naos.ugent.be/tutor/cgi-bin/build_trace.py",
            dataType: "json",
            data: {
                exercise_id: exercise_id,
                code: source_code,
                input: JSON.stringify(stdin.split("\n")),
                inlineFiles: JSON.stringify(inlineFiles),
                hrefFiles: JSON.stringify(hrefFiles),
            },
            success: function (data) {
                createTutor(data);
            },
            error: function (data) {
                $("<div style=\"display:none\" class=\"alert alert-danger alert-dismissible\"> <button type=\"button\" class=\"close\" data-dismiss=\"alert\"><span>&times;</span></button>" + I18n.t("js.tutor-failed") + "</div>").insertBefore(".feedback-table").show("fast");
            },
        });

        const createTutor = function (codeTrace) {
            showInfoModal("Python Tutor", "<div id=\"tutorcontent\"><div class=\"progress\"><div class=\"progress-bar progress-bar-striped progress-bar-info active\" role=\"progressbar\" style=\"width: 100%\">Loading</div></div></div>", {"allowFullscreen": true});

            $("#tutor #info-modal").on("shown.bs.modal", function (e) {
                $("#tutorcontent").html("<iframe id=\"tutorviz\" width=\"100%\" frameBorder=\"0\" src=\"/tutorviz/tutorviz.html\"></iframe>");
                $("#tutorviz").on("load", function () {
                    let content = $("#tutorviz").get(0).contentWindow;
                    content.load(codeTrace);
                    $("#tutorviz").data("standardheight", content.document.body.scrollHeight);
                    $("#tutorviz").height($("#tutorviz").data("standardheight"));
                });
            });

            $("#tutor #info-modal").on("hidden.bs.modal", function () {
                if (fullScreenApi.isFullScreen()) {
                    let $tutor = $("#tutor");
                    let elem = $tutor.get(0);
                    fullScreenApi.cancelFullScreen(elem);
                }
            });
        };
    }

    init();
}

export {initPythiaSubmissionShow};
