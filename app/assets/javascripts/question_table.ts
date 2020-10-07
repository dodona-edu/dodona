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
    relative: boolean = true): string {
    const url = new URL(urlValue, window.location.origin);
    url.searchParams.set(param, value);
    if (relative) {
        return url.pathname + url.search;
    } else {
        return url.href;
    }
}

export class QuestionTable {
    refreshUrl: string
    timeout: InactiveTimeout

    constructor(refreshUrl: string, autoStart: boolean) {
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
            if (tr) {
                e.preventDefault();
                window.open(tr.dataset["href"]);
                return;
            }
        });

        // Set up auto refresh.
        const element = document.getElementById(refreshElementId);
        this.timeout = new InactiveTimeout(element, 2000, () => this.refresh());
        if (autoStart) {
            this.timeout.start();
        }

        // Listen to the enabling/disabling or automatic refreshes.
        document.getElementById(refreshCheckboxId).addEventListener("change", e => {
            if ((e.target as HTMLInputElement).checked) {
                console.log("Enabling...");
                this.timeout.start();
            } else {
                console.log("Disabling...");
                this.timeout.end();
            }
            this.updatePaginationLinks();
        });
    }

    refresh(): void {
        const url = setParam(this.refreshUrl, "refresh", this.timeout.isStarted().toString());
        fetch(url, {
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
                    // eslint-disable-next-line @typescript-eslint/camelcase
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

    private updatePaginationLinks(): void {
        document.querySelectorAll(`#${refreshElementId} .pagination a`).forEach(e => {
            const link = e as HTMLLinkElement;
            link.href = setParam(link.href, "refresh", this.timeout.isStarted().toString());
        });
    }
}
