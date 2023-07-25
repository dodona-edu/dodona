import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult } from "lit";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { SelectedRange, UserAnnotationData, userAnnotationState } from "state/UserAnnotations";
import { AnnotationData } from "state/Annotations";
import { submissionState } from "state/Submissions";

declare type range = {
    start: number;
    length: number;
    annotations: (AnnotationData | SelectedRange)[];
};

function numberArrayEquals(a: number[], b: number[]): boolean {
    return a.length === b.length && a.every((v, i) => v === b[i]);
}

@customElement("d-marking-layer")
export class MarkingLayer extends ShadowlessLitElement {
    @property({ type: Number })
    row: number;

    get code(): string {
        return submissionState.codeByLine[this.row - 1];
    }

    get codeLength(): number {
        return this.code.length;
    }

    get machineAnnotationsToMark(): MachineAnnotationData[] {
        return machineAnnotationState.byMarkedLine.get(this.row) || [];
    }

    get userAnnotationsToMark(): UserAnnotationData[] {
        return userAnnotationState.rootIdsByMarkedLine.get(this.row)?.map(i => userAnnotationState.byId.get(i)) || [];
    }

    get shouldMarkSelection(): boolean {
        return userAnnotationState.selectedRange &&
            userAnnotationState.selectedRange.row <= this.row &&
            userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) > this.row;
    }

    /**
     * Calculates the range of the code that is covered by the given annotation.
     * If the annotation spans multiple lines, the range will be the whole line unless this is the first or last line.
     * In that case, the range will be the part of the line that is covered by the annotation.
     * @param annotation The annotation to calculate the range for.
     */
    getRangeFromAnnotation(annotation: AnnotationData | SelectedRange, index: number): { start: number, length: number, index: number } {
        const isMachineAnnotation = ["error", "warning", "info"].includes((annotation as AnnotationData).type);
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
            start = annotation.column || 0;
        }

        let length = this.codeLength - start;
        if (this.row === lastRow) {
            if (annotation.column !== undefined && annotation.column !== null) {
                const defaultLength = isMachineAnnotation ? 0 : this.codeLength - start;
                length = annotation.columns || defaultLength;
            }
        }

        return { start: start, length: length, index: index };
    }

    mergeRanges(ranges: { start: number, length: number, index: number }[]): { start: number, length: number, indexes: number[] }[] {
        console.log("merge_ranges", this.row, ranges);
        const annotationsByPosition: number[][] = new Array(this.codeLength).fill(null).map(() => []);
        for (const range of ranges) {
            for (let i = range.start; i < range.start + range.length; i++) {
                annotationsByPosition[i].push(range.index);
            }
        }
        const rangesToReturn = [];
        let i = 0;
        while (i < this.codeLength) {
            let j = 1;
            while (i + j < this.codeLength && numberArrayEquals(annotationsByPosition[i + j], annotationsByPosition[i])) {
                j++;
            }
            rangesToReturn.push({ start: i, length: j, indexes: annotationsByPosition[i] });
            i += j;
        }
        return rangesToReturn;
    }

    get ranges(): range[] {
        const toMark: (AnnotationData | SelectedRange)[] = [...this.machineAnnotationsToMark, ...this.userAnnotationsToMark];
        if (this.shouldMarkSelection) {
            toMark.push(userAnnotationState.selectedRange);
        }
        console.log("to_mark", this.row, toMark);
        // We use indexes to simplify the equality check in mergeRanges
        const ranges = toMark.map((annotation, index) => this.getRangeFromAnnotation(annotation, index));
        const mergedRanges = this.mergeRanges(ranges);
        return mergedRanges.map(range => {
            const annotations = range.indexes.map(i => toMark[i]);
            return { start: range.start, length: range.length, annotations: annotations };
        });
    }

    render(): TemplateResult {
        console.log(this.row, this.ranges);
        return html`${this.ranges.map(range => range.annotations.length ?
            html`<d-annotation-marker .annotations=${range.annotations}>${this.code.substring(range.start, range.start + range.length)}</d-annotation-marker>` :
            html`${this.code.substring(range.start, range.start + range.length)}`)}`;
    }
}
