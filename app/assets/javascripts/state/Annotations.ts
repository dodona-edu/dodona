import { events } from "state/PubSub";


export type AnnotationVisibilityOptions = "all" | "important" | "none";
let annotationVisibility: AnnotationVisibilityOptions = "all";

export function setAnnotationVisibility(visibility: AnnotationVisibilityOptions): void {
    annotationVisibility = visibility;
    events.publish("getAnnotationVisibility");
}

export function getAnnotationVisibility(): AnnotationVisibilityOptions {
    return annotationVisibility;
}
