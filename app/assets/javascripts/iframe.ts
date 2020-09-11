/**
 * Detect if the page is currently loaded in an iframe or not.
 *
 * @return {boolean} True if it is an iframe, false otherwise.
 */
export function isInIframe(): boolean {
    try {
        return window.self !== window.top;
    } catch (e) {
        return true;
    }
}
