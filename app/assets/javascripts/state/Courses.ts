import { events } from "state/PubSub";

let courseId: number;

export function setCourseId(id: number): void {
    courseId = id;
    events.publish("getCourseId");
}

export function getCourseId(): number {
    return courseId;
}
