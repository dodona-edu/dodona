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
            if (!link) {
                return;
            }

            // The user clicked one of the buttons, so handle the event.
            e.preventDefault();
            this.changeStatus(link.href, link.dataset["from"]);
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
        const url = setParam(this.refreshUrl, "refresh", this.timeout.started.toString());
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
     * @param {string} changeUrl The url to invoke, changing the status.
     * @param {string} from The status you expect the question to currently have. This allows us
     *                      to detect race conditions.
     */
    changeStatus(changeUrl: string, from: string): void {
        const url = setParam(changeUrl, "from", from);
        fetch(url, {
            method: "POST",
            headers: {
                "Accept": "application/json",
            }
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
            link.href = setParam(link.href, "refresh", this.timeout.started.toString());
        });
    }
}
