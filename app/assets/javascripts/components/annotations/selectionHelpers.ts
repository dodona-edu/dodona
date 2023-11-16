import { SelectedRange, userAnnotationState } from "state/UserAnnotations";
import { CodeListingRow } from "components/annotations/code_listing_row";
import { annotationState } from "state/Annotations";
import { submissionState } from "state/Submissions";

/**
 * @param node The node to get the offset for
 * @param childIndex The offset within the current node
 *
 * @returns The offset in number of characters from the start of the `closest` PRE element
 * If the element is not inside a PRE element, returns undefined
 */
export function getOffset(node: Node, childIndex: number): number | undefined {
    let offset = 0;
    if (node.nodeType === Node.TEXT_NODE) {
        offset += childIndex;
    } else {
        let precedingText = "";
        for (let i = 0; i < node.childNodes.length && i < childIndex; i++) {
            const child = node.childNodes[i];
            if (child.nodeType !== Node.COMMENT_NODE) {
                precedingText += child.textContent;
            }
        }
        offset += precedingText.length;
    }

    if (node.nodeName === "PRE") {
        return offset;
    }

    const parent = node.parentNode;
    if (!parent) {
        return undefined;
    }
    const indexInParent = Array.from(parent.childNodes).indexOf(node as ChildNode);

    const offsetInParent = getOffset(parent, indexInParent);
    return offsetInParent !== undefined ? offsetInParent + offset: undefined;
}

/**
 * This function translates a selection into a range within the code listing.
 * If the selection is not inside a code listing row, returns undefined.
 *
 * If exact is false, the range will be expanded to include the entire row if the selection spans multiple rows.
 * In this case the selection param might be modified to match the returned range.
 *
 * @param selection The selection to get the range for
 * @param exact If false, the range will be expanded to include the entire row if the selection spans multiple rows
 * @returns The range of the selection in the code listing
 * Unless both the start and end of the selection are inside a code listing row, returns undefined
 */
export function selectedRangeFromSelection(selection: Selection, exact = false): SelectedRange | undefined {
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

    if ( exact ) {
        return range;
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
            newRange.setStart(startLine.querySelector(".tooltip-layer"), 0);
            newRange.setEnd(endLine.querySelector(".tooltip-layer"), endLine.querySelector(".tooltip-layer").childNodes.length);
            selection.addRange(newRange);
        } else {
            for (let i = range.row; i < range.row + range.rows; i++) {
                const newRange = new Range();
                const line = document.querySelector(`#line-${i}`);
                newRange.setStart(line.querySelector(".tooltip-layer"), 0);
                newRange.setEnd(line.querySelector(".tooltip-layer"), line.querySelector(".tooltip-layer").childNodes.length);
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

export function anyRangeInAnnotation(selection: Selection): boolean {
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
    document.body.classList.add("no-selection-inside-annotations");
}

function removeSelectionClasses(): void {
    document.querySelector(".code-table")?.classList.remove("selection-color-annotation", "selection-color-question");
    document.body.classList.remove("no-selection-outside-code");
    document.body.classList.remove("no-selection-inside-annotations");
}

export async function triggerSelectionEnd(): Promise<void> {
    if (userAnnotationState.formShown) {
        removeSelectionClasses();
        return;
    }

    // Wait for the selection to be updated
    await new Promise(resolve => setTimeout(resolve, 100));
    const selection = window.getSelection();
    if (!selection.isCollapsed && !anyRangeInAnnotation(selection)) {
        userAnnotationState.selectedRange = selectedRangeFromSelection(selection);
        if (userAnnotationState.selectedRange) {
            // we might not have started with the selection inside the code
            // But we ended with a code selection, so add the selection classes
            addSelectionClasses();
            // starting a new selection outside the code should be allowed
            document.body.classList.remove("no-selection-outside-code");

            // Next time the selection is changed, remove the selection classes
            const unsubscribe = userAnnotationState.subscribe( () => {
                removeSelectionClasses();
                unsubscribe();
            }, "selectedRange");
        } else {
            removeSelectionClasses();
        }
    } else {
        removeSelectionClasses();
        userAnnotationState.selectedRange = undefined;
    }
}

export function triggerSelectionStart(e: PointerEvent): void {
    if (e.pointerType === "mouse" && e.button !== 0) {
        // ignore all mouse events except left click
        return;
    }

    if (!(e.target as Element).closest(".annotation") && !userAnnotationState.formShown) {
        addSelectionClasses();
        // reset the selection, unless we are clicking on a button or link (eg. the create annotation button)
        if (!(e.target as Element).closest("button,a")) {
            userAnnotationState.selectedRange = undefined;
        }
    }
}
