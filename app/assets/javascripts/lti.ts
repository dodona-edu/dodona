// Identifiers.
import { fetch, makeInvisible, makeVisible } from "utilities";
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

function deactivateSelect(container: HTMLElement | null): void {
    if (!container) {
        return;
    }
    container.classList.remove("active");
    container.classList.add("hidden");
    const element = container.getElementsByTagName("select")[0];
    element.removeAttribute("id");
}

function activateSelect(container: HTMLElement | null): void {
    if (!container) {
        return;
    }
    container.classList.remove("hidden");
    container.classList.add("active");
    const element = container.getElementsByTagName("select")[0];
    element.id = activitySelectId;
}

export function initLtiContentSelection(payloadUrl: string,
    returnUrl: string,
    multiple: boolean,
    decodedToken: Record<string, unknown>): void {
    // Initialise required elements.
    const confirmButton = document.getElementById(confirmButtonId) as HTMLButtonElement;
    const courseSelect = document.getElementById(courseSelectId) as HTMLSelectElement;
    const seriesContainer = document.getElementById("series");
    const progressBar = document.getElementById("lti-progress");
    const baseUrl = window.location.origin;

    courseSelect.addEventListener("change", async event => {
        const id = (event.target as HTMLSelectElement).value;
        seriesContainer.innerHTML = "";

        if (id === "") {
            makeInvisible(confirmButton);
            return;
        }
        makeVisible(confirmButton);
        makeVisible(progressBar);
        const url = new URL(baseUrl);
        url.pathname = "/lti/series_and_activities";
        url.searchParams.append("id", id);
        url.searchParams.append("multiple", multiple.toString());

        fetch(url, {
            headers: {
                "accept": "text/javascript",
            }
        })
            .then(resp => resp.text())
            .then(data => {
                eval(data);
                makeInvisible(progressBar);
            });
    });

    // Listen on clicks for series
    seriesContainer.addEventListener("change", e => {
        // Only listen to the selector.
        if (e.target && (e.target as HTMLElement).id !== seriesSelectId) {
            return;
        }
        const seriesId = (e.target as HTMLSelectElement).value;
        // Hide existing activities
        const existing = document.querySelector(".activities-container.active") as HTMLElement;
        deactivateSelect(existing);

        const newActivities = document.getElementById(`series-activities-${seriesId}`);
        activateSelect(newActivities);
    });

    // Add a listener to the confirmation button.
    confirmButton.addEventListener("click", async () => {
        // Reselect some elements, since they might have changed.
        const activitySelect = document.getElementById(activitySelectId) as HTMLSelectElement;
        const seriesSelect = document.getElementById(seriesSelectId) as HTMLSelectElement;
        // Get the signed payload from the backend.
        const activities = Array.from(activitySelect ? activitySelect.selectedOptions : [])
            .map(i => i.value);

        const data = {
            activities: activities,
            series: seriesSelect ? seriesSelect.value : null,
            course: courseSelect.value,

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
