import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import { initTooltips } from "util";

@customElement("d-selection-tooltip")
export class SelectionTooltip extends ShadowlessLitElement {
    get addAnnotationTitle(): string {
        return annotationState.isQuestionMode ? I18n.t("js.annotations.options.add_question") : I18n.t("js.annotations.options.add_annotation");
    }

    openForm(): void {
        userAnnotationState.showForm = true;
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
    }

    protected render(): TemplateResult {
        return html`
            <div class="btn-group btn-toggle" role="group"  data-bs-toggle="buttons">
                <button class="btn"
                        @click=${() => this.openForm()}
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        title="${this.addAnnotationTitle}">
                    <i class="mdi mdi-comment-plus-outline"></i>
                </button>
                <button class="btn"
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        title="${I18n.t("js.code.copy-to-clipboard")}"
                        @click=${() => undefined}>
                    <i class="mdi mdi-clipboard-outline"></i>
                </button>
            </div>`;
    }
}
