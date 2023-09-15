import { html, PropertyValues, TemplateResult } from "lit";
import { customElement, property } from "lit/decorators.js";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { ShadowlessLitElement } from "components/meta/shadowless_lit_element";
import { UserAnnotation, userAnnotationState } from "state/UserAnnotations";
import { i18nMixin } from "components/meta/i18n_mixin";
import { AnnotationForm } from "components/annotations/annotation_form";
import { createRef, Ref, ref } from "lit/directives/ref.js";
import "components/saved_annotations/new_saved_annotation";
import { initTooltips } from "utilities";
import "components/saved_annotations/saved_annotation_icon";
import { annotationState } from "state/Annotations";
import { savedAnnotationState } from "state/SavedAnnotations";
import { isBetaCourse } from "saved_annotation_beta";

/**
 * This component represents a single user annotation.
 * It can be either a root annotation or a response.
 * It also contains the form for editing the annotation.
 *
 * @element d-user-annotation
 *
 * @prop {UserAnnotation} data - the annotation
 */
@customElement("d-user-annotation")
export class UserAnnotationComponent extends i18nMixin(ShadowlessLitElement) {
    @property({ type: Object })
    data: UserAnnotation;

    @property({ state: true })
    editing = false;

    annotationFormRef: Ref<AnnotationForm> = createRef();

    get headerText(): string {
        if (!this.data.permission.can_see_annotator) {
            return I18n.t("js.user_annotation.anonymous_message");
        }

        const timestamp = I18n.formatDate(this.data.created_at, "time.formats.annotation");
        const user = this.data.user?.name;

        return I18n.t("js.user_annotation.meta", { user: user, time: timestamp });
    }

    get type(): string {
        return annotationState.isQuestionMode ? "user_question" : "user_annotation";
    }

    protected get header(): TemplateResult {
        return html`
            ${this.headerText}
            ${!this.data.released ? html`
                        <i class="mdi mdi-eye-off mdi-18 annotation-meta-icon"
                           title="${I18n.t("js.user_annotation.not_released")}"
                           data-bs-toggle="tooltip"
                           data-bs-placement="top"
                        ></i>
                    ` : ""}
            <d-saved-annotation-icon .savedAnnotationId="${this.data.saved_annotation_id}">
            </d-saved-annotation-icon>
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
            ${ this.data.question_state == "answered" ? html`
                <i class="mdi mdi-comment-check-outline mdi-18 annotation-meta-icon"
                   title="${I18n.t("js.user_question.is_answered")}"
                   data-bs-toggle="tooltip"
                   data-bs-placement="top"
                ></i>
            ` : ""}
        `;
    }

    deleteAnnotation(): void {
        if (confirm(I18n.t(`js.${this.type}.delete_confirm`))) {
            userAnnotationState.delete(this.data);
        }
    }

    async updateAnnotation(e: CustomEvent): Promise<void> {
        try {
            await userAnnotationState.update(this.data, {
                annotation_text: e.detail.text,
                saved_annotation_id: e.detail.savedAnnotationId || undefined,
            });
            if (e.detail.saveAnnotation) {
                await savedAnnotationState.create( {
                    from: this.data.id,
                    saved_annotation: {
                        title: e.detail.savedAnnotationTitle,
                        annotation_text: e.detail.text,
                    }
                });
            }
            this.editing = false;
        } catch (e) {
            this.annotationFormRef.value.hasErrors = true;
            this.annotationFormRef.value.disabled = false;
        }
    }

    protected updated(_changedProperties: PropertyValues): void {
        super.updated(_changedProperties);

        try {
            // Ask MathJax to search for math in the annotations
            window.MathJax.typeset([this]);
        } catch (e) {
            // MathJax is not loaded
            console.warn("MathJax is not loaded");
        }
        // Reinitialize tooltips
        initTooltips(this);
    }

    reopenQuestion(): void {
        userAnnotationState.transition(this.data, "unanswered");
    }

    get dropdownOptions(): TemplateResult[] {
        const options = [];

        if (this.data.permission.update) {
            options.push(html`
                <li>
                    <a class="dropdown-item" @click="${() => this.editing = true}">
                        <i class="mdi mdi-pencil mdi-18"></i> ${I18n.t(`js.${this.type}.edit`)}
                    </a>
                </li>
            `);
        }
        if (this.data.permission.save && isBetaCourse()) {
            options.push(html`
                <li>
                    <d-new-saved-annotation
                        class="dropdown-item"
                        from-annotation-id="${this.data.id}"
                        annotation-text="${this.data.annotation_text}"
                        .savedAnnotationId="${this.data.saved_annotation_id}">
                    </d-new-saved-annotation>
                </li>
            `);
        }
        if (this.data.permission.destroy) {
            options.push(html`
                <li>
                    <a class="dropdown-item" @click="${() => this.deleteAnnotation()}">
                        <i class="mdi mdi-delete mdi-18"></i> ${I18n.t(`js.user_annotation.delete`)}
                    </a>
                </li>
            `);
        }
        if (this.data.permission.transition?.unanswered) {
            options.push(html`
                <li>
                    <a class="dropdown-item" @click="${() => this.reopenQuestion()}">
                        <i class="mdi mdi-comment-question-outline mdi-18"></i> ${I18n.t("js.user_question.unresolve")}
                    </a>
                </li>
            `);
        }

        return options;
    }

    render(): TemplateResult {
        return html`
            <div class="annotation ${this.data.type === "annotation" ? "user" : "question"}"
                 @mouseenter="${() => this.data.isHovered = true}"
                 @mouseleave="${() => this.data.isHovered = false}">
                <div class="annotation-header">
                    <span class="annotation-meta">
                        ${this.header}
                    </span>
                    ${this.dropdownOptions.length > 0 ? html`
                        <div class="dropdown actions float-end" id="kebab-menu">
                            <a class="btn btn-icon btn-icon-muted dropdown-toggle" data-bs-toggle="dropdown">
                                <i class="mdi mdi-dots-vertical text-muted"></i>
                            </a>
                            <ul class="dropdown-menu dropdown-menu-end">
                                ${this.dropdownOptions}
                            </ul>
                        </div>
                    ` : ""}
                </div>
                ${this.editing ? html`
                    <d-annotation-form
                        annotation-text="${this.data.annotation_text}"
                        saved-annotation-id="${this.data.saved_annotation_id}"
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
