import { MachineAnnotationData } from "state/MachineAnnotations";
import { UserAnnotationData } from "state/UserAnnotations";
import { LitState, stateVar } from "lit-element-state";

export type AnnotationVisibilityOptions = "all" | "important" | "none";

class AnnotationState extends LitState {
    @stateVar() visibility: AnnotationVisibilityOptions = "all";
    @stateVar() isQuestionMode = false;

    isVisible(annotation: MachineAnnotationData | UserAnnotationData): boolean {
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
