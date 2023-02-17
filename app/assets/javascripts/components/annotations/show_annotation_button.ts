import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { stateMixin } from "state/StateMixin";
import { AnnotationVisibilityOptions, getAnnotationVisibility, setAnnotationVisibility } from "state/Annotations";

// TODO I18n
@customElement("d-show-annotation-buttons")
export class ShowAnnotationButtons extends stateMixin(ShadowlessLitElement) {
    @property({ type: String })
    visibility: AnnotationVisibilityOptions;

    state = ["getAnnotationVisibility"];

    get annotationVisibility(): AnnotationVisibilityOptions {
        return getAnnotationVisibility();
    }

    set annotationVisibility(value: AnnotationVisibilityOptions) {
        setAnnotationVisibility(value);
    }

    protected render(): TemplateResult {
        return html`
            <button class="btn annotation-toggle ${this.annotationVisibility === this.visibility ? "active" : ""}"
                    @click=${() => this.annotationVisibility = this.visibility}>
                <v-slot></v-slot>
            </button>
        `;
    }
}
