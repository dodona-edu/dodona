import ClipboardJS from "clipboard";
import { ready, tooltip } from "util.js";

export async function initClipboard(): Promise<void> {
    await ready;
    const selector = ".btn";
    const clip = new ClipboardJS(selector);
    const targetOf = (e): Element => document.querySelector(e.trigger.dataset["clipboard-target"]);
    clip.on("success", e => tooltip(targetOf(e), I18n.t("js.copy-success")));
    clip.on("error", e => tooltip(targetOf(e), I18n.t("js.copy-fail")));
}

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
