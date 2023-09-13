import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { MachineAnnotation, machineAnnotationState } from "state/MachineAnnotations";
import { UserAnnotation, userAnnotationState } from "state/UserAnnotations";
import { Annotation, compareAnnotationOrders } from "state/Annotations";
import { submissionState } from "state/Submissions";
import "components/annotations/annotation_marker";
import "components/annotations/annotation_tooltip";
import "components/annotations/selection_layer";
import { unsafeHTML } from "lit/directives/unsafe-html.js";

declare type range = {
    start: number;
    length: number;
    annotations: Annotation[];
};

function numberArrayEquals(a: number[], b: number[]): boolean {
    return a.length === b.length && a.every((v, i) => v === b[i]);
}

/**
 * renders the code with formatting and tooltips split into four layers:
 *  - the background layer renders the markup for annotations on the code (background color and underline)
 *  - the selection layer renders the background color for the selection (split off because keeping selection logic separate from existing annotations makes it much faster)
 *  - the tooltip layer handles all pointer events (text selection and tooltips)
 *  - the text layer renders the code with syntax highlighting
 *
 * @prop {number} row - the row of the code to render
 * @prop {string} renderedCode - the syntax highlighted code to render
 *
 * @element d-code-listing
 */
@customElement("d-line-of-code")
export class LineOfCode extends ShadowlessLitElement {
    @property({ type: Number })
    row: number;
    @property({ type: String, attribute: "rendered-code" })
    renderedCode: string;

    get code(): string {
        return submissionState.codeByLine[this.row - 1];
    }

    get codeLength(): number {
        return this.code.length;
    }

    get machineAnnotationsToMark(): MachineAnnotation[] {
        return machineAnnotationState.byMarkedLine.get(this.row) || [];
    }

    get userAnnotationsToMark(): UserAnnotation[] {
        return userAnnotationState.rootIdsByMarkedLine.get(this.row)?.map(i => userAnnotationState.byId.get(i)) || [];
    }

    get fullLineAnnotations(): UserAnnotation[] {
        return this.userAnnotationsToMark
            .filter(a => !a.column && !a.columns)
            .sort(compareAnnotationOrders);
    }

    hasValidColumn(annotation: Annotation): boolean {
        return annotation.column !== undefined && annotation.column !== null && annotation.column >= 0 && annotation.column < this.codeLength;
    }

    /**
     * Calculates the range of the code that is covered by the given annotation.
     * If the annotation spans multiple lines, the range will be the whole line unless this is the first or last line.
     * In that case, the range will be the part of the line that is covered by the annotation.
     * @param annotation The annotation to calculate the range for.
     */
    getRangeFromAnnotation(annotation: Annotation, index: number): { start: number, length: number, index: number } {
        const isMachineAnnotation = ["error", "warning", "info"].includes(annotation.type);
        const rowsLength = annotation.rows ?? 1;
        let lastRow = annotation.row ? annotation.row + rowsLength : 0;
        let firstRow = annotation.row ? annotation.row + 1 : 0;

        if (!isMachineAnnotation) {
            // rows on user annotations are 1-based, so we need to subtract 1
            firstRow -= 1;
            lastRow -= 1;
        }

        let start = 0;
        if (this.row === firstRow) {
            // In rare cases, machine annotations start past the end of the line, resulting in errors if we don't constrain them to be in the line
            if (this.hasValidColumn(annotation)) {
                start = annotation.column;
            } else {
                start = 0;
            }
        }

        let length = this.codeLength - start;
        if (this.row === lastRow) {
            if (this.hasValidColumn(annotation)) {
                const defaultLength = isMachineAnnotation ? 0 : this.codeLength - start;
                length = annotation.columns || defaultLength;
            }
        }

        return { start: start, length: length, index: index };
    }

    mergeRanges(ranges: { start: number, length: number, index: number }[]): { start: number, length: number, indexes: number[] }[] {
        const annotationsByPosition: number[][] = new Array(this.codeLength).fill(null).map(() => []);
        for (const range of ranges) {
            for (let i = range.start; i < range.start + range.length; i++) {
                annotationsByPosition[i].push(range.index);
            }
        }

        const zeroLengthRanges = ranges.filter(range => range.length === 0);
        const zeroLengthIndexesByPosition: number[][] = new Array(this.codeLength+1).fill(null).map(() => []);
        for (const range of zeroLengthRanges) {
            zeroLengthIndexesByPosition[range.start].push(range.index);
        }

        const rangesToReturn = [];
        let i = 0;
        while (i < this.codeLength) {
            if (zeroLengthIndexesByPosition[i].length) {
                rangesToReturn.push({ start: i, length: 0, indexes: zeroLengthIndexesByPosition[i] });
            }
            let j = 1;
            while (i + j < this.codeLength && numberArrayEquals(annotationsByPosition[i + j], annotationsByPosition[i]) && !zeroLengthIndexesByPosition[i + j].length) {
                j++;
            }
            rangesToReturn.push({ start: i, length: j, indexes: annotationsByPosition[i] });
            i += j;
        }

        // Add the zero length ranges at the end of the line
        if (zeroLengthIndexesByPosition[this.codeLength].length) {
            rangesToReturn.push({ start: this.codeLength, length: 0, indexes: zeroLengthIndexesByPosition[this.codeLength] });
        }
        return rangesToReturn;
    }

    get ranges(): range[] {
        const toMark: Annotation[] = [...this.machineAnnotationsToMark, ...this.userAnnotationsToMark];
        // We use indexes to simplify the equality check in mergeRanges
        const ranges = toMark.map((annotation, index) => this.getRangeFromAnnotation(annotation, index));
        const mergedRanges = this.mergeRanges(ranges);
        return mergedRanges.map(range => {
            const annotations = range.indexes.map(i => toMark[i]);
            return { start: range.start, length: range.length, annotations: annotations };
        });
    }

    render(): TemplateResult {
        const backgroundLayer = [];
        const tooltipLayer = [];

        for (const range of this.ranges) {
            const substring = this.code.substring(range.start, range.start + range.length);
            if (!range.annotations.length) {
                backgroundLayer.push(substring);
                tooltipLayer.push(substring);
            } else {
                backgroundLayer.push(html`<d-annotation-marker .annotations=${range.annotations}>${substring}</d-annotation-marker>`);
                tooltipLayer.push(html`<d-annotation-tooltip .annotations=${range.annotations}>${substring}</d-annotation-tooltip>`);
            }
        }

        return html`
            <div class="code-layers">
                ${ this.fullLineAnnotations.length > 0 ? html`
                    <d-annotation-marker style="width: 100%; display: block" .annotations=${this.fullLineAnnotations}>
                        <pre class="code-line background-layer"><span></span>${backgroundLayer}</pre>
                    </d-annotation-marker>` : html`
                    <pre class="code-line background-layer">${backgroundLayer}</pre>
                `}
                <d-selection-layer .row=${this.row}></d-selection-layer>
                <pre class="code-line tooltip-layer">${tooltipLayer}</pre>
                <pre class="code-line text-layer">${unsafeHTML(this.renderedCode)}</pre>
            </div>`;
    }
}
