import { MachineAnnotationData } from "state/MachineAnnotations";
import { UserAnnotationData } from "state/UserAnnotations";
import { State } from "state/state_system/State";
import { stateProperty } from "state/state_system/StateProperty";

export type AnnotationVisibilityOptions = "all" | "important" | "none";

class AnnotationState extends State {
    @stateProperty visibility: AnnotationVisibilityOptions = "none";
    @stateProperty isQuestionMode = false;

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
