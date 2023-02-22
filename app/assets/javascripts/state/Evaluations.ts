import { events } from "state/PubSub";

let evaluationId: number;

export function setEvaluationId(id: number): void {
    evaluationId = id;
    events.publish("getEvaluationId");
}

export function getEvaluationId(): number {
    return evaluationId;
}
