import { createDelayer, fetch } from "utilities";
import { Notification } from "notification";
import { savedAnnotationState } from "state/SavedAnnotations";
import { State } from "state/state_system/State";
import { StateMap } from "state/state_system/StateMap";
import { stateProperty } from "state/state_system/StateProperty";
import { createStateFromInterface } from "state/state_system/CreateStateFromInterface";

export interface UserAnnotationFormData {
    annotation_text: string;
    line_nr?: number | null;
    evaluation_id?: number | undefined;
    saved_annotation_id?: number | null;
    thread_root_id?: number | null;
    rows?: number;
    column?: number;
    columns?: number;
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

// UserAnnotationData is the data that is returned from the server
interface UserAnnotationData {
    annotation_text: string;
    created_at: string;
    id: number;
    line_nr: number;
    permission: UserAnnotationPermissionData;
    released: boolean;
    rendered_markdown: string;
    evaluation_id?: number | null;
    saved_annotation_id?: number | null;
    url: string;
    user: UserAnnotationUserData;
    type: AnnotationType;
    last_updated_by: UserAnnotationUserData;
    question_state?: QuestionState;
    newer_submission_url?: string | null;
    responses: UserAnnotationData[];
    thread_root_id?: number | null;
    row: number;
    rows: number;
    column?: number;
    columns?: number;
}

/**
 * UserAnnotation implements the UserAnnotationData interface and adds state properties and methods.
 */
export class UserAnnotation extends createStateFromInterface<UserAnnotationData>() {
    @stateProperty public accessor isHovered = false;
    responses: UserAnnotation[];

    constructor(data: UserAnnotationData) {
        super(data);
        this.responses = data.responses.map(response => new UserAnnotation(response));
    }
}

export interface SelectedRange {
    row: number;
    rows: number;
    column?: number;
    columns?: number;
}

class UserAnnotationState extends State {
    readonly rootIdsByLine = new StateMap<number, number[]>();
    readonly rootIdsByMarkedLine = new StateMap<number, number[]>();
    readonly byId = new StateMap<number, UserAnnotation>();

    @stateProperty public accessor selectedRange: SelectedRange | null = null;
    @stateProperty public accessor dragStartRow: number | null = null;
    @stateProperty public accessor formShown = false;
    @stateProperty private accessor _createButtonExpanded = false;
    private expansionDelayer = createDelayer();

    public set isCreateButtonExpanded(value: boolean) {
        this.expansionDelayer(() => this._createButtonExpanded = value, 250);
    }

    public get isCreateButtonExpanded(): boolean {
        return this._createButtonExpanded;
    }

    constructor() {
        super();
    }

    get count(): number {
        return this.byId.size;
    }

    public reset(): void {
        this.byId.clear();
        this.rootIdsByLine.clear();
        this.rootIdsByMarkedLine.clear();
        this.selectedRange = null;
        this.formShown = false;
    }

    // public for testing purposes
    public async addToMap(annotation: UserAnnotation): Promise<void> {
        this.byId.set(annotation.id, annotation);
        if (!annotation.thread_root_id) {
            const line = annotation.line_nr && annotation.rows ? annotation.line_nr + annotation.rows - 1 : 0;
            if (this.rootIdsByLine.has(line)) {
                const annotations = this.rootIdsByLine.get(line);
                this.rootIdsByLine.set(line, [...annotations, annotation.id]);
            } else {
                this.rootIdsByLine.set(line, [annotation.id]);
            }
            for (let markedLine = annotation.line_nr ?? 0; markedLine <= line; markedLine++) {
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

    private async replaceInMap(annotation: UserAnnotation): Promise<void> {
        this.byId.set(annotation.id, annotation);
        if (annotation.thread_root_id) {
            await this.invalidate(annotation.thread_root_id);
        }
    }

    private async removeFromMap(annotation: UserAnnotation): Promise<void> {
        this.byId.delete(annotation.id);
        if (!annotation.thread_root_id) {
            const line = annotation.line_nr && annotation.rows ? annotation.line_nr + annotation.rows - 1 : 0;
            if (this.rootIdsByLine.has(line)) {
                const annotations = this.rootIdsByLine.get(line);
                this.rootIdsByLine.set(line, annotations?.filter(id => id !== annotation.id));
            }
            for (let markedLine = annotation.line_nr ?? 0; markedLine <= line; markedLine++) {
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
        for (const data of json) {
            const annotation = new UserAnnotation(data);
            await this.addToMap(annotation);
        }
    }

    async invalidate(annotationId: number): Promise<void> {
        const response = await fetch(`/annotations/${annotationId}.json`);
        const json = await response.json();

        const annotation = new UserAnnotation(json);

        await this.replaceInMap(annotation);
    }

    async create(formData: UserAnnotationFormData, submissionId: number, mode = "annotation", saveAnnotation = false, savedAnnotationTitle: string = undefined): Promise<UserAnnotation> {
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

        const annotation = new UserAnnotation(data);

        await this.addToMap(annotation);

        return annotation;
    }

    async delete(annotation: UserAnnotation): Promise<void> {
        const response = await fetch(annotation.url, { method: "DELETE" });
        if (!response.ok) {
            throw new Error();
        }

        savedAnnotationState.invalidate(annotation.saved_annotation_id);
        await this.removeFromMap(annotation);
    }

    async update(annotation: UserAnnotation, formData: UserAnnotationFormData): Promise<void> {
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

    async transition(annotation: UserAnnotation, newState: QuestionState): Promise<void> {
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

    async transitionAll(annotations: UserAnnotation[], newState: QuestionState): Promise<void> {
        for (const annotation of annotations) {
            // we wait for each transition to finish before starting the next one
            // this prevents inconsistent questionstates being shown
            await this.transition(annotation, newState);
        }
    }
}

export const userAnnotationState = new UserAnnotationState();
