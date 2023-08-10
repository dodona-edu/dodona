import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import "components/annotations/annotations_cell";
import "components/annotations/hidden_annotations_dot";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips } from "utilities";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { annotationState } from "state/Annotations";
import { userAnnotationState } from "state/UserAnnotations";
import "components/annotations/create_annotation_button";
import { triggerSelectionStart } from "components/annotations/selectionHelpers";
import "components/annotations/line_of_code";

/**
 * This component represents a row in the code listing.
 * It contains the line number and the code itself, and the button to add a new annotation for this row.
 * It also contains the annotations for this row.
 *
 * @element d-code-listing-row
 *
 * @prop {number} row - The row number.
 * @prop {string} renderedCode - The code to display.
 */
@customElement("d-code-listing-row")
export class CodeListingRow extends i18nMixin(ShadowlessLitElement) {
    @property({ type: Number })
    row: number;
    @property({ type: String, attribute: "rendered-code" })
    renderedCode: string;

    firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
        this.addEventListener("pointerdown", e => triggerSelectionStart(e));
    }

    get canCreateAnnotation(): boolean {
        return userState.hasPermission("annotation.create");
    }

    get formShown(): boolean {
        const range = userAnnotationState.selectedRange;
        return userAnnotationState.formShown && range && range.row + range.rows - 1 === this.row;
    }

    closeForm(): void {
        userAnnotationState.formShown = false;
        userAnnotationState.selectedRange = undefined;
    }

    dragEnter(e: DragEvent): void {
        if (userAnnotationState.dragStartRow === null) {
            return;
        }

        e.preventDefault();
        const origin = userAnnotationState.dragStartRow;
        const startRow = Math.min(origin, this.row);
        const endRow = Math.max(origin, this.row);

        userAnnotationState.selectedRange = {
            row: startRow,
            rows: endRow - startRow + 1
        };
    }

    render(): TemplateResult {
        return html`
            <tr id="line-${this.row}" class="lineno"
                @dragenter=${e => this.dragEnter(e)}
            >
                <td class="rouge-gutter gl">
                    ${this.canCreateAnnotation ? html`<d-create-annotation-button row="${this.row}" .isQuestionMode="${annotationState.isQuestionMode}" ></d-create-annotation-button>` : html``}
                    <d-hidden-annotations-dot .row=${this.row}></d-hidden-annotations-dot>
                    <pre style="user-select: none;">${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <d-line-of-code .row=${this.row} .renderedCode=${this.renderedCode}></d-line-of-code>
                    <d-annotations-cell .row=${this.row}
                                        .formShown="${this.formShown}"
                                        @close-form=${() => this.closeForm()}
                    ></d-annotations-cell>
                </td>
            </tr>
        `;
    }
}
