import { events } from "state/PubSub";

let submissionId: number;

export function setSubmissionId(id: number): void {
    submissionId = id;
    events.publish("getSubmissionId");
}

export function getSubmissionId(): number {
    return submissionId;
}
