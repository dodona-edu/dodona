// Specifically import service worker provided by the Papyros-package
import { InputWorker } from "@dodona/papyros/dist/workers/input/InputWorker";

const inputHandler = new InputWorker();

addEventListener("fetch", async function (event: FetchEvent) {
    if (!await inputHandler.handleInputRequest(event)) {
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
