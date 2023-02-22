import { fetch } from "util.js";
import { events } from "state/PubSub";
import { Notification } from "notification";

export interface UserAnnotationFormData {
    // eslint-disable-next-line camelcase
    annotation_text: string;
    // eslint-disable-next-line camelcase
    line_nr?: number | null;
    // eslint-disable-next-line camelcase
    evaluation_id?: number | undefined;
    // eslint-disable-next-line camelcase
    saved_annotation_id?: string;
}

export type QuestionState = "unanswered" | "answered" | "in_progress";
export type AnnotationType = "error" | "info" | "user" | "warning" | "question";

interface UserAnnotationUserData {
    name: string;
}

export interface UserAnnotationPermissionData {
    update: boolean;
    destroy: boolean;
    can_see_annotator: boolean
}

export interface UserAnnotationData {
    // eslint-disable-next-line camelcase
    annotation_text: string;
    // eslint-disable-next-line camelcase
    created_at: string;
    id: number;
    // eslint-disable-next-line camelcase
    line_nr: number;
    permission: UserAnnotationPermissionData;
    released: boolean;
    // eslint-disable-next-line camelcase
    rendered_markdown: string;
    // eslint-disable-next-line camelcase
    evaluation_id: number | null;
    // eslint-disable-next-line camelcase
    saved_annotation_id: number | null;
    url: string;
    user: UserAnnotationUserData;
    type: AnnotationType;
    // eslint-disable-next-line camelcase
    last_updated_by: UserAnnotationUserData;
    // REMOVE AFTER CLOSED BETA
    // eslint-disable-next-line camelcase
    course_id: number;
    // eslint-disable-next-line camelcase
    question_state?: QuestionState;
    // eslint-disable-next-line camelcase
    newer_submission_url?: string | null;
}

const userAnnotationsByLine = new Map<number, UserAnnotationData[]>();

function addAnnotationToMap(annotation: UserAnnotationData): void {
    const line = annotation.line_nr ?? 0;
    if (userAnnotationsByLine.has(line)) {
        userAnnotationsByLine.get(line)?.push(annotation);
    } else {
        userAnnotationsByLine.set(line, [annotation]);
    }
}

export async function fetchUserAnnotations(submissionId: number): Promise<UserAnnotationData[]> {
    const response = await fetch(`/submissions/${submissionId}/annotations.json`);
    const json = await response.json();

    userAnnotationsByLine.clear();
    for (const annotation of json) {
        addAnnotationToMap(annotation);
    }
    events.publish("getUserAnnotations");
    console.log("user annotations loaded", userAnnotationsByLine);
    return json;
}

export async function createUserAnnotation(formData: UserAnnotationFormData, submissionId: number, mode = "annotation"): Promise<void> {
    const response = await fetch(`/submissions/${submissionId}/annotations.json`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ [mode]: formData })
    });
    const data = await response.json();

    if (response.ok) {
        if (mode === "question") {
            Notification.startNotificationRefresh();
        }
        addAnnotationToMap(data);
        events.publish("getUserAnnotations");
        return;
    }
    throw new Error();
}


export function getUserAnnotationsByLine(line: number): UserAnnotationData[] {
    return userAnnotationsByLine.get(line) ?? [];
}
