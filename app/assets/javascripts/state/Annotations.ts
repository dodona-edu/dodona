import { MachineAnnotation } from "state/MachineAnnotations";
import { AnnotationType, UserAnnotation } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

export type AnnotationVisibilityOptions = "all" | "important" | "none";
export type Annotation = MachineAnnotation | UserAnnotation;

const annotationOrder: Record<AnnotationType, number> = {
    annotation: 0,
    question: 1,
    strikethrough: 2,
    error: 3,
    warning: 4,
    info: 5,
};

export function compareAnnotationOrders(a: Annotation, b: Annotation): number {
    return annotationOrder[a.type] - annotationOrder[b.type];
}

export function isUserAnnotation(annotation: Annotation): annotation is UserAnnotation {
    return annotation.type === "annotation" || annotation.type === "question" || annotation.type === "strikethrough";
}

class AnnotationState extends State {
    @stateProperty visibility: AnnotationVisibilityOptions = "all";
    @stateProperty isQuestionMode = false;

    isVisible(annotation: Annotation): boolean {
        if (this.visibility === "none") {
            return false;
        }

        if (this.visibility === "important") {
            return annotation.type === "error" || annotation.type === "annotation" || annotation.type === "question" || annotation.type === "strikethrough";
        }

        return true;
    }
}

export const annotationState = new AnnotationState();
