import { Annotation, AnnotationType } from "code_listing/annotation";
import { fetch } from "util.js";

export interface UserAnnotationFormData {
    // eslint-disable-next-line camelcase
    annotation_text: string;
    // eslint-disable-next-line camelcase
    line_nr: number | null;
    // eslint-disable-next-line camelcase
    evaluation_id: number | undefined;
}

export type UserAnnotationEditor = (ua: UserAnnotation, cb: CallableFunction) => HTMLElement;

interface UserAnnotationUserData {
    name: string;
}

export interface UserAnnotationPermissionData {
    update: boolean;
    destroy: boolean;
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
    url: string;
    user: UserAnnotationUserData;
    type: string;
    // eslint-disable-next-line camelcase
    last_updated_by: UserAnnotationUserData;
}

export class UserAnnotation extends Annotation {
    protected readonly editor: UserAnnotationEditor;

    public readonly createdAt: string;
    public readonly id: number;
    public readonly permissions: UserAnnotationPermissionData;
    private readonly __rawText: string;
    public readonly released: boolean;
    public readonly evaluationId: number | null;
    public readonly url: string;
    public readonly user: UserAnnotationUserData;
    public readonly lastUpdatedBy: UserAnnotationUserData;

    constructor(data: UserAnnotationData,
        editFn: UserAnnotationEditor, type: AnnotationType = "user") {
        const line = data.line_nr === null ? null : data.line_nr + 1;
        super(line, data.rendered_markdown, type);
        this.createdAt = data.created_at;
        this.editor = editFn;
        this.id = data.id;
        this.permissions = data.permission;
        this.released = data.released;
        this.__rawText = data.annotation_text;
        this.evaluationId = data.evaluation_id;
        this.url = data.url;
        this.user = data.user;
        this.lastUpdatedBy = data.last_updated_by;
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

    protected save(): void {
        const modal = new bootstrap.Modal(document.getElementById("save-annotation"));
        const fromField = document.getElementById("save-annotation-from");
        const textField = document.getElementById("save-annotation-text")

        fromField.value = this.id;
        textField.value = this.__rawText;
        modal.show();
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
        return I18n.t("js.user_annotation.edit");
    }

    protected get saveTitle(): string {
        return I18n.t("js.user_annotation.save")
    }
}
