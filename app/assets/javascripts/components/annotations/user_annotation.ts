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
import "components/saved_annotations/new_saved_annotation";
import { getQuestionMode } from "state/Annotations";
import { initTooltips } from "util.js";


/**
 * This component represents a single user annotation.
 * It can be either a root annotation or a response.
 * It also contains the form for editing the annotation.
 *
 * @element d-user-annotation
 *
 * @prop {UserAnnotationData} data - the data of the annotation
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
        const state = ["getQuestionMode"];
        if (this.isAlreadyLinked) {
            state.push(`getSavedAnnotation${this.savedAnnotationId}`);
        }
        return state;
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

    get type(): string {
        return getQuestionMode() ? "user_question" : "user_annotation";
    }

    protected get meta(): TemplateResult {
        return html`
            ${this.metaText}
            ${!this.data.released ? html`
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
            ${this.data.newer_submission_url ? html`
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
            ${ this.data.question_state == "unanswered" ? html`
                <i class="mdi mdi-comment-question-outline mdi-18 annotation-meta-icon colored-secondary"
                   title="${I18n.t("js.user_question.is_unanswered")}"
                   data-bs-toggle="tooltip"
                   data-bs-placement="top"
                ></i>
            ` : ""}
            ${ this.data.question_state == "in_progress" ? html`
                <i class="mdi mdi-comment-processing-outline mdi-18 annotation-meta-icon"
                   title="${I18n.t("js.user_question.is_in_progress")}"
                   data-bs-toggle="tooltip"
                   data-bs-placement="top"
                ></i>
            ` : ""}
        `;
    }

    deleteAnnotation(): void {
        if (confirm(I18n.t(`js.${this.type}.delete_confirm`))) {
            deleteUserAnnotation(this.data);
        }
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
        // Reinitialize tooltips
        initTooltips(this);
    }

    render(): TemplateResult {
        return html`
            <div class="annotation ${this.data.type == "annotation" ? "user" : "question"}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${this.meta}
                    </span>
                    ${this.data.permission.update ? html`
                        <div class="dropdown actions float-end" id="kebab-menu">
                            <a class="btn btn-icon btn-icon-inverted dropdown-toggle" data-bs-toggle="dropdown">
                                <i class="mdi mdi-dots-horizontal text-muted"></i>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end">
                                 <li>
                                    <a class="dropdown-item" @click="${() => this.editing = true}">
                                        <i class="mdi mdi-pencil mdi-18"></i> ${I18n.t(`js.${this.type}.edit`)}
                                    </a>
                                </li>
                                ${ this.data.permission.destroy ? html`
                                    <li>
                                        <a class="dropdown-item" @click="${() => this.deleteAnnotation()}">
                                            <i class="mdi mdi-delete mdi-18"></i> ${I18n.t(`js.user_annotation.delete`)}
                                        </a>
                                    </li>
                                ` : ""}
                                ${ isBetaCourse(this.data.course_id) && !this.hasSavedAnnotation ? html`
                                    <d-new-saved-annotation
                                        from-annotation-id="${this.data.id}"
                                        annotation-text="${this.data.annotation_text}"
                                        @created="${e => this.__savedAnnotationId = e.detail.id}">
                                    </d-new-saved-annotation>
                                ` : ""}
                            </ul>
                        </div>
                    ` : ""}
                </div>
                ${this.editing ? html`
                    <d-annotation-form
                        annotation-text="${this.data.annotation_text}"
                        saved-annotation-id="${this.savedAnnotationId}"
                        @cancel="${() => this.editing = false}"
                        @submit="${e => this.updateAnnotation(e)}"
                        ${ref(this.annotationFormRef)}
                        submit-button-text="update"
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
