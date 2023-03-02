import { CodeListingRow } from "components/annotations/code_listing_row";
import { render } from "lit";
import { fetchUserAnnotations } from "state/UserAnnotations";
import { MachineAnnotationData, setMachineAnnotations } from "state/MachineAnnotations";
import { setCourseId } from "state/Courses";
import { setExerciseId } from "state/Exercises";
import { addPermission, setUserId } from "state/Users";
import { getSubmissionId, setCode, setSubmissionId } from "state/Submissions";
import { setQuestionMode } from "state/Annotations";
import "components/annotations/annotation_options";
import "components/annotations/annotations_count_badge";

const MARKING_CLASS = "marked";

export const codeListing = {
    initAnnotations(submissionId: number, courseId: number, exerciseId: number, userId: number, code: string, codeLines: number, questionMode = false): void {
        setCode(code);
        setCourseId(courseId);
        setExerciseId(exerciseId);
        setUserId(userId);
        setSubmissionId(submissionId);
        setQuestionMode(questionMode);

        const table = document.querySelector<HTMLTableElement>("table.code-listing");
        const rows = table.querySelectorAll("tr");

        for (let i = 0; i < rows.length; i++) {
            const code = rows[i].querySelector("td.rouge-code > pre").innerHTML;
            const codeListingRow = new CodeListingRow();
            codeListingRow.row = i + 1;
            codeListingRow.renderedCode = code;
            codeListingRow.style = "display: contents;";
            rows[i].innerHTML = "";
            render(codeListingRow, rows[i]);
        }
    },

    addMachineAnnotations(data: MachineAnnotationData[]): void {
        setMachineAnnotations(data);
    },

    initAnnotateButtons(): void {
        addPermission("annotation.create");
    },

    loadUserAnnotations(): void {
        fetchUserAnnotations(getSubmissionId());
    },


    // /////////////////////////////////////////////////////////////////////////
    // Highlighting ////////////////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    clearHighlights(): void {
        const markedAnnotations = document.querySelectorAll(`tr.lineno.${MARKING_CLASS}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    },

    highlightLine(lineNr: number, scrollToLine = false): void {
        const toMarkAnnotationRow = document.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(MARKING_CLASS);
        if (scrollToLine) {
            toMarkAnnotationRow.scrollIntoView({ block: "center" });
        }
    }
};
