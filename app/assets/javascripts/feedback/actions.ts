import { fetch, updateURLParameter } from "util.js";
import ScoreForm from "feedback/score";

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
 * Manage the feedback actions. This class is a little unusual,
 * as the amount of stuff it does is minimal. In a lot of cases,
 * a request is sent to the server, with rails replacing the actions
 * with the updated HTML. If we use Vue one day, we might rewrite this.
 */
export default class FeedbackActions {
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

    private syncNextButtonDisabledState(): void {
        this.nextButton.disabled = !this.allowNextAutoMark || !this.allowNextOrder;
    }

    private setNextWithAutoMark(): void {
        this.nextButton.innerHTML =
            `${this.options.buttonText} + <i class="mdi mdi-comment-check-outline mdi-18"></i>`;
        this.allowNextAutoMark = this.options.allowNext;
        this.syncNextButtonDisabledState();
    }

    private setNextWithoutAutoMark(): void {
        this.nextButton.innerHTML = this.options.buttonText;
        this.allowNextAutoMark = true;
        this.syncNextButtonDisabledState();
    }

    private checkAndSetNext(skipCompleted: boolean): void {
        if (skipCompleted) {
            // If we skip the completed feedbacks, we can only proceed of we have a next unseen url.
            this.allowNextOrder = this.options.nextUnseenURL !== null;
        } else {
            // If we don't skip the completed feedbacks, we can proceed if we have a next url.
            this.allowNextOrder = this.options.nextURL !== null;
        }

        // Ensure the button is synced with `allowNextOrder`.
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
        this.checkAndSetNext(skipCompleted);

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
            this.checkAndSetNext(skipCompleted);
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
