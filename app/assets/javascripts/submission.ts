import { getParentByClassName } from "util.js";

function initSubmissionShow(parentClass: string, mediaPath: string, token: string): void {
    function init(): void {
        initDiffSwitchButtons();
        initTabLinks();
        initHideCorrect();
        contextualizeMediaPaths(parentClass, mediaPath, token);
    }

    function initDiffSwitchButtons(): void {
        document.querySelectorAll(".diff-switch-buttons .btn").forEach( b => {
            b.addEventListener("click", e => {
                const button = e.currentTarget;
                const tab = getParentByClassName(button, "tab-pane");
                const tabButtons = tab.querySelectorAll(".diff-switch-buttons .btn");
                tabButtons.forEach(b => b.classList.remove("active"));
                button.classList.add("active");
                const diffs = tab.querySelectorAll(".diffs");
                diffs.forEach(d => {
                    d.classList.remove("show-split");
                    d.classList.remove("show-unified");
                    d.classList.add(button.dataset.show_class);
                });
            });
        });
    }

    function initHideCorrect(): void {
        document.querySelectorAll(".correct-switch-buttons .btn").forEach( b => {
            b.addEventListener("click", e => {
                const button = e.currentTarget;
                const tab = getParentByClassName(button, "feedback-tab-pane");
                const tabButtons = tab.querySelectorAll(".correct-switch-buttons .btn");
                tabButtons.forEach( b => b.classList.remove("active"));
                button.classList.add("active");
                if (button.dataset.show === "true") {
                    tab.querySelectorAll(".group.correct").forEach((testcase: HTMLElement) => {
                        testcase.style.display = "block";
                    });
                } else {
                    tab.querySelectorAll(".group.correct").forEach((testcase: HTMLElement) => {
                        testcase.style.display = "none";
                    });
                }
            });
        });
    }

    function initTabLinks(): void {
        document.querySelectorAll("a.tab-link").forEach(t => {
            t.addEventListener("click", e => {
                const link = e.currentTarget;
                const tabName = link.dataset.tab || "code";
                const line = link.dataset.line;

                // prevent automatic scrolling to top of the page when clicking a link
                e.preventDefault();

                const tab = document.querySelector(`.feedback-table .nav-tabs > li a[href*='#tab-${tabName}']`);
                new bootstrap.Tab(tab).show();

                if (line !== undefined) {
                    dodona.codeListing.clearHighlights();
                    dodona.codeListing.highlightLine(line, true);
                }
            });
        });
    }

    init();
}

function contextualizeMediaPaths(parentClass: string, exercisePath: string, token: string): void {
    const tokenPart = token ? `?token=${token}` : "";
    const query = "a[href^='media'],a[href^='./media']";
    Array.from(document.getElementsByClassName(parentClass)).forEach(parent => {
        parent.querySelectorAll(query).forEach(element => {
            Array.from(element.attributes).forEach(attribute => {
                if (attribute.name == "href") {
                    const value = attribute.value;
                    if (value.startsWith("./media/")) {
                        attribute.value = exercisePath + "/media/" +
                            value.substring(8) + tokenPart;
                    } else if (value.startsWith("media/")) {
                        attribute.value = exercisePath + "/media/" +
                            value.substring(6) + tokenPart;
                    }
                }
            });
        });
    });
}

function initCorrectSubmissionToNextLink(status: string): void {
    if (status !== "correct") {
        return;
    }
    const link = document.getElementById("next-exercise-link") as HTMLAnchorElement;
    if (!link) {
        return;
    }
    const message = document.getElementById("submission-motivational-message");
    const congrats = `js.submission_motivational_message.${Math.ceil(Math.random() * 36)}`;
    message.innerHTML = `
        <div class="callout callout-success mt-0" role="alert">
            <span>${I18n.t(congrats)}</span>
            <a href="${link.href}" class="m-1">
                ${link.dataset.title}
            </a>
        </div>
    `;
}

function initSubmissionHistory(id: string): void {
    const element = document.getElementById("history-"+id);
    element.scrollIntoView({ block: "center", inline: "nearest" });
}

export { initSubmissionShow, initSubmissionHistory, initCorrectSubmissionToNextLink };
