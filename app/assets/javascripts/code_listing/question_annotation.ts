import { Annotation } from "code_listing/annotation";
import { fetch } from "util.js";
import {
    UserAnnotation,
    UserAnnotationData,
    UserAnnotationEditor, UserAnnotationFormData,
    UserAnnotationPermissionData
} from "code_listing/user_annotation";

export type QuestionState = "unanswered" | "answered" | "in_progress";

interface QuestionAnnotationPermissionData extends UserAnnotationPermissionData {
    unresolve: boolean;
    in_progress: boolean;
    resolve: boolean;
}

export interface QuestionAnnotationData extends UserAnnotationData {
    question_state: QuestionState;
}

export class QuestionAnnotation extends UserAnnotation {
    public readonly permissions: QuestionAnnotationPermissionData;
    private readonly questionState: QuestionState;

    constructor(data: QuestionAnnotationData, editFn: UserAnnotationEditor) {
        super(data, editFn, "question");
        this.questionState = data.question_state;
        this.permissions = data.permission as QuestionAnnotationPermissionData;
    }

    protected get meta(): string {
        const timestamp = I18n.l("time.formats.annotation", this.createdAt);
        const user = this.user.name;

        const questionState = I18n.t(`js.question.state.${this.questionState}`);
        return I18n.t("js.user_question.meta", {
            user: user,
            time: timestamp,
            state: questionState
        });
    }

    public get resolvable(): boolean {
        return this.permissions.resolve;
    }

    public get inProgressable(): boolean {
        return this.permissions.in_progress;
    }

    public get unresolvable(): boolean {
        return this.permissions.unresolve;
    }

    protected get editTitle(): string {
        return I18n.t("js.user_question.edit");
    }

    protected async resolve(): Promise<void> {
        return this.changeState("resolve");
    }

    protected async inProgress(): Promise<void> {
        return this.changeState("in_progress");
    }

    protected async unresolve(): Promise<void> {
        return this.changeState("unresolve");
    }

    public async update(formData: UserAnnotationFormData): Promise<Annotation> {
        const response = await fetch(this.url, {
            headers: { "Content-Type": "application/json" },
            method: "PATCH",
            body: JSON.stringify({
                annotation: formData
            })
        });
        const data = await response.json();

        if (response.ok) {
            return new QuestionAnnotation(data, this.editor);
        }
        throw new Error();
    }

    protected changeState(newState: string): Promise<void> {
        return fetch(`/annotations/${this.id}/${newState}?from=${this.questionState}`, {
            method: "POST",
            headers: {
                "Accept": "application/json",
            }
        }).then(async response => {
            if (response.ok) {
                const json = await response.json();
                const newAnnotation: Annotation = new QuestionAnnotation(json, this.editor);
                window.dodona.codeListing.updateAnnotation(this, newAnnotation);
            } else if (response.status === 404) {
                // Someone already deleted this question.
                new dodona.Toast(I18n.t("js.user_question.deleted"));
                window.dodona.codeListing.removeAnnotation(this);
                this.__html.remove();
            } else if (response.status == 403) {
                // Someone already changed the status of this question.
                new dodona.Toast(I18n.t("js.user_question.conflict"));
                // We now need to update the annotation, but we don't have the new data.
                // Get the annotation from the backend.
                this.selfUpdate();
            }
        });
    }

    private selfUpdate(): void {
        fetch(`/annotations/${this.id}`, {
            headers: {
                "Accept": "application/json"
            }
        })
            .then(r => r.json())
            .then(r => {
                const newAnnotation: Annotation = new QuestionAnnotation(r, this.editor);
                window.dodona.codeListing.updateAnnotation(this, newAnnotation);
            });
    }
}

function annotationFromData(data: UserAnnotationData,
    editFn: UserAnnotationEditor): UserAnnotation {
    if (data.type == "question") {
        return new QuestionAnnotation(data as QuestionAnnotationData, editFn);
    }
    return new UserAnnotation(data, editFn);
}

export async function createUserAnnotation(formData: UserAnnotationFormData,
    submissionId: number,
    editFn: UserAnnotationEditor): Promise<UserAnnotation> {
    const response = await fetch(`/submissions/${submissionId}/annotations.json`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ annotation: formData })
    });
    const data = await response.json();

    if (response.ok) {
        return annotationFromData(data, editFn);
    }
    throw new Error();
}

export async function getAllUserAnnotations(submission: number,
    editFn: UserAnnotationEditor): Promise<UserAnnotation[]> {
    const response = await fetch(`/submissions/${submission}/annotations.json`);
    const json = await response.json();
    return json.map(data => annotationFromData(data, editFn));
}
