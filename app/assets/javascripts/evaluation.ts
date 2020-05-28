import { fetch } from "util.js";

async function setCompletedStatus(url: string, status: boolean): Promise<Response> {
    return fetch(url, {
        method: "PATCH",
        body: JSON.stringify({
            feedback: { completed: status }
        }),
        headers: { "Content-Type": "application/json" }
    });
}

function interceptFeedbackActionClicks(
    currentURL: string,
    nextURL: string,
    nextUnseenURL: string,
    buttonText: string
): void {
    const nextButton = document.getElementById("next-feedback-button");
    const completed = document.getElementById("feedback-completed") as HTMLInputElement;
    const autoMarkCheckBox = document.getElementById("auto-mark") as HTMLInputElement;
    const skipCompletedCheckBox = document.getElementById("skip-completed") as HTMLInputElement;

    const feedbackPrefs = window.localStorage.getItem("feedbackPrefs");
    if (feedbackPrefs !== null) {
        const { autoMark, skipCompleted } = JSON.parse(feedbackPrefs);
        autoMarkCheckBox.checked = autoMark;
        skipCompletedCheckBox.checked = skipCompleted;
        if (autoMark) {
            nextButton.innerHTML = `${buttonText} + <i class="mdi mdi-comment-check-outline mdi-18"></i>`;
        }
    }

    let autoMark = autoMarkCheckBox.checked;
    let skipCompleted = skipCompletedCheckBox.checked;

    nextButton.addEventListener("click", async event => {
        event.preventDefault();
        if (autoMark) {
            await setCompletedStatus(currentURL, true);
        }
        if (skipCompleted) {
            window.location.href = nextUnseenURL;
        } else {
            window.location.href = nextURL;
        }
    });

    completed.addEventListener("input", async () => {
        const resp = await setCompletedStatus(currentURL, completed.checked);
        eval(await resp.text());
    });

    autoMarkCheckBox.addEventListener("input", async () => {
        autoMark = autoMarkCheckBox.checked;
        localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
        if (autoMark) {
            nextButton.innerHTML = `${buttonText} + <i class="mdi mdi-comment-check-outline mdi-18"></i>`;
        } else {
            nextButton.innerHTML = buttonText;
        }
    });

    skipCompletedCheckBox.addEventListener("input", async () => {
        skipCompleted = skipCompletedCheckBox.checked;
        localStorage.setItem("feedbackPrefs", JSON.stringify({ autoMark, skipCompleted }));
    });
}

export { interceptFeedbackActionClicks };
