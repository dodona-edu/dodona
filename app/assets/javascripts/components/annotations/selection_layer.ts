import { html, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { userAnnotationState } from "state/UserAnnotations";
import { submissionState } from "state/Submissions";
import { annotationState } from "state/Annotations";
import { DodonaElement } from "components/meta/dodona_element";

/**
 * A separate layer that contains the marking for the selection.
 * It is separate from code-layers to make the rendering independent and thus much faster.
 *
 * The selected code is styled to look like a user annotation.
 * It is used to mark the selected code while editing an annotation
 * @element d-selection-layer
 */
@customElement("d-selection-layer")
class SelectionLayer extends DodonaElement {
    @property({ type: Number })
    row: number;

    get code(): string {
        return submissionState.codeByLine[this.row - 1];
    }


    get shouldMarkSelection(): boolean {
        return userAnnotationState.selectedRange &&
            userAnnotationState.selectedRange.row <= this.row &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) > this.row;
    }

    get markingClass(): string {
        return annotationState.isQuestionMode ? "question-selection-marker" : "annotation-selection-marker";
    }

    render(): TemplateResult {
        if (!this.shouldMarkSelection) {
            return html``;
        }
        if (!userAnnotationState.selectedRange.column && !userAnnotationState.selectedRange.columns) {
            return html`<pre class="code-line selection-layer ${this.markingClass}">${this.code}</pre>`;
        }

        const start = userAnnotationState.selectedRange.column ?? 0;
        const end = userAnnotationState.selectedRange.columns ? start + userAnnotationState.selectedRange.columns : this.code.length;

        const selectionLayer: (TemplateResult | string)[] = [
            html`<span></span>`, // this is a hack to force the height of the line to be correct even if no code is on this line
            this.code.substring(0, start),
            html`<span class="${this.markingClass}">${this.code.substring(start, end)}</span>`,
            this.code.substring(end)
        ];

        return html`<pre class="code-line selection-layer">${selectionLayer}</pre>`;
    }
}
