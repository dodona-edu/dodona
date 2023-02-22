import { CodeListingRow } from "components/annotations/code_listing_row";
import { render } from "lit";
import { fetchUserAnnotations } from "state/UserAnnotations";
import { MachineAnnotationData, setMachineAnnotations } from "state/MachineAnnotations";
import { setCourseId } from "state/Courses";
import { setExerciseId } from "state/Exercises";
import { setUserId } from "state/Users";
import { getSubmissionId, setSubmissionId } from "state/Submissions";

export class CodeListing {
    public readonly code: string;
    public readonly codeLines: number;
    private evaluationId: number;

    private readonly questionMode: boolean;

    constructor(submissionId: number, courseId: number, exerciseId: number, userId: number, code: string, codeLines: number, questionMode = false) {
        this.code = code;
        this.codeLines = codeLines;
        this.questionMode = questionMode;
        setCourseId(courseId);
        setExerciseId(exerciseId);
        setUserId(userId);
        setSubmissionId(submissionId);


        this.initAnnotations();
    }

    setEvaluation(id: number): void {
        this.evaluationId = id;
    }

    private initAnnotations(): void {
        fetchUserAnnotations(getSubmissionId());
        const table = document.querySelector<HTMLTableElement>("table.code-listing");
        const rows = table.querySelectorAll("tr");

        for (let i = 0; i < rows.length; i++) {
            const code = rows[i].querySelector("td.rouge-code > pre").innerHTML;
            const codeListingRow = new CodeListingRow();
            codeListingRow.row = i + 1;
            codeListingRow.renderedCode = code;
            codeListingRow.questionMode = this.questionMode;
            codeListingRow.style = "display: contents;";
            rows[i].innerHTML = "";
            render(codeListingRow, rows[i]);
        }
    }

    public addMachineAnnotations(data: MachineAnnotationData[]): void {
        setMachineAnnotations(data);
    }

    public initAnnotateButtons(): void {
    }

    public loadUserAnnotations(): void {
    }

    public showAnnotations(): void {
    }
}
