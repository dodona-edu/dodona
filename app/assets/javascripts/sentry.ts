import * as Sentry from "@sentry/browser";

const HOST_TO_ENVIRONMENT: Record<string, string> = {
    "dodona.localhost": "development",
    "naos.dodona.be": "staging",
    "dodona.be": "production",
};

export function initSentry(): void {
    const environment = window.location.hostname in HOST_TO_ENVIRONMENT ?
        HOST_TO_ENVIRONMENT[window.location.hostname] : "unknown";

    // config options can be found at https://docs.sentry.io/platforms/javascript/configuration/
    Sentry.init({
        dsn: "https://18315b6d60f9329de56983fd94f67db9@o4507329115783168.ingest.de.sentry.io/4507333215256657",
        environment,
    });
}
