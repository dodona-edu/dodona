import { events } from "state/PubSub";

let submissionId: number;
let _code: string;

export function setSubmissionId(id: number): void {
    submissionId = id;
    events.publish("getSubmissionId");
}

export function getSubmissionId(): number {
    return submissionId;
}

export function setCode(code: string): void {
    _code = code;
    events.publish("getCode");
}

export function getCode(): string {
    return _code;
}
