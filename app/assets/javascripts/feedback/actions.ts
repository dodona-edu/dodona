import { fetch, updateURLParameter } from "util.js";
import ScoreForm from "feedback/score";

interface ActionOptions {
    currentURL: string;
    feedbackId: string;
    nextURL: string | null;
    nextUnseenURL: string | null;
    buttonText: string;
    scoreItems: [string];
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
    private readonly autoMarkCheckBox: HTMLInputElement | null;
    private readonly skipCompletedCheckBox: HTMLInputElement;
    private readonly allScoresZeroButton: HTMLButtonElement | null;
    private readonly allScoresMaxButton: HTMLButtonElement | null;
    private readonly scoreSumElement: HTMLInputElement | null;
    private readonly completedIcon: HTMLTextElement | null;

    private scoreForms: ScoreForm[];
    // ID's of the score forms that are updating.
    private updatingForms: Set<string> = new Set<string>();
    // Go to the next feedback if all scores have been updated.
    private nextAfterScoreUpdate = false;
    private allowNextAutoMark = true;
    private allowNextOrder = true;
    private nextFeedbackAction: () => void = null;

    constructor(options: ActionOptions) {
        this.options = options;

        // Next/complete buttons
        this.nextButton = document.getElementById("next-feedback-button") as HTMLButtonElement;
        this.autoMarkCheckBox = document.getElementById("auto-mark") as HTMLInputElement;
        this.skipCompletedCheckBox = document.getElementById("skip-completed") as HTMLInputElement;

        this.scoreSumElement = document.getElementById("score-sum") as HTMLInputElement;
        this.completedIcon = document.getElementById("completed-button");

        // Score forms
        this.scoreForms = [];
        for (const scoreItem of this.options.scoreItems) {
            this.initScoreForm(scoreItem);
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
        this.allowNextAutoMark = true;
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

    update(data: Record<string, unknown>): Promise<void> {
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
            } else if ([403, 404, 422].includes(response.status)) {
                new dodona.Toast(I18n.t("js.score.conflict"));
                await this.refresh();
            } else {
                new dodona.Toast(I18n.t("js.score.unknown"));
                await this.refresh();
            }
        });
    }

    async refresh(warning = ""): Promise<void> {
        const url = updateURLParameter(this.options.currentURL, "warning", warning);
        const response = await fetch(url, {
            headers: {
                "Accept": "text/javascript"
            }
        });
        eval(await response.text());
    }

    registerUpdating(scoreItemId: string): void {
        this.updatingForms.add(scoreItemId);
    }

    initScoreForm(scoreItemId: string): void {
        if (this.updatingForms.has(scoreItemId)) {
            this.updatingForms.delete(scoreItemId);
            if (this.updatingForms.size === 0 && this.nextAfterScoreUpdate) {
                this.nextFeedbackAction();
                this.nextAfterScoreUpdate = false;
            }
        }
        // Remove existing score forms.
        this.scoreForms = this.scoreForms.filter(form => form.scoreItemId !== scoreItemId);
        // Get new form. This assumes the HTML has been set already.
        const form = document.getElementById(`${scoreItemId}-score-form-wrapper`) as HTMLElement;
        // If the form is null, we can't edit the score for some reason.
        if (form !== null) {
            this.scoreForms.push(new ScoreForm(form, this));
        }
    }

    setTotal(newTotal: string, completed: boolean): void {
        // Only update the total if we have a total.
        if (this.scoreSumElement) {
            this.scoreSumElement.value = newTotal;
        }

        if (this.completedIcon) {
            if (completed) {
                this.completedIcon.classList.add("mdi-check");
                this.completedIcon.classList.remove("mdi-circle-slice-3");
            } else {
                this.completedIcon.classList.add("mdi-circle-slice-3");
                this.completedIcon.classList.remove("mdi-check");
            }
        }
    }

    initialiseNextButtons(): void {
        const feedbackPrefs = window.localStorage.getItem("feedbackPrefs") || defaultOptions;
        let { autoMark, skipCompleted } = JSON.parse(feedbackPrefs);
        // If the checkbox is missing, we are in grade mode.
        // In that case, we ignore autoMark, since the backend does it for us.
        const hasAutoMark = this.autoMarkCheckBox !== null;
        if (hasAutoMark) {
            this.autoMarkCheckBox.checked = autoMark;
        }
        this.skipCompletedCheckBox.checked = skipCompleted;
        if (autoMark && hasAutoMark) {
            this.setNextWithAutoMark();
        }
        this.checkAndSetNext(skipCompleted);

        this.nextFeedbackAction = async () => {
            if (autoMark && hasAutoMark) {
                await this.update({
                    completed: true
                });
            }
            if (skipCompleted) {
                window.location.href = this.options.nextUnseenURL;
            } else {
                window.location.href = this.options.nextURL;
            }
        };

        this.nextButton.addEventListener("click", async event => {
            event.preventDefault();
            if (this.nextButton.disabled) {
                return;
            }
            this.disableInputs();
            // Wait for score updates before going away.
            if (this.updatingForms.size > 0) {
                this.nextAfterScoreUpdate = true;
                return;
            }
            await this.nextFeedbackAction();
        });

        document.addEventListener("keydown", event => {
            if (event.ctrlKey && event.code === "Enter") {
                event.preventDefault();
                this.nextButton.click();
                return false;
            }
        });

        this.autoMarkCheckBox?.addEventListener("input", async () => {
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
            this.scoreForms.forEach(f => {
                f.markBusy();
                f.data = "0";
            });
            const values = this.scoreForms.map(f => f.getDataForNested());
            await this.update({
                // eslint-disable-next-line camelcase
                scores_attributes: values
            });
        });
        this.allScoresMaxButton?.addEventListener("click", async e => {
            e.preventDefault();
            this.disableInputs();
            this.scoreForms.forEach(f => {
                f.markBusy();
                f.data = f.getMax();
            });
            const values = this.scoreForms.map(f => f.getDataForNested());
            await this.update({
                // eslint-disable-next-line camelcase
                scores_attributes: values
            });
        });
    }
}
