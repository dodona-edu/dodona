import ClipboardJS from "clipboard";
import { tooltip } from "util.js";

/**
 * Small wrapper around ClipboardJS to copy some content the clipboard when the
 * element with the given identifier is pressed. If the content you need to copy
 * is in some HTML element, you probably don't need this and can use ClipboardJS
 * directly.
 *
 * @param {string} identifier The identifying query for the button to attach the listener to.
 * @param {string} code The code to put on the clipboard.
 */
export function attachClipboard(identifier: string, code: string): void {
    const clipboardBtn = document.querySelector<HTMLButtonElement>(identifier);
    const clipboard = new ClipboardJS(clipboardBtn, { text: () => code });
    clipboard.on("success", () => {
        tooltip(clipboardBtn, I18n.t("js.copy-success"));
    });
    clipboard.on("error", () => {
        tooltip(clipboardBtn, I18n.t("js.copy-fail"));
    });
}
