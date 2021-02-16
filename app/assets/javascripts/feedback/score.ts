import { fetch } from "util.js";
import FeedbackActions from "feedback/actions";

/**
 * Manages a single score in the feedback actions.
 *
 * As with the general feedback actions, almost all changes
 * result in a request to the server to replace the current HTML.
 */
export default class ScoreForm {
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
