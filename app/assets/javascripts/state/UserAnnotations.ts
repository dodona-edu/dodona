import { fetch } from "util.js";
import { Notification } from "notification";
import { savedAnnotationState } from "state/SavedAnnotations";
import { State } from "state/state_system/State";
import { StateMap } from "state/state_system/StateMap";

export interface UserAnnotationFormData {
    // eslint-disable-next-line camelcase
    annotation_text: string;
    // eslint-disable-next-line camelcase
    line_nr?: number | null;
    // eslint-disable-next-line camelcase
    evaluation_id?: number | undefined;
    // eslint-disable-next-line camelcase
    saved_annotation_id?: number | null;
    // eslint-disable-next-line camelcase
    thread_root_id?: number | null;
}

export type QuestionState = "unanswered" | "answered" | "in_progress";
export type AnnotationType = "error" | "info" | "annotation" | "warning" | "question";

interface UserAnnotationUserData {
    name: string;
}

export interface UserAnnotationPermissionData {
    save?: boolean;
    transition?: Record<QuestionState, boolean>
    update?: boolean;
    destroy?: boolean;
    can_see_annotator?: boolean
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
    evaluation_id?: number | null;
    // eslint-disable-next-line camelcase
    saved_annotation_id?: number | null;
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
    responses: UserAnnotationData[];
    // eslint-disable-next-line camelcase
    thread_root_id?: number | null;
    row: number;
    rows: number;
    column?: number;
    columns?: number;
}

class UserAnnotationState extends State {
    readonly rootIdsByLine = new StateMap<number, number[]>();
    readonly rootIdsByMarkedLine = new StateMap<number, number[]>();
    readonly byId = new StateMap<number, UserAnnotationData>();

    get count(): number {
        return this.byId.size;
    }

    // public for testing purposes
    public async addToMap(annotation: UserAnnotationData): Promise<void> {
        this.byId.set(annotation.id, annotation);
        if (!annotation.thread_root_id) {
            const line = annotation.line_nr ?? 0;
            if (this.rootIdsByLine.has(line)) {
                const annotations = this.rootIdsByLine.get(line);
                this.rootIdsByLine.set(line, [...annotations, annotation.id]);
            } else {
                this.rootIdsByLine.set(line, [annotation.id]);
            }
            for (let markedLine = line; markedLine < line + annotation.rows; markedLine++) {
                if (this.rootIdsByMarkedLine.has(markedLine)) {
                    const annotations = this.rootIdsByMarkedLine.get(markedLine);
                    this.rootIdsByMarkedLine.set(markedLine, [...annotations, annotation.id]);
                } else {
                    this.rootIdsByMarkedLine.set(markedLine, [annotation.id]);
                }
            }
            annotation.responses.forEach(response => this.addToMap(response));
        } else {
            await this.invalidate(annotation.thread_root_id);
        }
    }

    private async replaceInMap(annotation: UserAnnotationData): Promise<void> {
        this.byId.set(annotation.id, annotation);
        if (annotation.thread_root_id) {
            await this.invalidate(annotation.thread_root_id);
        }
    }

    private async removeFromMap(annotation: UserAnnotationData): Promise<void> {
        this.byId.delete(annotation.id);
        if (!annotation.thread_root_id) {
            const line = annotation.line_nr ?? 0;
            if (this.rootIdsByLine.has(line)) {
                const annotations = this.rootIdsByLine.get(line);
                this.rootIdsByLine.set(line, annotations?.filter(id => id !== annotation.id));
            }
            for (let markedLine = line; markedLine < line + annotation.rows; markedLine++) {
                if (this.rootIdsByMarkedLine.has(markedLine)) {
                    const annotations = this.rootIdsByMarkedLine.get(markedLine);
                    this.rootIdsByMarkedLine.set(markedLine, annotations?.filter(id => id !== annotation.id));
                }
            }
        } else {
            await this.invalidate(annotation.thread_root_id);
        }
    }

    async fetch(submissionId: number): Promise<void> {
        const response = await fetch(`/submissions/${submissionId}/annotations.json`);
        const json = await response.json();

        this.rootIdsByLine.clear();
        this.byId.clear();
        for (const annotation of json) {
            await this.addToMap(annotation);
        }
    }

    async invalidate(annotationId: number): Promise<void> {
        const response = await fetch(`/annotations/${annotationId}.json`);
        const json = await response.json();

        await this.replaceInMap(json);
    }

    async create(formData: UserAnnotationFormData, submissionId: number, mode = "annotation", saveAnnotation = false, savedAnnotationTitle: string = undefined): Promise<UserAnnotationData> {
        const response = await fetch(`/submissions/${submissionId}/annotations.json`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ [mode]: formData })
        });
        const data = await response.json();

        if (!response.ok) {
            throw new Error();
        }

        if (mode === "question") {
            Notification.startNotificationRefresh();
        }
        if (saveAnnotation) {
            try {
                data.saved_annotation_id = await savedAnnotationState.create({
                    from: data.id,
                    saved_annotation: {
                        title: savedAnnotationTitle,
                        annotation_text: data.annotation_text,
                    }
                });
            } catch (errors) {
                alert(I18n.t("js.saved_annotation.new.errors", { count: errors.length }) + "\n\n" + errors.join("\n"));
            }
        }
        if (data.saved_annotation_id) {
            savedAnnotationState.invalidate(data.saved_annotation_id);
        }

        await this.addToMap(data);

        return data;
    }

    async delete(annotation: UserAnnotationData): Promise<void> {
        const response = await fetch(annotation.url, { method: "DELETE" });
        if (!response.ok) {
            throw new Error();
        }

        savedAnnotationState.invalidate(annotation.saved_annotation_id);
        await this.removeFromMap(annotation);
    }

    async update(annotation: UserAnnotationData, formData: UserAnnotationFormData): Promise<void> {
        const response = await fetch(annotation.url, {
            headers: { "Content-Type": "application/json" },
            method: "PATCH",
            body: JSON.stringify({
                annotation: formData
            })
        });
        const data = await response.json();

        if (!response.ok) {
            throw new Error();
        }

        await this.replaceInMap(data);
        if (formData.saved_annotation_id != annotation.saved_annotation_id) {
            savedAnnotationState.invalidate(formData.saved_annotation_id);
            savedAnnotationState.invalidate(annotation.saved_annotation_id);
        }
    }

    async transition(annotation: UserAnnotationData, newState: QuestionState): Promise<void> {
        const response = await fetch(annotation.url, {
            method: "PATCH",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                from: annotation.question_state,
                question: {
                    question_state: newState
                }
            })
        });

        if (response.ok) {
            const json = await response.json();
            await this.replaceInMap(json);
        } else if (response.status === 404) {
            // Someone already deleted this question.
            new dodona.Toast(I18n.t("js.user_question.deleted"));
            await this.removeFromMap(annotation);
        } else if (response.status == 403) {
            // Someone already changed the status of this question.
            new dodona.Toast(I18n.t("js.user_question.conflict"));
            // We now need to update the annotation, but we don't have the new data.
            // Get the annotation from the backend.
            await this.invalidate(annotation.id);
        }
    }

    async transitionAll(annotations: UserAnnotationData[], newState: QuestionState): Promise<void> {
        for (const annotation of annotations) {
            // we wait for each transition to finish before starting the next one
            // this prevents inconsistent questionstates being shown
            await this.transition(annotation, newState);
        }
    }
}

export const userAnnotationState = new UserAnnotationState();
