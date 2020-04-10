import { Annotation } from "code_listing/annotation";
import { fetch } from "util.js";

export interface UserAnnotationFormData {
    annotation_text: string;
    line_nr: number | null;
    review_session_id: number | undefined;
}

export type UserAnnotationEditor = (ua: UserAnnotation, cb: CallableFunction) => HTMLElement;

interface UserAnnotationUserData {
    name: string;
}

interface UserAnnotationVisibility {
    student: boolean;
}

interface UserAnnotationPermissionData {
    update: boolean;
    destroy: boolean;
}

export interface UserAnnotationData {
    annotation_text: string;
    created_at: string;
    id: number;
    line_nr: number;
    permission: UserAnnotationPermissionData;
    rendered_markdown: string;
    review_session_id: number | null;
    url: string;
    user: UserAnnotationUserData;
    visibility: UserAnnotationVisibility;
}

export class UserAnnotation extends Annotation {
    private readonly editor: UserAnnotationEditor;

    public readonly createdAt: string;
    public readonly id: number;
    public readonly permissions: UserAnnotationPermissionData;
    private readonly __rawText: string;
    public readonly reviewSessionId: number | null;
    public readonly url: string;
    public readonly user: UserAnnotationUserData;
    public readonly visibility: UserAnnotationVisibility;

    constructor(data: UserAnnotationData, editFn: UserAnnotationEditor) {
        const line = data.line_nr === null ? null : data.line_nr + 1;
        super(line, data.rendered_markdown, "user");
        this.createdAt = data.created_at;
        this.editor = editFn;
        this.id = data.id;
        this.permissions = data.permission;
        this.visibility = data.visibility;
        this.__rawText = data.annotation_text;
        this.reviewSessionId = data.review_session_id;
        this.url = data.url;
        this.user = data.user;
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
        return fetch(`/submissions/${submission}/annotations.json`)
            .then(resp => resp.json())
            .then(json => json.map(data =>
                new UserAnnotation(data, editFn)
            ));
    }

    protected get meta(): string {
        const timestamp = I18n.l("time.formats.annotation", this.createdAt);
        const user = this.user.name;

        return I18n.t("js.user_annotation.meta", { user: user, time: timestamp });
    }

    public get modifiable(): boolean {
        return this.permissions.update;
    }

    public get rawText(): string {
        return this.__rawText;
    }

    public get removable(): boolean {
        return this.permissions.destroy;
    }

    public async remove(): Promise<void> {
        return fetch(this.url, { method: "DELETE" }).then(() => {
            super.remove();
        });
    }

    public get released(): boolean {
        return this.visibility.student;
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
}
