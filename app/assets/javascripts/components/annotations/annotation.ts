import { html, TemplateResult } from "lit";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";

/**
 *
 */
export abstract class Annotation extends ShadowlessLitElement {
    protected abstract get text(): TemplateResult | string | TemplateResult[];
    protected abstract get meta(): TemplateResult | string | TemplateResult[];
    protected abstract get class(): string;

    protected get buttons(): TemplateResult | TemplateResult[] {
        return html``;
    }

    protected get footer(): TemplateResult | TemplateResult[] {
        return html``;
    }

    render(): TemplateResult {
        return html`
            <div class="annotation ${this.class}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${this.meta}
                    </span>
                    ${this.buttons}
                    <v-slot name="buttons"></v-slot>
                </div>
                <div class="annotation-text">
                    ${this.text}
                </div>
                ${this.footer}
                <v-slot name="footer"></v-slot>
            </div>
        `;
    }
}
