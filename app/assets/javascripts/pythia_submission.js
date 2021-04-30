/* globals fullScreenApi */
import { showInfoModal } from "./modal.js";
import { logToGoogle } from "./util.js";

function initPythiaSubmissionShow(submissionCode, activityPath) {
    function init() {
        initTutorLinks();
        initFileViewers(activityPath);
        if ($(".tutormodal").length == 1) {
            initFullScreen();
        } else {
            $(".tutormodal:last").remove();
        }
    }

    function initTutorLinks() {
        // add disabled to tutorlinks that are not valid
        $(".tutorlink").each(function () {
            const $group = $(this).parents(".group");
            if (!($group.data("statements") || $group.data("stdin"))) {
                $(this).remove();
            }
        });

        $(".tutorlink").click(function () {
            logToGoogle("tutor", "start", document.title);
            const exerciseId = $(".feedback-table").data("exercise_id");
            const $group = $(this).parents(".group");
            const stdin = $group.data("stdin").slice(0, -1);
            const statements = $group.data("statements");
            const files = { inline: {}, href: {} };

            $group.find(".contains-file").each(function () {
                const content = $(this).data("files");

                Object.values(content).forEach(value => {
                    files[value["location"]][value["name"]] = value["content"];
                });
            });

            loadTutor(
                exerciseId,
                submissionCode,
                statements,
                stdin,
                files["inline"],
                files["href"]
            );
            return false;
        });
    }

    function initFileViewers(activityPath) {
        $("a.file-link").click(function () {
            const fileName = $(this).text();
            const $tc = $(this).parents(".testcase.contains-file");
            if ($tc.length === 0) return;
            const file = $tc.data("files")[fileName];
            if (file.location === "inline") {
                showInlineFile(fileName, file.content);
            } else if (file.location === "href") {
                showRealFile(fileName, activityPath, file.content);
            }
            return false;
        });
    }

    function showInlineFile(name, content) {
        showInfoModal(name, "<div class='code'>" + content + "</div>");
    }

    function showRealFile(name, activityPath, filePath) {
        const path = activityPath + "/" + filePath;
        const random = Math.floor(Math.random() * 10000 + 1);
        showInfoModal(
            name +
            " <a href='" + path +
            "' title='Download' download><i class='mdi mdi-download'></i></a>",
            "<div class='code' id='file-" + random + "'>Loading...</div>"
        );
        $.get(path, function (data) {
            let lines = data.split("\n");
            const maxLines = 99;
            if (lines.length > maxLines) {
                lines = lines.slice(0, maxLines);
                lines.push("...");
            }

            const table = document.createElement("table");
            table.className = "external-file";
            for (let i = 0; i < lines.length; i++) {
                const tr = document.createElement("tr");

                const number = document.createElement("td");
                number.className = "line-nr";
                number.textContent = (i === maxLines) ? "": i + 1;
                tr.appendChild(number);

                const line = document.createElement("td");
                line.className = "line";
                // textContent is safe, html is not executed
                line.textContent = lines[i];
                tr.appendChild(line);
                table.appendChild(tr);
            }
            const fileView = document.getElementById(`file-${random}`);
            fileView.innerHTML = "";
            fileView.appendChild(table);
        });
    }

    function initFullScreen() {
        $(document).bind(fullScreenApi.fullScreenEventName, resizeFullScreen);

        $("#tutor #fullscreen-button").click(function () {
            const elem = $("#tutor").get(0);
            if (fullScreenApi.isFullScreen()) {
                fullScreenApi.cancelFullScreen(elem);
            } else {
                fullScreenApi.requestFullScreen(elem);
            }
        });
    }

    function resizeFullScreen() {
        const $tutor = $("#tutor");
        if (!fullScreenApi.isFullScreen()) {
            $tutor.removeClass("fullscreen");
            $("#tutorviz").height($("#tutorviz").data("standardheight"));
        } else {
            $tutor.addClass("fullscreen");
            $("#tutorviz").height("100%");
        }
    }

    function loadTutor(exerciseId, studentCode, statements, stdin, inlineFiles, hrefFiles) {
        const lines = studentCode.split("\n");
        // find and remove main
        let i = 0;
        let remove = false;
        const sourceArray = [];
        while (i < lines.length) {
            if (remove && !lines[i].match(/^\s+.*/g)) {
                remove = false;
            }
            if (lines[i].match(/if\s+__name__\s*==\s*(['"])__main__\s*\1:\s*/g)) {
                remove = true;
            }
            if (!remove) {
                sourceArray.push(lines[i]);
            }
            i += 1;
        }
        sourceArray.push(statements);

        const sourceCode = sourceArray.join("\n");

        $.ajax({
            type: "POST",
            url: "https://pandora.ugent.be/tutor/cgi-bin/build_trace.py",
            dataType: "json",
            data: {
                exercise_id: exerciseId,
                code: sourceCode,
                input: JSON.stringify(stdin.split("\n")),
                inlineFiles: JSON.stringify(inlineFiles),
                hrefFiles: JSON.stringify(hrefFiles),
            },
            success: function (data) {
                createTutor(data);
            },
            error: function (data) {
                $(
                    "<div style=\"display:none\" class=\"alert alert-danger alert-dismissible\"> <button type=\"button\" class=\"close\" data-dismiss=\"alert\"><span>&times;</span></button>" +
                    I18n.t("js.tutor-failed") +
                    "</div>"
                )
                    .insertBefore(".feedback-table")
                    .show("fast");
            },
        });

        const createTutor = function (codeTrace) {
            showInfoModal(
                "Python Tutor",
                "<div id=\"tutorcontent\"><div class=\"progress\"><div class=\"progress-bar progress-bar-striped progress-bar-info active\" role=\"progressbar\" style=\"width: 100%\">Loading</div></div></div>",
                { allowFullscreen: true }
            );

            $("#tutor #info-modal").on("shown.bs.modal", function (e) {
                $("#tutorcontent").html(
                    `<iframe id="tutorviz" width="100%" frameBorder="0" src="http://${window.dodona.sandboxHost}:3000/tutorviz/tutorviz.html"></iframe>`
                );
                $("#tutorviz").on("load", function () {
                    window.iFrameResize({ log: true, checkOrigin: false, onInit: frame => frame.iFrameResizer.sendMessage(codeTrace) }, "#tutorviz");
                    // const content = $("#tutorviz").get(0).contentWindow;
                    // content.load(codeTrace);
                    $("#tutorviz").data("standardheight", content.document.body.scrollHeight);
                    $("#tutorviz").height($("#tutorviz").data("standardheight"));
                });
            });

            $("#tutor #info-modal").on("hidden.bs.modal", function () {
                if (fullScreenApi.isFullScreen()) {
                    const $tutor = $("#tutor");
                    const elem = $tutor.get(0);
                    fullScreenApi.cancelFullScreen(elem);
                }
            });
        };
    }

    init();
}

export { initPythiaSubmissionShow };
