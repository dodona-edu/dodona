import { MachineAnnotationData } from "state/MachineAnnotations";
import { AnnotationType, UserAnnotationData } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

export type AnnotationVisibilityOptions = "all" | "important" | "none";
export type AnnotationData = MachineAnnotationData | UserAnnotationData;

const annotationOrder: Record<AnnotationType, number> = {
    annotation: 0,
    question: 1,
    error: 2,
    warning: 3,
    info: 4,
};

export function compareAnnotationOrders(a: AnnotationData, b: AnnotationData): number {
    return annotationOrder[a.type] - annotationOrder[b.type];
}

class AnnotationState extends State {
    @stateProperty visibility: AnnotationVisibilityOptions = "important";
    @stateProperty isQuestionMode = false;

    isVisible(annotation: AnnotationData): boolean {
        if (this.visibility === "none") {
            return false;
        }

        if (this.visibility === "important") {
            return annotation.type === "error" || annotation.type === "annotation" || annotation.type === "question";
        }

        return true;
    }
}

export const annotationState = new AnnotationState();
