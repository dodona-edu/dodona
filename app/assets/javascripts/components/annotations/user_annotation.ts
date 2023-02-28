import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { isBetaCourse } from "saved_annotation_beta";
import { getSavedAnnotation, SavedAnnotation } from "state/SavedAnnotations";
import { stateMixin } from "state/StateMixin";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { deleteUserAnnotation, updateUserAnnotation, UserAnnotationData } from "state/UserAnnotations";
import { i18nMixin } from "components/meta/i18n_mixin";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";


/**
 *
 */
@customElement("d-user-annotation")
export class UserAnnotation extends i18nMixin(stateMixin(ShadowlessLitElement)) {
    @property({ type: Object })
    data: UserAnnotationData;

    @property({ state: true })
    __savedAnnotationId: number | null;
    @property({ state: true })
    editing = false;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    get savedAnnotationId(): number | null {
        return this.__savedAnnotationId ?? this.data.saved_annotation_id;
    }

    get isAlreadyLinked(): boolean {
        return this.savedAnnotationId != undefined;
    }

    get state(): string[] {
        return this.isAlreadyLinked ? [`getSavedAnnotation${this.savedAnnotationId}`] : [];
    }

    get savedAnnotation(): SavedAnnotation | undefined {
        return getSavedAnnotation(this.savedAnnotationId);
    }

    get hasSavedAnnotation(): boolean {
        return this.isAlreadyLinked && this.savedAnnotation != undefined;
    }

    get metaText(): string {
        if (!this.data.permission.can_see_annotator) {
            return I18n.t("js.user_annotation.anonymous_message");
        }

        const timestamp = I18n.formatDate(this.data.created_at, "time.formats.annotation");
        const user = this.data.user?.name;

        return I18n.t("js.user_annotation.meta", { user: user, time: timestamp });
    }

    protected get meta(): TemplateResult {
        return html`
            ${this.metaText}
            ${this.data.released ? html`
                        <i class="mdi mdi-eye-off mdi-18 annotation-meta-icon"
                           title="${I18n.t("js.user_annotation.not_released")}"
                           data-bs-toggle="tooltip"
                           data-bs-placement="top"
                        ></i>
                    ` : ""}
            ${ isBetaCourse(this.data.course_id) && this.hasSavedAnnotation ? html`
                        <i class="mdi mdi-link-variant mdi-18 annotation-meta-icon"
                            title="${I18n.t("js.saved_annotation.new.linked", { title: this.savedAnnotation.title })}"
                        ></i>
                    ` : ""}
            ${this.data.newer_submission_url !== null ? html`
                <span>
                    ·
                    <a href="${this.data.newer_submission_url}" target="_blank">
                        <i class="mdi mdi-information mdi-18 colored-info"
                           title="${I18n.t("js.user_question.has_newer_submission")}"
                           data-bs-toggle="tooltip"
                           data-bs-placement="top"
                        ></i>
                    </a>
                </span>
            ` : ""}
        `;
    }

    protected get buttons(): TemplateResult {
        return html`
            <v-slot name="buttons"></v-slot>
            ${this.data.permission.update ? html`
                <a class="btn btn-text annotation-edit" @click="${() => this.editing = true}">
                    <i class="mdi mdi-pencil"></i>
                </a>
                ${ isBetaCourse(this.data.course_id) && !this.hasSavedAnnotation ? html`
                    <d-new-saved-annotation
                        from-annotation-id="${this.data.id}"
                        annotation-text="${this.data.annotation_text}"
                        @created="${e => this.__savedAnnotationId = e.detail.id}">
                    </d-new-saved-annotation>
                ` : ""}
            ` : ""}
        `;
    }

    deleteAnnotation(): void {
        deleteUserAnnotation(this.data);
    }

    async updateAnnotation(e: CustomEvent): Promise<void> {
        try {
            await updateUserAnnotation(this.data, {
                annotation_text: e.detail.text,
                saved_annotation_id: e.detail.savedAnnotationId || undefined,
            });
            this.editing = false;
        } catch (e) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);

        // Ask MathJax to search for math in the annotations
        window.MathJax.typeset();
    }

    render(): TemplateResult {
        return html`
            <div class="annotation ${this.data.type == "annotation" ? "user" : "question"}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${this.meta}
                    </span>
                    ${this.buttons}
                </div>
                ${this.editing ? html`
                    <d-annotation-form
                        annotation-text="${this.data.annotation_text}"
                        saved-annotation-id="${this.savedAnnotationId}"
                        removable="${this.data.permission.destroy}"
                        @cancel="${() => this.editing = false}"
                        @delete="${() => this.deleteAnnotation()}"
                        @submit="${e => this.updateAnnotation(e)}"
                        ${ref(this.annotationFormRef)}
                    ></d-annotation-form>
                ` : html`
                    <div class="annotation-text">
                        ${unsafeHTML(this.data.rendered_markdown)}
                    </div>
                `}
            </div>
        `;
    }
}
