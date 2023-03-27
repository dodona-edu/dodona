import { events } from "state/PubSub";

let exerciseId: number;

export function setExerciseId(id: number): void {
    exerciseId = id;
    events.publish("getExerciseId");
}

export function getExerciseId(): number {
    return exerciseId;
}
