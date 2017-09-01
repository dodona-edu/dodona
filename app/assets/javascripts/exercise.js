import {showNotification} from "./notifications.js";

function initExerciseShow(exerciseId, programmingLanguage, loggedIn, editorShown, courseId) {
    let editor;
    let lastSubmission;

    function init() {
        if (editorShown) {
            initEditor();
        }
        initLightboxes();

        centerImagesAndTables();
        swapActionButtons();

        // submit source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            if (!loggedIn) return;
            // test submitted source code
            let source = editor.getValue();
            disableSubmitButton();
            submitSolution(source)
                .done(submissionSuccessful)
                .fail(submissionFailed);
        });

        $("#submission-copy-btn").click(function () {
            let submissionSource = ace.edit("editor-result").getValue();
            editor.setValue(submissionSource, 1);
            $("#exercise-handin-link").tab("show");
        });

        $("#exercise-handin-link").on("shown.bs.tab", function () {
            // refresh editor after show
            editor.resize(true);
        });

        // configure mathjax
        MathJax.Hub.Config({
            tex2jax: {
                inlineMath: [
                    ["$$", "$$"],
                    ["\\(", "\\)"],
                ],
                displayMath: [
                    ["\\[", "\\]"],
                ],
            },
        });

        // export function
        window.dodona.feedbackLoaded = feedbackLoaded;
        window.dodona.feedbackTableLoaded = feedbackTableLoaded;
    }

    function initEditor() {
        // init editor
        editor = ace.edit("editor-text");
        editor.getSession().setMode("ace/mode/" + programmingLanguage);
        editor.setOptions({
            showPrintMargin: false,
            enableBasicAutocompletion: true,
        });
        editor.getSession().setUseWrapMode(true);
        editor.$blockScrolling = Infinity; // disable warning
        editor.focus();
        editor.on("focus", enableSubmitButton);
    }

    function initLightboxes() {
        initStrip();

        let index = 1;
        let images = [];
        $(".exercise-description img, a.dodona-lightbox").each(function () {
            let imagesrc = $(this).data("large") || $(this).attr("src") || $(this).attr("href");
            let altText = $(this).data("caption") || $(this).attr("alt") || imagesrc.split("/").pop();
            let image_object = {
                url: imagesrc,
                caption: altText,
            };
            images.push(image_object);

            $(this).data("image_index", index++);
        });

        $(".exercise-description img, a.dodona-lightbox").click(function () {
            Strip.show(images, {
                side: "top",
            }, $(this).data("image_index"));
            return false;
        });
    }

    function centerImagesAndTables() {
        $(".exercise-description p > img").parent().wrapInner("<center></center>");
        $(".exercise-description > table").wrap("<center></center>");
        $(".exercise-description > iframe").wrap("<center></center>");
    }

    function swapActionButtons() {
        $("#exercise-handin-link").on("show.bs.tab", function (e) {
            $("#submission-copy-btn").addClass("hidden-fab");
            $("#editor-process-btn").removeClass("hidden-fab");
        });
        $("#exercise-submission-link").on("show.bs.tab", function (e) {
            $("#submission-copy-btn").addClass("hidden-fab");
            if (lastSubmission) {
                $("#editor-process-btn").removeClass("hidden-fab");
            } else {
                $("#editor-process-btn").addClass("hidden-fab");
            }
        });
        $("#exercise-feedback-link").on("show.bs.tab", function (e) {
            $("#editor-process-btn").addClass("hidden-fab");
            $("#submission-copy-btn").removeClass("hidden-fab");
        });
    }

    function submitSolution(code) {
        ga("send", "pageview");
        return $.post("/submissions.json", {
            submission: {
                code: code,
                exercise_id: exerciseId,
                course_id: courseId,
            },
        });
    }

    function feedbackLoaded() {
        ga("send", "pageview");
        $("#feedback").removeClass("hidden");
        $("#exercise-feedback-link").removeClass("hidden");
        $("#exercise-feedback-link").tab("show");
    }

    function feedbackTableLoaded() {
        $("a.load-submission").attr("data-remote", "true");
        if (lastSubmission) {
            let $submissionRow = $("#submission_" + lastSubmission);
            let status = $submissionRow.data("status");
            if (status == "queued" || status == "running") {
                setTimeout(function () {
                    ga("send", "pageview");
                    $.get("submissions.js");
                }, 1000);
            } else {
                if ($("#exercise-submission-link").parent().hasClass("active")) {
                    $submissionRow.find(".load-submission").click();
                }
                setTimeout(enableSubmitButton, 100);
                showNotification(I18n.t("js.submission-processed"));
                lastSubmission = null;
            }
        }
    }

    function enableSubmitButton() {
        $("#editor-process-btn").prop("disabled", false).removeClass("busy");
        $("#editor-process-btn .glyphicon").removeClass("glyphicon-hourglass").addClass("glyphicon-play");
    }

    function disableSubmitButton() {
        $("#editor-process-btn").prop("disabled", true).addClass("busy");
        $("#editor-process-btn .glyphicon").removeClass("glyphicon-play").addClass("glyphicon-hourglass");
    }

    function submissionSuccessful(data) {
        lastSubmission = data.id;
        showNotification(I18n.t("js.submission-saved"));
        ga("send", "pageview");
        $.get("submissions.js");
        $("#exercise-submission-link").tab("show");
    }

    function submissionFailed(request) {
        let message = I18n.t("js.submission-failed");
        if (request.status === 422) {
            try {
                let response = JSON.parse(request.responseText);
                if (response.errors.code[0] === "emoji found") {
                    message = I18n.t("js.submission-emoji");
                }
            } catch (e) {}
        }
        $("<div style=\"display:none\" class=\"alert alert-danger alert-dismissible\"> <button type=\"button\" class=\"close\" data-dismiss=\"alert\"><span>&times;</span></button>" + message + "</div>").insertBefore("#editor-window").show("fast");
        enableSubmitButton();
    }

    init();
}

export {initExerciseShow};
