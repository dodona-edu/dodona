// Identifiers.
import { fetch } from "util.js";
import { isInIframe } from "iframe";

const redirectButtonId = "lti_redirect_button";
const beforeTextId = "lti_before_text";
const afterTextId = "lti_after_text";

export function ltiMaybeRedirect(browserPath: string): void {
    // If we are not in an iframe, redirect immediately.
    if (!isInIframe()) {
        window.location.href = browserPath;
    }
}

export function initLtiRedirect(): void {
    document.getElementById(redirectButtonId).addEventListener("click", () => {
        // After the user clicks, we wait a bit and then show the text assuming
        // the user has logged in.
        setTimeout(function () {
            document.getElementById(beforeTextId).classList.add("hidden");
            document.getElementById(afterTextId).classList.remove("hidden");
        }, 1000);
    });
}

const confirmButtonId = "lti_content_selection_confirm";
const activitySelectId = "lti_content_selection_activity";
const courseSelectId = "lti_content_selection_course";
const seriesSelectId = "lti_content_selection_series";

export function initLtiContentSelection(payloadUrl: string,
    returnUrl: string,
    decodedToken: object): void {
    // Initialise required elements.
    const confirmButton = document.getElementById(confirmButtonId) as HTMLButtonElement;
    const activitySelect = document.getElementById(activitySelectId) as HTMLSelectElement;
    const courseSelect = document.getElementById(courseSelectId) as HTMLSelectElement;
    const seriesSelect = document.getElementById(seriesSelectId) as HTMLSelectElement;

    // Add a listener to the confirmation button.
    confirmButton.addEventListener("click", async () => {
        // Get the signed payload from the backend.
        const data = {
            activity: activitySelect.value,
            course: courseSelect.value,
            series: seriesSelect.value,
            // eslint-disable-next-line @typescript-eslint/camelcase
            decoded_token: decodedToken
        };
        const responseRaw = await fetch(payloadUrl, {
            headers: { "Content-Type": "application/json" },
            method: "post",
            body: JSON.stringify(data)
        });
        const response = await responseRaw.json();

        // Create a form to submit the payload to the LTI Platform.
        const form = document.createElement("form") as HTMLFormElement;
        form.action = returnUrl;
        form.method = "post";

        const payloadField = document.createElement("input") as HTMLInputElement;
        payloadField.name = "JWT";
        payloadField.type = "hidden";
        payloadField.value = response["payload"];

        const submitButton = document.createElement("button") as HTMLButtonElement;
        submitButton.type = "submit";

        form.append(payloadField, submitButton);
        document.body.append(form);
        form.submit();
    });
}
