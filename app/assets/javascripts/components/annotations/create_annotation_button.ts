import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import { initTooltips } from "util.js";
import { submissionState } from "state/Submissions";
import { evaluationState } from "state/Evaluations";

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

    async createStrikeThrough(): Promise<void> {
        await userAnnotationState.create({
            line_nr: userAnnotationState.selectedRange.row,
            rows: userAnnotationState.selectedRange.rows,
            column: userAnnotationState.selectedRange.column,
            columns: userAnnotationState.selectedRange.columns,
            evaluation_id: evaluationState.id,
        }, submissionState.id, "strikethrough");

        userAnnotationState.selectedRange = undefined;
        window.getSelection()?.removeAllRanges();
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
        initTooltips();
    }

    get rowCharLength(): number {
        return this.row.toString().length;
    }

    protected render(): TemplateResult {
        return html`
            <div style="position: relative">
                <div class="annotation-buttons ${this.isRangeEnd ? "is-range-end" : ""} ${this.rangeExists ? "hide" : ""}">
                    <button class="btn btn-icon"
                            @pointerup=${() => this.openForm()}
                            data-bs-toggle="tooltip"
                            data-bs-placement="top"
                            data-bs-trigger="hover"
                            title="${this.addAnnotationTitle}">
                       <i class="mdi mdi-comment-plus-outline "></i>
                    </button>
                    ${ !this.rangeExists || annotationState.isQuestionMode ? "" : html`
                        <button class="btn btn-icon"
                               style="right: ${this.rowCharLength * 10 + 5}px"
                                @pointerup=${() => this.createStrikeThrough()}
                                data-bs-toggle="tooltip"
                                data-bs-placement="bottom"
                                data-bs-trigger="hover"
                                title="${I18n.t("js.annotations.options.add_strikethrough")}">
                           <i class="mdi mdi-format-strikethrough "></i>
                        </button>
                    `}
                </div>
            </div>`;
    }
}
