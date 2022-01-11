import { fetch, createDelayer } from "util.js";
import FeedbackActions from "feedback/actions";

/**
 * Manages a single score in the feedback actions.
 *
 * As with the general feedback actions, almost all changes
 * result in a request to the server to replace the current HTML.
 *
 * When a score is updated, the server sends a js response that will
 * replace the HTML for the given score. Afterwards, the `FeedbackActions`
 * instance will be notified.
 */
export default class ScoreForm {
    private readonly input: HTMLInputElement;
    private readonly expectedScore: HTMLInputElement;
    private readonly spinner: HTMLElement;
    private readonly deleteButton: HTMLElement;
    private readonly zeroButton: HTMLElement;
    private readonly maxButton: HTMLElement;
    private readonly maxText: HTMLElement;
    private readonly form: HTMLFormElement;

    private readonly parent: FeedbackActions;
    public readonly scoreItemId: string;
    private readonly existing: boolean;
    private readonly link: string;
    private readonly id: string;

    constructor(element: HTMLElement, parent: FeedbackActions) {
        this.parent = parent;

        this.form = element.querySelector(".score-form") as HTMLFormElement;
        this.input = this.form.querySelector("input.score-input");
        this.spinner = this.form.querySelector(".dodona-progress");
        this.expectedScore = this.form.querySelector(".score-form input.expected-score");
        this.deleteButton = this.form.parentElement.querySelector(".delete-button");
        this.zeroButton = this.form.parentElement.querySelector(".single-zero-button");
        this.maxButton = this.form.parentElement.querySelector(".single-max-button");
        this.scoreItemId = (this.form.querySelector("input.score-item") as HTMLInputElement).value;
        this.maxText = this.form.querySelector(".max-text");
        this.id = (this.form.querySelector("input.id") as HTMLInputElement).value;
        this.existing = this.form.dataset.new === "true";
        this.link = this.form.dataset.url;

        this.initListeners();
    }

    public getMax(): string {
        return this.maxText.dataset.max;
    }

    private initListeners(): void {
        let valueOnFocus = "";
        let updating = false;
        this.input.addEventListener("focus", e => {
            valueOnFocus = (e.target as HTMLInputElement).value;
        });
        this.form.addEventListener("submit", e => {
            e.preventDefault();
        });
        const delay = createDelayer();
        this.input.addEventListener("change", ev => {
            // If the score is not valid, don't do anything.
            if (!this.input.reportValidity()) {
                return;
            }
            // Mark as busy to show we are aware an update should happen.
            // If we don't do this, we need a difficult balance between waiting
            // long enough so the delay is useful when using the increment/decrement buttons
            // and the case where we type the value and don't want to wait.
            this.visualiseUpdating();
            this.markBusy();
            delay(() => {
                if (valueOnFocus === (ev.target as HTMLInputElement).value) {
                    return;
                }
                if (updating) {
                    return;
                }

                // This is delayed, so check validity again.
                if (!this.input.reportValidity()) {
                    return;
                }

                updating = true;
                this.sendUpdate(document.activeElement as HTMLElement);
            }, 400);
        });
        if (this.deleteButton) {
            this.deleteButton.addEventListener("click", e => {
                e.preventDefault();
                if (window.confirm(I18n.t("js.score.confirm"))) {
                    this.delete();
                }
            });
        }
        this.zeroButton.addEventListener("click", e => {
            e.preventDefault();
            this.input.value = "0";
            this.sendUpdate();
        });
        this.maxButton.addEventListener("click", e => {
            e.preventDefault();
            this.input.value = this.getMax();
            this.sendUpdate();
        });
    }

    public set data(value: string) {
        this.input.value = value;
    }

    public get data(): string {
        return this.input.value;
    }

    public getDataForNested(): Record<string, unknown> {
        // If not existing, include ID.
        if (this.existing) {
            return {
                id: this.id,
                score: this.input.value,
            };
        } else {
            return {
                score: this.input.value,
                // eslint-disable-next-line camelcase
                score_item_id: this.scoreItemId
            };
        }
    }

    private sendUpdate(newFocus?: HTMLElement): void {
        // Special case where the value is empty: do as if
        // the clear button has been pressed.
        if (this.input.value === "") {
            this.delete();
            return;
        }

        let data;
        if (this.existing) {
            data = {
                score: this.input.value,
                // eslint-disable-next-line camelcase
                expected_score: this.expectedScore.value
            };
        } else {
            data = {
                score: this.input.value,
                // eslint-disable-next-line camelcase
                feedback_id: this.parent.options.feedbackId,
                // eslint-disable-next-line camelcase
                score_item_id: this.scoreItemId
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
            // eslint-disable-next-line camelcase
            expected_score: this.expectedScore.value
        });
    }

    private doRequest(method: string, data: Record<string, unknown>, newFocus?: HTMLElement): void {
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

    private visualiseUpdating(): void {
        this.input.classList.add("in-progress");
        this.maxText.classList.add("in-progress");
        this.spinner.style.visibility = "visible";
    }

    public markBusy(): void {
        this.parent.registerUpdating(this.scoreItemId);
        this.disableInputs();
        this.visualiseUpdating();
    }

    public disableInputs(): void {
        this.input.disabled = true;
    }
}
