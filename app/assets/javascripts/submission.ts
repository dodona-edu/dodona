import { getParentByClassName } from "utilities";
import { i18n } from "i18n/i18n";

function initSubmissionShow(parentClass: string, mediaPath: string, token: string): void {
    function init(): void {
        initDiffSwitchButtons();
        initTabLinks();
        initCollapseButtons();
        initHideCorrect();
        initTabSummaryLinks();
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

    function initCollapseButtons(): void {
        document.querySelectorAll(".group .btn-collapse").forEach(b => {
            b.addEventListener("click", e => {
                const button = e.currentTarget;
                const group = getParentByClassName(button, "group");
                group.classList.toggle("collapsed");
            });
        });
    }

    function initTabSummaryLinks(): void {
        document.querySelectorAll(".tab-summary-icons a").forEach(l => {
            l.addEventListener("click", () => {
                // The href is a hash followed by the id of the group
                // We remove the hash and get the group by id
                const groupId = l.attributes["href"].value.substring(1);
                const group = document.getElementById(groupId);
                group.classList.remove("collapsed");
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
                    tab.querySelectorAll(".group.correct").forEach((group: HTMLElement) => {
                        group.classList.remove("collapsed");
                    });
                } else {
                    tab.querySelectorAll(".group.correct").forEach((group: HTMLElement) => {
                        group.classList.add("collapsed");
                    });
                }
            });
        });
    }

    function initTabLinks(): void {
        document.querySelectorAll("a.tab-link").forEach(t => {
            t.addEventListener("click", e => {
                const link = e.currentTarget;
                const tabName = link.dataset.tab;
                const line = link.dataset.line;

                // prevent automatic scrolling to top of the page when clicking a link
                e.preventDefault();

                const query = tabName && tabName !== "code" ?
                    `.feedback-table .nav-tabs > li a[href*='#tab-${tabName}']` :
                    "#link-to-code-tab";
                const tab = document.querySelector(query);
                new bootstrap.Tab(tab).show();

                if (line !== undefined) {
                    dodona.codeListing.clearHighlights();
                    dodona.codeListing.highlightLine(line, true);
                }
            });
        });

        // scroll to tab top after tab is shown
        document.querySelectorAll(".feedback-table a[data-bs-toggle=\"tab\"]").forEach(tabEl => {
            tabEl.addEventListener("shown.bs.tab", event => {
                const shownTabId = (event.target as HTMLElement).getAttribute("href");
                const shownTab = document.querySelector(shownTabId);
                shownTab.scrollIntoView();
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
    const congrats = `js.submission_motivational_message.${Math.ceil(Math.random() * 6)}`;
    message.innerHTML = `
        <div class="callout callout-success mt-0" role="alert">
            <span>${i18n.t(congrats)}</span>
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

function showLastTab(): void {
    const tab = document.querySelector(".nav.nav-tabs li:last-child a");
    if (tab) {
        new bootstrap.Tab(tab).show();
    }
}

export { initSubmissionShow, initSubmissionHistory, initCorrectSubmissionToNextLink, showLastTab };
