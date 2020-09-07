// Identifiers.
import { fetch } from "util.js";

const confirmButtonId = "lti_content_selection_confirm";
const activitySelectId = "lti_content_selection_activity";
const courseSelectId = "lti_content_selection_course";
const seriesSelectId = "lti_content_selection_series";

export function initLtiContentSelection(payloadUrl: string,
    providerId: number,
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
            // eslint-disable-next-line @typescript-eslint/camelcase
            provider_id: providerId,
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
