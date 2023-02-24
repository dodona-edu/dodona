import { events } from "state/PubSub";
import { MachineAnnotationData } from "state/MachineAnnotations";
import { UserAnnotationData } from "state/UserAnnotations";


export type AnnotationVisibilityOptions = "all" | "important" | "none";
let annotationVisibility: AnnotationVisibilityOptions = "all";
let questionMode = false;

export function setAnnotationVisibility(visibility: AnnotationVisibilityOptions): void {
    annotationVisibility = visibility;
    events.publish("getAnnotationVisibility");
    events.publish("isAnnotationVisible");
}

export function getAnnotationVisibility(): AnnotationVisibilityOptions {
    return annotationVisibility;
}

export function isAnnotationVisible(annotation: MachineAnnotationData | UserAnnotationData): boolean {
    if (annotationVisibility === "none") {
        return false;
    }

    if (annotationVisibility === "important") {
        return annotation.type === "error" || annotation.type === "annotation" || annotation.type === "question";
    }

    return true;
}

export function setQuestionMode(mode: boolean): void {
    questionMode = mode;
    events.publish("getQuestionMode");
}

export function getQuestionMode(): boolean {
    return questionMode;
}
