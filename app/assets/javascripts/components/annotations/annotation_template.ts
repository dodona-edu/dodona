import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";

/**
 *
 */
@customElement("d-annotation-template")
export class AnnotationTemplate extends ShadowlessLitElement {
    @property({ type: String })
    type = "";

    render(): TemplateResult {
        return html`
            <div class="annotation ${this.type}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        <v-slot name="meta"></v-slot>
                    </span>
                    <v-slot name="buttons"></v-slot>
                </div>
                <div class="annotation-text">
                    <v-slot name="text"></v-slot>
                </div>
            </div>
        `;
    }
}
