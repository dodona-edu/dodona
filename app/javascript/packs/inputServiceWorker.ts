// Specifically import service worker provided by the Papyros-package
// Due to Webpack bundling, we need to do this to prevent other
// parts of the Papyros code to be included as well, as that would cause
// the code to fail due to missing dependencies in a WebWorker environment
import { InputWorker } from "@dodona/papyros/dist/workers/input/InputWorker";
const inputHandler = new InputWorker();

const SYNC_MESSAGE_URL_SUFFIX = "__SyncMessageServiceWorkerInput__";
function isServiceWorkerRequest(event: FetchEvent) {
    return event.request.url.includes(SYNC_MESSAGE_URL_SUFFIX);
}

addEventListener("fetch", async function (event: FetchEvent) {
    if (isServiceWorkerRequest(event)) {
        await inputHandler.handleInputRequest(event);
    } else {
        // Not a Papyros-specific request
        // Fetch as we would handle a normal request
        return; // Default to nothing, browser will handle fetch itself
        // Should be changed when Dodona has service-worker specific duties
    }
});
// Prevent needing to reload page to have working input
addEventListener("install", function (event: ExtendableEvent) {
    event.waitUntil(skipWaiting());
});
addEventListener("activate", function (event: ExtendableEvent) {
    event.waitUntil(clients.claim());
});

export { };
