import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { customElement, property } from "lit/decorators.js";
import { html, TemplateResult, render } from "lit";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import "components/annotations/hidden_annotations_dot";
import "components/annotations/annotations_cell";
import "components/annotations/annotation_marker";
import { i18nMixin } from "components/meta/i18n_mixin";
import { initTooltips, sleep } from "util.js";
import { PropertyValues } from "@lit/reactive-element";
import { userState } from "state/Users";
import { AnnotationData, annotationState } from "state/Annotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { wrapRangesInHtml, range } from "mark";
import { SelectedRange, UserAnnotationData, userAnnotationState } from "state/UserAnnotations";
import { AnnotationMarker } from "components/annotations/annotation_marker";
import "components/annotations/selection_marker";
import "components/annotations/selection_tooltip";

function getOffset(e: Node, o: number): number | undefined {
    if (e.nodeName === "PRE") {
        return o;
    }

    const parent = e.parentNode;
    if (!parent) {
        return undefined;
    }

    let precedingText = "";
    for (const child of parent.childNodes) {
        if (child === e) {
            break;
        }
        if (child.nodeType !== Node.COMMENT_NODE) {
            precedingText += child.textContent;
        }
    }
    return getOffset(parent, o + precedingText.length);
}

function selectedRangeFromSelection(s: Selection): SelectedRange | undefined {
    // Selection.anchorNode does not behave as expected in firefox, see https://bugzilla.mozilla.org/show_bug.cgi?id=1420854
    // So we use the startContainer of the range instead
    const anchorNode = s.getRangeAt(0).startContainer;
    const focusNode = s.getRangeAt(s.rangeCount - 1).endContainer;
    const anchorOffset = s.getRangeAt(0).startOffset;
    const focusOffset = s.getRangeAt(s.rangeCount - 1).endOffset;

    const anchorRow = anchorNode?.parentElement.closest("d-code-listing-row") as CodeListingRow;
    const focusRow = focusNode?.parentElement.closest("d-code-listing-row") as CodeListingRow;
    const anchorColumn = getOffset(anchorNode, anchorOffset);
    const focusColumn = getOffset(focusNode, focusOffset);

    if (!anchorRow || !focusRow || anchorColumn === undefined || focusColumn === undefined) {
        return undefined;
    }

    let range: SelectedRange;
    if (anchorRow.row < focusRow.row) {
        range = {
            row: anchorRow.row,
            rows: focusRow.row - anchorRow.row + 1,
            column: anchorColumn,
            columns: focusColumn,
        };
    } else if (anchorRow.row > focusRow.row) {
        range = {
            row: focusRow.row,
            rows: anchorRow.row - focusRow.row + 1,
            column: focusColumn,
            columns: anchorColumn,
        };
    } else if (anchorColumn < focusColumn) {
        range = {
            row: anchorRow.row,
            rows: 1,
            column: anchorColumn,
            columns: focusColumn - anchorColumn,
        };
    } else {
        range = {
            row: anchorRow.row,
            rows: 1,
            column: focusColumn,
            columns: anchorColumn - focusColumn,
        };
    }

    if (range.columns === 0 && range.rows > 1) {
        range.columns = undefined;
        range.rows -= 1;
    }
    return range;
}

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

    async triggerSelectionEnd(): Promise<void> {
        console.log("triggerSelectionEnd");
        document.body.classList.remove("no-selection-outside-code");
        if (userAnnotationState.showForm) {
            return;
        }

        // Wait for the selection to be updated
        await sleep(10);
        const selection = window.getSelection();
        if (!selection.isCollapsed) {
            userAnnotationState.selectedRange = selectedRangeFromSelection(selection);
            if (userAnnotationState.selectedRange) {
                selection.removeAllRanges();
            }
        } else {
            userAnnotationState.selectedRange = undefined;
        }
    }

    triggerSelectionStart(e: PointerEvent): void {
        if (!(e.target as Element).closest(".annotation")) {
            console.log("triggerSelectionStart");
            document.body.classList.add("no-selection-outside-code");
        }
    }

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
        if (userAnnotationState.selectedRange && userAnnotationState.selectedRange.row <= this.row && userAnnotationState.selectedRange.row + (userAnnotationState.selectedRange.rows ?? 1) > this.row) {
            annotationsMarked = wrapRangesInHtml(annotationsMarked, [this.getRangeFromAnnotation(userAnnotationState.selectedRange)], "d-selection-marker");
        }
        return annotationsMarked;
    }

    firstUpdated(_changedProperties: PropertyValues): void {
        super.firstUpdated(_changedProperties);
        initTooltips(this);
        this.addEventListener("pointerup", () => this.triggerSelectionEnd());
        this.addEventListener("pointerdown", e => this.triggerSelectionStart(e));
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
                    ${this.canCreateAnnotation ? html`<d-selection-tooltip row="${this.row}"></d-selection-tooltip>` : html``}
                    <d-hidden-annotations-dot .row=${this.row}></d-hidden-annotations-dot>
                    <pre style="user-select: none;">${this.row}</pre>
                </td>
                <td class="rouge-code">
                    <pre class="code-line" style="overflow: visible; display: inline-block;">${unsafeHTML(this.wrappedCode)}</pre>
                    <d-annotations-cell .row=${this.row}
                                        .showForm="${this.showForm}"
                                        @close-form=${() => this.closeForm()}
                                        use-selection="true"
                    ></d-annotations-cell>
                </td>
            </tr>
        `;
    }
}
