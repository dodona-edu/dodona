import { MachineAnnotation } from "components/annotations/machine_annotation";
import { AnnotationType, UserAnnotation } from "components/annotations/user_annotation";


type Annotation = MachineAnnotation | UserAnnotation;
type OrderGroup = "error" | "conversation" | "warning" | "info";

// Map in which annotation group the annotation should appear.
const GROUP_MAPPING: Record<AnnotationType, OrderGroup> = {
    "error": "error",
    "user": "conversation",
    "warning": "warning",
    "info": "info",
    "question": "conversation"
};

// Order the groups. We use the same order as appearance in the mapping.
const GROUP_ORDER: OrderGroup[] = Array.from(new Set(Object.values(GROUP_MAPPING)));

export class CodeListing {
    private readonly annotations: Map<number, Annotation[]>;

    public readonly code: string;
    public readonly codeLines: number;
    public readonly submissionId: number;
    public readonly courseId: number | null;
    public readonly exerciseId: number;
    public readonly userId: number;

    private readonly markingClass: string = "marked";
    private evaluationId: number;

    private readonly badge: HTMLSpanElement;
    private readonly table: HTMLTableElement;

    private readonly globalAnnotations: HTMLDivElement;
    private readonly globalAnnotationGroups: HTMLDivElement;
    private readonly hideAllAnnotations: HTMLButtonElement;
    private readonly showAllAnnotations: HTMLButtonElement;
    private readonly showErrorAnnotations: HTMLButtonElement;
    private readonly annotationToggles: HTMLDivElement;

    private readonly questionMode: boolean;

    constructor(submissionId: number, courseId: number, exerciseId: number, userId: number, code: string, codeLines: number, questionMode = false) {
        this.annotations = new Map<number, Annotation[]>();
        this.code = code;
        this.codeLines = codeLines;
        this.submissionId = submissionId;
        this.courseId = courseId;
        this.exerciseId = exerciseId;
        this.userId = userId;
        this.questionMode = questionMode;

        this.badge = document.querySelector<HTMLSpanElement>(badge);
        this.table = document.querySelector<HTMLTableElement>("table.code-listing");

        this.hideAllAnnotations = document.querySelector<HTMLButtonElement>(annotationHideAll);
        this.showAllAnnotations = document.querySelector<HTMLButtonElement>(annotationShowAll);
        this.showErrorAnnotations = document.querySelector<HTMLButtonElement>(annotationShowErrors);
        this.annotationToggles = document.querySelector<HTMLDivElement>(annotationToggles);

        this.globalAnnotations = document.querySelector<HTMLDivElement>(annotationsGlobal);
        this.globalAnnotationGroups = document.querySelector<HTMLDivElement>(annotationsGlobalGroups);

        this.initAnnotations();
    }

    setEvaluation(id: number): void {
        this.evaluationId = id;
    }

    // /////////////////////////////////////////////////////////////////////////
    // Highlighting ////////////////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    clearHighlights(): void {
        const markedAnnotations = this.table.querySelectorAll(`tr.lineno.${this.markingClass}`);
        markedAnnotations.forEach(markedAnnotation => {
            markedAnnotation.classList.remove(this.markingClass);
        });
    }

    highlightLine(lineNr: number, scrollToLine = false): void {
        const toMarkAnnotationRow = this.table.querySelector(`tr.lineno#line-${lineNr}`);
        toMarkAnnotationRow.classList.add(this.markingClass);
        if (scrollToLine) {
            toMarkAnnotationRow.scrollIntoView({ block: "center" });
        }
    }

    // /////////////////////////////////////////////////////////////////////////
    // Annotation management ///////////////////////////////////////////////////
    // /////////////////////////////////////////////////////////////////////////

    public addAnnotation(annotation: Annotation, line: number): void {
        coline ??= 0;

        if (!this.annotations.has(line)) {
            this.annotations.set(line, []);
        }

        // Add the annotation in the map.
        this.annotations.get(line).push(annotation);

        // Append the HTML component of the annotation to the code table.
        if (annotation.global) {
            this.appendAnnotationToGlobal(annotation);
        } else {
            this.appendAnnotationToTable(annotation);
        }

        this.updateViewState();
    }
}
