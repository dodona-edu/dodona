/* globals Bloodhound,Strip,ace,ga,initStrip */
import { initTooltips, logToGoogle, updateURLParameter } from "util.js";
import { Toast } from "./toast";

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

function showLightbox(content) {
    Strip.show(content.images, {
        side: "top",
        onShow: function () {
            // There might have been math in the image captions, so ask
            // MathJax to search for new math (but only in the captions).
            window.MathJax.typeset([".strp-caption"]);
        }
    }, content.index);

    // Transfer focus back to the document body to allow the lightbox to be closed.
    // https://github.com/dodona-edu/dodona/issues/1759.
    document.body.focus();
}

function onFrameMessage(event) {
    if (event.message.type === "lightbox") {
        showLightbox(event.message.content);
    }
}

function initLightboxes() {
    let index = 1;
    const images = [];
    $(".activity-description img, a.dodona-lightbox").each(function () {
        const imagesrc = $(this).data("large") || $(this).attr("src") || $(this).attr("href");
        const altText = $(this).data("caption") || $(this).attr("alt") || imagesrc.split("/").pop();
        const imageObject = {
            url: imagesrc,
            caption: altText,
        };
        images.push(imageObject);

        $(this).data("image_index", index++);
    });

    $(".activity-description img, a.dodona-lightbox").click(function () {
        const index = $(this).data("image_index");
        window.parentIFrame.sendMessage({
            type: "lightbox",
            content: {
                images: images,
                index: index,
            }
        });
        return false;
    });
}

function centerImagesAndTables() {
    $(".activity-description p > img").parent().wrapInner("<center></center>");
    $(".activity-description > table").wrap("<center></center>");
    $(".activity-description > iframe").wrap("<center></center>");
}

function initMathJax() {
    // configure MathJax
    window.MathJax = {
        tex: {
            inlineMath: [
                ["$$", "$$"],
                ["\\(", "\\)"],
            ],
            displayMath: [
                ["\\[", "\\]"],
            ],
            autoload: {
                color: [],
                colorV2: ["color"]
            },
            packages: { "[+]": ["noerrors"] }
        },
        options: {
            ignoreHtmlClass: "feedback-table",
            processHtmlClass: "tex2jax_process|annotation user"
        },
        loader: {
            load: ["[tex]/noerrors"]
        }
    };
}

function initExerciseDescription() {
    initLightboxes();
    centerImagesAndTables();
}

function initExerciseShow(exerciseId, programmingLanguage, loggedIn, editorShown, courseId, _deadline) {
    let editor;
    let lastSubmission;
    let lastTimeout;

    function init() {
        if (editorShown) {
            initEditor();
            initDeadlineTimeout();
            enableSubmissionTableLinks();
            swapActionButtons();
        }
        initStrip();

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
            const codeString = dodona.codeListing.code;
            editor.setValue(codeString, 1);
            $("#activity-handin-link").tab("show");
        });

        $("#activity-handin-link").on("shown.bs.tab", function () {
            // refresh editor after show
            editor.resize(true);
        });

        // secure external links
        $(".activity-description a[target='_blank']").each(function () {
            $(this).attr("rel", "noopener");
        });

        // export function
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
        $("#activity-handin-link").on("show.bs.tab", function (e) {
            $("#submission-copy-btn").addClass("hidden-fab");
            $("#editor-process-btn").removeClass("hidden-fab");
        });
        $("#activity-submission-link").on("show.bs.tab", function (e) {
            $("#submission-copy-btn").addClass("hidden-fab");
            if (lastSubmission) {
                $("#editor-process-btn").removeClass("hidden-fab");
            } else {
                $("#editor-process-btn").addClass("hidden-fab");
            }
        });
        $("#activity-feedback-link").on("show.bs.tab", function (e) {
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
        const $exerciseFeedbackLink = $("#activity-feedback-link");
        $exerciseFeedbackLink.removeClass("hidden");
        $exerciseFeedbackLink.tab("show");
        $exerciseFeedbackLink.attr("data-submission_id", submissionId);
    }

    function loadFeedback(url, submissionId) {
        $("#submission-wrapper").html("<center><i class=\"mdi mdi-loading mdi-spin\"></i></center>");
        feedbackLoaded(submissionId);
        fetch(updateURLParameter(url, "format", "js"), {
            headers: {
                "accept": "text/javascript",
                "x-csrf-token": $("meta[name=\"csrf-token\"]").attr("content"),
                "x-requested-with": "XMLHttpRequest",
            },
            credentials: "same-origin",
        }).then(resp => Promise.all([resp.ok, resp.text()])).then(([ok, data]) => {
            if (ok) {
                $("#submission-wrapper").html(data);
                initTooltips();
            } else {
                $("#submission-wrapper").html(`<div class="alert alert-danger">${I18n.t("js.unknown-error-loading-feedback")}</div>`);
            }
        });
    }

    function enableSubmissionTableLinks() {
        $("a.load-submission").on("click", function (event) {
            if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
                return;
            }
            event.preventDefault();
            loadFeedback($(this).attr("href"), $(this).data("submission_id"));
        });
    }

    function feedbackTableLoaded(userId, exerciseId, courseId) {
        enableSubmissionTableLinks();
        if (lastSubmission) {
            const $submissionRow = $("#submission_" + lastSubmission);
            const status = $submissionRow.data("status");
            if (status === "queued" || status === "running") {
                setTimeout(function () {
                    lastTimeout = (lastTimeout || 0) + 1000;
                    lastTimeout = lastTimeout >= 5000 ? 4000 : lastTimeout;
                    ga("send", "pageview");
                    let url = `/submissions.js?user_id=${userId}&activity_id=${exerciseId}`;
                    if (courseId !== undefined) {
                        url += `&course_id=${courseId}`;
                    }
                    $.get(url);
                }, (lastTimeout || 0) + 1000);
            } else {
                lastTimeout = 0;
                if ($("#activity-submission-link").parent().hasClass("active")) {
                    $submissionRow.find(".load-submission").get(0).click();
                } else if ($("#activity-feedback-link").parent().hasClass("active") &&
                    $("#activity-feedback-link").data("submission_id") === lastSubmission) {
                    loadFeedback(`/submissions/${lastSubmission}`, lastSubmission);
                }
                setTimeout(enableSubmitButton, 100);
                new Toast(I18n.t("js.submission-processed"));
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
        new Toast(I18n.t("js.submission-saved"));
        ga("send", "pageview");
        let url = `/submissions.js?user_id=${userId}&activity_id=${data.exercise_id}`;
        if (data.course_id) {
            url += `&course_id=${data.course_id}`;
        }
        $.get(url);
        $("#activity-submission-link").tab("show");
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
                } else if (errors.exercise && errors.exercise[0] === "not permitted") {
                    message = I18n.t("js.submission-not-allowed");
                }
            } catch (e) {
                message = I18n.t("js.submission-failed");
            }
        }
        if (message === undefined) {
            message = I18n.t("js.submission-failed");
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

function afterResize(details) {
    /**
     * If the page is loaded with a hash (#), the browser scrolls to the element
     * with that id, but this happens before our iframe is loaded. After our
     * iframe content is loaded, we resize its element to fit the content. If
     * the item in the hash was below the iframe element, that item will
     * possibly have 'jumped' away because of this.
     *
     * This function is called after such a resize to re-trigger the scroll-to
     * behavior.
     */
    if (details.type === "init") {
        const hash = location.hash;
        location.hash = "#"; // some browsers only scroll after a change
        location.hash = hash;
    }
}

function onFrameScroll(position) {
    /**
     * The scroll position does not account for the navigation bar, which is always
     * visible. This will add the offset for the navigation bar.
     */
    const navHeight = document.querySelector("nav.dodona-navbar").offsetHeight;
    window.scrollTo(position.x, position.y - navHeight);
    return false;
}

export {
    initMathJax, initExerciseShow, initExerciseDescription, initLabelsEdit, afterResize,
    onFrameMessage, onFrameScroll
};
