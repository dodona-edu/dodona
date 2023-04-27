import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import { initTooltips } from "util.js";

@customElement("d-selection-tooltip")
export class SelectionTooltip extends ShadowlessLitElement {
    @property({ type: Number })
    row: number;

    get addAnnotationTitle(): string {
        return annotationState.isQuestionMode ? I18n.t("js.annotations.options.add_question") : I18n.t("js.annotations.options.add_annotation");
    }

    openForm(): void {
        userAnnotationState.showForm = true;
        if (!this.rangeExists) {
            userAnnotationState.selectedRange = {
                row: this.row,
                rows: 1,
            };
        }
    }

    get rangeExists(): boolean {
        return userAnnotationState.selectedRange !== undefined && userAnnotationState.selectedRange !== null;
    }

    get isRangeEnd(): boolean {
        return this.rangeExists &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) - 1 == this.row;
    }

    protected firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
    }

    protected render(): TemplateResult {
        return html`
               <button class="btn btn-icon annotation-button ${this.isRangeEnd ? "is-range-end" : ""} ${this.rangeExists ? "hide" : ""}"
                       style="${this.row >= 10 ? "left: -22px;" : "left: -12px;"}"
                        @pointerup=${() => this.openForm()}
                        data-bs-toggle="tooltip"
                        data-bs-placement="top"
                        data-bs-trigger="hover"
                        title="${this.addAnnotationTitle}">
                    <i class="mdi mdi-comment-plus-outline"></i>
                </button>`;
    }
}
