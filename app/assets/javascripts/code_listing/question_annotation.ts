import { Annotation, QuestionState } from "code_listing/annotation";
import { fetch } from "util.js";
import {
    UserAnnotation,
    UserAnnotationData,
    UserAnnotationEditor, UserAnnotationFormData,
    UserAnnotationPermissionData
} from "code_listing/user_annotation";

interface QuestionAnnotationPermissionData extends UserAnnotationPermissionData {
    transition: {[state in QuestionState]: boolean};
}

export interface QuestionAnnotationData extends UserAnnotationData {
    // eslint-disable-next-line camelcase
    question_state: QuestionState;
    // eslint-disable-next-line camelcase
    newer_submission_url: string | null;
}

export class QuestionAnnotation extends UserAnnotation {
    public readonly permissions: QuestionAnnotationPermissionData;
    private readonly questionState: QuestionState;
    private readonly newerSubmissionUrl: string | null;

    constructor(data: QuestionAnnotationData, editFn: UserAnnotationEditor) {
        super(data, editFn, "question");
        this.questionState = data.question_state;
        this.newerSubmissionUrl = data.newer_submission_url;
        this.permissions = data.permission as QuestionAnnotationPermissionData;
    }

    protected get meta(): string {
        const timestamp = I18n.l("time.formats.annotation", this.createdAt);
        const user = this.user.name;
        const questionState = I18n.t(`js.question.state.${this.questionState}`);

        if (this.questionState === "unanswered") {
            return I18n.t("js.user_question.meta_unanswered", {
                user: user,
                time: timestamp,
                state: questionState
            });
        } else {
            return I18n.t("js.user_question.meta_else", {
                user: user,
                time: timestamp,
                state: questionState,
                last: this.lastUpdatedBy.name
            });
        }
    }

    protected get hasNotice(): boolean {
        return this.newerSubmissionUrl !== null;
    }

    protected get noticeUrl(): string | null {
        return this.newerSubmissionUrl;
    }

    protected get noticeInfo(): string | null {
        return I18n.t("js.user_question.has_newer_submission");
    }

    public transitionable(to: QuestionState): boolean {
        return this.permissions.transition[to];
    }

    protected get editTitle(): string {
        return I18n.t("js.user_question.edit");
    }

    public async update(formData: UserAnnotationFormData): Promise<Annotation> {
        const response = await fetch(this.url, {
            headers: { "Content-Type": "application/json" },
            method: "PATCH",
            body: JSON.stringify({
                question: formData
            })
        });
        const data = await response.json();

        if (response.ok) {
            return new QuestionAnnotation(data, this.editor);
        }
        throw new Error();
    }

    protected async transition(newState: QuestionState): Promise<void> {
        fetch(this.url, {
            method: "PATCH",
            headers: {
                "Accept": "application/json",
                "Content-Type": "application/json"
            },
            body: JSON.stringify({
                from: this.questionState,
                question: {
                    // eslint-disable-next-line camelcase
                    question_state: newState
                }
            })
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
    editFn: UserAnnotationEditor, mode = "annotation"): Promise<UserAnnotation> {
    const response = await fetch(`/submissions/${submissionId}/annotations.json`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ [mode]: formData })
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
