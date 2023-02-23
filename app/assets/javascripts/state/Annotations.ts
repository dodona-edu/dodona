import { events } from "state/PubSub";


export type AnnotationVisibilityOptions = "all" | "important" | "none";
let annotationVisibility: AnnotationVisibilityOptions = "all";
let questionMode = false;

export function setAnnotationVisibility(visibility: AnnotationVisibilityOptions): void {
    annotationVisibility = visibility;
    events.publish("getAnnotationVisibility");
}

export function getAnnotationVisibility(): AnnotationVisibilityOptions {
    return annotationVisibility;
}

export function setQuestionMode(mode: boolean): void {
    questionMode = mode;
    events.publish("getQuestionMode");
}

export function getQuestionMode(): boolean {
    return questionMode;
}
