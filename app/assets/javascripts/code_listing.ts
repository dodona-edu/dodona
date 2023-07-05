import { CodeListingRow } from "components/annotations/code_listing_row";
import { render } from "lit";
import { userAnnotationState } from "state/UserAnnotations";
import { MachineAnnotationData, machineAnnotationState } from "state/MachineAnnotations";
import { courseState } from "state/Courses";
import { userState } from "state/Users";
import { submissionState } from "state/Submissions";
import "components/annotations/annotation_options";
import "components/annotations/annotations_count_badge";
import { annotationState } from "state/Annotations";
import { exerciseState } from "state/Exercises";
import { triggerSelectionEnd } from "components/annotations/select";

const MARKING_CLASS = "marked";

function closeForm(e: PointerEvent): void {
    if (!(e.target as Element).closest("d-annotation-form") && !(e.target as Element).closest(".annotation-button")) {
        userAnnotationState.showForm = false;
        userAnnotationState.selectedRange = undefined;
        console.log("closeForm");
    }
}

export function registerCloseForm(): void {
    userAnnotationState.subscribe(() => {
        if (userAnnotationState.showForm && !userAnnotationState.formHasContent) {
            // if the form is shown and has no content, close it when clicking outside
            document.addEventListener("click", closeForm);
        } else {
            document.removeEventListener("click", closeForm);
        }
    }, new Set(["showForm", "formHasContent"]));
}

function initAnnotations(submissionId: number, courseId: number, exerciseId: number, userId: number, code: string, codeLines: number, questionMode = false): void {
    userAnnotationState.reset();
    submissionState.code = code;
    courseState.id = courseId;
    exerciseState.id = exerciseId;
    userState.id = userId;
    submissionState.id = submissionId;
    annotationState.isQuestionMode = questionMode;

    const table = document.querySelector<HTMLTableElement>("table.code-listing");
    const rows = table.querySelectorAll("tr");

    for (let i = 0; i < rows.length; i++) {
        const code = rows[i].querySelector("td.rouge-code > pre").innerHTML;
        const codeListingRow = new CodeListingRow();
        codeListingRow.row = i + 1;
        codeListingRow.renderedCode = code;
        render(codeListingRow, rows[i].parentElement, { renderBefore: rows[i] });
        rows[i].remove();
    }
}

function addMachineAnnotations(data: MachineAnnotationData[]): void {
    machineAnnotationState.setMachineAnnotations(data);
}

function initAnnotateButtons(): void {
    userState.addPermission("annotation.create");

    document.addEventListener("pointerup", () => triggerSelectionEnd());

    registerCloseForm();
}

function loadUserAnnotations(): void {
    userAnnotationState.fetch(submissionState.id);
    // only show important annotations if any user annotations exist
    annotationState.visibility = "important";
}


// /////////////////////////////////////////////////////////////////////////
// Highlighting ////////////////////////////////////////////////////////////
// /////////////////////////////////////////////////////////////////////////

function clearHighlights(): void {
    const markedAnnotations = document.querySelectorAll(`tr.lineno.${MARKING_CLASS}`);
    markedAnnotations.forEach(markedAnnotation => {
        markedAnnotation.classList.remove(MARKING_CLASS);
    });
}

function highlightLine(lineNr: number, scrollToLine = false): void {
    const toMarkAnnotationRow = document.querySelector(`tr.lineno#line-${lineNr}`);
    toMarkAnnotationRow.classList.add(MARKING_CLASS);
    if (scrollToLine) {
        toMarkAnnotationRow.scrollIntoView({ block: "center" });
    }
}

export default {
    initAnnotations,
    addMachineAnnotations,
    initAnnotateButtons,
    loadUserAnnotations,
    clearHighlights,
    highlightLine,
};
