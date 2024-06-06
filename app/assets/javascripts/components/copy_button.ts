import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { initTooltips } from "utilities";
import { i18n } from "i18n/i18n";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * A button that copies the text content of a given element to the clipboard.
 * Alternatively, the text can be set directly.
 * The button is styled as a small icon button.
 * The button is a tooltip that shows the current status of the copy operation.
 *
 * @element d-copy-button
 *
 * @property {HTMLElement} target - The element whose text content is copied to the clipboard.
 * @property {string} targetId - The id of the element whose text content is copied to the clipboard.
 * @property {string} text - The text that is copied to the clipboard.
 */
@customElement("d-copy-button")
export class CopyButton extends DodonaElement {
    @property({ type: String, attribute: "target-id" })
    targetId: string;

    _target: HTMLElement;
    @property({ type: Object })
    get target(): HTMLElement {
        return this._target ?? document.getElementById(this.targetId);
    }

    set target(value: HTMLElement) {
        this._target = value;
    }

    _text: string;

    @property({ type: String })
    get text(): string {
        return this._text ?? this.target?.textContent;
    }

    set text(value: string) {
        this._text = value;
    }

    @property({ state: true })
    status: "idle" | "success" | "error" = "idle";

    async copyCode(): Promise<void> {
        try {
            await navigator.clipboard.writeText(this.text);
            this.status = "success";
        } catch (err) {
            if (this.target) {
                // Select the text in the code element so the user can copy it manually.
                window.getSelection().selectAllChildren(this.target);
                this.status = "error";
            } else {
                // rethrow the error if there is no target
                throw err;
            }
        }
    }

    get tooltip(): string {
        switch (this.status) {
        case "success":
            return i18n.t("js.copy-success");
        case "error":
            return i18n.t("js.copy-fail");
        default:
            return i18n.t("js.code.copy-to-clipboard");
        }
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    protected render(): TemplateResult {
        return html`<button class="btn btn-icon copy-btn"
                            @click=${() => this.copyCode()}
                            @focusout=${() => this.status = "idle"}
                            data-bs-placement="top"
                            data-bs-toggle="tooltip"
                            title="${this.tooltip}">
                <i class="mdi mdi-clipboard-outline"></i>
            </button>`;
    }
}
