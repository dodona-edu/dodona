import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { initTooltips } from "utilities";
import { i18n } from "i18n/i18n";
import { DodonaElement } from "components/meta/dodona_element";
import { userAnnotationState } from "state/UserAnnotations";

/**
 * A button that copies the text content of a given element to the clipboard.
 * Alternatively, the code can be set directly.
 * The button is styled as a small icon button.
 * The button is a tooltip that shows the current status of the copy operation.
 *
 * @element d-copy-button
 *
 * @property {HTMLElement} codeElement - The element whose text content is copied to the clipboard.
 * @property {string} code - The code that is copied to the clipboard.
 */
@customElement("d-copy-button")
export class CopyButton extends DodonaElement {
    @property({ type: Object })
    codeElement: HTMLElement;
    _code: string;

    @property({ type: String })
    get code(): string {
        return this._code ?? this.codeElement?.textContent;
    }

    set code(value: string) {
        this._code = value;
    }

    @property({ state: true })
    status: "idle" | "success" | "error" = "idle";

    async copyCode(): Promise<void> {
        try {
            await navigator.clipboard.writeText(this.code);
            this.status = "success";
        } catch (err) {
            if (this.codeElement) {
                // Select the text in the code element so the user can copy it manually.
                window.getSelection().selectAllChildren(this.codeElement);
            } else {
                // no element is given for the more complex code listings
                // use the userAnnotationState to select the text
                userAnnotationState.selectedRange = {
                    row: 0,
                    rows: this._code.split("\n").length
                };
            }
            this.status = "error";
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
