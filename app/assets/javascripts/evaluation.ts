import { fetch, updateURLParameter } from "util.js";

interface ActionOptions {
    currentURL: string;
    currentRefreshURL: string;
    feedbackId: string;
    nextURL: string | null;
    nextUnseenURL: string | null;
    buttonText: string;
    allowNext: boolean;
    rubrics: [string];
}

const defaultOptions = JSON.stringify({
    autoMark: true,
    skipCompleted: true
});

/**
 * Manages a single score in the feedback actions.
 *
 * As with the general feedback actions, almost all changes
 * result in a request to the server to replace the current HTML.
 */
class ScoreForm {
    private readonly input: HTMLInputElement;
    private readonly expectedScore: HTMLInputElement;
    private readonly spinner: HTMLElement;
    private readonly deleteButton: HTMLElement;
    private readonly maxLink: HTMLElement;

    private readonly parent: FeedbackActions;
    private readonly rubricId: string;
    private readonly existing: boolean;
    private readonly link: string;
    private readonly id: string;

    private disabled = false;

    constructor(element: HTMLElement, parent: FeedbackActions) {
        this.parent = parent;

        const form = element.querySelector(".score-form") as HTMLFormElement;
        this.input = form.querySelector("input.score-input");
        this.spinner = form.querySelector(".dodona-progress");
        this.expectedScore = form.querySelector(".score-form input.expected-score");
        this.deleteButton = form.parentElement.querySelector(".delete-button");
        this.rubricId = (form.querySelector("input.rubric") as HTMLInputElement).value;
        this.maxLink = element.querySelector("a.score-click");
        this.id = (form.querySelector("input.id") as HTMLInputElement).value;
        this.existing = form.dataset.new === "true";
        this.link = form.dataset.url;

        this.initListeners();
    }

    public getMax(): string {
        return this.maxLink.textContent;
    }

    private initListeners(): void {
        let valueOnFocus = "";
        this.input.addEventListener("focus", e => {
            valueOnFocus = (e.target as HTMLInputElement).value;
        });
        this.input.addEventListener("blur", e => {
            if (valueOnFocus === (e.target as HTMLInputElement).value) {
                return;
            }
            if (!this.input.reportValidity()) {
                return;
            }
            this.sendUpdate(e.relatedTarget as HTMLElement);
        });
        if (this.deleteButton) {
            this.deleteButton.addEventListener("click", e => {
                e.preventDefault();
                if (window.confirm(I18n.t("js.score.confirm"))) {
                    this.delete();
                }
            });
        }
        this.maxLink.addEventListener("click", e => {
            e.preventDefault();
            this.input.value = (e.target as HTMLElement).textContent;
            this.sendUpdate();
        });
    }

    public setData(value: string): void {
        this.input.value = value;
    }

    public getDataForNested(): object {
        // If not existing, include ID.
        if (this.existing) {
            return {
                id: this.id,
                score: this.input.value,
            };
        } else {
            return {
                score: this.input.value,
                // eslint-disable-next-line @typescript-eslint/camelcase
                rubric_id: this.rubricId
            };
        }
    }

    private sendUpdate(newFocus: HTMLElement | null = null): void {
        let data;
        if (this.existing) {
            data = {
                score: this.input.value,
                // eslint-disable-next-line @typescript-eslint/camelcase
                expected_score: this.expectedScore.value
            };
        } else {
            data = {
                score: this.input.value,
                // eslint-disable-next-line @typescript-eslint/camelcase
                feedback_id: this.parent.options.feedbackId,
                // eslint-disable-next-line @typescript-eslint/camelcase
                rubric_id: this.rubricId
            };
        }

        let method;
        if (this.existing) {
            method = "PATCH";
        } else {
            method = "POST";
        }

        this.doRequest(method, data, newFocus);
    }

    private delete(): void {
        this.doRequest("delete", {
            // eslint-disable-next-line @typescript-eslint/camelcase
            expected_score: this.expectedScore.value
        });
    }

    private doRequest(method: string, data: object, newFocus: HTMLElement | null = null): void {
        // Save the element that has focus.
        const activeId = newFocus?.id;
        this.markBusy();
        fetch(this.link, {
            method: method,
            headers: {
                "Accept": "text/javascript",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                score: data
            })
        }).then(async response => {
            if (response.ok) {
                // Evaluate the response, which will update the view.
                eval(await response.text());
            } else if ([403, 404, 422].includes(response.status)) {
                new dodona.Toast(I18n.t("js.score.conflict"));
                await this.parent.refresh(this.id);
            } else {
                new dodona.Toast(I18n.t("js.score.unknown"));
                await this.parent.refresh(this.id);
            }
            if (activeId) {
                document.getElementById(activeId)?.focus();
            }
        });
    }

    public markBusy(): void {
        this.disableInputs();
        this.input.classList.add("in-progress");
        this.spinner.style.visibility = "visible";
    }

    public disableInputs(): void {
        this.input.disabled = true;
        this.disabled = false;
    }
}

/**
 * Manage the feedback actions. This class is a little unusual,
 * as the amount of stuff it does is minimal. In a lot of cases,
 * a request is sent to the server, with rails replacing the actions
 * with the updated HTML. If we use Vue one day, we might rewrite this.
 */
class FeedbackActions {
    readonly options: ActionOptions;

    private readonly nextButton: HTMLButtonElement;
    private readonly autoMarkCheckBox: HTMLInputElement;
    private readonly skipCompletedCheckBox: HTMLInputElement;
    private readonly allScoresZeroButton: HTMLButtonElement | null;
    private readonly allScoresMaxButton: HTMLButtonElement | null;

    private readonly scoreForms: ScoreForm[];
    private allowNextAutoMark: boolean = true;
    private allowNextOrder: boolean = true;

    constructor(options: ActionOptions) {
        this.options = options;

        // Next/complete buttons
        this.nextButton = document.getElementById("next-feedback-button") as HTMLButtonElement;
        this.autoMarkCheckBox = document.getElementById("auto-mark") as HTMLInputElement;
        this.skipCompletedCheckBox = document.getElementById("skip-completed") as HTMLInputElement;

        // Score forms
        this.scoreForms = [];
        for (const rubric of this.options.rubrics) {
            const form = document.getElementById(`${rubric}-score-form-wrapper`) as HTMLElement;
            if (form !== null) {
                this.scoreForms.push(new ScoreForm(form, this));
            }
        }

        this.allScoresZeroButton = document.getElementById("zero-button") as HTMLButtonElement;
        this.allScoresMaxButton = document.getElementById("max-button") as HTMLButtonElement;

        this.initialiseNextButtons();
        this.initScoreForms();
    }

    syncNextButtonDisabledState(): void {
        this.nextButton.disabled = !this.allowNextAutoMark || !this.allowNextOrder;
    }

    setNextWithAutoMark(): void {
        this.nextButton.innerHTML =
            `${this.options.buttonText} + <i class="mdi mdi-comment-check-outline mdi-18"></i>`;
        this.allowNextAutoMark = this.options.allowNext;
        this.syncNextButtonDisabledState();
    }

    setNextWithoutAutoMark(): void {
        this.nextButton.innerHTML = this.options.buttonText;
        this.allowNextAutoMark = true;
        this.syncNextButtonDisabledState();
    }

    disableInputs(): void {
        this.nextButton.disabled = true;
        this.scoreForms.forEach(s => s.disableInputs());
    }

    update(data): Promise<void> {
        this.disableInputs();
        return fetch(this.options.currentURL, {
            method: "PATCH",
            body: JSON.stringify({ feedback: data }),
            headers: {
                "Content-Type": "application/json",
                "Accept": "text/javascript"
            }
        }).then(async response => {
            if (response.ok) {
                eval(await response.text());
            } else {
                new dodona.Toast(I18n.t("js.score.unknown"));
            }
        });
    }

    /**
     * Refresh the actions from the server.
     * @param {string} warning - Score to mark with a warning.
     */
    async refresh(warning: string = ""): Promise<void> {
        const url = updateURLParameter(this.options.currentRefreshURL, "warning", warning);
        const response = await fetch(url, {
            method: "post",
            headers: {
                "Accept": "text/javascript"
            }
        });
        eval(await response.text());
    }

    initialiseNextButtons(): void {
        const feedbackPrefs = window.localStorage.getItem("feedbackPrefs") || defaultOptions;
        let { autoMark, skipCompleted } = JSON.parse(feedbackPrefs);
        this.autoMarkCheckBox.checked = autoMark;
        this.skipCompletedCheckBox.checked = skipCompleted;
        if (autoMark) {
            this.setNextWithAutoMark();
        }

        if (this.options.nextURL === null && !skipCompleted) {
            this.allowNextOrder = false;
        } else if (skipCompleted && this.options.nextUnseenURL == null) {
            this.allowNextOrder = false;
        } else {
            this.allowNextOrder = true;
        }

        this.syncNextButtonDisabledState();

        this.nextButton.addEventListener("click", async event => {
            event.preventDefault();
            if (this.nextButton.disabled) {
                return;
            }
            this.disableInputs();
            if (autoMark) {
                await this.update({
                    completed: true
                });
            }
            if (skipCompleted) {
                window.location.href = this.options.nextUnseenURL;
            } else {
                window.location.href = this.options.nextURL;
            }
        });

        this.autoMarkCheckBox.addEventListener("input", async () => {
            autoMark = this.autoMarkCheckBox.checked;
            localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
            if (autoMark) {
                this.setNextWithAutoMark();
            } else {
                this.setNextWithoutAutoMark();
            }
        });

        this.skipCompletedCheckBox.addEventListener("input", async () => {
            skipCompleted = this.skipCompletedCheckBox.checked;
            localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
            if (this.options.nextURL === null && !skipCompleted) {
                this.nextButton.setAttribute("disabled", "1");
            } else if (skipCompleted && this.options.nextUnseenURL == null) {
                this.nextButton.setAttribute("disabled", "1");
            } else {
                this.nextButton.removeAttribute("disabled");
            }
        });
    }

    initScoreForms(): void {
        this.allScoresZeroButton?.addEventListener("click", async e => {
            e.preventDefault();
            this.disableInputs();
            const values = this.scoreForms.map(f => {
                f.markBusy();
                f.setData("0");
                return f.getDataForNested();
            });
            await this.update({
                // eslint-disable-next-line @typescript-eslint/camelcase
                scores_attributes: values
            });
        });
        this.allScoresMaxButton?.addEventListener("click", async e => {
            e.preventDefault();
            this.disableInputs();
            const values = this.scoreForms.map(f => {
                f.markBusy();
                f.setData(f.getMax());
                return f.getDataForNested();
            });
            await this.update({
                // eslint-disable-next-line @typescript-eslint/camelcase
                scores_attributes: values
            });
        });
    }
}

function interceptAddMultiUserClicks(): void {
    let running = false;
    document.querySelectorAll(".user-select-option a").forEach(option => {
        option.addEventListener("click", async event => {
            if (!running) {
                running = true;
                event.preventDefault();
                const button = option.querySelector(".button");
                const loader = option.querySelector(".loader");
                button.classList.add("hidden");
                loader.classList.remove("hidden");
                const response = await fetch(option.getAttribute("href"), { method: "POST" });
                eval(await response.text());
                loader.classList.add("hidden");
                button.classList.remove("hidden");
                running = false;
            }
        });
    });
}

export { interceptAddMultiUserClicks, FeedbackActions };
