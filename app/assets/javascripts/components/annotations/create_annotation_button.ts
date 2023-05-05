import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import { initTooltips } from "util.js";

/**
 * This component represents a button to create a new annotation.
 * It is displayed in the gutter of the code editor.
 * It will only display on the last row that is currently selected if any code is selected.
 *
 * @attr {number} row - The row number.
 *
 * @element d-create-annotation-button
 */
@customElement("d-create-annotation-button")
export class CreateAnnotationButton extends ShadowlessLitElement {
    @property({ type: Number })
    row: number;

    get addAnnotationTitle(): string {
        const key = annotationState.isQuestionMode ? "question" : "annotation";

        if (this.isRangeEnd) {
            return I18n.t(`js.annotations.options.add_${key}_for_selection`);
        }

        return I18n.t(`js.annotations.options.add_${key}`);
    }

    openForm(): void {
        userAnnotationState.showForm = true;
        if (!this.rangeExists) {
            userAnnotationState.selectedRange = {
                row: this.row,
                rows: 1,
            };
        } else {
            window.getSelection()?.removeAllRanges();
        }
    }

    get rangeExists(): boolean {
        return userAnnotationState.selectedRange !== undefined && userAnnotationState.selectedRange !== null;
    }

    get isRangeEnd(): boolean {
        return this.rangeExists && !userAnnotationState.showForm &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) - 1 == this.row;
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    get rowCharLength(): number {
        return this.row.toString().length;
    }

    protected render(): TemplateResult {
        return html`
            <div style="position: relative">
                ${this.isRangeEnd ? html`
                    <button class="btn annotation-button is-range-end with-icon btn-text btn-elevated "
                           style="right: ${this.rowCharLength * 10 + 5}px"
                            @pointerup=${() => this.openForm()}>
                       <i class="mdi mdi-comment-plus-outline "></i>
                        ${this.isRangeEnd ? this.addAnnotationTitle : ""}
                    </button>
                ` : html`
                    <button class="btn annotation-button btn-icon btn-elevated  ${this.rangeExists ? "hide" : ""}"
                           style="right: ${this.rowCharLength * 10 + 5}px"
                            @pointerup=${() => this.openForm()}
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${this.addAnnotationTitle}">
                       <i class="mdi mdi-comment-plus-outline "></i>
                    </button>
                `}
            </div>`;
    }
}
