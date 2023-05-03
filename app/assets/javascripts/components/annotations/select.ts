import { SelectedRange, userAnnotationState } from "state/UserAnnotations";
import { CodeListingRow } from "components/annotations/code_listing_row";
import { annotationState } from "state/Annotations";
import { submissionState } from "state/Submissions";

/**
 * @param node The node to get the offset for
 * @param offset The offset within the current node
 *
 * @returns The offset in number of characters from the start of the `closest` PRE element
 * If the element is not inside a PRE element, returns undefined
 */
function getOffset(node: Node, offset: number): number | undefined {
    if (node.nodeName === "PRE") {
        return offset;
    }

    const parent = node.parentNode;
    if (!parent) {
        return undefined;
    }

    let precedingText = "";
    for (const child of parent.childNodes) {
        if (child === node) {
            break;
        }
        if (child.nodeType !== Node.COMMENT_NODE) {
            precedingText += child.textContent;
        }
    }
    return getOffset(parent, offset + precedingText.length);
}

/**
 * This function translates a selection into a range within the code listing.
 * If the selection is not inside a code listing row, returns undefined.
 *
 * Multiline selections will always return the whole line for each line in the selection.
 * In this case the selection param might be modified to match the returned range.
 *
 * @param selection The selection to get the range for
 * @returns The range of the selection in the code listing
 * Unless both the start and end of the selection are inside a code listing row, returns undefined
 */
function selectedRangeFromSelection(selection: Selection): SelectedRange | undefined {
    // Selection.anchorNode does not behave as expected in firefox, see https://bugzilla.mozilla.org/show_bug.cgi?id=1420854
    // So we use the startContainer of the range instead
    const anchorNode = selection.getRangeAt(0).startContainer;
    const focusNode = selection.getRangeAt(selection.rangeCount - 1).endContainer;
    const anchorOffset = selection.getRangeAt(0).startOffset;
    const focusOffset = selection.getRangeAt(selection.rangeCount - 1).endOffset;

    const anchorRow = anchorNode?.parentElement.closest("d-code-listing-row") as CodeListingRow;
    const focusRow = focusNode?.parentElement.closest("d-code-listing-row") as CodeListingRow;

    // Both the start and end of the selection must be inside a code listing row to get a valid code selection
    if (!anchorRow || !focusRow) {
        return undefined;
    }

    // Find the exact position of the selection in the code `pre` element
    // If the selection is not inside a `pre` element, we assume the offset is zero
    const anchorColumn = getOffset(anchorNode, anchorOffset) || 0;
    const focusColumn = getOffset(focusNode, focusOffset) || 0;

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
    const codeLines = submissionState.code.split("\n");

    // If we have selected nothing on the last row, we don't want to include that row
    // Instead end the selection on the last char of the previous row
    if (range.columns === 0 && range.rows > 1) {
        range.columns = undefined;
        range.rows -= 1;
    }

    // If we selected multiple rows, we want to select the entire rows
    if (range.rows > 1) {
        // If we have selected nothing on the first row, we don't want to include that row
        while (codeLines[range.row - 1].length <= range.column && range.rows > 1) {
            range.column = 0;
            range.rows -= 1;
            range.row += 1;
        }

        // Ignore the columns if we have selected multiple rows
        range.column = 0;
        range.columns = undefined;

        // If we have selected nothing on the last row, we don't want to include that row
        while (codeLines[range.row + range.rows - 2] === "" && range.rows > 1) {
            range.rows -= 1;
        }

        // Update the selection to match the newly calculated Selected Range
        const numberOfRanges = selection.rangeCount;
        selection.removeAllRanges();

        // The number of ranges used is browser dependent
        // Chrome uses one range for the entire selection and filters out non selectable elements based on css
        // Firefox uses one range per continuous selection, but allows manual selection of non selectable elements
        // This code should be browser agnostic as it only returns multiple ranges if the selection is not continuous
        if (numberOfRanges == 1) {
            const newRange = new Range();
            const startLine = document.querySelector(`#line-${range.row}`);
            const endLine = document.querySelector(`#line-${range.row + range.rows - 1}`);
            newRange.setStart(startLine.querySelector(".code-line"), 0);
            newRange.setEnd(endLine.querySelector(".code-line"), endLine.querySelector(".code-line").childNodes.length);
            selection.addRange(newRange);
        } else {
            for (let i = range.row; i < range.row + range.rows; i++) {
                const newRange = new Range();
                const line = document.querySelector(`#line-${i}`);
                newRange.setStart(line.querySelector(".code-line"), 0);
                newRange.setEnd(line.querySelector(".code-line"), line.querySelector(".code-line").childNodes.length);
                selection.addRange(newRange);
            }
        }
    }

    return range;
}

function rangeInAnnotation(range: Range): boolean {
    const annotation = (range.startContainer.parentElement as Element)?.closest(".annotation") ||
        (range.endContainer.parentElement as Element)?.closest(".annotation");
    return annotation !== null;
}

function anyRangeInAnnotation(selection: Selection): boolean {
    for (let i = 0; i < selection.rangeCount; i++) {
        if (rangeInAnnotation(selection.getRangeAt(i))) {
            return true;
        }
    }
    return false;
}

function addSelectionClasses(): void {
    const selectionType = annotationState.isQuestionMode ? "question" : "annotation";
    document.querySelector(".code-table")?.classList.add(`selection-color-${selectionType}`);
    document.body.classList.add("no-selection-outside-code");
}

function removeSelectionClasses(): void {
    document.querySelector(".code-table")?.classList.remove("selection-color-annotation", "selection-color-question");
    document.body.classList.remove("no-selection-outside-code");
}

export async function triggerSelectionEnd(): Promise<void> {
    if (userAnnotationState.showForm) {
        removeSelectionClasses();
        return;
    }

    // Wait for the selection to be updated
    await new Promise(resolve => setTimeout(resolve, 100));
    const selection = window.getSelection();
    if (!selection.isCollapsed && !anyRangeInAnnotation(selection)) {
        userAnnotationState.selectedRange = selectedRangeFromSelection(selection);
        if (userAnnotationState.selectedRange) {
            addSelectionClasses();
        } else {
            removeSelectionClasses();
        }
    } else {
        removeSelectionClasses();
        userAnnotationState.selectedRange = undefined;
    }
}

export function triggerSelectionStart(e: PointerEvent): void {
    if (!(e.target as Element).closest(".annotation") && !userAnnotationState.showForm) {
        addSelectionClasses();
        if (!(e.target as Element).closest("button")) {
            userAnnotationState.selectedRange = undefined;
        }
    }
}
