import { fetch } from "util.js";

function interceptFeedbackActionClicks(
    currentURL: string,
    nextURL: string,
    nextUnseenURL: string,
    buttonText: string
): void {
    const nextButton = document.getElementById("next-feedback-button");
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

    if (nextURL === null && !skipCompleted) {
        nextButton.setAttribute("disabled", "1");
    } else if (skipCompleted && nextUnseenURL == null) {
        nextButton.setAttribute("disabled", "1");
    } else {
        nextButton.removeAttribute("disabled");
    }

    nextButton.addEventListener("click", async event => {
        event.preventDefault();
        if (nextButton.getAttribute("disabled") === "1") {
            return;
        }
        nextButton.setAttribute("disabled", "1");
        if (autoMark) {
            const resp = await fetch(currentURL, {
                method: "PATCH",
                body: JSON.stringify({ feedback: { completed: true } }),
                headers: { "Content-Type": "application/json" }
            });
            eval(await resp.text());
            // Button was replaced, so `nextButton` reference is outdated. For
            // the same reason we need to repeat the disabling.
            document.getElementById("next-feedback-button").setAttribute("disabled", "1");
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

export { interceptAddMultiUserClicks, interceptFeedbackActionClicks };
