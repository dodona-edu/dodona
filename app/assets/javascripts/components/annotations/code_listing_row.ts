import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/annotations_cell";
import "components/annotations/annotation_marker";
import "components/annotations/hidden_annotations_dot";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips } from "util.js";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { AnnotationData, annotationState } from "state/Annotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { wrapRangesInHtml, range } from "mark";
import { SelectedRange, UserAnnotationData, userAnnotationState } from "state/UserAnnotations";
import { AnnotationMarker } from "components/annotations/annotation_marker";
import "components/annotations/selection_marker";
import "components/annotations/create_annotation_button";
import { triggerSelectionStart } from "components/annotations/select";

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
    @property({ type: String })
    renderedCode: string;


    /**
     * Calculates the range of the code that is covered by the given annotation.
     * If the annotation spans multiple lines, the range will be the whole line unless this is the first or last line.
     * In that case, the range will be the part of the line that is covered by the annotation.
     * @param annotation The annotation to calculate the range for.
     */
    getRangeFromAnnotation(annotation: AnnotationData | SelectedRange): range {
        const isMachineAnnotation = ["error", "warning", "info"].includes((annotation as AnnotationData).type);
        const rowsLength = annotation.rows ?? 1;
        let lastRow = annotation.row + rowsLength ?? 0;
        let firstRow = annotation.row + 1 ?? 0;

        if (!isMachineAnnotation) {
            // rows on user annotations are 1-based, so we need to subtract 1
            firstRow -= 1;
            lastRow -= 1;
        }

        let start = 0;
        if (this.row === firstRow) {
            start = annotation.column || 0;
        }

        let length = Infinity;
        if (this.row === lastRow) {
            if (annotation.column !== undefined && annotation.column !== null) {
                const defaultLength = isMachineAnnotation ? 0 : Infinity;
                length = annotation.columns || defaultLength;
            }
        }

        return { start: start, length: length, data: annotation };
    }

    get wrappedCode(): string {
        const annotationsToMark = [...this.userAnnotationsToMark, ...this.machineAnnotationsToMark];
        let annotationsMarked = wrapRangesInHtml(
            this.renderedCode,
            annotationsToMark.map(a => this.getRangeFromAnnotation(a)),
            "d-annotation-marker",
            (node: AnnotationMarker, range) => {
                // these nodes will be recompiled to html, so we need to store the data in a json string
                const annotations = JSON.parse(node.getAttribute("annotations")) || [];
                annotations.push(range.data);
                node.setAttribute("annotations", JSON.stringify(annotations));
            });
        if ( userAnnotationState.showForm && userAnnotationState.selectedRange && userAnnotationState.selectedRange.row <= this.row && userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) > this.row) {
            annotationsMarked = wrapRangesInHtml(annotationsMarked, [this.getRangeFromAnnotation(userAnnotationState.selectedRange)], "d-selection-marker");
        }
        return annotationsMarked;
    }

    firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
        this.addEventListener("pointerdown", e => triggerSelectionStart(e));
    }

    get canCreateAnnotation(): boolean {
        return userState.hasPermission("annotation.create");
    }

    get machineAnnotationsToMark(): MachineAnnotationData[] {
        return machineAnnotationState.byMarkedLine.get(this.row) || [];
    }

    get userAnnotationsToMark(): UserAnnotationData[] {
        return userAnnotationState.rootIdsByMarkedLine.get(this.row)?.map(i => userAnnotationState.byId.get(i)) || [];
    }

    get showForm(): boolean {
        const range = userAnnotationState.selectedRange;
        return userAnnotationState.showForm && range && range.row + range.rows - 1 === this.row;
    }

    closeForm(): void {
        userAnnotationState.showForm = false;
        userAnnotationState.selectedRange = undefined;
    }

    render(): TemplateResult {
        return html`
            <tr id="line-${this.row}" class="lineno">
                <td class="rouge-gutter gl">
                    ${this.canCreateAnnotation ? html`<d-create-annotation-button row="${this.row}"></d-create-annotation-button>` : html``}
                    <d-hidden-annotations-dot .row=${this.row}></d-hidden-annotations-dot>
                    <pre style="user-select: none;">${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre class="code-line">${unsafeHTML(this.wrappedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.closeForm()}
                    ></d-annotations-cell>
                </td>
            </tr>
        `;
    }
}
