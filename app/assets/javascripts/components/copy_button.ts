import { ShadowlessLitElement } from "components/shadowless_lit_element";
import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { initTooltips, ready } from "util.js";

@customElement("d-copy-button")
export class CopyButton extends ShadowlessLitElement {
    @property({ type: Object })
    codeElement: HTMLElement;

    get code(): string {
        return this.codeElement.textContent;
    }

    @property({ state: true })
    status: "idle" | "success" | "error" = "idle";

    async copyCode(): Promise<void> {
        try {
            await navigator.clipboard.writeText(this.code);
            this.status = "success";
        } catch (err) {
            window.getSelection().selectAllChildren(this.codeElement);
            this.status = "error";
        }
    }

    get tooltip(): string {
        switch (this.status) {
        case "success":
            return I18n.t("js.copy-success");
        case "error":
            return I18n.t("js.copy-fail");
        default:
            return I18n.t("js.code.copy-to-clipboard");
        }
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    constructor() {
        super();

        // Reload when I18n is loaded
        ready.then(() => this.requestUpdate());
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
