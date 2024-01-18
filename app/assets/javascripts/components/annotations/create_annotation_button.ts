import { customElement, property } from "lit/decorators.js";
import { html, PropertyValues, TemplateResult } from "lit";
import { userAnnotationState } from "state/UserAnnotations";
import { initTooltips } from "utilities";
import { DodonaElement } from "components/meta/dodona_element";
import { i18n } from "i18n/i18n";

// The image has to be created before the event is fired
// otherwise safari will not create the drag image
const DRAG_IMAGE = document.createElement("img");
// Set image to a transparent 1x1px gif using data string
DRAG_IMAGE.src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7";

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
export class CreateAnnotationButton extends DodonaElement {
    @property({ type: Number })
    row: number;
    @property({ type: Boolean, attribute: "is-question-mode" })
    isQuestionMode: boolean;

    get buttonText(): string {
        const key = this.isQuestionMode ? "question" : "annotation";

        if (this.isDragStart) {
            return i18n.t(`js.annotations.options.add_${key}_drop`);
        }

        return i18n.t(`js.annotations.options.add_${key}`);
    }

    openForm(): void {
        userAnnotationState.formShown = true;
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
        return !userAnnotationState.formShown &&
            userAnnotationState.dragStartRow === null &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) - 1 == this.row;
    }

    get isDragStart(): boolean {
        return !userAnnotationState.formShown &&
            userAnnotationState.dragStartRow == this.row;
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);
        initTooltips(this);
    }

    get rowCharLength(): number {
        return this.row.toString().length;
    }

    dragStart(e: DragEvent): void {
        userAnnotationState.selectedRange = {
            row: this.row,
            rows: 1,
        };

        e.dataTransfer?.setDragImage(DRAG_IMAGE, 0, 0);
        userAnnotationState.dragStartRow = this.row;
    }

    dragEnd(): void {
        this.openForm();
        userAnnotationState.dragStartRow = null;
    }

    get buttonClasses(): string {
        let classes = "";
        if (this.rangeExists) {
            // If the range exists, the button should only be shown on the last row of the range
            // Or on the row where the drag started if the drag is still in progress
            if (this.isRangeEnd || this.isDragStart) {
                classes += "show expanded";
            } else {
                classes += "hide";
            }
        }

        if (userAnnotationState.isCreateButtonExpanded) {
            classes += " expanded";
        }

        return classes;
    }

    protected render(): TemplateResult {
        return html`
            <div style="position: relative">
                <div class="drop-target-extension"></div>
                <div class="annotation-button ${this.buttonClasses}"
                     style="right: ${this.rowCharLength * 10 + 12}px;"
                     draggable="${!this.rangeExists}"
                     @dragstart=${e => this.dragStart(e)}
                     @dragend=${() => this.dragEnd()}
                     @pointerover=${() => userAnnotationState.isCreateButtonExpanded = true}
                     @pointerout=${() => userAnnotationState.isCreateButtonExpanded = false}
                >
                    <a class="btn btn-fab-small-flex"
                            @pointerup=${() => this.openForm()}>
                        <span class="text">${this.buttonText}</span>
                       <i class="mdi mdi-comment-plus-outline "></i>
                    </a>
                </div>
            </div>`;
    }
}
