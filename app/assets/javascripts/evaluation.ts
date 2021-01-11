import { fetch } from "util.js";

const defaultOptions = JSON.stringify({
    autoMark: true,
    skipCompleted: true
});

function interceptFeedbackActionClicks(
    currentURL: string,
    nextURL: string,
    nextUnseenURL: string,
    buttonText: string,
    allowNext: boolean
): void {
    const nextButton = document.getElementById("next-feedback-button");
    const autoMarkCheckBox = document.getElementById("auto-mark") as HTMLInputElement;
    const skipCompletedCheckBox = document.getElementById("skip-completed") as HTMLInputElement;

    // Track if we are allowed to click next if auto mark is on.
    // If auto mark is on, we must consider if we are allowed to mark it as completed or not.
    let allowNextAutoMark = true;
    // Track if there is a next exercise.
    let allowNextOrder = true;

    function syncNextButtonDisabledState(): void {
        nextButton.disabled = !allowNextAutoMark || !allowNextOrder;
    }

    function setNextWithAutoMark(): void {
        nextButton.innerHTML = `${buttonText} + <i class="mdi mdi-comment-check-outline mdi-18"></i>`;
        allowNextAutoMark = allowNext;
        syncNextButtonDisabledState();
    }

    function setNextWithoutAutoMark(): void {
        nextButton.innerHTML = buttonText;
        allowNextAutoMark = true;
        syncNextButtonDisabledState();
    }

    const feedbackPrefs = window.localStorage.getItem("feedbackPrefs") || defaultOptions;
    let { autoMark, skipCompleted } = JSON.parse(feedbackPrefs);
    autoMarkCheckBox.checked = autoMark;
    skipCompletedCheckBox.checked = skipCompleted;
    if (autoMark) {
        setNextWithAutoMark();
    }

    if (nextURL === null && !skipCompleted) {
        allowNextOrder = false;
    } else if (skipCompleted && nextUnseenURL == null) {
        allowNextOrder = false;
    } else {
        allowNextOrder = true;
    }

    syncNextButtonDisabledState();

    nextButton.addEventListener("click", async event => {
        event.preventDefault();
        if (nextButton.disabled) {
            return;
        }
        nextButton.disabled = true;
        if (autoMark) {
            const resp = await fetch(currentURL, {
                method: "PATCH",
                body: JSON.stringify({ feedback: { completed: true } }),
                headers: { "Content-Type": "application/json" }
            });
            eval(await resp.text());
            // Button was replaced, so `nextButton` reference is outdated. For
            // the same reason we need to repeat the disabling.
            document.getElementById("next-feedback-button").disabled = true;
        }
        if (skipCompleted) {
            window.location.href = nextUnseenURL;
        } else {
            window.location.href = nextURL;
        }
    });

    autoMarkCheckBox.addEventListener("input", async () => {
        autoMark = autoMarkCheckBox.checked;
        localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
        if (autoMark) {
            setNextWithAutoMark();
        } else {
            setNextWithoutAutoMark();
        }
    });

    skipCompletedCheckBox.addEventListener("input", async () => {
        skipCompleted = skipCompletedCheckBox.checked;
        localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
        if (nextURL === null && !skipCompleted) {
            nextButton.setAttribute("disabled", "1");
        } else if (skipCompleted && nextUnseenURL == null) {
            nextButton.setAttribute("disabled", "1");
        } else {
            nextButton.removeAttribute("disabled");
        }
    });
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

class Score {
    private input: HTMLInputElement;
    private expectedScore: HTMLInputElement;
    private spinner: HTMLElement;
    private readonly form: HTMLElement;
    private readonly deleteButton: HTMLElement;

    private readonly rubricId: string;
    private readonly feedbackId: string;
    private readonly existing: boolean;
    private readonly link: string;
    private readonly feedbackLink: string;

    constructor(form: HTMLFormElement) {
        this.input = form.querySelector("input.score-input");
        this.spinner = form.querySelector(".dodona-progress");
        this.expectedScore = form.querySelector("input.expected-score");
        this.deleteButton = form.parentElement.querySelector(".delete-button");
        this.feedbackId = form.querySelector("input.feedback").value;
        this.rubricId = form.querySelector("input.rubric").value;
        this.existing = form.dataset.new === "true";
        this.link = form.dataset.url;
        this.feedbackLink = form.dataset.feedbackLink;
        this.form = form;

        this.initListeners();
    }

    private initListeners(): void {
        let valueOnFocus = "";
        this.input.addEventListener("focus", e => {
            valueOnFocus = e.target.value;
        });
        this.input.addEventListener("blur", e => {
            if (valueOnFocus === e.target.value) {
                console.log("Value not changed, aborting...");
                return;
            }
            if (!this.input.reportValidity()) {
                console.log("Data is not valid, aborting...");
                return;
            }
            this.sendUpdate();
        });
        if (this.deleteButton) {
            this.deleteButton.addEventListener("click", e => {
                e.preventDefault();
                if (window.confirm(I18n.t("js.score.confirm"))) {
                    this.delete();
                }
            });
        }
    }

    private sendUpdate(): void {
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
                feedback_id: this.feedbackId,
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

        this.doRequest(method, data);
    }

    private delete(): void {
        this.doRequest("delete", {
            // eslint-disable-next-line @typescript-eslint/camelcase
            expected_score: this.expectedScore.value
        });
    }

    private doRequest(method: string, data: object): void {
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
            // Save the element that has focus.
            const activeId = document.activeElement?.id;
            if (response.ok) {
                // Evaluate the response, which will update the view.
                eval(await response.text());
            } else if ([403, 404, 422].includes(response.status)) {
                new dodona.Toast(I18n.t("js.score.conflict"));
                this.requestRefresh();
            } else {
                new dodona.Toast(I18n.t("js.score.unknown"));
                console.error("Unexpected error when saving score.");
                this.requestRefresh();
            }
            if (activeId) {
                document.getElementById(activeId)?.focus();
            }
        });
    }

    private requestRefresh(): void {
        fetch(this.feedbackLink + "refresh", {
            method: "post",
            headers: {
                "Accept": "text/javascript"
            }
        }).then(async response => eval(await response.text()));
    }

    private markBusy(): void {
        this.input.classList.add("in-progress");
        this.spinner.style.visibility = "visible";
    }
}

function initScoreForms(rubrics: [string]): void {
    for (const rubric of rubrics) {
        const form = document.getElementById(`${rubric}-score-form`) as HTMLFormElement;
        new Score(form);
    }
}

export { interceptAddMultiUserClicks, interceptFeedbackActionClicks, initScoreForms };
