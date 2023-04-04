import { CodeListingRow } from "components/annotations/code_listing_row";
import { render } from "lit";
import { fetchUserAnnotations } from "state/UserAnnotations";
import { MachineAnnotationData, setMachineAnnotations } from "state/MachineAnnotations";
import { courseState } from "state/Courses";
import { addPermission, setUserId } from "state/Users";
import { getSubmissionId, setCode, setSubmissionId } from "state/Submissions";
import "components/annotations/annotation_options";
import "components/annotations/annotations_count_badge";
import { annotationState } from "state/Annotations";
import { exerciseState } from "state/Exercises";

const MARKING_CLASS = "marked";

function initAnnotations(submissionId: number, courseId: number, exerciseId: number, userId: number, code: string, codeLines: number, questionMode = false): void {
    setCode(code);
    courseState.id = courseId;
    exerciseState.id = exerciseId;
    setUserId(userId);
    setSubmissionId(submissionId);
    annotationState.isQuestionMode = questionMode;

    const table = document.querySelector<HTMLTableElement>("table.code-listing");
    const rows = table.querySelectorAll("tr");

    for (let i = 0; i < rows.length; i++) {
        const code = rows[i].querySelector("td.rouge-code > pre").innerHTML;
        const codeListingRow = new CodeListingRow();
        codeListingRow.row = i + 1;
        codeListingRow.renderedCode = code;
        rows[i].innerHTML = "";
        render(codeListingRow, rows[i]);
    }
}

function addMachineAnnotations(data: MachineAnnotationData[]): void {
    setMachineAnnotations(data);
}

function initAnnotateButtons(): void {
    addPermission("annotation.create");
}

function loadUserAnnotations(): void {
    fetchUserAnnotations(getSubmissionId());
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
