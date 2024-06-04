import * as Sentry from "@sentry/browser";

export function initSentry(): void {
    const environmentTag = document.querySelector("meta[name='environment']");
    const environment = environmentTag?.getAttribute("content") ?? "unknown";
    const releaseTag = document.querySelector("meta[name='version']");
    const release = releaseTag ? releaseTag.getAttribute("content") : "unknown";

    // config options can be found at https://docs.sentry.io/platforms/javascript/configuration/
    Sentry.init({
        dsn: "https://18315b6d60f9329de56983fd94f67db9@o4507329115783168.ingest.de.sentry.io/4507333215256657",
        environment,
        release,
    });
}
