import { SelectedRange, userAnnotationState } from "state/UserAnnotations";
import { CodeListingRow } from "components/annotations/code_listing_row";

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

    if (!anchorRow || !focusRow) {
        return undefined;
    }

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
