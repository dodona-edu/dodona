import { SelectedRange, userAnnotationState } from "state/UserAnnotations";
import { CodeListingRow } from "components/annotations/code_listing_row";

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

    // If we have selected nothing on the last row, we don't want to include that row
    // Instead end the selection on the last char of the previous row
    if (range.columns === 0 && range.rows > 1) {
        range.columns = undefined;
        range.rows -= 1;
    }
    return range;
}

export async function triggerSelectionEnd(): Promise<void> {
    document.body.classList.remove("no-selection-outside-code");
    if (userAnnotationState.showForm) {
        return;
    }

    // Wait for the selection to be updated
    await new Promise(resolve => setTimeout(resolve, 10));
    const selection = window.getSelection();
    if (!selection.isCollapsed) {
        userAnnotationState.selectedRange = selectedRangeFromSelection(selection);
    } else {
        userAnnotationState.selectedRange = undefined;
    }
}

export function triggerSelectionStart(e: PointerEvent): void {
    if (!(e.target as Element).closest(".annotation")) {
        document.body.classList.add("no-selection-outside-code");
    }
}
