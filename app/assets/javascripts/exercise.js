/* globals Bloodhound,Strip,MathJax,ace,ga,initStrip */
import { logToGoogle } from "util.js";
import { Notification } from "./notification";

function initLabelsEdit(labels, undeletableLabels) {
    const colorMap = {};
    for (const label of labels) {
        colorMap[label.name] = label.color;
        label.value = label.name;
    }

    const engine = new Bloodhound({
        local: labels,
        identify: d => d.id,
        datumTokenizer: d => {
            const result = Bloodhound.tokenizers.whitespace(d.name);
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
    const images = [];
    $(".exercise-description img, a.dodona-lightbox").each(function () {
        const imagesrc = $(this).data("large") || $(this).attr("src") || $(this).attr("href");
        const altText = $(this).data("caption") || $(this).attr("alt") || imagesrc.split("/").pop();
        const imageObject = {
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
        // eslint-disable-next-line new-cap
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

function initExerciseDescription() {
    initLightboxes();
    centerImagesAndTables();
    initMathJax();
}


function initExerciseShow(exerciseId, programmingLanguage, loggedIn, editorShown, courseId, _deadline) {
    let editor;
    let lastSubmission;
    let lastTimeout;

    function init() {
        if (editorShown) {
            initEditor();
        }
        swapActionButtons();
        initDeadlineTimeout();

        // submit source code if button is clicked on editor panel
        $("#editor-process-btn").click(function () {
            if (!loggedIn) return;
            logToGoogle("submission", "submitted");
            // test submitted source code
            const source = editor.getValue();
            disableSubmitButton();
            submitSolution(source)
                .done(data => submissionSuccessful(data, $("#editor-process-btn").data("user_id")))
                .fail(submissionFailed);
        });

        $("#submission-copy-btn").click(function () {
            const submissionSource = ace.edit("editor-result").getValue();
            editor.setValue(submissionSource, 1);
            $("#exercise-handin-link").tab("show");
        });

        $("#exercise-handin-link").on("shown.bs.tab", function () {
            // refresh editor after show
            editor.resize(true);
        });

        // secure external links
        $(".exercise-description a[target='_blank']").each(function () {
            $(this).attr("rel", "noopener");
        });

        // export function
        window.dodona.feedbackLoaded = feedbackLoaded;
        window.dodona.feedbackTableLoaded = feedbackTableLoaded;
    }

    function initEditor() {
        // init editor
        editor = ace.edit("editor-text");
        editor.getSession().setMode("ace/mode/" + programmingLanguage);
        if (window.dodona.darkMode) {
            editor.setTheme("ace/theme/twilight");
        }
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

    function feedbackLoaded(submissionId) {
        ga("send", "pageview");
        $("#feedback").removeClass("hidden");
        const $exerciseFeedbackLink = $("#exercise-feedback-link");
        $exerciseFeedbackLink.removeClass("hidden");
        $exerciseFeedbackLink.tab("show");
        $exerciseFeedbackLink.attr("data-submission_id", submissionId);
    }

    function feedbackTableLoaded(userId, exerciseId, courseId) {
        $("a.load-submission").attr("data-remote", "true");
        if (lastSubmission) {
            const $submissionRow = $("#submission_" + lastSubmission);
            const status = $submissionRow.data("status");
            if (status === "queued" || status === "running") {
                setTimeout(function () {
                    lastTimeout = (lastTimeout || 0) + 1000;
                    lastTimeout = lastTimeout >= 5000 ? 4000 : lastTimeout;
                    ga("send", "pageview");
                    let url = `/submissions.js?user_id=${userId}&exercise_id=${exerciseId}`;
                    if (courseId !== undefined) {
                        url += `&course_id=${courseId}`;
                    }
                    $.get(url);
                }, (lastTimeout || 0) + 1000);
            } else {
                lastTimeout = 0;
                if ($("#exercise-submission-link").parent().hasClass("active")) {
                    $submissionRow.find(".load-submission").get(0).click();
                } else if ($("#exercise-feedback-link").parent().hasClass("active") &&
                    $("#exercise-feedback-link").data("submission_id") === lastSubmission) {
                    $.get(`/submissions/${lastSubmission}.js`);
                }
                setTimeout(enableSubmitButton, 100);
                new Notification(I18n.t("js.submission-processed"));
                lastSubmission = null;
            }
        }
    }

    function enableSubmitButton() {
        $("#editor-process-btn").prop("disabled", false).removeClass("busy mdi-timer-sand-empty mdi-spin").addClass("mdi-play");
    }

    function disableSubmitButton() {
        $("#editor-process-btn").prop("disabled", true).removeClass("mdi-play").addClass("busy mdi-timer-sand-empty mdi-spin");
    }

    function submissionSuccessful(data, userId) {
        lastSubmission = data.id;
        new Notification(I18n.t("js.submission-saved"));
        ga("send", "pageview");
        let url = `/submissions.js?user_id=${userId}&exercise_id=${data.exercise_id}`;
        if (data.course_id) {
            url += `&course_id=${data.course_id}`;
        }
        $.get(url);
        $("#exercise-submission-link").tab("show");
    }

    function submissionFailed(request) {
        let message;
        if (request.readyState === 0) {
            message = I18n.t("js.submission-network");
        } else if (request.status === 422) {
            try {
                const response = JSON.parse(request.responseText);
                const errors = response.errors;
                if (errors.code && errors.code[0] === "emoji found") {
                    message = I18n.t("js.submission-emoji");
                } else if (errors.submission && errors.submission[0] === "rate limited") {
                    message = I18n.t("js.submission-rate-limit");
                } else if (errors.code && errors.code[0] === "too long") {
                    message = I18n.t("js.submission-too-long");
                }
            } catch (e) {
                message = I18n.t("js.submission-failed");
            }
        }
        $("<div style=\"display:none\" class=\"alert alert-danger alert-dismissible\"> <button type=\"button\" class=\"close\" data-dismiss=\"alert\"><span>&times;</span></button>" + message + "</div>").insertBefore("#editor-window").show("fast");
        enableSubmitButton();
    }

    function initDeadlineTimeout() {
        if (!_deadline) {
            return;
        }
        const $deadlineWarning = $("#deadline-warning");
        const $deadlineInfo = $("#deadline-info");
        const deadline = new Date(_deadline);
        const infoDeadline = new Date(deadline - (5 * 60 * 1000));

        function showDeadlineAlerts() {
            if (deadline < new Date()) {
                $deadlineInfo.hide();
                $deadlineWarning.show();
            } else if (infoDeadline < new Date()) {
                $deadlineInfo.show();
                setTimeout(showDeadlineAlerts, Math.min(
                    Math.max(10, (deadline - new Date()) / 10),
                    10 * 60 * 1000));
            } else {
                setTimeout(showDeadlineAlerts, Math.min(
                    Math.max(10, (infoDeadline - new Date()) / 10),
                    10 * 60 * 1000));
            }
        }

        showDeadlineAlerts();
    }

    init();
}

export { initExerciseShow, initExerciseDescription, initLabelsEdit };
