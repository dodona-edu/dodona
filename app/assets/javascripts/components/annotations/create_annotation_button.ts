import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult, render } from "lit";
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


        return I18n.t(`js.annotations.options.add_${key}_for_selection`);

        // return I18n.t(`js.annotations.options.add_${key}`);
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
            !userAnnotationState.dragStart &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) - 1 == this.row;
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    get rowCharLength(): number {
        return this.row.toString().length;
    }

    dragStart(): void {
        userAnnotationState.selectedRange = {
            row: this.row,
            rows: 1,
        };
    }

    drag(): void {
        // updating userAnnotationState.dragStart triggers a rerender that hides this button,
        // doing this in dragStart would cause the button to disappear before the browser can make the pseudo image
        userAnnotationState.dragStart = this.row;
    }

    dragEnd(): void {
        this.openForm();
        userAnnotationState.dragStart = null;
    }

    protected render(): TemplateResult {
        return html`
            <div style="position: relative">
                <div class="drop-target-extension"></div>
                <div class="annotation-button ${this.rangeExists ? "hide" : "" } ${this.isRangeEnd ? "expanded" : ""}"
                     style="right: ${this.rowCharLength * 10 + 12}px;"
                     draggable="${!this.rangeExists}"
                     @dragstart=${() => this.dragStart()}
                     @dragend=${() => this.dragEnd()}
                     @drag="${() => this.drag()}"
                >
                    <button class="btn btn-fab-small-flex"
                            @pointerup=${() => this.openForm()}>
                        <span class="text">${this.addAnnotationTitle}</span>
                       <i class="mdi mdi-comment-plus-outline "></i>
                    </button>
                </div>
            </div>`;
    }
}
