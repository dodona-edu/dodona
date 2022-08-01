import { fetch } from "util.js";
import { InactiveTimeout } from "auto_reload.ts";

const questionContainerId = "question-container";
const stateChangeLinkClass = "state-changer";
const refreshElementId = "question-refresh-container";
const refreshCheckboxId = "enable_refresh";

function setParam(
    urlValue: string,
    param: string,
    value: string,
    relative = true): string {
    const url = new URL(urlValue, window.location.origin);
    url.searchParams.set(param, value);
    if (relative) {
        return url.pathname + url.search;
    } else {
        return url.href;
    }
}

export class QuestionTable {
    refreshUrl: string;

    /**
     * Initiate the question table. The table containing the questions should have the html id
     * {@link questionContainerId}.
     *
     * @param {string} refreshUrl The URL of the page or section to use as refresh URL.
     * @param {boolean} enableClick If clicking the row should be intercepted or not.
     */
    constructor(refreshUrl: string, enableClick: boolean) {
        this.refreshUrl = refreshUrl;

        // Listen to the buttons to change state.
        document.getElementById(questionContainerId).addEventListener("click", e => {
            if (!e.target) {
                return;
            }
            const target = e.target as HTMLElement;
            const link = target.closest<HTMLLinkElement>(`a.${stateChangeLinkClass}`);
            if (link) {
                // The user clicked one of the buttons, so handle the event.
                e.preventDefault();
                this.changeStatus(link.href, link.dataset["from"], link.dataset["to"]);
                return;
            }

            const tr = target.closest<HTMLElement>("tr.selection-row");
            if (enableClick && tr) {
                e.preventDefault();
                window.open(tr.dataset["href"]);
                return;
            }
        });
    }

    refresh(): void {
        fetch(this.getRefreshUrl(), {
            headers: {
                "accept": "text/javascript",
                "x-csrf-token": $("meta[name=\"csrf-token\"]").attr("content"),
                "x-requested-with": "XMLHttpRequest",
            },
            credentials: "same-origin",
        })
            .then(req => req.text())
            .then(resp => eval(resp));
    }

    protected getRefreshUrl(): string {
        const url = new URL(this.refreshUrl, window.location.origin);
        url.search = window.location.search;
        return url.toString();
    }

    /**
     * Change the status of a question.
     * This function will reload the question table after the network operations complete.
     *
     * @param {string} url The url to invoke, changing the status.
     * @param {string} from The expected state of the question.
     * @param {string} to The new state.
     */
    changeStatus(url: string, from: string, to: string): void {
        fetch(url, {
            method: "PATCH",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                from: from,
                question: {
                    // eslint-disable-next-line camelcase
                    question_state: to
                }
            })
        }).then(response => {
            if (response.status == 404) {
                new dodona.Toast(I18n.t("js.user_question.deleted"));
            } else if (response.status == 403) {
                new dodona.Toast(I18n.t("js.user_question.conflict"));
            }
            this.refresh();
        });
    }
}

export class RefreshingQuestionTable extends QuestionTable {
    timeout: InactiveTimeout;

    constructor(refreshUrl: string, autoStart: boolean) {
        super(refreshUrl, true);

        // Set up auto refresh.
        const element = document.getElementById(refreshElementId);
        this.timeout = new InactiveTimeout(element, 2000, () => this.refresh());
        if (autoStart) {
            this.timeout.start();
        }

        // Listen to the enabling/disabling or automatic refreshes.
        document.getElementById(refreshCheckboxId).addEventListener("change", e => {
            if ((e.target as HTMLInputElement).checked) {
                this.timeout.start();
            } else {
                this.timeout.end();
            }
            this.updatePaginationLinks();
        });
    }

    protected getRefreshUrl(): string {
        return setParam(super.getRefreshUrl(), "refresh", this.timeout.isStarted().toString());
    }

    protected updatePaginationLinks(): void {
        document.querySelectorAll(`#${refreshElementId} .pagination a`).forEach(e => {
            const link = e as HTMLLinkElement;
            link.href = setParam(link.href, "refresh", this.timeout.isStarted().toString());
        });
    }
}

export function toggleQuestionNavDot(show: boolean): void {
    const element = document.getElementById("question-navbar-link");
    element.classList.toggle("notification", show);
    element.classList.toggle("notification-left", show);
}
