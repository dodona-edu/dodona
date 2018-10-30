/* globals Bloodhound,Strip,MathJax,ace,ga,I18n,initStrip */
import {showNotification} from "./notifications.js";

function initLabelsEdit(labels, undeletableLabels) {
    const colorMap = {};
    for (let label of labels) {
        colorMap[label.name] = label.color;
        label.value = label.name;
    }

    const engine = new Bloodhound({
        local: labels,
        identify: d => d.id,
        datumTokenizer: d => {
            let result = Bloodhound.tokenizers.whitespace(d.name);
            $.each(result, (i, val) => {
                for (let i = 1; i < val.length; i++) {
                    result.push(val.substr(i, val.length));
                }
            });
            return result;
        }, queryTokenizer: Bloodhound.tokenizers.whitespace,
    });

    const $field = $("#exercise_labels");
    $field.on("tokenfield:createdtoken", e => {
        if (colorMap[e.attrs.value]) {
            $(e.relatedTarget).addClass(`accent-${colorMap[e.attrs.value]}`);
        }
        if (undeletableLabels.includes(e.attrs.value)) {
            $(e.relatedTarget).addClass("tokenfield-undeletable");
            $(e.relatedTarget).prop("title", I18n.t("js.label-undeletable"));
        }
    });
    $field.on("tokenfield:removetoken", e => {
        if (undeletableLabels.includes(e.attrs.value)) {
            return false;
        }
    });
    $field.on("tokenfield:edittoken", e => {
        if (undeletableLabels.includes(e.attrs.value)) {
            return false;
        }
    });
    $field.tokenfield({
        beautify: false,
        createTokensOnBlur: true,
        typeahead: [{
            highlight: true,
        }, {
            source: engine,
            display: d => d.name,
        }],
    });
}

function initLightboxes() {
    initStrip();

    let index = 1;
    let images = [];
    $(".exercise-description img, a.dodona-lightbox").each(function () {
        let imagesrc = $(this).data("large") || $(this).attr("src") || $(this).attr("href");
        let altText = $(this).data("caption") || $(this).attr("alt") || imagesrc.split("/").pop();
        let imageObject = {
            url: imagesrc,
            caption: altText,
        };
        images.push(imageObject);

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

function initMathJax() {
    // configure MathJax if loaded
    if (typeof MathJax !== "undefined") {
        MathJax.Hub.Config({
            tex2jax: {
                inlineMath: [
                    ["$$", "$$"],
                    ["\\(", "\\)"],
                ],
                displayMath: [
                    ["\\[", "\\]"],
                ],
                ignoreClass: "feedback-table",
            },
        });
    }
}

function initExercisesReadonly() {
    initLightboxes();
    centerImagesAndTables();
    initMathJax();
}


function initExerciseShow(exerciseId, programmingLanguage, loggedIn, editorShown, courseId) {
    let editor;
    let lastSubmission;

    function init() {
        if (editorShown) {
            initEditor();
        }
        initExercisesReadonly();
        swapActionButtons();

        // submit source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            if (!loggedIn) return;
            // test submitted source code
            let source = editor.getValue();
            disableSubmitButton();
            submitSolution(source)
                .done(data => submissionSuccessful(data, $("#editor-process-btn").data("user_id")))
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

    function feedbackTableLoaded(userId) {
        $("a.load-submission").attr("data-remote", "true");
        if (lastSubmission) {
            let $submissionRow = $("#submission_" + lastSubmission);
            let status = $submissionRow.data("status");
            if (status == "queued" || status == "running") {
                setTimeout(function () {
                    ga("send", "pageview");
                    $.get(`submissions.js?user_id=${userId}`);
                }, 1000);
            } else {
                if ($("#exercise-submission-link").parent().hasClass("active")) {
                    $submissionRow.find(".load-submission").get(0).click();
                }
                setTimeout(enableSubmitButton, 100);
                showNotification(I18n.t("js.submission-processed"));
                lastSubmission = null;
            }
        }
    }

    function enableSubmitButton() {
        $("#editor-process-btn").prop("disabled", false).removeClass("busy");
        $("#editor-process-btn .material-icons").html("play_arrow");
    }

    function disableSubmitButton() {
        $("#editor-process-btn").prop("disabled", true).addClass("busy");
        $("#editor-process-btn .material-icons").html("hourglass_empty");
    }

    function submissionSuccessful(data, userId) {
        lastSubmission = data.id;
        showNotification(I18n.t("js.submission-saved"));
        ga("send", "pageview");
        $.get(`submissions.js?user_id=${userId}`);
        $("#exercise-submission-link").tab("show");
    }

    function submissionFailed(request) {
        let message = I18n.t("js.submission-failed");
        if (request.status === 422) {
            try {
                let response = JSON.parse(request.responseText);
                let errors = response.errors;
                if (errors.code && errors.code[0] === "emoji found") {
                    message = I18n.t("js.submission-emoji");
                } else if (errors.submission && errors.submission[0] === "rate limited") {
                    message = I18n.t("js.submission-rate-limit");
                }
            } catch (e) {
            }
        }
        $("<div style=\"display:none\" class=\"alert alert-danger alert-dismissible\"> <button type=\"button\" class=\"close\" data-dismiss=\"alert\"><span>&times;</span></button>" + message + "</div>").insertBefore("#editor-window").show("fast");
        enableSubmitButton();
    }

    init();
}

export {initExerciseShow, initExercisesReadonly, initLabelsEdit};
