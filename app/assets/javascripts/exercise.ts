/* globals ace */
import { initTooltips, updateURLParameter } from "util.js";
import { Toast } from "./toast";
import GLightbox from "glightbox";

function showLightbox(content): void {
    const lightbox = new GLightbox(content);
    lightbox.on("slide_changed", () => {
        // There might have been math in the image captions, so ask
        // MathJax to search for new math (but only in the captions).
        window.MathJax.typeset([".gslide-description"]);
    });
    lightbox.open();

    // Transfer focus back to the document body to allow the lightbox to be closed.
    // https://github.com/dodona-edu/dodona/issues/1759.
    document.body.focus();
}

function onFrameMessage(event): void {
    if (event.message.type === "lightbox") {
        showLightbox(event.message.content);
    }
}

function initLightboxes(): void {
    let index = 0;
    const images = [];
    document.querySelectorAll<HTMLElement>(".activity-description img, a.dodona-lightbox").forEach(el => {
        const imagesrc = el.dataset.large || el.getAttribute("src") || el.getAttribute("href");
        const altText = el.dataset.caption || el.getAttribute("alt") || imagesrc.split("/").pop();
        const imageObject = {
            href: imagesrc,
            description: altText,
        };
        images.push(imageObject);

        el.dataset.image_index = index.toString();
        index++;
    });

    document.querySelectorAll<HTMLElement>(".activity-description img, a.dodona-lightbox").forEach(el => {
        el.addEventListener("click", () => {
            const index = parseInt(el.dataset.image_index, 10);
            window.parentIFrame.sendMessage({
                type: "lightbox",
                content: {
                    elements: images,
                    startAt: index,
                    moreLength: 0,
                }
            });
            return false;
        });
    });
}

function centerImagesAndTables(): void {
    new Set(Array.from(document.querySelectorAll<HTMLElement>(".activity-description p > img"), el => el.parentElement))
        .forEach(parent => {
            // create center element
            const center = document.createElement("center");
            // add all the images to the center element
            center.append(...parent.children);
            // set the center element as only child of parent
            parent.innerHTML = "";
            parent.appendChild(center);
        });
    document.querySelectorAll(".activity-description > table").forEach(el => {
        // create center element
        const center = document.createElement("center");
        // replace the current element with the new center element
        el.parentNode.replaceChild(center, el);
        // set the current element as child of the center element (aka center wraps around current element)
        center.appendChild(el);
    });
    document.querySelectorAll(".activity-description > iframe").forEach(el => {
        // create center element
        const center = document.createElement("center");
        // replace the current element with the new center element
        el.parentNode.replaceChild(center, el);
        // set the current element as child of the center element (aka center wraps around current element)
        center.appendChild(el);
    });
}

function initMathJax(): void {
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

function initExerciseDescription(): void {
    initLightboxes();
    centerImagesAndTables();
}

function initExerciseShow(exerciseId, programmingLanguage, loggedIn, editorShown, courseId, _deadline, baseSubmissionsUrl): void {
    let editor;
    let lastSubmission;
    let lastTimeout;

    function init(): void {
        if (editorShown) {
            initEditor();
            initDeadlineTimeout();
            enableSubmissionTableLinks();
            swapActionButtons();
        }

        // submit source code if button is clicked on editor panel
        document.getElementById("editor-process-btn")?.addEventListener("click", () => {
            if (!loggedIn) return;
            // test submitted source code
            const source = editor.getValue();
            disableSubmitButton();
            submitSolution(source)
                .then(async response => {
                    if (response.ok) {
                        submissionSuccessful(await response.json(), document.getElementById("editor-process-btn").dataset.user_id);
                    } else {
                        submissionFailed(response);
                    }
                });
        });

        document.getElementById("submission-copy-btn")?.addEventListener("click", () => {
            const codeString = dodona.codeListing.code;
            editor.setValue(codeString, 1);
            // eslint-disable-next-line no-undef
            bootstrap.Tab.getInstance(document.getElementById("activity-handin-link")).show();
        });

        document.getElementById("activity-handin-link")?.addEventListener("shown.bs.tab", () => {
            // refresh editor after show
            editor.resize(true);
        });

        // secure external links
        document.querySelectorAll(".activity-description a[target='_blank']").forEach(el => {
            el.setAttribute("rel", "noopener");
        });

        // export function
        window.dodona.feedbackTableLoaded = feedbackTableLoaded;
    }

    function initEditor(): void {
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
        editor.commands.removeCommand("find"); // disable search box in ACE editor
        // Make editor available globally
        window.dodona.editor = editor;
    }

    function swapActionButtons(): void {
        document.getElementById("activity-handin-link").addEventListener("show.bs.tab", () => {
            document.getElementById("submission-copy-btn").classList.add("hidden");
            document.getElementById("editor-process-btn").classList.remove("hidden");
        });

        document.getElementById("activity-submission-link").addEventListener("show.bs.tab", () => {
            document.getElementById("submission-copy-btn").classList.add("hidden");
            if (lastSubmission) {
                document.getElementById("editor-process-btn").classList.remove("hidden");
            } else {
                document.getElementById("editor-process-btn").classList.add("hidden");
            }
        });

        document.getElementById("activity-feedback-link").addEventListener("show.bs.tab", () => {
            document.getElementById("editor-process-btn").classList.add("hidden");
            document.getElementById("submission-copy-btn").classList.remove("hidden");
        });
    }

    function submitSolution(code): Promise<Response> {
        const data = new FormData();
        data.append("submission[code]", code);
        data.append("submission[exercise_id]", exerciseId);
        data.append("submission[course_id]", courseId);

        return fetch("/submissions.json", {
            "method": "POST",
            "headers": {
                "x-csrf-token": document.querySelector("meta[name=\"csrf-token\"]").getAttribute("content"),
                "x-requested-with": "XMLHttpRequest",
            },
            "body": data,
        });
    }

    function feedbackLoaded(submissionId): void {
        document.getElementById("feedback").classList.remove("hidden");
        const exerciseFeedbackLink = document.getElementById("activity-feedback-link");
        exerciseFeedbackLink.classList.remove("hidden");
        // eslint-disable-next-line no-undef
        const tab = new bootstrap.Tab(exerciseFeedbackLink);
        tab.show();
        exerciseFeedbackLink.setAttribute("data-submission_id", submissionId);
    }

    function loadFeedback(url, submissionId): void {
        document.getElementById("submission-wrapper").innerHTML = "<center><i class=\"mdi mdi-loading mdi-spin\"></i></center>";
        feedbackLoaded(submissionId);
        fetch(updateURLParameter(url, "format", "js"), {
            headers: {
                "accept": "text/javascript",
                "x-csrf-token": document.querySelector("meta[name=\"csrf-token\"]").getAttribute("content"),
                "x-requested-with": "XMLHttpRequest",
            },
            credentials: "same-origin",
        }).then(resp => Promise.all([resp.ok, resp.text()])).then(([ok, data]) => {
            if (ok) {
                document.getElementById("submission-wrapper").innerHTML = data;
                // .innerHTML does not execute the <script> tags. We execute them manually using eval
                const scripts = document.getElementById("submission-wrapper").getElementsByTagName("script");
                for (const script of scripts) {
                    eval(script.innerHTML);
                }

                initTooltips();
            } else {
                document.getElementById("submission-wrapper").innerHTML = `<div class="alert alert-danger">${I18n.t("js.unknown-error-loading-feedback")}</div>`;
            }
        });
    }

    function enableSubmissionTableLinks(): void {
        document.querySelectorAll<HTMLElement>("a.load-submission").forEach(element => {
            element.addEventListener("click", event => {
                if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) {
                    return;
                }
                event.preventDefault();
                loadFeedback(baseSubmissionsUrl + element.dataset.submission_id, element.dataset.submission_id);
            });
        });
    }

    function feedbackTableLoaded(userId, exerciseId, courseId): void {
        enableSubmissionTableLinks();
        if (lastSubmission) {
            const submissionRow = document.getElementById("submission_" + lastSubmission);
            const status = submissionRow.dataset.status;
            if (status === "queued" || status === "running") {
                setTimeout(function () {
                    lastTimeout = (lastTimeout || 0) + 1000;
                    lastTimeout = lastTimeout >= 5000 ? 4000 : lastTimeout;
                    let url = `/submissions.js?user_id=${userId}&activity_id=${exerciseId}`;
                    if (courseId !== undefined) {
                        url += `&course_id=${courseId}`;
                    }
                    fetch(url, {
                        headers: {
                            "accept": "text/javascript",
                            "x-csrf-token": document.querySelector("meta[name=\"csrf-token\"]").getAttribute("content"),
                            "x-requested-with": "XMLHttpRequest",
                        },
                        credentials: "same-origin" })
                        .then(response => response.text())
                        .then(eval);
                }, (lastTimeout || 0) + 1000);
            } else {
                lastTimeout = 0;
                if (document.getElementById("activity-submission-link").classList.contains("active")) {
                    (submissionRow.querySelector(".load-submission") as HTMLButtonElement).click();
                } else if (document.getElementById("activity-feedback-link").classList.contains("active") &&
                    document.getElementById("activity-feedback-link").dataset.submission_id === lastSubmission) {
                    loadFeedback(baseSubmissionsUrl + lastSubmission, lastSubmission);
                }
                showFABStatus(status);
                setTimeout(enableSubmitButton, 100);
                new Toast(I18n.t("js.submission-processed"));
                lastSubmission = null;
            }
        }
    }

    function enableSubmitButton(): void {
        const btn = document.getElementById("editor-process-btn") as HTMLButtonElement;
        btn.disabled = false;
        btn.classList.remove("busy", "mdi-timer-sand-empty", "mdi-spin");
        btn.classList.add("mdi-send");
    }

    function disableSubmitButton(): void {
        const btn = document.getElementById("editor-process-btn") as HTMLButtonElement;
        btn.disabled = true;
        btn.classList.remove("mdi-send");
        btn.classList.add("busy", "mdi-timer-sand-empty", "mdi-spin");
    }

    function showFABStatus(status): void {
        const fab = document.getElementById("submission-copy-btn");
        const icon = fab.children[0];
        icon.classList.remove("mdi-pencil");
        if (status === "correct") {
            fab.classList.add("correct");
            icon.classList.add(getPositiveEmoji());
        } else {
            fab.classList.add("wrong");
            icon.classList.add("mdi-emoticon-sad-outline");
        }
        setTimeout(resetFABStatus, 4000);
    }
    function resetFABStatus(): void {
        const fab = document.getElementById("submission-copy-btn");
        const icon = fab.children[0];
        fab.classList.remove("correct", "wrong");
        icon.classList.remove(...icon.classList);
        icon.classList.add("mdi", "mdi-pencil");
    }
    function getPositiveEmoji(): string {
        const emojis = ["check-bold", "thumb-up-outline", "emoticon-happy-outline", "emoticon-excited-outline", "emoticon-cool-outline", "sparkles", "party-popper", "arm-flex-outline", "emoticon-kiss-outline", "robot-outline", "cow", "unicorn-variant"];
        return "mdi-" + emojis[Math.floor(Math.pow(Math.random(), 3) * emojis.length)];
    }

    function submissionSuccessful(data, userId): void {
        lastSubmission = data.id;
        new Toast(I18n.t("js.submission-saved"));
        let url = `/submissions.js?user_id=${userId}&activity_id=${data.exercise_id}`;
        if (data.course_id) {
            url += `&course_id=${data.course_id}`;
        }
        fetch(url, {
            headers: {
                "accept": "text/javascript",
                "x-csrf-token": document.querySelector("meta[name=\"csrf-token\"]").getAttribute("content"),
                "x-requested-with": "XMLHttpRequest",
            },
            credentials: "same-origin" })
            .then(response => response.text())
            .then(eval);
        // eslint-disable-next-line no-undef
        const tab = new bootstrap.Tab(document.getElementById("activity-submission-link"));
        tab.show();
    }

    function submissionFailed(request): void {
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

        // create the div that will house the message
        const newDiv = document.createElement("div");
        newDiv.style.display = "none";
        newDiv.classList.add("alert", "alert-danger", "alert-dismissible");
        newDiv.innerText = message;

        // create the button that will be in the div
        const newButton = document.createElement("button");
        newButton.type = "button";
        newButton.classList.add("btn-close", "btn-close-white");
        newButton.setAttribute("data-bs-dismiss", "alert");

        // place the button in the div and the div in the right place in the document
        newDiv.appendChild(newButton);
        const referenceEl = document.getElementById("editor-window");
        referenceEl.parentElement.insertBefore(newDiv, referenceEl);

        // make visible
        newDiv.style.display = "block";
        enableSubmitButton();
    }

    function initDeadlineTimeout(): void {
        if (!_deadline) {
            return;
        }
        const deadlineWarningElement = document.getElementById("deadline-warning");
        const deadlineInfoElement = document.getElementById("deadline-info");
        const deadline = new Date(_deadline);
        const infoDeadline = new Date(deadline.getTime() - (5 * 60 * 1000));

        function showDeadlineAlerts(): void {
            if (deadline < new Date()) {
                deadlineInfoElement.hidden = true;
                deadlineWarningElement.hidden = false;
            } else if (infoDeadline < new Date()) {
                deadlineInfoElement.hidden = false;
                setTimeout(showDeadlineAlerts, Math.min(
                    Math.max(10, (deadline.getTime() - new Date().getTime()) / 10),
                    10 * 60 * 1000));
            } else {
                setTimeout(showDeadlineAlerts, Math.min(
                    Math.max(10, (infoDeadline.getTime() - new Date().getTime()) / 10),
                    10 * 60 * 1000));
            }
        }

        showDeadlineAlerts();
    }

    init();
}

function afterResize(details): void {
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

function onFrameScroll(position): boolean {
    /**
     * The scroll position does not account for the navigation bar, which is always
     * visible. This will add the offset for the navigation bar.
     */
    const navHeight = document.querySelector<HTMLElement>("nav.dodona-navbar").offsetHeight;
    window.scrollTo(position.x, position.y - navHeight);
    return false;
}

export {
    initMathJax, initExerciseShow, initExerciseDescription, afterResize,
    onFrameMessage, onFrameScroll
};
