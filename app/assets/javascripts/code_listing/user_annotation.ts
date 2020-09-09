import { Annotation } from "code_listing/annotation";
import { fetch } from "util.js";

export type QuestionState = "unanswered" | "answered" | "in_progress";

export interface UserAnnotationFormData {
    annotation_text: string;
    line_nr: number | null;
    evaluation_id: number | undefined;
}

export type UserAnnotationEditor = (ua: UserAnnotation, cb: CallableFunction) => HTMLElement;

interface UserAnnotationUserData {
    name: string;
}

interface UserAnnotationPermissionData {
    update: boolean;
    destroy: boolean;
    unresolve: boolean;
    in_progress: boolean;
    resolve: boolean;
}

export interface UserAnnotationData {
    annotation_text: string;
    created_at: string;
    id: number;
    line_nr: number;
    permission: UserAnnotationPermissionData;
    released: boolean;
    rendered_markdown: string;
    evaluation_id: number | null;
    url: string;
    user: UserAnnotationUserData;
    type: string;
    question_state: QuestionState | null;
}

export class UserAnnotation extends Annotation {
    private readonly editor: UserAnnotationEditor;

    public readonly createdAt: string;
    public readonly id: number;
    public readonly permissions: UserAnnotationPermissionData;
    private readonly __rawText: string;
    public readonly released: boolean;
    public readonly evaluationId: number | null;
    public readonly url: string;
    public readonly user: UserAnnotationUserData;
    private readonly questionState: string | null;

    constructor(data: UserAnnotationData, editFn: UserAnnotationEditor) {
        const line = data.line_nr === null ? null : data.line_nr + 1;
        super(line, data.rendered_markdown, data.type == "question" ? "question" : "user");
        this.createdAt = data.created_at;
        this.editor = editFn;
        this.id = data.id;
        this.permissions = data.permission;
        this.released = data.released;
        this.__rawText = data.annotation_text;
        this.evaluationId = data.evaluation_id;
        this.url = data.url;
        this.user = data.user;
        this.questionState = data.question_state;
    }

    public static async create(formData: UserAnnotationFormData,
        submissionId: number,
        editFn: UserAnnotationEditor): Promise<UserAnnotation> {
        const response = await fetch(`/submissions/${submissionId}/annotations.json`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ annotation: formData })
        });
        const data = await response.json();

        if (response.ok) {
            return new UserAnnotation(data, editFn);
        }
        throw new Error();
    }

    protected edit(): void {
        const editButton = this.__html.querySelector(".annotation-edit");

        const editor = this.editor(this, () => {
            const editFormId = `#annotation-submission-update-${this.id}`;
            this.__html.querySelector(editFormId).replaceWith(this.body);
            editButton.classList.remove("hide");
        });
        editButton.classList.add("hide");

        this.__html.querySelector(".annotation-text").replaceWith(editor);
    }

    public static async getAll(submission: number,
        editFn: UserAnnotationEditor): Promise<UserAnnotation[]> {
        const response = await fetch(`/submissions/${submission}/annotations.json`);
        const json = await response.json();
        return json.map(data => new UserAnnotation(data, editFn));
    }

    protected get meta(): string {
        const timestamp = I18n.l("time.formats.annotation", this.createdAt);
        const user = this.user.name;

        return I18n.t("js.user_annotation.meta", { user: user, time: timestamp });
    }

    public get modifiable(): boolean {
        return this.permissions.update;
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

    public get rawText(): string {
        return this.__rawText;
    }

    public get removable(): boolean {
        return this.permissions.destroy;
    }

    public get visible(): boolean {
        return this.released;
    }

    public async remove(): Promise<void> {
        return fetch(this.url, { method: "DELETE" }).then(() => {
            super.remove();
        });
    }

    protected get title(): string {
        return I18n.t(`js.annotation.type.${this.type}`);
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
            return new UserAnnotation(data, this.editor);
        }
        throw new Error();
    }

    protected get editTitle(): string {
        if (this.type === "question") {
            return I18n.t("js.user_question.edit");
        }
        return I18n.t("js.user_annotation.edit");
    }

    private selfUpdate(): void {
        fetch(`/annotations/${this.id}`, {
            headers: {
                "Accept": "application/json"
            }
        })
            .then(r => r.json())
            .then(r => {
                const newAnnotation: Annotation = new UserAnnotation(r, this.editor);
                window.dodona.codeListing.updateAnnotation(this, newAnnotation);
            });
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

    protected changeState(newState: string): Promise<void> {
        console.assert(this.questionState != null, "questions must have a state");
        return fetch(`/annotations/${this.id}/${newState}?from=${this.questionState}`, {
            method: "POST",
            headers: {
                "Accept": "application/json",
            }
        }).then(async response => {
            if (response.ok) {
                const json = await response.json();
                const newAnnotation: Annotation = new UserAnnotation(json, this.editor);
                console.log("New annotation is", newAnnotation);
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
}
